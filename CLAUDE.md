# Daedalus — Claude Code Context

This file is loaded automatically by Claude Code at session start. Read it before making
any changes to this repository.

---

## What This Project Is

Daedalus is a document generation pipeline for architectural proposal documents using the
[arc42](https://arc42.org) standard. Authors write content in Markdown; the pipeline
produces a professional PDF, HTML, and optionally DOCX — with cover page, TOC, running
headers, Mermaid diagrams, cross-references, and bibliography.

**Stack:** Pandoc 3.1.13 → XeLaTeX (PDF) / HTML5 / DOCX. Filters: pandoc-crossref 0.3.17.1,
mermaid-filter (npm). CI: GitHub Actions. Container: Docker (Ubuntu 24.04). Linting:
markdownlint-cli 0.44.0 + codespell 2.3.0.

**VSDD role:** Daedalus produces the spec artifact layer in a VSDD workflow. The arc42
document it generates IS the formal specification — Section 1 is the behavioral contract,
Section 9 (ADRs) is the decision record, Section 10 is the provable properties catalog.
See `docs/` for the full VSDD knowledge base.

---

## Build Commands

```bash
make build                    # → project.pdf
make html                     # → project.html
make docx                     # → project.docx
make all                      # → PDF + HTML + DOCX
make build PROPOSAL=name      # build a specific proposal
make build DRAFT=1            # add DRAFT watermark
make lint                     # markdownlint on content
make spellcheck               # codespell on content
make validate                 # lint + spellcheck
make validate-all             # lint + spellcheck across all proposals
make check                    # verify all build dependencies are installed
make docker-run               # run make all inside locally-built Docker image
make docker-pull-run          # pull pre-built image from GHCR and run (faster)
make version                  # print installed versions of all build tools
```

---

## Critical Constraints

### pandoc-crossref version pinning
pandoc-crossref **must** be version-matched to pandoc. The project pins pandoc 3.1.13 with
pandoc-crossref 0.3.17.1. Do not upgrade one without upgrading the other. The Makefile,
Dockerfile, and all three CI workflows reference these versions — update all of them
together.

### Chrome / Puppeteer for mermaid-filter
mermaid-filter renders Mermaid diagrams via Chrome/Chromium. `PUPPETEER_EXECUTABLE_PATH`
must point to a real browser binary. Two sandbox contexts to handle:
- **Docker (root user):** Chrome requires `--no-sandbox`. The Dockerfile wraps the binary
  with a shell script that injects `--no-sandbox --disable-setuid-sandbox` automatically.
- **GitHub Actions on Ubuntu 24.04+:** AppArmor blocks unprivileged user namespaces. CI
  jobs write a puppeteer launch config and set `MERMAID_FILTER_PUPPETEER_CONFIG` to point
  at it before any build step. See the "Configure puppeteer no-sandbox" step in each workflow.

### mermaid-filter@1.4.7
Pinned in `package.json`, Dockerfile, and all three CI workflows. `package.json` is the
source of truth — dependabot opens PRs when a new version is available; update the npm
install commands in Dockerfile and CI to match when accepting.

### markdownlint-cli@0.44.0
Pinned to match `.pre-commit-config.yaml`. Update both together. The CI npm install and
Dockerfile both pin this version.

### codespell 2.3.0
Pinned to match `.pre-commit-config.yaml`. Update both together. The CI pip install and
Dockerfile both pin this version.

### American English
codespell uses American English by default. Use "fulfillment" not "fulfilment",
"coordinates" not "co-ordinates". The `.codespellrc` skips `project.tex` and `project.css`
to avoid false positives from LaTeX/CSS keywords.

### GitHub Actions — SHA pinning
All Actions are pinned to commit SHAs (not mutable tags). Dependabot opens weekly PRs to
update them. Never change `uses:` lines to mutable tag references. When accepting a
dependabot PR, verify the SHA comment matches the expected version tag.

---

## Repository Structure

```
daedalus/
  markdown/             Root example (complete arc42 worked example — Acme Commerce)
  templates/            Skeleton copied by make init into proposals/
  proposals/            User proposals (gitignored output files)
  images/               Root example images (logo.jpg/png/pdf drop-in)
  project.tex           Shared LaTeX header (cover page, fancyhdr, logo detection)
  project.css           HTML stylesheet (light + dark mode, print)
  project.bib           Root example bibliography
  draft.tex             Draft watermark (loaded with DRAFT=1)
  Dockerfile            Ubuntu 24.04 build environment
  docs/                 VSDD knowledge base (mem-1 through mem-4)
  prompts/              Agent prompt files for the VSDD workflow
  CLAUDE.md             This file
  .github/workflows/    build.yml, proposals.yml, release.yml
  .github/dependabot.yml  Weekly Actions + Docker + npm version bump PRs
  package.json            Node.js tool version pins (source of truth for mermaid-filter, markdownlint-cli)
  .pre-commit-config.yaml
  .markdownlint.json
  .codespellrc
  .editorconfig
  .dockerignore
  .gitignore
```

---

## CI Pipeline

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `build.yml` | Every push / PR / `workflow_dispatch` | lint → spellcheck → build PDF+HTML → validate → upload artifacts; Docker job builds, validates, and pushes to GHCR |
| `proposals.yml` | Push to `proposals/**` / `workflow_dispatch` | Detects changed proposals (or uses manual input); builds + validates each in matrix; arc42 heading checks |
| `release.yml` | Push of `v*` tag | lint → spellcheck → build PDF+HTML+DOCX → **validate all three** → attach to GitHub Release |

PDF validation checks: `pdfinfo` page count (≥5), `pdftotext` section heading grep
(Introduction, Context, Solution Strategy, Building Block, Deployment, Risks, References).

---

## arc42 Section Mapping

| File | arc42 Section | Purpose |
| --- | --- | --- |
| 01 | Introduction and Goals | Requirements, quality goals, stakeholders |
| 02 | Constraints | Technical, organisational, conventions |
| 03 | Context and Scope | System boundary, external interfaces |
| 04 | Solution Strategy | Technology decisions, structural approach |
| 05 | Building Block View | C4 Container/Component decomposition |
| 06 | Runtime View | Sequence diagrams, key scenarios |
| 07 | Deployment View | Infrastructure, environments, deploy process |
| 08 | Cross-cutting Concepts | Security, logging, error handling, config |
| 09 | Architecture Decisions | ADRs — the "why" behind key choices |
| 10 | Quality Requirements | Quality tree + measurable quality scenarios |
| 11 | Risks and Technical Debt | Risk register, tracked debt |
| 99 | References | Bibliography (auto-populated by --citeproc) |

---

## VSDD Prompt Roster

The `prompts/` directory contains the agent prompts for the full VSDD workflow. Load
`docs/mem-1-project-context.md` through `mem-4` at the start of every session.

| Prompt | File | Role | Phase |
| --- | --- | --- | --- |
| 00 | `prompts/00-workflow.md` | Architect (session start) | All — state assessment, phase mapping, handoff protocol |
| 01 | `prompts/01-arch-spec-author.md` | Spec Author (Claude) | 1b — write or revise arc42 document |
| 02 | `prompts/02-adversary-arch.md` | Adversary (Sarcasmotron) | 3 — full adversarial review of all 11 sections |
| 03 | `prompts/03-adr-author.md` | ADR Author (Claude) | 1b — write or audit ADRs in Section 9 |
| 04 | `prompts/04-feedback-triage.md` | Architect (triage) | 4 — Accept / Reject / Defer adversarial findings |

**Session start sequence:** Load Prompt 00 → assess document state → pick the right next prompt.

---

## Key Design Decisions

- **arc42 as default template** — replaces the earlier ad-hoc 5-section structure. More
  formal, widely adopted in enterprise software, maps naturally to VSDD's spec structure.
- **XeLaTeX over pdflatex** — enables custom fonts and better Unicode support.
- **`-H project.tex` header include** — injected before pandoc's hyperref/geometry packages.
  LaTeX commands that conflict with pandoc's own packages must go in `config.yaml`
  `header-includes`, not in `project.tex`.
- **`--resource-path=.:$(IMAGES)`** — allows `\IfFileExists{logo.jpg}` to find proposal logos
  without hardcoded `images/` prefix. The kpathsea TEXINPUTS path covers both directories.
- **One DB per service** (arc42 ADR pattern) — the DOCX output uses `DOCX_FLAGS` (a subset
  of `PANDOC_FLAGS`) that omits LaTeX-specific flags (`-H`, `-V subparagraph`, `--css`).
- **SHA-pinned Actions + dependabot** — supply chain hardening. Every `uses:` line has a
  commit SHA comment. Dependabot opens weekly PRs to keep them current.

---

## Process Lessons

See `docs/mem-4-process-lessons.md` for the full lesson log. Quick reference:

- pandoc-crossref version mismatch is silent and produces wrong output — always verify both
  versions together with `make check`
- Chrome `--no-sandbox` required in Docker (root user) and on Ubuntu 24.04+ CI runners
  (AppArmor restriction); see the Chrome/Puppeteer constraint above for both patterns
- apt cache key tied to workflow file hash — bust it by touching the workflow file
- npm cache key is version-based (`npm-mermaid-filter-X.Y.Z-markdownlint-X.Y.Z`); when
  bumping tool versions, the old cache is automatically abandoned and a fresh one built
- `git diff --name-only HEAD~1 HEAD` in `proposals.yml` can miss changes in merge commits;
  acceptable for this use case
- `build.yml`, `proposals.yml`, and `release.yml` share the same npm cache key — all three
  hit the same cache; a version bump in any one invalidates the cache for all three
