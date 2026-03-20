import { createClient } from "npm:@supabase/supabase-js@2";

type SupabaseClient = ReturnType<typeof createClient<any>>;
type JsonObject = Record<string, unknown>;

class HttpError extends Error {
  status: number;
  details?: unknown;

  constructor(status: number, message: string, details?: unknown) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

type ImportableGuestMessage = {
  localId: string;
  senderType: "user" | "assistant" | "system";
  messageText: string;
  createdAt: string;
  followUpSuggestions: string[];
  requiresProfileInfo: boolean;
};

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

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
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

function strictBooleanFlag(value: unknown): boolean {
  return typeof value === "boolean" ? value : false;
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
): Promise<{ id: string }> {
  const token = getBearerToken(req);
  const { data, error } = await userClient.auth.getUser(token);

  if (error || !data.user) {
    throw new HttpError(401, "unauthorized");
  }

  return { id: data.user.id };
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

function sanitizeGuestMessagesForImport(
  rawMessages: unknown,
): ImportableGuestMessage[] {
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

    const senderCandidate = String(payload.sender_type ?? "user").trim()
      .toLowerCase();
    const senderType: "user" | "assistant" | "system" =
      senderCandidate === "assistant" || senderCandidate === "system"
        ? senderCandidate
        : "user";

    const createdAtCandidate = String(payload.created_at ?? "").trim();
    const createdAtMillis = Date.parse(createdAtCandidate);
    const createdAt = Number.isNaN(createdAtMillis)
      ? new Date(fallbackStartedAt + index).toISOString()
      : new Date(createdAtMillis).toISOString();

    const localIdCandidate = String(payload.local_id ?? payload.id ?? "")
      .trim();
    const localId = localIdCandidate || `guest-local-${createdAt}-${index}`;

    sanitized.push({
      localId,
      senderType,
      messageText,
      createdAt,
      followUpSuggestions: ensureArrayOfStrings(payload.follow_up_suggestions),
      requiresProfileInfo: strictBooleanFlag(payload.requires_profile_info),
    });
  }

  sanitized.sort((left, right) =>
    left.createdAt.localeCompare(right.createdAt)
  );
  return sanitized;
}

async function findThreadForProfile(
  admin: SupabaseClient,
  ownerUserId: string,
  primaryProfileId: string,
): Promise<JsonObject | null> {
  const { data, error } = await admin
    .from("ai_threads")
    .select("*")
    .eq("owner_user_id", ownerUserId)
    .eq("primary_profile_id", primaryProfileId)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "thread_lookup_failed", error);
  }

  return (data as JsonObject | null) ?? null;
}

async function createThreadForProfile(
  admin: SupabaseClient,
  ownerUserId: string,
  primaryProfileId: string,
  title: string,
): Promise<JsonObject> {
  const { data, error } = await admin
    .from("ai_threads")
    .insert({
      owner_user_id: ownerUserId,
      primary_profile_id: primaryProfileId,
      title: title.slice(0, 48),
      last_message_at: nowIso(),
    })
    .select("*")
    .single();

  if (!error && data) {
    return data as JsonObject;
  }

  const errorCode = String((error as { code?: string } | null)?.code ?? "");
  if (errorCode === "23505") {
    const existing = await findThreadForProfile(
      admin,
      ownerUserId,
      primaryProfileId,
    );
    if (existing) {
      return existing;
    }
  }

  throw new HttpError(500, "thread_create_failed", error);
}

async function handleImportGuestHistory(req: Request): Promise<JsonObject> {
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
  const primaryProfileId = String(primaryProfile.id ?? "");
  if (!primaryProfileId) {
    throw new HttpError(500, "invalid_primary_profile");
  }

  const importableMessages = sanitizeGuestMessagesForImport(body.messages);
  let thread = await findThreadForProfile(admin, user.id, primaryProfileId);

  if (!thread && importableMessages.length > 0) {
    const firstTitle = importableMessages.find((item) =>
      item.senderType === "user"
    )
      ?.messageText ?? importableMessages[0].messageText;
    thread = await createThreadForProfile(
      admin,
      user.id,
      primaryProfileId,
      firstTitle,
    );
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

  const threadId = String(thread.id ?? "");
  if (!threadId) {
    throw new HttpError(500, "invalid_thread_payload");
  }

  const { data: existingMessages, error: existingMessagesError } = await admin
    .from("ai_messages")
    .select("metadata_json")
    .eq("owner_user_id", user.id)
    .eq("thread_id", threadId);

  if (existingMessagesError) {
    throw new HttpError(
      500,
      "existing_messages_lookup_failed",
      existingMessagesError,
    );
  }

  const importedLocalIdSet = new Set<string>();
  for (const row of existingMessages ?? []) {
    const metadata = (row as { metadata_json?: unknown })?.metadata_json;
    if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) {
      continue;
    }

    const importedLocalId = String(
      (metadata as JsonObject).guest_local_message_id ?? "",
    )
      .trim();
    if (importedLocalId) {
      importedLocalIdSet.add(importedLocalId);
    }
  }

  const seenLocalIds = new Set<string>(importedLocalIdSet);
  const rowsToInsert: JsonObject[] = [];

  for (const item of importableMessages) {
    if (seenLocalIds.has(item.localId)) {
      continue;
    }
    seenLocalIds.add(item.localId);

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
    if (item.requiresProfileInfo) {
      metadataJson.requires_profile_info = true;
    }

    rowsToInsert.push({
      owner_user_id: user.id,
      thread_id: threadId,
      sender_type: item.senderType,
      message_text: item.messageText,
      soul_point_cost: 0,
      metadata_json: metadataJson,
      created_at: item.createdAt,
    });
  }

  if (rowsToInsert.length > 0) {
    const { error: insertError } = await admin
      .from("ai_messages")
      .insert(rowsToInsert);

    if (insertError) {
      throw new HttpError(500, "guest_history_insert_failed", insertError);
    }

    const latestCreatedAt = String(
      rowsToInsert[rowsToInsert.length - 1].created_at ?? nowIso(),
    );
    const { error: updateThreadError } = await admin
      .from("ai_threads")
      .update({
        last_message_at: latestCreatedAt,
        updated_at: nowIso(),
      })
      .eq("id", threadId);

    if (updateThreadError) {
      throw new HttpError(500, "thread_update_failed", updateThreadError);
    }
  }

  return {
    ok: true,
    data: {
      thread_id: threadId,
      imported_count: rowsToInsert.length,
      skipped_count: importableMessages.length - rowsToInsert.length,
    },
  };
}

async function routeRequest(req: Request): Promise<Response | JsonObject> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    throw new HttpError(405, "method_not_allowed");
  }

  return handleImportGuestHistory(req);
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
