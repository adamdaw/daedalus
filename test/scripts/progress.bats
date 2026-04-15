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
