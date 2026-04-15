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
pandoc-ext/diagram v1.2.0 (Lua, vendored at `filters/diagram.lua`) + @mermaid-js/mermaid-cli@11.12.0 (npm).
CI: GitHub Actions. Container: Docker (Ubuntu 24.04). Linting: markdownlint-cli@0.48.0 + codespell (see
`requirements-dev.txt`). *(Keep tool versions here in sync with `package.json`.)*

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

### Chrome / Puppeteer for @mermaid-js/mermaid-cli (mmdc)
Mermaid diagrams are rendered by `mmdc` (via `filters/diagram.lua`). `PUPPETEER_EXECUTABLE_PATH`
must point to a real browser binary. Two sandbox contexts to handle:
- **Docker (root user):** Chrome requires `--no-sandbox`. The Dockerfile wraps the Chrome binary
  with a shell script, creates `/etc/mmdc-puppeteer.json` (points at the wrapper), and writes
  `/usr/local/bin/mmdc-pandoc` (the wrapper consumed via `MERMAID_BIN`).
- **GitHub Actions on Ubuntu 24.04+:** AppArmor blocks unprivileged user namespaces. CI
  jobs write a puppeteer config at `/tmp/mmdc-puppeteer.json` and create `/usr/local/bin/mmdc-pandoc`,
  then set `MERMAID_BIN` to point at it. See the "Configure mmdc for pandoc" step in each workflow.

### @mermaid-js/mermaid-cli@11.12.0
Pinned in `package.json`, Dockerfile, all three CI workflows, README.md (dependency table +
Troubleshooting section), and CONTRIBUTING.md (dependency table). `package.json` is the source
of truth — Dependabot opens PRs when a new version is available; update the npm install commands
in Dockerfile, CI, README.md, and CONTRIBUTING.md to match when accepting.

`package.json` also contains an `overrides` section that pins `picomatch` to `4.0.4` to fix
CVE-2026-33671 in the transitive dependency chain pulled in via puppeteer. When updating mmdc,
check whether the new version's puppeteer dependency still requires the picomatch override —
remove it once the upstream ships picomatch >= 4.0.4.

The NodeSource-bundled npm@10.x carries picomatch@4.0.3 (CVE-2026-33671) in its own internal
bundle — not patchable via `package.json` overrides, which only apply to packages we install.
npm@11.x was investigated but bundles `tinyglobby` which also carries picomatch@4.0.3. A
targeted `.trivyignore` entry suppresses the CVE at `usr/lib/node_modules/npm/node_modules/picomatch/`
with documented justification; see `.trivyignore` and the "targeted CVE suppression" section
in `docs/pipeline-decisions.md`. The entry will be removed when NodeSource ships a Node.js
version whose bundled npm no longer includes picomatch@4.0.3.

### filters/diagram.lua (pandoc-ext/diagram v1.2.0)
Vendored Lua filter at `filters/diagram.lua`. Pinned to pandoc-ext/diagram v1.2.0. To upgrade:
download `diagram.lua` from the new release tag at https://github.com/pandoc-ext/diagram and
replace the file. The version comment at the top of the file and the `local version` variable
must be updated to match.

### markdownlint-cli@0.48.0
Pinned across six places — update all together: `package.json` (source of truth),
`.pre-commit-config.yaml`, CI npm install commands, Dockerfile, README.md (dependency
table + Troubleshooting section), and CONTRIBUTING.md (dependency table). Dependabot opens
PRs against `package.json`; when accepting, update the other five to match.

### codespell
`requirements-dev.txt` is the sole source of truth. Accepting a Dependabot PR to
`requirements-dev.txt` is the **only** update required — no other files need editing:
- Dockerfile: `COPY requirements-dev.txt` + `--constraint ... codespell` (automatic)
- CI workflows: `pip install --constraint requirements-dev.txt codespell` (automatic)
- `.pre-commit-config.yaml`: `language: system` hook — calls the installed binary, no `rev:` to sync
- README.md and CONTRIBUTING.md: install command uses `--constraint` (version-agnostic); no hardcoded version present

### British English
Write all prose in British English. codespell's default dictionaries (`clear`, `rare`) focus
on unambiguous typos; the optional `en-GB_to_en-US` dictionary (which flags British spellings
as American English errors) is not enabled. British spellings (`organisation`, `colour`,
`analyse`, `licence`, `fulfil`, etc.) pass through unchecked by default. The `.codespellrc`
skips `project.tex` and `project.css` to avoid false positives from LaTeX/CSS keywords. If
a domain term is incorrectly flagged, add it to `.codespellrc` as `ignore-words-list = term`.
Reference: codespell builtin dictionaries — https://github.com/codespell-project/codespell#usage

### GitHub Actions — SHA pinning
All Actions are pinned to commit SHAs (not mutable tags). Dependabot opens weekly PRs to
update them. Never change `uses:` lines to mutable tag references. When accepting a
dependabot PR, verify the SHA comment matches the expected version tag.

---

## Repository Structure

```
daedalus/
  markdown/             Root example (complete arc42 worked example — Acme Commerce)
  templates/            Skeletons copied by make init: config.yaml, project.bib, markdown/, brief.md, requirements.md
  proposals/            User proposals (gitignored output files)
  images/               Root example images (logo.jpg/png/pdf drop-in)
  project.tex           Shared LaTeX header (cover page, fancyhdr, logo detection)
  project.css           HTML stylesheet (light + dark mode, print)
  project.bib           Root example bibliography
  draft.tex             Draft watermark (loaded with DRAFT=1)
  Dockerfile            Ubuntu 24.04 build environment
  docs/                 VSDD knowledge base (mem-1 through mem-4)
  prompts/              Agent prompt files for the VSDD workflow (00–05)
  templates/brief.md    Structured elicitation skeleton — copied into each new proposal by make init
  .claude/commands/     Slash commands: gather-01 through gather-11, req-01 through req-05
  scripts/              Pipeline and elicitation scripts (bash + Python)
  test/fixtures/        requirements-answers.txt, brief-answers.txt — CI fixture answers for Task Tracker
  CLAUDE.md             This file
  CONTRIBUTING.md       Developer guide — setup, workflow, PR process, release
  SECURITY.md           Coordinated vulnerability disclosure policy
  requirements-dev.txt  Python tool pins (source of truth for codespell — tracked by Dependabot)
  .github/workflows/    build.yml, proposals.yml, release.yml, codeql.yml
  .github/dependabot.yml  Weekly Actions + Docker + npm + pip version bump PRs
  .github/CODEOWNERS    Auto-assigns @adamdaw as reviewer on all PRs
  .github/ISSUE_TEMPLATE/  bug_report.md, feature_request.md
  .github/pull_request_template.md
  .devcontainer/devcontainer.json  VS Code Dev Container (builds from Dockerfile)
  filters/diagram.lua     Vendored pandoc-ext/diagram Lua filter (v1.2.0) — invokes mmdc for Mermaid rendering
  package.json            Node.js tool version pins (source of truth for @mermaid-js/mermaid-cli, markdownlint-cli)
  scripts/                  Pre-commit helper scripts (validate-jsonc.py)
  .pre-commit-config.yaml
  .markdownlint.yaml
  .codespellrc
  .editorconfig
  .dockerignore
  .gitignore
```

---

## CI Pipeline

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `build.yml` | Every push / PR / `workflow_dispatch` | lint → spellcheck → build PDF+HTML+DOCX → validate → upload artifacts; Docker job builds, validates, Trivy scans, and pushes to GHCR; version tag push also publishes `:vN.N.N` Docker tag |
| `proposals.yml` | Push to `proposals/**` / `workflow_dispatch` | Detects changed proposals (or uses manual input); builds + validates each in matrix; arc42 heading checks |
| `release.yml` | Push of `v*` tag | lint → spellcheck → build PDF+HTML+DOCX → **validate all three** → attach to GitHub Release |
| `codeql.yml` | Every push / PR / weekly cron | CodeQL static analysis on GitHub Actions YAML for script injection; `continue-on-error` for SARIF upload (requires GHAS) |

PDF validation checks: `pdfinfo` page count (≥5), `pdftotext` section heading grep
(Introduction, Context, Solution Strategy, Building Block, Deployment, Risks, References).

---

## arc42 Section Mapping

| File | arc42 Section | Purpose | Reference |
| --- | --- | --- | --- |
| 01 | Introduction and Goals | Requirements, quality goals, stakeholders | [§1](https://docs.arc42.org/section-1/) |
| 02 | Constraints | Technical, organisational, conventions | [§2](https://docs.arc42.org/section-2/) |
| 03 | Context and Scope | System boundary, external interfaces | [§3](https://docs.arc42.org/section-3/) |
| 04 | Solution Strategy | Technology decisions, structural approach | [§4](https://docs.arc42.org/section-4/) |
| 05 | Building Block View | C4 Container/Component decomposition | [§5](https://docs.arc42.org/section-5/) |
| 06 | Runtime View | Sequence diagrams, key scenarios | [§6](https://docs.arc42.org/section-6/) |
| 07 | Deployment View | Infrastructure, environments, deploy process | [§7](https://docs.arc42.org/section-7/) |
| 08 | Cross-cutting Concepts | Security, logging, error handling, config | [§8](https://docs.arc42.org/section-8/) |
| 09 | Architecture Decisions | ADRs — the "why" behind key choices | [§9](https://docs.arc42.org/section-9/) |
| 10 | Quality Requirements | Quality tree + measurable quality scenarios | [§10](https://docs.arc42.org/section-10/) |
| 11 | Risks and Technical Debt | Risk register, tracked debt | [§11](https://docs.arc42.org/section-11/) |
| 99 | References | Bibliography (auto-populated by --citeproc) | — |

---

## Standards & Practices

### Document & Architecture

| Standard | Reference | Applied in |
| --- | --- | --- |
| **arc42** | [arc42.org](https://arc42.org) | Document template structure — all 11 sections |
| **C4 Model** | [c4model.com](https://c4model.com) | Context, Container, and Deployment diagrams (Sections 3, 5, 7) |
| **Architecture Decision Records** | [adr.github.io](https://adr.github.io) | Section 9 ADR format (Nygard, 2011) |
| **ISO/IEC 25010** | [iso25010.info](https://iso25010.info) | Software quality model — Section 10 quality scenarios |

### Pipeline & Tooling

| Standard | Reference | Applied in |
| --- | --- | --- |
| **Conventional Commits** | [conventionalcommits.org](https://www.conventionalcommits.org) | Commit message format; enforced by pre-commit commit-msg hook |
| **Semantic Versioning** | [semver.org](https://semver.org) | Release tags (`v1.0.0`) trigger `release.yml` |
| **OCI Image Spec** | [opencontainers.org — annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md) | Docker image labels: title, description, source, licenses |
| **OpenSSF Supply Chain Best Practices** | [best.openssf.org](https://best.openssf.org) | SHA-256 verification of pandoc and pandoc-crossref downloads |
| **OpenSSF Scorecard** | [securityscorecards.dev](https://securityscorecards.dev) | SHA-pinned Actions, Dependabot, CodeQL, Trivy scanning, least-privilege permissions |
| **SLSA** | [slsa.dev](https://slsa.dev) | SLSA provenance attestation — deferred until repo is public (GitHub limitation for private user repos) |
| **EditorConfig** | [editorconfig.org](https://editorconfig.org) | Consistent formatting across editors (`.editorconfig`) |
| **pre-commit framework** | [pre-commit.com](https://pre-commit.com) | Automated quality gates on commit (pre-commit + commit-msg hooks) |
| **GNU Make conventions** | [GNU Make manual](https://www.gnu.org/software/make/manual/make.html) | `.DEFAULT_GOAL := help`; self-documenting `##` targets |
| **PEP 668** | [peps.python.org/pep-0668](https://peps.python.org/pep-0668/) | Python tools installed in isolated venv, not `--break-system-packages` |
| **CommonMark** | [spec.commonmark.org](https://spec.commonmark.org/0.31.2/) | Trailing whitespace preserved in `.md` files (hard line break §2.2) |
| **GitHub community health** | [docs.github.com — community health](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions) | `CONTRIBUTING.md`, `SECURITY.md` |

Every significant pipeline decision is documented with its rationale and authoritative reference in
[`docs/pipeline-decisions.md`](../docs/pipeline-decisions.md).

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
| 05 | `prompts/05-elicitation.md` | Reference — arc42 elicitation approach | 0 — documents /gather-* commands |
| 06 | `prompts/06-req-author.md` | Requirements Author (Claude) | 0 — synthesise raw material into requirements.md |

**Session start sequence:** Load Prompt 00 → assess document state → pick the right next prompt.

---

## Requirements Commands (`/req-*`)

Five slash commands for interactive requirements elicitation, producing `requirements.md`
per ISO/IEC/IEEE 29148:2018. Run these before or alongside the `/gather-*` commands —
`requirements.md` feeds into the `/gather-*` sessions as context.

| Command | Covers | Standards |
| --- | --- | --- |
| `/req-01` | Stakeholders + purpose/scope | ISO 29148 §5.2.4, IREB CPRE |
| `/req-02` | Business + functional requirements (user stories) | ISO 29148 §5.2.5, MoSCoW, INVEST |
| `/req-03` | Non-functional requirements | ISO 29148 §5.2.5, ISO/IEC 25010 |
| `/req-04` | Constraints + assumptions + dependencies | ISO 29148 §5.2.4, IREB |
| `/req-05` | Acceptance criteria (BDD) + traceability matrix | BDD Given/When/Then, IEEE 29148 |

**Prompt 06** (`prompts/06-req-author.md`) is the synthesis alternative: provide raw
material (meeting notes, emails, briefs) and it produces a structured `requirements.md`,
flagging gaps, contradictions, and untestable requirements.

**Full workflow (AI path):**

```
/req-* commands  ─┐
                   ├─→ requirements.md → (context for /gather-*) → brief.md → Prompt 01 → arc42
Prompt 06 ─────────┘
```

**Non-AI fallback (no Claude required):**

```
gather-requirements.sh ─┐
                         ├─→ requirements.md → brief.md → assemble.sh → arc42 markdown → make build
gather-brief.sh ─────────┘
```

| Script | Makefile target | Replaces |
| --- | --- | --- |
| `scripts/gather-requirements.sh` | `make gather-requirements` | Prompt 06 / `/req-*` commands |
| `scripts/gather-brief.sh` | `make gather-brief` | `/gather-*` commands |
| `scripts/assemble.sh` | `make assemble` | Prompt 01 |
| `scripts/validate-artifacts.sh` | `make validate-artifacts` | Manual review |

All scripts read from stdin — pipe fixture answers for CI: `grep -v '^#' test/fixtures/requirements-answers.txt | bash scripts/gather-requirements.sh`. The `test-elicitation` CI job in `build.yml` exercises the full non-AI path end-to-end using the Task Tracker fixtures in `test/fixtures/`.

---

## Elicitation Commands (`/gather-*`)

The `.claude/commands/` directory contains 11 Claude Code slash commands — one per arc42
section — for structured elicitation before running Prompt 01.

| Command | Section | Standards |
| --- | --- | --- |
| `/gather-01` | Introduction and Goals | arc42 §1, ISO/IEC 25010, SMART |
| `/gather-02` | Constraints | arc42 §2, Conway's Law |
| `/gather-03` | Context and Scope | arc42 §3, C4 Model Level 1 |
| `/gather-04` | Solution Strategy | arc42 §4 |
| `/gather-05` | Building Block View | arc42 §5, C4 Model Levels 2–3 |
| `/gather-06` | Runtime View | arc42 §6, UML 2.5 |
| `/gather-07` | Deployment View | arc42 §7, C4 Deployment, Twelve-Factor |
| `/gather-08` | Cross-cutting Concepts | arc42 §8, OWASP Top 10, Twelve-Factor |
| `/gather-09` | Architecture Decisions | arc42 §9, Nygard ADR format |
| `/gather-10` | Quality Requirements | arc42 §10, ISO/IEC 25010, ATAM |
| `/gather-11` | Risks and Technical Debt | arc42 §11, ISO 31000, Fowler Debt Quadrant |

**Workflow:**

1. `make init NAME=my-proposal` — scaffolds the proposal and copies `templates/brief.md`
2. `cd proposals/my-proposal` — work from the proposal directory
3. `/gather-01` through `/gather-11` — run each command in order or as needed; each writes
   structured output back into `brief.md` and marks the section `Status: complete`
4. Pass the completed `brief.md` to Prompt 01 as primary input

Each command is **resumable** — if a section already has content it asks whether to add,
update, or replace before proceeding.

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
- apt cache key uses a static version suffix (`apt-ubuntu-24.04-texlive-v1`), shared across
  all three workflows; increment the suffix when adding or changing apt packages. (Historical
  note: an earlier approach keyed on the workflow file hash, causing unnecessary cache misses
  on unrelated workflow edits — avoid that pattern.)
- npm cache key is version-based (`npm-mermaid-cli-X.Y.Z-markdownlint-X.Y.Z`); when
  bumping tool versions, the old cache is automatically abandoned and a fresh one built
- `git diff --name-only HEAD~1 HEAD` in `proposals.yml` can miss changes in merge commits;
  acceptable for this use case
- `build.yml`, `proposals.yml`, and `release.yml` share the same npm cache key — all three
  hit the same cache; a version bump in any one invalidates the cache for all three
- devcontainer `pip install pre-commit` fails on Ubuntu 24.04 (PEP 668 externally managed
  Python); use `python3 -m venv /opt/pre-commit` + symlink pattern, same as Dockerfile
- devcontainer `files.trimTrailingWhitespace: true` must have a `[markdown]` language
  override set to `false`; otherwise VS Code silently destroys CommonMark hard line breaks
- `devcontainer.json` is JSONC (JSON with Comments per the Dev Container spec) — exclude it
  from `check-json` in `.pre-commit-config.yaml`; strict JSON parsing rejects `//` comments;
  use the `check-jsonc` local hook (`scripts/validate-jsonc.py`) to validate JSONC with
  comment stripping rather than skipping validation entirely
- README.md contains hardcoded tool versions (@mermaid-js/mermaid-cli, markdownlint-cli, pandoc,
  pandoc-crossref) that Dependabot does not update automatically — update README alongside
  `package.json` when accepting npm Dependabot PRs (see Critical Constraints above)
- `pip install -r requirements-dev.txt` installs every listed package; use `--constraint`
  when an environment only needs a subset — prevents build-tool pollution in the wrong context
