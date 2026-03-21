create or replace function public._resolve_numai_profile_id(
  p_profile_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile_text text := nullif(trim(p_profile_id), '');
  v_profile_uuid uuid;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if v_profile_text is not null then
    if v_profile_text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
      select p.id
      into v_profile_uuid
      from public.numerology_profiles p
      where p.owner_user_id = v_user_id
        and p.id = v_profile_text::uuid
        and p.archived_at is null
      limit 1;

      if v_profile_uuid is not null then
        return v_profile_uuid;
      end if;
    end if;

    select p.id
    into v_profile_uuid
    from public.numerology_profiles p
    where p.owner_user_id = v_user_id
      and p.client_profile_id = v_profile_text
      and p.archived_at is null
    limit 1;

    if v_profile_uuid is null then
      raise exception 'profile_not_found';
    end if;

    return v_profile_uuid;
  end if;

  select p.id
  into v_profile_uuid
  from public.numerology_profiles p
  where p.owner_user_id = v_user_id
    and p.is_primary = true
    and p.archived_at is null
  order by p.created_at asc
  limit 1;

  if v_profile_uuid is not null then
    return v_profile_uuid;
  end if;

  select p.id
  into v_profile_uuid
  from public.numerology_profiles p
  where p.owner_user_id = v_user_id
    and p.archived_at is null
  order by p.created_at asc
  limit 1;

  if v_profile_uuid is null then
    raise exception 'primary_profile_not_found';
  end if;

  return v_profile_uuid;
end;
$$;

create or replace function public.list_numai_messages(
  p_primary_profile_id text default null,
  p_thread_id text default null,
  p_limit integer default 50
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 50), 1), 100);
  v_thread_id uuid;
  v_primary_profile_id uuid;
  v_messages jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if nullif(trim(p_thread_id), '') is not null then
    select t.id
    into v_thread_id
    from public.ai_threads t
    where t.owner_user_id = v_user_id
      and t.id::text = trim(p_thread_id)
    limit 1;

    if v_thread_id is null then
      raise exception 'thread_not_found';
    end if;
  else
    v_primary_profile_id := public._resolve_numai_profile_id(p_primary_profile_id);

    select t.id
    into v_thread_id
    from public.ai_threads t
    where t.owner_user_id = v_user_id
      and t.primary_profile_id = v_primary_profile_id
    limit 1;
  end if;

  if v_thread_id is null then
    return jsonb_build_object(
      'ok', true,
      'data', jsonb_build_object(
        'thread_id', null,
        'messages', '[]'::jsonb
      )
    );
  end if;

  select coalesce(
    jsonb_agg(to_jsonb(m) order by m.created_at asc),
    '[]'::jsonb
  )
  into v_messages
  from (
    select *
    from public.ai_messages
    where owner_user_id = v_user_id
      and thread_id = v_thread_id
    order by created_at asc
    limit v_limit
  ) m;

  return jsonb_build_object(
    'ok', true,
    'data', jsonb_build_object(
      'thread_id', v_thread_id::text,
      'messages', v_messages
    )
  );
end;
$$;

create or replace function public.import_guest_numai_history(
  p_primary_profile_id text,
  p_request_id text default null,
  p_messages jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_primary_profile_input text := nullif(trim(coalesce(p_primary_profile_id, '')), '');
  v_request_id text := nullif(trim(p_request_id), '');
  v_primary_profile_id uuid;
  v_thread_id uuid;
  v_thread_title text;
  v_raw_messages jsonb := case
    when jsonb_typeof(p_messages) = 'array' then p_messages
    else '[]'::jsonb
  end;
  v_raw_message jsonb;
  v_sanitized_messages jsonb := '[]'::jsonb;
  v_sanitized_message jsonb;
  v_sanitized_count integer := 0;
  v_imported_count integer := 0;
  v_seen_local_ids text[] := '{}'::text[];
  v_local_id text;
  v_sender_type text;
  v_message_text text;
  v_created_at timestamptz;
  v_created_at_text text;
  v_follow_up_suggestions jsonb := '[]'::jsonb;
  v_requires_profile_info boolean;
  v_metadata jsonb;
  v_latest_created_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if v_primary_profile_input is null then
    raise exception 'numai_profile_required';
  end if;

  v_primary_profile_id := public._resolve_numai_profile_id(v_primary_profile_input);

  for v_raw_message in
    select value
    from jsonb_array_elements(v_raw_messages)
  loop
    if jsonb_typeof(v_raw_message) <> 'object' then
      continue;
    end if;

    v_message_text := nullif(trim(coalesce(v_raw_message ->> 'message_text', '')), '');
    if v_message_text is null then
      continue;
    end if;

    v_sender_type := lower(trim(coalesce(v_raw_message ->> 'sender_type', 'user')));
    if v_sender_type not in ('user', 'assistant', 'system') then
      v_sender_type := 'user';
    end if;

    v_created_at := null;

    if nullif(trim(coalesce(v_raw_message ->> 'created_at_epoch_ms', '')), '') is not null then
      begin
        if (v_raw_message ->> 'created_at_epoch_ms')::numeric > 0 then
          v_created_at := to_timestamp((v_raw_message ->> 'created_at_epoch_ms')::numeric / 1000.0);
        end if;
      exception
        when others then
          v_created_at := null;
      end;
    end if;

    if v_created_at is null and nullif(trim(coalesce(v_raw_message ->> 'created_at', '')), '') is not null then
      begin
        v_created_at := (v_raw_message ->> 'created_at')::timestamptz;
      exception
        when others then
          v_created_at := null;
      end;
    end if;

    if v_created_at is null then
      v_created_at := now() + (v_sanitized_count || ' milliseconds')::interval;
    end if;

    v_created_at_text := to_char(
      v_created_at at time zone 'UTC',
      'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
    );

    v_local_id := nullif(trim(coalesce(v_raw_message ->> 'local_id', v_raw_message ->> 'id', '')), '');
    if v_local_id is null then
      v_local_id := format('guest-local-%s-%s', v_created_at_text, v_sanitized_count);
    end if;

    if jsonb_typeof(v_raw_message -> 'follow_up_suggestions') = 'array' then
      select coalesce(
        jsonb_agg(to_jsonb(trim(f.item)) order by f.ord)
          filter (where trim(f.item) <> ''),
        '[]'::jsonb
      )
      into v_follow_up_suggestions
      from jsonb_array_elements_text(v_raw_message -> 'follow_up_suggestions') with ordinality as f(item, ord);
    else
      v_follow_up_suggestions := '[]'::jsonb;
    end if;

    v_requires_profile_info := false;
    if jsonb_typeof(v_raw_message -> 'requires_profile_info') = 'boolean' then
      v_requires_profile_info := (v_raw_message ->> 'requires_profile_info')::boolean;
    end if;

    v_sanitized_messages := v_sanitized_messages || jsonb_build_array(
      jsonb_build_object(
        'local_id', v_local_id,
        'sender_type', v_sender_type,
        'message_text', v_message_text,
        'created_at', v_created_at,
        'follow_up_suggestions', v_follow_up_suggestions,
        'requires_profile_info', v_requires_profile_info
      )
    );

    v_sanitized_count := v_sanitized_count + 1;
  end loop;

  select t.id
  into v_thread_id
  from public.ai_threads t
  where t.owner_user_id = v_user_id
    and t.primary_profile_id = v_primary_profile_id
  limit 1;

  if v_thread_id is null and v_sanitized_count > 0 then
    select coalesce(
      (
        select s.value ->> 'message_text'
        from jsonb_array_elements(v_sanitized_messages) as s(value)
        where s.value ->> 'sender_type' = 'user'
        order by (s.value ->> 'created_at')::timestamptz asc
        limit 1
      ),
      (
        select s.value ->> 'message_text'
        from jsonb_array_elements(v_sanitized_messages) as s(value)
        order by (s.value ->> 'created_at')::timestamptz asc
        limit 1
      )
    )
    into v_thread_title;

    insert into public.ai_threads (
      owner_user_id,
      primary_profile_id,
      title,
      last_message_at
    )
    values (
      v_user_id,
      v_primary_profile_id,
      left(coalesce(v_thread_title, ''), 48),
      now()
    )
    on conflict (owner_user_id, primary_profile_id) do nothing
    returning id into v_thread_id;

    if v_thread_id is null then
      select t.id
      into v_thread_id
      from public.ai_threads t
      where t.owner_user_id = v_user_id
        and t.primary_profile_id = v_primary_profile_id
      limit 1;
    end if;
  end if;

  if v_thread_id is null then
    return jsonb_build_object(
      'ok', true,
      'data', jsonb_build_object(
        'thread_id', null,
        'imported_count', 0,
        'skipped_count', v_sanitized_count
      )
    );
  end if;

  select coalesce(
    array_agg(distinct nullif(trim(m.metadata_json ->> 'guest_local_message_id'), ''))
      filter (where nullif(trim(m.metadata_json ->> 'guest_local_message_id'), '') is not null),
    '{}'::text[]
  )
  into v_seen_local_ids
  from public.ai_messages m
  where m.owner_user_id = v_user_id
    and m.thread_id = v_thread_id;

  for v_sanitized_message in
    select value
    from jsonb_array_elements(v_sanitized_messages)
    order by (value ->> 'created_at')::timestamptz asc
  loop
    v_local_id := nullif(trim(coalesce(v_sanitized_message ->> 'local_id', '')), '');
    if v_local_id is null then
      continue;
    end if;

    if v_local_id = any(v_seen_local_ids) then
      continue;
    end if;
    v_seen_local_ids := array_append(v_seen_local_ids, v_local_id);

    v_sender_type := coalesce(v_sanitized_message ->> 'sender_type', 'user');
    v_message_text := coalesce(v_sanitized_message ->> 'message_text', '');
    v_created_at := (v_sanitized_message ->> 'created_at')::timestamptz;

    v_metadata := jsonb_build_object(
      'source', 'guest_local_migration',
      'guest_local_message_id', v_local_id
    );

    if v_request_id is not null then
      v_metadata := v_metadata || jsonb_build_object('import_request_id', v_request_id);
    end if;

    if jsonb_array_length(coalesce(v_sanitized_message -> 'follow_up_suggestions', '[]'::jsonb)) > 0 then
      v_metadata := v_metadata || jsonb_build_object(
        'follow_up_suggestions',
        v_sanitized_message -> 'follow_up_suggestions'
      );
    end if;

    if coalesce((v_sanitized_message ->> 'requires_profile_info')::boolean, false) then
      v_metadata := v_metadata || jsonb_build_object('requires_profile_info', true);
    end if;

    insert into public.ai_messages (
      owner_user_id,
      thread_id,
      sender_type,
      message_text,
      soul_point_cost,
      metadata_json,
      created_at
    )
    values (
      v_user_id,
      v_thread_id,
      v_sender_type,
      v_message_text,
      0,
      v_metadata,
      v_created_at
    );

    v_imported_count := v_imported_count + 1;
    if v_latest_created_at is null or v_created_at > v_latest_created_at then
      v_latest_created_at := v_created_at;
    end if;
  end loop;

  if v_imported_count > 0 and v_latest_created_at is not null then
    update public.ai_threads
    set last_message_at = v_latest_created_at,
        updated_at = now()
    where id = v_thread_id
      and owner_user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'data', jsonb_build_object(
      'thread_id', v_thread_id::text,
      'imported_count', v_imported_count,
      'skipped_count', v_sanitized_count - v_imported_count
    )
  );
end;
$$;

create or replace function public.sync_numai_snapshots(
  p_snapshots jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_raw_snapshots jsonb := case
    when jsonb_typeof(p_snapshots) = 'array' then p_snapshots
    else '[]'::jsonb
  end;
  v_raw_snapshot jsonb;
  v_sanitized_snapshots jsonb := '[]'::jsonb;
  v_snapshot jsonb;
  v_primary_profile_id text;
  v_profile_id uuid;
  v_engine_version text;
  v_calculated_at timestamptz;
  v_source_hash text;
  v_raw_input jsonb;
  v_core_numbers jsonb;
  v_birth_matrix jsonb;
  v_matrix_aspects jsonb;
  v_life_cycles jsonb;
  v_resolved_raw_input jsonb;
  v_current_snapshot_id uuid;
  v_current_source_hash text;
  v_created_snapshot_id uuid;
  v_generated_source_hash text;
  v_invalidated_current boolean;
  v_updated_count integer := 0;
  v_skipped_count integer := 0;
  v_results jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  for v_raw_snapshot in
    select value
    from jsonb_array_elements(v_raw_snapshots)
  loop
    if jsonb_typeof(v_raw_snapshot) <> 'object' then
      continue;
    end if;

    v_primary_profile_id := nullif(trim(coalesce(v_raw_snapshot ->> 'primary_profile_id', '')), '');
    if v_primary_profile_id is null then
      continue;
    end if;

    v_raw_input := v_raw_snapshot -> 'raw_input';
    v_core_numbers := v_raw_snapshot -> 'core_numbers';
    v_birth_matrix := v_raw_snapshot -> 'birth_matrix';
    v_matrix_aspects := v_raw_snapshot -> 'matrix_aspects';
    v_life_cycles := v_raw_snapshot -> 'life_cycles';

    if jsonb_typeof(v_raw_input) <> 'object'
      or jsonb_typeof(v_core_numbers) <> 'object'
      or jsonb_typeof(v_birth_matrix) <> 'object'
      or jsonb_typeof(v_matrix_aspects) <> 'object'
      or jsonb_typeof(v_life_cycles) <> 'object' then
      continue;
    end if;

    v_engine_version := nullif(trim(coalesce(v_raw_snapshot ->> 'engine_version', '')), '');
    if v_engine_version is null then
      v_engine_version := 'mobile_local_v1';
    end if;

    begin
      v_calculated_at := (v_raw_snapshot ->> 'calculated_at')::timestamptz;
    exception
      when others then
        v_calculated_at := now();
    end;

    v_source_hash := nullif(trim(coalesce(v_raw_snapshot ->> 'source_hash', '')), '');

    v_sanitized_snapshots := v_sanitized_snapshots || jsonb_build_array(
      jsonb_build_object(
        'primary_profile_id', v_primary_profile_id,
        'engine_version', v_engine_version,
        'calculated_at', v_calculated_at,
        'source_hash', v_source_hash,
        'raw_input', v_raw_input,
        'core_numbers', v_core_numbers,
        'birth_matrix', v_birth_matrix,
        'matrix_aspects', v_matrix_aspects,
        'life_cycles', v_life_cycles
      )
    );
  end loop;

  if jsonb_array_length(v_sanitized_snapshots) = 0 then
    return jsonb_build_object(
      'ok', true,
      'data', jsonb_build_object(
        'updated_count', 0,
        'skipped_count', 0,
        'snapshots', '[]'::jsonb
      )
    );
  end if;

  for v_snapshot in
    select value
    from jsonb_array_elements(v_sanitized_snapshots)
  loop
    v_primary_profile_id := v_snapshot ->> 'primary_profile_id';

    begin
      v_profile_id := public._resolve_numai_profile_id(v_primary_profile_id);
    exception
      when others then
        if sqlerrm in ('profile_not_found', 'primary_profile_not_found') then
          v_skipped_count := v_skipped_count + 1;
          v_results := v_results || jsonb_build_array(
            jsonb_build_object(
              'primary_profile_id', v_primary_profile_id,
              'status', 'skipped_profile_not_found'
            )
          );
          continue;
        end if;
        raise;
    end;

    if v_profile_id is null then
      v_skipped_count := v_skipped_count + 1;
      v_results := v_results || jsonb_build_array(
        jsonb_build_object(
          'primary_profile_id', v_primary_profile_id,
          'status', 'skipped_invalid_profile'
        )
      );
      continue;
    end if;

    v_engine_version := v_snapshot ->> 'engine_version';
    v_calculated_at := (v_snapshot ->> 'calculated_at')::timestamptz;
    v_source_hash := nullif(trim(coalesce(v_snapshot ->> 'source_hash', '')), '');
    v_raw_input := v_snapshot -> 'raw_input';
    v_core_numbers := v_snapshot -> 'core_numbers';
    v_birth_matrix := v_snapshot -> 'birth_matrix';
    v_matrix_aspects := v_snapshot -> 'matrix_aspects';
    v_life_cycles := v_snapshot -> 'life_cycles';

    v_resolved_raw_input := coalesce(v_raw_input, '{}'::jsonb) || jsonb_build_object(
      'profile_id', v_profile_id::text,
      'client_profile_id', v_primary_profile_id,
      'source', coalesce(nullif(trim(coalesce(v_raw_input ->> 'source', '')), ''), 'mobile_local_sync')
    );

    v_generated_source_hash := coalesce(
      v_source_hash,
      md5(
        jsonb_build_object(
          'owner_user_id', v_user_id::text,
          'profile_id', v_profile_id::text,
          'engine_version', v_engine_version,
          'raw_input_json', v_resolved_raw_input,
          'core_numbers_json', v_core_numbers,
          'birth_matrix_json', v_birth_matrix,
          'matrix_aspects_json', v_matrix_aspects,
          'life_cycles_json', v_life_cycles
        )::text
      )
    );

    select s.id, s.source_hash
    into v_current_snapshot_id, v_current_source_hash
    from public.numerology_snapshots s
    where s.owner_user_id = v_user_id
      and s.numerology_profile_id = v_profile_id
      and s.is_current = true
    limit 1;

    if v_current_snapshot_id is not null
      and coalesce(v_current_source_hash, '') = v_generated_source_hash then
      v_skipped_count := v_skipped_count + 1;
      v_results := v_results || jsonb_build_array(
        jsonb_build_object(
          'primary_profile_id', v_primary_profile_id,
          'profile_id', v_profile_id::text,
          'snapshot_id', v_current_snapshot_id::text,
          'status', 'unchanged'
        )
      );
      continue;
    end if;

    v_invalidated_current := false;
    if v_current_snapshot_id is not null then
      update public.numerology_snapshots
      set is_current = false
      where owner_user_id = v_user_id
        and numerology_profile_id = v_profile_id
        and is_current = true;

      v_invalidated_current := true;
    end if;

    begin
      insert into public.numerology_snapshots (
        owner_user_id,
        numerology_profile_id,
        engine_version,
        source_hash,
        is_current,
        raw_input_json,
        core_numbers_json,
        birth_matrix_json,
        matrix_aspects_json,
        life_cycles_json,
        calculated_at
      )
      values (
        v_user_id,
        v_profile_id,
        v_engine_version,
        v_generated_source_hash,
        true,
        v_resolved_raw_input,
        v_core_numbers,
        v_birth_matrix,
        v_matrix_aspects,
        v_life_cycles,
        v_calculated_at
      )
      returning id into v_created_snapshot_id;

      v_updated_count := v_updated_count + 1;
      v_results := v_results || jsonb_build_array(
        jsonb_build_object(
          'primary_profile_id', v_primary_profile_id,
          'profile_id', v_profile_id::text,
          'snapshot_id', v_created_snapshot_id::text,
          'status', 'updated'
        )
      );
    exception
      when others then
        if v_invalidated_current and v_current_snapshot_id is not null then
          update public.numerology_snapshots
          set is_current = true
          where owner_user_id = v_user_id
            and id = v_current_snapshot_id;
        end if;
        raise;
    end;
  end loop;

  return jsonb_build_object(
    'ok', true,
    'data', jsonb_build_object(
      'updated_count', v_updated_count,
      'skipped_count', v_skipped_count,
      'snapshots', v_results
    )
  );
end;
$$;

revoke all on function public._resolve_numai_profile_id(text) from public;
revoke all on function public._resolve_numai_profile_id(text) from anon;
grant execute on function public._resolve_numai_profile_id(text) to authenticated;
grant execute on function public._resolve_numai_profile_id(text) to service_role;

revoke all on function public.list_numai_messages(text, text, integer) from public;
revoke all on function public.list_numai_messages(text, text, integer) from anon;
grant execute on function public.list_numai_messages(text, text, integer) to authenticated;
grant execute on function public.list_numai_messages(text, text, integer) to service_role;

revoke all on function public.import_guest_numai_history(text, text, jsonb) from public;
revoke all on function public.import_guest_numai_history(text, text, jsonb) from anon;
grant execute on function public.import_guest_numai_history(text, text, jsonb) to authenticated;
grant execute on function public.import_guest_numai_history(text, text, jsonb) to service_role;

revoke all on function public.sync_numai_snapshots(jsonb) from public;
revoke all on function public.sync_numai_snapshots(jsonb) from anon;
grant execute on function public.sync_numai_snapshots(jsonb) to authenticated;
grant execute on function public.sync_numai_snapshots(jsonb) to service_role;
