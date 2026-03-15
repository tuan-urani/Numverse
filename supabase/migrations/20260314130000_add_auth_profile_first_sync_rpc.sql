do $$
begin
  if not exists (select 1 from pg_type where typname = 'profile_kind') then
    create type public.profile_kind as enum ('self', 'other');
  end if;
end
$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'relation_kind') then
    create type public.relation_kind as enum (
      'self',
      'lover',
      'spouse',
      'friend',
      'mother',
      'father',
      'child',
      'sibling',
      'coworker',
      'other'
    );
  end if;
end
$$;

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  locale text not null default 'vi-VN',
  timezone text not null default 'Asia/Ho_Chi_Minh',
  onboarding_completed boolean not null default false,
  first_local_sync_completed_at timestamptz,
  last_active_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles
  add column if not exists first_local_sync_completed_at timestamptz;

create table if not exists public.numerology_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  client_profile_id text not null,
  profile_kind public.profile_kind not null default 'other',
  relation_kind public.relation_kind not null default 'other',
  display_name text not null,
  full_name_for_reading text not null,
  birth_date date not null,
  is_primary boolean not null default false,
  archived_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.numerology_profiles
  add column if not exists client_profile_id text;
alter table public.numerology_profiles
  add column if not exists notes text;

create table if not exists public.soul_point_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  lifetime_earned integer not null default 0 check (lifetime_earned >= 0),
  lifetime_spent integer not null default 0 check (lifetime_spent >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists numerology_profiles_owner_client_id_uidx
  on public.numerology_profiles (owner_user_id, client_profile_id);

create unique index if not exists numerology_profiles_one_primary_uidx
  on public.numerology_profiles (owner_user_id)
  where is_primary = true and archived_at is null;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_user_profiles_updated_at'
  ) then
    create trigger set_user_profiles_updated_at
    before update on public.user_profiles
    for each row execute function public.set_updated_at();
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_numerology_profiles_updated_at'
  ) then
    create trigger set_numerology_profiles_updated_at
    before update on public.numerology_profiles
    for each row execute function public.set_updated_at();
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_soul_point_wallets_updated_at'
  ) then
    create trigger set_soul_point_wallets_updated_at
    before update on public.soul_point_wallets
    for each row execute function public.set_updated_at();
  end if;
end
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'name'
    )
  )
  on conflict (id) do nothing;

  insert into public.soul_point_wallets (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'on_auth_user_created'
  ) then
    create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
  end if;
end
$$;

alter table public.user_profiles enable row level security;
alter table public.numerology_profiles enable row level security;
alter table public.soul_point_wallets enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_profiles'
      and policyname = 'user_profiles_select_own'
  ) then
    create policy user_profiles_select_own
      on public.user_profiles for select to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_profiles'
      and policyname = 'user_profiles_insert_own'
  ) then
    create policy user_profiles_insert_own
      on public.user_profiles for insert to authenticated
      with check ((select auth.uid()) is not null and (select auth.uid()) = id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_profiles'
      and policyname = 'user_profiles_update_own'
  ) then
    create policy user_profiles_update_own
      on public.user_profiles for update to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = id)
      with check ((select auth.uid()) is not null and (select auth.uid()) = id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'numerology_profiles'
      and policyname = 'numerology_profiles_select_own'
  ) then
    create policy numerology_profiles_select_own
      on public.numerology_profiles for select to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'numerology_profiles'
      and policyname = 'numerology_profiles_insert_own'
  ) then
    create policy numerology_profiles_insert_own
      on public.numerology_profiles for insert to authenticated
      with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'numerology_profiles'
      and policyname = 'numerology_profiles_update_own'
  ) then
    create policy numerology_profiles_update_own
      on public.numerology_profiles for update to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id)
      with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'numerology_profiles'
      and policyname = 'numerology_profiles_delete_own'
  ) then
    create policy numerology_profiles_delete_own
      on public.numerology_profiles for delete to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'soul_point_wallets'
      and policyname = 'soul_point_wallets_select_own'
  ) then
    create policy soul_point_wallets_select_own
      on public.soul_point_wallets for select to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'soul_point_wallets'
      and policyname = 'soul_point_wallets_insert_own'
  ) then
    create policy soul_point_wallets_insert_own
      on public.soul_point_wallets for insert to authenticated
      with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'soul_point_wallets'
      and policyname = 'soul_point_wallets_update_own'
  ) then
    create policy soul_point_wallets_update_own
      on public.soul_point_wallets for update to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
      with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);
  end if;
end
$$;

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

  if v_soul_points_text is not null then
    begin
      v_wallet_balance := greatest(v_soul_points_text::integer, 0);
    exception
      when others then
        v_wallet_balance := 0;
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

  return jsonb_build_object(
    'already_synced', false,
    'user_id', v_user_id,
    'synced_profile_count', v_synced_count,
    'synced_at', v_now
  );
end;
$$;

revoke all on function public.sync_local_session_bootstrap(jsonb) from public;
revoke all on function public.sync_local_session_bootstrap(jsonb) from anon;
grant execute on function public.sync_local_session_bootstrap(jsonb) to authenticated;
grant execute on function public.sync_local_session_bootstrap(jsonb) to service_role;
