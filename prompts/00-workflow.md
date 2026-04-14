# Prompt 00 — VSDD Workflow Orchestration

**Role:** Architect (human or orchestrating agent)
**Phase:** Session Start — all phases
**Purpose:** Load context, assess document state, determine next action

---

## Session Start Sequence

Every daedalus session begins here. Before taking any action:

1. **Load memory files** — confirm all four are in context:
   - `docs/mem-1-project-context.md` — authority hierarchy, agent roles, phase gates
   - `docs/mem-2-vsdd-reference.md` — VSDD pipeline, convergence signal, anti-patterns
   - `docs/mem-3-pipeline-standards.md` — section standards, diagram conventions
   - `docs/mem-4-process-lessons.md` — build lessons, documentation lessons

2. **Identify the proposal** — which `proposals/<name>/` directory are you working in?
   If none exists yet, run `make init NAME=<name>` before continuing.

3. **Assess document state** — read the markdown files and determine which phase applies:

| State | Phase | Next Action |
| --- | --- | --- |
| Empty template (just scaffolded) | Phase 1a | Architect: provide requirements input |
| Requirements gathered, no spec written | Phase 1a → 1b | Use Prompt 01 (Spec Author) |
| Spec written, no adversarial review | Phase 1b → 3 | Use Prompt 02 (Adversary) |
| Adversarial review complete, findings unresolved | Phase 3 → 4 | Use Prompt 04 (Feedback Triage) |
| Findings triaged, fixes required | Phase 4 → 1b | Use Prompt 01 (Spec Author) with triage table |
| ADRs missing or incomplete | Phase 1b | Use Prompt 03 (ADR Author) in audit mode |
| All phases converged | Done | Run `make build PROPOSAL=<name>` |

---

## VSDD Phase Map (Architecture Documentation)

```
Phase 1a  Architect seeds requirements
    ↓
Phase 1b  Spec Author (Prompt 01) writes arc42 document
    ↓     [ADR Author (Prompt 03) on request or audit]
Phase 2   [Not applicable to documentation-only pipelines]
    ↓
Phase 3   Adversary (Prompt 02) reviews all 11 sections
    ↓
Phase 4   Architect triages findings (Prompt 04)
    ↓
    ├─ Rework required → back to Phase 1b with triage table
    └─ Converged → Phase 5 (build + validate)
```

**Phase 5 — Formal Hardening:** Run `make validate` then `make all` then `make archive`.
**Phase 6 — Convergence:** CI must pass. `make status` must show `[pdf+html]`.

---

## Phase Gate Rules

Do not proceed to the next phase until the current gate is cleared:

| Gate | Condition |
| --- | --- |
| 1b → 3 | All 11 sections present; no placeholder rows in key columns |
| 3 → 4 | Adversarial review complete; all findings numbered and located |
| 4 → 1b | Triage table complete; every finding has Accept/Reject/Defer + rationale |
| 4 → 5 | Zero accepted findings outstanding (all applied or explicitly deferred) |
| 5 → 6 | `make validate` passes; PDF ≥ 5 pages; all arc42 sections present |

---

## Prompt Roster

| Prompt | File | Agent | When to Use |
| --- | --- | --- | --- |
| 00 | `prompts/00-workflow.md` | Architect | Session start; state assessment |
| 01 | `prompts/01-arch-spec-author.md` | Spec Author (Claude) | Write or revise arc42 document |
| 02 | `prompts/02-adversary-arch.md` | Adversary (Sarcasmotron) | Review complete spec |
| 03 | `prompts/03-adr-author.md` | ADR Author (Claude) | Write or audit ADRs in Section 9 |
| 04 | `prompts/04-feedback-triage.md` | Architect | Triage adversarial findings |

---

## Handoff Protocol

When handing off between agents, always provide:

1. **The full arc42 document** (all markdown files in the proposal)
2. **The relevant memory files** (mem-1 through mem-4)
3. **The phase-specific prompt** (from the roster above)
4. **The triage table** (if Phase 4 → 1b handoff) or **findings list** (if Phase 3 → 4 handoff)

Do not hand off a partial document. Every agent starts from the complete current state.

---

## Convergence Signal

The document has converged when:

- [ ] Sarcasmotron finds zero new findings on a full re-review
- [ ] Every Section 4 technology decision has a Section 9 ADR
- [ ] Every Section 1 quality goal has a Section 10 scenario with a measurable response measure
- [ ] Section 6 contains at least one failure scenario
- [ ] `make validate PROPOSAL=<name>` passes (lint + spellcheck)
- [ ] `make build PROPOSAL=<name>` produces a PDF ≥ 5 pages

If any item above is unchecked, the document has not converged.

---

## Common Anti-Patterns

| Anti-Pattern | What It Looks Like | Correct Action |
| --- | --- | --- |
| Skipping Phase 3 | "The spec looks complete, let's ship it" | Always run the Adversary on a complete draft |
| Rubber-stamp triage | All findings marked Accept, no rationale | Justify each decision; Reject when the finding is wrong |
| ADR-less decisions | Section 4 has 6 decisions; Section 9 has 2 ADRs | Run Prompt 03 in audit mode |
| Vague response measures | "System handles it gracefully" | Require a specific number: latency, uptime %, count |
| Infinite refinement loop | 5+ adversarial rounds with minor findings | Apply convergence signal; if forced to manufacture flaws, stop |
