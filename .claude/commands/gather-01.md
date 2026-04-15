---
description: Gather Section 01 — Introduction and Goals (requirements, quality goals, stakeholders)
---

You are gathering information for **Section 01 — Introduction and Goals** of an arc42 architecture document.

**Standards:**
- arc42 §1 — https://docs.arc42.org/section-1/
- ISO/IEC 25010 quality model — https://iso25010.info
- SMART requirements (Specific, Measurable, Achievable, Relevant, Time-bound)

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. Extract the `## 01 — Introduction and Goals` block. If Status is not `empty`, or if any tables contain rows beyond the header, show the existing content and ask: "Section 01 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing. If an answer is vague or generic, ask one follow-up to make it concrete and measurable.
4. Write the structured output back into the `## 01` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**System Overview**
"Describe the system in one or two sentences: what it does and for whom."

**Requirements**
"What are the 3–5 most important functional requirements?

For each, try to be SMART — Specific, Measurable, Achievable, Relevant, Time-bound. For example: 'The order pipeline must sustain 500 orders per minute at peak load' rather than 'the system must handle high load'."

**Quality Goals**
"What are your top 3 quality goals? Pick from the ISO/IEC 25010 quality characteristics:
- Performance Efficiency — response time, throughput, resource usage
- Compatibility — interoperability with other systems
- Usability — ease of use, learnability
- Reliability — availability, fault tolerance, recoverability
- Security — confidentiality, integrity, authentication
- Maintainability — modularity, testability, modifiability
- Portability — adaptability across environments

For each goal, give the specific business motivation — why does this matter for your system?"

**Stakeholders**
"Who are the key stakeholders? For each, give their role and what they expect from this system. Include both business stakeholders (product owner, end users) and technical stakeholders (developers, operators, security team)."

## Output format

Replace the `## 01 — Introduction and Goals` block with:

```markdown
## 01 — Introduction and Goals
<!-- arc42 §1 — https://docs.arc42.org/section-1/ -->
<!-- ISO/IEC 25010 quality model — https://iso25010.info -->
<!-- Status: complete -->

### System Overview
[user's answer]

### Requirements
<!-- SMART: Specific, Measurable, Achievable, Relevant, Time-bound -->
| ID | Requirement | Priority |
| --- | --- | --- |
| R-01 | [requirement] | [High/Medium/Low] |

### Quality Goals
<!-- ISO/IEC 25010: https://iso25010.info -->
| Priority | Quality Goal | Motivation |
| --- | --- | --- |
| 1 | [characteristic] | [specific motivation] |

### Stakeholders
| Role | Expectations |
| --- | --- |
| [role] | [expectations] |
```
