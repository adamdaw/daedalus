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
`@mermaid-js/mermaid-cli` does not force a re-download of TeX Live.

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

Puppeteer (used by `@mermaid-js/mermaid-cli`) is tested against Google Chrome. Ubuntu's
packaged `chromium-browser` may lag behind the Puppeteer-compatible version or diverge in
behaviour. Using Chrome from Google's official apt repository ensures Puppeteer compatibility.

**Reference:** https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker  
**Reference:** https://github.com/mermaid-js/mermaid-cli/blob/master/docs/already-installed-chromium.md

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

### npm `overrides` to patch transitive CVEs; local install + manual bin links to apply them in Docker

`npm install -g pkg@version` has no package.json project context, so `overrides` is ignored.
To force a transitive dependency to a patched version in the Docker image, the Dockerfile:

1. COPYs `package.json` (with the `overrides` field) to a temp directory
2. Runs `npm install` locally (reads `package.json`, applies `overrides`)
3. Copies the resulting `node_modules/` to `/usr/local/lib/node_modules/` (the global package location), preserving symlinks
4. Creates `/usr/local/bin/` symlinks to `/usr/local/lib/node_modules/.bin/<bin>` (equivalent to what `npm install -g` does)
5. Cleans up the temp directory

npm local installs put packages in `<cwd>/node_modules/` with relative bin symlinks in `<cwd>/node_modules/.bin/`. npm global installs put packages in `<prefix>/lib/node_modules/` with absolute bin symlinks in `<prefix>/bin/`. By copying the local tree to the global location and creating the bin symlinks explicitly, the result is identical to `npm install -g` but with `overrides` honoured.

The `overrides` in `package.json` pin `picomatch` to `4.0.4`, patching CVE-2026-33671 (ReDoS
via crafted extglob patterns). `picomatch@4.0.3` is a transitive dependency of `puppeteer`,
itself a dependency of `@mermaid-js/mermaid-cli`.

This pattern follows the same principle as `requirements-dev.txt` for Python: a single
authoritative file pins and constrains all tool versions, and Dependabot tracks it.

**Reference:** npm overrides — https://docs.npmjs.com/cli/v10/configuring-npm/package-json#overrides  
**Reference:** npm install — https://docs.npmjs.com/cli/v10/commands/npm-install

### `npm install --no-fund --no-audit`

`--no-fund` suppresses the funding messages that appear in npm output. `--no-audit` suppresses
the audit report. Both are addressed through Dependabot version-update PRs, not the Docker
build or CI run. Suppressing them keeps build logs clean and free of noise that is not
actionable in an automated context. All three CI workflows use the same flags for consistency
with the Dockerfile.

**Reference:** npm install flags — https://docs.npmjs.com/cli/v10/commands/npm-install

### Chrome `--no-sandbox` wrapper

Docker containers run as root. Chrome's sandbox (the setuid sandbox helper) requires non-root
execution or privileged kernel namespace access not available in standard Docker. Wrapping the
binary with a shell script that injects `--no-sandbox` ensures the flag is always present
regardless of how Puppeteer invokes Chrome.

In CI (non-root user), the `mmdc-pandoc` wrapper script (created in the "Configure mmdc for
pandoc" step) includes the puppeteer config that passes `--no-sandbox` — the Chrome binary
wrapper is the Docker-specific solution.

**Reference:** https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker

### `mmdc-pandoc` wrapper and `MERMAID_BIN`

`filters/diagram.lua` (pandoc-ext/diagram) invokes the Mermaid engine via the binary path
from the `MERMAID_BIN` environment variable (resolved as `<ENGINE>_BIN` per the filter's
`get_engine` function). A bare `mmdc` call does not inject the Puppeteer configuration or the
diagram theme. A thin wrapper script (`mmdc-pandoc`) prepends `--puppeteerConfigFile` and
`--theme` before forwarding all arguments to `mmdc`.

This pattern keeps the Lua filter generic (it knows nothing about Puppeteer or themes) and
externalises the environment-specific configuration into the wrapper — which differs between
Docker (`/usr/local/bin/mmdc-pandoc`, static path) and CI (written to `/usr/local/bin/mmdc-pandoc`
at job startup).

**Reference:** pandoc-ext/diagram `get_engine` — https://github.com/pandoc-ext/diagram  
**Reference:** @mermaid-js/mermaid-cli — https://github.com/mermaid-js/mermaid-cli  
**Reference:** Using system Chrome with mmdc — https://github.com/mermaid-js/mermaid-cli/blob/master/docs/already-installed-chromium.md

### pandoc-ext/diagram Lua filter (vendored at `filters/diagram.lua`)

**Do not use `mermaid-filter`.** The package is unmaintained (last release December 2023),
has CVEs in transitive dependencies with no upstream fix path, and has been fully replaced
in this project. Any future diagram tooling changes must go through `pandoc-ext/diagram` +
`@mermaid-js/mermaid-cli`.

Mermaid diagram rendering was migrated from `mermaid-filter@1.4.7` to
`pandoc-ext/diagram` v1.2.0 + `@mermaid-js/mermaid-cli` v11.12.0.

The Lua filter is vendored (copied verbatim from the upstream tagged release) rather than
fetched at build time. Vendoring pins the exact filter version to a git commit, making
upgrades an explicit code change (auditable in the diff) rather than a silent network fetch.

The filter runs inside pandoc's built-in Lua interpreter — no additional runtime dependency
and no subprocess for the filter itself. Only `mmdc` (the diagram renderer) is an external
process.

Output format: SVG for HTML output (sharper, smaller, scalable); for PDF the filter produces
SVG embedded via pandoc's media bag. DOCX receives PNG (the filter automatically selects the
best format per output type via `format_options`).

**Reference:** pandoc-ext/diagram — https://github.com/pandoc-ext/diagram  
**Reference:** @mermaid-js/mermaid-cli — https://github.com/mermaid-js/mermaid-cli  
**Reference:** pandoc Lua filters — https://pandoc.org/lua-filters.html

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
- `npm-mermaid-cli-X.Y.Z-markdownlint-X.Y.Z`: invalidated automatically on version bump

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

### Four ecosystems: `github-actions`, `docker`, `npm`, `pip`

All four are potential supply chain attack vectors:
- `github-actions`: mutable tags on third-party Actions
- `docker`: Ubuntu base image security patches
- `npm`: @mermaid-js/mermaid-cli and markdownlint-cli vulnerability patches
- `pip`: codespell vulnerability patches and compatibility updates

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

### markdownlint-cli `rev:` pinned to match `package.json`

`rev: v0.44.0` for markdownlint-cli matches the version in `package.json` (the Dependabot
source of truth), CI npm install steps, and the Dockerfile. Different versions between the
pre-commit hook and CI would allow commits that pass locally to fail in CI.

### codespell: `language: system` instead of a repo-pinned `rev:`

codespell does not use a `repo:` entry with a `rev:` field. Instead it uses a local
`language: system` hook that calls whatever `codespell` binary is on the `PATH`.

**Why `language: system`:** codespell is version-pinned in `requirements-dev.txt`, which is
already consumed directly by the Dockerfile (`pip install --constraint ... codespell`) and
all three CI workflows (`pip install --constraint requirements-dev.txt codespell`). A `rev:`
in `.pre-commit-config.yaml` would be a fourth version string to update manually every time
Dependabot opens a PR — exactly the synchronisation problem `requirements-dev.txt` was
introduced to solve. With `language: system`, a single Dependabot PR to `requirements-dev.txt`
updates all four environments (Dockerfile, CI ×3, and the pre-commit hook) without any
additional edits.

**Prerequisite:** codespell must be installed before `pre-commit run` is called. This is
guaranteed in all execution contexts:
- Devcontainer: `postCreateCommand` runs `pip install --constraint requirements-dev.txt codespell` — but codespell is actually already present from the Docker image layer; the `language: system` hook calls `/usr/local/bin/codespell` which is symlinked by the Dockerfile
- CI: `pip install --constraint requirements-dev.txt codespell` runs before any lint/spellcheck step
- Local: `CONTRIBUTING.md` setup instructions install codespell via `pip install --constraint requirements-dev.txt codespell`

**Tradeoff:** unlike repo-based hooks, `language: system` does not auto-install the tool
if it is missing; the hook fails with "command not found" instead. This is acceptable
because all supported execution paths guarantee the install.

**Reference:** pre-commit `language: system` — https://pre-commit.com/index.html#creating-new-hooks

### `check-json` excludes `devcontainer.json`; `check-jsonc` validates it instead

`devcontainer.json` is intentionally JSONC (JSON with Comments) — the Dev Container
specification explicitly uses JSONC to allow inline documentation. The `check-json` hook
from `pre-commit/pre-commit-hooks` uses Python's `json.loads()`, which is a strict JSON
parser and rejects comments. Without the exclusion, `pre-commit run` fails on every commit.

Simply excluding the file and performing no validation would be the common shortcut. Instead,
the project adds a `check-jsonc` local hook (`scripts/validate-jsonc.py`) that strips `//`
comments via a string-context-aware state machine and then validates with `json.loads()`. The
state machine tracks whether the current position is inside a JSON string, so `//` inside a
value (e.g. `"https://example.com"`) is preserved correctly and not treated as a comment.

This preserves the intent of `check-json` (catching JSON syntax errors before they are
committed) while correctly handling the JSONC subset used in `devcontainer.json`.

The `check-json` exclusion is scoped precisely to `^\.devcontainer/devcontainer\.json$`. All
other `.json` files (e.g., `package.json`) remain subject to strict JSON validation.

**Reference:** Dev Container specification — https://containers.dev/implementors/json_reference/

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
npm registry. This file manages build tool version pins, not a distributable library. Without
this field, a bare `npm publish` from the project root would attempt to upload `package.json`
and all non-gitignored files to the public npm registry — leaking internal documentation,
build scripts, and potentially credentials. The `"private": true` field causes npm to
unconditionally refuse the publish, regardless of `.npmignore` or `files` configuration.
This is a defence-in-depth measure: even if an automated script or CI misconfiguration
invokes `npm publish`, the operation is blocked.

**Reference:** https://docs.npmjs.com/cli/v10/configuring-npm/package-json#private

### `"engines": { "node": ">=22" }`

Declares the Node.js version requirement. Node.js 20 reached End of Life on 30 April 2026;
Node.js 22 is the current LTS. `npm install` warns on incompatible versions. The `engines`
field serves as executable documentation — it is checked by npm at install time (when
`engine-strict` is set) and by CI/Docker environments to verify compatibility. Without it,
contributors using an older Node.js version would encounter cryptic runtime errors from
`@mermaid-js/mermaid-cli` or `markdownlint-cli` rather than a clear version mismatch warning.
The `>=22` constraint (rather than `>=20` or exact `22.x`) allows adoption of Node.js 24+
when it becomes LTS without requiring a `package.json` update.

**Reference:** Node.js release schedule — https://nodejs.org/en/about/previous-releases  
**Reference:** npm engines — https://docs.npmjs.com/cli/v10/configuring-npm/package-json#engines

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

## Dev Container (`.devcontainer/devcontainer.json`)

**Reference:** VS Code Dev Containers — https://code.visualstudio.com/docs/devcontainers/containers

### Builds from the project Dockerfile

The dev container uses `"build": { "dockerfile": "../Dockerfile" }` rather than a pre-built
base image. This ensures the dev environment is byte-for-byte identical to the Docker CI
environment — same tool versions, same paths, same Chrome binary.

### `"remoteUser": "root"`

The Dockerfile's Chrome `--no-sandbox` wrapper is installed for root because that is the
expected runtime user in Docker. If `remoteUser` were set to a non-root user, the sandbox
restriction would trigger and Mermaid diagram rendering would fail.

### PEP 668-compliant pre-commit install in `postCreateCommand`

Ubuntu 24.04 marks the system Python as externally managed. `pip install` without a
virtualenv fails with `externally-managed-environment`. The same venv pattern used in the
Dockerfile is applied here: `python3 -m venv /opt/pre-commit`, install into the venv,
symlink the binary for global access. This avoids `--break-system-packages`.

**Reference:** PEP 668 — https://peps.python.org/pep-0668/

### `pre-commit install` — single command installs both hook types

`pre-commit install` alone only installs the `pre-commit` hook type by default. The
`commit-msg` type is required for the Conventional Commits enforcement hook.

This is solved at the config level with `default_install_hook_types: [pre-commit, commit-msg]`
in `.pre-commit-config.yaml` (see the Pre-commit section). With that declaration in place, a
bare `pre-commit install` — with no `--hook-type` flags — installs both types. The
`postCreateCommand` uses this minimal form.

**Reference:** https://pre-commit.com/index.html#pre-commit-install

### `files.trimTrailingWhitespace` override for Markdown

The global VS Code setting `files.trimTrailingWhitespace: true` is correct for most file
types. However, the CommonMark specification defines two or more trailing spaces on a line
as a hard line break (`<br>`). The `[markdown]` language-specific override sets
`files.trimTrailingWhitespace: false` for `.md` files to prevent the editor from silently
destroying intentional line breaks. This mirrors the `.editorconfig` `trim_trailing_whitespace = false`
rule for `*.md` files.

**Reference:** CommonMark spec §2.2 — https://spec.commonmark.org/0.31.2/#hard-line-breaks

### EditorConfig extension recommended

The `editorconfig.editorconfig` VS Code extension reads `.editorconfig` and applies rules
in the editor — including the `trim_trailing_whitespace = false` override for `*.md`. Without
the extension, VS Code ignores `.editorconfig` and the global trim setting would win.

**Reference:** EditorConfig for VS Code — https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig

---

## OCI Build Metadata (`BUILD_DATE` and `VCS_REF`)

**Reference:** OCI Image Spec annotations — https://github.com/opencontainers/image-spec/blob/main/annotations.md

### `org.opencontainers.image.created` and `org.opencontainers.image.revision`

The OCI Image Specification defines standard labels for documenting when and from what
source a container image was built. `created` is a RFC 3339 timestamp (UTC); `revision`
is the source VCS commit identifier. These fields are consumed by:
- Container registries (GHCR, Docker Hub) — displayed in the image detail view
- Vulnerability scanners (Trivy, Grype) — used to correlate age-related CVEs
- Supply chain tooling — used alongside SLSA attestations to verify provenance

### ARG, not ENV

`BUILD_DATE` and `VCS_REF` are passed as `ARG`, not baked as `ENV`. ARG values are
available during the build but do not persist in the final image environment. This prevents
the timestamp from appearing in `docker run` environment output and avoids breaking the
Docker layer cache on every build (a `FROM` with an `ENV BUILD_DATE=...` would invalidate
the entire cache on every run).

### CI: separate "Capture OCI label metadata" step

`github.sha` is available as a context variable in all CI steps. The build timestamp is
not — GitHub Actions has no built-in expression for the current UTC time. A dedicated
shell step runs `date -u +%Y-%m-%dT%H:%M:%SZ` and writes the result to `$GITHUB_OUTPUT`,
making it available to the subsequent `docker/build-push-action` step via
`${{ steps.oci-meta.outputs.date }}`.

### Makefile: `$(shell ...)` for local builds

For local `make docker-build`, `$(shell date -u ...)` and `$(shell git rev-parse HEAD ...)`
are evaluated at recipe time by Make's shell function, producing the timestamp and commit
SHA at the moment of the build.

---

## Python Tool Version Management (`requirements-dev.txt`)

**Reference:** pip requirements format — https://pip.pypa.io/en/stable/reference/requirements-file-format/  
**Reference:** Dependabot pip ecosystem — https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem

### `requirements-dev.txt` as source of truth for codespell and pre-commit

`requirements-dev.txt` pins two Python tools: `codespell` (CI build tool) and `pre-commit`
(developer workflow tool). Dependabot's `pip` ecosystem entry opens weekly PRs against this
single file. A Dependabot PR requires zero manual follow-up edits anywhere.

### `--constraint` instead of `-r` (install list)

pip's `-r` flag installs every package listed in the file. pip's `--constraint` flag uses
the file purely as a version pin — only the packages explicitly named on the command line
are installed, constrained to the versions in the file. This means each environment installs
only the tool it actually needs:

| Environment | Command | Installs |
| --- | --- | --- |
| Dockerfile | `pip install --constraint ... codespell` | codespell only (pre-commit has no place in the build image) |
| CI (×3) | `pip install --constraint ... codespell` | codespell only (pre-commit is a dev workflow tool, not a build tool) |
| devcontainer | `pip install --constraint ... pre-commit` | pre-commit only (codespell is already in the image from the Dockerfile layer) |
| contributor local | `pip install --constraint ... pre-commit` | pre-commit only (codespell installed separately per CONTRIBUTING.md) |

Using `-r` instead would silently install the wrong tool in each environment: the Dockerfile
would ship pre-commit in the build image; the devcontainer would redundantly install a second
copy of codespell alongside the one already symlinked from the Dockerfile layer.

**Reference:** pip constraints files — https://pip.pypa.io/en/stable/user_guide/#constraints-files

### CI uses `--constraint`, not an inline version string

All three CI workflows use `pip install --constraint requirements-dev.txt codespell` rather
than `pip install codespell==X.Y.Z`. When Dependabot bumps codespell in `requirements-dev.txt`,
the CI workflows pick up the new version automatically — no additional edits required.
Only codespell is installed; pre-commit (also in `requirements-dev.txt`) is not installed
in CI because it is a developer workflow tool, not a build tool.

### Why CI doesn't need venv (PEP 668)

GitHub Actions ubuntu-24.04 runners execute as a non-root user (`runner`). `pip install`
without `sudo` installs to `~/.local/lib/python3.x/site-packages/` (user site-packages),
which is not the system-managed Python environment and does not trigger PEP 668's
`externally-managed-environment` guard. venv is required in the Dockerfile (root user
writing to system Python paths) and the devcontainer (same root context); it is unnecessary
overhead in the non-root CI runner environment.

**Reference:** PEP 668 — https://peps.python.org/pep-0668/

---

## Docker Vulnerability Scanning (Trivy)

**Reference:** aquasecurity/trivy-action — https://github.com/aquasecurity/trivy-action  
**Reference:** OpenSSF Scorecard "Vulnerabilities" check — https://securityscorecards.dev

### Trivy scans before GHCR push

The `build.yml` docker job scans the locally built image with Trivy before pushing it to
GHCR. This ensures no image with known CRITICAL or HIGH unfixed CVEs is published to the
registry — consumers pulling `:latest` always get a scanned image.

### `exit-code: 1` on CRITICAL/HIGH unfixed

`exit-code: '1'` fails the workflow if any unfixed CRITICAL or HIGH CVE is found.
`ignore-unfixed: true` suppresses CVEs that have no available fix in the package manager
(no actionable remediation exists). Together these settings block publishable vulnerabilities
while avoiding alert fatigue from issues that cannot be resolved by upgrading packages.

### `.trivyignore` — targeted CVE suppression for npm's internal dependency tree

The `.trivyignore` file suppresses CVEs that are confirmed non-actionable with a
documented justification. Each entry uses Trivy's targeted ignore format (Trivy >= 0.53.0):

```
CVE-XXXX-NNNNN target:<artifact-path>
```

The `target:` constraint limits suppression to a specific artifact path, leaving all other
instances of the same CVE active. An entry is added only when:
1. The affected package is inside npm's own internal bundle (`/usr/lib/node_modules/npm/`)
   — not any code we wrote or tools we invoke
2. The attack vector does not apply in our build pipeline context (npm's internal picomatch
   processes only trusted package manifest data, never user-controlled input)
3. The fix is not available through our toolchain (npm bundles its own transitive deps
   independently of our `package.json` overrides)

The CVE-2026-33671 entry targets `usr/lib/node_modules/npm/node_modules/picomatch/package.json`
— npm's own bundled picomatch@4.0.3 installed by NodeSource. Upgrading npm (10.x → 11.x) was
investigated but npm@11.x bundles `tinyglobby` which also carries picomatch@4.0.3, so the CVE
is present in npm's internal bundle regardless of npm version. The entry will be removed when
NodeSource ships a Node.js version whose bundled npm no longer includes picomatch@4.0.3.

Each entry includes a documented rationale and a removal condition.

**Reference:** Trivy ignore format — https://aquasecurity.github.io/trivy/latest/docs/configuration/filtering/#trivyignore-format

### OpenSSF Scorecard signal

The OpenSSF Scorecard "Vulnerabilities" check awards points when a project uses a
vulnerability scanner (e.g., Trivy, Grype, Snyk) on its container images. Adding Trivy to
the Docker publish step satisfies this check.

---

## SLSA Build Provenance

**Reference:** SLSA (Supply-chain Levels for Software Artifacts) — https://slsa.dev  
**Reference:** actions/attest-build-provenance — https://github.com/actions/attest-build-provenance

### Status: deferred until repository is public

`actions/attest-build-provenance` requires either a public repository or a GitHub
Organization account. This is a private user-owned repository; the step fails with
"Feature not available for user-owned private repositories."

The step and its associated permissions (`id-token: write`, `attestations: write`) have
been removed from the docker job in `build.yml`. Build provenance is captured via OCI
image labels (`org.opencontainers.image.created` and `.revision`).

When the repository is made public, re-add to the docker job:
1. Permissions: `id-token: write` and `attestations: write`
2. Digest capture in the push step (see git history)
3. The attestation step using `actions/attest-build-provenance`

### What it will provide

Once re-enabled, `actions/attest-build-provenance` will generate and sign a SLSA Level 2
provenance statement attached to the image in GHCR as an OCI referrer. The attestation records:
- The exact image digest (sha256:...)
- The GitHub repository, ref, and commit SHA
- The Actions workflow run ID and trigger event

Consumers can verify with `gh attestation verify` to confirm the image was built from the
expected source commit by the expected workflow.

---

## Versioned Docker Tags

### `:vN.N.N` tag on version tag push

When a `v*` tag triggers `build.yml`, the docker job pushes an additional tag:
`ghcr.io/owner/repo:v1.2.3`. This gives consumers a human-readable, stable version pin
alongside the immutable commit-SHA tag. The versioned tag is derived from `github.ref_name`
(the pushed tag name) and applied to the same image digest as `:${{ github.sha }}`.

The step uses `github.ref_type == 'tag'` to distinguish tag pushes from branch pushes,
so only version releases receive a versioned Docker tag.

---

## CONTRIBUTING.md

**Reference:** GitHub community health files — https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file

### Standard community health file

`CONTRIBUTING.md` is a GitHub community health file. GitHub surfaces it automatically on
the new issue form, new PR form, and the repository's Insights → Community Standards page.
Its presence contributes to the OpenSSF Scorecard "Contributors" and "Maintained" checks.

The file documents:
- All three dev environment options (devcontainer, Docker, local)
- Tool version pins and where to find them
- Quality check commands
- PEP 668-compliant pre-commit setup instructions
- Conventional Commits format and examples
- PR submission process and review expectations
- Release tagging process

---

## Issue and PR Templates

**Reference:** GitHub issue templates — https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates

### `.github/ISSUE_TEMPLATE/` — structured issue forms

`bug_report.md` and `feature_request.md` define the structure for new issues. Structured
templates produce consistently useful reports (environment, steps to reproduce, expected vs
actual behaviour) and reduce back-and-forth asking for clarifying information.

Pre-filling the title with `fix: ` or `feat: ` nudges reporters toward Conventional Commits
format for the eventual commit that closes the issue.

### `.github/pull_request_template.md` — PR checklist

A PR template surfaces the test checklist on every new pull request, reducing the chance
of a PR being merged without the author having run validation locally. It also reminds
contributors to link related issues (`Closes #NNN`) and notes the Conventional Commits
commit message requirement.

---

## codespell (`.codespellrc`)

**Reference:** https://github.com/codespell-project/codespell#configuration

### `skip` list

`.git`, `*.bib`, `*.pdf`, `*.html`, `project.tex`, `project.css` are excluded:
- Binary files (PDF) produce false positives from binary content
- BibTeX (`.bib`) contains author names and journal abbreviations that are not prose
- Generated LaTeX (`project.tex`) and CSS (`project.css`) contain keywords and identifiers
  that trigger hundreds of false positives

The `skip` list in `.codespellrc` applies when codespell scans a directory (e.g. `make
spellcheck` passes `markdown/` as a directory argument). The pre-commit `codespell` hook
does not duplicate `--skip` in its `args:` — pre-commit's default `pass_filenames: true`
passes individual matched filenames, not directories, so skip glob patterns in args would
have no effect. The `files:` pattern in the hook already restricts input to `.md` content
files.

**Reference:** pre-commit `pass_filenames` — https://pre-commit.com/index.html#creating-new-hooks

### British English: `en-GB_to_en-US` not added to `--builtin`

The project writes prose in British English. codespell's default builtins are `clear` and
`rare`, which focus on unambiguous typos. The optional `en-GB_to_en-US` builtin explicitly
flags British spellings as errors and suggests American English replacements — it is
deliberately not added.

If a domain term is incorrectly flagged by the default dictionaries, add it inline:

```ini
[codespell]
ignore-words-list = term1,term2
```

**Reference:** codespell builtin dictionaries — https://github.com/codespell-project/codespell#usage  
**Reference:** jj-vcs/jj@93368f1 — example of a project that explicitly enables `en-GB_to_en-US` to enforce American English

---

### ShellCheck for shell script analysis

**Decision:** All shell scripts in `scripts/` are analysed with ShellCheck (https://www.shellcheck.net/)
on every commit (pre-commit hook) and in CI.

**Rationale:** The non-AI elicitation path runs entirely through bash scripts — they must be
production-grade. ShellCheck catches quoting errors, unused variables, non-portable constructs,
and other common shell scripting mistakes that manual review often misses. ShellCheck is the
de facto standard static analysis tool for shell scripts, with over 35k GitHub stars, support
for bash/sh/dash/ksh, and comprehensive coverage of POSIX compliance issues. Its wiki provides
detailed explanations and fixes for every diagnostic code, making it educational as well as
preventive.

**Alternatives considered:** shellharden (Rust-based — focuses on quoting fixes, narrower
scope than ShellCheck's full diagnostic range), shfmt (Go-based — formatter only, does not
perform semantic analysis), bash -n (syntax check only — catches parse errors but not logic
bugs or quoting issues), manual code review (unreliable for shell's many quoting and
expansion edge cases).

**References:**
- ShellCheck — https://www.shellcheck.net/
- Shell Script Best Practices — https://sharats.me/posts/shell-script-best-practices/
- shellcheck-py (pre-commit integration) — https://github.com/shellcheck-py/shellcheck-py

**Applied in:** `.pre-commit-config.yaml` (shellcheck-py hook), `.github/workflows/build.yml`
(CI steps in build and test-elicitation jobs), `Dockerfile` (apt-get install), `Makefile`
(`shellcheck` target, part of `validate`).

---

### bats-core for shell script testing

**Decision:** Shell scripts are unit-tested with bats-core (https://github.com/bats-core/bats-core),
the Bash Automated Testing System. Tests are TAP-compliant and run in CI.

**Rationale:** The non-AI elicitation pipeline (`gather-requirements.sh`, `gather-brief.sh`,
`assemble.sh`, `validate-artifacts.sh`, `progress.sh`) is the primary interface for teams
without Claude Code. Unit tests verify each script's argument parsing, output format, edge
cases (missing files, empty sections), and cross-script integration. bats-core is the most
popular bash testing framework (10k+ GitHub stars), available in Ubuntu/Debian apt repos,
with TAP-compliant output that integrates with any CI system. The `@test` syntax is intuitive
— tests are just bash functions; heredoc/pipe input patterns work naturally for testing
stdin-driven scripts like the gather scripts.

**Alternatives considered:** shunit2 (xUnit-based — older, less actively maintained, its own
test suite has broken tests in recent versions), shellspec (BDD-style — more features
including mocking, parameterised tests, and multi-shell support, but less ubiquitous and the
BDD DSL adds learning overhead), basht (minimalist — too simple for a project of this size),
plain bash scripts with exit codes (no framework — poor test reporting and isolation).

**References:**
- bats-core — https://github.com/bats-core/bats-core
- TAP (Test Anything Protocol) — https://testanything.org
- Bash Best Practices — https://bertvv.github.io/cheat-sheets/Bash.html
- shellspec comparison — https://shellspec.info/comparison.html

**Applied in:** `test/scripts/*.bats` (test files), `.github/workflows/build.yml`
(test-elicitation job), `Dockerfile` (apt-get install), `Makefile` (`test-scripts` target).

---

### 90% coverage gates per language

**Decision:** Enforce a minimum 90% line-level code coverage gate for all project-owned code.
The gate fails the build if coverage drops below 90% for any language.

**Per-language enforcement:**

| Language | Tool | Gate mechanism | Applied in |
|---|---|---|---|
| Bash | bashcov + SimpleCov | `.simplecov` → `minimum_coverage 90` | `make coverage`, CI |
| Python | pytest-cov | `--cov-fail-under=90` | `make test-python`, CI |
| Lua | (excluded — vendored) | Integration tests must pass | `make test-lua`, CI |

**Rationale:** Line-level coverage gates prevent regressions and ensure the non-AI elicitation
path (the primary interface) remains production-grade. The 90% threshold is an industry-standard
target for mature projects. Below 80% allows too many untested code paths, increasing regression
risk. Above 95% forces testing trivial code (guard clauses, unreachable error handling) with
diminishing returns and brittle tests. 90% balances thoroughness with the practical reality
that some code paths (interactive terminal I/O, error recovery from external tools) require
complex test fixtures.

**Alternatives considered:** 80% (simpler to achieve but leaves significant gaps), 95%
(stricter but forces testing edge cases that rarely execute), 100% (theoretically ideal but
practically unachievable for interactive scripts without mocking the terminal).

**Vendored Lua exclusion:** `filters/diagram.lua` is vendored third-party code
(pandoc-ext/diagram v1.2.0). It runs inside pandoc's embedded Lua interpreter, which does
not support standard coverage instrumentation (luacov). It is tested via integration tests
but excluded from the per-language gate. This is standard practice for vendored dependencies.

**References:**
- bashcov — https://github.com/infertux/bashcov
- SimpleCov minimum_coverage — https://github.com/simplecov-ruby/simplecov#minimum-coverage
- pytest-cov — https://pytest-cov.readthedocs.io
- Coverage gates best practice — https://docs.codecov.io/docs/commit-status
- Google Testing Blog — https://testing.googleblog.com

---

## Architecture & Standards

### arc42 as default documentation template

**Decision:** Use arc42 as the default architecture documentation template.

**Rationale:** Pragmatic, section-driven (11 concrete sections vs. abstract views), maps naturally to C4 diagrams, widely adopted in enterprise software. Template-based — authors fill sections rather than defining views from scratch. Process-neutral (no mandated methodology). Critically, the pipeline itself is framework-agnostic: Pandoc + Markdown can render any structure. arc42 is the current default, not a permanent commitment.

**Alternatives considered:** TOGAF ADM deliverables (enterprise-scale, viewpoint-driven — planned enhancement), 4+1 View Model (Philippe Kruchten — logical/process/physical/development + scenarios — planned enhancement), Rozanski & Woods viewpoints (context/functional/information/concurrency/deployment/operational), ISO/IEC/IEEE 42010:2022 (formal architecture description standard — viewpoints + views + correspondence rules — planned enhancement), C4-only lightweight mode (diagrams + ADRs, skip prose sections — planned enhancement), custom user-defined templates (planned enhancement).

**References:**
- arc42 — https://arc42.org
- docs/ENHANCEMENTS.md for planned alternatives

**Applied in:** `templates/`, `markdown/`, `.claude/commands/gather-*.md`, `scripts/gather-brief.sh`

---

### ISO/IEC/IEEE 29148:2018 for requirements specification

**Decision:** Use ISO/IEC/IEEE 29148:2018 as the requirements specification standard.

**Rationale:** Modern triple-badged standard (ISO + IEC + IEEE). Supersedes IEEE 830-1998. Covers the full requirements lifecycle (stakeholder → system → software requirements), not just SRS document format. Explicit traceability requirements (§5.2.8). Well-structured section hierarchy maps directly to the five /req-* elicitation commands.

**Alternatives considered:** IEEE 830-1998 (legacy predecessor — still widely cited but superseded), BABOK v3 (Business Analysis Body of Knowledge — broader business analysis scope, not requirements-specific — planned enhancement), IREB CPRE syllabus (certification-oriented methodology, not a document template), SWEBOK (Software Engineering Body of Knowledge — reference framework, not template), user stories only (lightweight Agile approach, no formal structure — planned enhancement), Volere template (Robertson & Robertson — alternative section structure).

**References:**
- ISO/IEC/IEEE 29148:2018 — https://www.iso.org/standard/72089.html
- IEEE 29148-2018 — https://standards.ieee.org/standard/29148-2018.html

**Applied in:** `templates/requirements.md`, `.claude/commands/req-*.md`, `scripts/gather-requirements.sh`

---

### C4 Model for architecture diagrams

**Decision:** Use the C4 Model (Context, Container, Component, Code) as the primary diagram notation.

**Rationale:** Hierarchical abstraction maps to arc42 sections (§3 Context, §5 Building Blocks, §7 Deployment). Text-renderable in Mermaid. Lightweight — four levels, each with a clear purpose. Created by Simon Brown specifically for software architecture communication.

**Alternatives considered:** UML component/deployment/sequence diagrams (richer notation but heavier tooling and steeper learning curve), ArchiMate (enterprise architecture, aligned with TOGAF — more formal than needed for single-system docs), SysML (systems engineering — covers hardware + software, overkill for pure software), Structurizr DSL (C4 as code — more opinionated rendering than Mermaid), box-and-line diagrams (informal, no standard semantics or hierarchy).

**References:**
- C4 Model — https://c4model.com
- Software architecture diagrams — https://dev.to/simonbrown/software-architecture-diagrams-which-tool-should-we-use-29e

**Applied in:** `.claude/commands/gather-03.md`, `gather-05.md`, `gather-07.md`; `templates/brief.md`

---

### MoSCoW for requirements prioritisation

**Decision:** Use MoSCoW (Must/Should/Could/Won't) as the default prioritisation method.

**Rationale:** Simplest categorical method — no numeric scoring required. Forces the "Won't" conversation early, preventing scope creep at fixed-scope/fixed-deadline scale. Universally understood by non-technical stakeholders. Well-supported by DSDM methodology.

**Alternatives considered:** WSJF — Weighted Shortest Job First (SAFe — optimises flow using Cost of Delay / Job Size ratio, requires numeric estimates — planned enhancement), Kano model (customer satisfaction — must-be/one-dimensional/attractive, requires survey data — planned enhancement), RICE (Reach × Impact × Confidence / Effort — numeric scoring — planned enhancement), Value vs. Complexity matrix (2×2 visual, good for workshops), dot-voting / stakeholder voting (democratic, quick but unsystematic).

**References:**
- DSDM MoSCoW — https://www.agilebusiness.org/dsdm-project-framework/moscow-prioririsation.html
- Prioritisation methods comparison — https://highberg.com/insights/a-comparison-of-prioritization-methods/

**Applied in:** `templates/requirements.md`, `.claude/commands/req-02.md`, `scripts/gather-requirements.sh`

---

### BDD Given/When/Then for acceptance criteria

**Decision:** Use BDD Given/When/Then format for acceptance criteria in requirements.md §08.

**Rationale:** Testable by definition — each criterion maps directly to an executable test. Ubiquitous format understood by developers, testers, and business stakeholders (Cucumber, SpecFlow, Behave). ISO 29148 §5.2.8 traceability: each acceptance criterion links to a requirement ID. Forces concrete pre-conditions, actions, and observable outcomes.

**Alternatives considered:** ATDD scenarios (similar intent, framed as acceptance tests rather than behaviour specifications), Specification by Example / SbE (Gojko Adzic — uses concrete data examples, more tabular), FIT/FitNesse tables (tabular acceptance tests — framework-specific), decision tables (combinatorial conditions, good for complex business rules), rule-based criteria (simple bullet list of rules — flexible but not testable by format), freestyle prose acceptance tests (simple but ambiguous and hard to automate).

**References:**
- Cucumber BDD — https://cucumber.io/docs/bdd/better-gherkin/
- ISO/IEC/IEEE 29148:2018 (§5.2.8) — https://www.iso.org/standard/72089.html

**Applied in:** `templates/requirements.md` §08, `.claude/commands/req-05.md`, `scripts/gather-requirements.sh`

---

### Requirements and architecture as separate documents

**Decision:** Maintain requirements.md (ISO 29148) and brief.md (arc42) as separate artifacts.

**Rationale:** Different audiences — requirements.md serves business stakeholders and QA; brief.md serves architects and developers. Different lifecycles — requirements stabilise before architecture decisions are finalised. Different standards — ISO 29148 and arc42 have independent section structures. Separation enables parallel work and reuse (requirements can feed multiple architecture proposals). Cross-referencing is handled by the elicitation commands and the RTM (§09).

**Alternatives considered:** Unified requirements-and-architecture document (simpler but mixes audiences and change cadences), ADR-only lightweight approach (just Architecture Decision Records, no formal specification structure), wiki-based documentation (collaborative but harder to version-control and validate in CI).

**Applied in:** `templates/`, `scripts/gather-requirements.sh`, `scripts/gather-brief.sh`, `scripts/assemble.sh`

---

## Methodology & Process

### Non-AI bash/Makefile as the primary interface

**Decision:** The bash scripts and Makefile are the primary interface for the elicitation and build pipeline, not a fallback for the AI-assisted commands.

**Rationale:** End users may not have Claude Code or any AI tool. CI pipelines must validate without AI dependencies. Bash scripts are auditable, version-controlled, diff-able, and automatable. Every GNU/Linux system has bash and make — zero additional runtime dependencies. The AI-assisted commands (/req-*, /gather-*, /elicit, /start-proposal) are enrichment on top of a solid non-AI foundation. If a feature cannot work without AI, it must have a non-AI equivalent.

**References:**
- GNU Make conventions — https://www.gnu.org/software/make/manual/html_node/Makefile-Conventions.html
- Shell script best practices — https://sharats.me/posts/shell-script-best-practices/

**Applied in:** `scripts/`, `Makefile`, `.github/workflows/build.yml` (test-elicitation job validates the non-AI path end-to-end)

---

### British English for all prose

**Decision:** Write all prose (documentation, templates, comments, commit messages) in British English.

**Rationale:** Author preference. Once a spelling convention is chosen, consistency across the entire project is more important than the specific choice. British English is the author's native dialect. codespell's default dictionaries (`clear`, `rare`) do not include the `en-GB_to_en-US` dictionary, so British spellings pass through unchecked — enforcement is by convention and code review.

**Alternatives considered:** American English (would require enabling codespell's `en-GB_to_en-US` dictionary to flag British spellings).

**Applied in:** All prose files, `.codespellrc`, `CLAUDE.md` (documented constraint)

---

### Conventional Commits for commit message format

**Decision:** Enforce Conventional Commits format on all commit messages.

**Rationale:** Enables automated changelog generation from commit history. Type-driven CI logic (feat → minor version bump, fix → patch, chore → no release). Semantic commit history makes git log scannable without reading diffs. Unambiguous format prevents "fix stuff" or "WIP" messages. Widely adopted by major open-source projects (Angular, Vue, Rust).

**Alternatives considered:** Angular commit format (Conventional Commits is a generalisation of Angular's format), Jira-key-prefixed commits (e.g., PROJ-123: description — ties commits to issue tracker), freeform messages (no enforcement — relies on discipline).

**References:**
- Conventional Commits — https://www.conventionalcommits.org/en/v1.0.0/

**Applied in:** `.pre-commit-config.yaml` (commit-msg hook via compilerla/conventional-pre-commit)

---

### CI job decomposition (build, test-elicitation, docker)

**Decision:** Split the CI pipeline into three parallel jobs with distinct responsibilities.

**Rationale:** Separation of concerns — each job validates one aspect of the project: (1) build validates the document pipeline (lint → spellcheck → shellcheck → Lua tests → PDF/HTML/DOCX generation → output validation); (2) test-elicitation validates the non-AI elicitation scripts (bats unit tests, pytest, bashcov coverage, fixture-based integration pipeline); (3) docker validates the containerised environment (Docker build → run inside container → Trivy CVE scan → GHCR push). Parallel execution reduces wall-clock time: test-elicitation (~1 min) completes while docker (~11 min) is still building.

**Alternatives considered:** Single monolithic job (simpler configuration but longer wall-clock time, harder to diagnose failures), per-script job matrix (too granular, excessive overhead from repeated checkouts and installs).

**Applied in:** `.github/workflows/build.yml`

---

## Tool Choices

### bats-core for bash testing (over shunit2, shellspec)

**Decision:** Use bats-core as the bash unit testing framework.

**Rationale — ubiquity:** Most popular bash test framework; available in Ubuntu/Debian apt repos; 10k+ GitHub stars; TAP-compliant output integrates with any CI system. **Relevance:** `@test` syntax is intuitive — tests are just bash functions; heredoc/pipe input patterns work naturally for testing stdin-driven scripts. **Ease of use:** No class hierarchy (unlike shunit2's xUnit style), no domain-specific language to learn (unlike shellspec's BDD DSL).

**Alternatives considered:** shunit2 (xUnit-based — older, less actively maintained, its own test suite has broken tests in recent versions), shellspec (BDD-style — more features including mocking, parameterised tests, and multi-shell support, but less ubiquitous and the BDD DSL adds learning overhead), basht (minimalist — too simple for a project of this size), plain bash scripts with exit codes (no framework — poor test reporting and isolation).

**References:**
- bats-core — https://github.com/bats-core/bats-core
- shellspec comparison — https://shellspec.info/comparison.html

**Applied in:** `test/scripts/*.bats`, `Makefile` (`test-scripts` target), `.github/workflows/build.yml`

---

### pytest for Python testing (over unittest, nose2)

**Decision:** Use pytest as the Python testing framework.

**Rationale — ubiquity:** De facto Python testing standard; installed in virtually every Python development environment; enormous plugin ecosystem. **Relevance:** Fixture system, parametrisation, and pytest-cov plugin for coverage enforcement. **Ease of use:** Zero boilerplate — functions, not classes; automatic test discovery; assert rewriting produces clear failure messages without assertEqual/assertTrue ceremony.

**Alternatives considered:** unittest (Python standard library — built-in but verbose class-based API, weaker fixtures, no parametrize decorator, no plugin ecosystem), nose2 (unittest extension — less actively maintained, smaller community), hypothesis (property-based testing — complementary, not a replacement for unit tests).

**References:**
- pytest — https://docs.pytest.org
- pytest-cov — https://pytest-cov.readthedocs.io

**Applied in:** `test/python/`, `requirements-dev.txt`, `Makefile` (`test-python` target), `.github/workflows/build.yml`

---

### bashcov for bash coverage (over kcov)

**Decision:** Use bashcov (Ruby) for bash code coverage measurement.

**Rationale:** bashcov uses bash's native PS4/BASH_XTRACEFD tracing mechanism, which traces ALL bash execution including sourced files (`scripts/lib/input.sh`) and scripts invoked by bats test subprocesses. SimpleCov integration provides HTML reports, Cobertura XML output, result merging across multiple test runs, and the `.simplecov` configuration file with `minimum_coverage 90` gate enforcement.

**Why not kcov:** kcov v38 (available via apt on Ubuntu 24.04) is too old to trace through bats subprocesses — it instruments bats itself rather than the scripts bats invokes. kcov v43 (latest) fixes this but requires building from source (cmake + C++ compiler), adding significant build complexity. kcov also lacks SimpleCov-style configuration, merge support, and minimum_coverage gating.

**Trade-off:** bashcov requires Ruby, which is an unusual dependency for a bash-focused project. This is the one tool choice driven by technical necessity rather than ubiquity — kcov simply could not produce accurate coverage data for our bats-driven test suite.

**References:**
- bashcov — https://github.com/infertux/bashcov
- kcov — https://github.com/SimonKagstrom/kcov
- bats-core kcov issue — https://github.com/bats-core/bats-core/issues/15

**Applied in:** `Gemfile`, `.simplecov`, `scripts/coverage.sh`, `.github/workflows/build.yml`, `Dockerfile`

---

## Additional Tool Justifications

### Pandoc as document generation engine

**Decision:** Use Pandoc as the core document generation engine.

**Rationale:** Universal converter — Markdown → PDF + HTML + DOCX from a single source. Extensive filter ecosystem: Lua filters (`diagram.lua` for Mermaid/PlantUML/GraphViz), pandoc-crossref (figure/table/equation numbering), citeproc (bibliography). No vendor lock-in — Markdown input is portable to any other tool if Pandoc is ever replaced. Mature, well-documented, actively maintained (John MacFarlane, UC Berkeley).

**Alternatives considered:** Sphinx (Python-centric, requires reStructuredText or MyST-Markdown, primarily HTML output — planned enhancement for web output), Asciidoctor (AsciiDoc markup, Ruby-based, strong PDF via asciidoctor-pdf — planned enhancement for AsciiDoc input), Hugo / MkDocs / Docusaurus (static site generators — web-focused, no native PDF — planned enhancement for web output), LaTeX direct (no Markdown input, requires LaTeX expertise), groff / troff (Unix legacy, not Markdown-based).

**References:**
- Pandoc — https://pandoc.org
- Pandoc Lua filters — https://pandoc.org/lua-filters.html

**Applied in:** `Makefile` (`PANDOC_FLAGS`), `Dockerfile` (pandoc installation), `.github/workflows/build.yml`

---

### XeLaTeX as PDF engine (over pdflatex, LuaLaTeX)

**Decision:** Use XeLaTeX as the PDF rendering engine.

**Rationale:** Enables custom fonts (system fonts via fontspec) and full Unicode support — pdflatex does not support either. XeLaTeX is older and more widely tested than LuaLaTeX, with fewer rendering edge cases. It is the default pandoc PDF engine for custom font usage.

**Alternatives considered:** pdflatex (faster compilation but no custom font support and limited Unicode), LuaLaTeX (newer, adds Lua scripting within LaTeX — ironically relevant given our Lua filter, but has occasional font rendering differences and is less battle-tested; worth revisiting as it matures), Typst (modern alternative to LaTeX — much faster, simpler syntax, but less mature and lacks pandoc integration).

**References:**
- LaTeX Project — https://www.latex-project.org
- Pandoc PDF creation — https://pandoc.org/MANUAL.html#creating-a-pdf

**Applied in:** `Makefile` (`--pdf-engine=xelatex`), `project.tex`

---

### Mermaid as default diagram engine (over PlantUML, GraphViz)

**Decision:** Use Mermaid as the default diagram rendering engine.

**Rationale:** JavaScript-based — renders in browser (GitHub Markdown preview), CLI (mmdc), and embedded environments. No Java dependency (unlike PlantUML). Sufficient diagram types for architecture documentation: flowchart, sequence, entity-relationship, Gantt, C4 (via flowchart subgraphs). The vendored `pandoc-ext/diagram` filter supports PlantUML, GraphViz, TikZ, Asymptote, and Cetz in addition to Mermaid — Mermaid is the default, not the only option.

**Alternatives considered:** PlantUML (more diagram types, UML-native, but requires Java runtime — support already in vendored filter, planned enhancement to test and document), GraphViz/dot (excellent for graph visualisation, widely available via apt — support already in vendored filter, planned enhancement), D2 (modern text-to-diagram, auto-layout — not yet in vendored filter), Structurizr DSL (C4-specific rendering — opinionated but limited to C4), ArchiMate tooling (enterprise-focused — overkill for single-system architecture).

**References:**
- Mermaid — https://mermaid.js.org
- pandoc-ext/diagram — https://github.com/pandoc-ext/diagram
- Text-to-diagram landscape — https://text-to-diagram.com

**Applied in:** `package.json` (`@mermaid-js/mermaid-cli`), `filters/diagram.lua`, `Dockerfile`, `.github/workflows/build.yml`

---

## Testability Patterns

### Shared I/O library (scripts/lib/input.sh)

**Decision:** Extract shared I/O functions (`ask`, `ask_yn`, `ask_multiline`) into a shared library sourced by both gather scripts.

**Rationale:** DRY principle — the three functions were identically duplicated in `gather-requirements.sh` and `gather-brief.sh` (50 lines × 2). Single source of truth means bugs are fixed once, coverage is measured once, and I/O behaviour is guaranteed consistent. Independent testability — the library can be unit-tested in isolation (`test/scripts/input-lib.bats`).

**References:**
- Bash Best Practices — https://bertvv.github.io/cheat-sheets/Bash.html (prefer local variables, Single Responsibility)

**Applied in:** `scripts/lib/input.sh`, `scripts/gather-requirements.sh`, `scripts/gather-brief.sh`, `test/scripts/input-lib.bats`

---

### Section functions + --source-only guard

**Decision:** Refactor gather scripts into named section functions with a `--source-only` guard for test imports.

**Rationale:** Enables unit testing individual sections without running the full interactive flow. Each function (`gather_req_01` through `gather_req_09`, `gather_brief_01` through `gather_brief_11`) reads from stdin and sets global variables — tests pipe known input and verify the results. The `--source-only` guard (`if [[ "${1-}" == "--source-only" ]]; then return 0 2>/dev/null || exit 0; fi`) allows `source script.sh --source-only` to import all functions without executing the main body. Standard pattern in testable bash architecture.

**Applied in:** `scripts/gather-requirements.sh`, `scripts/gather-brief.sh`, `test/scripts/gather-requirements.bats`, `test/scripts/gather-brief.bats`

---

### 90% coverage threshold

**Decision:** Enforce 90% minimum line-level code coverage for all project-owned code.

**Rationale:** Industry-standard threshold for mature projects. Below 80% allows too many untested code paths, increasing regression risk. Above 95% forces testing trivial code (guard clauses, unreachable error handling) with diminishing returns and brittle tests. 90% balances thoroughness with the practical reality that some code paths (interactive terminal I/O, error recovery from external tools) require complex test fixtures.

**Alternatives considered:** 80% (simpler to achieve but leaves significant gaps), 95% (stricter but forces testing edge cases that rarely execute), 100% (theoretically ideal but practically unachievable for interactive scripts without mocking the terminal).

**References:**
- SimpleCov minimum_coverage — https://github.com/simplecov-ruby/simplecov#minimum-coverage
- Codecov commit status — https://docs.codecov.io/docs/commit-status
- Google Testing Blog — https://testing.googleblog.com

**Applied in:** `.simplecov` (`minimum_coverage 90`), `Makefile` (`test-python --cov-fail-under=90`), `docs/pipeline-decisions.md`
