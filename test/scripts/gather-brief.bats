#!/usr/bin/env bats
# gather-brief.bats — Unit tests for scripts/gather-brief.sh
#
# Standards:
#   bats-core (Bash Automated Testing System) — https://github.com/bats-core/bats-core
#   TAP (Test Anything Protocol) — https://testanything.org
#
# Run: bats test/scripts/gather-brief.bats
#   or: make test-scripts
#
# Note: Section function tests use process substitution (< <(...)) rather than
# pipes so that gather_brief_NN runs in the current shell and its global
# variables remain accessible to assertions.

setup() {
    source scripts/gather-brief.sh --source-only
}

# ---------------------------------------------------------------------------
# --help
# ---------------------------------------------------------------------------

@test "--help exits 0 and shows usage" {
    run bash scripts/gather-brief.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"arc42"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_01 — Introduction and Goals
# ---------------------------------------------------------------------------

@test "gather_brief_01 with HAS_REQ=true reads only system overview" {
    HAS_REQ=true
    gather_brief_01 2>/dev/null < <(printf 'A web app for task management.\nIt helps users organise work.\nEOF\n')
    [[ "$S01_OVERVIEW" == *"task management"* ]]
    [[ "$S01_OVERVIEW" == *"organise work"* ]]
    [[ "$S01_REQ_NOTE" == *"sourced from requirements.md"* ]]
    [ -z "$S01_TABLES" ]
}

@test "gather_brief_01 with HAS_REQ=false reads overview + requirements + quality goals + stakeholders" {
    HAS_REQ=false
    # Overview (multiline EOF), then:
    # Requirement 1 + priority + "no more", Quality goal 1 + motivation + "no more",
    # Stakeholder 1 + expectations + "no more"
    gather_brief_01 2>/dev/null < <(printf '%s\n' \
        "A web app for task management." \
        "EOF" \
        "Automated email reminders" \
        "High" \
        "" \
        "Performance goal" \
        "Keep response times low" \
        "" \
        "Product Owner" \
        "Timely feature delivery" \
        "")
    [[ "$S01_OVERVIEW" == *"task management"* ]]
    [[ "$S01_TABLES" == *"Automated email reminders"* ]]
    [[ "$S01_TABLES" == *"High"* ]]
    [[ "$S01_TABLES" == *"Performance goal"* ]]
    [[ "$S01_TABLES" == *"Product Owner"* ]]
    [ -z "$S01_REQ_NOTE" ]
}

# ---------------------------------------------------------------------------
# gather_brief_02 — Constraints
# ---------------------------------------------------------------------------

@test "gather_brief_02 with HAS_REQ=true reads only conventions (skips constraints)" {
    HAS_REQ=true
    # Convention 1: name, background, "n" to stop
    gather_brief_02 2>/dev/null < <(printf '%s\n' \
        "REST API conventions" \
        "Industry standard" \
        "n")
    [[ "$S02_CONVENTIONS" == *"REST API conventions"* ]]
    [[ "$S02_CONVENTIONS" == *"Industry standard"* ]]
    [[ "$S02_CONSTRAINTS" == *"sourced from requirements.md"* ]]
}

@test "gather_brief_02 with HAS_REQ=false reads technical + organisational constraints + conventions" {
    HAS_REQ=false
    # Technical constraint + bg + stop, organisational constraint + bg + stop,
    # convention + bg + stop
    gather_brief_02 2>/dev/null < <(printf '%s\n' \
        "Must use PostgreSQL" \
        "Organisational mandate" \
        "" \
        "Must deploy to AWS" \
        "Cloud provider contract" \
        "" \
        "Conventional Commits" \
        "Commit message consistency" \
        "")
    [[ "$S02_CONSTRAINTS" == *"Must use PostgreSQL"* ]]
    [[ "$S02_CONSTRAINTS" == *"Must deploy to AWS"* ]]
    [[ "$S02_CONVENTIONS" == *"Conventional Commits"* ]]
}

@test "gather_brief_02 with HAS_REQ=true includes sourced from requirements.md comment" {
    HAS_REQ=true
    gather_brief_02 2>/dev/null < <(printf '%s\n' \
        "Some convention" \
        "Some background" \
        "n")
    [[ "$S02_CONSTRAINTS" == *"sourced from requirements.md"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_03 — Context and Scope
# ---------------------------------------------------------------------------

@test "gather_brief_03 reads context diagram, actors, systems, out-of-scope" {
    HAS_REQ=true
    # Context diagram (multiline EOF), actors (1 then stop), systems (1 then stop), OOS
    gather_brief_03 2>/dev/null < <(printf '%s\n' \
        "flowchart TD" \
        "    A --> B" \
        "EOF" \
        "User" \
        "End user" \
        "Submits tasks" \
        "" \
        "SendGrid" \
        "Email service" \
        "Sends notifications" \
        "" \
        "Not mobile")
    [[ "$S03_DIAGRAM" == *'```mermaid'* ]]
    [[ "$S03_DIAGRAM" == *"flowchart TD"* ]]
    [[ "$S03_ACTORS" == *"User"* ]]
    [[ "$S03_ACTORS" == *"End user"* ]]
    [[ "$S03_SYSTEMS" == *"SendGrid"* ]]
    [[ "$S03_SYSTEMS" == *"Email service"* ]]
    [[ "$S03_OOS" == "Not mobile" ]]
}

# ---------------------------------------------------------------------------
# gather_brief_04 — Solution Strategy
# ---------------------------------------------------------------------------

@test "gather_brief_04 reads decisions, approach, quality goals text" {
    HAS_REQ=true
    # Decision 1 + rationale + quality goal + stop, approach (multiline), quality text (multiline)
    gather_brief_04 2>/dev/null < <(printf '%s\n' \
        "Use Node.js" \
        "Fast ecosystem" \
        "Performance" \
        "" \
        "" \
        "Monolith-first approach." \
        "Simple deployment model." \
        "EOF" \
        "Stateless auth reduces latency." \
        "EOF")
    [[ "$S04_DECISIONS" == *"Use Node.js"* ]]
    [[ "$S04_DECISIONS" == *"Fast ecosystem"* ]]
    [[ "$S04_APPROACH" == *"Monolith-first"* ]]
    [[ "$S04_QUALITY" == *"Stateless auth"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_05 — Building Block View
# ---------------------------------------------------------------------------

@test "gather_brief_05 reads container diagram, L1 containers, L2 components with skip" {
    HAS_REQ=true
    # Container diagram (multiline EOF), L1 containers (2 then stop), L2 skip (blank)
    gather_brief_05 2>/dev/null < <(printf '%s\n' \
        "flowchart TD" \
        "    API --> DB" \
        "EOF" \
        "Web App" \
        "React + TypeScript" \
        "User interface" \
        "y" \
        "REST API" \
        "Node.js + Express" \
        "Business logic" \
        "" \
        "" \
        "")
    [[ "$S05_DIAGRAM" == *'```mermaid'* ]]
    [[ "$S05_DIAGRAM" == *"API --> DB"* ]]
    [[ "$S05_L1" == *"Web App"* ]]
    [[ "$S05_L1" == *"REST API"* ]]
    # L2 was skipped — should only have the header row
    local l2_data
    l2_data=$(echo "$S05_L2" | grep -c '|' || true)
    # Header (2 lines: header + separator) and no data rows
    [ "$l2_data" -le 2 ]
}

# ---------------------------------------------------------------------------
# gather_brief_06 — Runtime View
# ---------------------------------------------------------------------------

@test "gather_brief_06 reads scenarios with nested multiline sequence diagrams" {
    HAS_REQ=true
    # Scenario 1 + why + diagram (multiline EOF) + stop
    gather_brief_06 2>/dev/null < <(printf '%s\n' \
        "Create Task" \
        "Primary user action" \
        "sequenceDiagram" \
        "    User->>API: POST /tasks" \
        "    API->>DB: INSERT" \
        "EOF" \
        "" \
        "")
    [[ "$S06_SCENARIOS" == *"Create Task"* ]]
    [[ "$S06_SCENARIOS" == *"Primary user action"* ]]
    [[ "$S06_DETAILS" == *"SC-01"* ]]
    [[ "$S06_DETAILS" == *'```mermaid'* ]]
    [[ "$S06_DETAILS" == *"sequenceDiagram"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_07 — Deployment View
# ---------------------------------------------------------------------------

@test "gather_brief_07 reads environments, infrastructure, deployment process" {
    HAS_REQ=true
    # Environments (2 then stop), infra (multiline EOF), deploy (multiline EOF)
    gather_brief_07 2>/dev/null < <(printf '%s\n' \
        "Development" \
        "Local dev" \
        "Docker Compose" \
        "y" \
        "Production" \
        "Live system" \
        "Full AWS" \
        "" \
        "" \
        "AWS us-east-1. ECS Fargate." \
        "EOF" \
        "Merge to main triggers GitHub Actions pipeline." \
        "EOF")
    [[ "$S07_ENVS" == *"Development"* ]]
    [[ "$S07_ENVS" == *"Production"* ]]
    [[ "$S07_INFRA" == *"ECS Fargate"* ]]
    [[ "$S07_DEPLOY" == *"GitHub Actions"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_08 — Cross-cutting Concepts
# ---------------------------------------------------------------------------

@test "gather_brief_08 reads security, observability, error handling, domain model" {
    HAS_REQ=true
    # 4 multiline inputs
    gather_brief_08 2>/dev/null < <(printf '%s\n' \
        "JWT Bearer tokens for auth." \
        "EOF" \
        "Structured JSON logs to CloudWatch." \
        "EOF" \
        "Exponential backoff for retries." \
        "EOF" \
        "User entity, Task entity." \
        "EOF")
    [[ "$S08_SECURITY" == *"JWT Bearer"* ]]
    [[ "$S08_OBS" == *"CloudWatch"* ]]
    [[ "$S08_ERR" == *"Exponential backoff"* ]]
    [[ "$S08_DOMAIN" == *"User entity"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_09 — Architecture Decisions
# ---------------------------------------------------------------------------

@test "gather_brief_09 reads ADR log with context/decision/consequences" {
    HAS_REQ=true
    # ADR 1: title, context (multiline), decision, positive (multiline), negative (multiline), stop
    gather_brief_09 2>/dev/null < <(printf '%s\n' \
        "Use JWT for auth" \
        "Stateless auth needed. Options: sessions, JWT, OAuth2." \
        "EOF" \
        "We will use JWT Bearer tokens with 15-minute access tokens." \
        "Stateless — no shared session store needed." \
        "EOF" \
        "Tokens cannot be invalidated before expiry." \
        "EOF" \
        "" \
        "")
    [[ "$S09_LOG" == *"ADR-001"* ]]
    [[ "$S09_LOG" == *"Use JWT for auth"* ]]
    [[ "$S09_LOG" == *"Accepted"* ]]
    [[ "$S09_DRAFTS" == *"ADR-001"* ]]
    [[ "$S09_DRAFTS" == *"Stateless auth needed"* ]]
    [[ "$S09_DRAFTS" == *"We will use JWT"* ]]
    [[ "$S09_DRAFTS" == *"Positive"* ]]
    [[ "$S09_DRAFTS" == *"Negative"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_10 — Quality Requirements
# ---------------------------------------------------------------------------

@test "gather_brief_10 reads quality tree and quality scenarios" {
    HAS_REQ=true
    # Quality tree: 1 entry then stop; Quality scenario: 1 entry then stop
    gather_brief_10 2>/dev/null < <(printf '%s\n' \
        "API Response Time" \
        "QS-01" \
        "High" \
        "" \
        "QS-01" \
        "API Response Time" \
        "100 concurrent users" \
        "Normal load" \
        "API responds" \
        "p95 <=300ms" \
        "")
    [[ "$S10_TREE" == *"API Response Time"* ]]
    [[ "$S10_TREE" == *"QS-01"* ]]
    [[ "$S10_TREE" == *"High"* ]]
    [[ "$S10_SCENARIOS" == *"QS-01"* ]]
    [[ "$S10_SCENARIOS" == *"100 concurrent users"* ]]
    [[ "$S10_SCENARIOS" == *"p95"* ]]
}

# ---------------------------------------------------------------------------
# gather_brief_11 — Risks and Technical Debt
# ---------------------------------------------------------------------------

@test "gather_brief_11 reads risks and technical debt" {
    HAS_REQ=true
    # Risk 1 + stop, Debt 1 + stop
    gather_brief_11 2>/dev/null < <(printf '%s\n' \
        "SendGrid outage disrupts notifications" \
        "M" \
        "H" \
        "Queue locally; in-app fallback" \
        "" \
        "No integration tests at launch" \
        "Prudent x Deliberate" \
        "Add integration tests in Q4" \
        "")
    [[ "$S11_RISKS" == *"R-01"* ]]
    [[ "$S11_RISKS" == *"SendGrid outage"* ]]
    [[ "$S11_RISKS" == *"M"* ]]
    [[ "$S11_RISKS" == *"H"* ]]
    [[ "$S11_DEBT" == *"TD-01"* ]]
    [[ "$S11_DEBT" == *"No integration tests"* ]]
    [[ "$S11_DEBT" == *"Prudent"* ]]
}

# ---------------------------------------------------------------------------
# Full pipeline — end-to-end with brief-answers.txt fixture
# ---------------------------------------------------------------------------

@test "full pipeline with HAS_REQ=true produces valid output with all 11 headings" {
    local tmpdir tmpfile
    tmpdir="$(mktemp -d)"
    # Create requirements.md so HAS_REQ=true
    cp templates/requirements.md "$tmpdir/requirements.md"
    tmpfile="$tmpdir/brief.md"
    cd "$tmpdir"
    grep -v '^#' "$OLDPWD/test/fixtures/brief-answers.txt" | \
        bash "$OLDPWD/scripts/gather-brief.sh" brief.md 2>/dev/null
    cd "$OLDPWD"
    grep -q "^## 01 — Introduction and Goals" "$tmpfile"
    grep -q "^## 02 — Constraints" "$tmpfile"
    grep -q "^## 03 — Context and Scope" "$tmpfile"
    grep -q "^## 04 — Solution Strategy" "$tmpfile"
    grep -q "^## 05 — Building Block View" "$tmpfile"
    grep -q "^## 06 — Runtime View" "$tmpfile"
    grep -q "^## 07 — Deployment View" "$tmpfile"
    grep -q "^## 08 — Cross-cutting Concepts" "$tmpfile"
    grep -q "^## 09 — Architecture Decisions" "$tmpfile"
    grep -q "^## 10 — Quality Requirements" "$tmpfile"
    grep -q "^## 11 — Risks and Technical Debt" "$tmpfile"
    rm -rf "$tmpdir"
}

@test "full pipeline output contains Status: complete markers" {
    local tmpdir tmpfile
    tmpdir="$(mktemp -d)"
    cp templates/requirements.md "$tmpdir/requirements.md"
    tmpfile="$tmpdir/brief.md"
    cd "$tmpdir"
    grep -v '^#' "$OLDPWD/test/fixtures/brief-answers.txt" | \
        bash "$OLDPWD/scripts/gather-brief.sh" brief.md 2>/dev/null
    cd "$OLDPWD"
    # Every section should have a Status: complete marker
    local count
    count=$(grep -c 'Status: complete' "$tmpfile")
    [ "$count" -ge 11 ]
    rm -rf "$tmpdir"
}

@test "mermaid diagram blocks in output are fenced correctly" {
    local tmpdir tmpfile
    tmpdir="$(mktemp -d)"
    cp templates/requirements.md "$tmpdir/requirements.md"
    tmpfile="$tmpdir/brief.md"
    cd "$tmpdir"
    grep -v '^#' "$OLDPWD/test/fixtures/brief-answers.txt" | \
        bash "$OLDPWD/scripts/gather-brief.sh" brief.md 2>/dev/null
    cd "$OLDPWD"
    # Check that mermaid fences open and close correctly
    local opens closes
    opens=$(grep -c '```mermaid' "$tmpfile")
    closes=$(grep -c '^```$' "$tmpfile")
    # At least 2 mermaid blocks: context diagram (§03) and container diagram (§05)
    [ "$opens" -ge 2 ]
    # Every open fence must have a matching close fence
    [ "$closes" -ge "$opens" ]
    rm -rf "$tmpdir"
}
