alter table public.user_profiles
  add column if not exists auth_mode text not null default 'registered';

alter table public.user_profiles
  drop constraint if exists user_profiles_auth_mode_check;

alter table public.user_profiles
  add constraint user_profiles_auth_mode_check
  check (auth_mode in ('anonymous', 'registered'));

update public.user_profiles up
set auth_mode = case
  when coalesce(u.is_anonymous, false) then 'anonymous'
  else 'registered'
end
from auth.users u
where u.id = up.id;

create or replace function public.sync_user_profile_auth_mode_from_auth()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_is_anonymous boolean := false;
begin
  select coalesce(u.is_anonymous, false)
  into v_is_anonymous
  from auth.users u
  where u.id = new.id;

  new.auth_mode := case
    when v_is_anonymous then 'anonymous'
    else 'registered'
  end;
  return new;
end;
$$;

drop trigger if exists trg_user_profiles_sync_auth_mode on public.user_profiles;
create trigger trg_user_profiles_sync_auth_mode
before insert or update on public.user_profiles
for each row execute function public.sync_user_profile_auth_mode_from_auth();

create or replace function public.cleanup_stale_anonymous_users(
  p_cutoff interval default interval '30 days'
)
returns integer
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_deleted integer := 0;
begin
  delete from auth.users u
  where coalesce(u.is_anonymous, false) is true
    and coalesce(
      (
        select up.last_active_at
        from public.user_profiles up
        where up.id = u.id
      ),
      u.last_sign_in_at,
      u.created_at
    ) < now() - p_cutoff;

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

revoke all on function public.cleanup_stale_anonymous_users(interval) from public;
revoke all on function public.cleanup_stale_anonymous_users(interval) from anon;
revoke all on function public.cleanup_stale_anonymous_users(interval) from authenticated;
grant execute on function public.cleanup_stale_anonymous_users(interval) to service_role;

do $$
declare
  v_job_id bigint;
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    for v_job_id in
      select jobid
      from cron.job
      where jobname = 'numverse_cleanup_anonymous_users'
    loop
      perform cron.unschedule(v_job_id);
    end loop;

    perform cron.schedule(
      'numverse_cleanup_anonymous_users',
      '15 3 * * *',
      $job$select public.cleanup_stale_anonymous_users(interval '30 days');$job$
    );
  end if;
end
$$;

create or replace function public.touch_user_profile_last_active()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_user_id uuid := new.owner_user_id;
begin
  if v_owner_user_id is null then
    return new;
  end if;

  update public.user_profiles
  set last_active_at = now(),
      updated_at = now()
  where id = v_owner_user_id;

  return new;
end;
$$;

drop trigger if exists trg_daily_checkins_touch_last_active on public.daily_checkins;
create trigger trg_daily_checkins_touch_last_active
after insert or update on public.daily_checkins
for each row execute function public.touch_user_profile_last_active();

drop trigger if exists trg_spend_events_touch_last_active on public.soul_point_spend_events;
create trigger trg_spend_events_touch_last_active
after insert on public.soul_point_spend_events
for each row execute function public.touch_user_profile_last_active();

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
  v_profiles jsonb := '[]'::jsonb;
  v_current_profile_id text;
  v_soul_points integer := 0;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  select u.email, coalesce(u.is_anonymous, false)
  into v_email, v_is_anonymous
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
    'currentStreak', 0,
    'dailyEarnings', 0,
    'lastCheckInAt', null,
    'compareProfiles', '[]'::jsonb,
    'selectedCompareProfileId', null
  );
end;
$$;

revoke all on function public.get_cloud_session_snapshot() from public;
revoke all on function public.get_cloud_session_snapshot() from anon;
grant execute on function public.get_cloud_session_snapshot() to authenticated;
grant execute on function public.get_cloud_session_snapshot() to service_role;
