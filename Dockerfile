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

# Install Google Chrome for mermaid-filter.
# Google Chrome (not Ubuntu's chromium-browser) is used for reliable Puppeteer compatibility;
# the Puppeteer team tests against Chrome and maintains the executable path contract.
# Reference — https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker
RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# PUPPETEER_SKIP_CHROMIUM_DOWNLOAD: prevents Puppeteer from downloading a bundled Chromium
# (several hundred MB) since we provide an explicit Chrome binary above.
# Reference — https://pptr.dev/guides/configuration#environment-variables
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Install Node.js tools.
# --no-fund: suppresses funding messages in build logs (addressed by Dependabot PRs, not here).
# --no-audit: suppresses audit output in build logs (same rationale).
# Versions pinned to match package.json, .pre-commit-config.yaml, and CI workflows.
RUN npm install -g --no-fund --no-audit mermaid-filter@1.4.7 markdownlint-cli@0.44.0

# Install Python tools via a virtual environment (PEP 668 compliance).
# Ubuntu 24.04 marks the system Python as 'externally managed'; --break-system-packages
# bypasses this guard and can corrupt the OS Python environment. The correct approach
# per PEP 668 is an isolated virtual environment, with the binary symlinked for global access.
# --no-cache-dir: prevents pip from storing the package cache in the image layer.
# Reference — https://peps.python.org/pep-0668/
RUN apt-get update && apt-get install -y --no-install-recommends python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /opt/codespell \
    && /opt/codespell/bin/pip install --no-cache-dir codespell==2.3.0 \
    && ln -s /opt/codespell/bin/codespell /usr/local/bin/codespell

# Chrome refuses to run as root without --no-sandbox. Wrap the binary so the flag is always
# present regardless of how Puppeteer invokes it. In CI (non-root), MERMAID_FILTER_PUPPETEER_CONFIG
# handles this instead; this wrapper is the Docker-specific solution.
# Reference — https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker
RUN mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable-real \
    && printf '#!/bin/sh\nexec /usr/bin/google-chrome-stable-real --no-sandbox --disable-setuid-sandbox "$@"\n' \
       > /usr/bin/google-chrome-stable \
    && chmod +x /usr/bin/google-chrome-stable

# Explicit absolute WORKDIR (never rely on implicit working directory or RUN cd).
# /workspace matches the GitHub Actions runner workspace convention for environment consistency.
# Reference — https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#workdir
WORKDIR /workspace

# CMD in exec form (JSON array, not shell form string).
# Exec form makes 'make' PID 1, ensuring SIGTERM/SIGINT are received directly.
# Shell form would make /bin/sh PID 1, which does not forward signals to child processes.
# Reference — https://docs.docker.com/engine/reference/builder/#cmd
CMD ["make", "all"]
