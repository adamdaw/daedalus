---
description: Gather stakeholders for the Requirements Specification (ISO/IEC/IEEE 29148:2018 §5.2.4)
---

You are gathering stakeholder information for the **Requirements Specification** of a system.

**Standards:**
- ISO/IEC/IEEE 29148:2018 §5.2.4 — stakeholder identification and analysis — https://www.iso.org/standard/72089.html
- IREB CPRE Handbook — stakeholder classification — https://www.ireb.org/en/cpre/

## Procedure

1. Read `requirements.md` in the current directory. If it does not exist, read `templates/requirements.md` and write it as `requirements.md`.
2. Extract the `## 02 — Stakeholders` block. If Status is not `empty`, or if the table has entries beyond the header, show the existing content and ask: "Section 02 already has content — would you like to (a) add more stakeholders, (b) update existing ones, or (c) replace entirely?"
3. Ask the questions below. Wait for each answer before continuing.
4. Write the structured output back into the `## 02` block of `requirements.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Stakeholder identification**
"Who are the stakeholders for this system?

For each stakeholder:
- **Role or title** — what do they do? (e.g., 'End User', 'System Administrator', 'Product Owner', 'Operations Engineer', 'External Integrator', 'Regulator')
- **Organisation or context** — internal team, customer, partner, regulator, etc.
- **Goals** — what do they need this system to do for them? What problem does it solve for them?
- **Priority**: High (decision-maker or heavily impacted by the system), Medium (regular user or contributor), Low (peripheral interest or indirect stakeholder)

Categories to ensure you cover:
- **End users** — people who use the system day-to-day
- **Administrators** — people who configure, deploy, or maintain it
- **Business owners** — people with budget authority or business accountability
- **Operations / SRE** — people who run it in production and respond to incidents
- **External integrators** — systems or teams that consume or feed the system's APIs
- **Regulators or compliance bodies** — if any regulatory requirements apply"

**Purpose and scope** (after stakeholders are captured)
"Now that we have the stakeholders:

1. In one or two sentences, what is the **purpose** of this requirements specification — what system is it for and who is the intended audience?
2. What is **in scope** — what the system being specified includes?
3. What is **out of scope** — what is explicitly excluded, to prevent scope creep?"

## Output format

Replace the `## 01 — Purpose and Scope` and `## 02 — Stakeholders` blocks with:

```markdown
## 01 — Purpose and Scope
<!-- Status: complete -->

**Purpose:** [one or two sentences on what this spec covers and its audience]

**In scope:** [what the system includes]

**Out of scope:** [what is explicitly excluded]

### Definitions
| Term | Definition |
| --- | --- |
| [term] | [definition — only if domain-specific terms were mentioned] |

---

## 02 — Stakeholders
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — stakeholder identification and analysis -->
<!-- IREB CPRE Handbook — https://www.ireb.org/en/cpre/ -->
<!-- Status: complete -->

| ID | Role | Organisation / Context | Goals | Priority |
| --- | --- | --- | --- | --- |
| STK-01 | [role] | [context] | [goals] | [High/Medium/Low] |
```
