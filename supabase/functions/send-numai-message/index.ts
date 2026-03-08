import { serveHandler } from "../_shared/runtime.ts";
import { handleSendNumaiMessage } from "../_shared/flows.ts";

Deno.serve(serveHandler(handleSendNumaiMessage));
