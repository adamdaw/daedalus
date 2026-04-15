---
description: Gather Section 04 — Solution Strategy (technology decisions, architectural approach)
---

You are gathering information for **Section 04 — Solution Strategy** of an arc42 architecture document.

**Standards:**
- arc42 §4 — https://docs.arc42.org/section-4/
- arc42 guidance: each technology decision should be traceable to a quality goal from §01 and foreshadow an ADR in §09

**Note:** If Section 01 of `brief.md` is empty, remind the user that quality goals must be defined there first — this section references them.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. If `requirements.md` exists, read Section 05 (Non-Functional Requirements). Show: "Non-functional requirements from requirements.md that should inform technology decisions: [list NFRs with their measurable criteria]."
   If `requirements.md` does not exist, proceed without cross-reference.
3. Extract the `## 04 — Solution Strategy` block. If Status is not `empty`, or if fields are populated beyond the skeleton, show the existing content and ask: "Section 04 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
4. If Section 01 is empty or has no quality goals, note: "You may want to run /gather-01 first — Section 04 asks you to link decisions to quality goals."
5. Ask the questions below one topic at a time. Wait for each answer before continuing.
6. Write the structured output back into the `## 04` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Technology Decisions**
"What are the key technology decisions that have been made (or are being made) for this system? For each decision, link it to a quality goal from Section 01 and/or a non-functional requirement from requirements.md.

- What was decided (e.g., 'Use PostgreSQL as the primary data store')
- Why (the rationale)
- Which quality goal from Section 01 and/or NFR from requirements.md it addresses

These are the decisions significant enough to document — ones that constrain the architecture or would be hard to reverse."

**Architectural Approach**
"How is the system structured at the highest level? What architectural style or pattern is being used?

Examples: layered monolith, microservices, event-driven, CQRS, serverless, modular monolith, pipes-and-filters.

Describe the top-level decomposition in a sentence or two."

**Achieving Quality Goals**
"For each quality goal listed in Section 01, how does the architectural approach address it?

For example: if Reliability is a goal, what architectural decision directly contributes to it (redundancy, circuit breakers, retry policies)?"

## Output format

Replace the `## 04 — Solution Strategy` block with:

```markdown
## 04 — Solution Strategy
<!-- arc42 §4 — https://docs.arc42.org/section-4/ -->
<!-- Status: complete -->

### Technology Decisions
| Decision | Rationale | Quality Goal Addressed |
| --- | --- | --- |
| [decision] | [rationale] | [quality goal from §01] |

### Architectural Approach
[user's answer — style, pattern, top-level decomposition]

### How Strategy Achieves Quality Goals
[user's answer — one entry per quality goal from §01]
```
