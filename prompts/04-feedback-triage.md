# Prompt 04 — Feedback Triage

**Role:** Architect (human or orchestrating agent)
**Phase:** VSDD Phase 4 — Feedback Integration
**Input:** Adversarial review output (from Prompt 02)
**Output:** Triage table + rework instructions for Spec Author

---

## Context Load

Before responding, confirm you have access to:
- The adversarial review output (numbered findings from Sarcasmotron)
- The current arc42 document (to verify each finding against the actual text)
- `docs/mem-1-project-context.md` (phase gate rules, authority hierarchy)

---

## Your Task

You will triage every finding from the adversarial review. For each finding, you must:

1. Read the finding and locate the referenced section in the arc42 document.
2. Verify the finding is accurate — Sarcasmotron occasionally invents problems or
   misreads the document. Challenge findings that do not hold up against the actual text.
3. Assign a decision: **Accept**, **Reject**, or **Defer**.
4. Write a rationale for every decision.
5. For Accepted findings, write a concrete correction instruction for the Spec Author.

---

## Triage Decisions

| Decision | Meaning | When to Use |
| --- | --- | --- |
| **Accept** | The finding is valid and must be fixed before convergence | The document has a real gap, error, or missing element |
| **Reject** | The finding is invalid, misread, or out of scope | Sarcasmotron misread the document; the "flaw" is intentional; the finding applies a standard not relevant here |
| **Defer** | The finding is valid but will not be fixed in this iteration | Explicitly out of scope for this version; tracked as technical debt |

**Rejection discipline:** Reject only when you can cite the specific document text that
disproves the finding. "I think it's fine" is not a rejection. If you are uncertain, Accept.

**Deferral discipline:** A Defer must be accompanied by a Section 11 technical debt entry.
If you Defer a finding, add it to the Technical Debt table with a "Plan to Address" milestone.

---

## Output Format

```markdown
## Feedback Integration Record — [Proposal Name]

**Date:** YYYY-MM-DD
**Adversarial Review:** [date of Sarcasmotron review]
**Architect:** [name]

### Triage Table

| # | Section | Finding Summary | Decision | Rationale | Correction Instruction |
|---|---------|-----------------|----------|-----------|------------------------|
| 1 | [Section N] | [one-line summary] | Accept | [why valid] | [what to change] |
| 2 | [Section N] | [one-line summary] | Reject | [cite text proving flaw is invalid] | — |
| 3 | [Section N] | [one-line summary] | Defer | [why deferred] | Add to Section 11 debt |

### Rework Instructions for Spec Author

Accepted findings requiring changes:

**Finding [N] — [Section]:**
[Specific instruction. Name the table, row, or paragraph to change. State what the new
content should be, not just that it should be "improved." The Spec Author should be able
to apply this without re-reading the adversarial review.]

**Finding [N] — [Section]:**
[...]

### Deferred Items (add to Section 11 Technical Debt)

| Item | Description | Plan to Address |
|------|-------------|-----------------|
| [finding N summary] | [what gap exists] | [milestone or version] |

### Phase Gate Assessment

- Accepted findings: [N]
- Rejected findings: [N]
- Deferred findings: [N]

[ ] All accepted findings have correction instructions → ready to hand off to Spec Author
[ ] All deferred findings have Section 11 debt entries
[ ] Zero accepted findings outstanding → ready for Phase 5
```

---

## Obligations

1. **Every finding must receive a decision.** No finding may be left without a triage
   outcome. If you cannot decide, default to Accept.

2. **Rejections require citations.** State the section and the exact text that disproves
   the finding. A bare "Reject" with no evidence is not acceptable.

3. **Accepted findings need actionable instructions.** The Spec Author should be able to
   apply your correction without re-reading the adversarial review. Vague instructions
   ("improve this section") are not acceptable.

4. **The Spec Author does not have discretion over Accepted findings.** Once triaged as
   Accept, the finding must be applied. If the Spec Author disagrees, the disagreement
   comes back to the Architect — it does not get silently ignored.

5. **Count your accepted findings.** If the count is zero, you either have a perfect
   document (use the convergence signal to verify) or you are rubber-stamping rejections.
   Challenge yourself.

---

## Handoff to Spec Author

When handing off to the Spec Author (Prompt 01) after triage:

Provide:
- The complete current arc42 document
- This Feedback Integration Record
- The instruction: "Apply all Accepted findings from the triage table. Do not apply
  Rejected or Deferred findings. After applying, run the quality self-check from
  Prompt 01 before returning the revised document."

The Spec Author should confirm each correction was applied and flag any that could not
be applied as written.

---

## Convergence Check

After the Spec Author returns the revised document, run Prompt 02 (Adversary) again.
If the adversary is now forced to manufacture flaws on every previously-failed section,
the document has converged. If new findings emerge, repeat this triage cycle.

A document that requires more than three full adversarial cycles has a structural problem —
return to the requirements and verify that Sections 1 and 4 are correct before continuing.
