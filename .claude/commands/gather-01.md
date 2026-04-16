---
description: Gather Section 01 — Introduction and Goals (requirements, quality goals, stakeholders)
---

You are gathering information for **Section 01 — Introduction and Goals** of an arc42 architecture document.

**Standards:**
- arc42 §1 — https://docs.arc42.org/section-1/
- ISO/IEC 25010 quality model — https://iso25000.com/en/iso-25000-standards/iso-25010
- SMART requirements (Specific, Measurable, Achievable, Relevant, Time-bound)

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. If `requirements.md` exists in the current directory, read it and extract:
   - Section 02 (Stakeholders) — Role, Goals, Priority columns
   - Sections 03–04 (Business + Functional Requirements) — a brief summary
   - Section 05 (Non-Functional Requirements) — Category, Description, Measurable Criterion
   Show the user a summary: "I found the following in your requirements specification:" followed by a condensed table of what was extracted. Then note: "I will use these as context. The questions below focus on architecture-specific aspects."
   If `requirements.md` does not exist, note: "No requirements.md found. Consider running /req-01 through /req-05 first for a richer foundation, or proceed to gather requirements fresh here."
3. Extract the `## 01 — Introduction and Goals` block. If Status is not `empty`, or if any tables contain rows beyond the header, show the existing content and ask: "Section 01 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
4. Ask the questions below one topic at a time. Wait for each answer before continuing. If an answer is vague or generic, ask one follow-up to make it concrete and measurable.
5. Write the structured output back into the `## 01` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**System Overview**
"Describe the system in one or two sentences: what it does and for whom."

**Requirements**
"Are there additional requirements beyond what is in requirements.md that should appear in the architecture brief? Any requirements you want to reframe or prioritise differently for the architecture audience? If requirements.md covers everything, summarise the key requirements for inclusion.

For each, try to be SMART — Specific, Measurable, Achievable, Relevant, Time-bound. For example: 'The order pipeline must sustain 500 orders per minute at peak load' rather than 'the system must handle high load'."

**Quality Goals**
"From requirements.md, the non-functional requirements suggest these quality concerns: [reference NFRs]. Which 3 should be the top quality goals for the architecture? Are there architecture-level quality concerns not captured in the requirements?

Pick from the ISO/IEC 25010 quality characteristics:
- Performance Efficiency — response time, throughput, resource usage
- Compatibility — interoperability with other systems
- Usability — ease of use, learnability
- Reliability — availability, fault tolerance, recoverability
- Security — confidentiality, integrity, authentication
- Maintainability — modularity, testability, modifiability
- Portability — adaptability across environments

For each goal, give the specific business motivation — why does this matter for your system?"

**Stakeholders**
"requirements.md lists these stakeholders: [reference]. Are there additional architecture stakeholders not listed there — such as the platform team, SRE, external API consumers, or the security team?

For each stakeholder, give their role and what they expect from this system. Include both business stakeholders (product owner, end users) and technical stakeholders (developers, operators, security team)."

## Output format

Replace the `## 01 — Introduction and Goals` block with:

```markdown
## 01 — Introduction and Goals
<!-- arc42 §1 — https://docs.arc42.org/section-1/ -->
<!-- ISO/IEC 25010 quality model — https://iso25000.com/en/iso-25000-standards/iso-25010 -->
<!-- Status: complete -->

### System Overview
[user's answer]

### Requirements
<!-- SMART: Specific, Measurable, Achievable, Relevant, Time-bound -->
| ID | Requirement | Priority |
| --- | --- | --- |
| R-01 | [requirement] | [High/Medium/Low] |

### Quality Goals
<!-- ISO/IEC 25010: https://iso25000.com/en/iso-25000-standards/iso-25010 -->
| Priority | Quality Goal | Motivation |
| --- | --- | --- |
| 1 | [characteristic] | [specific motivation] |

### Stakeholders
| Role | Expectations |
| --- | --- |
| [role] | [expectations] |
```
