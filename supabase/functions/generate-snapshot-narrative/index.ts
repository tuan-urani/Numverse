import { serveHandler } from "../_shared/runtime.ts";
import { handleGenerateSnapshotNarrative } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleGenerateSnapshotNarrative));
