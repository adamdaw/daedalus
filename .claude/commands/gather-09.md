---
description: Gather Section 09 — Architecture Decisions (ADR drafts for significant decisions)
---

You are gathering information for **Section 09 — Architecture Decisions** of an arc42 architecture document.

**Standards:**
- arc42 §9 — https://docs.arc42.org/section-9/
- ADR format (Michael Nygard, 2011) — https://adr.github.io  
  Each decision is captured as: Context → Decision ("We will…") → Consequences (positive and negative).
  The Decision statement must begin with "We will" to make it unambiguous.

**Note:** This command gathers ADR drafts. Prompt 03 (ADR Author) refines these drafts into
fully-formed Section 09 entries. Technology decisions from Section 04 are good starting candidates.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. Extract the `## 09 — Architecture Decisions` block. If Status is not `empty`, or if the decision log has entries, show the existing content and ask: "Section 09 already has content — would you like to (a) add more decisions, (b) update existing ones, or (c) replace entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing.
4. Write the structured output back into the `## 09` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Decision Identification**
"What are the 3–5 most significant architectural decisions made for this system?

Significant decisions are ones that:
- Were difficult or contentious to make
- Constrain the architecture going forward
- Would be costly to reverse
- Other architects reviewing this document would wonder about

Examples: choice of database technology, synchronous vs. asynchronous communication, monolith vs. microservices, build vs. buy for a key capability."

**For each decision identified, ask:**
"Tell me about '[decision]':
1. Context: what problem or forces led to this decision? What options were considered?
2. Decision: what was decided? (Start with 'We will…')
3. Consequences: what are the positive outcomes? What are the downsides or trade-offs accepted?"

**Open Decisions**
"Are there any significant architectural decisions still open or under active discussion — ones that will need to be made but haven't been yet?

Capturing these in the ADR log as 'Proposed' status makes the unknowns visible."

## Output format

Replace the `## 09 — Architecture Decisions` block with:

```markdown
## 09 — Architecture Decisions
<!-- arc42 §9 — https://docs.arc42.org/section-9/ -->
<!-- ADR format (Nygard, 2011) — https://adr.github.io -->
<!-- Status: complete -->

### Decision Log
| ID | Title | Status | Date |
| --- | --- | --- | --- |
| ADR-001 | [title] | Accepted | [date or TBD] |

### ADR Drafts

#### ADR-001 — [Title]
**Status:** Accepted

**Context:**
[what led to this decision, options considered]

**Decision:**
We will [what was decided].

**Consequences:**
- Positive: [positive outcomes]
- Negative: [trade-offs accepted]
```

Repeat the ADR draft block for each decision. Use status `Proposed` for open decisions.
