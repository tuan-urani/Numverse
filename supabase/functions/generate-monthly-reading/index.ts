import { serveHandler } from "../_shared/runtime.ts";
import { handleGenerateMonthlyReading } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleGenerateMonthlyReading));
