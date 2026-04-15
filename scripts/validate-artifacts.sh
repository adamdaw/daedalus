#!/usr/bin/env bash
# validate-artifacts.sh — validates structure of requirements.md and brief.md
# Usage: validate-artifacts.sh [--requirements FILE] [--brief FILE]
# Exit 0 if valid, 1 if any blocking errors.
#
# Standards:
#   ISO/IEC/IEEE 29148:2018 — requirements specification structure
#   arc42 §1–11 — architecture documentation structure

set -euo pipefail

REQUIREMENTS="requirements.md"
BRIEF="brief.md"
errors=0
warnings=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --requirements) REQUIREMENTS="$2"; shift 2 ;;
        --brief)        BRIEF="$2";        shift 2 ;;
        *) echo "Usage: $0 [--requirements FILE] [--brief FILE]" >&2; exit 1 ;;
    esac
done

err()  { echo "  ERROR: $*"; ((errors++));   }
warn() { echo "  WARN:  $*"; ((warnings++)); }
ok()   { echo "  OK:    $*"; }

# --- requirements.md ---

echo "Validating ${REQUIREMENTS}..."

if [[ ! -f "$REQUIREMENTS" ]]; then
    err "${REQUIREMENTS} not found"
    echo ""
    echo "Result: ${errors} error(s) — run 'make gather-requirements' to create it"
    exit 1
fi

REQUIRED_REQ_SECTIONS=(
    "01 — Purpose and Scope"
    "02 — Stakeholders"
    "03 — Business Requirements"
    "04 — Functional Requirements"
    "05 — Non-Functional Requirements"
    "06 — Constraints"
    "07 — Assumptions and Dependencies"
    "08 — Acceptance Criteria"
    "09 — Requirements Traceability Matrix"
)

for section in "${REQUIRED_REQ_SECTIONS[@]}"; do
    if grep -q "^## ${section}" "$REQUIREMENTS"; then
        ok "Section '${section}' present"
    else
        err "Section '${section}' missing"
    fi
done

# Check Status markers
empty_count=$(grep -c "Status: empty" "$REQUIREMENTS" || true)
complete_count=$(grep -c "Status: complete" "$REQUIREMENTS" || true)
if [[ $empty_count -gt 0 ]]; then
    warn "${empty_count} section(s) still marked 'Status: empty' in ${REQUIREMENTS}"
fi
if [[ $complete_count -gt 0 ]]; then
    ok "${complete_count} section(s) marked 'Status: complete'"
fi

# Check for obviously empty table rows (| | | pattern — all cells blank)
empty_rows=$(grep -cP '^\|\s*\|\s*\|' "$REQUIREMENTS" || true)
if [[ $empty_rows -gt 0 ]]; then
    warn "${empty_rows} potentially empty table row(s) in ${REQUIREMENTS}"
fi

# Check that Must requirements have acceptance criteria
must_count=$(grep -cP '\|\s*(M|Must)\s*\|' "$REQUIREMENTS" || true)
ac_count=$(grep -c "^| AC-" "$REQUIREMENTS" || true)
if [[ $must_count -gt 0 && $ac_count -eq 0 ]]; then
    warn "${must_count} Must requirement(s) found but no acceptance criteria (AC-*) rows"
fi

echo ""

# --- brief.md ---

echo "Validating ${BRIEF}..."

if [[ ! -f "$BRIEF" ]]; then
    err "${BRIEF} not found"
    echo ""
    echo "Result: ${errors} error(s) — run 'make gather-brief' to create it"
    exit 1
fi

REQUIRED_BRIEF_SECTIONS=(
    "01 — Introduction and Goals"
    "02 — Constraints"
    "03 — Context and Scope"
    "04 — Solution Strategy"
    "05 — Building Block View"
    "06 — Runtime View"
    "07 — Deployment View"
    "08 — Cross-cutting Concepts"
    "09 — Architecture Decisions"
    "10 — Quality Requirements"
    "11 — Risks and Technical Debt"
)

for section in "${REQUIRED_BRIEF_SECTIONS[@]}"; do
    if grep -q "^## ${section}" "$BRIEF"; then
        ok "Section '${section}' present"
    else
        err "Section '${section}' missing"
    fi
done

empty_count=$(grep -c "Status: empty" "$BRIEF" || true)
complete_count=$(grep -c "Status: complete" "$BRIEF" || true)
if [[ $empty_count -gt 0 ]]; then
    warn "${empty_count} section(s) still marked 'Status: empty' in ${BRIEF}"
fi
if [[ $complete_count -gt 0 ]]; then
    ok "${complete_count} section(s) marked 'Status: complete'"
fi

empty_rows=$(grep -cP '^\|\s*\|\s*\|' "$BRIEF" || true)
if [[ $empty_rows -gt 0 ]]; then
    warn "${empty_rows} potentially empty table row(s) in ${BRIEF}"
fi

echo ""

# --- Summary ---

if [[ $errors -gt 0 ]]; then
    echo "Result: ${errors} error(s), ${warnings} warning(s) — fix errors before running assemble"
    exit 1
else
    echo "Result: valid — ${warnings} warning(s)"
    exit 0
fi
