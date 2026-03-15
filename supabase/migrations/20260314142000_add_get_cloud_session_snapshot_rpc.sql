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
  v_profiles jsonb := '[]'::jsonb;
  v_current_profile_id text;
  v_soul_points integer := 0;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  select u.email
  into v_email
  from auth.users u
  where u.id = v_user_id;

  select up.display_name
  into v_display_name
  from public.user_profiles up
  where up.id = v_user_id;

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
    'currentStreak', 0,
    'dailyEarnings', 0,
    'lastCheckInAt', null
  );
end;
$$;

revoke all on function public.get_cloud_session_snapshot() from public;
revoke all on function public.get_cloud_session_snapshot() from anon;
grant execute on function public.get_cloud_session_snapshot() to authenticated;
grant execute on function public.get_cloud_session_snapshot() to service_role;
