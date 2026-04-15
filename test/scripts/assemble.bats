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
