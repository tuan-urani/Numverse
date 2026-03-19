import { createClient } from "npm:@supabase/supabase-js@2";

type SupabaseClient = ReturnType<typeof createClient>;
type JsonObject = Record<string, unknown>;

interface PromptTemplateRow {
  id: string;
  prompt_key: string;
  version: string;
  locale: string;
  status: string;
  provider: string;
  model_name: string;
  temperature: number | null;
  max_output_tokens: number | null;
  system_prompt: string;
  task_prompt_template: string;
}

class HttpError extends Error {
  status: number;
  details?: unknown;

  constructor(status: number, message: string, details?: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

const ENGINE_VERSION = Deno.env.get("NUMEROLOGY_ENGINE_VERSION") ?? "v1";
const DEFAULT_LOCALE = "vi-VN";
const DEFAULT_TIMEZONE = "Asia/Ho_Chi_Minh";
const NUMAI_SOUL_POINT_COST = 3;
const NUMAI_RECENT_MESSAGES_LIMIT = 4;
const NUMAI_TECHNICAL_FALLBACK_MESSAGE =
  "Oops, hệ thống đang gặp trục trặc nhỏ khi xử lý dữ liệu. Bạn thử lại ngay nhé.";
const NUMAI_OUT_OF_SCOPE_FALLBACK_MESSAGE =
  "Mình chỉ hỗ trợ về thần số học.\nBạn có thể hỏi về con số, năm cá nhân hoặc ý nghĩa cuộc đời.";
const NUMAI_TECHNICAL_ERROR_CODES = new Set<string>([
  "gemini_provider_error",
  "gemini_empty_output",
  "invalid_json_output",
  "invalid_numai_output",
  "numai_empty_answer",
  "missing_env_gemini_api_key",
]);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function nowIso(): string {
  return new Date().toISOString();
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function errorResponse(error: unknown): Response {
  if (error instanceof HttpError) {
    return jsonResponse(
      { ok: false, error: error.message, details: error.details ?? null },
      error.status,
    );
  }

  const message = error instanceof Error ? error.message : "internal_error";
  return jsonResponse({ ok: false, error: message }, 500);
}

function getEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new HttpError(500, `missing_env_${name.toLowerCase()}`);
  }
  return value;
}

function ensureObject(
  value: unknown,
  message = "invalid_object_payload",
): JsonObject {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpError(500, message);
  }
  return value as JsonObject;
}

function asObject(value: unknown): JsonObject | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as JsonObject;
}

function ensureArrayOfStrings(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((item) => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function stripCodeFences(text: string): string {
  const trimmed = text.trim();
  if (!trimmed.startsWith("```")) {
    return trimmed;
  }

  return trimmed
    .replace(/^```[a-zA-Z]*\s*/, "")
    .replace(/\s*```$/, "")
    .trim();
}

function isTruthyFlag(value: unknown): boolean {
  if (value === true) {
    return true;
  }

  if (typeof value === "string") {
    return value.trim().toLowerCase() === "true";
  }

  if (typeof value === "number") {
    return value === 1;
  }

  return false;
}

function resolveErrorCode(error: unknown): string {
  if (error instanceof HttpError) {
    return error.message.trim();
  }
  if (error instanceof Error) {
    return error.message.trim();
  }
  return "unknown_error";
}

function isNumAiTechnicalError(error: unknown): boolean {
  const code = resolveErrorCode(error);
  if (NUMAI_TECHNICAL_ERROR_CODES.has(code)) {
    return true;
  }

  if (error instanceof HttpError) {
    return false;
  }

  return error instanceof Error;
}

function buildThreadSummary(
  existingSummary: string,
  userQuestion: string,
  answer: string,
): string {
  const pieces = [
    existingSummary.trim(),
    `Nguoi dung hoi: ${userQuestion.trim()}`,
    `AI tra loi: ${answer.trim()}`,
  ].filter((item) => item.length > 0);
  const summary = pieces.join(" | ");
  if (summary.length <= 800) {
    return summary;
  }
  return summary.slice(summary.length - 800);
}

function fallbackFollowUpSuggestions(locale: string): string[] {
  const isVietnamese = locale.toLowerCase().startsWith("vi");
  if (isVietnamese) {
    return [
      "Tóm tắt ngắn gọn điểm mạnh cốt lõi của mình.",
      "Hôm nay mình nên tập trung vào điều gì đầu tiên?",
      "Tuần này mình nên tránh sai lầm nào?",
    ];
  }

  return [
    "Can you summarize my core strengths?",
    "What should I prioritize first today?",
    "Which pitfall should I avoid this week?",
  ];
}

function resolveFollowUpSuggestions(output: JsonObject, locale: string): string[] {
  const suggestions: string[] = [];
  const candidates = [
    ...ensureArrayOfStrings(output.suggestions),
    ...ensureArrayOfStrings(output.follow_up_suggestions),
  ];

  for (const candidate of candidates) {
    if (suggestions.includes(candidate)) {
      continue;
    }
    suggestions.push(candidate);
    if (suggestions.length === 3) {
      return suggestions;
    }
  }

  for (const fallback of fallbackFollowUpSuggestions(locale)) {
    if (suggestions.includes(fallback)) {
      continue;
    }
    suggestions.push(fallback);
    if (suggestions.length === 3) {
      break;
    }
  }

  return suggestions.slice(0, 3);
}

type ImportableGuestMessage = {
  localId: string;
  senderType: "user" | "assistant" | "system";
  messageText: string;
  createdAt: string;
  followUpSuggestions: string[];
};

type ClientNumAiSnapshot = {
  primaryProfileId: string;
  engineVersion: string;
  calculatedAt: string;
  rawInputJson: JsonObject;
  coreNumbersJson: JsonObject;
  birthMatrixJson: JsonObject;
  matrixAspectsJson: JsonObject;
  lifeCyclesJson: JsonObject;
  sourceHash?: string;
};

type NumAiFallbackReason = "technical_error" | "out_of_scope";

function sanitizeClientNumAiSnapshots(rawSnapshots: unknown): ClientNumAiSnapshot[] {
  if (!Array.isArray(rawSnapshots)) {
    return [];
  }

  const sanitized: ClientNumAiSnapshot[] = [];
  for (const raw of rawSnapshots) {
    const payload = asObject(raw);
    if (!payload) {
      continue;
    }

    const primaryProfileId = String(payload.primary_profile_id ?? "").trim();
    if (!primaryProfileId) {
      continue;
    }

    const rawInputJson = asObject(payload.raw_input);
    const coreNumbersJson = asObject(payload.core_numbers);
    const birthMatrixJson = asObject(payload.birth_matrix);
    const matrixAspectsJson = asObject(payload.matrix_aspects);
    const lifeCyclesJson = asObject(payload.life_cycles);
    if (
      !rawInputJson ||
      !coreNumbersJson ||
      !birthMatrixJson ||
      !matrixAspectsJson ||
      !lifeCyclesJson
    ) {
      continue;
    }

    const calculatedAtRaw = String(payload.calculated_at ?? "").trim();
    const calculatedAtMs = Date.parse(calculatedAtRaw);
    const calculatedAt = Number.isNaN(calculatedAtMs)
      ? nowIso()
      : new Date(calculatedAtMs).toISOString();

    const sourceHash = String(payload.source_hash ?? "").trim();

    sanitized.push({
      primaryProfileId,
      engineVersion: String(payload.engine_version ?? "mobile_local_v1").trim() || "mobile_local_v1",
      calculatedAt,
      rawInputJson,
      coreNumbersJson,
      birthMatrixJson,
      matrixAspectsJson,
      lifeCyclesJson,
      sourceHash: sourceHash || undefined,
    });
  }

  return sanitized;
}

function sanitizeGuestMessagesForImport(rawMessages: unknown): ImportableGuestMessage[] {
  if (!Array.isArray(rawMessages)) {
    return [];
  }

  const sanitized: ImportableGuestMessage[] = [];
  const fallbackStartedAt = Date.now();

  for (let index = 0; index < rawMessages.length; index += 1) {
    const raw = rawMessages[index];
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
      continue;
    }

    const payload = raw as JsonObject;
    const messageText = String(payload.message_text ?? "").trim();
    if (!messageText) {
      continue;
    }

    const senderCandidate = String(payload.sender_type ?? "user").trim().toLowerCase();
    const senderType: "user" | "assistant" | "system" =
      senderCandidate === "assistant" || senderCandidate === "system"
        ? senderCandidate
        : "user";

    const createdAtEpochRaw = payload.created_at_epoch_ms;
    const createdAtEpochMillis = typeof createdAtEpochRaw === "number" ||
        typeof createdAtEpochRaw === "string"
      ? Number(createdAtEpochRaw)
      : Number.NaN;
    const hasCreatedAtEpoch = Number.isFinite(createdAtEpochMillis) &&
      createdAtEpochMillis > 0;

    const createdAtCandidate = String(payload.created_at ?? "").trim();
    const createdAtMillis = hasCreatedAtEpoch
      ? createdAtEpochMillis
      : Date.parse(createdAtCandidate);
    const createdAt = Number.isNaN(createdAtMillis)
      ? new Date(fallbackStartedAt + index).toISOString()
      : new Date(createdAtMillis).toISOString();

    const localIdCandidate = String(payload.local_id ?? payload.id ?? "").trim();
    const localId = localIdCandidate || `guest-local-${createdAt}-${index}`;

    sanitized.push({
      localId,
      senderType,
      messageText,
      createdAt,
      followUpSuggestions: ensureArrayOfStrings(payload.follow_up_suggestions),
    });
  }

  sanitized.sort((left, right) => left.createdAt.localeCompare(right.createdAt));
  return sanitized;
}

function createClients(req: Request): {
  admin: SupabaseClient;
  userClient: SupabaseClient;
} {
  const supabaseUrl = getEnv("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SB_PUBLISHABLE_KEY");
  const serviceRoleKey = getEnv("SUPABASE_SERVICE_ROLE_KEY");

  if (!anonKey) {
    throw new HttpError(500, "missing_env_supabase_anon_key");
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: req.headers.get("Authorization") ?? "",
      },
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  return { admin, userClient };
}

function getBearerToken(req: Request): string {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new HttpError(401, "missing_authorization_header");
  }

  const [scheme, token] = authHeader.split(" ");
  if (scheme !== "Bearer" || !token) {
    throw new HttpError(401, "invalid_authorization_header");
  }

  return token;
}

async function requireUser(
  req: Request,
  userClient: SupabaseClient,
): Promise<{ id: string; email?: string | null }> {
  const token = getBearerToken(req);
  const { data, error } = await userClient.auth.getUser(token);

  if (error || !data.user) {
    throw new HttpError(401, "unauthorized");
  }

  return { id: data.user.id, email: data.user.email };
}

async function parseJsonBody<T>(req: Request): Promise<T> {
  const text = await req.text();
  if (!text) {
    return {} as T;
  }

  try {
    return JSON.parse(text) as T;
  } catch {
    throw new HttpError(400, "invalid_json_body");
  }
}

async function hashJson(value: unknown): Promise<string> {
  const encoded = new TextEncoder().encode(JSON.stringify(value));
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function resolveActivePrompt(
  admin: SupabaseClient,
  promptKey: string,
  locale: string,
): Promise<PromptTemplateRow> {
  const { data, error } = await admin
    .from("prompt_templates")
    .select("*")
    .eq("prompt_key", promptKey)
    .eq("locale", locale)
    .eq("status", "active")
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "prompt_lookup_failed", error);
  }

  if (!data) {
    throw new HttpError(404, "prompt_not_found", { promptKey, locale });
  }

  return data as PromptTemplateRow;
}

async function createGenerationRun(
  admin: SupabaseClient,
  payload: JsonObject,
): Promise<{ id: string }> {
  const { data, error } = await admin
    .from("ai_generation_runs")
    .insert(payload)
    .select("id")
    .single();

  if (error || !data) {
    throw new HttpError(500, "generation_run_create_failed", error);
  }

  return data as { id: string };
}

async function completeGenerationRun(
  admin: SupabaseClient,
  generationRunId: string,
  payload: JsonObject,
): Promise<void> {
  const { error } = await admin
    .from("ai_generation_runs")
    .update(payload)
    .eq("id", generationRunId);

  if (error) {
    throw new HttpError(500, "generation_run_update_failed", error);
  }
}

async function callGeminiJson(
  promptTemplate: PromptTemplateRow,
  contextJson: JsonObject,
): Promise<{ parsedOutput: JsonObject; rawTextOutput: string; latencyMs: number }> {
  const geminiApiKey = getEnv("GEMINI_API_KEY");
  const renderedPrompt = [
    "[Task Prompt]",
    promptTemplate.task_prompt_template,
    "",
    "[Context JSON]",
    JSON.stringify(contextJson, null, 2),
  ].join("\n");

  const startedAt = Date.now();
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${promptTemplate.model_name}:generateContent?key=${geminiApiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: promptTemplate.system_prompt }],
        },
        contents: [
          {
            role: "user",
            parts: [{ text: renderedPrompt }],
          },
        ],
        generationConfig: {
          temperature: promptTemplate.temperature ?? 0.45,
          maxOutputTokens: promptTemplate.max_output_tokens ?? 700,
          responseMimeType: "application/json",
        },
      }),
    },
  );
  const latencyMs = Date.now() - startedAt;
  const rawPayload = await response.json();

  if (!response.ok) {
    throw new HttpError(502, "gemini_provider_error", rawPayload);
  }

  const textOutput = stripCodeFences(
    rawPayload?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part.text ?? "")
      .join("") ?? "",
  );

  if (!textOutput) {
    throw new HttpError(502, "gemini_empty_output", rawPayload);
  }

  try {
    const parsedOutput = ensureObject(JSON.parse(textOutput), "invalid_json_output");
    return {
      parsedOutput,
      rawTextOutput: textOutput,
      latencyMs,
    };
  } catch (error) {
    if (error instanceof HttpError) {
      throw error;
    }
    throw new HttpError(502, "invalid_json_output", { textOutput });
  }
}

async function resolvePrimaryProfile(
  admin: SupabaseClient,
  ownerUserId: string,
  profileId?: string | null,
): Promise<JsonObject> {
  if (profileId) {
    if (isUuid(profileId)) {
      const { data, error } = await admin
        .from("numerology_profiles")
        .select("*")
        .eq("owner_user_id", ownerUserId)
        .eq("id", profileId)
        .is("archived_at", null)
        .maybeSingle();

      if (error) {
        throw new HttpError(500, "profile_lookup_failed", error);
      }
      if (data) {
        return data as JsonObject;
      }
    }

    const { data: byClientId, error: byClientIdError } = await admin
      .from("numerology_profiles")
      .select("*")
      .eq("owner_user_id", ownerUserId)
      .eq("client_profile_id", profileId)
      .is("archived_at", null)
      .maybeSingle();

    if (byClientIdError) {
      throw new HttpError(500, "profile_lookup_failed", byClientIdError);
    }
    if (!byClientId) {
      throw new HttpError(404, "profile_not_found");
    }
    return byClientId as JsonObject;
  }

  const { data: primary, error: primaryError } = await admin
    .from("numerology_profiles")
    .select("*")
    .eq("owner_user_id", ownerUserId)
    .eq("is_primary", true)
    .is("archived_at", null)
    .maybeSingle();

  if (primaryError) {
    throw new HttpError(500, "primary_profile_lookup_failed", primaryError);
  }
  if (primary) {
    return primary as JsonObject;
  }

  const { data: fallback, error: fallbackError } = await admin
    .from("numerology_profiles")
    .select("*")
    .eq("owner_user_id", ownerUserId)
    .is("archived_at", null)
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();

  if (fallbackError) {
    throw new HttpError(500, "fallback_profile_lookup_failed", fallbackError);
  }
  if (!fallback) {
    throw new HttpError(404, "primary_profile_not_found");
  }

  return fallback as JsonObject;
}

async function resolveOwnedThread(
  admin: SupabaseClient,
  ownerUserId: string,
  threadId: string,
): Promise<JsonObject> {
  const { data, error } = await admin
    .from("ai_threads")
    .select("*")
    .eq("owner_user_id", ownerUserId)
    .eq("id", threadId)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "thread_lookup_failed", error);
  }
  if (!data) {
    throw new HttpError(404, "thread_not_found");
  }
  return data as JsonObject;
}

async function resolveCurrentSnapshot(
  admin: SupabaseClient,
  ownerUserId: string,
  profileId: string,
): Promise<JsonObject> {
  const { data, error } = await admin
    .from("numerology_snapshots")
    .select("*")
    .eq("owner_user_id", ownerUserId)
    .eq("numerology_profile_id", profileId)
    .eq("is_current", true)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "snapshot_lookup_failed", error);
  }
  if (!data) {
    throw new HttpError(404, "snapshot_not_found");
  }
  return data as JsonObject;
}

function buildFallbackSnapshotPayload(profile: JsonObject): {
  rawInputJson: JsonObject;
  coreNumbersJson: JsonObject;
  birthMatrixJson: JsonObject;
  matrixAspectsJson: JsonObject;
  lifeCyclesJson: JsonObject;
} {
  const rawInputJson: JsonObject = {
    profile_id: String(profile.id ?? ""),
    display_name: profile.display_name ?? null,
    full_name_for_reading: profile.full_name_for_reading ?? null,
    birth_date: profile.birth_date ?? null,
    gender: profile.gender ?? null,
    profile_kind: profile.profile_kind ?? null,
    relation_kind: profile.relation_kind ?? null,
    source: "fallback_profile_snapshot",
  };

  const coreNumbersJson: JsonObject = {
    status: "fallback_pending_recalculation",
    display_name: profile.display_name ?? null,
    birth_date: profile.birth_date ?? null,
  };

  const birthMatrixJson: JsonObject = {
    status: "fallback_pending_recalculation",
    digits: [],
    missing_digits: [],
  };

  return {
    rawInputJson,
    coreNumbersJson,
    birthMatrixJson,
    matrixAspectsJson: {
      status: "fallback_pending_recalculation",
    },
    lifeCyclesJson: {
      status: "fallback_pending_recalculation",
    },
  };
}

async function createFallbackSnapshot(
  admin: SupabaseClient,
  ownerUserId: string,
  profile: JsonObject,
): Promise<JsonObject> {
  const profileId = String(profile.id ?? "");
  if (!profileId) {
    throw new HttpError(500, "invalid_profile_payload");
  }

  const payload = buildFallbackSnapshotPayload(profile);
  const sourceHash = await hashJson({
    engine_version: ENGINE_VERSION,
    ...payload.rawInputJson,
  });

  const { error: clearCurrentError } = await admin
    .from("numerology_snapshots")
    .update({ is_current: false })
    .eq("owner_user_id", ownerUserId)
    .eq("numerology_profile_id", profileId)
    .eq("is_current", true);

  if (clearCurrentError) {
    throw new HttpError(500, "snapshot_fallback_prepare_failed", clearCurrentError);
  }

  const { data, error } = await admin
    .from("numerology_snapshots")
    .insert({
      owner_user_id: ownerUserId,
      numerology_profile_id: profileId,
      engine_version: ENGINE_VERSION,
      source_hash: sourceHash,
      is_current: true,
      raw_input_json: payload.rawInputJson,
      core_numbers_json: payload.coreNumbersJson,
      birth_matrix_json: payload.birthMatrixJson,
      matrix_aspects_json: payload.matrixAspectsJson,
      life_cycles_json: payload.lifeCyclesJson,
      calculated_at: nowIso(),
    })
    .select("*")
    .single();

  if (error) {
    const errorCode = String((error as { code?: string })?.code ?? "");
    if (errorCode === "23505") {
      return resolveCurrentSnapshot(admin, ownerUserId, profileId);
    }
    throw new HttpError(500, "snapshot_fallback_create_failed", error);
  }

  return data as JsonObject;
}

async function ensureCurrentSnapshot(
  admin: SupabaseClient,
  ownerUserId: string,
  profile: JsonObject,
): Promise<JsonObject> {
  const profileId = String(profile.id ?? "");
  try {
    return await resolveCurrentSnapshot(admin, ownerUserId, profileId);
  } catch (error) {
    if (error instanceof HttpError && error.status === 404) {
      return createFallbackSnapshot(admin, ownerUserId, profile);
    }
    throw error;
  }
}

async function resolveAppUserProfile(
  admin: SupabaseClient,
  ownerUserId: string,
): Promise<JsonObject> {
  const { data, error } = await admin
    .from("user_profiles")
    .select("*")
    .eq("id", ownerUserId)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "user_profile_lookup_failed", error);
  }

  return (data as JsonObject | null) ?? {
    id: ownerUserId,
    locale: DEFAULT_LOCALE,
    timezone: DEFAULT_TIMEZONE,
  };
}

async function ensureWallet(
  admin: SupabaseClient,
  ownerUserId: string,
): Promise<void> {
  const { error } = await admin
    .from("soul_point_wallets")
    .upsert({ user_id: ownerUserId }, { onConflict: "user_id" });
  if (error) {
    throw new HttpError(500, "wallet_ensure_failed", error);
  }
}

async function getWalletBalance(
  admin: SupabaseClient,
  ownerUserId: string,
): Promise<number> {
  await ensureWallet(admin, ownerUserId);
  const { data, error } = await admin
    .from("soul_point_wallets")
    .select("balance")
    .eq("user_id", ownerUserId)
    .single();

  if (error || !data) {
    throw new HttpError(500, "wallet_lookup_failed", error);
  }
  return Number(data.balance ?? 0);
}

async function spendSoulPoints(
  admin: SupabaseClient,
  ownerUserId: string,
  amount: number,
  sourceType: string,
  metadataJson: JsonObject,
  sourceRefId: string,
): Promise<number> {
  if (amount <= 0) {
    return getWalletBalance(admin, ownerUserId);
  }

  await ensureWallet(admin, ownerUserId);
  const { data, error } = await admin
    .from("soul_point_wallets")
    .select("balance, lifetime_spent")
    .eq("user_id", ownerUserId)
    .single();

  if (error || !data) {
    throw new HttpError(500, "wallet_update_prepare_failed", error);
  }

  const currentBalance = Number(data.balance ?? 0);
  const lifetimeSpent = Number(data.lifetime_spent ?? 0);
  if (currentBalance < amount) {
    throw new HttpError(402, "insufficient_soul_points", {
      required: amount,
      balance: currentBalance,
    });
  }

  const nextBalance = currentBalance - amount;
  const { error: walletError } = await admin
    .from("soul_point_wallets")
    .update({
      balance: nextBalance,
      lifetime_spent: lifetimeSpent + amount,
      updated_at: nowIso(),
    })
    .eq("user_id", ownerUserId);

  if (walletError) {
    throw new HttpError(500, "wallet_spend_failed", walletError);
  }

  const { error: ledgerError } = await admin
    .from("soul_point_ledger")
    .insert({
      owner_user_id: ownerUserId,
      direction: "debit",
      amount,
      source_type: sourceType,
      source_ref_id: sourceRefId,
      balance_after: nextBalance,
      metadata_json: metadataJson,
    });

  if (ledgerError) {
    throw new HttpError(500, "ledger_spend_failed", ledgerError);
  }

  return nextBalance;
}

async function grantSoulPoints(
  admin: SupabaseClient,
  ownerUserId: string,
  amount: number,
  sourceType: string,
  metadataJson: JsonObject,
  sourceRefId: string,
): Promise<number> {
  if (amount <= 0) {
    return getWalletBalance(admin, ownerUserId);
  }

  await ensureWallet(admin, ownerUserId);
  const { data, error } = await admin
    .from("soul_point_wallets")
    .select("balance, lifetime_earned")
    .eq("user_id", ownerUserId)
    .single();

  if (error || !data) {
    throw new HttpError(500, "wallet_credit_lookup_failed", error);
  }

  const currentBalance = Number(data.balance ?? 0);
  const lifetimeEarned = Number(data.lifetime_earned ?? 0);
  const nextBalance = currentBalance + amount;

  const { error: walletError } = await admin
    .from("soul_point_wallets")
    .update({
      balance: nextBalance,
      lifetime_earned: lifetimeEarned + amount,
      updated_at: nowIso(),
    })
    .eq("user_id", ownerUserId);

  if (walletError) {
    throw new HttpError(500, "wallet_credit_failed", walletError);
  }

  const { error: ledgerError } = await admin
    .from("soul_point_ledger")
    .insert({
      owner_user_id: ownerUserId,
      direction: "credit",
      amount,
      source_type: sourceType,
      source_ref_id: sourceRefId,
      balance_after: nextBalance,
      metadata_json: metadataJson,
    });

  if (ledgerError) {
    throw new HttpError(500, "ledger_credit_failed", ledgerError);
  }

  return nextBalance;
}

async function handleSendNumaiMessage(req: Request): Promise<JsonObject> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);

  const body = await parseJsonBody<{
    thread_id?: string;
    primary_profile_id?: string;
    related_profile_id?: string;
    locale?: string;
    message_text?: string;
  }>(req);

  const messageText = String(body.message_text ?? "").trim();
  if (!messageText) {
    throw new HttpError(400, "message_text_required");
  }

  const locale = String(body.locale ?? DEFAULT_LOCALE);
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  let thread: JsonObject;

  if (body.thread_id) {
    thread = await resolveOwnedThread(admin, user.id, body.thread_id);
  } else {
    const primaryProfile = await resolvePrimaryProfile(
      admin,
      user.id,
      body.primary_profile_id,
    );
    const relatedProfileId = body.related_profile_id
      ? String((await resolvePrimaryProfile(admin, user.id, body.related_profile_id)).id)
      : null;

    const { data: existingThread, error: existingThreadError } = await admin
      .from("ai_threads")
      .select("*")
      .eq("owner_user_id", user.id)
      .eq("primary_profile_id", primaryProfile.id)
      .maybeSingle();

    if (existingThreadError) {
      throw new HttpError(500, "thread_lookup_failed", existingThreadError);
    }

    if (existingThread) {
      thread = existingThread as JsonObject;
    } else {
      const { data: createdThread, error: createThreadError } = await admin
        .from("ai_threads")
        .insert({
          owner_user_id: user.id,
          primary_profile_id: primaryProfile.id,
          related_profile_id: relatedProfileId,
          title: messageText.slice(0, 48),
          last_message_at: nowIso(),
        })
        .select("*")
        .single();

      if (createThreadError || !createdThread) {
        throw new HttpError(500, "thread_create_failed", createThreadError);
      }
      thread = createdThread as JsonObject;
    }
  }

  const activeProfile = await resolvePrimaryProfile(
    admin,
    user.id,
    String(thread.primary_profile_id),
  );
  const snapshot = await ensureCurrentSnapshot(admin, user.id, activeProfile);
  const currentBalance = await getWalletBalance(admin, user.id);
  if (currentBalance < NUMAI_SOUL_POINT_COST) {
    throw new HttpError(402, "insufficient_soul_points", {
      required: NUMAI_SOUL_POINT_COST,
      balance: currentBalance,
    });
  }

  const { data: userMessage, error: userMessageError } = await admin
    .from("ai_messages")
    .insert({
      owner_user_id: user.id,
      thread_id: thread.id,
      sender_type: "user",
      message_text: messageText,
      context_snapshot_id: snapshot.id,
      soul_point_cost: NUMAI_SOUL_POINT_COST,
    })
    .select("*")
    .single();

  if (userMessageError || !userMessage) {
    throw new HttpError(500, "user_message_insert_failed", userMessageError);
  }

  let charged = false;
  let walletBalanceAfterCharge: number | null = null;

  try {
    walletBalanceAfterCharge = await spendSoulPoints(
      admin,
      user.id,
      NUMAI_SOUL_POINT_COST,
      "numai_message",
      { thread_id: String(thread.id), message_id: String(userMessage.id) },
      String(userMessage.id),
    );
    charged = true;
  } catch (error) {
    const { error: cleanupError } = await admin
      .from("ai_messages")
      .delete()
      .eq("id", userMessage.id);
    if (cleanupError) {
      throw new HttpError(500, "message_cleanup_after_charge_failure_failed", {
        charge_error: error,
        cleanup_error: cleanupError,
      });
    }
    throw error;
  }

  const { data: recentMessages, error: recentMessagesError } = await admin
    .from("ai_messages")
    .select("sender_type, message_text, created_at")
    .eq("thread_id", thread.id)
    .order("created_at", { ascending: false })
    .limit(NUMAI_RECENT_MESSAGES_LIMIT);

  if (recentMessagesError) {
    if (charged) {
      await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        { reason: "numai_message_failed", message_id: String(userMessage.id) },
        String(userMessage.id),
      );
    }
    throw new HttpError(500, "recent_messages_lookup_failed", recentMessagesError);
  }

  const contextJson: JsonObject = {
    thread_summary: {
      summary: String(thread.thread_summary ?? ""),
      updated_at: thread.thread_summary_updated_at ?? null,
    },
    recent_messages: (recentMessages ?? [])
      .slice()
      .reverse()
      .map((message) => ({
        role: message.sender_type,
        text: message.message_text,
      })),
    active_profile: {
      profile_id: activeProfile.id,
      display_name: activeProfile.display_name,
      profile_kind: activeProfile.profile_kind,
      relation_kind: activeProfile.relation_kind,
      timezone: appUserProfile.timezone ?? DEFAULT_TIMEZONE,
    },
    snapshot_facts: {
      core_numbers: snapshot.core_numbers_json,
      birth_matrix: snapshot.birth_matrix_json,
      matrix_aspects: snapshot.matrix_aspects_json,
      life_cycles: snapshot.life_cycles_json,
    },
    user_question: messageText,
  };

  let prompt: PromptTemplateRow;
  let generationRun: { id: string };
  try {
    prompt = await resolveActivePrompt(admin, "numai_chat_reply", locale);
    generationRun = await createGenerationRun(admin, {
      owner_user_id: user.id,
      generation_kind: "numai_reply",
      prompt_template_id: prompt.id,
      prompt_key: prompt.prompt_key,
      target_table: "ai_messages",
      provider: prompt.provider,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      system_prompt_snapshot: prompt.system_prompt,
      task_prompt_snapshot: prompt.task_prompt_template,
      status: "running",
      input_hash: await hashJson(contextJson),
      input_context_json: contextJson,
      started_at: nowIso(),
    });
  } catch (error) {
    if (charged) {
      await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        {
          reason: "numai_generation_refund",
          message_id: String(userMessage.id),
          original_error_code: resolveErrorCode(error),
        },
        String(userMessage.id),
      );
    }
    throw error;
  }

  try {
    let assistantText = "";
    let suggestions: string[] = [];
    let referencedSections: string[] = [];
    let fallbackReason: NumAiFallbackReason | null = null;
    let originalErrorCode: string | null = null;
    let generationStatus: "succeeded" | "failed" = "succeeded";
    let generationOutput: JsonObject | null = null;
    let rawTextOutput: string | null = null;
    let generationLatencyMs: number | null = null;

    try {
      const geminiResult = await callGeminiJson(prompt, contextJson);
      generationOutput = geminiResult.parsedOutput;
      rawTextOutput = geminiResult.rawTextOutput;
      generationLatencyMs = geminiResult.latencyMs;

      const output = ensureObject(geminiResult.parsedOutput, "invalid_numai_output");
      if (isTruthyFlag(output.is_out_of_scope)) {
        fallbackReason = "out_of_scope";
        assistantText = NUMAI_OUT_OF_SCOPE_FALLBACK_MESSAGE;
        suggestions = fallbackFollowUpSuggestions(locale);
      } else {
        const answer = String(output.answer ?? "").trim();
        if (!answer) {
          throw new HttpError(502, "numai_empty_answer");
        }
        assistantText = answer;
        referencedSections = ensureArrayOfStrings(output.referenced_sections);
        suggestions = resolveFollowUpSuggestions(output, locale);
      }
    } catch (error) {
      if (!isNumAiTechnicalError(error)) {
        throw error;
      }
      fallbackReason = "technical_error";
      generationStatus = "failed";
      originalErrorCode = resolveErrorCode(error);
      assistantText = NUMAI_TECHNICAL_FALLBACK_MESSAGE;
      suggestions = fallbackFollowUpSuggestions(locale);
    }

    if (fallbackReason && charged) {
      walletBalanceAfterCharge = await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        {
          reason: "numai_generation_refund",
          refund_type: fallbackReason,
          message_id: String(userMessage.id),
          original_error_code: originalErrorCode,
        },
        String(userMessage.id),
      );
      charged = false;
    }

    const metadataJson: JsonObject = {
      referenced_sections: referencedSections,
      follow_up_suggestions: suggestions,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
    };
    if (fallbackReason) {
      metadataJson.fallback_reason = fallbackReason;
    }
    if (originalErrorCode) {
      metadataJson.original_error_code = originalErrorCode;
    }

    const { data: assistantMessage, error: assistantError } = await admin
      .from("ai_messages")
      .insert({
        owner_user_id: user.id,
        thread_id: thread.id,
        sender_type: "assistant",
        message_text: assistantText,
        context_snapshot_id: snapshot.id,
        ai_generation_run_id: generationRun.id,
        prompt_template_id: prompt.id,
        soul_point_cost: 0,
        metadata_json: metadataJson,
      })
      .select("*")
      .single();

    if (assistantError || !assistantMessage) {
      throw new HttpError(500, "assistant_message_insert_failed", assistantError);
    }

    const { error: threadUpdateError } = await admin
      .from("ai_threads")
      .update({
        last_message_at: nowIso(),
        updated_at: nowIso(),
        thread_summary: buildThreadSummary(
          String(thread.thread_summary ?? ""),
          messageText,
          assistantText,
        ),
        thread_summary_updated_at: nowIso(),
      })
      .eq("id", thread.id);

    if (threadUpdateError) {
      throw new HttpError(500, "thread_update_failed", threadUpdateError);
    }

    if (generationStatus === "succeeded") {
      await completeGenerationRun(admin, generationRun.id, {
        status: "succeeded",
        target_id: assistantMessage.id,
        output_json: generationOutput ?? {
          answer: assistantText,
          referenced_sections: referencedSections,
          follow_up_suggestions: suggestions,
          is_out_of_scope: fallbackReason === "out_of_scope",
        },
        raw_text_output: rawTextOutput,
        latency_ms: generationLatencyMs,
        completed_at: nowIso(),
      });
    } else {
      await completeGenerationRun(admin, generationRun.id, {
        status: "failed",
        target_id: assistantMessage.id,
        output_json: generationOutput,
        raw_text_output: rawTextOutput,
        latency_ms: generationLatencyMs,
        error_text: originalErrorCode ?? "technical_fallback",
        completed_at: nowIso(),
      });
    }

    return {
      ok: true,
      data: {
        thread_id: thread.id,
        user_message: userMessage,
        assistant_message: assistantMessage,
        charged_soul_points: charged ? NUMAI_SOUL_POINT_COST : 0,
        wallet_balance: walletBalanceAfterCharge ?? currentBalance,
        assistant_suggestions: suggestions,
      },
      meta: {
        prompt_key: prompt.prompt_key,
        prompt_version: prompt.version,
        engine_version: ENGINE_VERSION,
      },
    };
  } catch (error) {
    if (charged) {
      await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        {
          reason: "numai_generation_refund",
          message_id: String(userMessage.id),
          original_error_code: resolveErrorCode(error),
        },
        String(userMessage.id),
      );
    }

    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: resolveErrorCode(error),
      completed_at: nowIso(),
    });
    throw error;
  }
}

async function handleListNumaiMessages(req: Request): Promise<JsonObject> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);

  const body = await parseJsonBody<{
    thread_id?: string;
    primary_profile_id?: string;
    limit?: number;
  }>(req);

  const requestedLimit = Number(body.limit ?? 50);
  const limit = Number.isFinite(requestedLimit)
    ? Math.min(Math.max(Math.trunc(requestedLimit), 1), 100)
    : 50;

  let thread: JsonObject | null = null;
  if (body.thread_id) {
    thread = await resolveOwnedThread(admin, user.id, body.thread_id);
  } else {
    const primaryProfile = await resolvePrimaryProfile(
      admin,
      user.id,
      body.primary_profile_id,
    );

    const { data: existingThread, error: existingThreadError } = await admin
      .from("ai_threads")
      .select("*")
      .eq("owner_user_id", user.id)
      .eq("primary_profile_id", primaryProfile.id)
      .maybeSingle();

    if (existingThreadError) {
      throw new HttpError(500, "thread_lookup_failed", existingThreadError);
    }

    thread = (existingThread as JsonObject | null) ?? null;
  }

  if (!thread) {
    return {
      ok: true,
      data: {
        thread_id: null,
        messages: [],
      },
    };
  }

  const { data: messages, error: messagesError } = await admin
    .from("ai_messages")
    .select("*")
    .eq("owner_user_id", user.id)
    .eq("thread_id", thread.id)
    .order("created_at", { ascending: true })
    .limit(limit);

  if (messagesError) {
    throw new HttpError(500, "messages_lookup_failed", messagesError);
  }

  return {
    ok: true,
    data: {
      thread_id: thread.id,
      messages: messages ?? [],
    },
  };
}

async function handleImportGuestNumaiHistory(req: Request): Promise<JsonObject> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);

  const body = await parseJsonBody<{
    primary_profile_id?: string;
    request_id?: string;
    messages?: unknown;
  }>(req);

  const requestId = String(body.request_id ?? "").trim();
  const primaryProfile = await resolvePrimaryProfile(
    admin,
    user.id,
    body.primary_profile_id,
  );
  const importableMessages = sanitizeGuestMessagesForImport(body.messages);

  const { data: existingThread, error: existingThreadError } = await admin
    .from("ai_threads")
    .select("*")
    .eq("owner_user_id", user.id)
    .eq("primary_profile_id", primaryProfile.id)
    .maybeSingle();

  if (existingThreadError) {
    throw new HttpError(500, "thread_lookup_failed", existingThreadError);
  }

  let thread = (existingThread as JsonObject | null) ?? null;
  if (!thread && importableMessages.length > 0) {
    const firstTitle = importableMessages.find((item) => item.senderType === "user")
      ?.messageText ?? importableMessages[0].messageText;

    const { data: createdThread, error: createThreadError } = await admin
      .from("ai_threads")
      .insert({
        owner_user_id: user.id,
        primary_profile_id: primaryProfile.id,
        title: firstTitle.slice(0, 48),
        last_message_at: nowIso(),
      })
      .select("*")
      .single();

    if (createThreadError || !createdThread) {
      throw new HttpError(500, "thread_create_failed", createThreadError);
    }

    thread = createdThread as JsonObject;
  }

  if (!thread) {
    return {
      ok: true,
      data: {
        thread_id: null,
        imported_count: 0,
        skipped_count: importableMessages.length,
      },
    };
  }

  const { data: existingMessages, error: existingMessagesError } = await admin
    .from("ai_messages")
    .select("metadata_json")
    .eq("owner_user_id", user.id)
    .eq("thread_id", thread.id);

  if (existingMessagesError) {
    throw new HttpError(500, "existing_messages_lookup_failed", existingMessagesError);
  }

  const importedLocalIdSet = new Set<string>();
  for (const row of existingMessages ?? []) {
    const metadata = (row as { metadata_json?: unknown })?.metadata_json;
    if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) {
      continue;
    }
    const importedLocalId = String((metadata as JsonObject).guest_local_message_id ?? "")
      .trim();
    if (importedLocalId) {
      importedLocalIdSet.add(importedLocalId);
    }
  }

  const rowsToInsert = importableMessages
    .filter((item) => !importedLocalIdSet.has(item.localId))
    .map((item) => {
      const metadataJson: JsonObject = {
        source: "guest_local_migration",
        guest_local_message_id: item.localId,
      };
      if (requestId) {
        metadataJson.import_request_id = requestId;
      }
      if (item.followUpSuggestions.length > 0) {
        metadataJson.follow_up_suggestions = item.followUpSuggestions;
      }

      return {
        owner_user_id: user.id,
        thread_id: thread.id,
        sender_type: item.senderType,
        message_text: item.messageText,
        soul_point_cost: 0,
        metadata_json: metadataJson,
        created_at: item.createdAt,
      };
    });

  if (rowsToInsert.length > 0) {
    const { error: insertError } = await admin
      .from("ai_messages")
      .insert(rowsToInsert);

    if (insertError) {
      throw new HttpError(500, "guest_history_insert_failed", insertError);
    }

    const latestCreatedAt = rowsToInsert[rowsToInsert.length - 1].created_at;
    const { error: threadUpdateError } = await admin
      .from("ai_threads")
      .update({
        last_message_at: latestCreatedAt,
        updated_at: nowIso(),
      })
      .eq("id", thread.id);

    if (threadUpdateError) {
      throw new HttpError(500, "thread_update_failed", threadUpdateError);
    }
  }

  return {
    ok: true,
    data: {
      thread_id: thread.id,
      imported_count: rowsToInsert.length,
      skipped_count: importableMessages.length - rowsToInsert.length,
    },
  };
}

async function handleSyncNumaiSnapshots(req: Request): Promise<JsonObject> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);

  const body = await parseJsonBody<{
    snapshots?: unknown;
  }>(req);

  const snapshots = sanitizeClientNumAiSnapshots(body.snapshots);
  if (snapshots.length === 0) {
    return {
      ok: true,
      data: {
        updated_count: 0,
        skipped_count: 0,
        snapshots: [],
      },
    };
  }

  const results: JsonObject[] = [];
  let updatedCount = 0;
  let skippedCount = 0;

  for (const snapshot of snapshots) {
    let profile: JsonObject;
    try {
      profile = await resolvePrimaryProfile(admin, user.id, snapshot.primaryProfileId);
    } catch (error) {
      if (
        error instanceof HttpError &&
        (error.message === "profile_not_found" || error.message === "primary_profile_not_found")
      ) {
        skippedCount += 1;
        results.push({
          primary_profile_id: snapshot.primaryProfileId,
          status: "skipped_profile_not_found",
        });
        continue;
      }
      throw error;
    }

    const profileId = String(profile.id ?? "").trim();
    if (!profileId) {
      skippedCount += 1;
      results.push({
        primary_profile_id: snapshot.primaryProfileId,
        status: "skipped_invalid_profile",
      });
      continue;
    }

    const resolvedRawInputJson: JsonObject = {
      ...snapshot.rawInputJson,
      profile_id: profileId,
      client_profile_id: snapshot.primaryProfileId,
      source: String(snapshot.rawInputJson.source ?? "mobile_local_sync"),
    };

    const sourceHash = snapshot.sourceHash ?? await hashJson({
      owner_user_id: user.id,
      profile_id: profileId,
      engine_version: snapshot.engineVersion,
      raw_input_json: resolvedRawInputJson,
      core_numbers_json: snapshot.coreNumbersJson,
      birth_matrix_json: snapshot.birthMatrixJson,
      matrix_aspects_json: snapshot.matrixAspectsJson,
      life_cycles_json: snapshot.lifeCyclesJson,
    });

    const { data: currentSnapshot, error: currentSnapshotError } = await admin
      .from("numerology_snapshots")
      .select("id, source_hash")
      .eq("owner_user_id", user.id)
      .eq("numerology_profile_id", profileId)
      .eq("is_current", true)
      .maybeSingle();

    if (currentSnapshotError) {
      throw new HttpError(500, "snapshot_lookup_failed", currentSnapshotError);
    }

    const currentSnapshotId = String(currentSnapshot?.id ?? "").trim();
    const currentSourceHash = String(currentSnapshot?.source_hash ?? "").trim();
    if (currentSnapshotId && currentSourceHash === sourceHash) {
      skippedCount += 1;
      results.push({
        primary_profile_id: snapshot.primaryProfileId,
        profile_id: profileId,
        snapshot_id: currentSnapshotId,
        status: "unchanged",
      });
      continue;
    }

    let invalidatedCurrent = false;
    if (currentSnapshotId) {
      const { error: clearCurrentError } = await admin
        .from("numerology_snapshots")
        .update({ is_current: false })
        .eq("owner_user_id", user.id)
        .eq("numerology_profile_id", profileId)
        .eq("is_current", true);
      if (clearCurrentError) {
        throw new HttpError(500, "snapshot_invalidate_failed", clearCurrentError);
      }
      invalidatedCurrent = true;
    }

    try {
      const { data: createdSnapshot, error: createSnapshotError } = await admin
        .from("numerology_snapshots")
        .insert({
          owner_user_id: user.id,
          numerology_profile_id: profileId,
          engine_version: snapshot.engineVersion,
          source_hash: sourceHash,
          is_current: true,
          raw_input_json: resolvedRawInputJson,
          core_numbers_json: snapshot.coreNumbersJson,
          birth_matrix_json: snapshot.birthMatrixJson,
          matrix_aspects_json: snapshot.matrixAspectsJson,
          life_cycles_json: snapshot.lifeCyclesJson,
          calculated_at: snapshot.calculatedAt,
        })
        .select("id")
        .single();

      if (createSnapshotError || !createdSnapshot) {
        throw new HttpError(500, "snapshot_create_failed", createSnapshotError);
      }

      updatedCount += 1;
      results.push({
        primary_profile_id: snapshot.primaryProfileId,
        profile_id: profileId,
        snapshot_id: String(createdSnapshot.id ?? ""),
        status: "updated",
      });
    } catch (error) {
      if (invalidatedCurrent && currentSnapshotId) {
        await admin
          .from("numerology_snapshots")
          .update({ is_current: true })
          .eq("owner_user_id", user.id)
          .eq("id", currentSnapshotId);
      }
      throw error;
    }
  }

  return {
    ok: true,
    data: {
      updated_count: updatedCount,
      skipped_count: skippedCount,
      snapshots: results,
    },
  };
}

async function routeRequest(req: Request): Promise<unknown> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    throw new HttpError(405, "method_not_allowed");
  }

  const url = new URL(req.url);
  const action = url.searchParams.get("action") ??
    req.headers.get("x-numverse-action");

  if (!action) {
    throw new HttpError(400, "missing_action", {
      allowed_actions: [
        "send-numai-message",
        "list-numai-messages",
        "import-guest-numai-history",
        "sync-numai-snapshots",
      ],
    });
  }

  if (action === "send-numai-message") {
    return handleSendNumaiMessage(req);
  }

  if (action === "list-numai-messages") {
    return handleListNumaiMessages(req);
  }

  if (action === "import-guest-numai-history") {
    return handleImportGuestNumaiHistory(req);
  }

  if (action === "sync-numai-snapshots") {
    return handleSyncNumaiSnapshots(req);
  }

  throw new HttpError(404, "unknown_action", {
    action,
    allowed_actions: [
      "send-numai-message",
      "list-numai-messages",
      "import-guest-numai-history",
      "sync-numai-snapshots",
    ],
  });
}

Deno.serve(async (req: Request) => {
  try {
    const result = await routeRequest(req);
    if (result instanceof Response) {
      return result;
    }
    return jsonResponse(result);
  } catch (error) {
    console.error(error);
    return errorResponse(error);
  }
});
