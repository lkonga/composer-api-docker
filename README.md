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

## Deploy (Dokploy on g5kc)

1. Dokploy → new Project (e.g. `composer-api`).
2. Compose app from this repo (`lkonga/composer-api-docker`, branch `main`, path `docker-compose.yml`).
3. Env: set `CURSOR_API_KEY=crsr_...` (your key).
4. Port map stays loopback `127.0.0.1:8787`; expose over tailnet:
   ```
   tailscale serve --bg https:8787 http://127.0.0.1:8787
   ```
   Reachable at `https://g5kc.tail1e9037.ts.net:8787/v1`.
5. Health: `curl https://g5kc.tail1e9037.ts.net:8787/health`

## Usage

```bash
curl https://g5kc.tail1e9037.ts.net:8787/v1/models \
  -H "Authorization: Bearer crsr_..."

curl https://g5kc.tail1e9037.ts.net:8787/v1/chat/completions \
  -H "Authorization: Bearer crsr_..." -H "Content-Type: application/json" \
  -d '{"model":"composer-2.5","messages":[{"role":"user","content":"Hello"}]}'
```

OpenCode/Codex: point at the `/v1` base URL with any bearer token when
`CURSOR_API_KEY` is set server-side.

## Caveats

- Cursor ToS/commercial-use question is open upstream (standardagents/composer-api #15);
  keep the endpoint tailnet-only.
- reasoning.effort forwarding has an open upstream gap (#28).
