create or replace function public.sync_local_session_bootstrap(
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := now();
  v_profiles_json jsonb := coalesce(p_payload -> 'profiles', '[]'::jsonb);
  v_profile jsonb;
  v_current_profile_id text := nullif(trim(p_payload ->> 'currentProfileId'), '');
  v_local_profile_id text;
  v_profile_name text;
  v_birth_text text;
  v_birth_date date;
  v_has_primary boolean := false;
  v_synced_count integer := 0;
  v_first_sync_completed_at timestamptz;
  v_wallet_balance integer := 0;
  v_soul_points_text text := nullif(trim(p_payload ->> 'soulPoints'), '');
  v_display_name text := nullif(
    trim(coalesce(p_payload ->> 'userName', p_payload ->> 'userEmail')),
    ''
  );
  v_local_streak integer := 0;
  v_local_earning integer := 0;
  v_last_checkin_text text := nullif(trim(p_payload ->> 'lastCheckInAt'), '');
  v_last_checkin_at timestamptz;
  v_last_checkin_date date;
  v_profile_limit integer := 2;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if jsonb_typeof(p_payload) <> 'object' then
    raise exception 'invalid_payload';
  end if;

  if jsonb_typeof(v_profiles_json) <> 'array' then
    raise exception 'invalid_profiles_payload';
  end if;

  if (
    select count(distinct nullif(trim(item ->> 'id'), ''))
    from jsonb_array_elements(v_profiles_json) as profile(item)
    where jsonb_typeof(item) = 'object'
      and nullif(trim(item ->> 'id'), '') is not null
      and nullif(trim(item ->> 'name'), '') is not null
      and nullif(trim(item ->> 'birthDate'), '') is not null
  ) > v_profile_limit then
    raise exception 'profile_limit_reached';
  end if;

  if v_soul_points_text is not null then
    begin
      v_wallet_balance := greatest(v_soul_points_text::integer, 0);
    exception
      when others then
        v_wallet_balance := 0;
    end;
  end if;

  begin
    v_local_streak := greatest(coalesce((p_payload ->> 'currentStreak')::integer, 0), 0);
  exception
    when others then
      v_local_streak := 0;
  end;

  begin
    v_local_earning := greatest(coalesce((p_payload ->> 'dailyEarnings')::integer, 0), 0);
  exception
    when others then
      v_local_earning := 0;
  end;

  if v_last_checkin_text is not null then
    begin
      v_last_checkin_at := v_last_checkin_text::timestamptz;
      v_last_checkin_date := (v_last_checkin_at at time zone 'Asia/Ho_Chi_Minh')::date;
    exception
      when others then
        v_last_checkin_at := null;
        v_last_checkin_date := null;
    end;
  end if;

  insert into public.user_profiles (id, display_name)
  values (v_user_id, v_display_name)
  on conflict (id) do nothing;

  insert into public.soul_point_wallets (user_id, balance)
  values (v_user_id, v_wallet_balance)
  on conflict (user_id) do nothing;

  select first_local_sync_completed_at
  into v_first_sync_completed_at
  from public.user_profiles
  where id = v_user_id
  for update;

  if v_first_sync_completed_at is not null then
    update public.user_profiles
    set display_name = coalesce(v_display_name, display_name),
        last_active_at = v_now,
        updated_at = v_now
    where id = v_user_id;

    return jsonb_build_object(
      'already_synced', true,
      'user_id', v_user_id,
      'synced_profile_count', 0
    );
  end if;

  -- local wins first sync: wipe cloud profiles once, then hydrate from local.
  delete from public.numerology_profiles
  where owner_user_id = v_user_id;

  for v_profile in select value from jsonb_array_elements(v_profiles_json)
  loop
    if jsonb_typeof(v_profile) <> 'object' then
      continue;
    end if;

    v_local_profile_id := nullif(trim(v_profile ->> 'id'), '');
    v_profile_name := nullif(trim(v_profile ->> 'name'), '');
    v_birth_text := nullif(trim(v_profile ->> 'birthDate'), '');

    if v_local_profile_id is null or v_profile_name is null or v_birth_text is null then
      continue;
    end if;

    begin
      v_birth_date := substring(v_birth_text from 1 for 10)::date;
    exception
      when others then
        continue;
    end;

    if not v_has_primary then
      if v_current_profile_id is null or v_current_profile_id = v_local_profile_id then
        v_has_primary := true;
      end if;
    end if;

    insert into public.numerology_profiles (
      owner_user_id,
      client_profile_id,
      profile_kind,
      relation_kind,
      display_name,
      full_name_for_reading,
      birth_date,
      is_primary,
      notes
    )
    values (
      v_user_id,
      v_local_profile_id,
      case
        when v_current_profile_id is not null and v_current_profile_id = v_local_profile_id then 'self'::public.profile_kind
        when v_current_profile_id is null and v_synced_count = 0 then 'self'::public.profile_kind
        else 'other'::public.profile_kind
      end,
      case
        when v_current_profile_id is not null and v_current_profile_id = v_local_profile_id then 'self'::public.relation_kind
        when v_current_profile_id is null and v_synced_count = 0 then 'self'::public.relation_kind
        else 'other'::public.relation_kind
      end,
      v_profile_name,
      v_profile_name,
      v_birth_date,
      (
        (v_current_profile_id is not null and v_current_profile_id = v_local_profile_id) or
        (v_current_profile_id is null and v_synced_count = 0)
      ),
      concat('local_profile_id:', v_local_profile_id)
    )
    on conflict (owner_user_id, client_profile_id) do update
      set display_name = excluded.display_name,
          full_name_for_reading = excluded.full_name_for_reading,
          birth_date = excluded.birth_date,
          profile_kind = excluded.profile_kind,
          relation_kind = excluded.relation_kind,
          is_primary = excluded.is_primary,
          archived_at = null,
          notes = excluded.notes,
          updated_at = v_now;

    v_synced_count := v_synced_count + 1;
  end loop;

  if v_synced_count > 0 and not exists (
    select 1
    from public.numerology_profiles
    where owner_user_id = v_user_id
      and archived_at is null
      and is_primary = true
  ) then
    update public.numerology_profiles
    set is_primary = true
    where id = (
      select id
      from public.numerology_profiles
      where owner_user_id = v_user_id
        and archived_at is null
      order by created_at asc
      limit 1
    );
  end if;

  update public.user_profiles
  set display_name = coalesce(v_display_name, display_name),
      onboarding_completed = onboarding_completed or v_synced_count > 0,
      first_local_sync_completed_at = v_now,
      last_active_at = v_now,
      updated_at = v_now
  where id = v_user_id;

  update public.soul_point_wallets
  set balance = v_wallet_balance,
      updated_at = v_now
  where user_id = v_user_id;

  if v_last_checkin_date is not null then
    insert into public.daily_checkins (
      owner_user_id,
      local_date,
      streak_count,
      reward_amount,
      request_id,
      created_at
    )
    values (
      v_user_id,
      v_last_checkin_date,
      v_local_streak,
      v_local_earning,
      concat('bootstrap:', v_user_id::text, ':', extract(epoch from v_now)::bigint::text),
      coalesce(v_last_checkin_at, v_now)
    )
    on conflict (owner_user_id, local_date) do update
      set streak_count = excluded.streak_count,
          reward_amount = excluded.reward_amount,
          created_at = excluded.created_at;
  end if;

  return jsonb_build_object(
    'already_synced', false,
    'user_id', v_user_id,
    'synced_profile_count', v_synced_count,
    'synced_at', v_now
  );
end;
$$;

create or replace function public.sync_local_session_snapshot(
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := now();
  v_profiles_json jsonb := coalesce(p_payload -> 'profiles', '[]'::jsonb);
  v_profile jsonb;
  v_current_profile_id text := nullif(trim(p_payload ->> 'currentProfileId'), '');
  v_local_profile_id text;
  v_profile_name text;
  v_birth_text text;
  v_birth_date date;
  v_synced_count integer := 0;
  v_display_name text := nullif(
    trim(coalesce(p_payload ->> 'userName', p_payload ->> 'userEmail')),
    ''
  );
  v_seen_profile_ids text[] := '{}'::text[];
  v_first_profile_id text;
  v_primary_profile_id text;
  v_profile_limit integer := 2;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if jsonb_typeof(p_payload) <> 'object' then
    raise exception 'invalid_payload';
  end if;

  if jsonb_typeof(v_profiles_json) <> 'array' then
    raise exception 'invalid_profiles_payload';
  end if;

  if (
    select count(distinct nullif(trim(item ->> 'id'), ''))
    from jsonb_array_elements(v_profiles_json) as profile(item)
    where jsonb_typeof(item) = 'object'
      and nullif(trim(item ->> 'id'), '') is not null
      and nullif(trim(item ->> 'name'), '') is not null
      and nullif(trim(item ->> 'birthDate'), '') is not null
  ) > v_profile_limit then
    raise exception 'profile_limit_reached';
  end if;

  insert into public.user_profiles (
    id,
    display_name,
    last_active_at,
    updated_at
  )
  values (
    v_user_id,
    v_display_name,
    v_now,
    v_now
  )
  on conflict (id) do update
    set display_name = coalesce(excluded.display_name, public.user_profiles.display_name),
        last_active_at = v_now,
        updated_at = v_now;

  for v_profile in select value from jsonb_array_elements(v_profiles_json)
  loop
    if jsonb_typeof(v_profile) <> 'object' then
      continue;
    end if;

    v_local_profile_id := nullif(trim(v_profile ->> 'id'), '');
    v_profile_name := nullif(trim(v_profile ->> 'name'), '');
    v_birth_text := nullif(trim(v_profile ->> 'birthDate'), '');

    if v_local_profile_id is null or v_profile_name is null or v_birth_text is null then
      continue;
    end if;

    begin
      v_birth_date := substring(v_birth_text from 1 for 10)::date;
    exception
      when others then
        continue;
    end;

    if v_first_profile_id is null then
      v_first_profile_id := v_local_profile_id;
    end if;

    if v_primary_profile_id is null and v_current_profile_id is not null and v_current_profile_id = v_local_profile_id then
      v_primary_profile_id := v_local_profile_id;
    end if;

    insert into public.numerology_profiles (
      owner_user_id,
      client_profile_id,
      profile_kind,
      relation_kind,
      display_name,
      full_name_for_reading,
      birth_date,
      is_primary,
      notes,
      archived_at
    )
    values (
      v_user_id,
      v_local_profile_id,
      case
        when v_current_profile_id is not null and v_current_profile_id = v_local_profile_id then 'self'::public.profile_kind
        when v_current_profile_id is null and v_synced_count = 0 then 'self'::public.profile_kind
        else 'other'::public.profile_kind
      end,
      case
        when v_current_profile_id is not null and v_current_profile_id = v_local_profile_id then 'self'::public.relation_kind
        when v_current_profile_id is null and v_synced_count = 0 then 'self'::public.relation_kind
        else 'other'::public.relation_kind
      end,
      v_profile_name,
      v_profile_name,
      v_birth_date,
      false,
      null,
      null
    )
    on conflict (owner_user_id, client_profile_id) do update
      set display_name = excluded.display_name,
          full_name_for_reading = excluded.full_name_for_reading,
          birth_date = excluded.birth_date,
          profile_kind = excluded.profile_kind,
          relation_kind = excluded.relation_kind,
          is_primary = false,
          archived_at = null,
          notes = excluded.notes,
          updated_at = v_now;

    v_seen_profile_ids := array_append(v_seen_profile_ids, v_local_profile_id);
    v_synced_count := v_synced_count + 1;
  end loop;

  v_primary_profile_id := coalesce(v_primary_profile_id, v_first_profile_id);

  if v_synced_count = 0 then
    update public.numerology_profiles
    set archived_at = v_now,
        is_primary = false,
        updated_at = v_now
    where owner_user_id = v_user_id
      and archived_at is null;
  else
    update public.numerology_profiles
    set is_primary = false,
        updated_at = v_now
    where owner_user_id = v_user_id
      and archived_at is null
      and is_primary = true;

    if v_primary_profile_id is not null then
      update public.numerology_profiles
      set is_primary = true,
          updated_at = v_now
      where owner_user_id = v_user_id
        and archived_at is null
        and client_profile_id = v_primary_profile_id;
    end if;

    update public.numerology_profiles
    set archived_at = v_now,
        is_primary = false,
        updated_at = v_now
    where owner_user_id = v_user_id
      and archived_at is null
      and not (client_profile_id = any(v_seen_profile_ids));
  end if;

  update public.user_profiles
  set last_active_at = v_now,
      updated_at = v_now
  where id = v_user_id;

  return jsonb_build_object(
    'synced_profile_count', v_synced_count,
    'current_profile_id', v_primary_profile_id
  );
end;
$$;

revoke all on function public.sync_local_session_bootstrap(jsonb) from public;
revoke all on function public.sync_local_session_bootstrap(jsonb) from anon;
grant execute on function public.sync_local_session_bootstrap(jsonb) to authenticated;
grant execute on function public.sync_local_session_bootstrap(jsonb) to service_role;

revoke all on function public.sync_local_session_snapshot(jsonb) from public;
revoke all on function public.sync_local_session_snapshot(jsonb) from anon;
grant execute on function public.sync_local_session_snapshot(jsonb) to authenticated;
grant execute on function public.sync_local_session_snapshot(jsonb) to service_role;
