create or replace function public.get_ad_reward_status(
  p_placement_code text default null,
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
  v_reward_per_watch integer := 5;
  v_today_earned integer := 0;
  v_remaining integer := 0;
  v_balance integer := 0;
  v_last_reward_at timestamptz;
  v_clean_placement_code text := coalesce(
    nullif(trim(p_placement_code), ''),
    'default_rewarded'
  );
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

  case lower(v_clean_placement_code)
    when 'profile_soul_points_dialog' then
      v_reward_per_watch := 5;
      v_daily_limit := 50;
    when 'numai_soul_points_dialog' then
      v_reward_per_watch := 5;
      v_daily_limit := 50;
    when 'compatibility_soul_points_dialog' then
      v_reward_per_watch := 5;
      v_daily_limit := 50;
    else
      v_clean_placement_code := 'default_rewarded';
      v_reward_per_watch := 5;
      v_daily_limit := 50;
  end case;

  insert into public.soul_point_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select coalesce(w.balance, 0)
  into v_balance
  from public.soul_point_wallets w
  where w.user_id = v_user_id;

  select coalesce(sum(l.amount), 0), max(l.created_at)
  into v_today_earned, v_last_reward_at
  from public.soul_point_ledger l
  where l.owner_user_id = v_user_id
    and l.direction = 'credit'
    and l.source_type = 'ad_reward'
    and l.local_date = v_today;

  v_remaining := greatest(v_daily_limit - v_today_earned, 0);

  return jsonb_build_object(
    'placementCode', v_clean_placement_code,
    'rewardPerWatch', v_reward_per_watch,
    'dailyLimit', v_daily_limit,
    'todayEarned', v_today_earned,
    'remaining', v_remaining,
    'canWatch', v_remaining > 0,
    'soulPoints', greatest(v_balance, 0),
    'lastRewardAt', v_last_reward_at
  );
end;
$$;

revoke all on function public.get_ad_reward_status(text, text) from public;
revoke all on function public.get_ad_reward_status(text, text) from anon;
grant execute on function public.get_ad_reward_status(text, text) to authenticated;
grant execute on function public.get_ad_reward_status(text, text) to service_role;

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
  v_requested_amount integer := greatest(coalesce(p_reward_amount, 0), 0);
  v_clean_request_id text := nullif(trim(p_request_id), '');
  v_clean_placement_code text := coalesce(
    nullif(trim(p_placement_code), ''),
    'default_rewarded'
  );
  v_clean_ad_network text := coalesce(
    nullif(trim(p_ad_network), ''),
    'admob'
  );
  v_reward_per_watch integer := 5;
  v_daily_limit integer := 50;
  v_today_earned integer := 0;
  v_remaining integer := 0;
  v_granted integer := 0;
  v_balance integer := 0;
  v_existing_balance integer := 0;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if v_clean_request_id is null then
    raise exception 'request_id_required';
  end if;

  case lower(v_clean_placement_code)
    when 'profile_soul_points_dialog' then
      v_reward_per_watch := 5;
      v_daily_limit := 50;
    when 'numai_soul_points_dialog' then
      v_reward_per_watch := 5;
      v_daily_limit := 50;
    when 'compatibility_soul_points_dialog' then
      v_reward_per_watch := 5;
      v_daily_limit := 50;
    else
      v_clean_placement_code := 'default_rewarded';
      v_reward_per_watch := 5;
      v_daily_limit := 50;
  end case;

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
      'rewardPerWatch', v_reward_per_watch,
      'dailyLimit', v_daily_limit,
      'todayEarned', v_today_earned,
      'remaining', greatest(v_daily_limit - v_today_earned, 0),
      'soulPoints', greatest(v_existing_balance, 0)
    );
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
  v_granted := least(v_reward_per_watch, v_remaining);

  if v_granted <= 0 then
    return jsonb_build_object(
      'granted', false,
      'idempotent', false,
      'rewardAwarded', 0,
      'rewardPerWatch', v_reward_per_watch,
      'dailyLimit', v_daily_limit,
      'todayEarned', v_today_earned,
      'remaining', v_remaining,
      'soulPoints', greatest(v_balance, 0)
    );
  end if;

  v_balance := v_balance + v_granted;

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
    v_clean_request_id,
    v_clean_request_id,
    v_today,
    v_balance,
    v_metadata || jsonb_build_object(
      'adNetwork', v_clean_ad_network,
      'placementCode', v_clean_placement_code,
      'clientRequestedAmount', v_requested_amount,
      'rewardPerWatch', v_reward_per_watch,
      'dailyLimit', v_daily_limit,
      'timezone', v_timezone
    ),
    v_now
  );

  return jsonb_build_object(
    'granted', true,
    'idempotent', false,
    'rewardAwarded', v_granted,
    'rewardPerWatch', v_reward_per_watch,
    'dailyLimit', v_daily_limit,
    'todayEarned', v_today_earned + v_granted,
    'remaining', greatest(v_daily_limit - (v_today_earned + v_granted), 0),
    'soulPoints', greatest(v_balance, 0)
  );
exception
  when unique_violation then
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
        'rewardPerWatch', v_reward_per_watch,
        'dailyLimit', v_daily_limit,
        'todayEarned', v_today_earned,
        'remaining', greatest(v_daily_limit - v_today_earned, 0),
        'soulPoints', greatest(v_existing_balance, 0)
      );
    end if;
    raise;
end;
$$;

revoke all on function public.grant_ad_reward(integer, text, text, text, jsonb, text) from public;
revoke all on function public.grant_ad_reward(integer, text, text, text, jsonb, text) from anon;
grant execute on function public.grant_ad_reward(integer, text, text, text, jsonb, text) to authenticated;
grant execute on function public.grant_ad_reward(integer, text, text, text, jsonb, text) to service_role;
