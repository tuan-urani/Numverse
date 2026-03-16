create table if not exists public.daily_checkins (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  local_date date not null,
  streak_count integer not null check (streak_count >= 0),
  reward_amount integer not null check (reward_amount >= 0),
  request_id text,
  created_at timestamptz not null default now()
);

create unique index if not exists daily_checkins_owner_date_uidx
  on public.daily_checkins (owner_user_id, local_date);

create unique index if not exists daily_checkins_owner_request_uidx
  on public.daily_checkins (owner_user_id, request_id)
  where request_id is not null;

alter table public.daily_checkins enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'daily_checkins'
      and policyname = 'daily_checkins_select_own'
  ) then
    create policy daily_checkins_select_own
      on public.daily_checkins for select to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
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
  v_local_streak integer := 0;
  v_local_earning integer := 0;
  v_last_checkin_text text := nullif(trim(p_payload ->> 'lastCheckInAt'), '');
  v_last_checkin_at timestamptz;
  v_last_checkin_date date;
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

create or replace function public.claim_daily_checkin(
  p_request_id text default null,
  p_tz text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := now();
  v_timezone text;
  v_today date;
  v_existing public.daily_checkins%rowtype;
  v_prev_date date;
  v_prev_streak integer := 0;
  v_is_consecutive boolean := false;
  v_effective_prev_streak integer := 0;
  v_new_streak integer := 1;
  v_reward integer := 10;
  v_balance integer := 0;
  v_clean_request_id text := nullif(trim(p_request_id), '');
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  select coalesce(
    nullif(trim(p_tz), ''),
    nullif(trim(up.timezone), ''),
    'Asia/Ho_Chi_Minh'
  )
  into v_timezone
  from public.user_profiles up
  where up.id = v_user_id;

  if v_timezone is null then
    v_timezone := 'Asia/Ho_Chi_Minh';
  end if;

  v_today := (v_now at time zone v_timezone)::date;

  select *
  into v_existing
  from public.daily_checkins dc
  where dc.owner_user_id = v_user_id
    and dc.local_date = v_today
  order by dc.created_at desc
  limit 1;

  if found then
    select coalesce(w.balance, 0)
    into v_balance
    from public.soul_point_wallets w
    where w.user_id = v_user_id;

    return jsonb_build_object(
      'alreadyClaimed', true,
      'rewardAwarded', 0,
      'soulPoints', greatest(v_balance, 0),
      'currentStreak', v_existing.streak_count,
      'dailyEarnings', v_existing.reward_amount,
      'lastCheckInAt', v_existing.created_at
    );
  end if;

  insert into public.soul_point_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select dc.local_date, dc.streak_count
  into v_prev_date, v_prev_streak
  from public.daily_checkins dc
  where dc.owner_user_id = v_user_id
    and dc.local_date < v_today
  order by dc.local_date desc
  limit 1;

  v_is_consecutive := v_prev_date = (v_today - 1);
  v_effective_prev_streak := case
    when v_is_consecutive then coalesce(v_prev_streak, 0)
    else 0
  end;
  v_new_streak := case
    when v_is_consecutive then coalesce(v_prev_streak, 0) + 1
    else 1
  end;

  if v_effective_prev_streak >= 30 then
    v_reward := 30;
  elsif v_effective_prev_streak >= 14 then
    v_reward := 20;
  elsif v_effective_prev_streak >= 7 then
    v_reward := 15;
  else
    v_reward := 10;
  end if;

  begin
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
      v_today,
      v_new_streak,
      v_reward,
      v_clean_request_id,
      v_now
    );
  exception
    when unique_violation then
      select *
      into v_existing
      from public.daily_checkins dc
      where dc.owner_user_id = v_user_id
        and (
          dc.local_date = v_today
          or (v_clean_request_id is not null and dc.request_id = v_clean_request_id)
        )
      order by dc.created_at desc
      limit 1;

      select coalesce(w.balance, 0)
      into v_balance
      from public.soul_point_wallets w
      where w.user_id = v_user_id;

      return jsonb_build_object(
        'alreadyClaimed', true,
        'rewardAwarded', 0,
        'soulPoints', greatest(v_balance, 0),
        'currentStreak', coalesce(v_existing.streak_count, 0),
        'dailyEarnings', coalesce(v_existing.reward_amount, 0),
        'lastCheckInAt', v_existing.created_at
      );
  end;

  update public.soul_point_wallets
  set balance = balance + v_reward,
      lifetime_earned = lifetime_earned + v_reward,
      updated_at = v_now
  where user_id = v_user_id
  returning balance into v_balance;

  return jsonb_build_object(
    'alreadyClaimed', false,
    'rewardAwarded', v_reward,
    'soulPoints', greatest(v_balance, 0),
    'currentStreak', v_new_streak,
    'dailyEarnings', v_reward,
    'lastCheckInAt', v_now
  );
end;
$$;

revoke all on function public.claim_daily_checkin(text, text) from public;
revoke all on function public.claim_daily_checkin(text, text) from anon;
grant execute on function public.claim_daily_checkin(text, text) to authenticated;
grant execute on function public.claim_daily_checkin(text, text) to service_role;

create or replace function public.get_cloud_session_snapshot()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_display_name text;
  v_timezone text;
  v_today date;
  v_profiles jsonb := '[]'::jsonb;
  v_current_profile_id text;
  v_soul_points integer := 0;
  v_current_streak integer := 0;
  v_daily_earnings integer := 0;
  v_last_checkin_at timestamptz;
  v_last_checkin_date date;
  v_last_streak integer := 0;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  select u.email
  into v_email
  from auth.users u
  where u.id = v_user_id;

  select up.display_name,
         coalesce(nullif(trim(up.timezone), ''), 'Asia/Ho_Chi_Minh')
  into v_display_name, v_timezone
  from public.user_profiles up
  where up.id = v_user_id;

  if v_timezone is null then
    v_timezone := 'Asia/Ho_Chi_Minh';
  end if;
  v_today := (now() at time zone v_timezone)::date;

  select coalesce(w.balance, 0)
  into v_soul_points
  from public.soul_point_wallets w
  where w.user_id = v_user_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', p.client_profile_id,
        'name', p.display_name,
        'birthDate', (p.birth_date::text || 'T00:00:00.000'),
        'createdAt', p.created_at
      )
      order by p.created_at asc
    ),
    '[]'::jsonb
  )
  into v_profiles
  from public.numerology_profiles p
  where p.owner_user_id = v_user_id
    and p.archived_at is null;

  select p.client_profile_id
  into v_current_profile_id
  from public.numerology_profiles p
  where p.owner_user_id = v_user_id
    and p.archived_at is null
    and p.is_primary = true
  order by p.updated_at desc, p.created_at asc
  limit 1;

  if v_current_profile_id is null then
    select p.client_profile_id
    into v_current_profile_id
    from public.numerology_profiles p
    where p.owner_user_id = v_user_id
      and p.archived_at is null
    order by p.created_at asc
    limit 1;
  end if;

  select dc.local_date, dc.streak_count, dc.created_at
  into v_last_checkin_date, v_last_streak, v_last_checkin_at
  from public.daily_checkins dc
  where dc.owner_user_id = v_user_id
  order by dc.local_date desc, dc.created_at desc
  limit 1;

  if v_last_checkin_date is not null then
    if v_last_checkin_date = v_today or v_last_checkin_date = (v_today - 1) then
      v_current_streak := coalesce(v_last_streak, 0);
    else
      v_current_streak := 0;
    end if;
  end if;

  select coalesce(dc.reward_amount, 0)
  into v_daily_earnings
  from public.daily_checkins dc
  where dc.owner_user_id = v_user_id
    and dc.local_date = v_today
  order by dc.created_at desc
  limit 1;

  return jsonb_build_object(
    'isAuthenticated', true,
    'userEmail', nullif(trim(coalesce(v_email, '')), ''),
    'userName', nullif(
      trim(
        coalesce(
          v_display_name,
          nullif(split_part(coalesce(v_email, ''), '@', 1), '')
        )
      ),
      ''
    ),
    'profiles', v_profiles,
    'lifeBasedByProfileId', jsonb_build_object(),
    'timeLifeByProfileId', jsonb_build_object(),
    'currentProfileId', v_current_profile_id,
    'soulPoints', greatest(v_soul_points, 0),
    'currentStreak', greatest(v_current_streak, 0),
    'dailyEarnings', greatest(v_daily_earnings, 0),
    'lastCheckInAt', v_last_checkin_at
  );
end;
$$;

revoke all on function public.get_cloud_session_snapshot() from public;
revoke all on function public.get_cloud_session_snapshot() from anon;
grant execute on function public.get_cloud_session_snapshot() to authenticated;
grant execute on function public.get_cloud_session_snapshot() to service_role;
