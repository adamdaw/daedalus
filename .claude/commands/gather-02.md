---
description: Gather Section 02 — Constraints (technical, organisational, conventions)
---

You are gathering information for **Section 02 — Constraints** of an arc42 architecture document.

**Standards:**
- arc42 §2 — https://docs.arc42.org/section-2/
- Conway's Law (Melvin Conway, 1967) — organisational structure shapes system design; organisational constraints are captured explicitly to surface this

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. If `requirements.md` exists, read Section 06 (Constraints) and Section 07 (Assumptions and Dependencies). If these sections have populated tables (Status is not `empty`), show the user: "I found constraints and assumptions in your requirements specification. Technical and organisational constraints will be sourced from there. I will only ask about conventions, which are architecture-specific."
   If requirements.md has no constraints, proceed with all three questions as normal.
3. Extract the `## 02 — Constraints` block. If Status is not `empty`, or if any tables contain rows beyond the header, show the existing content and ask: "Section 02 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
4. If requirements.md had populated constraints (step 2), ask only the **Conventions** question below. Skip Technical Constraints and Organisational Constraints — those will be sourced from requirements.md.
   If requirements.md had no constraints, ask all three questions below one topic at a time. Wait for each answer before continuing.
5. Write the structured output back into the `## 02` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Technical Constraints**
"What technical constraints does the system operate under? These are non-negotiable external impositions — not choices. Examples:
- Mandated programming language or framework
- Required cloud provider or on-prem environment
- Existing systems the solution must integrate with
- Protocol or data format requirements
- Performance or security certifications required

For each, give the constraint and why it cannot be changed."

**Organisational Constraints**
"What organisational constraints apply? Examples:
- Team size and skill availability
- Budget ceiling
- Fixed deadlines or regulatory timelines
- Compliance requirements (GDPR, HIPAA, SOC 2, etc.)
- Approval or governance processes

Note: per Conway's Law, team structure often predetermines system structure — capture team boundaries if relevant."

**Conventions**
"What conventions must the codebase or architecture follow? Examples:
- Coding standards or style guides
- Branching and release strategy
- Specific architectural patterns mandated by the organisation
- Documentation standards
- Licensing requirements"

## Output format

Replace the `## 02 — Constraints` block with:

When requirements.md provided constraints, use this format:

```markdown
## 02 — Constraints
<!-- arc42 §2 — https://docs.arc42.org/section-2/ -->
<!-- Status: complete -->

### Technical Constraints
<!-- Sourced from requirements.md §06 — run /req-04 to update -->
| Constraint | Background / Motivation |
| --- | --- |
| [constraint from requirements.md] | [motivation from requirements.md] |

### Organisational Constraints
<!-- Sourced from requirements.md §06 — run /req-04 to update -->
| Constraint | Background / Motivation |
| --- | --- |
| [constraint from requirements.md] | [motivation from requirements.md] |

### Conventions
| Convention | Background / Motivation |
| --- | --- |
| [convention] | [rationale] |
```

When requirements.md has no constraints (or does not exist), use this format:

```markdown
## 02 — Constraints
<!-- arc42 §2 — https://docs.arc42.org/section-2/ -->
<!-- Status: complete -->

### Technical Constraints
| Constraint | Background / Motivation |
| --- | --- |
| [constraint] | [why it cannot be changed] |

### Organisational Constraints
| Constraint | Background / Motivation |
| --- | --- |
| [constraint] | [context] |

### Conventions
| Convention | Background / Motivation |
| --- | --- |
| [convention] | [rationale] |
```
