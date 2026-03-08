import { serveHandler } from "../_shared/runtime.ts";
import { handleGenerateCompatibilityReport } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleGenerateCompatibilityReport));
