#!/usr/bin/env bash
# gather-brief.sh — non-AI fallback for /gather-01 through /gather-11
# Interactive arc42 architecture elicitation. Reads from stdin — pipe answers for CI:
#   gather-brief.sh < test/fixtures/brief-answers.txt
#
# Usage: gather-brief.sh [OUTPUT_FILE]
#   OUTPUT_FILE defaults to brief.md in the current directory.
#   If requirements.md exists in the current directory, requirements/constraints
#   sections are noted as cross-referenced rather than re-gathered.
#
# Mermaid diagrams: enter diagram lines, then type EOF on its own line to finish.
#
# Standards:
#   arc42 §1–11 — https://docs.arc42.org
#   C4 Model — https://c4model.com
#   ISO 31000 risk management — https://www.iso.org/iso-31000-risk-management.html
#   Fowler Technical Debt Quadrant — https://martinfowler.com/bliki/TechnicalDebtQuadrant.html
#   ADR format (Nygard, 2011) — https://adr.github.io
#   ATAM quality scenarios — https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908

set -euo pipefail

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    cat <<'HELPEOF'
Usage: bash scripts/gather-brief.sh [OUTPUT_FILE]

Interactively gather architecture information for an arc42 brief covering
all 11 sections. If requirements.md exists in the current directory,
constraints and stakeholders are sourced from it to avoid duplication.

Arguments:
  OUTPUT_FILE    Path to write brief.md (default: brief.md)

Standards:
  arc42 — https://arc42.org
  C4 Model — https://c4model.com
  ISO 31000 — https://www.iso.org/iso-31000-risk-management.html

Non-AI fallback for /gather-01 through /gather-11.
Pipe fixture answers for CI: grep -v '^#' test/fixtures/brief-answers.txt | bash scripts/gather-brief.sh
HELPEOF
    exit 0
fi

OUTPUT="${1:-brief.md}"
HAS_REQ=false
[[ -f "requirements.md" ]] && HAS_REQ=true

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

ask() {
    printf '%s ' "$1" >&2
    local val
    IFS= read -r val
    printf '%s' "$val"
}

ask_multiline() {
    printf '%s\n(End with EOF on its own line)\n' "$1" >&2
    local out=""
    local line
    while IFS= read -r line; do
        [[ "$line" == "EOF" ]] && break
        out="${out}${line}"$'\n'
    done
    printf '%s' "$out"
}

ask_yn() {
    local answer
    answer=$(ask "$1 [y/N]:")
    [[ "$answer" =~ ^[Yy] ]]
}

# ---------------------------------------------------------------------------
# §01 — Introduction and Goals
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §01 Introduction and Goals ===" >&2

S01_OVERVIEW=$(ask_multiline "System overview (brief description of what the system is and does):")

if $HAS_REQ; then
    echo "  (Requirements, Quality Goals, and Stakeholders will be drawn from requirements.md)" >&2
    S01_REQ_NOTE="<!-- Requirements, Quality Goals, and Stakeholders sourced from requirements.md -->"
    S01_TABLES=""
else
    echo "  No requirements.md found — gathering requirements inline." >&2
    echo "  Requirements (leave Requirement blank to finish):" >&2
    S01_TABLES="### Requirements"$'\n'"<!-- SMART: Specific, Measurable, Achievable, Relevant, Time-bound -->"$'\n'"| ID | Requirement | Priority |"$'\n'"| --- | --- | --- |"$'\n'
    req_idx=1
    while true; do
        req=$(ask "  Requirement:")
        [[ -z "$req" ]] && break
        pri=$(ask "  Priority [High/Medium/Low]:")
        S01_TABLES="${S01_TABLES}| R-$(printf '%02d' $req_idx) | ${req} | ${pri} |"$'\n'
        ((req_idx++))
        ask_yn "  Add another?" || break
    done
    S01_TABLES="${S01_TABLES}"$'\n'"### Quality Goals"$'\n'"| Priority | Quality Goal | Motivation |"$'\n'"| --- | --- | --- |"$'\n'
    qg_idx=1
    while true; do
        goal=$(ask "  Quality goal:")
        [[ -z "$goal" ]] && break
        mot=$(ask "  Motivation:")
        S01_TABLES="${S01_TABLES}| ${qg_idx} | ${goal} | ${mot} |"$'\n'
        ((qg_idx++))
        ask_yn "  Add another?" || break
    done
    S01_TABLES="${S01_TABLES}"$'\n'"### Stakeholders"$'\n'"| Role | Expectations |"$'\n'"| --- | --- |"$'\n'
    while true; do
        role=$(ask "  Role:")
        [[ -z "$role" ]] && break
        exp=$(ask "  Expectations:")
        S01_TABLES="${S01_TABLES}| ${role} | ${exp} |"$'\n'
        ask_yn "  Add another?" || break
    done
    S01_REQ_NOTE=""
fi

# ---------------------------------------------------------------------------
# §02 — Constraints
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §02 Constraints ===" >&2

if $HAS_REQ; then
    echo "  (Technical and Organisational Constraints sourced from requirements.md)" >&2
    S02_CONSTRAINTS="<!-- Technical and Organisational Constraints sourced from requirements.md §06 -->"
else
    echo "  Technical constraints (leave Constraint blank to finish):" >&2
    S02_CONSTRAINTS="### Technical Constraints"$'\n'"| Constraint | Background / Motivation |"$'\n'"| --- | --- |"$'\n'
    while true; do
        con=$(ask "  Constraint:")
        [[ -z "$con" ]] && break
        bg=$(ask "  Background / Motivation:")
        S02_CONSTRAINTS="${S02_CONSTRAINTS}| ${con} | ${bg} |"$'\n'
        ask_yn "  Add another?" || break
    done
    S02_CONSTRAINTS="${S02_CONSTRAINTS}"$'\n'"### Organisational Constraints"$'\n'"| Constraint | Background / Motivation |"$'\n'"| --- | --- |"$'\n'
    while true; do
        con=$(ask "  Constraint:")
        [[ -z "$con" ]] && break
        bg=$(ask "  Background / Motivation:")
        S02_CONSTRAINTS="${S02_CONSTRAINTS}| ${con} | ${bg} |"$'\n'
        ask_yn "  Add another?" || break
    done
fi

echo "  Conventions (leave Convention blank to finish):" >&2
S02_CONVENTIONS="### Conventions"$'\n'"| Convention | Background / Motivation |"$'\n'"| --- | --- |"$'\n'
while true; do
    con=$(ask "  Convention:")
    [[ -z "$con" ]] && break
    bg=$(ask "  Background / Motivation:")
    S02_CONVENTIONS="${S02_CONVENTIONS}| ${con} | ${bg} |"$'\n'
    ask_yn "  Add another?" || break
done

# ---------------------------------------------------------------------------
# §03 — Context and Scope
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §03 Context and Scope ===" >&2

S03_DIAGRAM=$(ask_multiline "Context diagram — enter Mermaid flowchart TD code:")
S03_DIAGRAM="\`\`\`mermaid"$'\n'"${S03_DIAGRAM}"$'\n'"\`\`\`"

echo "  External Actors (leave Actor blank to finish):" >&2
S03_ACTORS="| Actor | Role | Interaction with System |"$'\n'"| --- | --- | --- |"$'\n'
while true; do
    actor=$(ask "  Actor:")
    [[ -z "$actor" ]] && break
    role=$(ask "  Role:")
    inter=$(ask "  Interaction:")
    S03_ACTORS="${S03_ACTORS}| ${actor} | ${role} | ${inter} |"$'\n'
    ask_yn "  Add another actor?" || break
done

echo "  External Systems (leave System blank to finish):" >&2
S03_SYSTEMS="| System | Purpose | Data / Events Exchanged |"$'\n'"| --- | --- | --- |"$'\n'
while true; do
    sys=$(ask "  System:")
    [[ -z "$sys" ]] && break
    purpose=$(ask "  Purpose:")
    data=$(ask "  Data / Events exchanged:")
    S03_SYSTEMS="${S03_SYSTEMS}| ${sys} | ${purpose} | ${data} |"$'\n'
    ask_yn "  Add another system?" || break
done

S03_OOS=$(ask "Out of scope (one line):")

# ---------------------------------------------------------------------------
# §04 — Solution Strategy
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §04 Solution Strategy ===" >&2

echo "  Technology decisions (leave Decision blank to finish):" >&2
S04_DECISIONS="| Decision | Rationale | Quality Goal Addressed |"$'\n'"| --- | --- | --- |"$'\n'
while true; do
    dec=$(ask "  Decision:")
    [[ -z "$dec" ]] && break
    rat=$(ask "  Rationale:")
    qg=$(ask "  Quality goal addressed:")
    S04_DECISIONS="${S04_DECISIONS}| ${dec} | ${rat} | ${qg} |"$'\n'
    ask_yn "  Add another decision?" || break
done

S04_APPROACH=$(ask_multiline "Architectural approach (describe the overall structure — e.g., monolith, microservices, event-driven):")
S04_QUALITY=$(ask_multiline "How does the strategy achieve the quality goals?")

# ---------------------------------------------------------------------------
# §05 — Building Block View
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §05 Building Block View ===" >&2

S05_DIAGRAM=$(ask_multiline "Container diagram — enter Mermaid flowchart TD code:")
S05_DIAGRAM="\`\`\`mermaid"$'\n'"${S05_DIAGRAM}"$'\n'"\`\`\`"

echo "  Containers / Level 1 blocks (leave Container blank to finish):" >&2
S05_L1="| Container | Technology | Responsibility |"$'\n'"| --- | --- | --- |"$'\n'
while true; do
    container=$(ask "  Container:")
    [[ -z "$container" ]] && break
    tech=$(ask "  Technology:")
    resp=$(ask "  Responsibility:")
    S05_L1="${S05_L1}| ${container} | ${tech} | ${resp} |"$'\n'
    ask_yn "  Add another container?" || break
done

echo "  Level 2 components for complex containers (leave Container blank to skip):" >&2
S05_L2="| Container | Component | Responsibility |"$'\n'"| --- | --- | --- |"$'\n'
while true; do
    container=$(ask "  Container (blank to skip L2):")
    [[ -z "$container" ]] && break
    comp=$(ask "  Component:")
    resp=$(ask "  Responsibility:")
    S05_L2="${S05_L2}| ${container} | ${comp} | ${resp} |"$'\n'
    ask_yn "  Add another component?" || break
done

# ---------------------------------------------------------------------------
# §06 — Runtime View
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §06 Runtime View ===" >&2

echo "  Key scenarios (leave Scenario blank to finish):" >&2
S06_SCENARIOS="| ID | Scenario | Why It Matters |"$'\n'"| --- | --- | --- |"$'\n'
S06_DETAILS=""
sc_idx=1
while true; do
    sc=$(ask "  Scenario name:")
    [[ -z "$sc" ]] && break
    why=$(ask "  Why it matters:")
    S06_SCENARIOS="${S06_SCENARIOS}| SC-$(printf '%02d' $sc_idx) | ${sc} | ${why} |"$'\n'

    diagram=$(ask_multiline "  Sequence diagram for '${sc}' — enter Mermaid sequenceDiagram code:")
    S06_DETAILS="${S06_DETAILS}#### SC-$(printf '%02d' $sc_idx): ${sc}"$'\n'$'\n'
    S06_DETAILS="${S06_DETAILS}\`\`\`mermaid"$'\n'"${diagram}"$'\n'"\`\`\`"$'\n'$'\n'

    ((sc_idx++))
    ask_yn "  Add another scenario?" || break
done

# ---------------------------------------------------------------------------
# §07 — Deployment View
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §07 Deployment View ===" >&2

echo "  Environments (leave Environment blank to finish):" >&2
S07_ENVS="| Environment | Purpose | Notes |"$'\n'"| --- | --- | --- |"$'\n'
while true; do
    env=$(ask "  Environment:")
    [[ -z "$env" ]] && break
    purpose=$(ask "  Purpose:")
    notes=$(ask "  Notes / differences from production:")
    S07_ENVS="${S07_ENVS}| ${env} | ${purpose} | ${notes} |"$'\n'
    ask_yn "  Add another environment?" || break
done

S07_INFRA=$(ask_multiline "Infrastructure (cloud provider, compute platform, data stores, networking):")
S07_DEPLOY=$(ask_multiline "Deployment process (pipeline from commit to production, config management, rollback):")

# ---------------------------------------------------------------------------
# §08 — Cross-cutting Concepts
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §08 Cross-cutting Concepts ===" >&2

S08_SECURITY=$(ask_multiline "Security (authentication, authorisation, data protection, relevant OWASP mitigations):")
S08_OBS=$(ask_multiline "Observability (logging format/destination, metrics tooling, tracing, alerting):")
S08_ERR=$(ask_multiline "Error handling (error strategy, retries, circuit breakers, user-facing messages):")
S08_DOMAIN=$(ask_multiline "Domain model / shared concepts (key entities and which containers use them; 'N/A' if not applicable):")

# ---------------------------------------------------------------------------
# §09 — Architecture Decisions
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §09 Architecture Decisions ===" >&2
echo "  Enter ADRs. Leave Title blank to finish." >&2

S09_LOG="| ID | Title | Status | Date |"$'\n'"| --- | --- | --- |"$'\n'
S09_DRAFTS=""
adr_idx=1
today=$(date +%Y-%m-%d)
while true; do
    title=$(ask "  ADR title:")
    [[ -z "$title" ]] && break
    context=$(ask_multiline "  Context (problem, forces, options considered):")
    decision=$(ask "  Decision (complete: 'We will...'):")
    pos=$(ask_multiline "  Positive consequences:")
    neg=$(ask_multiline "  Negative consequences / trade-offs:")

    adr_id="ADR-$(printf '%03d' $adr_idx)"
    S09_LOG="${S09_LOG}| ${adr_id} | ${title} | Accepted | ${today} |"$'\n'
    S09_DRAFTS="${S09_DRAFTS}#### ${adr_id} — ${title}"$'\n'$'\n'
    S09_DRAFTS="${S09_DRAFTS}**Status:** Accepted"$'\n'$'\n'
    S09_DRAFTS="${S09_DRAFTS}**Context:**"$'\n'"${context}"$'\n'
    S09_DRAFTS="${S09_DRAFTS}**Decision:**"$'\n'"${decision}"$'\n'$'\n'
    S09_DRAFTS="${S09_DRAFTS}**Consequences:**"$'\n'"- Positive: ${pos}"$'\n'"- Negative: ${neg}"$'\n'$'\n'

    ((adr_idx++))
    ask_yn "  Add another ADR?" || break
done

# ---------------------------------------------------------------------------
# §10 — Quality Requirements
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §10 Quality Requirements ===" >&2

echo "  Quality tree (quality goal → scenario ID mapping). Leave Goal blank to finish." >&2
S10_TREE="| Quality Goal | Scenario ID | Priority |"$'\n'"| --- | --- | --- |"$'\n'
while true; do
    goal=$(ask "  Quality goal:")
    [[ -z "$goal" ]] && break
    sc_id=$(ask "  Scenario ID (e.g. QS-01):")
    pri=$(ask "  Priority [High/Medium/Low]:")
    S10_TREE="${S10_TREE}| ${goal} | ${sc_id} | ${pri} |"$'\n'
    ask_yn "  Add another?" || break
done

echo "  Quality scenarios (leave ID blank to finish):" >&2
S10_SCENARIOS="| ID | Quality Goal | Stimulus | Environment | Response | Response Measure |"$'\n'"| --- | --- | --- | --- | --- | --- |"$'\n'
while true; do
    qs_id=$(ask "  Scenario ID (e.g. QS-01):")
    [[ -z "$qs_id" ]] && break
    qgoal=$(ask "  Quality goal:")
    stimulus=$(ask "  Stimulus (source + what happens):")
    env=$(ask "  Environment (conditions):")
    response=$(ask "  Response (what the system does):")
    measure=$(ask "  Response measure (quantified — must include a number):")
    S10_SCENARIOS="${S10_SCENARIOS}| ${qs_id} | ${qgoal} | ${stimulus} | ${env} | ${response} | ${measure} |"$'\n'
    ask_yn "  Add another scenario?" || break
done

# ---------------------------------------------------------------------------
# §11 — Risks and Technical Debt
# ---------------------------------------------------------------------------

echo "" >&2
echo "=== §11 Risks and Technical Debt ===" >&2

echo "  Risks (leave Description blank to finish). Likelihood/Impact: H/M/L" >&2
S11_RISKS="| ID | Risk | Likelihood | Impact | Mitigation |"$'\n'"| --- | --- | --- | --- | --- |"$'\n'
r_idx=1
while true; do
    risk=$(ask "  Risk description:")
    [[ -z "$risk" ]] && break
    likelihood=$(ask "  Likelihood [H/M/L]:")
    impact=$(ask "  Impact [H/M/L]:")
    mitigation=$(ask "  Mitigation:")
    S11_RISKS="${S11_RISKS}| R-$(printf '%02d' $r_idx) | ${risk} | ${likelihood} | ${impact} | ${mitigation} |"$'\n'
    ((r_idx++))
    ask_yn "  Add another risk?" || break
done

echo "  Technical debt (leave Description blank to finish)." >&2
echo "  Quadrant: Prudent/Reckless × Deliberate/Inadvertent" >&2
S11_DEBT="| ID | Description | Quadrant | Plan |"$'\n'"| --- | --- | --- | --- |"$'\n'
td_idx=1
while true; do
    desc=$(ask "  Description:")
    [[ -z "$desc" ]] && break
    quad=$(ask "  Quadrant (e.g. Prudent × Deliberate):")
    plan=$(ask "  Plan to address (or explicit deferral):")
    S11_DEBT="${S11_DEBT}| TD-$(printf '%02d' $td_idx) | ${desc} | ${quad} | ${plan} |"$'\n'
    ((td_idx++))
    ask_yn "  Add another debt item?" || break
done

# ---------------------------------------------------------------------------
# Write output
# ---------------------------------------------------------------------------

cat > "$OUTPUT" <<BRIEFEOF
# Project Brief
<!-- Populated by scripts/gather-brief.sh -->
<!-- Re-run to update any section. -->
<!-- Consumed by prompts/01-arch-spec-author.md and scripts/assemble.sh -->

---

## 01 — Introduction and Goals
<!-- arc42 §1 — https://docs.arc42.org/section-1/ -->
<!-- ISO/IEC 25010 quality model — https://iso25010.info -->
<!-- Status: complete -->

### System Overview

${S01_OVERVIEW}
${S01_REQ_NOTE}
${S01_TABLES}
---

## 02 — Constraints
<!-- arc42 §2 — https://docs.arc42.org/section-2/ -->
<!-- Status: complete -->

${S02_CONSTRAINTS}

${S02_CONVENTIONS}
---

## 03 — Context and Scope
<!-- arc42 §3 — https://docs.arc42.org/section-3/ -->
<!-- C4 Model — System Context (Level 1) — https://c4model.com -->
<!-- Status: complete -->

### Context Diagram

${S03_DIAGRAM}

### External Actors
${S03_ACTORS}
### External Systems
${S03_SYSTEMS}
### Out of Scope

${S03_OOS}

---

## 04 — Solution Strategy
<!-- arc42 §4 — https://docs.arc42.org/section-4/ -->
<!-- Status: complete -->

### Technology Decisions
${S04_DECISIONS}
### Architectural Approach

${S04_APPROACH}

### How Strategy Achieves Quality Goals

${S04_QUALITY}

---

## 05 — Building Block View
<!-- arc42 §5 — https://docs.arc42.org/section-5/ -->
<!-- C4 Model — Container (Level 2), Component (Level 3) — https://c4model.com -->
<!-- Status: complete -->

### Level 1 — Containers

${S05_DIAGRAM}

${S05_L1}
### Level 2 — Components (for complex containers)
${S05_L2}
---

## 06 — Runtime View
<!-- arc42 §6 — https://docs.arc42.org/section-6/ -->
<!-- UML 2.5 Sequence Diagrams — https://www.omg.org/spec/UML/2.5.1 -->
<!-- Status: complete -->

### Key Scenarios
${S06_SCENARIOS}
### Scenario Detail

${S06_DETAILS}
---

## 07 — Deployment View
<!-- arc42 §7 — https://docs.arc42.org/section-7/ -->
<!-- C4 Model — Deployment — https://c4model.com -->
<!-- The Twelve-Factor App — https://12factor.net -->
<!-- Status: complete -->

### Environments
${S07_ENVS}
### Infrastructure

${S07_INFRA}

### Deployment Process

${S07_DEPLOY}

---

## 08 — Cross-cutting Concepts
<!-- arc42 §8 — https://docs.arc42.org/section-8/ -->
<!-- OWASP Top 10 — https://owasp.org/www-project-top-ten/ -->
<!-- The Twelve-Factor App — https://12factor.net -->
<!-- Status: complete -->

### Security

${S08_SECURITY}

### Observability

${S08_OBS}

### Error Handling

${S08_ERR}

### Domain Model / Shared Concepts

${S08_DOMAIN}

---

## 09 — Architecture Decisions
<!-- arc42 §9 — https://docs.arc42.org/section-9/ -->
<!-- ADR format (Nygard, 2011) — https://adr.github.io -->
<!-- Status: complete -->

### Decision Log
${S09_LOG}
### ADR Drafts

${S09_DRAFTS}
---

## 10 — Quality Requirements
<!-- arc42 §10 — https://docs.arc42.org/section-10/ -->
<!-- ISO/IEC 25010 — https://iso25010.info -->
<!-- ATAM quality scenarios — https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908 -->
<!-- Status: complete -->

### Quality Tree
${S10_TREE}
### Quality Scenarios
${S10_SCENARIOS}
---

## 11 — Risks and Technical Debt
<!-- arc42 §11 — https://docs.arc42.org/section-11/ -->
<!-- ISO 31000 risk management — https://www.iso.org/iso-31000-risk-management.html -->
<!-- Technical Debt Quadrant (Fowler) — https://martinfowler.com/bliki/TechnicalDebtQuadrant.html -->
<!-- Status: complete -->

### Risks
${S11_RISKS}
### Technical Debt
${S11_DEBT}
BRIEFEOF

echo "" >&2
echo "Written to ${OUTPUT}" >&2
