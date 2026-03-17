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
  v_is_anonymous boolean := false;
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

  select u.email, coalesce(u.is_anonymous, false)
  into v_email, v_is_anonymous
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
    'authMode', case
      when v_is_anonymous then 'anonymous'
      else 'registered'
    end,
    'pendingAnonymousBootstrap', false,
    'cloudUserId', v_user_id::text,
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
    'lastCheckInAt', v_last_checkin_at,
    'compareProfiles', '[]'::jsonb,
    'selectedCompareProfileId', null
  );
end;
$$;

revoke all on function public.get_cloud_session_snapshot() from public;
revoke all on function public.get_cloud_session_snapshot() from anon;
grant execute on function public.get_cloud_session_snapshot() to authenticated;
grant execute on function public.get_cloud_session_snapshot() to service_role;
