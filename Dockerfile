FROM ubuntu:24.04

# DEBIAN_FRONTEND as ARG (not ENV): scoped to build-time RUN commands only and does not
# persist into the final image. If set as ENV it affects every container run from this image,
# preventing interactive apt operations in derived containers or debugging sessions.
# Docker Dockerfile best practices — https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
ARG DEBIAN_FRONTEND=noninteractive

# Version pins — keep in sync with Makefile and all three CI workflows.
ARG PANDOC_VERSION=3.1.13
ARG CROSSREF_VERSION=0.3.17.1

# SHA-256 digests for supply-chain integrity.
# Declared as ARGs so version upgrades require explicitly updating both the version and the
# digest, making changes auditable. Re-compute when upgrading: sha256sum <downloaded-file>
# OpenSSF Supply Chain Best Practices — https://best.openssf.org/Compiler-Hardening-Guides/Dockerfile-Best-Practices
ARG PANDOC_SHA=b51029afd2e302679aabb9464cd96bda378145d48bb853bd32d93c57b93a293d
ARG CROSSREF_SHA=52a21ef8945e664e7ccfea5f40268db3e3ddee4e7ce1f47f24716fea37c2410e

# OCI image specification annotations — https://github.com/opencontainers/image-spec/blob/main/annotations.md
# Pass BUILD_DATE and VCS_REF at build time for full provenance:
#   docker build --build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) --build-arg VCS_REF=$(git rev-parse HEAD) .
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.title="Daedalus" \
      org.opencontainers.image.description="arc42 document generation pipeline — Pandoc to PDF, HTML, and DOCX" \
      org.opencontainers.image.source="https://github.com/adamdaw/daedalus" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}"

# Layer ordering: most-stable dependencies first, most-frequently-changed last.
# Docker invalidates the build cache from the first changed layer onwards; placing stable
# tooling (base utils, XeLaTeX) before volatile tooling (npm packages) means version bumps
# only invalidate layers from that point forward.
# Reference — https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache

# Base utilities — curl used throughout (not wget) for consistency; -fsSL flags enforce
# error detection (-f: fail on HTTP error), silent output, and redirect following.
# --no-install-recommends: excludes optional packages not required at runtime, reducing
# image size significantly. rm -rf /var/lib/apt/lists/*: must be in the same RUN layer as
# apt-get install to prevent the package index from being baked into the image layer.
# Reference — https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#apt-get
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    make \
    ca-certificates \
    xz-utils \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install pandoc — download with curl and verify SHA-256 before executing.
# Using a simplified filename avoids embedding the version string in the sha256sum check.
RUN curl -fsSL -o pandoc.deb \
      "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" \
    && echo "${PANDOC_SHA}  pandoc.deb" | sha256sum -c - \
    && dpkg -i pandoc.deb \
    && rm pandoc.deb

# Install pandoc-crossref (must be version-matched to pandoc) — verify SHA-256 before extracting.
RUN curl -fsSL -o pandoc-crossref.tar.xz \
      "https://github.com/lierdakil/pandoc-crossref/releases/download/v${CROSSREF_VERSION}/pandoc-crossref-Linux.tar.xz" \
    && echo "${CROSSREF_SHA}  pandoc-crossref.tar.xz" | sha256sum -c - \
    && tar -xf pandoc-crossref.tar.xz \
    && mv pandoc-crossref /usr/local/bin/ \
    && rm pandoc-crossref.tar.xz

# Install XeLaTeX (large layer — placed after pandoc which changes less often than Node/npm).
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-latex-extra \
    lmodern \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22 via the official NodeSource repository.
# Uses explicit GPG key fetch + apt source configuration instead of the 'curl | bash' pattern.
# 'curl | bash' executes arbitrary code from a remote server; this approach only executes
# trusted system tools (gpg, apt-get) after fetching the key.
# Reference — https://github.com/nodesource/distributions?tab=readme-ov-file#installation-instructions-deb
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome for @mermaid-js/mermaid-cli (mmdc).
# Google Chrome (not Ubuntu's chromium-browser) is used for reliable Puppeteer compatibility;
# the Puppeteer team tests against Chrome and maintains the executable path contract.
# Reference — https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker
# Reference — https://github.com/mermaid-js/mermaid-cli/blob/master/docs/already-installed-chromium.md
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# PUPPETEER_SKIP_CHROMIUM_DOWNLOAD: prevents Puppeteer from downloading a bundled Chromium
# (several hundred MB) since we provide an explicit Chrome binary above.
# PUPPETEER_EXECUTABLE_PATH: points mmdc's Puppeteer instance at the installed Chrome binary.
# Reference — https://pptr.dev/guides/configuration#environment-variables
# Reference — https://github.com/mermaid-js/mermaid-cli/blob/master/docs/already-installed-chromium.md
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Install Node.js tools from package.json using --prefix /usr/local.
# --prefix /usr/local installs packages into /usr/local/lib/node_modules/ and creates
# bin symlinks in /usr/local/bin/ — equivalent to 'npm install -g' but in a project
# context so that package.json's 'overrides' field is honoured.
# 'overrides' forces picomatch to 4.0.4, patching CVE-2026-33671 (ReDoS) in the
# transitive picomatch@4.0.3 dependency pulled in by puppeteer.
# --no-fund: suppresses funding messages in build logs (addressed by Dependabot PRs, not here).
# --no-audit: suppresses audit output in build logs (same rationale).
# @mermaid-js/mermaid-cli replaces the unmaintained mermaid-filter; diagram rendering is now
# handled by filters/diagram.lua (pandoc-ext/diagram Lua filter) which invokes mmdc via
# the MERMAID_BIN environment variable.
# Reference — npm overrides: https://docs.npmjs.com/cli/v10/configuring-npm/package-json#overrides
# Reference — https://github.com/mermaid-js/mermaid-cli
# Reference — https://github.com/pandoc-ext/diagram
# Install Node.js tools from package.json with npm overrides applied.
# 'npm install -g pkg@version' has no package.json project context, so 'overrides' is
# not honoured. Instead: install locally (which reads package.json and applies overrides),
# copy the resulting node_modules to the global location, and create /usr/local/bin/
# symlinks manually — equivalent to 'npm install -g' with overrides.
#
# npm local install: packages → <cwd>/node_modules/
#                   bin symlinks → <cwd>/node_modules/.bin/  (relative to .bin/)
# npm global install: packages → <prefix>/lib/node_modules/
#                   bin symlinks → <prefix>/bin/
#
# Copying node_modules to /usr/local/lib/node_modules/ preserves the relative symlinks
# in .bin/ — they resolve correctly from the new location. /usr/local/bin/ symlinks
# point at the absolute /usr/local/lib/node_modules/.bin/<bin> paths.
#
# --include=dev: install devDependencies regardless of NODE_ENV.
# --no-fund / --no-audit: suppress non-actionable build log noise (handled via Dependabot).
# overrides in package.json force picomatch to 4.0.4, patching CVE-2026-33671 in the
# picomatch@4.0.3 transitive dependency pulled in by puppeteer.
#
# package.json also pins npm@11.x as a devDependency. NodeSource bundles npm@10.x with
# Node.js 22; npm@10.x transitively includes picomatch@4.0.3 in its own internal tree.
# npm@11.x's dependency chain (glob@13.x → minimatch@10.x → brace-expansion) no longer
# includes picomatch. Installing npm@11.x via the local install step (rather than
# 'npm install -g npm@11.x') avoids a MODULE_NOT_FOUND error in npm@10.x's arborist
# when it tries to upgrade itself globally. After copying, the old npm directory is
# removed and /usr/bin/npm and /usr/bin/npx are redirected to the new installation.
#
# Reference — npm overrides: https://docs.npmjs.com/cli/v10/configuring-npm/package-json#overrides
# Reference — npm install: https://docs.npmjs.com/cli/v10/commands/npm-install
# Reference — npm changelog: https://github.com/npm/cli/releases
COPY package.json /tmp/npm-install/package.json
RUN cd /tmp/npm-install \
    && npm install --no-fund --no-audit --include=dev \
    && cp -rP node_modules/. /usr/local/lib/node_modules/ \
    && for bin_link in node_modules/.bin/*; do \
         bin_name=$(basename "$bin_link"); \
         ln -sf "/usr/local/lib/node_modules/.bin/${bin_name}" "/usr/local/bin/${bin_name}"; \
       done \
    && rm -rf /tmp/npm-install \
    && rm -rf /usr/lib/node_modules/npm \
    && ln -sf /usr/local/bin/npm /usr/bin/npm \
    && ln -sf /usr/local/bin/npx /usr/bin/npx

# Install Python tools via a virtual environment (PEP 668 compliance).
# COPY requirements-dev.txt so the version pin is read from the Dependabot-tracked source
# of truth rather than a hardcoded string in this file.
# --constraint uses requirements-dev.txt as a version constraint file, not an install list:
# only the explicitly named package (codespell) is installed. pre-commit is also listed in
# requirements-dev.txt but is a developer workflow tool with no place in the build image;
# --constraint installs it if named, ignores it otherwise.
# Ubuntu 24.04 marks the system Python as 'externally managed'; --break-system-packages
# bypasses this guard and can corrupt the OS Python environment. The correct approach
# per PEP 668 is an isolated virtual environment, with the binary symlinked for global access.
# --no-cache-dir: prevents pip from storing the package cache in the image layer.
# Reference — PEP 668: https://peps.python.org/pep-0668/
# Reference — pip constraints files: https://pip.pypa.io/en/stable/user_guide/#constraints-files
COPY requirements-dev.txt /tmp/requirements-dev.txt
RUN apt-get update && apt-get install -y --no-install-recommends python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /opt/codespell \
    && /opt/codespell/bin/pip install --no-cache-dir --constraint /tmp/requirements-dev.txt codespell \
    && ln -s /opt/codespell/bin/codespell /usr/local/bin/codespell

# Chrome refuses to run as root without --no-sandbox. Wrap the binary so the flag is always
# present regardless of how Puppeteer invokes it. In CI (non-root), the mmdc-pandoc wrapper
# and puppeteer config file handle this instead; this wrapper is the Docker-specific solution.
# Reference — https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker
RUN mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable-real \
    && printf '#!/bin/sh\nexec /usr/bin/google-chrome-stable-real --no-sandbox --disable-setuid-sandbox "$@"\n' \
       > /usr/bin/google-chrome-stable \
    && chmod +x /usr/bin/google-chrome-stable

# Puppeteer configuration for mmdc — points at the Chrome wrapper above.
# executablePath: the Chrome wrapper script that injects --no-sandbox (required for root).
# Reference — https://pptr.dev/guides/configuration
RUN printf '{"executablePath":"/usr/bin/google-chrome-stable"}\n' \
    > /etc/mmdc-puppeteer.json

# mmdc-pandoc: wrapper script consumed by filters/diagram.lua via MERMAID_BIN.
# pandoc-ext/diagram calls the binary at $MERMAID_BIN with --pdfFit --input --output args.
# This wrapper injects --puppeteerConfigFile (for the Chrome binary + no-sandbox config)
# and --theme (for diagram theming) before forwarding all other arguments to mmdc.
# MERMAID_THEME defaults to "default" if unset; override with: make build MERMAID_THEME=dark
# Reference — https://github.com/pandoc-ext/diagram
# Reference — https://github.com/mermaid-js/mermaid-cli
RUN printf '#!/bin/sh\nexec mmdc --puppeteerConfigFile /etc/mmdc-puppeteer.json --theme "${MERMAID_THEME:-default}" "$@"\n' \
    > /usr/local/bin/mmdc-pandoc \
    && chmod +x /usr/local/bin/mmdc-pandoc

# MERMAID_BIN: tells filters/diagram.lua which binary to call for Mermaid rendering.
# The Lua filter reads MERMAID_BIN via os.getenv('MERMAID_BIN') (the diagram engine resolves
# execpath from <ENGINE_NAME>_BIN, i.e. MERMAID_BIN).
# Reference — https://github.com/pandoc-ext/diagram (get_engine function)
ENV MERMAID_BIN=/usr/local/bin/mmdc-pandoc

# Explicit absolute WORKDIR (never rely on implicit working directory or RUN cd).
# /workspace matches the GitHub Actions runner workspace convention for environment consistency.
# Reference — https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#workdir
WORKDIR /workspace

# CMD in exec form (JSON array, not shell form string).
# Exec form makes 'make' PID 1, ensuring SIGTERM/SIGINT are received directly.
# Shell form would make /bin/sh PID 1, which does not forward signals to child processes.
# Reference — https://docs.docker.com/engine/reference/builder/#cmd
CMD ["make", "all"]
