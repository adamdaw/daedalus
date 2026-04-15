---
description: Gather Section 06 — Runtime View (key scenarios and interaction sequences)
---

You are gathering information for **Section 06 — Runtime View** of an arc42 architecture document.

**Standards:**
- arc42 §6 — https://docs.arc42.org/section-6/
- UML 2.5 Sequence Diagrams — https://www.omg.org/spec/UML/2.5.1  
  Scenarios are described as actor–system interaction sequences; the spec author
  will render them as Mermaid sequence diagrams in the finished document.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. If `requirements.md` exists, read Sections 03–04 (Functional Requirements). Note key user stories that map to runtime scenarios — suggest these as scenario candidates.
3. Extract the `## 06 — Runtime View` block. If Status is not `empty`, or if content is populated beyond the skeleton, show the existing content and ask: "Section 06 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
4. Ask the questions below one topic at a time. Wait for each answer before continuing.
5. Write the structured output back into the `## 06` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Scenario Selection**
"What are the 2–4 most important runtime scenarios for this system?

These should be the scenarios that best illustrate how the system works, or the ones that are most critical to get right. Good candidates:
- The primary happy path (the most common user journey)
- A failure or error scenario that requires special handling
- A scenario that involves multiple systems or complex coordination
- A scenario that demonstrates how a quality goal (e.g. reliability) is achieved"

**Scenario Detail — for each scenario identified above, ask:**
"Walk me through '[scenario name]' step by step:
1. Who or what initiates it?
2. What happens next — which containers or external systems are involved, in what order?
3. What data is passed at each step?
4. How does it end (success state, and what happens on failure)?"

**Sequence Diagram**
"I'll draft a Mermaid sequence diagram for this scenario based on the steps you described."

Generate a `sequenceDiagram` from the gathered actors, systems, and steps. Include it in the output format within each scenario detail block.

Repeat for each scenario, keeping the detail at the level of container-to-container interactions rather than line-by-line code.

## Output format

Replace the `## 06 — Runtime View` block with:

```markdown
## 06 — Runtime View
<!-- arc42 §6 — https://docs.arc42.org/section-6/ -->
<!-- UML 2.5 Sequence Diagrams — https://www.omg.org/spec/UML/2.5.1 -->
<!-- Status: complete -->

### Key Scenarios
| ID | Scenario | Why It Matters |
| --- | --- | --- |
| SC-01 | [name] | [why it matters] |

### Scenario Detail

#### SC-01 — [Scenario Name]
**Initiator:** [who/what starts it]
**Steps:**
1. [step — actor/system → actor/system: what happens]
2. ...

```mermaid
sequenceDiagram
    [generated from scenario steps]
```

**Success end state:** [what correct completion looks like]
**Failure handling:** [what happens if it goes wrong]
```

Repeat the Scenario Detail block for each scenario.
