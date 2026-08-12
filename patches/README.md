# Patches

Patches applied on top of the pinned fork (`ElCabrii/composer-api-local` at
`fbe06a0a6328`) during the Docker build.

## `apply-error-status.js`

Fixes the local server's catch-all so it preserves `HttpError` status codes
instead of always returning HTTP 500 `local_server_error`. Without it, a bad
or missing API key surfaces as 500 (clients treat it as retryable) instead of
a clean typed `unauthorized` error.

The script is idempotent and assertion-based: it only rewrites exact anchor
text and throws if the anchors are missing, so the build fails loudly rather
than shipping a silently-unpatched server. Remove it (and the Dockerfile
`COPY`/`RUN` steps) once the fix lands upstream.

Note: with an invalid key the SDK bridge still reports HTTP 502 with a typed
`unauthorized` body (bridge run-failure mapping, `cursor-sdk-local-agent-bridge.mjs`
line ~2138). That only happens for genuinely bad keys; valid requests return 200.
