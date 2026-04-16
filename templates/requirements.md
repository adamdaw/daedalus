# Requirements Specification
<!-- ISO/IEC/IEEE 29148:2018 — https://www.iso.org/standard/72089.html -->
<!-- MoSCoW prioritisation (DSDM) — https://www.agilebusiness.org/dsdm-project-framework/moscow-prioririsation.html -->
<!-- BDD acceptance criteria — https://cucumber.io/docs/bdd/better-gherkin/ -->
<!-- IREB CPRE Handbook — https://www.ireb.org/en/cpre/ -->
<!-- Populated section by section using /req-01 through /req-05. -->
<!-- Synthesis from existing material: use prompts/06-req-author.md. -->
<!-- Feeds into /gather-* commands and prompts/01-arch-spec-author.md. -->

> **System:** [system name]
> **Date:** [date]
> **Version:** 0.1 — draft

---

## 01 — Purpose and Scope
<!-- Status: empty -->

**Purpose:** [what this requirements specification covers and its intended audience]

**In scope:** [what the system being specified includes]

**Out of scope:** [what is explicitly excluded from this system]

### Definitions
| Term | Definition |
| --- | --- |

---

## 02 — Stakeholders
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — stakeholder identification and analysis -->
<!-- IREB CPRE — stakeholder classification: user, subject matter expert, decision-maker, sponsor -->
<!-- Status: empty -->

| ID | Role | Organisation / Context | Goals | Priority |
| --- | --- | --- | --- | --- |
| STK-01 | | | | High/Medium/Low |

---

## 03 — Business Requirements
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — business/stakeholder requirements -->
<!-- MoSCoW: M = Must (non-negotiable), S = Should (important), C = Could (nice-to-have), W = Won't (this release) -->
<!-- Status: empty -->

Business goals and success criteria — what the system must achieve at the business level.

| ID | Goal | Success Criterion | Priority |
| --- | --- | --- | --- |
| BR-01 | | | M/S/C/W |

---

## 04 — Functional Requirements
<!-- ISO/IEC/IEEE 29148:2018 §5.2.5 — system/software requirements -->
<!-- User story format: As a [role], I want [capability], so that [benefit] -->
<!-- MoSCoW: M = Must, S = Should, C = Could, W = Won't (this release) -->
<!-- Status: empty -->

Organised by functional area. Each story has a unique FR-NN identifier for traceability.

### [Feature Area]
| ID | User Story | Priority |
| --- | --- | --- |
| FR-01 | As a …, I want …, so that … | M |

---

## 05 — Non-Functional Requirements
<!-- ISO/IEC 25010 quality model — https://iso25000.com/en/iso-25000-standards/iso-25010 -->
<!-- Categories: Performance Efficiency, Reliability, Security, Maintainability, Usability, Compatibility, Portability -->
<!-- Every NFR must have a measurable criterion — vague descriptors ("fast", "reliable") are not requirements -->
<!-- MoSCoW: M = Must, S = Should, C = Could, W = Won't (this release) -->
<!-- Status: empty -->

| ID | ISO 25010 Category | Description | Measurable Criterion | Priority |
| --- | --- | --- | --- | --- |
| NFR-01 | | | | M/S/C/W |

---

## 06 — Constraints
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — constraints on requirements -->
<!-- Distinguish: technical constraints (technology, platform, integration) from -->
<!-- organisational constraints (budget, timeline, compliance, team) -->
<!-- Status: empty -->

### Technical Constraints
| ID | Constraint | Rationale |
| --- | --- | --- |
| TC-01 | | |

### Organisational Constraints
| ID | Constraint | Rationale |
| --- | --- | --- |
| OC-01 | | |

---

## 07 — Assumptions and Dependencies
<!-- ISO/IEC/IEEE 29148:2018 §5.2.4 — assumptions and dependencies -->
<!-- Assumption: something believed to be true that has not been verified -->
<!-- Dependency: something external that the system or project relies on -->
<!-- Status: empty -->

| ID | Type | Description | Impact if Wrong / Unavailable |
| --- | --- | --- | --- |
| A-01 | Assumption | | |
| D-01 | Dependency | | |

---

## 08 — Acceptance Criteria
<!-- BDD Given/When/Then — de facto standard for testable acceptance criteria -->
<!-- IEEE 29148 verification methods: Test, Inspection, Demonstration, Analysis -->
<!-- Cover all Must requirements; Should requirements where feasible -->
<!-- Status: empty -->

| ID | Requirement Ref | Given | When | Then | Verification |
| --- | --- | --- | --- | --- | --- |
| AC-01 | FR-01 | | | | Test |

---

## 09 — Requirements Traceability Matrix
<!-- ISO/IEC/IEEE 29148:2018 §5.2.8 — requirements traceability -->
<!-- Maps each requirement to the arc42 section(s) that address it -->
<!-- arc42: §1 = Introduction/Goals, §2 = Constraints, §3 = Context, §4 = Solution Strategy, -->
<!--        §5 = Building Blocks, §6 = Runtime, §7 = Deployment, §8 = Cross-cutting, -->
<!--        §10 = Quality Scenarios, §11 = Risks -->
<!-- Status: empty -->

| Requirement ID | Summary | arc42 Section(s) | Status |
| --- | --- | --- | --- |
| FR-01 | | | Untraced |
