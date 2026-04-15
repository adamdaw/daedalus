#!/usr/bin/env bats
# makefile.bats — Tests for Makefile targets
#
# Verifies that key Makefile targets produce expected outputs. This is the
# standard approach for testing Makefiles: exercise each target and verify
# its side effects (files created, output produced, exit codes).
#
# Standards:
#   bats-core — https://github.com/bats-core/bats-core
#   GNU Make Conventions — https://www.gnu.org/software/make/manual/html_node/Makefile-Conventions.html
#   Makefile.test pattern — https://github.com/box/Makefile.test
#
# Run: bats test/scripts/makefile.bats
#   or: make test-scripts

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
    # Clean up any test proposals created in the repo
    rm -rf proposals/bats-test-proposal 2>/dev/null || true
}

# ── Help target ─────────────────────────────────────────────────────────────

@test "make help lists all documented targets" {
    run make help
    [ "$status" -eq 0 ]
    [[ "$output" == *"build"* ]]
    [[ "$output" == *"html"* ]]
    [[ "$output" == *"docx"* ]]
    [[ "$output" == *"lint"* ]]
    [[ "$output" == *"spellcheck"* ]]
    [[ "$output" == *"shellcheck"* ]]
    [[ "$output" == *"validate"* ]]
    [[ "$output" == *"init"* ]]
    [[ "$output" == *"progress"* ]]
    [[ "$output" == *"ready"* ]]
    [[ "$output" == *"test-scripts"* ]]
    [[ "$output" == *"test-elicitation"* ]]
}

@test "make (bare) shows help by default" {
    run make
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

# ── Init target ─────────────────────────────────────────────────────────────

@test "make init scaffolds a proposal directory" {
    run make init NAME=bats-test-proposal TITLE="Bats Test" AUTHOR="Test"
    [ "$status" -eq 0 ]
    [ -d "proposals/bats-test-proposal" ]
    [ -f "proposals/bats-test-proposal/config.yaml" ]
    [ -f "proposals/bats-test-proposal/brief.md" ]
    [ -f "proposals/bats-test-proposal/requirements.md" ]
    [ -d "proposals/bats-test-proposal/markdown" ]
    [ -d "proposals/bats-test-proposal/images" ]
}

@test "make init rejects duplicate proposal name" {
    make init NAME=bats-test-proposal TITLE="Test" AUTHOR="Test" 2>/dev/null
    run make init NAME=bats-test-proposal TITLE="Test" AUTHOR="Test"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
}

@test "make init rejects invalid name characters" {
    run make init NAME="bad name!" TITLE="Test" AUTHOR="Test"
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid"* ]]
}

@test "make init sets title and author in config.yaml" {
    make init NAME=bats-test-proposal TITLE="My Title" AUTHOR="Jane Doe" 2>/dev/null
    run grep "title:" proposals/bats-test-proposal/config.yaml
    [[ "$output" == *"My Title"* ]]
    run grep "author:" proposals/bats-test-proposal/config.yaml
    [[ "$output" == *"Jane Doe"* ]]
}

# ── List target ─────────────────────────────────────────────────────────────

@test "make list shows created proposals" {
    make init NAME=bats-test-proposal TITLE="Listed Proposal" AUTHOR="Test" 2>/dev/null
    run make list
    [ "$status" -eq 0 ]
    [[ "$output" == *"bats-test-proposal"* ]]
    [[ "$output" == *"Listed Proposal"* ]]
}

# ── Progress target ─────────────────────────────────────────────────────────

@test "make progress works with proposal flag" {
    make init NAME=bats-test-proposal TITLE="Test" AUTHOR="Test" 2>/dev/null
    run make progress PROPOSAL=bats-test-proposal
    [ "$status" -eq 0 ]
    [[ "$output" == *"0/9 complete"* ]]
    [[ "$output" == *"0/11 complete"* ]]
}

# ── Validate targets ────────────────────────────────────────────────────────

@test "make validate-artifacts works with proposal flag" {
    make init NAME=bats-test-proposal TITLE="Test" AUTHOR="Test" 2>/dev/null
    run make validate-artifacts PROPOSAL=bats-test-proposal
    [ "$status" -eq 0 ]
    [[ "$output" == *"Section '01 — Purpose and Scope' present"* ]]
}

# ── Version target ──────────────────────────────────────────────────────────

@test "make version shows tool versions" {
    run make version
    [ "$status" -eq 0 ]
    [[ "$output" == *"pandoc:"* ]]
    [[ "$output" == *"node:"* ]]
    [[ "$output" == *"python:"* ]]
}

# ── Delete target ───────────────────────────────────────────────────────────

@test "make delete requires CONFIRM=yes" {
    make init NAME=bats-test-proposal TITLE="Test" AUTHOR="Test" 2>/dev/null
    run make delete PROPOSAL=bats-test-proposal
    [ "$status" -ne 0 ]
    [[ "$output" == *"CONFIRM=yes"* ]]
    [ -d "proposals/bats-test-proposal" ]
}

@test "make delete with CONFIRM=yes removes proposal" {
    make init NAME=bats-test-proposal TITLE="Test" AUTHOR="Test" 2>/dev/null
    run make delete PROPOSAL=bats-test-proposal CONFIRM=yes
    [ "$status" -eq 0 ]
    [ ! -d "proposals/bats-test-proposal" ]
}
