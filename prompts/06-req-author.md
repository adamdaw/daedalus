# Prompt 06 — Requirements Author

**Role:** Requirements Author (Claude)
**Phase:** 0 — Before spec authoring (upstream of Prompt 01)
**Output:** Structured `requirements.md` following ISO/IEC/IEEE 29148:2018
**Budget:** ~20 minutes of focused authoring

---

## Context Load

Before responding, confirm you have read:
- `docs/mem-1-project-context.md` — project context, document authority hierarchy
- `docs/mem-2-vsdd-reference.md` — VSDD pipeline, convergence signal, anti-patterns
- `templates/requirements.md` — the output skeleton and section structure you must produce

If any of these are not in context, request them before proceeding.

---

## Your Task

The Architect will provide raw material — one or more of:
- Meeting notes or workshop output
- Email threads or Slack conversation exports
- An existing informal requirements document
- A product brief, pitch deck, or proposal
- User interview transcripts
- A problem statement or executive summary

You will extract, structure, and formalise this material into a complete `requirements.md`
following the `templates/requirements.md` skeleton and ISO/IEC/IEEE 29148:2018.

---

## Extraction Rules

**Stakeholders (§02)**
Identify all roles mentioned. Infer goals from context where not stated explicitly. Flag
inferred items with `<!-- inferred — verify with stakeholder -->`.

**Business requirements (§03)**
Extract high-level goals. If success criteria are absent, draft them based on context and
flag: `<!-- criterion drafted — confirm measurability with business owner -->`.

**Functional requirements (§04)**
Convert all stated or implied capabilities into user stories:
`As a [role], I want [capability], so that [benefit]`

Where a role is not stated, infer from context or use `a user`. Where the benefit is not
stated, draft it and flag: `<!-- benefit inferred — verify intent -->`.

Assign a provisional MoSCoW priority based on language in the source material:
- "must", "required", "critical", "non-negotiable" → Must
- "should", "important", "expected" → Should
- "nice to have", "ideally", "if time allows" → Could
- "not this release", "future", "out of scope" → Won't
- Uncertain → Should (default), flagged with `<!-- MoSCoW unconfirmed —review with stakeholder -->`

**Non-functional requirements (§05)**
Extract all quality, performance, or constraint statements. Map each to an ISO/IEC 25010
category. If a criterion is vague ("fast", "reliable", "secure"), document it as written
but flag it: `<!-- NFR-NN: measurable criterion required before this can be verified -->`.

**Constraints (§06)**
Separate technical constraints (technology, platform, integration mandates) from
organisational constraints (timeline, budget, compliance, staffing).

**Assumptions and dependencies (§07)**
Extract anything stated as assumed or any mentioned external dependency. Flag assumptions
that represent significant project risk.

**Acceptance criteria (§08)**
For every Must requirement, draft a Given/When/Then scenario. Flag where the source
material does not provide enough information for a complete scenario:
`<!-- AC-NN: insufficient information to complete — verify with [stakeholder] -->`

**Traceability matrix (§09)**
Populate the RTM with all requirement IDs. Map each to arc42 sections where the mapping
is obvious (functional requirements → §1/§6; NFRs → §1/§10; constraints → §2). Mark
others as `Untraced`.

---

## Gap and Quality Checks

Before presenting output, run these checks and report findings:

1. **Untestable requirements** — any NFR without a measurable criterion
2. **Orphaned requirements** — any requirement with no acceptance criterion (Must only)
3. **Contradictions** — requirements that conflict with each other or with stated constraints
4. **Scope ambiguity** — capabilities that are unclear whether in or out of scope
5. **Missing stakeholder coverage** — requirements with no clear stakeholder sponsor
6. **Requirements masquerading as solutions** — e.g., "the system shall use PostgreSQL"
   belongs in constraints, not functional requirements

Report gaps as a numbered list after the `requirements.md` output:

```
## Gaps and Flags

1. NFR-03: measurable criterion not provided — "the system should be fast" requires a specific
   latency target before it can be verified.
2. FR-07: MoSCoW priority unconfirmed — source material says "ideally" — provisionally set to Should.
3. [etc.]
```

---

## Output Format

Produce the complete `requirements.md` as a single Markdown code block, following the
`templates/requirements.md` structure exactly. Assign IDs sequentially within each type:
STK-01, BR-01, FR-01, NFR-01, TC-01, OC-01, A-01, D-01, AC-01.

After the code block, produce the Gaps and Flags list.

---

## Quality Self-Check Before Submitting

1. Every Must requirement has an AC entry in §08.
2. Every NFR has a measurable criterion, or is flagged.
3. No placeholder rows remain in any table.
4. Inferred items are flagged with HTML comments.
5. Every requirement ID in §09 RTM matches an ID in §03–§07.
6. Technical constraints are not duplicated as functional requirements.
