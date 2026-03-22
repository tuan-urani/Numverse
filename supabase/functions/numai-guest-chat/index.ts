import { createClient } from "npm:@supabase/supabase-js@2";

type SupabaseClient = ReturnType<typeof createClient<any>>;
type JsonObject = Record<string, unknown>;

type GuestRecentMessage = {
  role: "user" | "assistant";
  text: string;
};

class HttpError extends Error {
  status: number;
  details?: unknown;

  constructor(status: number, message: string, details?: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

const DEFAULT_LOCALE = "vi-VN";
const NUMAI_SOUL_POINT_COST = 3;
const DEFAULT_GUEST_MODEL = Deno.env.get("NUMAI_GUEST_MODEL") ??
  "gpt-5-nano";
const NUMAI_RECENT_MESSAGES_LIMIT = 4;
const NUMAI_MAX_OUTPUT_TOKENS = 1000;
const NUMAI_OPENAI_REASONING_EFFORT = "low";
const NUMAI_TECHNICAL_FALLBACK_MESSAGE =
  "Oops, hệ thống đang gặp trục trặc nhỏ khi xử lý dữ liệu. Bạn thử lại ngay nhé.";
const NUMAI_OUT_OF_SCOPE_FALLBACK_MESSAGE =
  "Mình chỉ hỗ trợ về thần số học.\nBạn có thể hỏi về con số, năm cá nhân hoặc ý nghĩa cuộc đời.";
const NUMAI_TECHNICAL_ERROR_CODES = new Set<string>([
  "openai_provider_error",
  "openai_empty_output",
  "openai_timeout",
  "invalid_json_output",
  "invalid_numai_output",
  "numai_empty_answer",
  "missing_env_openai_api_key",
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

function extractOpenAiOutputText(rawPayload: unknown): string {
  const payload = asObject(rawPayload);
  if (!payload) {
    return "";
  }

  const directOutputText = payload.output_text;
  if (typeof directOutputText === "string" && directOutputText.trim().length > 0) {
    return directOutputText.trim();
  }

  const outputItems = payload.output;
  if (!Array.isArray(outputItems)) {
    return "";
  }

  const chunks: string[] = [];
  for (const outputItem of outputItems) {
    const outputObject = asObject(outputItem);
    if (!outputObject) {
      continue;
    }

    const contentItems = outputObject.content;
    if (!Array.isArray(contentItems)) {
      continue;
    }

    for (const contentItem of contentItems) {
      const contentObject = asObject(contentItem);
      if (!contentObject) {
        continue;
      }
      if (contentObject.type !== "output_text") {
        continue;
      }

      const textChunk = typeof contentObject.text === "string"
        ? contentObject.text.trim()
        : "";
      if (textChunk.length > 0) {
        chunks.push(textChunk);
      }
    }
  }

  return chunks.join("\n").trim();
}

function logStructuredError(functionName: string, error: unknown): void {
  const payload: JsonObject = {
    function: functionName,
    error_code: resolveErrorCode(error),
  };
  if (error instanceof Error && error.stack) {
    payload.stack = error.stack;
  }
  console.error(JSON.stringify(payload));
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

function strictBooleanFlag(value: unknown): boolean {
  return typeof value === "boolean" ? value : false;
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

function fallbackFollowUpSuggestions(locale: string): string[] {
  const isVietnamese = locale.toLowerCase().startsWith("vi");
  if (isVietnamese) {
    return [
      "Bạn muốn mình tóm tắt điểm mạnh nổi bật của bạn không?",
      "Mình có thể gợi ý 3 việc nên ưu tiên trong hôm nay.",
      "Bạn muốn đi sâu vào tình cảm, công việc hay tài chính?",
    ];
  }

  return [
    "Do you want a quick summary of your core strengths?",
    "I can suggest 3 priorities for today.",
    "Would you like to dive into love, work, or finances?",
  ];
}

function resolveFollowUpSuggestions(
  output: JsonObject,
  locale: string,
): string[] {
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

function sanitizeRecentMessages(raw: unknown): GuestRecentMessage[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  const sanitized: GuestRecentMessage[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object" || Array.isArray(item)) {
      continue;
    }

    const payload = item as JsonObject;
    const roleCandidate = String(payload.role ?? "").trim().toLowerCase();
    const role: "user" | "assistant" = roleCandidate === "assistant"
      ? "assistant"
      : "user";
    const text = String(payload.text ?? "").trim();
    if (!text) {
      continue;
    }

    sanitized.push({ role, text });
  }

  if (sanitized.length <= NUMAI_RECENT_MESSAGES_LIMIT) {
    return sanitized;
  }
  return sanitized.slice(
    sanitized.length - NUMAI_RECENT_MESSAGES_LIMIT,
  );
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

async function callGuestOpenAiJson(
  messageText: string,
  locale: string,
  recentMessages: GuestRecentMessage[],
): Promise<{
  parsedOutput: JsonObject;
  rawTextOutput: string;
}> {
  const openAiApiKey = getEnv("OPENAI_API_KEY");
  const contextJson: JsonObject = {
    mode: "guest_no_profile",
    locale,
    recent_messages: recentMessages,
    user_question: messageText,
  };

  const systemPrompt = locale.toLowerCase().startsWith("vi")
    ? "Bạn là NumAI assistant - chuyên gia thần số học cho user chưa tạo profile. Trả lời ngắn gọn, hữu ích, thực tế, không phán xét, không hứa hẹn cực đoan. Luôn trả về JSON hợp lệ."
    : "You are NumAI assistant for users without a profile. Be concise, useful, practical, and non-judgmental. Always return valid JSON.";
  const taskPrompt = locale.toLowerCase().startsWith("vi")
    ? 'Trả về JSON với shape:\n{\n  "answer": string,\n  "suggestions": string[3],\n  "referenced_sections": string[],\n  "is_out_of_scope": boolean,\n  "requires_profile_info": boolean\n}\n\nYêu cầu:\n- answer tập trung trả lời đúng câu hỏi hiện tại.\n- suggestions phải có đúng 3 gợi ý câu hỏi tiếp theo.\n- referenced_sections ghi các phần đã dùng, ví dụ: recent_messages, user_question.\n- is_out_of_scope = true nếu câu hỏi nằm ngoài thần số học; ngược lại là false.\n- requires_profile_info = true chỉ khi câu hỏi thuộc thần số học cá nhân nhưng thiếu dữ liệu profile (tên/ngày sinh) để cá nhân hóa cho guest chưa có profile.\n- Nếu is_out_of_scope = true thì requires_profile_info phải là false.\n- Không bao markdown, không dùng ```.'
    : 'Return JSON with shape:\n{\n  "answer": string,\n  "suggestions": string[3],\n  "referenced_sections": string[],\n  "is_out_of_scope": boolean,\n  "requires_profile_info": boolean\n}\n\nRequirements:\n- answer focuses on the user\'s latest question.\n- suggestions must include exactly 3 follow-up questions.\n- referenced_sections can include recent_messages and user_question.\n- is_out_of_scope must be true when the question is outside numerology; otherwise false.\n- requires_profile_info must be true only when the question is personal numerology and needs missing profile data (name/date of birth) for a guest without a profile.\n- If is_out_of_scope is true, requires_profile_info must be false.\n- No markdown wrapper, no ```.';

  const renderedPrompt = [
    "[Task Prompt]",
    taskPrompt,
    "",
    "[Context JSON]",
    JSON.stringify(contextJson, null, 2),
  ].join("\n");

  const openAiTimeoutMs = 30_000;
  const timeoutController = new AbortController();
  let didTimeout = false;
  const timeoutHandle = setTimeout(() => {
    didTimeout = true;
    timeoutController.abort();
  }, openAiTimeoutMs);

  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify({
        model: DEFAULT_GUEST_MODEL,
        input: [
          {
            role: "system",
            content: [
              {
                type: "input_text",
                text: systemPrompt,
              },
            ],
          },
          {
            role: "user",
            content: [
              {
                type: "input_text",
                text: renderedPrompt,
              },
            ],
          },
        ],
        text: {
          format: {
            type: "json_object",
          },
        },
        reasoning: {
          effort: NUMAI_OPENAI_REASONING_EFFORT,
        },
        max_output_tokens: NUMAI_MAX_OUTPUT_TOKENS,
      }),
      signal: timeoutController.signal,
    });
  } catch (error) {
    if (didTimeout) {
      throw new HttpError(504, "openai_timeout");
    }
    throw new HttpError(502, "openai_provider_error");
  } finally {
    clearTimeout(timeoutHandle);
  }
  
  const rawPayload = await response.json();

  console.log("OpenAI JSON response:", rawPayload);

  const textOutput = stripCodeFences(extractOpenAiOutputText(rawPayload));
  console.log(
    JSON.stringify({
      event: "numai_guest_openai_fetch_response",
      model: DEFAULT_GUEST_MODEL,
      http_status: response.status,
      response_ok: response.ok,
      raw_payload: rawPayload,
    }),
  );
  console.log(
    JSON.stringify({
      event: "numai_guest_openai_extract_result",
      extracted_text_length: textOutput.length,
      extracted_text: textOutput,
      is_empty: textOutput.length === 0,
    }),
  );

  if (!response.ok) {
    throw new HttpError(502, "openai_provider_error");
  }

  if (!textOutput) {
    throw new HttpError(502, "openai_empty_output");
  }

  try {
    const parsedOutput = ensureObject(
      JSON.parse(textOutput),
      "invalid_json_output",
    );
    console.log(
      JSON.stringify({
        event: "numai_guest_openai_parse_result",
        parse_ok: true,
        parsed_keys: Object.keys(parsedOutput),
      }),
    );
    return {
      parsedOutput,
      rawTextOutput: textOutput,
    };
  } catch (error) {
    console.error(
      JSON.stringify({
        event: "numai_guest_openai_parse_result",
        parse_ok: false,
        parse_error: error instanceof Error
          ? error.message
          : "unknown_parse_error",
        extracted_text: textOutput,
      }),
    );
    if (error instanceof HttpError) {
      throw error;
    }
    throw new HttpError(502, "invalid_json_output");
  }
}

async function handleGuestChat(req: Request): Promise<JsonObject> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);

  const body = await parseJsonBody<{
    message_text?: string;
    locale?: string;
    recent_messages?: unknown;
  }>(req);

  const messageText = String(body.message_text ?? "").trim();
  if (!messageText) {
    throw new HttpError(400, "message_text_required");
  }

  const locale = String(body.locale ?? DEFAULT_LOCALE).trim() || DEFAULT_LOCALE;
  const recentMessages = sanitizeRecentMessages(body.recent_messages);
  const requestRef = `guest_numai:${Date.now()}`;

  const currentBalance = await getWalletBalance(admin, user.id);
  if (currentBalance < NUMAI_SOUL_POINT_COST) {
    throw new HttpError(402, "insufficient_soul_points", {
      required: NUMAI_SOUL_POINT_COST,
      balance: currentBalance,
    });
  }

  let charged = false;
  let walletBalanceAfterCharge = currentBalance;

  try {
    walletBalanceAfterCharge = await spendSoulPoints(
      admin,
      user.id,
      NUMAI_SOUL_POINT_COST,
      "numai_message",
      {
        mode: "guest_no_profile",
      },
      requestRef,
    );
    charged = true;

    let answer = "";
    let suggestions: string[] = [];
    let fallbackReason: "technical_error" | "out_of_scope" | null = null;
    let originalErrorCode: string | null = null;
    let rawOutput: string | null = null;
    let requiresProfileInfo = false;

    try {
      const openAiResult = await callGuestOpenAiJson(
        messageText,
        locale,
        recentMessages,
      );
      rawOutput = openAiResult.rawTextOutput;
      const output = ensureObject(
        openAiResult.parsedOutput,
        "invalid_numai_output",
      );
      if (isTruthyFlag(output.is_out_of_scope)) {
        fallbackReason = "out_of_scope";
        answer = NUMAI_OUT_OF_SCOPE_FALLBACK_MESSAGE;
        suggestions = fallbackFollowUpSuggestions(locale);
        requiresProfileInfo = false;
      } else {
        const resolvedAnswer = String(output.answer ?? "").trim();
        if (!resolvedAnswer) {
          throw new HttpError(502, "numai_empty_answer");
        }
        answer = resolvedAnswer;
        suggestions = resolveFollowUpSuggestions(output, locale);
        requiresProfileInfo = strictBooleanFlag(output.requires_profile_info);
      }
    } catch (error) {
      if (!isNumAiTechnicalError(error)) {
        throw error;
      }
      fallbackReason = "technical_error";
      originalErrorCode = resolveErrorCode(error);
      logStructuredError("numai-guest-chat:handleGuestChat:technical_fallback", error);
      answer = NUMAI_TECHNICAL_FALLBACK_MESSAGE;
      suggestions = fallbackFollowUpSuggestions(locale);
      requiresProfileInfo = false;
    }

    if (fallbackReason === "technical_error" && charged) {
      const refundMetadata: JsonObject = {
        reason: "guest_numai_generation_refund",
        request_ref: requestRef,
        refund_type: fallbackReason,
        original_error_code: originalErrorCode,
      };
      walletBalanceAfterCharge = await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        refundMetadata,
        requestRef,
      );
      charged = false;
    }

    const metadataJson: JsonObject = {
      follow_up_suggestions: suggestions,
      model_name: DEFAULT_GUEST_MODEL,
      mode: "guest_no_profile",
      requires_profile_info: requiresProfileInfo,
    };
    if (fallbackReason) {
      metadataJson.fallback_reason = fallbackReason;
    }
    if (originalErrorCode) {
      metadataJson.original_error_code = originalErrorCode;
    }

    return {
      ok: true,
      data: {
        thread_id: "",
        assistant_message: {
          message_text: answer,
          metadata_json: metadataJson,
        },
        charged_soul_points: charged ? NUMAI_SOUL_POINT_COST : 0,
        wallet_balance: walletBalanceAfterCharge,
        assistant_suggestions: suggestions,
      },
      meta: {
        model_name: DEFAULT_GUEST_MODEL,
        raw_output: rawOutput,
      },
    };
  } catch (error) {
    if (charged) {
      const refundMetadata: JsonObject = {
        reason: "guest_numai_generation_refund",
        request_ref: requestRef,
        original_error_code: resolveErrorCode(error),
      };
      await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        refundMetadata,
        requestRef,
      );
    }
    logStructuredError("numai-guest-chat:handleGuestChat:unhandled", error);
    throw error;
  }
}

async function routeRequest(req: Request): Promise<Response | JsonObject> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    throw new HttpError(405, "method_not_allowed");
  }

  return handleGuestChat(req);
}

Deno.serve(async (req: Request) => {
  try {
    const result = await routeRequest(req);
    if (result instanceof Response) {
      return result;
    }
    return jsonResponse(result);
  } catch (error) {
    logStructuredError("numai-guest-chat:route", error);
    return errorResponse(error);
  }
});
