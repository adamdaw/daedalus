FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Version pins — keep in sync with Makefile and all CI workflows.
ARG PANDOC_VERSION=3.1.13
ARG CROSSREF_VERSION=0.3.17.1

# SHA-256 digests for supply-chain integrity.
# Re-compute when upgrading: sha256sum <downloaded-file>
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

# Install base utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    make \
    ca-certificates \
    xz-utils \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install pandoc — verify SHA-256 before installing
RUN wget -q "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" \
    && echo "${PANDOC_SHA}  pandoc-${PANDOC_VERSION}-1-amd64.deb" | sha256sum -c - \
    && dpkg -i "pandoc-${PANDOC_VERSION}-1-amd64.deb" \
    && rm "pandoc-${PANDOC_VERSION}-1-amd64.deb"

# Install pandoc-crossref (must match pandoc version) — verify SHA-256 before installing
RUN wget -q "https://github.com/lierdakil/pandoc-crossref/releases/download/v${CROSSREF_VERSION}/pandoc-crossref-Linux.tar.xz" \
    && echo "${CROSSREF_SHA}  pandoc-crossref-Linux.tar.xz" | sha256sum -c - \
    && tar -xf "pandoc-crossref-Linux.tar.xz" \
    && mv pandoc-crossref /usr/local/bin/ \
    && rm "pandoc-crossref-Linux.tar.xz"

# Install XeLaTeX
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-latex-extra \
    lmodern \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome for mermaid-filter
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Install Node.js tools (pin markdownlint-cli to match .pre-commit-config.yaml)
RUN npm install -g mermaid-filter@1.4.7 markdownlint-cli@0.44.0

# Install Python tools
# Ubuntu 24.04 enforces PEP 668; --break-system-packages is required for global installs.
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --break-system-packages codespell==2.3.0

# Chrome refuses to run as root without --no-sandbox. Wrap the binary so the
# flag is always present regardless of how puppeteer invokes it.
RUN mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable-real \
    && printf '#!/bin/sh\nexec /usr/bin/google-chrome-stable-real --no-sandbox --disable-setuid-sandbox "$@"\n' \
       > /usr/bin/google-chrome-stable \
    && chmod +x /usr/bin/google-chrome-stable

WORKDIR /workspace

CMD ["make", "all"]
