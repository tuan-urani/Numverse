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

revoke all on function public.sync_local_session_snapshot(jsonb) from public;
revoke all on function public.sync_local_session_snapshot(jsonb) from anon;
grant execute on function public.sync_local_session_snapshot(jsonb) to authenticated;
grant execute on function public.sync_local_session_snapshot(jsonb) to service_role;
