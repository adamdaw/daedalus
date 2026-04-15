---
description: Gather Section 03 — Context and Scope (external actors, systems, system boundary)
---

You are gathering information for **Section 03 — Context and Scope** of an arc42 architecture document.

**Standards:**
- arc42 §3 — https://docs.arc42.org/section-3/
- C4 Model — System Context diagram (Level 1) — https://c4model.com  
  The external actors and systems gathered here map directly to the C4 System Context diagram in the finished section.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. Extract the `## 03 — Context and Scope` block. If Status is not `empty`, or if any tables contain rows beyond the header, show the existing content and ask: "Section 03 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing.
4. Write the structured output back into the `## 03` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**External Actors**
"Who are the external actors that interact directly with the system? For each:
- Their role or name (e.g., 'Customer', 'Administrator', 'Batch Job')
- How they interact (e.g., 'submits orders via web UI', 'triggers nightly reconciliation')

These are the people or automated agents at the system boundary — not internal components."

**External Systems**
"What external systems does your system exchange data or events with? For each:
- System name and brief purpose
- What data or events flow in each direction (into and out of your system)

Examples: payment gateways, identity providers, message queues, third-party APIs, legacy systems, data warehouses."

**System Boundary**
"What is explicitly outside the scope of this system? What responsibilities are delegated to external systems rather than owned internally?

This defines the boundary — it is as important as what the system does."

## Output format

Replace the `## 03 — Context and Scope` block with:

```markdown
## 03 — Context and Scope
<!-- arc42 §3 — https://docs.arc42.org/section-3/ -->
<!-- C4 Model — System Context (Level 1) — https://c4model.com -->
<!-- Status: complete -->

### External Actors
| Actor | Role | Interaction with System |
| --- | --- | --- |
| [actor] | [role] | [how they interact] |

### External Systems
| System | Purpose | Data / Events Exchanged |
| --- | --- | --- |
| [system] | [purpose] | [what flows in/out] |

### Out of Scope
[user's answer — what is explicitly delegated outside this system]
```
