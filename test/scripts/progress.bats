#!/usr/bin/env bats
# progress.bats — Unit tests for scripts/progress.sh
#
# Standards:
#   bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core
#   TAP (Test Anything Protocol) — https://testanything.org
#
# Run: bats test/scripts/progress.bats
#   or: make test-scripts

setup() {
    # Create a temp directory for each test
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "progress.sh --help exits 0 and shows usage" {
    run bash scripts/progress.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "progress.sh with missing files shows 'Not started'" {
    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/nonexistent-req.md" \
        --brief "$TEST_DIR/nonexistent-brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Not started"* ]]
}

@test "progress.sh with empty templates shows 0/9 and 0/11" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"
    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"0/9 complete"* ]]
    [[ "$output" == *"0/11 complete"* ]]
}

@test "progress.sh with complete fixtures shows 9/9 and 11/11" {
    # Generate complete artifacts from fixtures
    grep -v '^#' test/fixtures/requirements-answers.txt | \
        bash scripts/gather-requirements.sh "$TEST_DIR/requirements.md" 2>/dev/null
    cd "$TEST_DIR"
    grep -v '^#' "$OLDPWD/test/fixtures/brief-answers.txt" | \
        bash "$OLDPWD/scripts/gather-brief.sh" brief.md 2>/dev/null
    cd "$OLDPWD"

    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"9/9 complete"* ]]
    [[ "$output" == *"11/11 complete"* ]]
    [[ "$output" == *"Elicitation complete"* ]]
}

@test "progress.sh recommends next step for incomplete artifacts" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"
    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Next step"* ]]
    [[ "$output" == *"/req-01"* ]]
}

@test "progress.sh unknown option exits with non-zero status" {
    run bash scripts/progress.sh --bogus-flag
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "progress.sh mixed completion shows partial progress" {
    # Create a requirements.md where sections 01-05 are complete and 06-09 are empty
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    for num in 01 02 03 04 05; do
        sed -i "s/\(## ${num} .*\)/\1/" "$TEST_DIR/requirements.md"
        sed -i "/^## ${num} /,/^---$/{s/Status: empty/Status: complete/}" "$TEST_DIR/requirements.md"
    done
    cp templates/brief.md "$TEST_DIR/brief.md"

    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"5/9 complete"* ]]
}

@test "progress.sh architecture-only next step when requirements fully complete" {
    # Complete all 9 requirement sections, leave brief incomplete
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    for num in 01 02 03 04 05 06 07 08 09; do
        sed -i "/^## ${num} /,/^---$/{s/Status: empty/Status: complete/}" "$TEST_DIR/requirements.md"
    done
    cp templates/brief.md "$TEST_DIR/brief.md"

    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"9/9 complete"* ]]
    [[ "$output" == *"0/11 complete"* ]]
    # Next step should recommend /gather-* not /req-*
    [[ "$output" == *"/gather-"* ]]
    [[ "$output" != *"/req-"* ]]
}

@test "progress.sh in-progress status shows tilde marker" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    # Mark section 01 as in-progress
    sed -i '/^## 01 /,/^---$/{s/Status: empty/Status: in-progress/}' "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"

    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"~"* ]]
}

@test "progress.sh non-TTY output has no ANSI escape sequences" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"

    # Pipe to file to force non-TTY
    bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md" > "$TEST_DIR/output.txt"

    # Verify no ANSI escape sequences (ESC [ sequences)
    ! grep -P '\033\[' "$TEST_DIR/output.txt"
}

@test "progress.sh progress bar shows hash and dash characters" {
    # Create requirements with 5/9 complete to get a partial bar
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    for num in 01 02 03 04 05; do
        sed -i "/^## ${num} /,/^---$/{s/Status: empty/Status: complete/}" "$TEST_DIR/requirements.md"
    done
    cp templates/brief.md "$TEST_DIR/brief.md"

    run bash scripts/progress.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    # 5/9 = ~55% → filled=5 of 10 bar chars → should have both # and -
    [[ "$output" == *"#"* ]]
    [[ "$output" == *"-"* ]]
}

@test "progress.sh --proposal resolves paths correctly" {
    mkdir -p "$TEST_DIR/proposals/test-proj"
    cp templates/requirements.md "$TEST_DIR/proposals/test-proj/requirements.md"
    cp templates/brief.md "$TEST_DIR/proposals/test-proj/brief.md"

    # progress.sh uses proposals/$NAME/ relative path, so we need to run from
    # a directory that has the proposals/ subdirectory
    cd "$TEST_DIR"
    run bash "$OLDPWD/scripts/progress.sh" --proposal test-proj
    cd "$OLDPWD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"0/9 complete"* ]]
}
