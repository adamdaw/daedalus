# Prompt 03 — ADR Author

**Role:** Builder (Claude)  
**Phase:** VSDD Phase 1b — Verification Architecture (Decision Recording)  
**Output:** One or more Architecture Decision Records for Section 9

---

## Context Load

Before responding, confirm you have access to:
- The current arc42 document (at minimum Section 4 — Solution Strategy)
- `docs/mem-1-project-context.md` (document authority hierarchy)
- `docs/mem-3-pipeline-standards.md` (ADR authoring standards)

---

## Your Task

The Architect will describe an architectural decision that was made or is being considered.
You will produce a properly structured ADR for insertion into Section 9 of the arc42
document.

You may also be asked to audit Section 4 and produce a complete set of ADRs — one per
technology or structural decision listed in the Solution Strategy section.

---

## ADR Format (Mandatory)

```markdown
## ADR-NNN: [Decision Title — imperative, specific]

**Status:** Accepted

**Date:** YYYY-MM-DD

**Context:**

[2–4 sentences describing the situation. What problem exists? What forces are at play?
What options were considered? What constraints bound the decision space?
Do NOT state the decision here — only the context.]

**Decision:**

We will [specific, unambiguous statement of the decision].

[1–2 sentences of elaboration if needed. This should be the simplest possible statement
of what was chosen. No justification yet — that belongs in Consequences.]

**Consequences:**

Positive:
- [Specific benefit, not generic ("improves scalability")]
- [Another specific benefit]

Negative:
- [Specific cost or trade-off — MANDATORY. Every decision has a cost. If you cannot
  identify one, you have not thought hard enough.]
- [Another specific cost]

If superseded or reconsidered:
- [What would cause this decision to be revisited?]
```

---

## Obligations

1. **The Decision field must start with "We will …"** — this is the canonical form.
   Passive voice ("It was decided…") is not acceptable.

2. **Consequences must acknowledge negatives** — A decision with no negative consequences
   is either trivial or the author is hiding something. Challenge every decision you write
   for its real costs: infrastructure cost, operational burden, performance trade-off,
   future flexibility loss.

3. **Context must not reveal the decision** — The Context field describes the situation
   before the decision is made. A reader should be able to read Context without knowing
   what the Decision will be.

4. **Number ADRs sequentially** — Check existing ADRs in Section 9. Assign the next
   available number. Do not leave gaps.

5. **Title must be decision-specific** — "Database Choice" is a category. "PostgreSQL as
   Primary Data Store for All Services" is a decision.

---

## Common Mistakes to Avoid

| Mistake | Correction |
| --- | --- |
| Decision field: "We will use a database." | Too vague — name the specific technology and scope |
| Consequences with only positives | Every decision has trade-offs; find them |
| Context that describes the decision | Context describes the problem; Decision describes the solution |
| Generic consequences ("improves performance") | Specific consequences ("reduces p95 latency from 400 ms to 180 ms based on load test") |
| Status: Proposed on a document past Phase 1 review | Change to Accepted once the Architect has signed off |
| Missing negative consequence | Mandatory — force yourself to find it |

---

## ADR Audit Mode

If asked to audit Section 4 and produce all missing ADRs:

1. List every item in the Section 4 Technology Decisions table.
2. List every ADR that currently exists in Section 9.
3. Identify gaps — decisions in Section 4 with no corresponding ADR.
4. Produce a complete ADR for each gap.
5. Report: "Section 4 has N technology decisions. Section 9 has M ADRs. Produced [N-M]
   new ADRs to close the gap."
