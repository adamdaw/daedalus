#!/usr/bin/env bats
# validate-artifacts.bats — Unit tests for scripts/validate-artifacts.sh
#
# Standards:
#   bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core
#   TAP (Test Anything Protocol) — https://testanything.org
#
# Run: bats test/scripts/validate-artifacts.bats
#   or: make test-scripts

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "validate-artifacts.sh --help exits 0 and shows usage" {
    run bash scripts/validate-artifacts.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"ISO/IEC/IEEE 29148"* ]]
}

@test "validate-artifacts.sh fails when requirements.md is missing" {
    cp templates/brief.md "$TEST_DIR/brief.md"
    run bash scripts/validate-artifacts.sh \
        --requirements "$TEST_DIR/nonexistent.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "validate-artifacts.sh fails when brief.md is missing" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    run bash scripts/validate-artifacts.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/nonexistent.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "validate-artifacts.sh passes with valid templates (warns about empty sections)" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"
    run bash scripts/validate-artifacts.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Section '01 — Purpose and Scope' present"* ]]
    [[ "$output" == *"Section '11 — Risks and Technical Debt' present"* ]]
}

@test "validate-artifacts.sh detects missing section" {
    # Create a requirements.md with a section removed
    grep -v "^## 05" templates/requirements.md > "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"
    run bash scripts/validate-artifacts.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Non-Functional Requirements' missing"* ]]
}

@test "validate-artifacts.sh --ready runs cross-document checks" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"
    run bash scripts/validate-artifacts.sh --ready \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Readiness checks"* ]]
}

@test "validate-artifacts.sh --ready passes with complete fixtures" {
    grep -v '^#' test/fixtures/requirements-answers.txt | \
        bash scripts/gather-requirements.sh "$TEST_DIR/requirements.md" 2>/dev/null
    cd "$TEST_DIR"
    grep -v '^#' "$OLDPWD/test/fixtures/brief-answers.txt" | \
        bash "$OLDPWD/scripts/gather-brief.sh" brief.md 2>/dev/null
    cd "$OLDPWD"

    run bash scripts/validate-artifacts.sh --ready \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"All sections marked complete"* ]]
}
