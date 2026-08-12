# Apply local-server error-status fix (return HttpError statuses such as 401
# instead of always-500) until the fork ships it.
COPY patches/apply-error-status.js /tmp/apply-error-status.js
RUN node /tmp/apply-error-status.js && rm /tmp/apply-error-status.js
