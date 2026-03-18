// supabase/functions/numverse-api/index.bundle.ts
import { createClient } from "npm:@supabase/supabase-js@2";
var HttpError = class extends Error {
  status;
  details;
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
};
var ENGINE_VERSION = Deno.env.get("NUMEROLOGY_ENGINE_VERSION") ?? "v1";
var DEFAULT_LOCALE = "vi-VN";
var DEFAULT_TIMEZONE = "Asia/Ho_Chi_Minh";
var NUMAI_SOUL_POINT_COST = Number(
  Deno.env.get("NUMAI_SOUL_POINT_COST") ?? "10"
);
var corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS"
};
function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json"
    }
  });
}
function errorResponse(error) {
  if (error instanceof HttpError) {
    return jsonResponse(
      { ok: false, error: error.message, details: error.details ?? null },
      error.status
    );
  }
  const message = error instanceof Error ? error.message : "internal_error";
  return jsonResponse({ ok: false, error: message }, 500);
}
function serveHandler(handler) {
  return async (req) => {
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
function getEnv(name) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new HttpError(500, `missing_env_${name.toLowerCase()}`);
  }
  return value;
}
function createClients(req) {
  const supabaseUrl = getEnv("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SB_PUBLISHABLE_KEY");
  const serviceRoleKey = getEnv("SUPABASE_SERVICE_ROLE_KEY");
  if (!anonKey) {
    throw new HttpError(500, "missing_env_supabase_anon_key");
  }
  const userClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: req.headers.get("Authorization") ?? ""
      }
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false
    }
  });
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false
    }
  });
  return { admin, userClient };
}
function getBearerToken(req) {
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
async function requireUser(req, userClient) {
  const token = getBearerToken(req);
  const { data, error } = await userClient.auth.getUser(token);
  if (error || !data.user) {
    throw new HttpError(401, "unauthorized");
  }
  return { id: data.user.id, email: data.user.email };
}
async function parseJsonBody(req) {
  const text = await req.text();
  if (!text) {
    return {};
  }
  try {
    return JSON.parse(text);
  } catch {
    throw new HttpError(400, "invalid_json_body");
  }
}
async function sha256Hex(input) {
  const encoded = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}
async function hashJson(value) {
  return sha256Hex(JSON.stringify(value));
}
function ensureObject(value, message = "invalid_object_payload") {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpError(500, message);
  }
  return value;
}
function ensureArrayOfStrings(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((item) => typeof item === "string");
}
function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}
function isoDate(date) {
  return date.toISOString().slice(0, 10);
}
function parseIsoDate(value) {
  return /* @__PURE__ */ new Date(`${value}T00:00:00.000Z`);
}
function addDays(iso, days) {
  const date = parseIsoDate(iso);
  date.setUTCDate(date.getUTCDate() + days);
  return isoDate(date);
}
function addYears(iso, years) {
  const date = parseIsoDate(iso);
  date.setUTCFullYear(date.getUTCFullYear() + years);
  return isoDate(date);
}
function getLocalDateParts(timezone, reference = /* @__PURE__ */ new Date()) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
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
    day
  };
}
function valueMatchesType(value, typeName) {
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
function validateSchemaNode(value, schema, path, errors) {
  const rawType = schema.type;
  const allowedTypes = Array.isArray(rawType) ? rawType.filter((item) => typeof item === "string") : typeof rawType === "string" ? [rawType] : [];
  if (allowedTypes.length > 0 && !allowedTypes.some((typeName) => valueMatchesType(value, typeName))) {
    errors.push(`${path}: expected ${allowedTypes.join("|")}`);
    return;
  }
  if (!value || typeof value !== "object") {
    return;
  }
  if (Array.isArray(value)) {
    const itemSchema = schema.items;
    if (itemSchema && typeof itemSchema === "object" && !Array.isArray(itemSchema)) {
      value.forEach((item, index) => validateSchemaNode(
        item,
        itemSchema,
        `${path}[${index}]`,
        errors
      ));
    }
    return;
  }
  const required = Array.isArray(schema.required) ? schema.required.filter((item) => typeof item === "string") : [];
  const properties = schema.properties && typeof schema.properties === "object" && !Array.isArray(schema.properties) ? schema.properties : {};
  for (const key of required) {
    if (!(key in value)) {
      errors.push(`${path}.${key}: required`);
    }
  }
  for (const [key, childSchema] of Object.entries(properties)) {
    if (key in value && childSchema && typeof childSchema === "object" && !Array.isArray(childSchema)) {
      validateSchemaNode(
        value[key],
        childSchema,
        `${path}.${key}`,
        errors
      );
    }
  }
}
function validateWithSchema(schema, value) {
  if (!schema) {
    return [];
  }
  const errors = [];
  validateSchemaNode(value, schema, "$", errors);
  return errors;
}
async function resolveActivePrompt(admin, promptKey, locale) {
  const { data, error } = await admin.from("prompt_templates").select("*").eq("prompt_key", promptKey).eq("locale", locale).eq("status", "active").maybeSingle();
  if (error) {
    throw new HttpError(500, "prompt_lookup_failed", error);
  }
  if (!data) {
    throw new HttpError(404, "prompt_not_found", { promptKey, locale });
  }
  return data;
}
async function createGenerationRun(admin, payload) {
  const { data, error } = await admin.from("ai_generation_runs").insert(payload).select("id").single();
  if (error || !data) {
    throw new HttpError(500, "generation_run_create_failed", error);
  }
  return data;
}
async function completeGenerationRun(admin, generationRunId, payload) {
  const { error } = await admin.from("ai_generation_runs").update(payload).eq("id", generationRunId);
  if (error) {
    throw new HttpError(500, "generation_run_update_failed", error);
  }
}
function stripCodeFences(text) {
  const trimmed = text.trim();
  if (!trimmed.startsWith("```")) {
    return trimmed;
  }
  return trimmed.replace(/^```[a-zA-Z]*\s*/, "").replace(/\s*```$/, "").trim();
}
async function callGeminiJson(promptTemplate, contextJson) {
  const geminiApiKey = getEnv("GEMINI_API_KEY");
  const renderedPrompt = [
    "[Task Prompt]",
    promptTemplate.task_prompt_template,
    "",
    "[Context JSON]",
    JSON.stringify(contextJson, null, 2),
    "",
    "[Output Schema JSON]",
    JSON.stringify(promptTemplate.output_schema_json ?? {}, null, 2)
  ].join("\n");
  const contextErrors = validateWithSchema(
    promptTemplate.context_schema_json,
    contextJson
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
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: promptTemplate.system_prompt }]
        },
        contents: [
          {
            role: "user",
            parts: [{ text: renderedPrompt }]
          }
        ],
        generationConfig: {
          temperature: promptTemplate.temperature ?? 0.3,
          maxOutputTokens: promptTemplate.max_output_tokens ?? 1024,
          responseMimeType: "application/json"
        }
      })
    }
  );
  const latencyMs = Date.now() - startedAt;
  const rawPayload = await response.json();
  if (!response.ok) {
    throw new HttpError(502, "gemini_provider_error", rawPayload);
  }
  const textOutput = stripCodeFences(
    rawPayload?.candidates?.[0]?.content?.parts?.map((part) => part.text ?? "").join("") ?? ""
  );
  if (!textOutput) {
    throw new HttpError(502, "gemini_empty_output", rawPayload);
  }
  let parsedOutput;
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
    parsedOutput
  );
  if (outputErrors.length > 0) {
    throw new HttpError(502, "schema_validation_failed", outputErrors);
  }
  return {
    parsedOutput,
    rawTextOutput: textOutput,
    latencyMs
  };
}
async function resolvePrimaryProfile(admin, ownerUserId, profileId) {
  if (profileId) {
    const { data, error } = await admin.from("numerology_profiles").select("*").eq("owner_user_id", ownerUserId).eq("id", profileId).is("archived_at", null).maybeSingle();
    if (error) {
      throw new HttpError(500, "profile_lookup_failed", error);
    }
    if (!data) {
      throw new HttpError(404, "profile_not_found");
    }
    return data;
  }
  const { data: primary, error: primaryError } = await admin.from("numerology_profiles").select("*").eq("owner_user_id", ownerUserId).eq("is_primary", true).is("archived_at", null).maybeSingle();
  if (primaryError) {
    throw new HttpError(500, "primary_profile_lookup_failed", primaryError);
  }
  if (primary) {
    return primary;
  }
  const { data: fallback, error: fallbackError } = await admin.from("numerology_profiles").select("*").eq("owner_user_id", ownerUserId).is("archived_at", null).order("created_at", { ascending: true }).limit(1).maybeSingle();
  if (fallbackError) {
    throw new HttpError(500, "fallback_profile_lookup_failed", fallbackError);
  }
  if (!fallback) {
    throw new HttpError(404, "primary_profile_not_found");
  }
  return fallback;
}
async function resolveAppUserProfile(admin, ownerUserId) {
  const { data, error } = await admin.from("user_profiles").select("*").eq("id", ownerUserId).maybeSingle();
  if (error) {
    throw new HttpError(500, "user_profile_lookup_failed", error);
  }
  return data ?? {
    id: ownerUserId,
    locale: DEFAULT_LOCALE,
    timezone: DEFAULT_TIMEZONE
  };
}
async function resolveOwnedThread(admin, ownerUserId, threadId) {
  const { data, error } = await admin.from("ai_threads").select("*").eq("owner_user_id", ownerUserId).eq("id", threadId).maybeSingle();
  if (error) {
    throw new HttpError(500, "thread_lookup_failed", error);
  }
  if (!data) {
    throw new HttpError(404, "thread_not_found");
  }
  return data;
}
async function resolveCurrentSnapshot(admin, ownerUserId, profileId) {
  const { data, error } = await admin.from("numerology_snapshots").select("*").eq("owner_user_id", ownerUserId).eq("numerology_profile_id", profileId).eq("is_current", true).maybeSingle();
  if (error) {
    throw new HttpError(500, "snapshot_lookup_failed", error);
  }
  if (!data) {
    throw new HttpError(404, "snapshot_not_found");
  }
  return data;
}
async function resolveCurrentNarrative(admin, ownerUserId, snapshotId) {
  const { data, error } = await admin.from("numerology_snapshot_narratives").select("*").eq("owner_user_id", ownerUserId).eq("numerology_snapshot_id", snapshotId).eq("is_current", true).maybeSingle();
  if (error) {
    throw new HttpError(500, "narrative_lookup_failed", error);
  }
  return data;
}
async function hasActiveProSubscription(admin, ownerUserId) {
  const { data, error } = await admin.from("subscriptions").select("id, status, expires_at").eq("owner_user_id", ownerUserId).in("status", ["trialing", "active", "grace_period"]).order("created_at", { ascending: false }).limit(20);
  if (error) {
    throw new HttpError(500, "subscription_lookup_failed", error);
  }
  if (!Array.isArray(data) || data.length === 0) {
    return false;
  }
  const nowMs = Date.now();
  return data.some((item) => !item.expires_at || Date.parse(item.expires_at) > nowMs);
}
async function ensureWallet(admin, ownerUserId) {
  const { error } = await admin.from("soul_point_wallets").upsert({ user_id: ownerUserId }, { onConflict: "user_id" });
  if (error) {
    throw new HttpError(500, "wallet_ensure_failed", error);
  }
}
async function getWalletBalance(admin, ownerUserId) {
  await ensureWallet(admin, ownerUserId);
  const { data, error } = await admin.from("soul_point_wallets").select("balance").eq("user_id", ownerUserId).single();
  if (error || !data) {
    throw new HttpError(500, "wallet_lookup_failed", error);
  }
  return Number(data.balance ?? 0);
}
async function spendSoulPoints(admin, ownerUserId, amount, sourceType, metadataJson = {}, sourceRefId) {
  if (amount <= 0) {
    return getWalletBalance(admin, ownerUserId);
  }
  await ensureWallet(admin, ownerUserId);
  const { data, error } = await admin.from("soul_point_wallets").select("balance, lifetime_spent").eq("user_id", ownerUserId).single();
  if (error || !data) {
    throw new HttpError(500, "wallet_update_prepare_failed", error);
  }
  const currentBalance = Number(data.balance ?? 0);
  const lifetimeSpent = Number(data.lifetime_spent ?? 0);
  if (currentBalance < amount) {
    throw new HttpError(402, "insufficient_soul_points", {
      required: amount,
      balance: currentBalance
    });
  }
  const nextBalance = currentBalance - amount;
  const { error: walletError } = await admin.from("soul_point_wallets").update({
    balance: nextBalance,
    lifetime_spent: lifetimeSpent + amount,
    updated_at: (/* @__PURE__ */ new Date()).toISOString()
  }).eq("user_id", ownerUserId);
  if (walletError) {
    throw new HttpError(500, "wallet_spend_failed", walletError);
  }
  const { error: ledgerError } = await admin.from("soul_point_ledger").insert({
    owner_user_id: ownerUserId,
    direction: "debit",
    amount,
    source_type: sourceType,
    source_ref_id: sourceRefId ?? null,
    balance_after: nextBalance,
    metadata_json: metadataJson
  });
  if (ledgerError) {
    throw new HttpError(500, "ledger_spend_failed", ledgerError);
  }
  return nextBalance;
}
async function grantSoulPoints(admin, ownerUserId, amount, sourceType, metadataJson = {}, sourceRefId) {
  if (amount <= 0) {
    return getWalletBalance(admin, ownerUserId);
  }
  await ensureWallet(admin, ownerUserId);
  const { data, error } = await admin.from("soul_point_wallets").select("balance, lifetime_earned").eq("user_id", ownerUserId).single();
  if (error || !data) {
    throw new HttpError(500, "wallet_credit_lookup_failed", error);
  }
  const currentBalance = Number(data.balance ?? 0);
  const lifetimeEarned = Number(data.lifetime_earned ?? 0);
  const nextBalance = currentBalance + amount;
  const { error: walletError } = await admin.from("soul_point_wallets").update({
    balance: nextBalance,
    lifetime_earned: lifetimeEarned + amount,
    updated_at: (/* @__PURE__ */ new Date()).toISOString()
  }).eq("user_id", ownerUserId);
  if (walletError) {
    throw new HttpError(500, "wallet_credit_failed", walletError);
  }
  const { error: ledgerError } = await admin.from("soul_point_ledger").insert({
    owner_user_id: ownerUserId,
    direction: "credit",
    amount,
    source_type: sourceType,
    source_ref_id: sourceRefId ?? null,
    balance_after: nextBalance,
    metadata_json: metadataJson
  });
  if (ledgerError) {
    throw new HttpError(500, "ledger_credit_failed", ledgerError);
  }
  return nextBalance;
}
function buildThreadSummary(existingSummary, userQuestion, answer) {
  const pieces = [
    existingSummary?.trim(),
    `Nguoi dung hoi: ${userQuestion.trim()}`,
    `AI tra loi: ${answer.trim()}`
  ].filter(Boolean);
  const summary = pieces.join(" | ");
  return summary.length <= 800 ? summary : summary.slice(summary.length - 800);
}
function cacheResponse(cacheStatus, data, meta) {
  return {
    ok: true,
    cache_status: cacheStatus,
    data,
    meta
  };
}
var MASTER_NUMBERS = /* @__PURE__ */ new Set([11, 22, 33]);
var VOWELS = /* @__PURE__ */ new Set(["A", "E", "I", "O", "U", "Y"]);
function normalizeName(name) {
  return name.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^A-Za-z]/g, "").toUpperCase();
}
function sumDigits(value) {
  return String(value).replace(/\D/g, "").split("").reduce((sum, digit) => sum + Number(digit), 0);
}
function reduceNumber(value, preserveMasters = true) {
  let current = Math.abs(Math.trunc(value));
  while (current > 9 && !(preserveMasters && MASTER_NUMBERS.has(current))) {
    current = sumDigits(current);
  }
  return current;
}
function letterValue(char) {
  return (char.charCodeAt(0) - 65) % 9 + 1;
}
function intersectNumbers(left, right) {
  const rightSet = new Set(right);
  return left.filter((value) => rightSet.has(value));
}
function buildAxis(key, digits, counts) {
  const totalCount = digits.reduce((sum, digit) => sum + (counts[digit] ?? 0), 0);
  const level = totalCount >= 4 ? "strong" : totalCount >= 2 ? "balanced" : totalCount === 1 ? "developing" : "missing";
  return {
    key,
    digits,
    total_count: totalCount,
    level
  };
}
function computeCoreNumbers(birthDate, fullNameForReading) {
  const normalizedName = normalizeName(fullNameForReading);
  const nameValues = normalizedName.split("").map(letterValue);
  const vowelValues = normalizedName.split("").filter((char) => VOWELS.has(char)).map(letterValue);
  const consonantValues = normalizedName.split("").filter((char) => !VOWELS.has(char)).map(letterValue);
  const [year, month, day] = birthDate.split("-").map(Number);
  const lifePath = reduceNumber(sumDigits(birthDate), true);
  const birthMonth = reduceNumber(month, true);
  const birthDay = reduceNumber(day, true);
  const birthYear = reduceNumber(sumDigits(year), true);
  const expression = reduceNumber(nameValues.reduce((sum, value) => sum + value, 0), true);
  const soulUrge = reduceNumber(vowelValues.reduce((sum, value) => sum + value, 0), true);
  const personality = reduceNumber(
    consonantValues.reduce((sum, value) => sum + value, 0),
    true
  );
  return {
    life_path: { value: lifePath, title: "So chu dao" },
    expression: { value: expression, title: "So bieu dat" },
    soul_urge: { value: soulUrge, title: "So linh hon" },
    personality: { value: personality, title: "So nhan cach" },
    birth_month: { value: birthMonth, title: "Thang sinh rut gon" },
    birth_day: { value: birthDay, title: "Ngay sinh rut gon" },
    birth_year: { value: birthYear, title: "Nam sinh rut gon" }
  };
}
function computeBirthMatrix(birthDate) {
  const counts = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
    7: 0,
    8: 0,
    9: 0
  };
  for (const digit of birthDate.replace(/\D/g, "")) {
    const value = Number(digit);
    if (value >= 1 && value <= 9) {
      counts[value] += 1;
    }
  }
  const strongNumbers = Object.entries(counts).filter(([, count]) => count >= 2).map(([digit]) => Number(digit));
  const weakNumbers = Object.entries(counts).filter(([, count]) => count === 1).map(([digit]) => Number(digit));
  const missingNumbers = Object.entries(counts).filter(([, count]) => count === 0).map(([digit]) => Number(digit));
  return {
    digit_counts: counts,
    grid: [
      [counts[1], counts[4], counts[7]],
      [counts[2], counts[5], counts[8]],
      [counts[3], counts[6], counts[9]]
    ],
    strong_numbers: strongNumbers,
    weak_numbers: weakNumbers,
    missing_numbers: missingNumbers
  };
}
function computeMatrixAspects(birthMatrix) {
  const counts = birthMatrix.digit_counts;
  const axes = {
    physical: buildAxis("physical", [1, 4, 7], counts),
    emotional: buildAxis("emotional", [2, 5, 8], counts),
    intellectual: buildAxis("intellectual", [3, 6, 9], counts)
  };
  const arrowDefinitions = [
    { key: "determination", digits: [1, 5, 9] },
    { key: "sensitivity", digits: [2, 5, 8] },
    { key: "intellect", digits: [3, 6, 9] },
    { key: "practicality", digits: [1, 4, 7] },
    { key: "planning", digits: [1, 2, 3] },
    { key: "willpower", digits: [4, 5, 6] },
    { key: "intuition", digits: [3, 5, 7] },
    { key: "activity", digits: [7, 8, 9] }
  ];
  const arrows = arrowDefinitions.map((arrow) => {
    const presentCount = arrow.digits.filter((digit) => (counts[digit] ?? 0) > 0).length;
    return {
      key: arrow.key,
      digits: arrow.digits,
      status: presentCount === arrow.digits.length ? "present" : presentCount === 0 ? "missing" : "partial",
      present_count: presentCount
    };
  });
  return { axes, arrows };
}
function computeLifeCycles(birthDate, lifePathValue) {
  const [year, month, day] = birthDate.split("-").map(Number);
  const reducedMonth = reduceNumber(month, true);
  const reducedDay = reduceNumber(day, true);
  const reducedYear = reduceNumber(sumDigits(year), true);
  const reducedLifePath = reduceNumber(lifePathValue, false);
  const peak1 = reduceNumber(reducedMonth + reducedDay, true);
  const peak2 = reduceNumber(reducedDay + reducedYear, true);
  const peak3 = reduceNumber(peak1 + peak2, true);
  const peak4 = reduceNumber(reducedMonth + reducedYear, true);
  const challenge1 = reduceNumber(Math.abs(reducedMonth - reducedDay), false);
  const challenge2 = reduceNumber(Math.abs(reducedDay - reducedYear), false);
  const challenge3 = reduceNumber(Math.abs(challenge1 - challenge2), false);
  const challenge4 = reduceNumber(Math.abs(reducedMonth - reducedYear), false);
  const firstEndAge = 36 - reducedLifePath;
  const secondEndAge = firstEndAge + 9;
  const thirdEndAge = secondEndAge + 9;
  const peakAgeWindows = [
    { startAge: 0, endAge: firstEndAge },
    { startAge: firstEndAge + 1, endAge: secondEndAge },
    { startAge: secondEndAge + 1, endAge: thirdEndAge },
    { startAge: thirdEndAge + 1, endAge: null }
  ];
  const challenges = [challenge1, challenge2, challenge3, challenge4];
  const peaks = [peak1, peak2, peak3, peak4];
  const peakItems = peaks.map((value, index) => {
    const window = peakAgeWindows[index];
    const startDate = addYears(birthDate, window.startAge);
    const endDate = window.endAge === null ? null : addDays(addYears(birthDate, window.endAge + 1), -1);
    return {
      index: index + 1,
      value,
      start_age: window.startAge,
      end_age: window.endAge,
      start_date: startDate,
      end_date: endDate
    };
  });
  const challengeItems = challenges.map((value, index) => {
    const window = peakAgeWindows[index];
    const startDate = addYears(birthDate, window.startAge);
    const endDate = window.endAge === null ? null : addDays(addYears(birthDate, window.endAge + 1), -1);
    return {
      index: index + 1,
      value,
      start_age: window.startAge,
      end_age: window.endAge,
      start_date: startDate,
      end_date: endDate
    };
  });
  return {
    peaks: peakItems,
    challenges: challengeItems
  };
}
async function calculateSnapshot(profile) {
  const fullNameForReading = String(profile.full_name_for_reading ?? "");
  const birthDate = String(profile.birth_date ?? "");
  const coreNumbersJson = computeCoreNumbers(birthDate, fullNameForReading);
  const birthMatrixJson = computeBirthMatrix(birthDate);
  const matrixAspectsJson = computeMatrixAspects(birthMatrixJson);
  const lifeCyclesJson = computeLifeCycles(
    birthDate,
    Number(
      coreNumbersJson.life_path.value ?? 0
    )
  );
  const rawInputJson = {
    profile_id: profile.id,
    display_name: profile.display_name,
    full_name_for_reading: fullNameForReading,
    birth_date: birthDate,
    profile_kind: profile.profile_kind,
    relation_kind: profile.relation_kind
  };
  return {
    sourceHash: await sha256Hex(JSON.stringify(rawInputJson)),
    rawInputJson,
    coreNumbersJson,
    birthMatrixJson,
    matrixAspectsJson,
    lifeCyclesJson
  };
}
function findActiveWindow(items, localDate) {
  const active = items.find((item) => {
    const startDate = String(item.start_date);
    const endDate = item.end_date ? String(item.end_date) : null;
    return startDate <= localDate && (!endDate || localDate <= endDate);
  });
  if (active) {
    return active;
  }
  return items[items.length - 1];
}
function calculatePersonalYear(birthDate, targetYear) {
  const [, month, day] = birthDate.split("-").map(Number);
  const universalYear = reduceNumber(sumDigits(targetYear), true);
  return reduceNumber(reduceNumber(month, true) + reduceNumber(day, true) + universalYear, true);
}
function calculatePersonalMonth(personalYear, targetMonth) {
  return reduceNumber(personalYear + targetMonth, true);
}
function calculatePersonalDay(personalMonth, targetDay) {
  return reduceNumber(personalMonth + targetDay, true);
}
function calculateLocalDateContext(profile, snapshot, localDate) {
  const [localYear, localMonth, localDay] = localDate.split("-").map(Number);
  const birthDate = String(profile.birth_date);
  const lifeCycles = snapshot.life_cycles_json;
  const peaks = lifeCycles.peaks ?? [];
  const challenges = lifeCycles.challenges ?? [];
  const activePeak = findActiveWindow(peaks, localDate);
  const activeChallenge = findActiveWindow(challenges, localDate);
  const phaseStartDate = [
    activePeak.start_date ? String(activePeak.start_date) : null,
    activeChallenge.start_date ? String(activeChallenge.start_date) : null
  ].filter(Boolean).sort().at(-1) ?? null;
  const phaseEndCandidates = [
    activePeak.end_date ? String(activePeak.end_date) : null,
    activeChallenge.end_date ? String(activeChallenge.end_date) : null
  ].filter(Boolean).sort();
  const phaseEndDate = phaseEndCandidates.length > 0 ? phaseEndCandidates[0] : null;
  const activePeakNumber = activePeak.value === void 0 || activePeak.value === null ? null : Number(activePeak.value);
  const activeChallengeNumber = activeChallenge.value === void 0 || activeChallenge.value === null ? null : Number(activeChallenge.value);
  const phaseKey = [
    `peak${activePeak.index ?? "x"}`,
    `challenge${activeChallenge.index ?? "x"}`,
    phaseStartDate ?? "open",
    phaseEndDate ?? "open"
  ].join("-");
  const personalYear = calculatePersonalYear(birthDate, localYear);
  const personalMonth = calculatePersonalMonth(personalYear, localMonth);
  const personalDay = calculatePersonalDay(personalMonth, localDay);
  return {
    localDate,
    localYear,
    localMonth,
    localDay,
    personalYear,
    personalMonth,
    personalDay,
    activePeakNumber,
    activeChallengeNumber,
    phaseKey,
    phaseStartDate,
    phaseEndDate
  };
}
function compatibilityDelta(left, right, sameBonus) {
  const rawDiff = Math.abs(left - right);
  const diff = Math.min(rawDiff, 9 - rawDiff);
  if (diff === 0) return sameBonus;
  if (diff === 1) return 6;
  if (diff === 2) return 2;
  if (diff === 3) return -3;
  return -7;
}
function calculateCompatibility(primarySnapshot, targetSnapshot) {
  const primaryCore = primarySnapshot.core_numbers_json;
  const targetCore = targetSnapshot.core_numbers_json;
  const primaryMatrix = primarySnapshot.birth_matrix_json;
  const targetMatrix = targetSnapshot.birth_matrix_json;
  const primaryLifePath = reduceNumber(Number(primaryCore.life_path?.value ?? 0), false);
  const primaryExpression = reduceNumber(Number(primaryCore.expression?.value ?? 0), false);
  const primarySoulUrge = reduceNumber(Number(primaryCore.soul_urge?.value ?? 0), false);
  const primaryPersonality = reduceNumber(Number(primaryCore.personality?.value ?? 0), false);
  const targetLifePath = reduceNumber(Number(targetCore.life_path?.value ?? 0), false);
  const targetExpression = reduceNumber(Number(targetCore.expression?.value ?? 0), false);
  const targetSoulUrge = reduceNumber(Number(targetCore.soul_urge?.value ?? 0), false);
  const targetPersonality = reduceNumber(Number(targetCore.personality?.value ?? 0), false);
  const sharedStrong = intersectNumbers(
    primaryMatrix.strong_numbers ?? [],
    targetMatrix.strong_numbers ?? []
  );
  const sharedMissing = intersectNumbers(
    primaryMatrix.missing_numbers ?? [],
    targetMatrix.missing_numbers ?? []
  );
  let score = 58;
  score += compatibilityDelta(primaryLifePath, targetLifePath, 12);
  score += compatibilityDelta(primaryExpression, targetExpression, 8);
  score += compatibilityDelta(primarySoulUrge, targetSoulUrge, 8);
  score += compatibilityDelta(primaryPersonality, targetPersonality, 6);
  score += sharedStrong.length * 3;
  score -= sharedMissing.length * 2;
  score = clamp(score, 0, 100);
  const compatibilityBand = score >= 80 ? "high" : score >= 65 ? "balanced" : score >= 50 ? "mixed" : "challenging";
  return {
    score,
    compatibilityStructure: {
      compatibility_band: compatibilityBand,
      life_path_pair: [primaryLifePath, targetLifePath],
      expression_pair: [primaryExpression, targetExpression],
      soul_urge_pair: [primarySoulUrge, targetSoulUrge],
      personality_pair: [primaryPersonality, targetPersonality],
      shared_strong_numbers: sharedStrong,
      shared_missing_numbers: sharedMissing,
      signals: [
        compatibilityBand === "high" ? "Hai ho so co nhieu diem hoa hop nen tang truong cung nhau." : compatibilityBand === "balanced" ? "Hai ho so co nen tang tuong doi hop, can duy tri giao tiep ro rang." : compatibilityBand === "mixed" ? "Moi quan he co ca diem hut va diem va cham, can chu dong dieu chinh." : "Cap ho so nay de xuat nhieu bai hoc ve cach thau hieu va ton trong khac biet."
      ]
    }
  };
}
function calculateStreakReward(streakCount) {
  return streakCount > 0 && streakCount % 7 === 0 ? 13 : 3;
}
function calculateAgeOnDate(birthDate, localDate) {
  const birth = parseIsoDate(birthDate);
  const current = parseIsoDate(localDate);
  let age = current.getUTCFullYear() - birth.getUTCFullYear();
  const monthDelta = current.getUTCMonth() - birth.getUTCMonth();
  const dayDelta = current.getUTCDate() - birth.getUTCDate();
  if (monthDelta < 0 || monthDelta === 0 && dayDelta < 0) {
    age -= 1;
  }
  return age;
}
function nowIso() {
  return (/* @__PURE__ */ new Date()).toISOString();
}
async function invalidateProfileCaches(admin, profileId) {
  const deletions = [
    admin.from("daily_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("monthly_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("yearly_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("active_phase_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("compatibility_reports").delete().or(
      `primary_profile_id.eq.${profileId},target_profile_id.eq.${profileId}`
    )
  ];
  const results = await Promise.all(deletions);
  const failed = results.find((result) => result.error);
  if (failed?.error) {
    throw new HttpError(500, "cache_invalidation_failed", failed.error);
  }
}
async function createSnapshotRecord(admin, ownerUserId, profile, snapshotComputation) {
  const { error: clearError } = await admin.from("numerology_snapshots").update({ is_current: false }).eq("numerology_profile_id", profile.id).eq("is_current", true);
  if (clearError) {
    throw new HttpError(500, "snapshot_invalidate_failed", clearError);
  }
  const { data, error } = await admin.from("numerology_snapshots").insert({
    owner_user_id: ownerUserId,
    numerology_profile_id: profile.id,
    engine_version: ENGINE_VERSION,
    source_hash: snapshotComputation.sourceHash,
    is_current: true,
    raw_input_json: snapshotComputation.rawInputJson,
    core_numbers_json: snapshotComputation.coreNumbersJson,
    birth_matrix_json: snapshotComputation.birthMatrixJson,
    matrix_aspects_json: snapshotComputation.matrixAspectsJson,
    life_cycles_json: snapshotComputation.lifeCyclesJson,
    calculated_at: nowIso()
  }).select("*").single();
  if (error || !data) {
    throw new HttpError(500, "snapshot_create_failed", error);
  }
  return data;
}
function buildLifeNarrativeContext(profile, snapshot, locale) {
  return {
    profile: {
      profile_id: profile.id,
      display_name: profile.display_name,
      locale
    },
    snapshot: {
      snapshot_id: snapshot.id,
      core_numbers: snapshot.core_numbers_json,
      birth_matrix: snapshot.birth_matrix_json,
      matrix_aspects: snapshot.matrix_aspects_json,
      life_cycles: snapshot.life_cycles_json
    }
  };
}
async function buildCompactSummary(admin, ownerUserId, snapshotId) {
  const narrative = await resolveCurrentNarrative(admin, ownerUserId, snapshotId);
  if (!narrative) {
    return null;
  }
  const sections = ensureObject(narrative.sections_json, "invalid_sections_json");
  const compactSummary = sections.compact_summary;
  if (!compactSummary || typeof compactSummary !== "object" || Array.isArray(compactSummary)) {
    return null;
  }
  return compactSummary;
}
async function insertDailyReading(admin, payload, profileId, localDate) {
  const { data, error } = await admin.from("daily_readings").insert(payload).select("*").single();
  if (!error && data) {
    return data;
  }
  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin.from("daily_readings").select("*").eq("numerology_profile_id", profileId).eq("local_date", localDate).eq("engine_version", ENGINE_VERSION).single();
    if (existingError || !existing) {
      throw new HttpError(500, "daily_reading_requery_failed", existingError);
    }
    return existing;
  }
  throw new HttpError(500, "daily_reading_insert_failed", error);
}
async function insertMonthlyReading(admin, payload, profileId, localYear, localMonth) {
  const { data, error } = await admin.from("monthly_readings").insert(payload).select("*").single();
  if (!error && data) {
    return data;
  }
  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin.from("monthly_readings").select("*").eq("numerology_profile_id", profileId).eq("local_year", localYear).eq("local_month", localMonth).eq("engine_version", ENGINE_VERSION).single();
    if (existingError || !existing) {
      throw new HttpError(500, "monthly_reading_requery_failed", existingError);
    }
    return existing;
  }
  throw new HttpError(500, "monthly_reading_insert_failed", error);
}
async function insertYearlyReading(admin, payload, profileId, localYear) {
  const { data, error } = await admin.from("yearly_readings").insert(payload).select("*").single();
  if (!error && data) {
    return data;
  }
  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin.from("yearly_readings").select("*").eq("numerology_profile_id", profileId).eq("local_year", localYear).eq("engine_version", ENGINE_VERSION).single();
    if (existingError || !existing) {
      throw new HttpError(500, "yearly_reading_requery_failed", existingError);
    }
    return existing;
  }
  throw new HttpError(500, "yearly_reading_insert_failed", error);
}
async function insertActivePhaseReading(admin, payload, profileId, phaseKey) {
  const { data, error } = await admin.from("active_phase_readings").insert(payload).select("*").single();
  if (!error && data) {
    return data;
  }
  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin.from("active_phase_readings").select("*").eq("numerology_profile_id", profileId).eq("phase_key", phaseKey).eq("engine_version", ENGINE_VERSION).single();
    if (existingError || !existing) {
      throw new HttpError(500, "active_phase_requery_failed", existingError);
    }
    return existing;
  }
  throw new HttpError(500, "active_phase_insert_failed", error);
}
async function insertCompatibilityReport(admin, payload, ownerUserId, primaryProfileId, targetProfileId) {
  const { data, error } = await admin.from("compatibility_reports").insert(payload).select("*").single();
  if (!error && data) {
    return data;
  }
  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin.from("compatibility_reports").select("*").eq("owner_user_id", ownerUserId).eq("primary_profile_id", primaryProfileId).eq("target_profile_id", targetProfileId).eq("engine_version", ENGINE_VERSION).single();
    if (existingError || !existing) {
      throw new HttpError(500, "compatibility_requery_failed", existingError);
    }
    return existing;
  }
  throw new HttpError(500, "compatibility_insert_failed", error);
}
async function handleRecalculateNumerologyProfile(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshotComputation = await calculateSnapshot(profile);
  const snapshot = await createSnapshotRecord(admin, user.id, profile, snapshotComputation);
  await invalidateProfileCaches(admin, String(profile.id));
  return {
    ok: true,
    data: {
      profile_id: profile.id,
      snapshot_id: snapshot.id,
      engine_version: ENGINE_VERSION
    }
  };
}
async function handleGenerateSnapshotNarrative(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  let snapshot;
  let profile;
  if (body.snapshot_id) {
    const { data, error } = await admin.from("numerology_snapshots").select("*, numerology_profiles(*)").eq("owner_user_id", user.id).eq("id", body.snapshot_id).single();
    if (error || !data) {
      throw new HttpError(404, "snapshot_not_found", error);
    }
    snapshot = data;
    profile = ensureObject(snapshot.numerology_profiles, "profile_join_missing");
  } else {
    profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
    snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  }
  const currentNarrative = await resolveCurrentNarrative(admin, user.id, String(snapshot.id));
  if (currentNarrative && !forceRegenerate) {
    return cacheResponse("hit", currentNarrative, {
      prompt_key: "life_snapshot_narrative",
      prompt_version: currentNarrative.prompt_version ?? "unknown",
      engine_version: snapshot.engine_version
    });
  }
  const prompt = await resolveActivePrompt(admin, "life_snapshot_narrative", locale);
  const contextJson = buildLifeNarrativeContext(profile, snapshot, locale);
  const generationRun = await createGenerationRun(admin, {
    owner_user_id: user.id,
    generation_kind: "snapshot_narrative",
    prompt_template_id: prompt.id,
    prompt_key: prompt.prompt_key,
    target_table: "numerology_snapshot_narratives",
    provider: prompt.provider,
    model_name: prompt.model_name,
    prompt_version: prompt.version,
    system_prompt_snapshot: prompt.system_prompt,
    task_prompt_snapshot: prompt.task_prompt_template,
    status: "running",
    input_hash: await hashJson(contextJson),
    input_context_json: contextJson,
    started_at: nowIso()
  });
  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const { error: clearError } = await admin.from("numerology_snapshot_narratives").update({ is_current: false }).eq("numerology_snapshot_id", snapshot.id).eq("is_current", true);
    if (clearError) {
      throw new HttpError(500, "snapshot_narrative_invalidate_failed", clearError);
    }
    const { data, error } = await admin.from("numerology_snapshot_narratives").insert({
      owner_user_id: user.id,
      numerology_snapshot_id: snapshot.id,
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      locale,
      model_provider: prompt.provider,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      status: "succeeded",
      is_current: true,
      sections_json: geminiResult.parsedOutput,
      generated_at: nowIso()
    }).select("*").single();
    if (error || !data) {
      throw new HttpError(500, "snapshot_narrative_insert_failed", error);
    }
    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: data.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso()
    });
    return cacheResponse("miss_generated", data, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: snapshot.engine_version
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso()
    });
    throw error;
  }
}
async function handleGenerateDailyReading(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localDate = body.local_date ?? getLocalDateParts(timezone).localDate;
  const { data: existing, error: existingError } = await admin.from("daily_readings").select("*").eq("numerology_profile_id", profile.id).eq("local_date", localDate).eq("engine_version", ENGINE_VERSION).maybeSingle();
  if (existingError) {
    throw new HttpError(500, "daily_reading_lookup_failed", existingError);
  }
  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "daily_reading_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION
    });
  }
  if (existing && forceRegenerate) {
    const { error } = await admin.from("daily_readings").delete().eq("id", existing.id);
    if (error) {
      throw new HttpError(500, "daily_reading_delete_failed", error);
    }
  }
  const dateContext = calculateLocalDateContext(profile, snapshot, localDate);
  const compactSummary = await buildCompactSummary(admin, user.id, String(snapshot.id));
  const prompt = await resolveActivePrompt(admin, "daily_reading_narrative", locale);
  const contextJson = {
    profile: {
      profile_id: profile.id,
      display_name: profile.display_name,
      locale,
      timezone
    },
    date_context: {
      local_date: dateContext.localDate,
      personal_year: dateContext.personalYear,
      personal_month: dateContext.personalMonth,
      personal_day: dateContext.personalDay,
      active_peak_number: dateContext.activePeakNumber,
      active_challenge_number: dateContext.activeChallengeNumber
    },
    life_summary_compact: compactSummary
  };
  const generationRun = await createGenerationRun(admin, {
    owner_user_id: user.id,
    generation_kind: "daily_reading_narrative",
    prompt_template_id: prompt.id,
    prompt_key: prompt.prompt_key,
    target_table: "daily_readings",
    provider: prompt.provider,
    model_name: prompt.model_name,
    prompt_version: prompt.version,
    system_prompt_snapshot: prompt.system_prompt,
    task_prompt_snapshot: prompt.task_prompt_template,
    status: "running",
    input_hash: await hashJson(contextJson),
    input_context_json: contextJson,
    started_at: nowIso()
  });
  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const output = ensureObject(geminiResult.parsedOutput, "invalid_daily_output");
    const inserted = await insertDailyReading(admin, {
      owner_user_id: user.id,
      numerology_profile_id: profile.id,
      local_date: localDate,
      timezone,
      engine_version: ENGINE_VERSION,
      personal_year: dateContext.personalYear,
      personal_month: dateContext.personalMonth,
      personal_day: dateContext.personalDay,
      active_peak_number: dateContext.activePeakNumber,
      active_challenge_number: dateContext.activeChallengeNumber,
      hero_text: String(output.hero_text ?? ""),
      energy_score: Number(output.energy_score ?? 0),
      daily_rhythm: String(output.daily_rhythm ?? ""),
      daily_insight_short: String(output.daily_insight_short ?? ""),
      daily_insight_full: String(output.daily_insight_full ?? ""),
      action_do_json: output.action_do ?? [],
      action_avoid_json: output.action_avoid ?? [],
      month_context_json: output.month_context ?? {},
      year_context_json: output.year_context ?? {},
      active_phase_json: output.active_phase ?? {
        title: "Giai doan active",
        summary: "Du lieu dang duoc cap nhat."
      },
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      generated_at: nowIso()
    }, String(profile.id), localDate);
    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso()
    });
    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso()
    });
    throw error;
  }
}
async function handleGenerateMonthlyReading(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localParts = getLocalDateParts(timezone);
  const localYear = body.local_year ?? localParts.year;
  const localMonth = body.local_month ?? localParts.month;
  const { data: existing, error: existingError } = await admin.from("monthly_readings").select("*").eq("numerology_profile_id", profile.id).eq("local_year", localYear).eq("local_month", localMonth).eq("engine_version", ENGINE_VERSION).maybeSingle();
  if (existingError) {
    throw new HttpError(500, "monthly_reading_lookup_failed", existingError);
  }
  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "monthly_reading_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION
    });
  }
  if (existing && forceRegenerate) {
    const { error } = await admin.from("monthly_readings").delete().eq("id", existing.id);
    if (error) {
      throw new HttpError(500, "monthly_reading_delete_failed", error);
    }
  }
  const personalYear = calculatePersonalYear(String(profile.birth_date), localYear);
  const personalMonth = calculatePersonalMonth(personalYear, localMonth);
  const compactSummary = await buildCompactSummary(admin, user.id, String(snapshot.id));
  const prompt = await resolveActivePrompt(admin, "monthly_reading_narrative", locale);
  const contextJson = {
    profile: {
      profile_id: profile.id,
      display_name: profile.display_name,
      locale,
      timezone
    },
    month_context: {
      local_year: localYear,
      local_month: localMonth,
      personal_year: personalYear,
      personal_month: personalMonth
    },
    life_summary_compact: compactSummary
  };
  const generationRun = await createGenerationRun(admin, {
    owner_user_id: user.id,
    generation_kind: "monthly_reading_narrative",
    prompt_template_id: prompt.id,
    prompt_key: prompt.prompt_key,
    target_table: "monthly_readings",
    provider: prompt.provider,
    model_name: prompt.model_name,
    prompt_version: prompt.version,
    system_prompt_snapshot: prompt.system_prompt,
    task_prompt_snapshot: prompt.task_prompt_template,
    status: "running",
    input_hash: await hashJson(contextJson),
    input_context_json: contextJson,
    started_at: nowIso()
  });
  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const output = ensureObject(geminiResult.parsedOutput, "invalid_monthly_output");
    const inserted = await insertMonthlyReading(admin, {
      owner_user_id: user.id,
      numerology_profile_id: profile.id,
      local_year: localYear,
      local_month: localMonth,
      timezone,
      engine_version: ENGINE_VERSION,
      personal_year: personalYear,
      personal_month: personalMonth,
      headline: String(output.headline ?? ""),
      summary_text: String(output.summary_text ?? ""),
      focus_text: String(output.focus_text ?? ""),
      opportunities_json: output.opportunities ?? [],
      cautions_json: output.cautions ?? [],
      guidance_json: output.guidance ?? [],
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      generated_at: nowIso()
    }, String(profile.id), localYear, localMonth);
    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso()
    });
    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso()
    });
    throw error;
  }
}
async function handleGenerateYearlyReading(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localYear = body.local_year ?? getLocalDateParts(timezone).year;
  const { data: existing, error: existingError } = await admin.from("yearly_readings").select("*").eq("numerology_profile_id", profile.id).eq("local_year", localYear).eq("engine_version", ENGINE_VERSION).maybeSingle();
  if (existingError) {
    throw new HttpError(500, "yearly_reading_lookup_failed", existingError);
  }
  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "yearly_reading_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION
    });
  }
  if (existing && forceRegenerate) {
    const { error } = await admin.from("yearly_readings").delete().eq("id", existing.id);
    if (error) {
      throw new HttpError(500, "yearly_reading_delete_failed", error);
    }
  }
  const personalYear = calculatePersonalYear(String(profile.birth_date), localYear);
  const compactSummary = await buildCompactSummary(admin, user.id, String(snapshot.id));
  const prompt = await resolveActivePrompt(admin, "yearly_reading_narrative", locale);
  const contextJson = {
    profile: {
      profile_id: profile.id,
      display_name: profile.display_name,
      locale,
      timezone
    },
    year_context: {
      local_year: localYear,
      personal_year: personalYear
    },
    life_summary_compact: compactSummary
  };
  const generationRun = await createGenerationRun(admin, {
    owner_user_id: user.id,
    generation_kind: "yearly_reading_narrative",
    prompt_template_id: prompt.id,
    prompt_key: prompt.prompt_key,
    target_table: "yearly_readings",
    provider: prompt.provider,
    model_name: prompt.model_name,
    prompt_version: prompt.version,
    system_prompt_snapshot: prompt.system_prompt,
    task_prompt_snapshot: prompt.task_prompt_template,
    status: "running",
    input_hash: await hashJson(contextJson),
    input_context_json: contextJson,
    started_at: nowIso()
  });
  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const output = ensureObject(geminiResult.parsedOutput, "invalid_yearly_output");
    const inserted = await insertYearlyReading(admin, {
      owner_user_id: user.id,
      numerology_profile_id: profile.id,
      local_year: localYear,
      timezone,
      engine_version: ENGINE_VERSION,
      personal_year: personalYear,
      headline: String(output.headline ?? ""),
      summary_text: String(output.summary_text ?? ""),
      theme_text: String(output.theme_text ?? ""),
      priorities_json: output.priorities ?? [],
      cautions_json: output.cautions ?? [],
      guidance_json: output.guidance ?? [],
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      generated_at: nowIso()
    }, String(profile.id), localYear);
    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso()
    });
    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso()
    });
    throw error;
  }
}
async function handleGenerateActivePhaseReading(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localDate = getLocalDateParts(timezone).localDate;
  const dateContext = calculateLocalDateContext(profile, snapshot, localDate);
  const phaseKey = body.phase_key ?? dateContext.phaseKey;
  const { data: existing, error: existingError } = await admin.from("active_phase_readings").select("*").eq("numerology_profile_id", profile.id).eq("phase_key", phaseKey).eq("engine_version", ENGINE_VERSION).maybeSingle();
  if (existingError) {
    throw new HttpError(500, "active_phase_lookup_failed", existingError);
  }
  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "active_phase_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION
    });
  }
  if (existing && forceRegenerate) {
    const { error } = await admin.from("active_phase_readings").delete().eq("id", existing.id);
    if (error) {
      throw new HttpError(500, "active_phase_delete_failed", error);
    }
  }
  const compactSummary = await buildCompactSummary(admin, user.id, String(snapshot.id));
  const prompt = await resolveActivePrompt(admin, "active_phase_narrative", locale);
  const contextJson = {
    profile: {
      profile_id: profile.id,
      display_name: profile.display_name,
      locale,
      timezone
    },
    phase_context: {
      phase_key: phaseKey,
      phase_start_date: dateContext.phaseStartDate,
      phase_end_date: dateContext.phaseEndDate,
      active_peak_number: dateContext.activePeakNumber,
      active_challenge_number: dateContext.activeChallengeNumber
    },
    life_summary_compact: compactSummary
  };
  const generationRun = await createGenerationRun(admin, {
    owner_user_id: user.id,
    generation_kind: "active_phase_narrative",
    prompt_template_id: prompt.id,
    prompt_key: prompt.prompt_key,
    target_table: "active_phase_readings",
    provider: prompt.provider,
    model_name: prompt.model_name,
    prompt_version: prompt.version,
    system_prompt_snapshot: prompt.system_prompt,
    task_prompt_snapshot: prompt.task_prompt_template,
    status: "running",
    input_hash: await hashJson(contextJson),
    input_context_json: contextJson,
    started_at: nowIso()
  });
  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const output = ensureObject(geminiResult.parsedOutput, "invalid_active_phase_output");
    const inserted = await insertActivePhaseReading(admin, {
      owner_user_id: user.id,
      numerology_profile_id: profile.id,
      phase_key: phaseKey,
      phase_start_date: dateContext.phaseStartDate,
      phase_end_date: dateContext.phaseEndDate,
      timezone,
      engine_version: ENGINE_VERSION,
      active_peak_number: dateContext.activePeakNumber,
      active_challenge_number: dateContext.activeChallengeNumber,
      headline: String(output.headline ?? ""),
      summary_text: String(output.summary_text ?? ""),
      peak_text: String(output.peak_text ?? ""),
      challenge_text: String(output.challenge_text ?? ""),
      guidance_json: output.guidance ?? [],
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      generated_at: nowIso()
    }, String(profile.id), phaseKey);
    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso()
    });
    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso()
    });
    throw error;
  }
}
async function handleGenerateCompatibilityReport(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  if (!body.target_profile_id) {
    throw new HttpError(400, "target_profile_id_required");
  }
  const primaryProfile = await resolvePrimaryProfile(admin, user.id, body.primary_profile_id);
  const targetProfile = await resolvePrimaryProfile(admin, user.id, body.target_profile_id);
  const primarySnapshot = await resolveCurrentSnapshot(admin, user.id, String(primaryProfile.id));
  const targetSnapshot = await resolveCurrentSnapshot(admin, user.id, String(targetProfile.id));
  const { data: existing, error: existingError } = await admin.from("compatibility_reports").select("*").eq("owner_user_id", user.id).eq("primary_profile_id", primaryProfile.id).eq("target_profile_id", targetProfile.id).eq("engine_version", ENGINE_VERSION).maybeSingle();
  if (existingError) {
    throw new HttpError(500, "compatibility_lookup_failed", existingError);
  }
  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "compatibility_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION
    });
  }
  if (existing && forceRegenerate) {
    const { error } = await admin.from("compatibility_reports").delete().eq("id", existing.id);
    if (error) {
      throw new HttpError(500, "compatibility_delete_failed", error);
    }
  }
  const compatibility = calculateCompatibility(primarySnapshot, targetSnapshot);
  const primarySummary = await buildCompactSummary(admin, user.id, String(primarySnapshot.id));
  const targetSummary = await buildCompactSummary(admin, user.id, String(targetSnapshot.id));
  const prompt = await resolveActivePrompt(admin, "compatibility_narrative", locale);
  const contextJson = {
    primary_profile: {
      profile_id: primaryProfile.id,
      display_name: primaryProfile.display_name
    },
    target_profile: {
      profile_id: targetProfile.id,
      display_name: targetProfile.display_name
    },
    primary_facts: {
      core_numbers: primarySnapshot.core_numbers_json,
      matrix_aspects: primarySnapshot.matrix_aspects_json,
      life_cycles: primarySnapshot.life_cycles_json
    },
    target_facts: {
      core_numbers: targetSnapshot.core_numbers_json,
      matrix_aspects: targetSnapshot.matrix_aspects_json,
      life_cycles: targetSnapshot.life_cycles_json
    },
    compatibility_structure: {
      score: compatibility.score,
      signals: ensureArrayOfStrings(
        compatibility.compatibilityStructure.signals
      )
    },
    primary_life_summary_compact: primarySummary,
    target_life_summary_compact: targetSummary
  };
  const generationRun = await createGenerationRun(admin, {
    owner_user_id: user.id,
    generation_kind: "compatibility_narrative",
    prompt_template_id: prompt.id,
    prompt_key: prompt.prompt_key,
    target_table: "compatibility_reports",
    provider: prompt.provider,
    model_name: prompt.model_name,
    prompt_version: prompt.version,
    system_prompt_snapshot: prompt.system_prompt,
    task_prompt_snapshot: prompt.task_prompt_template,
    status: "running",
    input_hash: await hashJson(contextJson),
    input_context_json: contextJson,
    started_at: nowIso()
  });
  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const output = ensureObject(geminiResult.parsedOutput, "invalid_compatibility_output");
    const inserted = await insertCompatibilityReport(admin, {
      owner_user_id: user.id,
      primary_profile_id: primaryProfile.id,
      target_profile_id: targetProfile.id,
      engine_version: ENGINE_VERSION,
      score: compatibility.score,
      compatibility_structure_json: compatibility.compatibilityStructure,
      summary: String(output.summary ?? ""),
      strengths_json: output.strengths ?? [],
      tensions_json: output.tensions ?? [],
      guidance_json: output.guidance ?? [],
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      calculated_at: nowIso()
    }, user.id, String(primaryProfile.id), String(targetProfile.id));
    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso()
    });
    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso()
    });
    throw error;
  }
}
async function handleSendNumaiMessage(req) {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody(req);
  const messageText = String(body.message_text ?? "").trim();
  if (!messageText) {
    throw new HttpError(400, "message_text_required");
  }
  const locale = body.locale ?? DEFAULT_LOCALE;
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  let thread;
  if (body.thread_id) {
    thread = await resolveOwnedThread(admin, user.id, body.thread_id);
  } else {
    const primaryProfile = await resolvePrimaryProfile(admin, user.id, body.primary_profile_id);
    const relatedProfileId = body.related_profile_id ? String((await resolvePrimaryProfile(admin, user.id, body.related_profile_id)).id) : null;
    const { data, error } = await admin.from("ai_threads").insert({
      owner_user_id: user.id,
      primary_profile_id: primaryProfile.id,
      related_profile_id: relatedProfileId,
      title: messageText.slice(0, 48),
      last_message_at: nowIso()
    }).select("*").single();
    if (error || !data) {
      throw new HttpError(500, "thread_create_failed", error);
    }
    thread = data;
  }
  const activeProfile = await resolvePrimaryProfile(
    admin,
    user.id,
    String(thread.primary_profile_id)
  );
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(activeProfile.id));
  const hasPro = await hasActiveProSubscription(admin, user.id);
  if (!hasPro) {
    const { data: walletData, error: walletError } = await admin.from("soul_point_wallets").select("balance").eq("user_id", user.id).maybeSingle();
    if (walletError) {
      throw new HttpError(500, "wallet_lookup_failed", walletError);
    }
    const balance = Number(walletData?.balance ?? 0);
    if (balance < NUMAI_SOUL_POINT_COST) {
      throw new HttpError(402, "insufficient_soul_points", {
        required: NUMAI_SOUL_POINT_COST,
        balance
      });
    }
  }
  const { data: userMessage, error: userMessageError } = await admin.from("ai_messages").insert({
    owner_user_id: user.id,
    thread_id: thread.id,
    sender_type: "user",
    message_text: messageText,
    context_snapshot_id: snapshot.id,
    soul_point_cost: hasPro ? 0 : NUMAI_SOUL_POINT_COST,
  }).select("*").single();
  if (userMessageError || !userMessage) {
    throw new HttpError(500, "user_message_insert_failed", userMessageError);
  }
  let charged = false;
  if (!hasPro) {
    await spendSoulPoints(
      admin,
      user.id,
      NUMAI_SOUL_POINT_COST,
      "numai_message",
      { thread_id: thread.id, message_id: userMessage.id },
      String(userMessage.id)
    );
    charged = true;
  }
  const { data: recentMessages, error: recentMessagesError } = await admin.from("ai_messages").select("sender_type, message_text, created_at").eq("thread_id", thread.id).order("created_at", { ascending: false }).limit(20);
  if (recentMessagesError) {
    if (charged) {
      await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        { reason: "numai_message_failed", message_id: userMessage.id },
        String(userMessage.id)
      );
    }
    throw new HttpError(500, "recent_messages_lookup_failed", recentMessagesError);
  }
  const prompt = await resolveActivePrompt(admin, "numai_chat_reply", locale);
  const contextJson = {
    thread_summary: {
      summary: String(thread.thread_summary ?? ""),
      updated_at: thread.thread_summary_updated_at ?? null
    },
    recent_messages: (recentMessages ?? []).slice().reverse().map((message) => ({
      role: message.sender_type,
      text: message.message_text
    })),
    active_profile: {
      profile_id: activeProfile.id,
      display_name: activeProfile.display_name,
      profile_kind: activeProfile.profile_kind,
      relation_kind: activeProfile.relation_kind,
      timezone: appUserProfile.timezone ?? DEFAULT_TIMEZONE
    },
    snapshot_facts: {
      core_numbers: snapshot.core_numbers_json,
      birth_matrix: snapshot.birth_matrix_json,
      matrix_aspects: snapshot.matrix_aspects_json,
      life_cycles: snapshot.life_cycles_json
    },
    user_question: messageText
  };
  const generationRun = await createGenerationRun(admin, {
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
    started_at: nowIso()
  });
  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const output = ensureObject(geminiResult.parsedOutput, "invalid_numai_output");
    const { data: assistantMessage, error: assistantError } = await admin.from("ai_messages").insert({
      owner_user_id: user.id,
      thread_id: thread.id,
      sender_type: "assistant",
      message_text: String(output.answer ?? ""),
      context_snapshot_id: snapshot.id,
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      soul_point_cost: 0,
      metadata_json: {
        referenced_sections: output.referenced_sections ?? [],
        follow_up_suggestions: output.follow_up_suggestions ?? [],
        model_name: prompt.model_name,
        prompt_version: prompt.version
      }
    }).select("*").single();
    if (assistantError || !assistantMessage) {
      throw new HttpError(500, "assistant_message_insert_failed", assistantError);
    }
    const { error: threadUpdateError } = await admin.from("ai_threads").update({
      last_message_at: nowIso(),
      updated_at: nowIso(),
      thread_summary: buildThreadSummary(
        String(thread.thread_summary ?? ""),
        messageText,
        String(output.answer ?? "")
      ),
      thread_summary_updated_at: nowIso()
    }).eq("id", thread.id);
    if (threadUpdateError) {
      throw new HttpError(500, "thread_update_failed", threadUpdateError);
    }
    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: assistantMessage.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso()
    });
    return {
      ok: true,
      data: {
        thread_id: thread.id,
        user_message: userMessage,
        assistant_message: assistantMessage,
        charged_soul_points: charged ? NUMAI_SOUL_POINT_COST : 0
      },
      meta: {
        prompt_key: prompt.prompt_key,
        prompt_version: prompt.version,
        engine_version: ENGINE_VERSION
      }
    };
  } catch (error) {
    if (charged) {
      await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        { reason: "numai_generation_refund", message_id: userMessage.id },
        String(userMessage.id)
      );
    }
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso()
    });
    throw error;
  }
}
var handlerMap = {
  "recalculate-numerology-profile": handleRecalculateNumerologyProfile,
  "generate-snapshot-narrative": handleGenerateSnapshotNarrative,
  "generate-daily-reading": handleGenerateDailyReading,
  "generate-monthly-reading": handleGenerateMonthlyReading,
  "generate-yearly-reading": handleGenerateYearlyReading,
  "generate-active-phase-reading": handleGenerateActivePhaseReading,
  "generate-compatibility-report": handleGenerateCompatibilityReport,
  "send-numai-message": handleSendNumaiMessage
};
async function routeRequest(req) {
  const url = new URL(req.url);
  const action = url.searchParams.get("action") ?? req.headers.get("x-numverse-action");
  if (!action) {
    throw new HttpError(400, "missing_action", {
      allowed_actions: Object.keys(handlerMap)
    });
  }
  const handler = handlerMap[action];
  if (!handler) {
    throw new HttpError(404, "unknown_action", {
      action,
      allowed_actions: Object.keys(handlerMap)
    });
  }
  return handler(req);
}
Deno.serve(serveHandler(routeRequest));
export {
  DEFAULT_LOCALE,
  DEFAULT_TIMEZONE,
  ENGINE_VERSION,
  HttpError,
  NUMAI_SOUL_POINT_COST,
  addDays,
  addYears,
  buildThreadSummary,
  cacheResponse,
  calculateAgeOnDate,
  calculateCompatibility,
  calculateLocalDateContext,
  calculatePersonalDay,
  calculatePersonalMonth,
  calculatePersonalYear,
  calculateSnapshot,
  calculateStreakReward,
  callGeminiJson,
  clamp,
  completeGenerationRun,
  createClients,
  createGenerationRun,
  ensureArrayOfStrings,
  ensureObject,
  ensureWallet,
  errorResponse,
  getBearerToken,
  getEnv,
  getLocalDateParts,
  getWalletBalance,
  grantSoulPoints,
  handleGenerateActivePhaseReading,
  handleGenerateCompatibilityReport,
  handleGenerateDailyReading,
  handleGenerateMonthlyReading,
  handleGenerateSnapshotNarrative,
  handleGenerateYearlyReading,
  handleRecalculateNumerologyProfile,
  handleSendNumaiMessage,
  hasActiveProSubscription,
  hashJson,
  isoDate,
  jsonResponse,
  parseIsoDate,
  parseJsonBody,
  requireUser,
  resolveActivePrompt,
  resolveAppUserProfile,
  resolveCurrentNarrative,
  resolveCurrentSnapshot,
  resolveOwnedThread,
  resolvePrimaryProfile,
  serveHandler,
  sha256Hex,
  spendSoulPoints,
  validateWithSchema
};
