import {
  buildThreadSummary,
  cacheResponse,
  callGeminiJson,
  completeGenerationRun,
  createClients,
  createGenerationRun,
  DEFAULT_LOCALE,
  DEFAULT_TIMEZONE,
  ENGINE_VERSION,
  ensureArrayOfStrings,
  ensureObject,
  getLocalDateParts,
  grantSoulPoints,
  hasActiveProSubscription,
  HttpError,
  NUMAI_SOUL_POINT_COST,
  parseJsonBody,
  resolveActivePrompt,
  resolveAppUserProfile,
  resolveCurrentNarrative,
  resolveCurrentSnapshot,
  resolveOwnedThread,
  resolvePrimaryProfile,
  requireUser,
  spendSoulPoints,
  hashJson,
} from "./runtime.ts";
import {
  calculateCompatibility,
  calculateLocalDateContext,
  calculatePersonalMonth,
  calculatePersonalYear,
  calculateSnapshot,
} from "./numerology.ts";

function nowIso(): string {
  return new Date().toISOString();
}

async function invalidateProfileCaches(
  admin: ReturnType<typeof createClients>["admin"],
  profileId: string,
): Promise<void> {
  const deletions = [
    admin.from("daily_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("monthly_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("yearly_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("active_phase_readings").delete().eq("numerology_profile_id", profileId),
    admin.from("compatibility_reports").delete().or(
      `primary_profile_id.eq.${profileId},target_profile_id.eq.${profileId}`,
    ),
  ];

  const results = await Promise.all(deletions);
  const failed = results.find((result) => result.error);
  if (failed?.error) {
    throw new HttpError(500, "cache_invalidation_failed", failed.error);
  }
}

async function createSnapshotRecord(
  admin: ReturnType<typeof createClients>["admin"],
  ownerUserId: string,
  profile: Record<string, unknown>,
  snapshotComputation: Awaited<ReturnType<typeof calculateSnapshot>>,
): Promise<Record<string, unknown>> {
  const { error: clearError } = await admin
    .from("numerology_snapshots")
    .update({ is_current: false })
    .eq("numerology_profile_id", profile.id)
    .eq("is_current", true);

  if (clearError) {
    throw new HttpError(500, "snapshot_invalidate_failed", clearError);
  }

  const { data, error } = await admin
    .from("numerology_snapshots")
    .insert({
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
      calculated_at: nowIso(),
    })
    .select("*")
    .single();

  if (error || !data) {
    throw new HttpError(500, "snapshot_create_failed", error);
  }

  return data as Record<string, unknown>;
}

function buildLifeNarrativeContext(
  profile: Record<string, unknown>,
  snapshot: Record<string, unknown>,
  locale: string,
): Record<string, unknown> {
  return {
    profile: {
      profile_id: profile.id,
      display_name: profile.display_name,
      locale,
    },
    snapshot: {
      snapshot_id: snapshot.id,
      core_numbers: snapshot.core_numbers_json,
      birth_matrix: snapshot.birth_matrix_json,
      matrix_aspects: snapshot.matrix_aspects_json,
      life_cycles: snapshot.life_cycles_json,
    },
  };
}

async function buildCompactSummary(
  admin: ReturnType<typeof createClients>["admin"],
  ownerUserId: string,
  snapshotId: string,
): Promise<Record<string, unknown> | null> {
  const narrative = await resolveCurrentNarrative(admin, ownerUserId, snapshotId);
  if (!narrative) {
    return null;
  }

  const sections = ensureObject(narrative.sections_json, "invalid_sections_json");
  const compactSummary = sections.compact_summary;
  if (!compactSummary || typeof compactSummary !== "object" || Array.isArray(compactSummary)) {
    return null;
  }

  return compactSummary as Record<string, unknown>;
}

async function insertDailyReading(
  admin: ReturnType<typeof createClients>["admin"],
  payload: Record<string, unknown>,
  profileId: string,
  localDate: string,
): Promise<Record<string, unknown>> {
  const { data, error } = await admin
    .from("daily_readings")
    .insert(payload)
    .select("*")
    .single();

  if (!error && data) {
    return data as Record<string, unknown>;
  }

  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin
      .from("daily_readings")
      .select("*")
      .eq("numerology_profile_id", profileId)
      .eq("local_date", localDate)
      .eq("engine_version", ENGINE_VERSION)
      .single();

    if (existingError || !existing) {
      throw new HttpError(500, "daily_reading_requery_failed", existingError);
    }
    return existing as Record<string, unknown>;
  }

  throw new HttpError(500, "daily_reading_insert_failed", error);
}

async function insertMonthlyReading(
  admin: ReturnType<typeof createClients>["admin"],
  payload: Record<string, unknown>,
  profileId: string,
  localYear: number,
  localMonth: number,
): Promise<Record<string, unknown>> {
  const { data, error } = await admin
    .from("monthly_readings")
    .insert(payload)
    .select("*")
    .single();

  if (!error && data) {
    return data as Record<string, unknown>;
  }

  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin
      .from("monthly_readings")
      .select("*")
      .eq("numerology_profile_id", profileId)
      .eq("local_year", localYear)
      .eq("local_month", localMonth)
      .eq("engine_version", ENGINE_VERSION)
      .single();

    if (existingError || !existing) {
      throw new HttpError(500, "monthly_reading_requery_failed", existingError);
    }
    return existing as Record<string, unknown>;
  }

  throw new HttpError(500, "monthly_reading_insert_failed", error);
}

async function insertYearlyReading(
  admin: ReturnType<typeof createClients>["admin"],
  payload: Record<string, unknown>,
  profileId: string,
  localYear: number,
): Promise<Record<string, unknown>> {
  const { data, error } = await admin
    .from("yearly_readings")
    .insert(payload)
    .select("*")
    .single();

  if (!error && data) {
    return data as Record<string, unknown>;
  }

  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin
      .from("yearly_readings")
      .select("*")
      .eq("numerology_profile_id", profileId)
      .eq("local_year", localYear)
      .eq("engine_version", ENGINE_VERSION)
      .single();

    if (existingError || !existing) {
      throw new HttpError(500, "yearly_reading_requery_failed", existingError);
    }
    return existing as Record<string, unknown>;
  }

  throw new HttpError(500, "yearly_reading_insert_failed", error);
}

async function insertActivePhaseReading(
  admin: ReturnType<typeof createClients>["admin"],
  payload: Record<string, unknown>,
  profileId: string,
  phaseKey: string,
): Promise<Record<string, unknown>> {
  const { data, error } = await admin
    .from("active_phase_readings")
    .insert(payload)
    .select("*")
    .single();

  if (!error && data) {
    return data as Record<string, unknown>;
  }

  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin
      .from("active_phase_readings")
      .select("*")
      .eq("numerology_profile_id", profileId)
      .eq("phase_key", phaseKey)
      .eq("engine_version", ENGINE_VERSION)
      .single();

    if (existingError || !existing) {
      throw new HttpError(500, "active_phase_requery_failed", existingError);
    }
    return existing as Record<string, unknown>;
  }

  throw new HttpError(500, "active_phase_insert_failed", error);
}

async function insertCompatibilityReport(
  admin: ReturnType<typeof createClients>["admin"],
  payload: Record<string, unknown>,
  ownerUserId: string,
  primaryProfileId: string,
  targetProfileId: string,
): Promise<Record<string, unknown>> {
  const { data, error } = await admin
    .from("compatibility_reports")
    .insert(payload)
    .select("*")
    .single();

  if (!error && data) {
    return data as Record<string, unknown>;
  }

  if (error?.code === "23505") {
    const { data: existing, error: existingError } = await admin
      .from("compatibility_reports")
      .select("*")
      .eq("owner_user_id", ownerUserId)
      .eq("primary_profile_id", primaryProfileId)
      .eq("target_profile_id", targetProfileId)
      .eq("engine_version", ENGINE_VERSION)
      .single();

    if (existingError || !existing) {
      throw new HttpError(500, "compatibility_requery_failed", existingError);
    }
    return existing as Record<string, unknown>;
  }

  throw new HttpError(500, "compatibility_insert_failed", error);
}

export async function handleRecalculateNumerologyProfile(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{ profile_id?: string }>(req);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshotComputation = await calculateSnapshot(profile);
  const snapshot = await createSnapshotRecord(admin, user.id, profile, snapshotComputation);
  await invalidateProfileCaches(admin, String(profile.id));

  return {
    ok: true,
    data: {
      profile_id: profile.id,
      snapshot_id: snapshot.id,
      engine_version: ENGINE_VERSION,
    },
  };
}

export async function handleGenerateSnapshotNarrative(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{
    snapshot_id?: string;
    profile_id?: string;
    locale?: string;
    force_regenerate?: boolean;
  }>(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);

  let snapshot: Record<string, unknown>;
  let profile: Record<string, unknown>;

  if (body.snapshot_id) {
    const { data, error } = await admin
      .from("numerology_snapshots")
      .select("*, numerology_profiles(*)")
      .eq("owner_user_id", user.id)
      .eq("id", body.snapshot_id)
      .single();

    if (error || !data) {
      throw new HttpError(404, "snapshot_not_found", error);
    }
    snapshot = data as Record<string, unknown>;
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
      engine_version: snapshot.engine_version,
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
    started_at: nowIso(),
  });

  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);

    const { error: clearError } = await admin
      .from("numerology_snapshot_narratives")
      .update({ is_current: false })
      .eq("numerology_snapshot_id", snapshot.id)
      .eq("is_current", true);

    if (clearError) {
      throw new HttpError(500, "snapshot_narrative_invalidate_failed", clearError);
    }

    const { data, error } = await admin
      .from("numerology_snapshot_narratives")
      .insert({
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
        generated_at: nowIso(),
      })
      .select("*")
      .single();

    if (error || !data) {
      throw new HttpError(500, "snapshot_narrative_insert_failed", error);
    }

    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: data.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso(),
    });

    return cacheResponse("miss_generated", data, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: snapshot.engine_version,
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso(),
    });
    throw error;
  }
}

export async function handleGenerateDailyReading(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{
    profile_id?: string;
    local_date?: string;
    locale?: string;
    force_regenerate?: boolean;
  }>(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localDate = body.local_date ?? getLocalDateParts(timezone).localDate;

  const { data: existing, error: existingError } = await admin
    .from("daily_readings")
    .select("*")
    .eq("numerology_profile_id", profile.id)
    .eq("local_date", localDate)
    .eq("engine_version", ENGINE_VERSION)
    .maybeSingle();

  if (existingError) {
    throw new HttpError(500, "daily_reading_lookup_failed", existingError);
  }

  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "daily_reading_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION,
    });
  }

  if (existing && forceRegenerate) {
    const { error } = await admin
      .from("daily_readings")
      .delete()
      .eq("id", existing.id);
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
      timezone,
    },
    date_context: {
      local_date: dateContext.localDate,
      personal_year: dateContext.personalYear,
      personal_month: dateContext.personalMonth,
      personal_day: dateContext.personalDay,
      active_peak_number: dateContext.activePeakNumber,
      active_challenge_number: dateContext.activeChallengeNumber,
    },
    life_summary_compact: compactSummary,
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
    started_at: nowIso(),
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
        summary: "Du lieu dang duoc cap nhat.",
      },
      ai_generation_run_id: generationRun.id,
      prompt_template_id: prompt.id,
      model_name: prompt.model_name,
      prompt_version: prompt.version,
      generated_at: nowIso(),
    }, String(profile.id), localDate);

    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso(),
    });

    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION,
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso(),
    });
    throw error;
  }
}

export async function handleGenerateMonthlyReading(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{
    profile_id?: string;
    local_year?: number;
    local_month?: number;
    locale?: string;
    force_regenerate?: boolean;
  }>(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localParts = getLocalDateParts(timezone);
  const localYear = body.local_year ?? localParts.year;
  const localMonth = body.local_month ?? localParts.month;

  const { data: existing, error: existingError } = await admin
    .from("monthly_readings")
    .select("*")
    .eq("numerology_profile_id", profile.id)
    .eq("local_year", localYear)
    .eq("local_month", localMonth)
    .eq("engine_version", ENGINE_VERSION)
    .maybeSingle();

  if (existingError) {
    throw new HttpError(500, "monthly_reading_lookup_failed", existingError);
  }

  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "monthly_reading_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION,
    });
  }

  if (existing && forceRegenerate) {
    const { error } = await admin
      .from("monthly_readings")
      .delete()
      .eq("id", existing.id);
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
      timezone,
    },
    month_context: {
      local_year: localYear,
      local_month: localMonth,
      personal_year: personalYear,
      personal_month: personalMonth,
    },
    life_summary_compact: compactSummary,
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
    started_at: nowIso(),
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
      generated_at: nowIso(),
    }, String(profile.id), localYear, localMonth);

    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso(),
    });

    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION,
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso(),
    });
    throw error;
  }
}

export async function handleGenerateYearlyReading(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{
    profile_id?: string;
    local_year?: number;
    locale?: string;
    force_regenerate?: boolean;
  }>(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localYear = body.local_year ?? getLocalDateParts(timezone).year;

  const { data: existing, error: existingError } = await admin
    .from("yearly_readings")
    .select("*")
    .eq("numerology_profile_id", profile.id)
    .eq("local_year", localYear)
    .eq("engine_version", ENGINE_VERSION)
    .maybeSingle();

  if (existingError) {
    throw new HttpError(500, "yearly_reading_lookup_failed", existingError);
  }

  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "yearly_reading_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION,
    });
  }

  if (existing && forceRegenerate) {
    const { error } = await admin
      .from("yearly_readings")
      .delete()
      .eq("id", existing.id);
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
      timezone,
    },
    year_context: {
      local_year: localYear,
      personal_year: personalYear,
    },
    life_summary_compact: compactSummary,
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
    started_at: nowIso(),
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
      generated_at: nowIso(),
    }, String(profile.id), localYear);

    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso(),
    });

    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION,
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso(),
    });
    throw error;
  }
}

export async function handleGenerateActivePhaseReading(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{
    profile_id?: string;
    phase_key?: string;
    locale?: string;
    force_regenerate?: boolean;
  }>(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  const profile = await resolvePrimaryProfile(admin, user.id, body.profile_id);
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(profile.id));
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  const timezone = String(appUserProfile.timezone ?? DEFAULT_TIMEZONE);
  const localDate = getLocalDateParts(timezone).localDate;
  const dateContext = calculateLocalDateContext(profile, snapshot, localDate);
  const phaseKey = body.phase_key ?? dateContext.phaseKey;

  const { data: existing, error: existingError } = await admin
    .from("active_phase_readings")
    .select("*")
    .eq("numerology_profile_id", profile.id)
    .eq("phase_key", phaseKey)
    .eq("engine_version", ENGINE_VERSION)
    .maybeSingle();

  if (existingError) {
    throw new HttpError(500, "active_phase_lookup_failed", existingError);
  }

  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "active_phase_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION,
    });
  }

  if (existing && forceRegenerate) {
    const { error } = await admin
      .from("active_phase_readings")
      .delete()
      .eq("id", existing.id);
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
      timezone,
    },
    phase_context: {
      phase_key: phaseKey,
      phase_start_date: dateContext.phaseStartDate,
      phase_end_date: dateContext.phaseEndDate,
      active_peak_number: dateContext.activePeakNumber,
      active_challenge_number: dateContext.activeChallengeNumber,
    },
    life_summary_compact: compactSummary,
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
    started_at: nowIso(),
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
      generated_at: nowIso(),
    }, String(profile.id), phaseKey);

    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso(),
    });

    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION,
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso(),
    });
    throw error;
  }
}

export async function handleGenerateCompatibilityReport(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{
    primary_profile_id?: string;
    target_profile_id?: string;
    locale?: string;
    force_regenerate?: boolean;
  }>(req);
  const locale = body.locale ?? DEFAULT_LOCALE;
  const forceRegenerate = Boolean(body.force_regenerate);
  if (!body.target_profile_id) {
    throw new HttpError(400, "target_profile_id_required");
  }

  const primaryProfile = await resolvePrimaryProfile(admin, user.id, body.primary_profile_id);
  const targetProfile = await resolvePrimaryProfile(admin, user.id, body.target_profile_id);
  const primarySnapshot = await resolveCurrentSnapshot(admin, user.id, String(primaryProfile.id));
  const targetSnapshot = await resolveCurrentSnapshot(admin, user.id, String(targetProfile.id));

  const { data: existing, error: existingError } = await admin
    .from("compatibility_reports")
    .select("*")
    .eq("owner_user_id", user.id)
    .eq("primary_profile_id", primaryProfile.id)
    .eq("target_profile_id", targetProfile.id)
    .eq("engine_version", ENGINE_VERSION)
    .maybeSingle();

  if (existingError) {
    throw new HttpError(500, "compatibility_lookup_failed", existingError);
  }

  if (existing && !forceRegenerate) {
    return cacheResponse("hit", existing, {
      prompt_key: "compatibility_narrative",
      prompt_version: existing.prompt_version ?? "unknown",
      engine_version: ENGINE_VERSION,
    });
  }

  if (existing && forceRegenerate) {
    const { error } = await admin
      .from("compatibility_reports")
      .delete()
      .eq("id", existing.id);
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
      display_name: primaryProfile.display_name,
    },
    target_profile: {
      profile_id: targetProfile.id,
      display_name: targetProfile.display_name,
    },
    primary_facts: {
      core_numbers: primarySnapshot.core_numbers_json,
      matrix_aspects: primarySnapshot.matrix_aspects_json,
      life_cycles: primarySnapshot.life_cycles_json,
    },
    target_facts: {
      core_numbers: targetSnapshot.core_numbers_json,
      matrix_aspects: targetSnapshot.matrix_aspects_json,
      life_cycles: targetSnapshot.life_cycles_json,
    },
    compatibility_structure: {
      score: compatibility.score,
      signals: ensureArrayOfStrings(
        (compatibility.compatibilityStructure as Record<string, unknown>).signals,
      ),
    },
    primary_life_summary_compact: primarySummary,
    target_life_summary_compact: targetSummary,
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
    started_at: nowIso(),
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
      calculated_at: nowIso(),
    }, user.id, String(primaryProfile.id), String(targetProfile.id));

    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: inserted.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso(),
    });

    return cacheResponse("miss_generated", inserted, {
      prompt_key: prompt.prompt_key,
      prompt_version: prompt.version,
      engine_version: ENGINE_VERSION,
    });
  } catch (error) {
    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso(),
    });
    throw error;
  }
}

export async function handleSendNumaiMessage(
  req: Request,
): Promise<Record<string, unknown>> {
  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);
  const body = await parseJsonBody<{
    thread_id?: string;
    primary_profile_id?: string;
    related_profile_id?: string;
    context_type?: string;
    locale?: string;
    message_text?: string;
  }>(req);
  const messageText = String(body.message_text ?? "").trim();
  if (!messageText) {
    throw new HttpError(400, "message_text_required");
  }

  const locale = body.locale ?? DEFAULT_LOCALE;
  const appUserProfile = await resolveAppUserProfile(admin, user.id);
  let thread: Record<string, unknown>;

  if (body.thread_id) {
    thread = await resolveOwnedThread(admin, user.id, body.thread_id);
  } else {
    const primaryProfile = await resolvePrimaryProfile(admin, user.id, body.primary_profile_id);
    const relatedProfileId = body.related_profile_id
      ? String((await resolvePrimaryProfile(admin, user.id, body.related_profile_id)).id)
      : null;
    const { data, error } = await admin
      .from("ai_threads")
      .insert({
        owner_user_id: user.id,
        primary_profile_id: primaryProfile.id,
        related_profile_id: relatedProfileId,
        context_type: body.context_type ?? "general",
        title: messageText.slice(0, 48),
        last_message_at: nowIso(),
      })
      .select("*")
      .single();

    if (error || !data) {
      throw new HttpError(500, "thread_create_failed", error);
    }
    thread = data as Record<string, unknown>;
  }

  const activeProfile = await resolvePrimaryProfile(
    admin,
    user.id,
    String(thread.primary_profile_id),
  );
  const snapshot = await resolveCurrentSnapshot(admin, user.id, String(activeProfile.id));
  const hasPro = await hasActiveProSubscription(admin, user.id);

  if (!hasPro) {
    const { data: walletData, error: walletError } = await admin
      .from("soul_point_wallets")
      .select("balance")
      .eq("user_id", user.id)
      .maybeSingle();

    if (walletError) {
      throw new HttpError(500, "wallet_lookup_failed", walletError);
    }

    const balance = Number(walletData?.balance ?? 0);
    if (balance < NUMAI_SOUL_POINT_COST) {
      throw new HttpError(402, "insufficient_soul_points", {
        required: NUMAI_SOUL_POINT_COST,
        balance,
      });
    }
  }

  const { data: userMessage, error: userMessageError } = await admin
    .from("ai_messages")
    .insert({
      owner_user_id: user.id,
      thread_id: thread.id,
      sender_type: "user",
      message_text: messageText,
      context_snapshot_id: snapshot.id,
      soul_point_cost: hasPro ? 0 : NUMAI_SOUL_POINT_COST,
      metadata_json: {
        context_type: thread.context_type,
      },
    })
    .select("*")
    .single();

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
      String(userMessage.id),
    );
    charged = true;
  }

  const { data: recentMessages, error: recentMessagesError } = await admin
    .from("ai_messages")
    .select("sender_type, message_text, created_at")
    .eq("thread_id", thread.id)
    .order("created_at", { ascending: false })
    .limit(20);

  if (recentMessagesError) {
    if (charged) {
      await grantSoulPoints(
        admin,
        user.id,
        NUMAI_SOUL_POINT_COST,
        "manual_adjustment",
        { reason: "numai_message_failed", message_id: userMessage.id },
        String(userMessage.id),
      );
    }
    throw new HttpError(500, "recent_messages_lookup_failed", recentMessagesError);
  }

  const prompt = await resolveActivePrompt(admin, "numai_chat_reply", locale);
  const contextJson = {
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
    context_type: thread.context_type,
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
    started_at: nowIso(),
  });

  try {
    const geminiResult = await callGeminiJson(prompt, contextJson);
    const output = ensureObject(geminiResult.parsedOutput, "invalid_numai_output");
    const { data: assistantMessage, error: assistantError } = await admin
      .from("ai_messages")
      .insert({
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
          prompt_version: prompt.version,
        },
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
          String(output.answer ?? ""),
        ),
        thread_summary_updated_at: nowIso(),
      })
      .eq("id", thread.id);

    if (threadUpdateError) {
      throw new HttpError(500, "thread_update_failed", threadUpdateError);
    }

    await completeGenerationRun(admin, generationRun.id, {
      status: "succeeded",
      target_id: assistantMessage.id,
      output_json: geminiResult.parsedOutput,
      raw_text_output: geminiResult.rawTextOutput,
      latency_ms: geminiResult.latencyMs,
      completed_at: nowIso(),
    });

    return {
      ok: true,
      data: {
        thread_id: thread.id,
        user_message: userMessage,
        assistant_message: assistantMessage,
        charged_soul_points: charged ? NUMAI_SOUL_POINT_COST : 0,
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
        { reason: "numai_generation_refund", message_id: userMessage.id },
        String(userMessage.id),
      );
    }

    await completeGenerationRun(admin, generationRun.id, {
      status: "failed",
      error_text: error instanceof Error ? error.message : "unknown_error",
      completed_at: nowIso(),
    });
    throw error;
  }
}
