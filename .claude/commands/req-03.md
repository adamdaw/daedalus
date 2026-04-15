---
description: Gather non-functional requirements (ISO/IEC 25010 quality categories, measurable criteria)
---

You are gathering non-functional requirements for the **Requirements Specification** of a system.

**Standards:**
- ISO/IEC/IEEE 29148:2018 §5.2.5 — system requirements — https://www.iso.org/standard/72089.html
- ISO/IEC 25010 quality model — https://iso25010.info  
  NFRs are categorised using the eight ISO 25010 quality characteristics to ensure they
  are internationally recognised and unambiguous. Every NFR must have a measurable criterion —
  "fast" and "reliable" are descriptions, not requirements.
- MoSCoW prioritisation (DSDM) — https://www.agilebusiness.org/dsdm-project-framework/moscow-prioririsation.html

## Procedure

1. Read `requirements.md` in the current directory. If it does not exist, read `templates/requirements.md` and write it as `requirements.md`.
2. Extract the `## 05 — Non-Functional Requirements` block. If Status is not `empty`, or if the table has entries, show the existing content and ask: "Section 05 already has content — would you like to (a) add more NFRs, (b) update existing ones, or (c) replace entirely?"
3. Ask the question below. Wait for the full answer before continuing. If a criterion is vague ("fast", "reliable", "secure"), probe for a specific measure before accepting it.
4. Write the structured output back into the `## 05` block of `requirements.md`. Update the Status comment to `complete`. Do not modify any other section.

## Question

"What are the non-functional requirements for this system?

Work through the ISO/IEC 25010 quality categories that are relevant to your system. For each requirement:
- **ISO 25010 Category** — which quality characteristic does this belong to?
- **Description** — what is required?
- **Measurable Criterion** — a specific, testable measure. This is mandatory — if you cannot measure it, it is not a requirement yet. Examples:
  - 'p95 API response time ≤ 200ms under 500 concurrent users'
  - '99.9% uptime measured over a rolling 30-day window'
  - 'Zero high-severity CVEs in production container image'
  - 'WCAG 2.1 AA compliance verified by automated axe-core scan'
  - 'Deployment lead time ≤ 15 minutes from merge to production'
- **MoSCoW priority** — Must / Should / Could / Won't

**ISO 25010 categories to work through:**

- **Performance Efficiency** — response times, throughput, resource utilisation (CPU, memory, storage)
- **Reliability** — availability target (uptime %), fault tolerance, RTO/RPO (recovery time and point objectives)
- **Security** — authentication method, authorisation model, data protection at rest and in transit, relevant compliance requirements (GDPR, HIPAA, SOC 2, PCI DSS)
- **Maintainability** — test coverage targets, deployment frequency, change lead time, MTTR (mean time to recovery)
- **Usability** — accessibility standard (WCAG level), onboarding / time-to-competency target, supported languages
- **Compatibility** — browser/OS/platform support matrix, API versioning policy, integration requirements
- **Portability** — cloud portability, containerisation requirements, data migration or export requirements

Skip categories that genuinely do not apply to your system — but note explicitly why (e.g., 'Portability: N/A — single-cloud deployment by policy')."

## Output format

Replace the `## 05 — Non-Functional Requirements` block with:

```markdown
## 05 — Non-Functional Requirements
<!-- ISO/IEC/IEEE 29148:2018 §5.2.5 — system requirements -->
<!-- ISO/IEC 25010 quality model — https://iso25010.info -->
<!-- Every NFR must have a measurable criterion — vague descriptors are not accepted -->
<!-- MoSCoW: M = Must, S = Should, C = Could, W = Won't (this release) -->
<!-- Status: complete -->

| ID | ISO 25010 Category | Description | Measurable Criterion | Priority |
| --- | --- | --- | --- | --- |
| NFR-01 | [category] | [description] | [specific, testable measure] | M/S/C/W |
```

If the user provides a vague criterion, note it in the table but add a comment: `<!-- NFR-NN: criterion needs quantification before this can be verified -->`.
