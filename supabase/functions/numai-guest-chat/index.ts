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
const NUMAI_SOUL_POINT_COST = Number(
  Deno.env.get("NUMAI_SOUL_POINT_COST") ?? "10",
);
const DEFAULT_GUEST_MODEL = Deno.env.get("NUMAI_GUEST_MODEL") ??
  "gemini-2.5-flash-lite";
const NUMAI_RECENT_MESSAGES_LIMIT = 4;

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

function recoverAnswerFromInvalidJson(rawText: string): string {
  const answerMatch = rawText.match(/"answer"\s*:\s*"([\s\S]*)/);
  if (answerMatch && answerMatch[1]) {
    return answerMatch[1]
      .replace(/\\n/g, "\n")
      .replace(/\\"/g, '"')
      .replace(/\s*[,}]\s*$/, "")
      .trim();
  }

  return rawText
    .replace(/^\{+/, "")
    .replace(/\}+$/, "")
    .replace(/^"+|"+$/g, "")
    .trim();
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

async function callGuestGeminiJson(
  messageText: string,
  locale: string,
  recentMessages: GuestRecentMessage[],
): Promise<{ parsedOutput: JsonObject; rawTextOutput: string }> {
  const geminiApiKey = getEnv("GEMINI_API_KEY");
  const contextJson: JsonObject = {
    mode: "guest_no_profile",
    locale,
    recent_messages: recentMessages,
    user_question: messageText,
  };

  const systemPrompt = locale.toLowerCase().startsWith("vi")
    ? "Bạn là NumAI assistant cho user chưa tạo profile. Trả lời ngắn gọn, hữu ích, thực tế, không phán xét, không hứa hẹn cực đoan. Luôn trả về JSON hợp lệ."
    : "You are NumAI assistant for users without a profile. Be concise, useful, practical, and non-judgmental. Always return valid JSON.";
  const taskPrompt = locale.toLowerCase().startsWith("vi")
    ? 'Trả về JSON với shape:\n{\n  "answer": string,\n  "suggestions": string[3],\n  "referenced_sections": string[]\n}\n\nYêu cầu:\n- answer tập trung trả lời đúng câu hỏi hiện tại.\n- suggestions phải có đúng 3 gợi ý câu hỏi tiếp theo.\n- referenced_sections ghi các phần đã dùng, ví dụ: recent_messages, user_question.\n- Không bao markdown, không dùng ```.'
    : 'Return JSON with shape:\n{\n  "answer": string,\n  "suggestions": string[3],\n  "referenced_sections": string[]\n}\n\nRequirements:\n- answer focuses on the user\'s latest question.\n- suggestions must include exactly 3 follow-up questions.\n- referenced_sections can include recent_messages and user_question.\n- No markdown wrapper, no ```.';

  const renderedPrompt = [
    "[Task Prompt]",
    taskPrompt,
    "",
    "[Context JSON]",
    JSON.stringify(contextJson, null, 2),
  ].join("\n");

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${DEFAULT_GUEST_MODEL}:generateContent?key=${geminiApiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: systemPrompt }],
        },
        contents: [
          {
            role: "user",
            parts: [{ text: renderedPrompt }],
          },
        ],
        generationConfig: {
          temperature: 0.4,
          maxOutputTokens: 700,
          responseMimeType: "application/json",
        },
      }),
    },
  );
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
    const parsedOutput = ensureObject(
      JSON.parse(textOutput),
      "invalid_json_output",
    );
    return {
      parsedOutput,
      rawTextOutput: textOutput,
    };
  } catch (error) {
    const fallbackAnswer = recoverAnswerFromInvalidJson(textOutput);
    if (!fallbackAnswer) {
      if (error instanceof HttpError) {
        throw error;
      }
      throw new HttpError(502, "invalid_json_output", { textOutput });
    }

    return {
      parsedOutput: {
        answer: fallbackAnswer,
        referenced_sections: [],
        suggestions: [],
      },
      rawTextOutput: textOutput,
    };
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

    const geminiResult = await callGuestGeminiJson(
      messageText,
      locale,
      recentMessages,
    );
    const output = ensureObject(
      geminiResult.parsedOutput,
      "invalid_numai_output",
    );
    const answer = String(output.answer ?? "").trim();
    if (!answer) {
      throw new HttpError(502, "numai_empty_answer");
    }

    const suggestions = resolveFollowUpSuggestions(output, locale);
    return {
      ok: true,
      data: {
        thread_id: "",
        assistant_message: {
          message_text: answer,
          metadata_json: {
            follow_up_suggestions: suggestions,
            model_name: DEFAULT_GUEST_MODEL,
            mode: "guest_no_profile",
          },
        },
        charged_soul_points: NUMAI_SOUL_POINT_COST,
        wallet_balance: walletBalanceAfterCharge,
        assistant_suggestions: suggestions,
      },
      meta: {
        model_name: DEFAULT_GUEST_MODEL,
        raw_output: geminiResult.rawTextOutput,
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
          reason: "guest_numai_generation_refund",
          request_ref: requestRef,
        },
        requestRef,
      );
    }
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
    console.error(error);
    return errorResponse(error);
  }
});
