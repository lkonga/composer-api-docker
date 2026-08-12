# Apply local-server error-status fix (return HttpError statuses such as 401
# instead of always-500) until the fork ships it.
COPY patches/apply-error-status.js /tmp/apply-error-status.js
RUN node /tmp/apply-error-status.js && rm /tmp/apply-error-status.js

RUN npm install --no-audit --no-fund

ENV CURSOR_API_HOST=0.0.0.0 \
    CURSOR_API_PORT=8788 \
    CURSOR_SDK_BRIDGE_HOST=127.0.0.1 \
    CURSOR_SDK_BRIDGE_PORT=8792 \
    CURSOR_SDK_BRIDGE_TIMEOUT_MS=180000

EXPOSE 8788

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
 CMD node -e "fetch('http://127.0.0.1:8788/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["npm", "run", "local:server"]
