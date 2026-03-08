import { serveHandler } from "../_shared/runtime.ts";
import { handleGenerateYearlyReading } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleGenerateYearlyReading));
