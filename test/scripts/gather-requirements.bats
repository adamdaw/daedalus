#!/usr/bin/env bats
# gather-requirements.bats — Unit tests for scripts/gather-requirements.sh
#
# Standards:
#   bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core
#   TAP (Test Anything Protocol) — https://testanything.org
#   ISO/IEC/IEEE 29148:2018 — https://www.iso.org/standard/72089.html
#
# Run: bats test/scripts/gather-requirements.bats
#   or: make test-scripts
#
# Note: section functions set global variables, so input is redirected via
# heredoc (not piped) to avoid running the function in a subshell.

setup() {
    source scripts/gather-requirements.sh --source-only
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
}

# ---------------------------------------------------------------------------
# --help
# ---------------------------------------------------------------------------

@test "--help exits 0 and shows usage" {
    run bash scripts/gather-requirements.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"ISO/IEC/IEEE 29148:2018"* ]]
}

# ---------------------------------------------------------------------------
# §01 — Purpose and Scope
# ---------------------------------------------------------------------------

@test "gather_req_01 sets SYS_NAME, SYS_PURPOSE, SYS_IN_SCOPE, SYS_OUT_SCOPE" {
    gather_req_01 2>/dev/null <<'INPUT'
My System
Manage tasks
Task CRUD
Mobile apps
INPUT
    [ "$SYS_NAME" = "My System" ]
    [ "$SYS_PURPOSE" = "Manage tasks" ]
    [ "$SYS_IN_SCOPE" = "Task CRUD" ]
    [ "$SYS_OUT_SCOPE" = "Mobile apps" ]
}

# ---------------------------------------------------------------------------
# §02 — Stakeholders
# ---------------------------------------------------------------------------

@test "gather_req_02 builds STK_ROWS with STK-01 ID" {
    gather_req_02 2>/dev/null <<'INPUT'
Dev
Engineering
Build features
High
n
INPUT
    [[ "$STK_ROWS" == *"STK-01"* ]]
    [[ "$STK_ROWS" == *"Dev"* ]]
    [[ "$STK_ROWS" == *"Engineering"* ]]
    [[ "$STK_ROWS" == *"High"* ]]
}

@test "gather_req_02 handles empty role (zero stakeholders)" {
    gather_req_02 2>/dev/null <<'INPUT'

INPUT
    [ -z "$STK_ROWS" ]
}

# ---------------------------------------------------------------------------
# §03 — Business Requirements
# ---------------------------------------------------------------------------

@test "gather_req_03 builds BR_ROWS with BR-01 ID" {
    gather_req_03 2>/dev/null <<'INPUT'
Increase revenue
Revenue up 10%
M
n
INPUT
    [[ "$BR_ROWS" == *"BR-01"* ]]
    [[ "$BR_ROWS" == *"Increase revenue"* ]]
    [[ "$BR_ROWS" == *"M"* ]]
}

# ---------------------------------------------------------------------------
# §04 — Functional Requirements
# ---------------------------------------------------------------------------

@test "gather_req_04 builds FR_CONTENT with feature area heading and FR-01 story" {
    gather_req_04 2>/dev/null <<'INPUT'
Auth
user
log in
access dashboard
M
n
n
INPUT
    [[ "$FR_CONTENT" == *"### Auth"* ]]
    [[ "$FR_CONTENT" == *"FR-01"* ]]
    [[ "$FR_CONTENT" == *"As a user"* ]]
    [[ "$FR_CONTENT" == *"I want log in"* ]]
}

@test "gather_req_04 handles empty area name (zero features)" {
    gather_req_04 2>/dev/null <<'INPUT'

INPUT
    [ -z "$FR_CONTENT" ]
}

# ---------------------------------------------------------------------------
# §05 — Non-Functional Requirements
# ---------------------------------------------------------------------------

@test "gather_req_05 builds NFR_ROWS with NFR-01 ID" {
    gather_req_05 2>/dev/null <<'INPUT'
Performance Efficiency
Fast responses
p95 < 300ms
M
n
INPUT
    [[ "$NFR_ROWS" == *"NFR-01"* ]]
    [[ "$NFR_ROWS" == *"Performance Efficiency"* ]]
    [[ "$NFR_ROWS" == *"M"* ]]
}

# ---------------------------------------------------------------------------
# §06 — Constraints
# ---------------------------------------------------------------------------

@test "gather_req_06 builds TC_ROWS and OC_ROWS" {
    gather_req_06 2>/dev/null <<'INPUT'
Must use AWS
Approved provider
n
Must comply with GDPR
EU data rules
n
INPUT
    [[ "$TC_ROWS" == *"TC-01"* ]]
    [[ "$TC_ROWS" == *"Must use AWS"* ]]
    [[ "$OC_ROWS" == *"OC-01"* ]]
    [[ "$OC_ROWS" == *"Must comply with GDPR"* ]]
}

# ---------------------------------------------------------------------------
# §07 — Assumptions and Dependencies
# ---------------------------------------------------------------------------

@test "gather_req_07 builds AD_ROWS with A-01 for assumptions and D-01 for dependencies" {
    gather_req_07 2>/dev/null <<'INPUT'
Assumption
API is stable
Feature descoped
y
Dependency
SendGrid API
No email
n
INPUT
    [[ "$AD_ROWS" == *"A-01"* ]]
    [[ "$AD_ROWS" == *"Assumption"* ]]
    [[ "$AD_ROWS" == *"D-01"* ]]
    [[ "$AD_ROWS" == *"Dependency"* ]]
}

# ---------------------------------------------------------------------------
# §08 — Acceptance Criteria
# ---------------------------------------------------------------------------

@test "gather_req_08 builds AC_ROWS with AC-01 ID" {
    gather_req_08 2>/dev/null <<'INPUT'
FR-01
User on registration page
User submits valid email
Account is created
Test
n
INPUT
    [[ "$AC_ROWS" == *"AC-01"* ]]
    [[ "$AC_ROWS" == *"FR-01"* ]]
    [[ "$AC_ROWS" == *"Test"* ]]
}

# ---------------------------------------------------------------------------
# §09 — Requirements Traceability Matrix
# ---------------------------------------------------------------------------

@test "gather_req_09 builds RTM_ROWS" {
    gather_req_09 2>/dev/null <<'INPUT'
FR-01
User registration
§1, §6
n
INPUT
    [[ "$RTM_ROWS" == *"FR-01"* ]]
    [[ "$RTM_ROWS" == *"User registration"* ]]
    [[ "$RTM_ROWS" == *"Traced"* ]]
}

# ---------------------------------------------------------------------------
# write_output — markdown generation
# ---------------------------------------------------------------------------

@test "write_output produces valid markdown with all section headings" {
    # Set all global variables that write_output expects
    SYS_NAME="Test System"
    SYS_PURPOSE="Test purpose"
    SYS_IN_SCOPE="Everything"
    SYS_OUT_SCOPE="Nothing"
    STK_ROWS="| STK-01 | Dev | Eng | Build | High |"$'\n'
    BR_ROWS="| BR-01 | Goal | Criterion | M |"$'\n'
    FR_CONTENT="### Auth"$'\n'"| ID | User Story | Priority |"$'\n'"| --- | --- | --- |"$'\n'"| FR-01 | As a user, I want login, so that access | M |"$'\n'
    NFR_ROWS="| NFR-01 | Performance | Fast | p95 < 300ms | M |"$'\n'
    TC_ROWS="| TC-01 | AWS | Approved |"$'\n'
    OC_ROWS="| OC-01 | GDPR | EU data |"$'\n'
    AD_ROWS="| A-01 | Assumption | API stable | Descope |"$'\n'
    AC_ROWS="| AC-01 | FR-01 | Given | When | Then | Test |"$'\n'
    RTM_ROWS="| FR-01 | Registration | §1, §6 | Traced |"$'\n'

    OUTPUT="$TEST_DIR/requirements.md"
    write_output

    [ -f "$OUTPUT" ]
    grep -q "^## 01 — Purpose and Scope" "$OUTPUT"
    grep -q "^## 02 — Stakeholders" "$OUTPUT"
    grep -q "^## 03 — Business Requirements" "$OUTPUT"
    grep -q "^## 04 — Functional Requirements" "$OUTPUT"
    grep -q "^## 05 — Non-Functional Requirements" "$OUTPUT"
    grep -q "^## 06 — Constraints" "$OUTPUT"
    grep -q "^## 07 — Assumptions and Dependencies" "$OUTPUT"
    grep -q "^## 08 — Acceptance Criteria" "$OUTPUT"
    grep -q "^## 09 — Requirements Traceability Matrix" "$OUTPUT"
    grep -q "Status: complete" "$OUTPUT"
    grep -q "Test System" "$OUTPUT"
}

# ---------------------------------------------------------------------------
# Full pipeline — fixture-driven end-to-end
# ---------------------------------------------------------------------------

@test "full pipeline produces valid output from fixture answers" {
    local tmpfile="$TEST_DIR/requirements.md"
    grep -v '^#' test/fixtures/requirements-answers.txt | \
        bash scripts/gather-requirements.sh "$tmpfile" 2>/dev/null
    [ -f "$tmpfile" ]
    grep -q "^## 01 — Purpose and Scope" "$tmpfile"
    grep -q "^## 09 — Requirements Traceability Matrix" "$tmpfile"
    grep -q "Status: complete" "$tmpfile"
    grep -q "Task Tracker" "$tmpfile"
}
