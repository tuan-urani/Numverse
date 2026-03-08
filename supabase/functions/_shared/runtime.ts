import { createClient } from "npm:@supabase/supabase-js@2";

export type SupabaseClient = ReturnType<typeof createClient>;

export interface PromptTemplateRow {
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
  context_schema_json: Record<string, unknown> | null;
  output_schema_json: Record<string, unknown> | null;
}

export interface GenerationRunInsert {
  owner_user_id: string;
  generation_kind: string;
  prompt_template_id: string | null;
  prompt_key: string;
  target_table: string;
  target_id?: string | null;
  provider: string;
  model_name: string;
  prompt_version: string;
  system_prompt_snapshot?: string | null;
  task_prompt_snapshot?: string | null;
  schema_version?: string | null;
  status: string;
  input_hash?: string | null;
  input_context_json: Record<string, unknown>;
  started_at?: string;
}

export interface GeminiResult {
  parsedOutput: Record<string, unknown>;
  rawTextOutput: string;
  latencyMs: number;
}

export class HttpError extends Error {
  status: number;
  details?: unknown;

  constructor(status: number, message: string, details?: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

export const ENGINE_VERSION = Deno.env.get("NUMEROLOGY_ENGINE_VERSION") ?? "v1";
export const DEFAULT_LOCALE = "vi-VN";
export const DEFAULT_TIMEZONE = "Asia/Ho_Chi_Minh";
export const NUMAI_SOUL_POINT_COST = Number(
  Deno.env.get("NUMAI_SOUL_POINT_COST") ?? "10",
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export function errorResponse(error: unknown): Response {
  if (error instanceof HttpError) {
    return jsonResponse(
      { ok: false, error: error.message, details: error.details ?? null },
      error.status,
    );
  }

  const message = error instanceof Error ? error.message : "internal_error";
  return jsonResponse({ ok: false, error: message }, 500);
}

export function serveHandler(
  handler: (req: Request) => Promise<unknown>,
): (req: Request) => Promise<Response> {
  return async (req: Request) => {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    try {
      const result = await handler(req);
      return jsonResponse(result);
    } catch (error) {
      console.error(error);
      return errorResponse(error);
    }
  };
}

export function getEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new HttpError(500, `missing_env_${name.toLowerCase()}`);
  }
  return value;
}

export function createClients(req: Request): {
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

export function getBearerToken(req: Request): string {
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

export async function requireUser(
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

export async function parseJsonBody<T>(
  req: Request,
): Promise<T> {
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

export async function sha256Hex(input: string): Promise<string> {
  const encoded = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function hashJson(value: unknown): Promise<string> {
  return sha256Hex(JSON.stringify(value));
}

export function ensureObject(
  value: unknown,
  message = "invalid_object_payload",
): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpError(500, message);
  }
  return value as Record<string, unknown>;
}

export function ensureArrayOfStrings(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((item) => typeof item === "string");
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export function isoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function parseIsoDate(value: string): Date {
  return new Date(`${value}T00:00:00.000Z`);
}

export function addDays(iso: string, days: number): string {
  const date = parseIsoDate(iso);
  date.setUTCDate(date.getUTCDate() + days);
  return isoDate(date);
}

export function addYears(iso: string, years: number): string {
  const date = parseIsoDate(iso);
  date.setUTCFullYear(date.getUTCFullYear() + years);
  return isoDate(date);
}

export function getLocalDateParts(
  timezone: string,
  reference = new Date(),
): { localDate: string; year: number; month: number; day: number } {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });

  const parts = formatter.formatToParts(reference);
  const year = Number(parts.find((part) => part.type === "year")?.value);
  const month = Number(parts.find((part) => part.type === "month")?.value);
  const day = Number(parts.find((part) => part.type === "day")?.value);

  if (!year || !month || !day) {
    throw new HttpError(500, "failed_to_resolve_local_date");
  }

  return {
    localDate: `${year.toString().padStart(4, "0")}-${month.toString().padStart(2, "0")}-${day.toString().padStart(2, "0")}`,
    year,
    month,
    day,
  };
}

function valueMatchesType(value: unknown, typeName: string): boolean {
  if (typeName === "null") return value === null;
  if (typeName === "string") return typeof value === "string";
  if (typeName === "number") return typeof value === "number" && !Number.isNaN(value);
  if (typeName === "integer") return Number.isInteger(value);
  if (typeName === "boolean") return typeof value === "boolean";
  if (typeName === "array") return Array.isArray(value);
  if (typeName === "object") {
    return !!value && typeof value === "object" && !Array.isArray(value);
  }
  return true;
}

function validateSchemaNode(
  value: unknown,
  schema: Record<string, unknown>,
  path: string,
  errors: string[],
): void {
  const rawType = schema.type;
  const allowedTypes = Array.isArray(rawType)
    ? rawType.filter((item) => typeof item === "string")
    : typeof rawType === "string"
    ? [rawType]
    : [];

  if (
    allowedTypes.length > 0 &&
    !allowedTypes.some((typeName) => valueMatchesType(value, typeName))
  ) {
    errors.push(`${path}: expected ${allowedTypes.join("|")}`);
    return;
  }

  if (!value || typeof value !== "object") {
    return;
  }

  if (Array.isArray(value)) {
    const itemSchema = schema.items;
    if (itemSchema && typeof itemSchema === "object" && !Array.isArray(itemSchema)) {
      value.forEach((item, index) =>
        validateSchemaNode(
          item,
          itemSchema as Record<string, unknown>,
          `${path}[${index}]`,
          errors,
        ));
    }
    return;
  }

  const required = Array.isArray(schema.required)
    ? schema.required.filter((item) => typeof item === "string")
    : [];
  const properties = schema.properties &&
      typeof schema.properties === "object" &&
      !Array.isArray(schema.properties)
    ? schema.properties as Record<string, unknown>
    : {};

  for (const key of required) {
    if (!(key in value)) {
      errors.push(`${path}.${key}: required`);
    }
  }

  for (const [key, childSchema] of Object.entries(properties)) {
    if (
      key in value &&
      childSchema &&
      typeof childSchema === "object" &&
      !Array.isArray(childSchema)
    ) {
      validateSchemaNode(
        (value as Record<string, unknown>)[key],
        childSchema as Record<string, unknown>,
        `${path}.${key}`,
        errors,
      );
    }
  }
}

export function validateWithSchema(
  schema: Record<string, unknown> | null | undefined,
  value: unknown,
): string[] {
  if (!schema) {
    return [];
  }

  const errors: string[] = [];
  validateSchemaNode(value, schema, "$", errors);
  return errors;
}

export async function resolveActivePrompt(
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

export async function createGenerationRun(
  admin: SupabaseClient,
  payload: GenerationRunInsert,
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

export async function completeGenerationRun(
  admin: SupabaseClient,
  generationRunId: string,
  payload: Record<string, unknown>,
): Promise<void> {
  const { error } = await admin
    .from("ai_generation_runs")
    .update(payload)
    .eq("id", generationRunId);

  if (error) {
    throw new HttpError(500, "generation_run_update_failed", error);
  }
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

export async function callGeminiJson(
  promptTemplate: PromptTemplateRow,
  contextJson: Record<string, unknown>,
): Promise<GeminiResult> {
  const geminiApiKey = getEnv("GEMINI_API_KEY");
  const renderedPrompt = [
    "[Task Prompt]",
    promptTemplate.task_prompt_template,
    "",
    "[Context JSON]",
    JSON.stringify(contextJson, null, 2),
    "",
    "[Output Schema JSON]",
    JSON.stringify(promptTemplate.output_schema_json ?? {}, null, 2),
  ].join("\n");

  const contextErrors = validateWithSchema(
    promptTemplate.context_schema_json,
    contextJson,
  );
  if (contextErrors.length > 0) {
    throw new HttpError(500, "context_schema_validation_failed", contextErrors);
  }

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
          temperature: promptTemplate.temperature ?? 0.3,
          maxOutputTokens: promptTemplate.max_output_tokens ?? 1024,
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

  let parsedOutput: Record<string, unknown>;
  try {
    parsedOutput = ensureObject(JSON.parse(textOutput), "invalid_json_output");
  } catch (error) {
    if (error instanceof HttpError) {
      throw error;
    }
    throw new HttpError(502, "invalid_json_output", { textOutput });
  }

  const outputErrors = validateWithSchema(
    promptTemplate.output_schema_json,
    parsedOutput,
  );
  if (outputErrors.length > 0) {
    throw new HttpError(502, "schema_validation_failed", outputErrors);
  }

  return {
    parsedOutput,
    rawTextOutput: textOutput,
    latencyMs,
  };
}

export async function resolvePrimaryProfile(
  admin: SupabaseClient,
  ownerUserId: string,
  profileId?: string | null,
): Promise<Record<string, unknown>> {
  if (profileId) {
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
    if (!data) {
      throw new HttpError(404, "profile_not_found");
    }
    return data as Record<string, unknown>;
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
    return primary as Record<string, unknown>;
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

  return fallback as Record<string, unknown>;
}

export async function resolveAppUserProfile(
  admin: SupabaseClient,
  ownerUserId: string,
): Promise<Record<string, unknown>> {
  const { data, error } = await admin
    .from("user_profiles")
    .select("*")
    .eq("id", ownerUserId)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "user_profile_lookup_failed", error);
  }

  return (data as Record<string, unknown> | null) ?? {
    id: ownerUserId,
    locale: DEFAULT_LOCALE,
    timezone: DEFAULT_TIMEZONE,
  };
}

export async function resolveOwnedThread(
  admin: SupabaseClient,
  ownerUserId: string,
  threadId: string,
): Promise<Record<string, unknown>> {
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

  return data as Record<string, unknown>;
}

export async function resolveCurrentSnapshot(
  admin: SupabaseClient,
  ownerUserId: string,
  profileId: string,
): Promise<Record<string, unknown>> {
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

  return data as Record<string, unknown>;
}

export async function resolveCurrentNarrative(
  admin: SupabaseClient,
  ownerUserId: string,
  snapshotId: string,
): Promise<Record<string, unknown> | null> {
  const { data, error } = await admin
    .from("numerology_snapshot_narratives")
    .select("*")
    .eq("owner_user_id", ownerUserId)
    .eq("numerology_snapshot_id", snapshotId)
    .eq("is_current", true)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "narrative_lookup_failed", error);
  }

  return data as Record<string, unknown> | null;
}

export async function hasActiveProSubscription(
  admin: SupabaseClient,
  ownerUserId: string,
): Promise<boolean> {
  const { data, error } = await admin
    .from("subscriptions")
    .select("id, status, expires_at")
    .eq("owner_user_id", ownerUserId)
    .in("status", ["trialing", "active", "grace_period"])
    .order("created_at", { ascending: false })
    .limit(20);

  if (error) {
    throw new HttpError(500, "subscription_lookup_failed", error);
  }

  if (!Array.isArray(data) || data.length === 0) {
    return false;
  }

  const nowMs = Date.now();
  return data.some((item) => !item.expires_at || Date.parse(item.expires_at) > nowMs);
}

export async function ensureWallet(
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

export async function getWalletBalance(
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

export async function spendSoulPoints(
  admin: SupabaseClient,
  ownerUserId: string,
  amount: number,
  sourceType: string,
  metadataJson: Record<string, unknown> = {},
  sourceRefId?: string | null,
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
      updated_at: new Date().toISOString(),
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
      source_ref_id: sourceRefId ?? null,
      balance_after: nextBalance,
      metadata_json: metadataJson,
    });

  if (ledgerError) {
    throw new HttpError(500, "ledger_spend_failed", ledgerError);
  }

  return nextBalance;
}

export async function grantSoulPoints(
  admin: SupabaseClient,
  ownerUserId: string,
  amount: number,
  sourceType: string,
  metadataJson: Record<string, unknown> = {},
  sourceRefId?: string | null,
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
      updated_at: new Date().toISOString(),
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
      source_ref_id: sourceRefId ?? null,
      balance_after: nextBalance,
      metadata_json: metadataJson,
    });

  if (ledgerError) {
    throw new HttpError(500, "ledger_credit_failed", ledgerError);
  }

  return nextBalance;
}

export function buildThreadSummary(
  existingSummary: string | null | undefined,
  userQuestion: string,
  answer: string,
): string {
  const pieces = [
    existingSummary?.trim(),
    `Nguoi dung hoi: ${userQuestion.trim()}`,
    `AI tra loi: ${answer.trim()}`,
  ].filter(Boolean);

  const summary = pieces.join(" | ");
  return summary.length <= 800 ? summary : summary.slice(summary.length - 800);
}

export function cacheResponse(
  cacheStatus: "hit" | "miss_generated" | "miss_in_progress",
  data: unknown,
  meta: Record<string, unknown>,
): Record<string, unknown> {
  return {
    ok: true,
    cache_status: cacheStatus,
    data,
    meta,
  };
}
