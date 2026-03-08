import { serveHandler } from "../_shared/runtime.ts";
import { handleRecalculateNumerologyProfile } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleRecalculateNumerologyProfile));
