import { serveHandler } from "../_shared/runtime.ts";
import { handleGenerateActivePhaseReading } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleGenerateActivePhaseReading));
