FROM pandoc/extra:3.1

# Install Node.js, npm, and Chromium for mermaid-filter
RUN apk add --no-cache \
    nodejs \
    npm \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    make

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

RUN npm install -g mermaid-filter

WORKDIR /workspace

CMD ["make", "build"]
