import { serveHandler, HttpError } from "../_shared/runtime.ts";
import {
  handleGenerateActivePhaseReading,
  handleGenerateCompatibilityReport,
  handleGenerateDailyReading,
  handleGenerateMonthlyReading,
  handleGenerateSnapshotNarrative,
  handleGenerateYearlyReading,
  handleRecalculateNumerologyProfile,
  handleSendNumaiMessage,
} from "../_shared/flows.ts";

const handlerMap = {
  "recalculate-numerology-profile": handleRecalculateNumerologyProfile,
  "generate-snapshot-narrative": handleGenerateSnapshotNarrative,
  "generate-daily-reading": handleGenerateDailyReading,
  "generate-monthly-reading": handleGenerateMonthlyReading,
  "generate-yearly-reading": handleGenerateYearlyReading,
  "generate-active-phase-reading": handleGenerateActivePhaseReading,
  "generate-compatibility-report": handleGenerateCompatibilityReport,
  "send-numai-message": handleSendNumaiMessage,
} as const;

async function routeRequest(req: Request): Promise<unknown> {
  const url = new URL(req.url);
  const action = url.searchParams.get("action") ??
    req.headers.get("x-numverse-action");

  if (!action) {
    throw new HttpError(400, "missing_action", {
      allowed_actions: Object.keys(handlerMap),
    });
  }

  const handler = handlerMap[action as keyof typeof handlerMap];
  if (!handler) {
    throw new HttpError(404, "unknown_action", {
      action,
      allowed_actions: Object.keys(handlerMap),
    });
  }

  return handler(req);
}

Deno.serve(serveHandler(routeRequest));
