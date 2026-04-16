#!/usr/bin/env bash
# Requires bash 3.0+ (local, [[ ]], set -uo pipefail)
# validate-artifacts.sh — validates structure of requirements.md and brief.md
# Usage: validate-artifacts.sh [--requirements FILE] [--brief FILE]
# Exit 0 if valid, 1 if any blocking errors.
#
# Standards:
#   ISO/IEC/IEEE 29148:2018 — requirements specification structure
#   arc42 §1–11 — architecture documentation structure

set -uo pipefail

REQUIREMENTS="requirements.md"
BRIEF="brief.md"
READY=false
errors=0
warnings=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --requirements) REQUIREMENTS="$2"; shift 2 ;;
        --brief)        BRIEF="$2";        shift 2 ;;
        --ready)        READY=true;        shift ;;
        -h|--help)
            cat <<'HELPEOF'
Usage: bash scripts/validate-artifacts.sh [--requirements FILE] [--brief FILE] [--ready]

Validate the structure and completeness of requirements.md and brief.md.

Options:
  --requirements FILE    Path to requirements.md (default: requirements.md)
  --brief FILE           Path to brief.md (default: brief.md)
  --ready                Enable cross-document consistency checks (pre-authoring gate)

Checks:
  Basic: 9 required sections in requirements.md, 11 in brief.md, Status markers
  Ready: Must requirements have acceptance criteria, quality goals have scenarios,
         technology decisions have ADRs, RTM completeness

Standards:
  ISO/IEC/IEEE 29148:2018 — https://www.iso.org/standard/72089.html
  arc42 §1–11 — https://docs.arc42.org
HELPEOF
            exit 0
            ;;
        *) echo "Usage: $0 [--requirements FILE] [--brief FILE] [--ready]" >&2; exit 1 ;;
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

# --- Readiness checks (cross-document consistency, --ready flag) ---

if [[ "$READY" == true && -f "$REQUIREMENTS" && -f "$BRIEF" ]]; then
    echo "Readiness checks..."

    # 1. All sections must be complete
    req_empty=$(grep -c "Status: empty" "$REQUIREMENTS" || true)
    req_ip=$(grep -c "Status: in-progress" "$REQUIREMENTS" || true)
    brief_empty=$(grep -c "Status: empty" "$BRIEF" || true)
    brief_ip=$(grep -c "Status: in-progress" "$BRIEF" || true)
    incomplete=$((req_empty + req_ip + brief_empty + brief_ip))
    if [[ $incomplete -gt 0 ]]; then
        warn "${incomplete} section(s) not yet complete across both files"
    else
        ok "All sections marked complete"
    fi

    # 2. Must requirements have acceptance criteria
    must_count=$(grep -cP '\|\s*(M|Must)\s*\|' "$REQUIREMENTS" || true)
    ac_count=$(grep -c "^| AC-" "$REQUIREMENTS" || true)
    if [[ $must_count -gt 0 ]]; then
        if [[ $ac_count -ge $must_count ]]; then
            ok "Must requirements (${must_count}) covered by acceptance criteria (${ac_count})"
        elif [[ $ac_count -gt 0 ]]; then
            warn "Only ${ac_count} acceptance criterion/criteria for ${must_count} Must requirement(s)"
        else
            warn "${must_count} Must requirement(s) but no acceptance criteria rows"
        fi
    fi

    # 3. Quality goals in brief §01 have quality scenarios in brief §10
    # Extract quality goals from §01 Quality Goals table
    goal_count=$(awk '/^## 01 /,/^---/' "$BRIEF" | grep -cP '^\| \d' || true)
    scenario_count=$(awk '/^## 10 /,/^---/' "$BRIEF" | grep -cP '^\| QS-' || true)
    if [[ $goal_count -gt 0 ]]; then
        if [[ $scenario_count -ge $goal_count ]]; then
            ok "Quality goals (${goal_count}) covered by scenarios (${scenario_count})"
        else
            warn "Only ${scenario_count} quality scenario(s) for ${goal_count} quality goal(s)"
        fi
    fi

    # 4. Technology decisions in brief §04 have ADR drafts in brief §09
    tech_decisions=$(awk '/^## 04 /,/^---/' "$BRIEF" | grep -cP '^\| [A-Z]' || true)
    adr_count=$(awk '/^## 09 /,/^## (1[0-9]|References)/' "$BRIEF" | grep -cP '^#### ADR-' || true)
    if [[ $tech_decisions -gt 0 ]]; then
        if [[ $adr_count -ge $tech_decisions ]]; then
            ok "Technology decisions (${tech_decisions}) covered by ADRs (${adr_count})"
        else
            warn "Only ${adr_count} ADR(s) for ${tech_decisions} technology decision(s)"
        fi
    fi

    # 5. RTM completeness — check for Untraced entries
    untraced=$(grep -c "Untraced" "$REQUIREMENTS" || true)
    if [[ $untraced -gt 0 ]]; then
        warn "${untraced} requirement(s) still marked 'Untraced' in RTM"
    else
        ok "All requirements traced in RTM"
    fi

    echo ""
fi

# --- Summary ---

if [[ $errors -gt 0 ]]; then
    echo "Result: ${errors} error(s), ${warnings} warning(s) — fix errors before proceeding"
    exit 1
elif [[ "$READY" == true && $warnings -gt 0 ]]; then
    echo "Result: ${warnings} warning(s) — review before starting spec authoring"
    exit 0
else
    echo "Result: valid — ${warnings} warning(s)"
    exit 0
fi
