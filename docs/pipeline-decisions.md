# Pipeline Implementation Decisions

This document is a decision register for the Daedalus build pipeline. Every significant
implementation decision is recorded here with its rationale and an authoritative reference.
It exists so the pipeline can be audited line by line: for any choice, this document explains
what we do, why we do it, and where the recommendation comes from.

---

## Dockerfile

**Reference:** Docker Dockerfile Best Practices — https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

### `DEBIAN_FRONTEND` as `ARG`, not `ENV`

`ENV DEBIAN_FRONTEND=noninteractive` persists into the final image and every container derived
from it, preventing interactive `apt-get` operations for users debugging the container.
Using `ARG DEBIAN_FRONTEND=noninteractive` scopes the variable to build-time `RUN` commands
only and does not appear in the runtime environment.

### Layer ordering: most-stable dependencies first

Docker invalidates the build cache from the first changed layer onwards. Base utilities,
pandoc, pandoc-crossref, and XeLaTeX change rarely; Node.js tooling and Python tooling
change on version bumps. Placing stable layers first ensures that a version bump in
`mermaid-filter` does not force a re-download of TeX Live.

**Reference:** https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache

### `--no-install-recommends` on every `apt-get install`

`apt` installs recommended packages by default, which can add hundreds of MB of documentation
and optional dependencies not required at runtime. `--no-install-recommends` restricts the
install to declared dependencies only.

**Reference:** https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#apt-get

### `rm -rf /var/lib/apt/lists/*` in the same `RUN` layer

`apt-get update` downloads the package index into `/var/lib/apt/lists/`. Removing it in the
same `RUN` instruction (same layer) ensures the index is never baked into the image. A
separate `RUN rm` instruction would create a new layer on top, not reduce the layer below.

**Reference:** https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#apt-get

### `curl` throughout, not `wget`

All downloads use `curl -fsSL`. The `-f` flag causes curl to return a non-zero exit code on
HTTP errors (4xx, 5xx), immediately failing the `RUN` command rather than silently writing
an error page to disk. `wget` also fails on HTTP errors, but `curl -f` is more explicit.
Standardising on `curl` removes the inconsistency of mixing two HTTP clients. `wget` is no
longer installed in the base utilities layer.

### SHA-256 verification before every binary install

`curl` downloads over HTTPS but does not verify that the downloaded content matches a known
hash. A compromised release, CDN tampering, or a MITM attack could substitute a malicious
binary. Verifying the SHA-256 digest before executing the binary ensures we run exactly what
was expected. SHA values are declared as `ARG`s alongside version pins so a version upgrade
requires updating both values — making the change auditable in the diff.

**Reference:** OpenSSF Supply Chain Best Practices — https://best.openssf.org/Compiler-Hardening-Guides/Dockerfile-Best-Practices

### NodeSource repository: explicit GPG key + apt, not `curl | bash`

The `curl | bash` pattern downloads and executes arbitrary code from a remote server in a
single step. If the server is compromised or the connection intercepted, malicious code runs
with full root privileges — there is no verification step between download and execution.

The alternative: fetch the GPG signing key with `curl | gpg --dearmor`, write the apt source
entry, and install via `apt-get`. Only trusted system tools (`gpg`, `apt-get`) execute code;
the key fetch is data, not a shell script.

**Reference:** NodeSource manual installation — https://github.com/nodesource/distributions?tab=readme-ov-file#installation-instructions-deb

### Google Chrome, not `chromium-browser`

Puppeteer (used by mermaid-filter) is tested against Google Chrome. Ubuntu's packaged
`chromium-browser` may lag behind the Puppeteer-compatible version or diverge in behaviour.
Using Chrome from Google's official apt repository ensures Puppeteer compatibility.

**Reference:** https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker

### `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true`

Puppeteer's default install behaviour downloads a bundled Chromium binary (several hundred MB)
into `node_modules`. Since we install Chrome explicitly above, the download is wasted. This
ENV var disables it.

**Reference:** https://pptr.dev/guides/configuration#environment-variables

### Python tooling via venv, not `pip --break-system-packages`

Ubuntu 24.04 marks the system Python environment as "externally managed" (PEP 668). The
`--break-system-packages` flag bypasses this protection and risks corrupting OS packages that
depend on system Python. The correct approach per PEP 668 is an isolated virtual environment.
`python3 -m venv /opt/codespell` creates the environment; the binary is symlinked to
`/usr/local/bin/codespell` for global access without PATH manipulation.

**Reference:** PEP 668 — https://peps.python.org/pep-0668/

### `pip install --no-cache-dir`

pip caches downloaded packages in `~/.cache/pip/`. In a Docker layer, this cache is baked
into the image and serves no purpose (the package is installed, the cache cannot be reused
outside the build). `--no-cache-dir` prevents the cache from entering the image.

**Reference:** https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run

### `npm install --no-fund --no-audit`

`--no-fund` suppresses the funding messages that appear in npm output. `--no-audit` suppresses
the audit report. Both are addressed through Dependabot version-update PRs, not the Docker
build. Suppressing them keeps build logs clean.

### Chrome `--no-sandbox` wrapper

Docker containers run as root. Chrome's sandbox (the setuid sandbox helper) requires non-root
execution or privileged kernel namespace access not available in standard Docker. Wrapping the
binary with a shell script that injects `--no-sandbox` ensures the flag is always present
regardless of how Puppeteer invokes Chrome.

In CI (non-root user), `MERMAID_FILTER_PUPPETEER_CONFIG` handles this instead — the wrapper
is the Docker-specific solution.

**Reference:** https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker

### `WORKDIR /workspace` — explicit, absolute, matching convention

Best practice is to use an explicit absolute `WORKDIR` rather than relying on the implicit
`/` default or using `RUN cd`. `/workspace` matches the GitHub Actions runner workspace
directory name, so the container environment is consistent whether run locally or in CI.

**Reference:** https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#workdir

### `CMD ["make", "all"]` — exec form, not shell form

The exec form (JSON array) makes `make` PID 1. Shell form (`CMD make all`) wraps the command
in `/bin/sh -c`, making the shell PID 1. PID 1 does not receive `SIGTERM` forwarded from
the shell, so `docker stop` would wait 10 seconds before sending `SIGKILL`. Exec form ensures
`make` receives signals directly for clean shutdown.

**Reference:** https://docs.docker.com/engine/reference/builder/#cmd

### OCI image labels

Standard metadata that container registries (GHCR, Docker Hub) display, vulnerability
scanners consume, and supply-chain tooling requires. The `created` and `revision` fields
can be populated at build time via `--build-arg BUILD_DATE=... --build-arg VCS_REF=...`.

**Reference:** OCI Image Specification annotations — https://github.com/opencontainers/image-spec/blob/main/annotations.md

---

## Makefile

**Reference:** GNU Make Manual — https://www.gnu.org/software/make/manual/make.html

### `.DEFAULT_GOAL := help`

Without `.DEFAULT_GOAL`, bare `make` executes the first recipe in the file (`build`). Setting
`.DEFAULT_GOAL := help` means a new contributor running `make` sees usage instructions rather
than triggering an unexpected build.

**Reference:** GNU Make §6.14 — https://www.gnu.org/software/make/manual/make.html#index-.DEFAULT_005fGOAL

### `.PHONY` declaration

If a file named `build`, `clean`, `help`, etc. were ever created in the working directory,
Make would treat it as an up-to-date target and skip the recipe silently. `.PHONY` declares
targets that are not file names, ensuring the recipe always runs.

**Reference:** GNU Make §4.6 — https://www.gnu.org/software/make/manual/make.html#Phony-Targets

### `$(MAKE)` for recursive calls

`$(MAKE)` inherits the current invocation's flags (`--jobs`, `--dry-run`, `-s`, etc.) and
participates in the jobserver. A literal `make` would start an independent process, ignoring
`-n` (dry-run) and breaking parallel jobserver accounting.

**Reference:** GNU Make §9.3 — https://www.gnu.org/software/make/manual/make.html#Recursion

### `:=` for version pins, `?=` for user overrides

`:=` (simply-expanded assignment) evaluates immediately — no recursive expansion, predictable
performance. `?=` (conditional assignment) only sets the variable if it has not already been
set, allowing `make build MERMAID_THEME=dark` overrides without editing the file.

**Reference:** GNU Make §6.2 — https://www.gnu.org/software/make/manual/make.html#Flavors

### Self-documenting `##` help pattern

Targets with `## Description` comments on the same line are extracted by the `help` target
via `grep` + `awk`. The target list never goes stale because each target documents itself.

**Reference:** François Zaninotto's self-documenting Makefile — https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

### Cross-platform `SED_I`

BSD `sed` (macOS) requires an extension argument for `-i` (`sed -i ''`); GNU `sed` (Linux)
does not. `uname -s` selects the correct form at recipe evaluation time, making `make init`
work on both platforms.

**Reference:** POSIX sed — https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sed.html

---

## GitHub Actions Workflows

**Reference:** GitHub Actions Security Hardening Guide — https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions

### All `uses:` lines pinned to commit SHAs

Mutable tags (e.g. `v4`) can be silently updated to point at new code. A compromised or
malicious update would execute in all downstream workflows. Commit SHAs are immutable:
the code at that SHA cannot change. Tag comments (`# v6.0.2`) document the human-readable
version for maintenance.

**Reference:** §Using third-party actions — https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-third-party-actions

### `permissions: {}` at workflow level + per-job grants

GitHub Actions grants `GITHUB_TOKEN` broad read-write permissions by default. An attacker
achieving code execution in a workflow step could exfiltrate secrets or modify the repository.
Workflow-level `permissions: {}` removes all defaults; each job declares only what it requires
(`contents: read`, `packages: write`, etc.). This follows the principle of least privilege.

**Reference:** GITHUB_TOKEN permissions — https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token

### `persist-credentials: false` on all `actions/checkout` steps

`actions/checkout` stores the `GITHUB_TOKEN` git credential in the repository's git config by
default. When no git push or authenticated remote operation is needed after checkout, the
credential is unnecessary and represents a residual attack surface. `persist-credentials: false`
removes it immediately after checkout.

**Reference:** §Limiting permissions for tokens — https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#limiting-permissions-for-tokens

### `fetch-depth: 1` for build/release/analyze jobs

A shallow clone of depth 1 fetches only the latest commit — sufficient for building documents
and running CodeQL on static files. Explicit declaration makes the intent auditable.
`proposals.yml` detect job uses `fetch-depth: 2` to support `git diff HEAD~1 HEAD`.

**Reference:** https://github.com/actions/checkout#usage

### `concurrency.cancel-in-progress: true`

New pushes to the same branch cancel any in-progress run for the same workflow+ref. Rapid
pushes (typo fix, amend) would otherwise queue redundant runs, consuming CI minutes and
potentially racing to upload the same artifact.

**Reference:** https://docs.github.com/en/actions/using-jobs/using-concurrency

### `timeout-minutes` on all jobs

Without a timeout, a hung step (Chrome failing to launch, network stall) consumes the full
6-hour GitHub Actions job limit. Explicit timeouts surface failures quickly:
- `detect`: 10 minutes (git diff only)
- `analyze`: 15 minutes (CodeQL on workflow YAML)
- All build jobs: 30 minutes (full PDF/HTML/DOCX pipeline)

**Reference:** https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration

### `if: github.event_name != 'pull_request'` on Docker push steps

Pull requests from forks run with a restricted `GITHUB_TOKEN` that does not have `packages:
write` permission. Attempting a `docker push` on a fork PR fails with 403. Skipping push on
PR still builds and validates the Docker image, and pushes only on direct pushes to the repo.

**Reference:** §Using secrets — https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-secrets

### `fail-fast: false` in proposals matrix

Each proposal is independent. If one proposal's build fails, others should complete and be
reported. The default `fail-fast: true` would cancel all matrix jobs on the first failure,
hiding information about the remaining proposals.

**Reference:** https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs#handling-failures

### SHA-256 verification in CI download steps (even on cache hit)

The binary download steps verify SHA-256 both when downloading fresh and when restoring from
cache. While GitHub's Actions cache is a trusted service, defence-in-depth means we verify
the binary we're about to execute regardless of where it came from.

**Reference:** OpenSSF Supply Chain Best Practices — https://best.openssf.org

### `curl -fsSL` for binary downloads

`curl -fsSL -o <file> <url>` is used in place of `wget -q <url>`:
- `-f`: fail immediately on HTTP errors (4xx/5xx), returning a non-zero exit code
- `-s`: silent (no progress bar)
- `-S`: show errors even in silent mode
- `-L`: follow redirects
- `-o <file>`: explicit output filename

Consistent with the Dockerfile convention and eliminates the risk of silently caching an
error response.

### Quoted `${{ matrix.proposal }}` in shell commands

`${{ matrix.proposal }}` is template-expanded by GitHub Actions before the shell script runs.
If a proposal name contained special characters or whitespace (e.g. from a manually created
directory), an unquoted expansion would cause shell word-splitting. Quoting all uses ensures
the value is treated as a single argument regardless of content.

**Reference:** §Script injection — https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#understanding-the-risk-of-script-injections

### Stable, shared cache keys

Cache keys are version-pinned strings shared across all three build workflows:
- `pandoc-$VERSION` / `pandoc-crossref-$VERSION`: keyed by tool version
- `apt-ubuntu-24.04-texlive-v1`: stable key; bump the suffix if apt packages change
- `npm-mermaid-filter-X.Y.Z-markdownlint-X.Y.Z`: invalidated automatically on version bump

Sharing keys across workflows means a warm cache from `build.yml` benefits `proposals.yml`
and `release.yml` without a separate download.

**Reference:** https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows#matching-a-cache-key

---

## CodeQL (`codeql.yml`)

### `language: [actions]`

This repository has no application source code (Python, JavaScript, etc.) to analyse.
The `actions` language target scans GitHub Actions workflow YAML files for dangerous patterns
such as script injection via user-controlled `github.event` values.

**Reference:** CodeQL supported languages — https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning-with-codeql#about-codeql

### `continue-on-error: true`

Uploading SARIF results to GitHub's Security tab requires GitHub Advanced Security (GHAS),
which is not available on private repositories without a paid GHAS licence. The analysis
still runs and contributes to the OpenSSF Scorecard SAST signal; only the upload step is
non-fatal.

**Reference:** GitHub Advanced Security — https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security

### Weekly scheduled scan

The push/PR triggers catch newly introduced issues. The weekly `cron` schedule catches issues
introduced by newly published CodeQL query packs that were not available when the code was
last pushed.

**Reference:** https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/customizing-your-advanced-setup-for-code-scanning#scanning-on-a-schedule

---

## Dependabot (`.github/dependabot.yml`)

**Reference:** https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates

### Three ecosystems: `github-actions`, `docker`, `npm`

All three are potential supply chain attack vectors:
- `github-actions`: mutable tags on third-party Actions
- `docker`: Ubuntu base image security patches
- `npm`: mermaid-filter and markdownlint-cli vulnerability patches

**Reference:** OpenSSF Scorecard "Dependency-Update-Tool" — https://securityscorecards.dev

### Weekly cadence

Daily would generate noise; monthly would leave vulnerable versions unpatched too long.
Weekly aligns with the OpenSSF Scorecard expectation for dependency update frequency.

### `commit-message.prefix: chore`

Dependabot PR commits are prefixed `chore:` for consistency with the project's Conventional
Commits format, allowing automated changelog tools to categorise dependency bumps correctly.

**Reference:** Conventional Commits — https://www.conventionalcommits.org/en/v1.0.0/#specification

---

## Pre-commit (`.pre-commit-config.yaml`)

**Reference:** pre-commit framework — https://pre-commit.com/

### `default_install_hook_types: [pre-commit, commit-msg]`

`pre-commit install` only installs the `pre-commit` hook type by default. The `commit-msg`
type is required for the Conventional Commits hook. Declaring both at config level means a
single `pre-commit install` installs both without extra flags.

**Reference:** https://pre-commit.com/index.html#pre-commit-install

### Hook versions pinned to match CI and Dockerfile

`rev: v0.44.0` for markdownlint-cli, `rev: v2.3.0` for codespell match the versions in
`package.json`, `.pre-commit-config.yaml`, CI workflows, and Dockerfile. Different versions
between pre-commit and CI would allow commits that pass locally to fail in CI.

### `files:` pattern restricts to content Markdown

Markdownlint and codespell run only on `(markdown|proposals/.+/markdown)/.*\.md$`. README,
CLAUDE.md, and other repository Markdown files have different formatting conventions and are
not part of the generated document output.

---

## EditorConfig (`.editorconfig`)

**Reference:** EditorConfig specification — https://editorconfig.org/

### `root = true`

Stops EditorConfig's upward search for parent `.editorconfig` files. Without this,
parent-directory configs (if any) could override project settings silently.

### `end_of_line = lf`

LF (Unix) line endings are the POSIX standard. CRLF in a repository causes `make` recipe
parsing failures on some implementations (CRLF-terminated recipe lines are treated as
literal characters) and produces noisy diffs on cross-platform teams.

**Reference:** POSIX §2.2 — https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap02.html

### `charset = utf-8`

UTF-8 is the IETF-mandated encoding for Internet text (RFC 3629). Pandoc processes Markdown
as UTF-8 by default; non-UTF-8 source files would produce encoding errors at build time.

**Reference:** RFC 3629 — https://www.rfc-editor.org/rfc/rfc3629

### `insert_final_newline = true`

POSIX defines a text file as a sequence of newline-terminated lines. Files missing the final
newline cause unexpected behaviour in `wc -l`, `diff`, `cat`, and other Unix tools.

**Reference:** POSIX §3.206 — https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_206

### `indent_style = tab` for Makefile

This is not a style preference — it is a POSIX and GNU Make requirement. Recipe lines
indented with spaces are silently treated as non-recipe continuation lines, producing
`*** missing separator` errors.

**Reference:** POSIX Make §1.3 — https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html

### `trim_trailing_whitespace = false` for `*.md`

The CommonMark specification defines two or more trailing spaces on a line as a hard line
break (`<br>`). Automatically trimming Markdown trailing whitespace would silently destroy
intentional hard line breaks.

**Reference:** CommonMark spec §2.2 — https://spec.commonmark.org/0.31.2/#hard-line-breaks

---

## markdownlint (`.markdownlint.yaml`)

**Reference:** markdownlint rules — https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md

### `default: true` with selective disable

Opt-out is safer than opt-in: new rules published in future markdownlint releases are
automatically active. Every disabled rule requires an explicit justification in this file.

### MD013 disabled — line length

arc42 prose sections contain long descriptive lines, table cells, and URLs that would require
mechanical wrapping with no readability benefit.

### MD024 disabled — duplicate headings

arc42 section templates reuse structural heading names (e.g. "Overview") across different
numbered sections.

### MD033 disabled — inline HTML

Mermaid diagram code fences and Pandoc raw HTML pass-through attributes require inline HTML
in source files.

### MD041 disabled — first line heading

arc42 section files begin with a level-1 heading; however, non-content `.md` files that may
be encountered via glob patterns do not, and would produce false positives.

---

## package.json

**Reference:** npm package.json — https://docs.npmjs.com/cli/v10/configuring-npm/package-json

### `"private": true`

Prevents accidental `npm publish` from publishing this internal tooling manifest to the public
npm registry. This file manages build tool version pins, not a distributable library.

**Reference:** https://docs.npmjs.com/cli/v10/configuring-npm/package-json#private

### `"engines": { "node": ">=22" }`

Declares the Node.js version requirement. Node.js 20 reached End of Life on 30 April 2026;
Node.js 22 is the current LTS. `npm install` warns on incompatible versions.

**Reference:** Node.js release schedule — https://nodejs.org/en/about/previous-releases

### Exact version pins (no `^` or `~`)

Range specifiers (`^1.4.7`) allow `npm install` to silently upgrade to newer patch or minor
versions, which may behave differently. Exact pins ensure every environment uses identical
versions, making environment-specific failures impossible.

---

## SECURITY.md

### Coordinated disclosure

Vulnerabilities are reported via private email, not public GitHub issues. Public disclosure
before a fix is available gives attackers a head start. The 48-hour acknowledgement / 7-day
response window follows coordinated disclosure norms.

**Reference:** OWASP Vulnerability Disclosure Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html

### Explicit scope section

Clearly defines the supply-chain attack surface (Dockerfile, Actions workflows, Makefile
shell execution) to help reporters focus on areas of genuine risk, and explicitly marks
generated document content as out of scope.

---

## codespell (`.codespellrc`)

**Reference:** https://github.com/codespell-project/codespell#configuration

### `skip` list

`.git`, `*.bib`, `*.pdf`, `*.html`, `project.tex`, `project.css` are excluded:
- Binary files (PDF) produce false positives from binary content
- BibTeX (`.bib`) contains author names and journal abbreviations that are not prose
- Generated LaTeX (`project.tex`) and CSS (`project.css`) contain keywords and identifiers
  that trigger hundreds of false positives
