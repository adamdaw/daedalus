# Contributing to Daedalus

Thank you for your interest in contributing. This document covers how to set up the
development environment, run the pipeline, and submit changes.

This file is a GitHub community health file — it appears automatically on new issue and
pull request forms.  
Reference: [GitHub community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)

---

## Table of Contents

- [Development environment](#development-environment)
- [Running the pipeline](#running-the-pipeline)
- [Quality checks](#quality-checks)
- [Pre-commit hooks](#pre-commit-hooks)
- [Commit messages](#commit-messages)
- [Submitting a pull request](#submitting-a-pull-request)
- [Release process](#release-process)
- [Reporting security issues](#reporting-security-issues)

---

## Development environment

### Option A — Dev Container (recommended)

The repository includes a dev container that builds the full Daedalus environment
(Pandoc, XeLaTeX, Chrome, Node.js, Python tools) automatically.

**Requirements:** VS Code with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), or any OCI-compatible runtime.

```bash
# In VS Code: Reopen in Container (Ctrl+Shift+P → Dev Containers: Reopen in Container)
# The postCreateCommand installs pre-commit hooks and runs make check automatically.
```

### Option B — Docker

```bash
make docker-run        # build the image locally and run make all inside it
make docker-pull-run   # pull the pre-built GHCR image and run make all inside it
```

### Option C — Local install

Install the dependencies listed in `make check` output:

```bash
make check             # lists all required tools and their expected versions
```

Key tools and version pins (update all together — see `CLAUDE.md` Critical Constraints):

| Tool | Version | Source |
| --- | --- | --- |
| pandoc | 3.1.13 | [GitHub releases](https://github.com/jgm/pandoc/releases) |
| pandoc-crossref | 0.3.17.1 | [GitHub releases](https://github.com/lierdakil/pandoc-crossref/releases) |
| @mermaid-js/mermaid-cli | 11.12.0 | `npm install -g @mermaid-js/mermaid-cli@11.12.0` |
| markdownlint-cli | 0.48.0 | `npm install -g markdownlint-cli@0.48.0` |
| codespell | `requirements-dev.txt` | `pip install --constraint requirements-dev.txt codespell` (use a venv on Ubuntu 24.04+) |
| ShellCheck | latest | `apt-get install shellcheck` / [shellcheck.net](https://www.shellcheck.net/) |
| bats | latest | `apt-get install bats` / [github.com/bats-core](https://github.com/bats-core/bats-core) |

---

## Running the pipeline

```bash
make build             # → project.pdf  (root example)
make html              # → project.html
make docx              # → project.docx
make all               # → PDF + HTML + DOCX

# Work on a specific proposal
make build PROPOSAL=my-proposal
make all   PROPOSAL=my-proposal

# Add a DRAFT watermark to the PDF
make build DRAFT=1
```

---

## Quality checks

All checks must pass before a PR is merged. CI runs them automatically.

```bash
make lint              # markdownlint on content/markdown/**/*.md
make spellcheck        # codespell on content/markdown/**/*.md
make validate          # lint + spellcheck (both in one command)
make validate-all      # lint + spellcheck across all proposals
```

```bash
make shellcheck    # ShellCheck static analysis on scripts/*.sh
make test-scripts  # bats unit tests for shell scripts
```

**British English.** Write all prose in British English (`organisation`, `colour`, `analyse`,
`licence`, `fulfil`, etc.). codespell's default dictionaries do not include the `en-GB_to_en-US`
dictionary, so British spellings are not flagged. If a domain term is incorrectly flagged, add it
to `.codespellrc` as `ignore-words-list = term`.

---

## Pre-commit hooks

Pre-commit hooks enforce quality gates at commit time, catching issues before they reach CI.

```bash
# Install pre-commit (PEP 668 — use a venv on Ubuntu 24.04+)
# --constraint pins the version from requirements-dev.txt without installing every
# package listed there; only pre-commit is installed in this venv.
python3 -m venv /opt/pre-commit
/opt/pre-commit/bin/pip install --no-cache-dir --constraint requirements-dev.txt pre-commit
ln -sf /opt/pre-commit/bin/pre-commit /usr/local/bin/pre-commit

# Install hook types — a single command installs both pre-commit and commit-msg.
# default_install_hook_types: [pre-commit, commit-msg] is declared in
# .pre-commit-config.yaml, so no explicit --hook-type flags are needed.
pre-commit install

# Run all hooks manually against staged files
pre-commit run

# Run all hooks against all files (useful after changing the config)
pre-commit run --all-files
```

Both the `pre-commit` and `commit-msg` hook types must be installed. `commit-msg` enforces
the Conventional Commits format (see below). Because `default_install_hook_types` is declared
in `.pre-commit-config.yaml`, a bare `pre-commit install` installs both — no flags needed.  
Reference: [pre-commit — install](https://pre-commit.com/index.html#pre-commit-install)

---

## Commit messages

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
The `commit-msg` pre-commit hook rejects non-conforming messages at commit time.

**Format:**

```
<type>(<optional scope>): <short description>

[optional body]

[optional footer(s)]
```

**Common types:**

| Type | Use for |
| --- | --- |
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `docs` | Documentation changes only |
| `chore` | Build process, dependency updates, tooling |
| `refactor` | Code restructuring with no behaviour change |
| `test` | Adding or modifying tests/validation |
| `ci` | CI/CD workflow changes |

**Examples:**

```
feat(proposals): add support for custom cover page logo
fix(mermaid): pass --no-sandbox flag when running as root in Docker
docs(arc42): add ADR for XeLaTeX font choice
chore(deps): bump @mermaid-js/mermaid-cli from 11.11.0 to 11.12.0
ci: add Trivy vulnerability scan before Docker push
```

---

## Submitting a pull request

1. Fork the repository and create a feature branch from `master`.
2. Make your changes. Run `make validate` and `pre-commit run --all-files` locally.
3. Commit with a Conventional Commits message (the hook enforces this).
4. Push and open a pull request against `master`.
5. CI runs lint, spellcheck, full build (PDF + HTML + DOCX), Docker build, and Trivy scan.
   All checks must pass before merge.
6. Keep the PR focused — one logical change per PR. If unsure, open an issue first.

**Review expectations:** maintainers aim to respond within a few business days.

---

## Release process

Releases are triggered by pushing a semantic version tag:

```bash
git tag v1.2.3
git push origin v1.2.3
```

The `release.yml` workflow runs the full build, validates all three output formats, attaches
`project.pdf`, `project.html`, and `project.docx` to the GitHub Release, and publishes a
versioned Docker image tag (`ghcr.io/owner/repo:v1.2.3`) to GHCR.

Tag format follows [Semantic Versioning](https://semver.org/): `vMAJOR.MINOR.PATCH`.

---

## Reporting security issues

Do **not** open a public GitHub issue for security vulnerabilities. Follow the coordinated
disclosure process in [SECURITY.md](SECURITY.md).
