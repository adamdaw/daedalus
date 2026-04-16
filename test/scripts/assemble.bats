#!/usr/bin/env bats
# assemble.bats — Unit tests for scripts/assemble.sh
#
# Standards:
#   bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core
#   TAP (Test Anything Protocol) — https://testanything.org
#
# Run: bats test/scripts/assemble.bats
#   or: make test-scripts

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR

    # Generate complete artifacts from fixtures for assembly tests
    grep -v '^#' test/fixtures/requirements-answers.txt | \
        bash scripts/gather-requirements.sh "$TEST_DIR/requirements.md" 2>/dev/null
    cd "$TEST_DIR"
    grep -v '^#' "$OLDPWD/test/fixtures/brief-answers.txt" | \
        bash "$OLDPWD/scripts/gather-brief.sh" brief.md 2>/dev/null
    cd "$OLDPWD"

    mkdir -p "$TEST_DIR/markdown"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "assemble.sh --help exits 0 and shows usage" {
    run bash scripts/assemble.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"arc42"* ]]
}

@test "assemble.sh produces 12 output files" {
    run bash scripts/assemble.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md" \
        --output "$TEST_DIR/markdown"
    [ "$status" -eq 0 ]

    file_count=$(find "$TEST_DIR/markdown" -maxdepth 1 -name '*.md' | wc -l)
    [ "$file_count" -eq 12 ]
}

@test "assemble.sh output files are non-empty" {
    bash scripts/assemble.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md" \
        --output "$TEST_DIR/markdown"

    for f in "$TEST_DIR/markdown"/*.md; do
        [ -s "$f" ] || fail "$(basename "$f") is empty"
    done
}

@test "assemble.sh --proposal resolves paths correctly" {
    # Create proposal structure
    mkdir -p "$TEST_DIR/proposals/test-proj/markdown"
    cp "$TEST_DIR/requirements.md" "$TEST_DIR/proposals/test-proj/requirements.md"
    cp "$TEST_DIR/brief.md" "$TEST_DIR/proposals/test-proj/brief.md"

    cd "$TEST_DIR"
    run bash "$OLDPWD/scripts/assemble.sh" --proposal test-proj
    cd "$OLDPWD"
    [ "$status" -eq 0 ]

    file_count=$(find "$TEST_DIR/proposals/test-proj/markdown" -maxdepth 1 -name '*.md' | wc -l)
    [ "$file_count" -eq 12 ]
}

@test "assemble.sh fails when brief.md is missing" {
    run bash scripts/assemble.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/nonexistent-brief.md" \
        --output "$TEST_DIR/markdown"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "assemble.sh unknown option exits with error" {
    run bash scripts/assemble.sh --bogus-flag
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "assemble.sh output section 01 contains Introduction heading" {
    bash scripts/assemble.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md" \
        --output "$TEST_DIR/markdown"

    grep -q "Introduction and Goals" "$TEST_DIR/markdown/01_Introduction_and_Goals.md"
}

@test "assemble.sh output section 02 contains constraint content" {
    bash scripts/assemble.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md" \
        --output "$TEST_DIR/markdown"

    # The constraints file should have the Constraints heading
    grep -q "Constraints" "$TEST_DIR/markdown/02_Constraints.md"
}

@test "assemble.sh produces all 12 expected filenames" {
    bash scripts/assemble.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md" \
        --output "$TEST_DIR/markdown"

    # Check all 12 exact filenames
    [ -f "$TEST_DIR/markdown/01_Introduction_and_Goals.md" ]
    [ -f "$TEST_DIR/markdown/02_Constraints.md" ]
    [ -f "$TEST_DIR/markdown/03_Context_and_Scope.md" ]
    [ -f "$TEST_DIR/markdown/04_Solution_Strategy.md" ]
    [ -f "$TEST_DIR/markdown/05_Building_Block_View.md" ]
    [ -f "$TEST_DIR/markdown/06_Runtime_View.md" ]
    [ -f "$TEST_DIR/markdown/07_Deployment_View.md" ]
    [ -f "$TEST_DIR/markdown/08_Crosscutting_Concepts.md" ]
    [ -f "$TEST_DIR/markdown/09_Architecture_Decisions.md" ]
    [ -f "$TEST_DIR/markdown/10_Quality_Requirements.md" ]
    [ -f "$TEST_DIR/markdown/11_Risks_and_Technical_Debt.md" ]
    [ -f "$TEST_DIR/markdown/99_References.md" ]
}

@test "assemble.sh output contains expected section headings" {
    bash scripts/assemble.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md" \
        --output "$TEST_DIR/markdown"

    grep -q "Introduction" "$TEST_DIR/markdown/01_Introduction_and_Goals.md"
    grep -q "Constraints"  "$TEST_DIR/markdown/02_Constraints.md"
    grep -q "Context"      "$TEST_DIR/markdown/03_Context_and_Scope.md"
    grep -q "Risks"        "$TEST_DIR/markdown/11_Risks_and_Technical_Debt.md"
}
