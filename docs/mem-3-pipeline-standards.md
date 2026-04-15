# mem-3 — Pipeline Technical Standards

**Maintained by:** Adam Daw (Bespoke Informatics)
**Load at:** Any session that involves writing or editing Markdown content for daedalus.

---

## Build Reference

```bash
# Build outputs for a proposal
make build  PROPOSAL=<name>   # → proposals/<name>/project.pdf
make html   PROPOSAL=<name>   # → proposals/<name>/project.html
make docx   PROPOSAL=<name>   # → proposals/<name>/project.docx
make all    PROPOSAL=<name>   # PDF + HTML + DOCX

# Quality checks
make validate PROPOSAL=<name> # lint + spellcheck

# Add a section
make new-section TITLE="Security Review" PROPOSAL=<name>
# Creates the next numbered file in proposals/<name>/markdown/

# Root example (no PROPOSAL=)
make build && make validate
```

---

## arc42 Section Authoring Standards

### Section 1 — Introduction and Goals
- Requirements table must use IDs (R-01, R-02, …) and Priority (High/Medium/Low).
- Quality Goals must be **concrete**, not generic. "Performance" is a category.
  "Order pipeline sustains 500 orders/minute at peak" is a quality goal.
- Stakeholders table must include Operations/SRE. Architecture decisions have operational
  consequences that must be represented in the stakeholder list.

### Section 2 — Constraints
- Distinguish technical constraints (technology choices that cannot be changed) from
  organisational constraints (process, budget, team structure).
- Every constraint must have a "Background / Motivation" column entry.
  A constraint without motivation is an assumption masquerading as a constraint.

### Section 3 — Context and Scope
- **Must include a context diagram** — at minimum a flowchart showing the system boundary,
  external systems, and the direction of data flow.
- The Technical Context table documents protocols and data formats, not just system names.
- "Internal" is not a valid interface description.

### Section 4 — Solution Strategy
- The "Approach to Quality Goals" table must connect each Section 1 quality goal to a
  specific architectural mechanism. Vague answers ("good design") do not meet the standard.

### Section 5 — Building Block View
- The Level 1 diagram is required. Use flowchart TD with a `subgraph` for the system
  boundary.
- Each building block in the diagram must appear in the table below it.
- If a building block is complex enough to warrant decomposition, add a Level 2 subsection.

### Section 6 — Runtime View
- The primary use case scenario is required.
- At least one **failure or error scenario** is required. Systems that only document happy
  paths have incomplete specs.
- Use `sequenceDiagram` for runtime views. `actor` keyword for human participants.
- Do not use `Note over` for non-trivial logic — put it in the prose above the diagram.

### Section 9 — Architecture Decisions (ADRs)
- Every ADR must have: Status, Date, Context, Decision, Consequences.
- The Decision field must be a single unambiguous statement starting with "We will …".
- Consequences must acknowledge **negative** consequences, not just positive ones.
- Status must be one of: `Proposed`, `Accepted`, `Deprecated`, `Superseded by ADR-NNN`.
- Do not number ADRs retroactively — assign the next available number when written.

### Section 10 — Quality Requirements
- Quality scenarios must have a **measurable response measure** column.
  "Fast" is not measurable. "≤ 200 ms p95" is measurable.
- The stimulus and system state columns must be specific enough that someone could write
  a load test or chaos experiment based on the scenario.

### Section 11 — Risks and Technical Debt
- Risk Probability must be one of: High, Medium, Low.
- Risk Impact must be one of: High, Medium, Low.
- Every risk with High impact must have a concrete Mitigation, not "monitor and address."
- Technical debt items must have a "Plan to Address" that names a timeline or milestone.

---

## Mermaid Diagram Standards

Use C4-aligned diagram types:
- **Context level (Section 3):** `flowchart TD` with `([External System])` round-rectangle
  for external actors and `[System Name]` for the system under design.
- **Container level (Section 5):** `flowchart TD` with `subgraph` for the system boundary.
- **Sequence diagrams (Section 6):** `sequenceDiagram` with `actor` for humans,
  `participant X as Alias` for services.
- **Deployment view (Section 7):** `flowchart TD` with nested `subgraph` blocks for cloud
  regions and availability zones.

**Node notation:**
- `([Text])` — external person/system (rounded rectangle, stadium shape)
- `[Text]` — internal service or component
- `[(Text)]` — database
- `[[Text]]` — queue / message bus
- `{Text}` — decision (rarely used in architecture diagrams)

**Theme:** Default unless `MERMAID_THEME=dark` is set. Dark theme recommended when
producing documents intended for dark-mode viewing.

---

## Cross-References and Citations

### Cross-references (pandoc-crossref)
- Label figures: `![Caption](image.png){#fig:id}`
- Label tables: `Table: Caption {#tbl:id}` (on a line immediately after the table)
- Cite: `[@fig:id]`, `[@tbl:id]`
- Sections (if `autoSectionLabels: true` in config.yaml): `[@sec:id]`

### Bibliography citations
- Add entries to `project.bib` (BibTeX format)
- Cite inline: `[@Key]` — e.g., `[@Newman2019]`
- The `# References` section in `99_References.md` is populated automatically by
  `--citeproc`. Do not add manual reference lists.

---

## Document Metadata (config.yaml)

Minimum required fields for a proposal:
```yaml
title: "..."
author: "..."
date: "Month Year"
papersize: a4          # or letter
highlight-style: tango
```

Optional but recommended:
```yaml
subtitle: "..."
numbersections: true   # for formal documents
abstract: |            # executive summary before TOC
  One-paragraph summary.
```

For client deliverables, add cover page fields via `header-includes`:
```yaml
header-includes:
  - \def\docclient{Client Name}
  - \def\docversion{1.0}
  - \def\docclassification{Internal Use Only}
```

---

## CI Validation Expectations

A proposal PDF must pass all of the following in CI:
- **Page count ≥ 5** (for the root example; proposals use page count ≥ 1)
- **Section headings present:** Introduction, Context, Solution Strategy, Building Block,
  Deployment, Risks, References
- HTML must contain at least one `<h1>` element

These checks run in `build.yml`, `proposals.yml`, and `release.yml`.

---

## Spell Check Reference

Use British English throughout. codespell's default dictionaries (`clear`, `rare`) focus on
unambiguous typos; the `en-GB_to_en-US` dictionary is not enabled, so British spellings
(`organisation`, `colour`, `analyse`, `licence`, `fulfil`, etc.) are not flagged.

Acronyms (JWT, ECS, SQS, ADR) are not flagged.

If a domain term is incorrectly flagged, add it to `.codespellrc` as:

```ini
ignore-words-list = term1,term2
```
