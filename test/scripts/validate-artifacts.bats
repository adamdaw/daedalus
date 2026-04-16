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

@test "validate-artifacts.sh unknown option exits with non-zero status" {
    run bash scripts/validate-artifacts.sh --bogus-flag
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "validate-artifacts.sh readiness detects incomplete sections" {
    # Create files with a mix of empty and complete sections
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    for num in 01 02 03 04 05; do
        sed -i "/^## ${num} /,/^---$/{s/Status: empty/Status: complete/}" "$TEST_DIR/requirements.md"
    done
    cp templates/brief.md "$TEST_DIR/brief.md"

    run bash scripts/validate-artifacts.sh --ready \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Readiness checks"* ]]
    [[ "$output" == *"not yet complete"* ]]
}

@test "validate-artifacts.sh readiness warns when Must requirements lack acceptance criteria" {
    # Create requirements.md with Must rows but no AC- rows
    cat > "$TEST_DIR/requirements.md" << 'FIXTURE'
# Requirements Specification

---

## 01 — Purpose and Scope
<!-- Status: complete -->
Purpose text here.

---

## 02 — Stakeholders
<!-- Status: complete -->
| ID | Role | Organisation / Context | Goals | Priority |
| --- | --- | --- | --- | --- |
| STK-01 | User | Internal | Use the system | High |

---

## 03 — Business Requirements
<!-- Status: complete -->
| ID | Goal | Success Criterion | Priority |
| --- | --- | --- | --- |
| BR-01 | Improve workflow | Reduce time by 50% | M |

---

## 04 — Functional Requirements
<!-- Status: complete -->
| ID | User Story | Priority |
| --- | --- | --- |
| FR-01 | As a user I want X so that Y | M |
| FR-02 | As a user I want Z so that W | Must |

---

## 05 — Non-Functional Requirements
<!-- Status: complete -->
| ID | ISO 25010 Category | Description | Measurable Criterion | Priority |
| --- | --- | --- | --- | --- |
| NFR-01 | Performance | Fast | Under 200ms | M |

---

## 06 — Constraints
<!-- Status: complete -->
Technical constraints here.

---

## 07 — Assumptions and Dependencies
<!-- Status: complete -->
Assumptions here.

---

## 08 — Acceptance Criteria
<!-- Status: complete -->
| ID | Requirement Ref | Given | When | Then | Verification |
| --- | --- | --- | --- | --- | --- |

---

## 09 — Requirements Traceability Matrix
<!-- Status: complete -->
| Requirement ID | Summary | arc42 Section(s) | Status |
| --- | --- | --- | --- |
| FR-01 | Feature X | §4 | Traced |
FIXTURE
    cp templates/brief.md "$TEST_DIR/brief.md"

    run bash scripts/validate-artifacts.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Must requirement"* ]]
}

@test "validate-artifacts.sh readiness OK when Must requirements have sufficient acceptance criteria" {
    # Create requirements.md with Must rows AND matching AC- rows
    cat > "$TEST_DIR/requirements.md" << 'FIXTURE'
# Requirements Specification

---

## 01 — Purpose and Scope
<!-- Status: complete -->
Purpose text here.

---

## 02 — Stakeholders
<!-- Status: complete -->
| ID | Role | Organisation / Context | Goals | Priority |
| --- | --- | --- | --- | --- |

---

## 03 — Business Requirements
<!-- Status: complete -->
| ID | Goal | Success Criterion | Priority |
| --- | --- | --- | --- |

---

## 04 — Functional Requirements
<!-- Status: complete -->
| ID | User Story | Priority |
| --- | --- | --- |
| FR-01 | As a user I want X so that Y | M |

---

## 05 — Non-Functional Requirements
<!-- Status: complete -->
| ID | ISO 25010 Category | Description | Measurable Criterion | Priority |
| --- | --- | --- | --- | --- |

---

## 06 — Constraints
<!-- Status: complete -->

---

## 07 — Assumptions and Dependencies
<!-- Status: complete -->

---

## 08 — Acceptance Criteria
<!-- Status: complete -->
| ID | Requirement Ref | Given | When | Then | Verification |
| --- | --- | --- | --- | --- | --- |
| AC-01 | FR-01 | system is ready | user does X | result Y | Test |

---

## 09 — Requirements Traceability Matrix
<!-- Status: complete -->
| Requirement ID | Summary | arc42 Section(s) | Status |
| --- | --- | --- | --- |
| FR-01 | Feature X | §4 | Traced |
FIXTURE
    cp templates/brief.md "$TEST_DIR/brief.md"
    # Mark all brief sections complete
    for num in 01 02 03 04 05 06 07 08 09 10 11; do
        sed -i "/^## ${num} /,/^---$/{s/Status: empty/Status: complete/}" "$TEST_DIR/brief.md"
    done

    run bash scripts/validate-artifacts.sh --ready \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Readiness checks"* ]]
    [[ "$output" == *"Must requirements"*"covered by acceptance criteria"* ]]
}

@test "validate-artifacts.sh readiness warns when technology decisions lack ADRs" {
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    # Create brief.md with technology decisions in §04 but no ADRs in §09
    cat > "$TEST_DIR/brief.md" << 'FIXTURE'
# Project Brief

---

## 01 — Introduction and Goals
<!-- Status: complete -->
Goals here.

---

## 02 — Constraints
<!-- Status: complete -->

---

## 03 — Context and Scope
<!-- Status: complete -->

---

## 04 — Solution Strategy
<!-- Status: complete -->

### Technology Decisions
| Decision | Rationale | Quality Goal Addressed |
| --- | --- | --- |
| Python 3.12 | Best ecosystem | Maintainability |
| PostgreSQL | ACID compliance | Reliability |

---

## 05 — Building Block View
<!-- Status: complete -->

---

## 06 — Runtime View
<!-- Status: complete -->

---

## 07 — Deployment View
<!-- Status: complete -->

---

## 08 — Cross-cutting Concepts
<!-- Status: complete -->

---

## 09 — Architecture Decisions
<!-- Status: complete -->

### Decision Log
| ID | Title | Status | Date |
| --- | --- | --- | --- |

---

## 10 — Quality Requirements
<!-- Status: complete -->

---

## 11 — Risks and Technical Debt
<!-- Status: complete -->
FIXTURE

    run bash scripts/validate-artifacts.sh --ready \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ADR"* ]]
}

@test "validate-artifacts.sh readiness warns when requirements are Untraced in RTM" {
    # Create requirements.md with Untraced entries in RTM
    cat > "$TEST_DIR/requirements.md" << 'FIXTURE'
# Requirements Specification

---

## 01 — Purpose and Scope
<!-- Status: complete -->

---

## 02 — Stakeholders
<!-- Status: complete -->

---

## 03 — Business Requirements
<!-- Status: complete -->

---

## 04 — Functional Requirements
<!-- Status: complete -->

---

## 05 — Non-Functional Requirements
<!-- Status: complete -->

---

## 06 — Constraints
<!-- Status: complete -->

---

## 07 — Assumptions and Dependencies
<!-- Status: complete -->

---

## 08 — Acceptance Criteria
<!-- Status: complete -->

---

## 09 — Requirements Traceability Matrix
<!-- Status: complete -->
| Requirement ID | Summary | arc42 Section(s) | Status |
| --- | --- | --- | --- |
| FR-01 | Feature X | §4 | Traced |
| FR-02 | Feature Y | | Untraced |
| FR-03 | Feature Z | | Untraced |
FIXTURE
    cp templates/brief.md "$TEST_DIR/brief.md"
    for num in 01 02 03 04 05 06 07 08 09 10 11; do
        sed -i "/^## ${num} /,/^---$/{s/Status: empty/Status: complete/}" "$TEST_DIR/brief.md"
    done

    run bash scripts/validate-artifacts.sh --ready \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Untraced"* ]]
}

@test "validate-artifacts.sh detects empty table rows as warning" {
    # Create requirements.md with empty table rows (| | | pattern)
    cp templates/requirements.md "$TEST_DIR/requirements.md"
    # The template already has empty placeholder rows like "| | | |"
    # Add an obviously empty row
    sed -i '/^## 02 /,/^---$/{/^| STK-01/a\| | | | | |
}' "$TEST_DIR/requirements.md"
    cp templates/brief.md "$TEST_DIR/brief.md"

    run bash scripts/validate-artifacts.sh \
        --requirements "$TEST_DIR/requirements.md" \
        --brief "$TEST_DIR/brief.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"empty table row"* ]]
}

@test "validate-artifacts.sh readiness all sections complete and all checks pass gives clean output" {
    # Build complete fixtures using the answer files
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
    [[ "$output" == *"All requirements traced"* ]]
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
