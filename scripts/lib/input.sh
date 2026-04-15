#!/usr/bin/env bash
# lib/input.sh — Shared I/O functions for interactive elicitation scripts
#
# Sourced by gather-requirements.sh and gather-brief.sh to avoid code duplication.
# All prompts go to stderr; values read from stdin. This separation allows
# piping fixture data for automated testing (stdin) while keeping prompts
# visible to interactive users (stderr).
#
# Standards:
#   Shell Script Best Practices — https://sharats.me/posts/shell-script-best-practices/
#   Bash Best Practices — https://bertvv.github.io/cheat-sheets/Bash.html

# Print prompt to stderr, read one line from stdin, return it on stdout.
ask() {
    printf '%s ' "$1" >&2
    local val
    IFS= read -r val || true
    printf '%s' "$val"
}

# Read multi-line input from stdin until a line containing only 'EOF'.
# Prompt goes to stderr. Returns all lines (including blank lines) joined
# with newlines.
ask_multiline() {
    printf '%s\n(End with EOF on its own line)\n' "$1" >&2
    local out="" line
    while IFS= read -r line; do
        [[ "$line" == "EOF" ]] && break
        out="${out}${line}"$'\n'
    done
    printf '%s' "$out"
}

# Ask yes/no question. Returns 0 (true) for y/Y/yes/Yes, 1 (false) otherwise.
# Default is no (empty input returns 1).
ask_yn() {
    local answer
    answer=$(ask "$1 [y/N]:")
    [[ "$answer" =~ ^[Yy] ]]
}
