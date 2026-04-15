---
description: Gather Section 10 — Quality Requirements (measurable quality scenarios per ISO/IEC 25010)
---

You are gathering information for **Section 10 — Quality Requirements** of an arc42 architecture document.

**Standards:**
- arc42 §10 — https://docs.arc42.org/section-10/
- ISO/IEC 25010 quality model — https://iso25010.info
- ATAM quality scenarios (CMU SEI) — https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908  
  A quality scenario has six parts: Stimulus Source, Stimulus, Environment, Artefact, Response, Response Measure.
  The Response Measure must be quantified — this is the most common gap in quality requirement sections.

**Note:** This section makes the quality goals from Section 01 verifiable. If Section 01 is empty, remind the user to run /gather-01 first.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. Extract the `## 10 — Quality Requirements` block. If Status is not `empty`, or if the scenarios table has entries, show the existing content and ask: "Section 10 already has content — would you like to (a) add more scenarios, (b) update existing ones, or (c) replace entirely?"
3. Check whether Section 01 has quality goals defined. If not, note: "Section 01 has no quality goals yet — consider running /gather-01 first. I can still gather scenarios if you tell me your quality goals now."
4. Ask the questions below one topic at a time. Wait for each answer before continuing.
5. Write the structured output back into the `## 10` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Quality Tree**
"Looking at the quality goals from Section 01, which are the most critical to the system's success? Rank them if there are more than three."

**Quality Scenarios**
For each quality goal (working through them one at a time):

"Let's define a measurable scenario for '[quality goal]'.

A quality scenario needs six parts (ATAM format):
1. **Stimulus Source** — who or what triggers the scenario? (e.g., a user, an automated process, a failure event)
2. **Stimulus** — what specifically happens? (e.g., '1,000 concurrent users submit orders')
3. **Environment** — under what conditions? (e.g., 'normal load', 'peak traffic', 'after a dependency failure')
4. **Artefact** — which part of the system is affected? (e.g., 'the order service', 'the entire system')
5. **Response** — what should the system do?
6. **Response Measure** — how do we quantify success? This must be a number. (e.g., '95th percentile response time ≤ 200ms', 'zero data loss', 'system recovers within 30 seconds')

The Response Measure is the most important part — without a number, the requirement cannot be tested."

## Output format

Replace the `## 10 — Quality Requirements` block with:

```markdown
## 10 — Quality Requirements
<!-- arc42 §10 — https://docs.arc42.org/section-10/ -->
<!-- ISO/IEC 25010 — https://iso25010.info -->
<!-- ATAM quality scenarios — https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908 -->
<!-- Status: complete -->

### Quality Tree
| Quality Goal | Scenario ID | Priority |
| --- | --- | --- |
| [quality goal] | QS-01 | [High/Medium/Low] |

### Quality Scenarios
| ID | Quality Goal | Stimulus | Environment | Response | Response Measure |
| --- | --- | --- | --- | --- | --- |
| QS-01 | [goal] | [stimulus source + stimulus] | [conditions] | [what happens] | [quantified measure] |
```
