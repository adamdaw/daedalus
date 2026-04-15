# Prompt 05 — Requirements Elicitation

**Role:** Elicitation guide (one per arc42 section)  
**Phase:** 0 — Before spec authoring  
**Invocation:** `/gather-01` through `/gather-11` Claude Code slash commands

---

## Purpose

The spec author (Prompt 01) drafts an arc42 document from requirements. This prompt set
systematically gathers those requirements before any drafting begins, section by section,
using a structured Q&A that produces `brief.md` — the handoff artifact consumed by Prompt 01.

Without elicitation, the spec author must infer requirements from whatever the user provides
ad-hoc, producing generic output. With a populated `brief.md`, the spec author works from
concrete, domain-specific inputs and produces a document that reflects the actual system.

---

## How It Works

Each `/gather-XX` command covers one arc42 section:

| Command | Section |
| --- | --- |
| `/gather-01` | Introduction and Goals |
| `/gather-02` | Constraints |
| `/gather-03` | Context and Scope |
| `/gather-04` | Solution Strategy |
| `/gather-05` | Building Block View |
| `/gather-06` | Runtime View |
| `/gather-07` | Deployment View |
| `/gather-08` | Cross-cutting Concepts |
| `/gather-09` | Architecture Decisions |
| `/gather-10` | Quality Requirements |
| `/gather-11` | Risks and Technical Debt |

Each command:
1. Reads `brief.md` in the current directory (creates it from `templates/brief.md` if absent)
2. Shows the user any existing content for that section
3. Conducts a focused Q&A (4–6 questions grounded in the relevant standard)
4. Writes structured output back into that section's block in `brief.md`

Commands are **resumable**: re-running `/gather-01` shows the existing Section 01 content
and asks whether to refine specific fields or replace the section. The Status comment
(`empty` / `in-progress` / `complete`) tracks which sections have been worked.

The sections can be run in any order and independently. Recommended order follows the
arc42 numbering; Section 01 first (quality goals from §01 are referenced in §04 and §10).

---

## Standards Applied Per Section

### §01 — Introduction and Goals
- **arc42 §1** — https://docs.arc42.org/section-1/
- **ISO/IEC 25010** quality model — https://iso25010.info  
  Quality goals are drawn from the eight ISO/IEC 25010 quality characteristics
  (Performance Efficiency, Compatibility, Usability, Reliability, Security,
  Maintainability, Portability) to ensure goals are internationally recognised and
  unambiguous.
- **SMART requirements** — requirements must be Specific, Measurable, Achievable,
  Relevant, and Time-bound to be verifiable in Section 10 quality scenarios.

### §02 — Constraints
- **arc42 §2** — https://docs.arc42.org/section-2/
- **Conway's Law** (Melvin Conway, 1967) — organisational structure influences system
  design; organisational constraints are captured explicitly to surface this tension.

### §03 — Context and Scope
- **arc42 §3** — https://docs.arc42.org/section-3/
- **C4 Model — System Context (Level 1)** — https://c4model.com  
  External actors and systems map directly to the C4 System Context diagram that
  opens Section 03 of the finished document.

### §04 — Solution Strategy
- **arc42 §4** — https://docs.arc42.org/section-4/
- Technology decisions gathered here are the precursors to ADRs in Section 09.
  Each decision is linked to a quality goal from Section 01 to make the tradeoff
  explicit.

### §05 — Building Block View
- **arc42 §5** — https://docs.arc42.org/section-5/
- **C4 Model — Container (Level 2) and Component (Level 3)** — https://c4model.com

### §06 — Runtime View
- **arc42 §6** — https://docs.arc42.org/section-6/
- **UML 2.5 Sequence Diagrams** — https://www.omg.org/spec/UML/2.5.1  
  Scenarios are described as actor–system interaction sequences, matching the
  sequence diagram format used in the finished section.

### §07 — Deployment View
- **arc42 §7** — https://docs.arc42.org/section-7/
- **C4 Model — Deployment** — https://c4model.com
- **The Twelve-Factor App** — https://12factor.net  
  Deployment environment separation (factor I) and configuration management
  (factor III) are explicitly surfaced in the questions.

### §08 — Cross-cutting Concepts
- **arc42 §8** — https://docs.arc42.org/section-8/
- **OWASP Top 10** — https://owasp.org/www-project-top-ten/  
  Security questions are framed around authentication, authorisation, and data
  protection — the three dimensions most commonly under-specified.
- **The Twelve-Factor App** — https://12factor.net  
  Logging (factor XI) and configuration (factor III) are covered in observability.

### §09 — Architecture Decisions
- **arc42 §9** — https://docs.arc42.org/section-9/
- **ADR format (Nygard, 2011)** — https://adr.github.io  
  Each decision is captured as: Context → Decision ("We will…") → Consequences.
  `/gather-09` produces ADR drafts; Prompt 03 (ADR Author) refines them into
  the formal Section 09 entries.

### §10 — Quality Requirements
- **arc42 §10** — https://docs.arc42.org/section-10/
- **ISO/IEC 25010** — https://iso25010.info
- **ATAM quality scenarios (CMU SEI)** — https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=513908  
  Each quality scenario has six fields: Stimulus Source, Stimulus, Environment,
  Artefact, Response, Response Measure. The Response Measure must be quantified —
  this is the most common gap in quality requirement sections.

### §11 — Risks and Technical Debt
- **arc42 §11** — https://docs.arc42.org/section-11/
- **ISO 31000 risk management** — https://www.iso.org/iso-31000-risk-management.html  
  Risks are assessed on a Likelihood × Impact matrix (H/M/L × H/M/L) per ISO 31000.
- **Technical Debt Quadrant (Fowler)** — https://martinfowler.com/bliki/TechnicalDebtQuadrant.html  
  Debt is categorised as Reckless/Prudent × Deliberate/Inadvertent to identify
  which debt was a conscious tradeoff vs. an oversight.

---

## Handoff to Spec Author

When all (or sufficient) sections of `brief.md` are marked `complete`, run Prompt 01
(spec author). Prompt 01 reads `brief.md` as its primary input and produces the full
arc42 document. Sections still marked `empty` will be drafted with minimal content and
flagged for review.

---

## Output File

`brief.md` lives in the proposal directory (created by `make init`, or in the current
working directory if running from an existing proposal). It is a drafting artifact —
it is not compiled by `make build`. It feeds Prompt 01 only.
