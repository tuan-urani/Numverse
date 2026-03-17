create extension if not exists pgcrypto;

create table if not exists public.soul_point_ledger (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  direction text not null,
  amount integer not null check (amount > 0),
  source_type text not null,
  source_ref_id text,
  request_id text,
  local_date date,
  balance_after integer not null check (balance_after >= 0),
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.soul_point_ledger
  add column if not exists source_ref_id text,
  add column if not exists request_id text,
  add column if not exists local_date date,
  add column if not exists metadata_json jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'soul_point_ledger'
      and column_name = 'direction'
      and data_type <> 'text'
  ) then
    execute 'alter table public.soul_point_ledger alter column direction type text using direction::text';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'soul_point_ledger'
      and column_name = 'source_type'
      and data_type <> 'text'
  ) then
    execute 'alter table public.soul_point_ledger alter column source_type type text using source_type::text';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'soul_point_ledger'
      and column_name = 'source_ref_id'
      and data_type <> 'text'
  ) then
    execute 'alter table public.soul_point_ledger alter column source_ref_id type text using source_ref_id::text';
  end if;
end
$$;

update public.soul_point_ledger
set metadata_json = '{}'::jsonb
where metadata_json is null;

alter table public.soul_point_ledger
  alter column metadata_json set default '{}'::jsonb,
  alter column metadata_json set not null,
  alter column created_at set default now(),
  alter column created_at set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'soul_point_ledger_direction_check'
      and conrelid = 'public.soul_point_ledger'::regclass
  ) then
    alter table public.soul_point_ledger
      add constraint soul_point_ledger_direction_check
      check (direction in ('credit', 'debit'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'soul_point_ledger_source_type_check'
      and conrelid = 'public.soul_point_ledger'::regclass
  ) then
    alter table public.soul_point_ledger
      add constraint soul_point_ledger_source_type_check
      check (char_length(trim(source_type)) > 0);
  end if;
end
$$;

create index if not exists soul_point_ledger_owner_created_idx
  on public.soul_point_ledger (owner_user_id, created_at desc);

create index if not exists soul_point_ledger_owner_source_date_idx
  on public.soul_point_ledger (owner_user_id, source_type, direction, local_date);

create unique index if not exists soul_point_ledger_owner_request_uidx
  on public.soul_point_ledger (owner_user_id, request_id)
  where request_id is not null;

alter table public.soul_point_ledger enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'soul_point_ledger'
      and policyname = 'soul_point_ledger_select_own'
  ) then
    create policy soul_point_ledger_select_own
      on public.soul_point_ledger for select to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'soul_point_spend_events'
  ) then
    insert into public.soul_point_ledger (
      owner_user_id,
      direction,
      amount,
      source_type,
      source_ref_id,
      request_id,
      local_date,
      balance_after,
      metadata_json,
      created_at
    )
    select
      e.owner_user_id,
      'debit',
      e.amount,
      e.source_type,
      e.request_id,
      e.request_id,
      (e.created_at at time zone 'Asia/Ho_Chi_Minh')::date,
      e.balance_after,
      coalesce(e.metadata_json, '{}'::jsonb),
      e.created_at
    from public.soul_point_spend_events e
    where not exists (
      select 1
      from public.soul_point_ledger l
      where l.owner_user_id = e.owner_user_id
        and l.request_id = e.request_id
    );
  end if;
end
$$;

create or replace function public.spend_soul_points(
  p_amount integer,
  p_source_type text default 'manual_adjustment',
  p_request_id text default null,
  p_metadata jsonb default '{}'::jsonb
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
  v_balance integer := 0;
  v_next_balance integer := 0;
  v_existing_balance integer := 0;
  v_clean_request_id text := nullif(trim(p_request_id), '');
  v_source_type text := coalesce(nullif(trim(p_source_type), ''), 'manual_adjustment');
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'invalid_amount';
  end if;

  select coalesce(
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

  if v_clean_request_id is not null then
    select l.balance_after
    into v_existing_balance
    from public.soul_point_ledger l
    where l.owner_user_id = v_user_id
      and l.request_id = v_clean_request_id
      and l.direction = 'debit'
    order by l.created_at desc
    limit 1;

    if found then
      return jsonb_build_object(
        'applied', false,
        'idempotent', true,
        'insufficient', false,
        'required', p_amount,
        'charged', 0,
        'soulPoints', greatest(v_existing_balance, 0)
      );
    end if;
  end if;

  insert into public.soul_point_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select w.balance
  into v_balance
  from public.soul_point_wallets w
  where w.user_id = v_user_id
  for update;

  v_balance := coalesce(v_balance, 0);
  if v_balance < p_amount then
    return jsonb_build_object(
      'applied', false,
      'idempotent', false,
      'insufficient', true,
      'required', p_amount,
      'charged', 0,
      'soulPoints', greatest(v_balance, 0)
    );
  end if;

  v_next_balance := v_balance - p_amount;

  update public.soul_point_wallets
  set balance = v_next_balance,
      lifetime_spent = lifetime_spent + p_amount,
      updated_at = v_now
  where user_id = v_user_id;

  insert into public.soul_point_ledger (
    owner_user_id,
    direction,
    amount,
    source_type,
    source_ref_id,
    request_id,
    local_date,
    balance_after,
    metadata_json,
    created_at
  )
  values (
    v_user_id,
    'debit',
    p_amount,
    v_source_type,
    v_clean_request_id,
    coalesce(v_clean_request_id, gen_random_uuid()::text),
    v_today,
    v_next_balance,
    coalesce(p_metadata, '{}'::jsonb),
    v_now
  );

  return jsonb_build_object(
    'applied', true,
    'idempotent', false,
    'insufficient', false,
    'required', p_amount,
    'charged', p_amount,
    'soulPoints', greatest(v_next_balance, 0)
  );
exception
  when unique_violation then
    if v_clean_request_id is not null then
      select l.balance_after
      into v_existing_balance
      from public.soul_point_ledger l
      where l.owner_user_id = v_user_id
        and l.request_id = v_clean_request_id
        and l.direction = 'debit'
      order by l.created_at desc
      limit 1;

      if found then
        return jsonb_build_object(
          'applied', false,
          'idempotent', true,
          'insufficient', false,
          'required', p_amount,
          'charged', 0,
          'soulPoints', greatest(v_existing_balance, 0)
        );
      end if;
    end if;
    raise;
end;
$$;

revoke all on function public.spend_soul_points(integer, text, text, jsonb) from public;
revoke all on function public.spend_soul_points(integer, text, text, jsonb) from anon;
grant execute on function public.spend_soul_points(integer, text, text, jsonb) to authenticated;
grant execute on function public.spend_soul_points(integer, text, text, jsonb) to service_role;

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
  v_ledger_request_id text;
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

  v_ledger_request_id := coalesce(
    v_clean_request_id,
    concat('daily_checkin:', v_today::text)
  );

  insert into public.soul_point_ledger (
    owner_user_id,
    direction,
    amount,
    source_type,
    source_ref_id,
    request_id,
    local_date,
    balance_after,
    metadata_json,
    created_at
  )
  values (
    v_user_id,
    'credit',
    v_reward,
    'daily_checkin',
    v_today::text,
    v_ledger_request_id,
    v_today,
    v_balance,
    jsonb_build_object('streak_count', v_new_streak),
    v_now
  )
  on conflict (owner_user_id, request_id)
  where request_id is not null
  do nothing;

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

create or replace function public.grant_ad_reward(
  p_reward_amount integer default 10,
  p_request_id text default null,
  p_ad_network text default null,
  p_placement_code text default null,
  p_metadata jsonb default '{}'::jsonb,
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
  v_daily_limit integer := 50;
  v_requested_amount integer := coalesce(p_reward_amount, 0);
  v_clean_request_id text := nullif(trim(p_request_id), '');
  v_today_earned integer := 0;
  v_remaining integer := 0;
  v_granted integer := 0;
  v_balance integer := 0;
  v_existing_balance integer := 0;
  v_ledger_request_id text;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if v_requested_amount <= 0 then
    raise exception 'invalid_amount';
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

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));

  if v_clean_request_id is not null then
    select l.balance_after
    into v_existing_balance
    from public.soul_point_ledger l
    where l.owner_user_id = v_user_id
      and l.request_id = v_clean_request_id
      and l.direction = 'credit'
      and l.source_type = 'ad_reward'
    order by l.created_at desc
    limit 1;

    if found then
      select coalesce(sum(l.amount), 0)
      into v_today_earned
      from public.soul_point_ledger l
      where l.owner_user_id = v_user_id
        and l.direction = 'credit'
        and l.source_type = 'ad_reward'
        and l.local_date = v_today;

      return jsonb_build_object(
        'granted', false,
        'idempotent', true,
        'rewardAwarded', 0,
        'dailyLimit', v_daily_limit,
        'todayEarned', v_today_earned,
        'soulPoints', greatest(v_existing_balance, 0)
      );
    end if;
  end if;

  insert into public.soul_point_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select w.balance
  into v_balance
  from public.soul_point_wallets w
  where w.user_id = v_user_id
  for update;

  v_balance := coalesce(v_balance, 0);

  select coalesce(sum(l.amount), 0)
  into v_today_earned
  from public.soul_point_ledger l
  where l.owner_user_id = v_user_id
    and l.direction = 'credit'
    and l.source_type = 'ad_reward'
    and l.local_date = v_today;

  v_remaining := greatest(v_daily_limit - v_today_earned, 0);
  v_granted := least(v_requested_amount, v_remaining);

  if v_granted <= 0 then
    return jsonb_build_object(
      'granted', false,
      'idempotent', false,
      'rewardAwarded', 0,
      'dailyLimit', v_daily_limit,
      'todayEarned', v_today_earned,
      'soulPoints', greatest(v_balance, 0)
    );
  end if;

  v_balance := v_balance + v_granted;
  v_ledger_request_id := coalesce(v_clean_request_id, gen_random_uuid()::text);

  update public.soul_point_wallets
  set balance = v_balance,
      lifetime_earned = lifetime_earned + v_granted,
      updated_at = v_now
  where user_id = v_user_id;

  insert into public.soul_point_ledger (
    owner_user_id,
    direction,
    amount,
    source_type,
    source_ref_id,
    request_id,
    local_date,
    balance_after,
    metadata_json,
    created_at
  )
  values (
    v_user_id,
    'credit',
    v_granted,
    'ad_reward',
    v_ledger_request_id,
    v_ledger_request_id,
    v_today,
    v_balance,
    v_metadata || jsonb_build_object(
      'adNetwork', nullif(trim(coalesce(p_ad_network, '')), ''),
      'placementCode', nullif(trim(coalesce(p_placement_code, '')), ''),
      'requestedAmount', v_requested_amount,
      'dailyLimit', v_daily_limit,
      'timezone', v_timezone
    ),
    v_now
  );

  return jsonb_build_object(
    'granted', true,
    'idempotent', false,
    'rewardAwarded', v_granted,
    'dailyLimit', v_daily_limit,
    'todayEarned', v_today_earned + v_granted,
    'soulPoints', greatest(v_balance, 0)
  );
exception
  when unique_violation then
    if v_clean_request_id is not null then
      select l.balance_after
      into v_existing_balance
      from public.soul_point_ledger l
      where l.owner_user_id = v_user_id
        and l.request_id = v_clean_request_id
        and l.direction = 'credit'
        and l.source_type = 'ad_reward'
      order by l.created_at desc
      limit 1;

      if found then
        select coalesce(sum(l.amount), 0)
        into v_today_earned
        from public.soul_point_ledger l
        where l.owner_user_id = v_user_id
          and l.direction = 'credit'
          and l.source_type = 'ad_reward'
          and l.local_date = v_today;

        return jsonb_build_object(
          'granted', false,
          'idempotent', true,
          'rewardAwarded', 0,
          'dailyLimit', v_daily_limit,
          'todayEarned', v_today_earned,
          'soulPoints', greatest(v_existing_balance, 0)
        );
      end if;
    end if;
    raise;
end;
$$;

revoke all on function public.grant_ad_reward(integer, text, text, text, jsonb, text) from public;
revoke all on function public.grant_ad_reward(integer, text, text, text, jsonb, text) from anon;
grant execute on function public.grant_ad_reward(integer, text, text, text, jsonb, text) to authenticated;
grant execute on function public.grant_ad_reward(integer, text, text, text, jsonb, text) to service_role;

drop table if exists public.soul_point_spend_events;
