---
description: Gather Section 11 — Risks and Technical Debt (risk register, debt quadrant)
---

You are gathering information for **Section 11 — Risks and Technical Debt** of an arc42 architecture document.

**Standards:**
- arc42 §11 — https://docs.arc42.org/section-11/
- ISO 31000 risk management — https://www.iso.org/iso-31000-risk-management.html  
  Risks are assessed on a Likelihood × Impact matrix (High/Medium/Low × High/Medium/Low) per ISO 31000.
- Technical Debt Quadrant (Martin Fowler) — https://martinfowler.com/bliki/TechnicalDebtQuadrant.html  
  Debt is categorised as Reckless/Prudent × Deliberate/Inadvertent to distinguish conscious
  trade-offs from oversights. Only Prudent debt is worth explicitly planning to address.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. If `requirements.md` exists, read Section 07 (Assumptions and Dependencies). Unverified assumptions are risk sources; dependencies that could be delayed or unavailable are also risks. Show: "From requirements.md, these assumptions and dependencies may represent risks: [list items where 'Impact if Wrong' column is populated]."
3. Extract the `## 11 — Risks and Technical Debt` block. If Status is not `empty`, or if tables have entries beyond the header, show the existing content and ask: "Section 11 already has content — would you like to (a) add more entries, (b) update existing ones, or (c) replace entirely?"
4. Ask the questions below one topic at a time. Wait for each answer before continuing.
5. Write the structured output back into the `## 11` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Risks**
"The assumptions and dependencies from requirements.md are good starting candidates for the risk register. What additional risks should be captured?

For each risk:
- A brief description of what could go wrong
- Likelihood: High (likely to occur), Medium (possible), or Low (unlikely but significant if it does)
- Impact: High (project-threatening or severe user impact), Medium (significant but recoverable), Low (minor)
- What mitigation is in place or planned?

Risk categories to consider: technical risks (unknown technology, integration complexity), organisational risks (key person dependency, team changes), external risks (third-party API reliability, regulatory change)."

**Technical Debt**
"What known technical debt exists in the system?

For each debt item, classify it using the Fowler Technical Debt Quadrant (https://martinfowler.com/bliki/TechnicalDebtQuadrant.html):
- **Prudent + Deliberate** — 'We know this is a shortcut; we'll fix it when X happens' (most valuable to document)
- **Prudent + Inadvertent** — 'Now we know better, we should refactor this'
- **Reckless + Deliberate** — 'We don't have time for design' (flag; should be minimal)
- **Reckless + Inadvertent** — discovered later; often found during code review

For each debt item: description, quadrant, and plan to address (or explicit decision to leave it)."

## Output format

Replace the `## 11 — Risks and Technical Debt` block with:

```markdown
## 11 — Risks and Technical Debt
<!-- arc42 §11 — https://docs.arc42.org/section-11/ -->
<!-- ISO 31000 risk management — https://www.iso.org/iso-31000-risk-management.html -->
<!-- Technical Debt Quadrant (Fowler) — https://martinfowler.com/bliki/TechnicalDebtQuadrant.html -->
<!-- Status: complete -->

### Risks
| ID | Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| R-01 | [description] | [H/M/L] | [H/M/L] | [mitigation] |

### Technical Debt
| ID | Description | Quadrant | Plan |
| --- | --- | --- | --- |
| TD-01 | [description] | [Prudent/Reckless × Deliberate/Inadvertent] | [plan or explicit deferral] |
```
