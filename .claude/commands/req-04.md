---
description: Gather constraints and assumptions (ISO/IEC/IEEE 29148:2018 §5.2.4)
---

You are gathering constraints and assumptions for the **Requirements Specification** of a system.

**Standards:**
- ISO/IEC/IEEE 29148:2018 §5.2.4 — constraints, assumptions, and dependencies — https://www.iso.org/standard/72089.html
- IREB CPRE Handbook — constraint vs. assumption distinction — https://www.ireb.org/en/cpre/  
  A **constraint** limits the solution space — it is a fact that the architect must work within.
  An **assumption** is something believed to be true that has not been verified — it is a risk if wrong.
  A **dependency** is something external that the system or project relies on.

## Procedure

1. Read `requirements.md` in the current directory. If it does not exist, read `templates/requirements.md` and write it as `requirements.md`.
2. Extract the `## 06 — Constraints` and `## 07 — Assumptions and Dependencies` blocks. If Status is not `empty`, or if tables have entries, show the existing content and ask: "Sections 06 and 07 already have content — would you like to (a) add more entries, (b) update existing ones, or (c) replace entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing.
4. Write the structured output back into the `## 06` and `## 07` blocks of `requirements.md`. Update Status comments to `complete`. Do not modify any other section.

## Questions

**Technical constraints**
"What technical constraints does the system operate under?

A technical constraint limits the technology choices or architecture — it is not a preference but a requirement imposed from outside.

Examples:
- 'Must use PostgreSQL — mandated by the enterprise data platform team'
- 'Must run on AWS us-east-1 — existing infrastructure is AWS-only'
- 'Must integrate with Salesforce CRM via REST API'
- 'API must be REST/JSON — mobile clients cannot consume GraphQL'
- 'Must be containerised — deployment platform is Kubernetes'

For each constraint: what it is, and why it exists (existing infrastructure, contractual, mandated by another team, regulatory, etc.)."

**Organisational constraints**
"What organisational, regulatory, budgetary, or timeline constraints apply?

Examples:
- 'Must go live by [date] — contractual deadline with client'
- 'Team is capped at N engineers through Q[X]'
- 'Must comply with GDPR — EU user data is in scope'
- 'Must achieve SOC 2 Type II — required for enterprise sales'
- 'Budget is fixed at £X — no scope for additional infrastructure spend'
- 'Must use the existing SSO provider — no new identity systems permitted'

For each constraint: what it is and why it exists."

**Assumptions**
"What assumptions are you making that have not yet been verified?

An assumption is something you are treating as true in order to write these requirements — if it turns out to be false, one or more requirements would need to change.

Examples:
- 'Assumes the third-party payment API supports webhooks for async confirmation'
- 'Assumes current data volume will not exceed 10M records in year one'
- 'Assumes the mobile app will be developed by a separate team and will consume the API'

For each assumption: what you are assuming, and what the impact would be if it is wrong."

**Dependencies**
"What external systems, teams, services, or third parties does this project depend on?

Examples:
- 'Depends on the Identity team delivering the new OAuth service by Q2'
- 'Depends on legacy ERP API remaining available during migration period'
- 'Depends on vendor X delivering their SDK before integration work begins'

For each dependency: what it is, what it provides, and the risk if it is delayed or unavailable."

## Output format

Replace the `## 06 — Constraints` and `## 07 — Assumptions and Dependencies` blocks with:

```markdown
## 06 — Constraints
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — constraints on requirements -->
<!-- Status: complete -->

### Technical Constraints
| ID | Constraint | Rationale |
| --- | --- | --- |
| TC-01 | [constraint] | [why it exists] |

### Organisational Constraints
| ID | Constraint | Rationale |
| --- | --- | --- |
| OC-01 | [constraint] | [why it exists] |

---

## 07 — Assumptions and Dependencies
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — assumptions and dependencies -->
<!-- Status: complete -->

| ID | Type | Description | Impact if Wrong / Unavailable |
| --- | --- | --- | --- |
| A-01 | Assumption | [what is assumed] | [impact if false] |
| D-01 | Dependency | [what is depended on] | [impact if delayed or unavailable] |
```
