# Getting Started

This guide covers installing dependencies, building documents, running quality checks
and tests, and using Docker or the VS Code Dev Container. For authoring content (creating
proposals, writing sections, customising output), see [authoring.md](authoring.md).

---

## Dependencies

| Tool | Purpose | Install |
|---|---|---|
| `pandoc` 3.1.13 | Markdown → PDF/HTML | [pandoc.org/installing](https://pandoc.org/installing.html) |
| `pandoc-crossref` 0.3.17.1 | Figure/table cross-references | [releases](https://github.com/lierdakil/pandoc-crossref/releases) |
| `xelatex` | PDF rendering engine | `apt install texlive-xetex texlive-latex-extra lmodern` |
| `@mermaid-js/mermaid-cli` 11.12.0 | Diagram rendering (mmdc) | `npm install -g @mermaid-js/mermaid-cli@11.12.0` |
| Chromium / Chrome | Required by mmdc (Puppeteer) | `apt install chromium` / `brew install chromium` |
| `markdownlint-cli` 0.48.0 | Markdown linting (optional) | `npm install -g markdownlint-cli@0.48.0` |
| `codespell` | Spell checking (optional) | `pip install --constraint requirements-dev.txt codespell` |
| Node.js >= 22 | Required by npm tools | [nodejs.org](https://nodejs.org) |

Development tools (for testing and coverage — not required for document generation):

| Tool | Purpose | Install |
|---|---|---|
| `bats` | Shell script testing | `apt install bats` / [bats-core](https://github.com/bats-core/bats-core) |
| `shellcheck` | Shell script linting | `apt install shellcheck` / [shellcheck.net](https://www.shellcheck.net) |
| `pytest` + `pytest-cov` | Python testing + coverage | `pip install --constraint requirements-dev.txt pytest pytest-cov` |
| `bashcov` | Bash coverage analysis | `gem install bashcov simplecov-cobertura` / [Gemfile](../Gemfile) |

pandoc-crossref must be version-matched to pandoc. Download the Linux binary and place it on your `$PATH`:

```bash
curl -fsSL -o pandoc-crossref-Linux.tar.xz \
  https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.17.1/pandoc-crossref-Linux.tar.xz
tar -xf pandoc-crossref-Linux.tar.xz
sudo mv pandoc-crossref /usr/local/bin/
```

For mmdc to find the browser and the pandoc-ext/diagram filter to invoke it:

```bash
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=$(which chromium)
# MERMAID_BIN points filters/diagram.lua at the mmdc binary (or a wrapper script)
export MERMAID_BIN=$(which mmdc)
```

Verify all dependencies:

```bash
make check
```

---

## Build

```bash
make build        # generate project.pdf
make html         # generate project.html
make docx         # generate project.docx (Word)
make all          # generate PDF, HTML, and DOCX
make clean        # remove generated output
make watch        # rebuild on file changes (requires fswatch or inotify-tools)
make open         # open the PDF in the system viewer
make help         # list all available targets
```

### Draft mode

```bash
make build DRAFT=1   # adds a DRAFT watermark to every page
```

### Mermaid theme

```bash
make build MERMAID_THEME=dark     # dark theme
make build MERMAID_THEME=forest   # forest theme
```

Available themes: `default`, `dark`, `forest`, `neutral`. Defaults to `default`.

---

## Quality checks

```bash
make lint         # run markdownlint on content files
make spellcheck   # run codespell on content files
make shellcheck   # lint shell scripts with ShellCheck
make validate     # run lint + spellcheck + shellcheck (without building)
make wordcount    # word count per file and total
make status       # show build state and word count for all proposals
make version      # print installed versions of all build tools
make progress     # show elicitation completion dashboard
make ready        # validate artifacts are ready for spec authoring
```

---

## Testing

```bash
make test-scripts  # run bats unit tests for shell scripts (95 tests)
make test-python   # run Python unit tests with 90% coverage gate
make test-lua      # run Lua filter integration tests
make test-all      # run all tests (bats + Python + Lua)
make coverage      # run bash test coverage analysis (requires Ruby + bashcov)
```

The test suite comprises 113 tests across three languages:

- **95 bats tests** — shell scripts and Makefile targets (`test/scripts/*.bats`)
- **12 pytest tests** — Python JSONC validation (`test/python/`)
- **6 Lua integration tests** — pandoc diagram filter (`test/lua/`)

Coverage gates enforce 90% minimum line coverage for project-owned code:

- **Bash:** [bashcov](https://github.com/infertux/bashcov) + [SimpleCov](https://github.com/simplecov-ruby/simplecov) (`.simplecov` config)
- **Python:** [pytest-cov](https://pytest-cov.readthedocs.io) with `--cov-fail-under=90`
- **Lua:** Excluded from line-level gate — `filters/diagram.lua` is [vendored third-party code](https://github.com/pandoc-ext/diagram) tested via integration tests

---

## Docker (no local dependencies required)

```bash
make docker-build       # build the image locally
make docker-run         # run the build inside the locally-built container
make docker-pull-run    # pull the pre-built image from GHCR and run the build
```

The pre-built image (`ghcr.io/adamdaw/daedalus:latest`) is published to GitHub Container
Registry on every push to `master`. Using it skips the ~3-minute local Docker build.

---

## VS Code Dev Container

Open this repository in VS Code with the Remote - Containers extension. The devcontainer
uses the same Docker image — all dependencies are pre-installed.

---

## Pre-commit hooks

Install [pre-commit](https://pre-commit.com/) and run:

```bash
pre-commit install
```

`default_install_hook_types: [pre-commit, commit-msg]` is declared in `.pre-commit-config.yaml`,
so a single `pre-commit install` installs both hook types — no extra flags needed.

This enforces quality gates automatically on every commit:

- **File hygiene** — trailing whitespace, end-of-file newlines, valid YAML/JSON/JSONC, no merge conflict markers
- **Markdown linting** — markdownlint on content files
- **Spell checking** — codespell on content files
- **Conventional Commits** — commit message format validated on every commit (`feat:`, `fix:`, `chore:`, `docs:`, etc.)

---

## CI/CD

### `build.yml` — runs on every push, PR, or manual trigger

1. Installs pandoc, pandoc-crossref, XeLaTeX, @mermaid-js/mermaid-cli, markdownlint, codespell
2. Lints all markdown files
3. Spell-checks all markdown files
4. Builds `project.pdf` and validates structure (page count, arc42 section headings)
5. Builds `project.html` and validates it is non-empty
6. Builds `project.docx` and validates it is non-empty
7. Uploads PDF, HTML, and DOCX as downloadable artifacts (30-day retention)
8. Tests the non-AI elicitation pipeline end-to-end using fixture data (`make test-elicitation`)
9. Builds and validates the Docker image end-to-end, then pushes to GHCR

Can also be triggered manually from the GitHub Actions UI (`workflow_dispatch`).

### `proposals.yml` — runs when `proposals/**` changes, or manually

Detects which proposal directories were modified in the push, then builds and validates
only those proposals in parallel (matrix strategy). Each proposal is checked against
all arc42 section headings. Uploads PDF, HTML, and DOCX for each as artifacts.

Supports manual trigger: optionally specify a single `proposal` name to rebuild, or
leave empty to rebuild all proposals.

### `release.yml` — runs on `v*` tags

Lints and spell-checks, builds the root example PDF, HTML, and DOCX, validates all
artifacts, then attaches them to the GitHub Release. Tag a release with:

```bash
git tag v1.0 && git push origin v1.0
```

### `codeql.yml` — runs on every push, PR, and weekly cron

[CodeQL](https://codeql.github.com/) static analysis targeting GitHub Actions YAML for
script injection vulnerabilities. Uses `continue-on-error` for SARIF upload (requires
GitHub Advanced Security on private repos).

### Dependency caching

All CI jobs cache:

- The pandoc `.deb` installer (keyed by pandoc version)
- The pandoc-crossref `.tar.xz` binary (keyed by crossref version)
- apt package archives (stable key `apt-ubuntu-24.04-texlive-v1`, shared across all workflows; bump the suffix if packages change)
- npm global cache (keyed by tool versions, e.g. `npm-mermaid-cli-11.12.0-markdownlint-0.48.0`; shared across all workflows)

---

## Project Structure

```
daedalus/
  config.yaml              # Root example metadata
  project.tex              # Shared LaTeX template (cover page, headers, fonts)
  project.css              # HTML stylesheet (light + dark mode, print)
  project.bib              # Root example bibliography
  draft.tex                # Draft watermark (loaded when DRAFT=1)
  Makefile                 # Build automation (~40 targets)
  Dockerfile               # Containerised build environment (Ubuntu 24.04)
  package.json             # Node.js tool version pins (source of truth for npm tools)
  requirements-dev.txt     # Python tool pins (source of truth for codespell)
  filters/
    diagram.lua            # Vendored pandoc-ext/diagram Lua filter (v1.2.0)
  markdown/                # Root example content (a complete sample proposal)
  images/                  # Root example images
  templates/               # Skeleton copied into each new proposal by make init
    config.yaml            # Document metadata template
    project.bib            # Bibliography template
    brief.md               # Architecture elicitation skeleton (arc42)
    requirements.md        # Requirements specification skeleton (ISO 29148)
    markdown/              # 11 empty arc42 sections + 99_References
  proposals/               # Your proposals (generated output is gitignored)
  prompts/                 # VSDD agent prompt files
    00-workflow.md         # Architect — session start, phase mapping, handoff protocol
    01-arch-spec-author.md # Spec Author — write or revise arc42 document
    02-adversary-arch.md   # Adversary — full adversarial review of all 11 sections
    03-adr-author.md       # ADR Author — write or audit Architecture Decision Records
    04-feedback-triage.md  # Architect — triage adversarial findings
    05-elicitation.md      # Reference — arc42 elicitation methodology
    06-req-author.md       # Requirements Author — synthesise raw material into requirements.md
  docs/                    # VSDD knowledge base
    mem-1-project-context.md   # Authority hierarchy, agent roles, phase gates
    mem-2-vsdd-reference.md    # VSDD pipeline, convergence signal, anti-patterns
    mem-3-pipeline-standards.md # Section standards, diagram conventions
    mem-4-process-lessons.md   # Build lessons, documentation lessons, constraints
    pipeline-decisions.md      # Every significant decision with rationale and reference
  scripts/                 # Elicitation and validation automation
    gather-requirements.sh # Non-AI requirements elicitation (ISO 29148)
    gather-brief.sh        # Non-AI architecture elicitation (arc42)
    assemble.sh            # Assemble arc42 markdown from elicitation artifacts
    validate-artifacts.sh  # Validate requirements.md and brief.md structure
    progress.sh            # Elicitation progress dashboard
    validate-jsonc.py      # JSONC validation for devcontainer.json
  test/
    scripts/             # bats unit tests (95 tests across 8 files)
    python/              # pytest tests for validate-jsonc.py (12 tests)
    lua/                 # Lua filter integration tests (6 tests)
    fixtures/            # CI fixture data (requirements, brief, JSONC)
  .claude/commands/        # Claude Code slash commands (/start-proposal, /elicit, /req-01–05, /gather-01–11)
  .devcontainer/           # VS Code Dev Container config
  .github/
    workflows/             # CI/CD pipelines (build, proposals, release, codeql)
    dependabot.yml         # Weekly version bump PRs (Actions, Docker, npm, pip)
    CODEOWNERS             # Auto-assigns reviewer on all PRs
    ISSUE_TEMPLATE/        # Bug report and feature request templates
    pull_request_template.md
  .markdownlint.yaml       # Lint configuration (YAML enables inline comments)
  .codespellrc             # Spell check configuration
  .pre-commit-config.yaml  # Pre-commit hook definitions
  .editorconfig            # Consistent formatting across editors
  Gemfile                  # Ruby dependencies for coverage tooling (bashcov)
  .simplecov               # bashcov/SimpleCov coverage configuration (90% gate)
```
