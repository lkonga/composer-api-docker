// Applies the local-server error-status fix to local/local-server.ts.
// Idempotent: asserts anchor text exists, then swaps the always-500 catch for
// errorResponse() so HttpError statuses (401, 404, ...) are preserved.
import { readFileSync, writeFileSync } from "node:fs";

const file = "local/local-server.ts";
const src = readFileSync(file, "utf8");

if (!src.includes('import { errorResponse } from "../worker/http";')) {
  const importAnchor = 'import type { Deps, Env } from "../worker/types";';
  if (!src.includes(importAnchor)) throw new Error("import anchor not found");
  const out = src.replace(
    importAnchor,
    `${importAnchor}\nimport { errorResponse } from "../worker/http";`,
  );
  writeFileSync(file, out);
}

const bad =
  'const message = error instanceof Error ? error.message : "Unexpected local server error";\n' +
  '      await sendResponse(response, Response.json({\n' +
  "        error: {\n" +
  "          message,\n" +
  '          type: "local_server_error",\n' +
  '          code: "local_server_error"\n' +
  "        }\n" +
  "      }, { status: 500 }));";

if (src.includes(bad)) {
  const fixed = readFileSync(file, "utf8").replace(
    bad,
    "await sendResponse(response, errorResponse(error));",
  );
  writeFileSync(file, fixed);
}

const check = readFileSync(file, "utf8");
if (!check.includes('import { errorResponse } from "../worker/http";')) {
  throw new Error("fix not applied: import missing");
}
if (!check.includes("await sendResponse(response, errorResponse(error));")) {
  throw new Error("fix not applied: catch body missing");
}
console.log("error-status fix applied");
