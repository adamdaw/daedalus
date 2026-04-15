---
description: Gather acceptance criteria (BDD Given/When/Then) and populate the traceability matrix
---

You are gathering acceptance criteria for the **Requirements Specification** of a system,
and populating the Requirements Traceability Matrix.

**Standards:**
- BDD Given/When/Then — de facto industry standard for testable acceptance criteria — https://cucumber.io/docs/bdd/better-gherkin/
- IEEE 29148 verification methods: Test, Inspection, Demonstration, Analysis — https://www.iso.org/standard/72089.html
- ISO/IEC/IEEE 29148:2018 §5.2.8 — requirements traceability — https://www.iso.org/standard/72089.html
- arc42 section mapping for the RTM: §1 = Introduction/Goals, §2 = Constraints, §3 = Context,
  §4 = Solution Strategy, §5 = Building Blocks, §6 = Runtime, §7 = Deployment,
  §8 = Cross-cutting Concepts, §10 = Quality Scenarios, §11 = Risks

## Procedure

1. Read `requirements.md` in the current directory. If it does not exist, stop and ask the user to run `/req-01` through `/req-04` first — acceptance criteria cannot be written without requirements.
2. Extract the `## 04 — Functional Requirements` and `## 05 — Non-Functional Requirements` blocks to get the list of requirements to work from.
3. Extract the `## 08 — Acceptance Criteria` block. If Status is not `empty`, or if the table has entries, show the existing content and ask: "Section 08 already has content — would you like to (a) add criteria for more requirements, (b) update existing ones, or (c) replace entirely?"
4. Ask the questions below, working through Must requirements first, then Should. Wait for each answer before continuing.
5. Write the structured output back into the `## 08` and `## 09` blocks of `requirements.md`. Update Status comments to `complete`. Do not modify any other section.

## Questions

**Acceptance criteria**
For each Must requirement (starting with functional, then non-functional):

"Let's define the acceptance criterion for **[FR-NN / NFR-NN]: [user story or NFR description]**.

A Given/When/Then scenario:
1. **Given** — the pre-conditions or state of the system/context before the action
2. **When** — the specific action or event that occurs
3. **Then** — the observable, testable outcome that proves the requirement is met

**Then** must be falsifiable — it should be possible to determine with certainty whether the outcome occurred.

**Verification method** — how will this criterion be confirmed?
- **Test**: automated or manual test case
- **Inspection**: code, configuration, or document review
- **Demonstration**: live walkthrough for a stakeholder
- **Analysis**: measurement, data analysis, or calculation (common for NFRs)

Example (FR):
- Given: a registered user is on the login page
- When: they enter valid credentials and submit
- Then: they are redirected to the dashboard within 2 seconds and their session is active
- Verification: Test

Example (NFR — Performance):
- Given: the system is under 500 concurrent users
- When: any user submits an API request
- Then: p95 response time is ≤ 200ms as measured by load testing
- Verification: Analysis"

**Traceability** (after all criteria are captured)
"For the RTM — for each requirement, which arc42 section(s) will address it?

| ID | Brief summary | arc42 section(s) |
| FR-01 | [summary] | e.g., §1, §6 |
| NFR-01 | [summary] | e.g., §1, §10 |

If you are not sure, use 'TBD' — the RTM is a living document and can be completed after the arc42 spec is drafted."

## Output format

Replace the `## 08 — Acceptance Criteria` and `## 09 — Requirements Traceability Matrix` blocks with:

```markdown
## 08 — Acceptance Criteria
<!-- BDD Given/When/Then — https://cucumber.io/docs/bdd/better-gherkin/ -->
<!-- IEEE 29148 verification methods: Test, Inspection, Demonstration, Analysis -->
<!-- Status: complete -->

| ID | Requirement Ref | Given | When | Then | Verification |
| --- | --- | --- | --- | --- | --- |
| AC-01 | FR-01 | [pre-conditions] | [action] | [observable outcome] | Test |

---

## 09 — Requirements Traceability Matrix
<!-- ISO/IEC/IEEE 29148:2018 §5.2.8 — requirements traceability -->
<!-- Status: complete -->

| Requirement ID | Summary | arc42 Section(s) | Status |
| --- | --- | --- | --- |
| FR-01 | [brief summary] | §1, §6 | Traced |
| NFR-01 | [brief summary] | §1, §10 | Traced |
```

Use `Untraced` in the Status column for any requirement the user answered 'TBD' for.
