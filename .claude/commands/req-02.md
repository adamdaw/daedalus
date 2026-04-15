---
description: Gather business and functional requirements (user stories, MoSCoW) per ISO/IEC/IEEE 29148:2018
---

You are gathering business and functional requirements for the **Requirements Specification** of a system.

**Standards:**
- ISO/IEC/IEEE 29148:2018 §5.2.4–5.2.5 — stakeholder and system requirements — https://www.iso.org/standard/72089.html
- User story format (Mike Cohn) — https://www.mountaingoatsoftware.com/agile/user-stories
- MoSCoW prioritisation (DSDM) — https://www.agilebusiness.org/dsdm-project-framework/moscow-prioririsation.html
- INVEST criteria (Bill Wake) — Independent, Negotiable, Valuable, Estimable, Small, Testable — https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/

## Procedure

1. Read `requirements.md` in the current directory. If it does not exist, read `templates/requirements.md` and write it as `requirements.md`.
2. Extract the `## 03 — Business Requirements` and `## 04 — Functional Requirements` blocks. If Status is not `empty`, or if tables have entries, show existing content and ask: "Sections 03 and 04 already have content — would you like to (a) add more requirements, (b) update existing ones, or (c) replace entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing.
4. Write the structured output back into the `## 03` and `## 04` blocks of `requirements.md`. Update Status comments to `complete`. Do not modify any other section.

## Questions

**Business requirements**
"What are the 3–5 top-level business goals this system must achieve?

For each goal:
- The goal itself (what the business needs — not how the system works)
- A measurable success criterion ('this goal is met when…')
- MoSCoW priority:
  - **Must**: non-negotiable; the project fails without it
  - **Should**: important but not critical for initial release
  - **Could**: a nice-to-have if time and budget allow
  - **Won't**: explicitly out of scope for this release (but possibly future)"

**Functional areas**
"What are the main functional areas or capabilities of this system?

Examples: 'User Authentication', 'Product Catalogue', 'Order Management', 'Reporting and Analytics', 'Admin Console', 'API Integration Layer'.

List the areas — we will then capture user stories for each."

**User stories** (repeat for each functional area identified)
"For **[functional area]**, what are the user stories?

Use the format: **As a [role], I want [capability], so that [benefit].**

For each story:
- Assign a MoSCoW priority (Must / Should / Could / Won't)
- The story should be testable — if there is no way to tell when it is done, it needs breaking down further (INVEST: Testable)

Work through the Must stories first, then Should, then Could. Won't items can be listed briefly."

## Output format

Replace the `## 03 — Business Requirements` and `## 04 — Functional Requirements` blocks with:

```markdown
## 03 — Business Requirements
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — stakeholder requirements -->
<!-- MoSCoW: M = Must, S = Should, C = Could, W = Won't (this release) -->
<!-- Status: complete -->

| ID | Goal | Success Criterion | Priority |
| --- | --- | --- | --- |
| BR-01 | [goal] | [success criterion] | M/S/C/W |

---

## 04 — Functional Requirements
<!-- ISO/IEC/IEEE 29148:2018 §5.2.5 — system/software requirements -->
<!-- User story format: As a [role], I want [capability], so that [benefit] -->
<!-- MoSCoW: M = Must, S = Should, C = Could, W = Won't (this release) -->
<!-- Status: complete -->

### [Feature Area]
| ID | User Story | Priority |
| --- | --- | --- |
| FR-01 | As a [role], I want [capability], so that [benefit] | M/S/C/W |
```

Use a separate `### [Feature Area]` subsection for each functional area. Number FR-IDs sequentially across all areas (FR-01, FR-02, … without resetting per area).
