#!/usr/bin/env bash
# Smoke test for composer-api (api-for-cursor-local) on g5kc.
#
# Usage:
#   CURSOR_API_KEY=sk-... ./smoke-test.sh                # tailnet URL, port 8788
#   BASE_URL=http://127.0.0.1:8788 ./smoke-test.sh       # override base URL
#
# Exits 0 only when health passes AND a real chat completion returns.
set -euo pipefail

BASE_URL="${BASE_URL:-https://g5kc.tail1e9037.ts.net:8788}"
KEY="${CURSOR_API_KEY:-}"

if [[ -z "$KEY" ]]; then
  echo "FAIL: CURSOR_API_KEY is empty. Paste it in Dokploy env and redeploy first." >&2
  exit 2
fi

health=$(curl -sf -m 10 "$BASE_URL/health") || { echo "FAIL: health unreachable at $BASE_URL/health" >&2; exit 1; }
echo "PASS health: $(echo "$health" | head -c 120)"

resp=$(curl -sf -m 60 -X POST "$BASE_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $KEY" \
  -d '{"model":"composer","messages":[{"role":"user","content":"Reply with exactly: ok"}],"max_tokens":10}')

if echo "$resp" | grep -qi '"error"'; then
  echo "FAIL: API returned an error payload:" >&2
  echo "$resp" | head -c 400 >&2
  exit 1
fi

if echo "$resp" | grep -q '"choices"'; then
  echo "PASS chat: $(echo "$resp" | head -c 200)"
  echo "SMOKE TEST PASSED"
else
  echo "FAIL: unexpected response:" >&2
  echo "$resp" | head -c 400 >&2
  exit 1
fi
