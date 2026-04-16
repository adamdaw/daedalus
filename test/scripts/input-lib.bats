#!/usr/bin/env bats
# input-lib.bats — Unit tests for scripts/lib/input.sh
#
# Standards:
#   bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core
#   TAP (Test Anything Protocol) — https://testanything.org
#
# Run: bats test/scripts/input-lib.bats
#   or: make test-scripts

# ---------------------------------------------------------------------------
# ask() — single-line input
# ---------------------------------------------------------------------------

@test "ask reads a single line from stdin and returns it" {
    source scripts/lib/input.sh
    result=$(echo "hello world" | ask "Prompt:")
    [ "$result" = "hello world" ]
}

@test "ask returns empty string for empty input" {
    source scripts/lib/input.sh
    result=$(echo "" | ask "Prompt:")
    [ "$result" = "" ]
}

@test "ask preserves leading and trailing spaces" {
    source scripts/lib/input.sh
    result=$(echo "  spaced value  " | ask "Prompt:")
    [ "$result" = "  spaced value  " ]
}

@test "ask prints prompt to stderr not stdout" {
    source scripts/lib/input.sh
    # Capture stderr and stdout separately
    stdout=$(echo "val" | ask "MyPrompt:" 2>/dev/null)
    stderr=$(echo "val" | ask "MyPrompt:" 2>&1 >/dev/null)
    # stdout should contain only the value, no prompt text
    [ "$stdout" = "val" ]
    # stderr should contain the prompt text
    [[ "$stderr" == *"MyPrompt:"* ]]
}

# ---------------------------------------------------------------------------
# ask_multiline() — multi-line input until EOF sentinel
# ---------------------------------------------------------------------------

@test "ask_multiline reads until EOF sentinel" {
    source scripts/lib/input.sh
    result=$(printf 'line one\nline two\nEOF\n' | ask_multiline "Enter text:")
    [[ "$result" == *"line one"* ]]
    [[ "$result" == *"line two"* ]]
}

@test "ask_multiline returns empty when EOF is the first line" {
    source scripts/lib/input.sh
    result=$(printf 'EOF\n' | ask_multiline "Enter text:")
    [ -z "$result" ]
}

@test "ask_multiline preserves blank lines in content" {
    source scripts/lib/input.sh
    result=$(printf 'first\n\nsecond\nEOF\n' | ask_multiline "Enter text:")
    # The output should contain both lines with a blank line between them
    line_count=$(printf '%s' "$result" | wc -l)
    # 3 lines: "first", "", "second" (trailing newline adds one more from the function)
    [ "$line_count" -ge 2 ]
    [[ "$result" == *"first"* ]]
    [[ "$result" == *"second"* ]]
}

# ---------------------------------------------------------------------------
# ask_yn() — yes/no questions
# ---------------------------------------------------------------------------

@test "ask_yn returns 0 for y, Y, and yes" {
    source scripts/lib/input.sh
    echo "y" | ask_yn "Continue?" 2>/dev/null
    echo "Y" | ask_yn "Continue?" 2>/dev/null
    echo "yes" | ask_yn "Continue?" 2>/dev/null
}

@test "ask_yn returns 1 for n, N, empty, and no" {
    source scripts/lib/input.sh
    ! (echo "n" | ask_yn "Continue?" 2>/dev/null)
    ! (echo "N" | ask_yn "Continue?" 2>/dev/null)
    ! (echo "" | ask_yn "Continue?" 2>/dev/null)
    ! (echo "no" | ask_yn "Continue?" 2>/dev/null)
}
