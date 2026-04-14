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

### PL-06 — apt cache key tied to workflow file hash

**Date:** 2026-04  
**Source:** daedalus CI

The apt package cache is keyed on `${{ hashFiles('.github/workflows/build.yml') }}`.
Changing the workflow file content busts the apt cache, which is useful when adding
new apt packages but can cause unnecessary cache misses for unrelated workflow changes.
The `release.yml` apt cache is keyed separately — both can diverge if one workflow is
updated without the other.

---

### PL-07 — markdownlint-cli and codespell must be pinned consistently

**Date:** 2026-04  
**Source:** daedalus CI + pre-commit

Both tools appear in three places: `.pre-commit-config.yaml` (pre-commit hooks),
the Dockerfile, and the CI workflow `npm install` / `pip install` steps. All three must
use the same version. Current pinned versions:
- markdownlint-cli: 0.44.0
- codespell: 2.3.0

When upgrading, update all three locations atomically.

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

### PL-10 — Ubuntu 24.04 enforces PEP 668; pip3 install requires --break-system-packages

**Date:** 2026-04
**Source:** daedalus Dockerfile, Dependabot docker bump PR

Ubuntu 24.04 ships pip 24.x which enforces PEP 668 (externally-managed-environment).
`pip3 install <package>` fails with "externally managed environment" unless
`--break-system-packages` is passed. Ubuntu 22.04 ships pip 22.0.2, which does not
recognise that flag and would error if it is present.

**Fix:** Use a fallback pattern in the Dockerfile:
```dockerfile
pip3 install --break-system-packages codespell==2.3.0 2>/dev/null \
|| pip3 install codespell==2.3.0
```
Tries with the flag (works on 24.04), falls back without it (works on 22.04).
If both fail, the layer fails as expected.

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

### DL-01 — British English is flagged by codespell

**Date:** 2026-04  
**Source:** daedalus arc42 example

codespell defaults to American English. Common British spellings that fail:
- `fulfilment` → `fulfillment`
- `co-ordinates` → `coordinates`
- `organisation` → `organization`
- `licence` → `license`

Write all prose in American English. Do not add British variants to `.codespellrc` unless
the project explicitly uses British English for all content.

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
