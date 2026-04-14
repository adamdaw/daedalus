# mem-1 — Project Context

**Maintained by:** Adam Daw (Bespoke Informatics)
**Load at:** Start of every agent session that touches architectural documentation.

---

## What Daedalus Is

Daedalus is an arc42 architectural documentation pipeline. Authors write content in
Markdown; the pipeline (Pandoc + XeLaTeX + mermaid-filter + pandoc-crossref) produces
a professional PDF, HTML, and DOCX. It is version-controlled, CI-validated, and
Docker-reproducible.

Every proposal lives in `proposals/<name>/`. Use `make init NAME=<name>` to scaffold.
Use `make build PROPOSAL=<name>` to produce the PDF.

---

## Document Authority Hierarchy

1. **The Architect (human)** — final authority on all architectural decisions. Signs off on
   specs, arbitrates adversarial findings, accepts or rejects ADRs.
2. **The arc42 Specification** — the arc42 document is the source of truth for what the
   architecture is and why. If an implementation diverges from the spec, the spec wins or
   the ADR explaining the divergence must be updated.
3. **ADRs (Section 9)** — individual Architecture Decision Records are the authoritative
   record of significant decisions. Every significant decision must have an ADR. ADRs are
   never deleted — they are superseded.
4. **Implementation artifacts** — code, config, infrastructure — must be consistent with the
   spec. When they aren't, it's either a bug or an un-documented ADR.

---

## Agent Roles in the VSDD Pipeline

| Role | Agent | Prompt File | Responsibility |
| --- | --- | --- | --- |
| **The Architect** | Human | `prompts/00-workflow.md` | Strategic vision, session orchestration, acceptance authority |
| **Spec Author** | Claude (Builder) | `prompts/01-arch-spec-author.md` | Drafts arc42 sections from requirements and constraints |
| **Adversary (Spec)** | Sarcasmotron / Gemini | `prompts/02-adversary-arch.md` | Adversarial review of the arc42 document |
| **ADR Author** | Claude (Builder) | `prompts/03-adr-author.md` | Documents architectural decisions as structured ADRs |
| **Feedback Triage** | Architect (human) | `prompts/04-feedback-triage.md` | Triages adversarial findings: Accept / Reject / Defer |

---

## Phase Gate Rules

Before a proposal document is considered complete, **all** of the following must hold:

1. **Sections 1–11 and 99 are substantively filled** — no placeholder rows left, no
   "TBD" in quality scenarios, no empty ADR context fields.
2. **Section 9 has at least one ADR per significant technology or structural decision**
   identified in Section 4 (Solution Strategy). If Section 4 lists a decision, Section 9
   must explain why.
3. **Every quality goal in Section 1 has a corresponding quality scenario in Section 10**
   with a measurable response measure (latency figure, uptime percentage, time bound, etc.).
4. **Section 3 includes a context diagram** (flowchart TD at minimum) showing system
   boundary and external systems.
5. **Section 5 includes at least one container-level diagram** showing the main building
   blocks and their relationships.
6. **Section 6 includes at least one sequence diagram** for the primary use case.
7. **The document builds without error** — `make build PROPOSAL=<name>` produces a PDF.
8. **Lint and spellcheck pass** — `make validate PROPOSAL=<name>` exits 0.

The Adversary's job is to verify these gates and find everything that doesn't meet the
standard. The Architect makes the final acceptance call.

---

## The arc42 → VSDD Mapping

| VSDD Concept | arc42 Location |
| --- | --- |
| Behavioral Contract | Section 1 (Requirements Overview) |
| Interface Definition | Section 3 (Context and Scope — Technical Context) |
| Edge Case Catalog | Section 6 (Runtime View — failure scenarios) |
| Non-Functional Requirements | Section 1 (Quality Goals) |
| Provable Properties Catalog | Section 10 (Quality Scenarios with measurable response) |
| Purity Boundary Map | Section 5 (Building Block View — service boundaries) |
| Decision Records | Section 9 (Architecture Decisions — ADRs) |
| Risk Register | Section 11 (Risks and Technical Debt) |

---

## How to Reference This File

At the start of an agent session that involves authoring or reviewing an arc42 document,
paste or load this file along with the relevant prompt from `prompts/`. The Architect
provides the requirement context. The agent operates within the constraints defined here.
