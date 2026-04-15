# Prompt 01 — Architecture Spec Author

**Role:** Builder (Claude)  
**Phase:** VSDD Phase 1 — Spec Crystallization  
**Output:** Complete arc42 architecture specification in Markdown  
**Budget:** ~30 minutes of focused authoring

---

## Context Load

Before responding, confirm you have read:
- `docs/mem-1-project-context.md` — project context, document authority hierarchy, phase gate rules
- `docs/mem-2-vsdd-reference.md` — VSDD pipeline, convergence signal, anti-patterns
- `docs/mem-3-pipeline-standards.md` — section authoring standards, diagram conventions, citation format

If any of these are not in context, request them before proceeding.

---

## Your Task

The Architect will provide one of:
- A `brief.md` file (preferred) — structured elicitation output from the `/gather-*` commands
- A requirements description (natural language)
- A requirements PDF or document reference
- A partially completed arc42 document for completion

**If `brief.md` is present:** read it first. It is the primary input — each section maps
directly to the corresponding arc42 section. Sections with `Status: complete` contain
structured, validated answers to the ATAM/ISO 31000/arc42 questions; treat them as
authoritative. Sections with `Status: empty` require authoring from context or by asking the
Architect.

You will produce a **complete arc42 architectural specification** across all 11 sections plus
References, formatted for the daedalus pipeline (Markdown files, BibTeX citations, Mermaid
diagrams).

---

## Section-by-Section Obligations

For each section, you must meet the authoring standards in `mem-3`. The following are
non-negotiable:

**Section 1:**
- Requirements table with ID, Requirement, Priority columns
- Quality Goals table with Priority, Quality Goal, Motivation columns — goals must be
  **concrete and domain-specific**, not generic
- Stakeholders table including an Operations/SRE row

**Section 2:**
- Separate tables for Technical Constraints and Organisational Constraints
- Every constraint must have a Background/Motivation entry

**Section 3:**
- A Mermaid `flowchart TD` context diagram is mandatory
- Technical Context table must include protocol/format, not just system names

**Section 4:**
- Technology Decisions table linking each decision to a quality goal or constraint
- Structural Approach paragraph naming the architectural style and the reason for it
- Approach to Quality Goals table — every Section 1 quality goal must have a row here

**Section 5:**
- Level 1 container diagram is mandatory
- Every building block in the diagram must appear in the table
- If any building block is complex, add a Level 2 subsection

**Section 6:**
- Primary use case sequence diagram is mandatory
- At least one failure/error scenario is mandatory — do not skip it

**Section 7:**
- Infrastructure diagram is mandatory
- Deployment Environments table must include at least three environments
- Deployment Process must describe the CI/CD pipeline at a step level

**Section 8:**
- Cover all five subsections: Security, Logging, Error Handling, Configuration, Data

**Section 9:**
- One ADR per significant technology or structural decision identified in Section 4
- Every ADR must have: Status (Accepted), Date, Context, Decision ("We will …"),
  Consequences (including negative consequences)
- Minimum: one ADR per item in the Section 4 Technology Decisions table

**Section 10:**
- Quality Scenarios table must use the 6-column format from `mem-3`
- Every Section 1 quality goal must have at least one scenario
- Response Measure column must contain a specific, measurable figure — never "fast" or "reliable"

**Section 11:**
- Risk table with ID, Risk, Probability, Impact, Mitigation columns
- Every High-impact risk must have a concrete mitigation, not "monitor"
- Technical Debt table with Item, Description, Plan to Address columns

---

## Output Format

Produce one Markdown code block per section file, labelled with the filename:

```
### proposals/<name>/markdown/01_Introduction_and_Goals.md
[content]
```

```
### proposals/<name>/markdown/02_Constraints.md
[content]
```

…and so on through 99_References.md.

Also produce a `proposals/<name>/project.bib` with BibTeX entries for all sources cited.

---

## Quality Self-Check Before Submitting

Before presenting your output, verify:

1. Every Section 1 quality goal has a Section 10 scenario with a measurable response measure.
2. Every Section 4 technology decision has a Section 9 ADR.
3. Section 6 includes at least one failure scenario.
4. No placeholder rows remain in any table (no empty cells in key columns).
5. All diagrams use correct Mermaid syntax (test with the node notation in `mem-3`).
6. All citations use `[@Key]` format and every Key exists in `project.bib`.
7. No British English spellings (see `mem-4` DL-01).

If any of these fail your self-check, fix them before submitting. Do not ask for permission
to meet the standard — just meet it.
