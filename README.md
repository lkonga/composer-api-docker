# composer-api-docker

Docker packaging of **standardagents/composer-api** ("API for Cursor") for Dokploy/g5kc:
OpenAI-compatible `/v1` server backed by Cursor Composer models via `@cursor/sdk`.

## Why this repo

Upstream (301 stars, actively maintained, MIT) ships a macOS app plus cross-platform
Node scripts. This image builds the **ElCabrii/composer-api-local** fork
(upstream + a `local/` Node wrapper that serves `/v1/chat/completions`,
`/v1/responses`, `/v1/models` on Linux/Windows/WSL), pinned at commit
`fbe06a0a6328`, and runs it in Node 22.

Runtime facts:
- No Cursor IDE required; only a Cursor user API key (`crsr_...`)
  from https://cursor.com/dashboard/api.
- Usage bills to your Cursor plan request pool (usage dashboard "SDK" tag).
- It is an agent API, not raw inference: no temperature/top_p; Responses API
  rejects `tools` (use chat completions for client tool loops).

## Deploy status (g5kc / Dokploy)

- Dokploy project `composer-api` (env `production`), compose service `composer-api`
  (custom git + SSH key deploy from this repo, branch `main`).
- Container `composer-api`, image `g5kc/composer-api:latest`, maps
  **loopback `127.0.0.1:8788`** (8787 is taken by portkey-gateway on g5kc).
- Tailnet: `tailscale serve --bg --https=8788 http://127.0.0.1:8788` →
  `https://g5kc.tail1e9037.ts.net:8788/v1` (tailnet only).
- Env in Dokploy: `CURSOR_API_KEY=` (paste the key), `CURSOR_API_PORT=8788`.

## Deploy (from scratch)

1. Dokploy → new Project (e.g. `composer-api`).
2. Compose app from this repo (`lkonga/composer-api-docker`, branch `main`, path `docker-compose.yml`)
   — use a read-only SSH deploy key: add pubkey to GitHub repo, register in
   Dokploy, set compose `sourceType=git`, `customGitUrl=git@github.com:lkonga/composer-api-docker.git`,
   `customGitSSHKeyId=<id>`. (`sourceType=github` requires the Dokploy Github Provider OAuth.)
3. Env: set `CURSOR_API_KEY=crsr_...` and `CURSOR_API_PORT=8788`.
4. After deploy: `tailscale serve --bg --https=8788 http://127.0.0.1:8788`.

## Verify (after pasting the key + redeploy)

```bash
CURSOR_API_KEY=crsr_... ./smoke-test.sh
# or against the loopback endpoint:
BASE_URL=http://127.0.0.1:8788 CURSOR_API_KEY=crsr_... ./smoke-test.sh
```

Exits 0 only when `/health` passes AND a real `/v1/chat/completions` round-trip
returns. Fails with a clear message if the key is missing or the API errors.

## Usage

```bash
curl https://g5kc.tail1e9037.ts.net:8788/v1/models \
  -H "Authorization: Bearer crsr_..."

curl https://g5kc.tail1e9037.ts.net:8788/v1/chat/completions \
  -H "Authorization: Bearer crsr_..." -H "Content-Type: application/json" \
  -d '{"model":"composer-2.5","messages":[{"role":"user","content":"Hello"}]}'
```

OpenCode/Codex: point at the `/v1` base URL with any bearer token when
`CURSOR_API_KEY` is set server-side.

## Caveats

- Cursor ToS/commercial-use question is open upstream (standardagents/composer-api #15);
  keep the endpoint tailnet-only.
- reasoning.effort forwarding has an open upstream gap (#28).
