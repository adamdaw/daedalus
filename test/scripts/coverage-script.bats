#!/usr/bin/env bats
# coverage-script.bats — Unit tests for scripts/coverage.sh
#
# Standards:
#   bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core
#   TAP (Test Anything Protocol) — https://testanything.org
#
# Run: bats test/scripts/coverage-script.bats
#   or: make test-scripts

@test "coverage.sh --help exits 0 and shows usage" {
    run bash scripts/coverage.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"bashcov"* ]]
}

@test "coverage.sh -h exits 0 and shows usage" {
    run bash scripts/coverage.sh -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "coverage.sh unknown option exits with error" {
    run bash scripts/coverage.sh --bogus-flag
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "coverage.sh fails when ruby not found" {
    # Restrict PATH to exclude ruby
    PATH="/usr/bin:/bin" run bash scripts/coverage.sh
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "coverage.sh fails when bashcov not found" {
    # Use a PATH that has ruby but not bashcov (ruby is typically in /usr/bin)
    # Create a minimal PATH with ruby available but no bashcov
    TEMP_BIN="$(mktemp -d)"
    if command -v ruby >/dev/null 2>&1; then
        ln -s "$(command -v ruby)" "$TEMP_BIN/ruby"
    else
        # If ruby is not installed, skip gracefully — the ruby test above covers that
        skip "ruby not available on this system"
    fi
    PATH="$TEMP_BIN:/usr/bin:/bin" run bash scripts/coverage.sh
    rm -rf "$TEMP_BIN"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}
