FROM node:22-bookworm-slim

# System deps + Chromium (single copy, shared with Playwright)
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gosu \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    zip \
    chromium \
    fonts-liberation \
  && rm -rf /var/lib/apt/lists/*

# crawl4ai + playwright Python packages only (skip browser download — use system Chromium)
RUN python3 -m venv /opt/crawl4ai-venv \
  && /opt/crawl4ai-venv/bin/pip install --no-cache-dir crawl4ai playwright

ENV PATH="/opt/crawl4ai-venv/bin:${PATH}"
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH="/usr/bin/chromium"

RUN npm install -g openclaw@2026.2.26

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile --prod

# Remove build-essential after native modules are compiled
RUN apt-get purge -y --auto-remove build-essential \
  && rm -rf /var/lib/apt/lists/*

COPY src ./src
COPY entrypoint.sh ./entrypoint.sh

RUN useradd -m -s /bin/bash openclaw \
  && chown -R openclaw:openclaw /app \
  && mkdir -p /data && chown openclaw:openclaw /data \
  && mkdir -p /home/linuxbrew/.linuxbrew && chown -R openclaw:openclaw /home/linuxbrew

USER openclaw
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

ENV PORT=8080
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/setup/healthz || exit 1

USER root
ENTRYPOINT ["./entrypoint.sh"]
