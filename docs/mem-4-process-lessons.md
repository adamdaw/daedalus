# mem-4 — Process Lessons

**Maintained by:** Adam Daw (Bespoke Informatics)
**Load at:** When debugging a build failure, onboarding a new contributor, or planning
a change to the build pipeline.

When a new non-obvious lesson is discovered:
1. Add an entry here with date and project reference.
2. If it implies a prompt change, update the relevant file in `prompts/`.
3. If it implies a pipeline change, update `CLAUDE.md`.
4. Commit — the next session will inherit the knowledge.

---

## Build Pipeline Lessons

### PL-01 — pandoc-crossref version must match pandoc exactly

**Date:** 2026-04  
**Source:** daedalus pipeline build

pandoc-crossref 0.3.17.2 does not exist — the 404 from wget returns exit code 8, which is
not immediately obvious as a "wrong version" error. The correct version for pandoc 3.1.13
is 0.3.17.1. The asset name is `pandoc-crossref-Linux.tar.xz` — later releases use
`Linux-X64` in the filename but this version does not.

**Consequence:** Always verify both versions together against the pandoc-crossref release
page before upgrading. The Makefile, Dockerfile, and all CI workflows must be updated
atomically.

---

### PL-02 — Chrome requires --no-sandbox when running as root in Docker

**Date:** 2026-04  
**Source:** daedalus Docker build

mermaid-filter calls puppeteer which calls Chrome. Chrome refuses to run as root without
`--no-sandbox`. The fix is a wrapper shell script at `/usr/bin/google-chrome-stable` that
appends the flag:

```sh
#!/bin/sh
exec /usr/bin/google-chrome-stable-real --no-sandbox --disable-setuid-sandbox "$@"
```

This is in the Dockerfile. Do not remove it. Do not create a non-root user as a workaround
without verifying that mermaid-filter can still find Chrome via `PUPPETEER_EXECUTABLE_PATH`.

---

### PL-03 — Ubuntu 22.04 minimal image is missing xz-utils

**Date:** 2026-04  
**Source:** daedalus Docker build

The pandoc-crossref tarball is `.tar.xz`. Ubuntu 22.04 minimal does not include `xz-utils`.
The `tar -xf` command exits with code 2 (not a clear "missing tool" error). Always include
`xz-utils` in the Dockerfile base apt install.

---

### PL-04 — Logo path resolution uses --resource-path, not hardcoded images/

**Date:** 2026-04  
**Source:** daedalus project.tex

`\IfFileExists{logo.jpg}` in project.tex relies on `--resource-path=.:$(IMAGES)` in the
pandoc invocation to find `images/logo.jpg`. Do not hardcode `images/logo.jpg` — proposals
have their own `images/` directory that would not match the hardcoded path.

---

### PL-05 — pandoc -H flag injects before hyperref/geometry

**Date:** 2026-04  
**Source:** daedalus project.tex

In pandoc 3.x, `-H file.tex` injects the file's content before pandoc's own template,
which includes `\hypersetup`, `\geometry`, etc. Commands like `\hypersetup{}` placed in
`project.tex` are overridden by pandoc's template. Use metadata variables in `config.yaml`
instead (`colorlinks: true`, `geometry:`, etc.).

---

### PL-06 — apt cache key: use a static version suffix, not a workflow file hash

**Date:** 2026-04  
**Source:** daedalus CI

**Anti-pattern:** Keying the apt cache on `${{ hashFiles('.github/workflows/build.yml') }}`
caused two problems: (1) any unrelated workflow edit busted the apt cache unnecessarily,
adding ~3 minutes to CI; (2) if `build.yml` and `release.yml` used separate keys, they
could diverge silently after an edit to one.

**Current approach:** all three workflows use the same static key `apt-ubuntu-24.04-texlive-v1`.
The cache persists across all workflow runs unless you explicitly increment the suffix.
Increment the suffix (e.g., to `-v2`) when adding or changing apt packages; the old cache
is then cleanly abandoned and rebuilt.

---

### PL-07 — markdownlint-cli and codespell version management differ

**Date:** 2026-04  
**Source:** daedalus CI + pre-commit

The two linting tools use different version management strategies:

**markdownlint-cli** — `package.json` is the source of truth (Dependabot npm ecosystem).
Four places must match: `package.json`, `.pre-commit-config.yaml` (`rev:`), Dockerfile
(`npm install -g`), and all three CI workflows (`npm install -g`). When accepting a
Dependabot PR to `package.json`, update the other three locations manually.

**codespell** — `requirements-dev.txt` is the sole source of truth (Dependabot pip ecosystem).
One place to update: `requirements-dev.txt`. Dockerfile consumes it via `--constraint`
(automatic), CI workflows consume it via `--constraint` (automatic), and `.pre-commit-config.yaml`
uses `language: system` with no `rev:` to sync. A single Dependabot PR to
`requirements-dev.txt` updates all environments automatically — no manual follow-up needed.

---

### PL-08 — GitHub Actions SHA pins + dependabot is the correct supply chain approach

**Date:** 2026-04  
**Source:** daedalus CI security hardening

Mutable `@vN` tags are a supply chain risk — a compromised action publisher could push
malicious code to `@v4` without changing the tag. SHA pins (`uses: action@SHA # vN.N.N`)
are immutable. Dependabot automatically opens PRs to update SHA pins when new releases
are cut. Both pieces are required: SHA pins without dependabot means stale dependencies;
dependabot without SHA pins means no protection.

---

### PL-10 — Ubuntu 24.04 enforces PEP 668; correct fix is a venv, not --break-system-packages

**Date:** 2026-04
**Source:** daedalus Dockerfile, Dependabot docker bump PR

Ubuntu 24.04 ships pip 24.x which enforces PEP 668 (externally-managed-environment).
`pip install <package>` fails with "externally managed environment" in root contexts
(Dockerfile, devcontainer). `--break-system-packages` bypasses the guard but can corrupt
the OS Python environment — it is not the correct fix.

**Fix:** Create an isolated virtual environment per PEP 668's intent:
```dockerfile
RUN python3 -m venv /opt/codespell \
    && /opt/codespell/bin/pip install --no-cache-dir --constraint /tmp/requirements-dev.txt codespell \
    && ln -s /opt/codespell/bin/codespell /usr/local/bin/codespell
```
The symlink provides global `codespell` access without polluting the system Python.
GitHub Actions runners execute as a non-root user; pip installs to `~/.local` (user
site-packages) and does not trigger the PEP 668 guard — venv is not required in CI.

---

### PL-11 — Ubuntu 24.04 AppArmor blocks Chrome sandbox in GitHub Actions

**Date:** 2026-04
**Source:** daedalus build.yml — mermaid-filter / puppeteer on ubuntu-24.04 runner

Ubuntu 24.04 (and 23.10+) restricts unprivileged user namespaces via AppArmor. Chrome's
zygote process requires a usable sandbox to launch and crashes with:
`FATAL: No usable sandbox!`

This affects any CI job that calls puppeteer/Chrome headlessly (mermaid-filter, Playwright, etc.)
on an `ubuntu-24.04` runner. The `ubuntu-22.04` runner was not affected.

**Fix:** Create a puppeteer launch config that passes `--no-sandbox` and point
`MERMAID_FILTER_PUPPETEER_CONFIG` at it via `$GITHUB_ENV`:
```yaml
- name: Configure puppeteer no-sandbox (Ubuntu 24.04 AppArmor)
  run: |
    echo '{"args":["--no-sandbox","--disable-setuid-sandbox"]}' > /tmp/puppeteer-config.json
    echo "MERMAID_FILTER_PUPPETEER_CONFIG=/tmp/puppeteer-config.json" >> $GITHUB_ENV
```
In Docker, wrap the Chrome binary to always inject `--no-sandbox --disable-setuid-sandbox`
(already done in the Dockerfile via the wrapper script).

---

### PL-09 — sed -i is not portable between Linux and macOS

**Date:** 2026-04
**Source:** daedalus Makefile `init` target

GNU `sed -i 's/foo/bar/' file` works on Linux. BSD `sed` (macOS) requires a backup
extension argument: `sed -i '' 's/foo/bar/' file`. The difference is invisible until
someone tries `make init` on a Mac and gets a cryptic error.

**Fix:** Detect the OS with `$(shell uname -s)` and set `SED_I := sed -i ''` on Darwin,
`SED_I := sed -i` otherwise. Use `$(SED_I)` everywhere in-place sed is needed.

---

## Documentation Authoring Lessons

### DL-01 — British English is supported; do not add `en-GB_to_en-US` to builtins

**Date:** 2026-04  
**Source:** daedalus arc42 example; updated 2026-04 after codespell dictionary audit

Write all prose in British English. codespell's default dictionaries (`clear`, `rare`) focus
on unambiguous typos and do not include British→American corrections. The optional
`en-GB_to_en-US` builtin would flag British spellings as errors — do not add it.

The `-ise`/`-our` spellings, `organisation`, `licence`, etc. do not need to be added to
`.codespellrc`; they are not in the default dictionaries. If a specific domain term is
incorrectly flagged, add it as `ignore-words-list = term`.

**Reference:** codespell builtin dictionaries — https://github.com/codespell-project/codespell

---

### DL-02 — arc42 Section 9 (ADRs) is the most frequently skipped

**Date:** 2026-04  
**Source:** daedalus arc42 template

In practice, authors fill Sections 1–8 and then leave Section 9 thin. This is the worst
section to skip — ADRs are the primary mechanism for capturing the "why" behind decisions.
A document with no ADRs is an architecture description, not an architecture specification.

The Adversary should specifically interrogate Section 9 against Section 4. Every technology
or structural decision in Section 4 must have a corresponding ADR in Section 9.

---

### DL-03 — Quality scenarios without response measures are useless

**Date:** 2026-04  
**Source:** daedalus arc42 template, VSDD methodology

A quality scenario that says "the system responds quickly" cannot be verified. The template
explicitly requires a "Measure" column with a concrete figure (latency, uptime %, time bound,
throughput). Enforce this in Adversary review.

---

### DL-04 — Template HTML comments are invisible in PDF output

**Date:** 2026-04  
**Source:** daedalus arc42 template design

The arc42 template uses `<!-- HTML comment -->` for instructional text to the author.
These comments are stripped by pandoc and do not appear in the generated PDF or HTML.
This is intentional — they are editor-visible guidance only. Authors who review only the
PDF without opening the Markdown source may miss the guidance. Ensure `make init` is
followed by a README prompt to open the Markdown files, not the PDF.
