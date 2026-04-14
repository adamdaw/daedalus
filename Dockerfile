FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG PANDOC_VERSION=3.1.13
ARG CROSSREF_VERSION=0.3.17.1

# Install base utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    make \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install pandoc
RUN wget -q "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" \
    && dpkg -i "pandoc-${PANDOC_VERSION}-1-amd64.deb" \
    && rm "pandoc-${PANDOC_VERSION}-1-amd64.deb"

# Install pandoc-crossref (must match pandoc version)
RUN wget -q "https://github.com/lierdakil/pandoc-crossref/releases/download/v${CROSSREF_VERSION}/pandoc-crossref-Linux.tar.xz" \
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
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome for mermaid-filter
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" \
        >> /etc/apt/sources.list.d/google.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Install Node.js tools
RUN npm install -g mermaid-filter markdownlint-cli

# Install Python tools
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install codespell

# Chrome refuses to run as root without --no-sandbox. Wrap the binary so the
# flag is always present regardless of how puppeteer invokes it.
RUN mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-stable-real \
    && printf '#!/bin/sh\nexec /usr/bin/google-chrome-stable-real --no-sandbox --disable-setuid-sandbox "$@"\n' \
       > /usr/bin/google-chrome-stable \
    && chmod +x /usr/bin/google-chrome-stable

WORKDIR /workspace

CMD ["make", "build"]
