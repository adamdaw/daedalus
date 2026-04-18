# Where things live

Daedalus has four overlapping directories that collaborate during AI-assisted authoring.
This is the map.

| Location | What it is | When it's loaded | Authority |
|---|---|---|---|
| [`CLAUDE.md`](../CLAUDE.md) (repo root) | Project instructions for Claude Code — build commands, critical constraints, repo structure, design decisions | Auto-loaded at the start of every Claude Code session | Source of truth for repo conventions; points at everything else |
| [`docs/mem-1` … `mem-4`](../docs/) | VSDD knowledge base — project context, methodology reference, pipeline standards, process lessons | Loaded explicitly at session start (per `CLAUDE.md`) | Reference knowledge that informs all agents |
| `prompts/` (this directory) | Agent persona prompts — Architect, Spec Author, Adversary, ADR Author, Requirements Author | Loaded by hand when invoking a specific agent role | Defines what each agent does and how it behaves |
| [`.claude/commands/`](../.claude/commands/) | User-invokable slash commands — `/start-proposal`, `/elicit`, `/req-01`–`/req-05`, `/gather-01`–`/gather-11` | Triggered by the user typing `/<command>` | Drives interactive elicitation — the surface a user actually clicks |

## How to enter

**New session:** read `CLAUDE.md`, then `docs/mem-1` through `mem-4`, then `prompts/00-workflow.md`.
Prompt 00 is the Architect — it assesses document state and tells you which prompt to load next.

**Just want to author a proposal:** start with the slash commands in `.claude/commands/`.
`/start-proposal` is the guided entry point; `/elicit` shows progress and runs the next
incomplete step. The prompts in this directory are for deeper agent work (writing the spec,
running adversarial review, drafting ADRs) — they're invoked after elicitation produces
`requirements.md` and `brief.md`.

## Prompt roster

| Prompt | Role | Phase |
|---|---|---|
| `00-workflow.md` | Architect (session start) | All — state assessment, phase mapping, handoff protocol |
| `01-arch-spec-author.md` | Spec Author | 1b — write or revise arc42 document |
| `02-adversary-arch.md` | Adversary (Sarcasmotron) | 3 — full adversarial review of all 11 sections |
| `03-adr-author.md` | ADR Author | 1b — write or audit ADRs in Section 9 |
| `04-feedback-triage.md` | Architect (triage) | 4 — Accept / Reject / Defer adversarial findings |
| `05-elicitation.md` | Reference | 0 — documents the `/gather-*` elicitation approach |
| `06-req-author.md` | Requirements Author | 0 — synthesise raw material into `requirements.md` |

See [`docs/mem-2-vsdd-reference.md`](../docs/mem-2-vsdd-reference.md) for the VSDD pipeline
and how these phases hand off to each other.
