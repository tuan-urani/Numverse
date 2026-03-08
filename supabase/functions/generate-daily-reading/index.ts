import { serveHandler } from "../_shared/runtime.ts";
import { handleGenerateDailyReading } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleGenerateDailyReading));
