# API for Cursor (composer-api) - Linux container
#
# Builds standardagents/composer-api via the ElCabrii/composer-api-local fork
# (upstream + local/ Node wrapper that serves /v1 chat completions, responses
# and models backed by @cursor/sdk). Pinned to fork commit fbe06a0a6328.
#
# Runtime: pure Node 22 (SDK requires >= 22.13). No Cursor IDE needed.
FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone pinned fork = upstream standardagents/composer-api + local/ wrapper
ARG COMPOSER_API_REF=fbe06a0a6328
RUN git clone --depth 1 https://github.com/ElCabrii/composer-api-local.git . \
 && git fetch --depth 1 origin "${COMPOSER_API_REF}" \
 && git checkout "${COMPOSER_API_REF}"

RUN npm install --no-audit --no-fund

ENV CURSOR_API_HOST=0.0.0.0 \
    CURSOR_API_PORT=8787 \
    CURSOR_SDK_BRIDGE_HOST=127.0.0.1 \
    CURSOR_SDK_BRIDGE_PORT=8792 \
    CURSOR_SDK_BRIDGE_TIMEOUT_MS=180000

EXPOSE 8787

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
 CMD node -e "fetch('http://127.0.0.1:8787/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["npm", "run", "local:server"]
