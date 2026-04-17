# Troubleshooting

Common issues and their fixes. If something here doesn't help, please
[open an issue](https://github.com/adamdaw/daedalus/issues).

---

## `Error: mmdc not found`

Install `@mermaid-js/mermaid-cli` and ensure the browser path and `MERMAID_BIN` are set:

```bash
npm install -g @mermaid-js/mermaid-cli@11.12.0
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=$(which chromium || which google-chrome)
export MERMAID_BIN=$(which mmdc)
```

---

## `Error: pandoc-crossref not found`

Download the binary matching your pandoc version and place it on `$PATH`:

```bash
curl -fsSL -o pandoc-crossref-Linux.tar.xz \
  https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.17.1/pandoc-crossref-Linux.tar.xz
tar -xf pandoc-crossref-Linux.tar.xz
sudo mv pandoc-crossref /usr/local/bin/
```

pandoc-crossref must be version-matched to pandoc. Run `make check` to verify both versions together.

---

## `Warning: expected pandoc 3.1.13, got X.Y.Z`

The build will still proceed, but cross-references or other features may behave differently.
Install the pinned version from [pandoc releases](https://github.com/jgm/pandoc/releases/tag/3.1.13)
or use Docker to get a guaranteed-correct environment.

---

## Mermaid diagrams render as blank boxes

`PUPPETEER_EXECUTABLE_PATH` must point to a real Chrome or Chromium binary, and `MERMAID_BIN`
must point to the `mmdc` binary (or a wrapper script). Confirm with:

```bash
echo $PUPPETEER_EXECUTABLE_PATH
$PUPPETEER_EXECUTABLE_PATH --version
echo $MERMAID_BIN
$MERMAID_BIN --version
```

If running as root (e.g., in Docker), Chrome requires `--no-sandbox`. The Dockerfile handles
this automatically via a Chrome wrapper script and a puppeteer config at `/etc/mmdc-puppeteer.json`.

For local root environments or Ubuntu 24.04+ (AppArmor sandbox restriction), create a puppeteer
config file and use a wrapper script as `MERMAID_BIN`:

```bash
echo '{"executablePath":"'$(which google-chrome)'","args":["--no-sandbox","--disable-setuid-sandbox"]}' \
  > /tmp/mmdc-puppeteer.json
printf '#!/bin/sh\nexec mmdc --puppeteerConfigFile /tmp/mmdc-puppeteer.json --theme "${MERMAID_THEME:-default}" "$@"\n' \
  > /tmp/mmdc-pandoc && chmod +x /tmp/mmdc-pandoc
export MERMAID_BIN=/tmp/mmdc-pandoc
```

---

## `xelatex not found`

Install the required TeX packages:

```bash
# Debian / Ubuntu
sudo apt-get install texlive-xetex texlive-fonts-recommended texlive-latex-extra lmodern

# macOS
brew install --cask mactex
```

Alternatively, use Docker — all dependencies are pre-installed:

```bash
make docker-run
```
