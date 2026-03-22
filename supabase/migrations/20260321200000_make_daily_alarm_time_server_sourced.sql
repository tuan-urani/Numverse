create or replace function public.get_daily_alarm_settings()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_enabled boolean := true;
  v_time time := '08:00:00'::time;
  v_timezone text := 'Asia/Ho_Chi_Minh';
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  insert into public.user_settings (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select
    us.daily_notification_enabled,
    coalesce(us.daily_notification_time, '08:00:00'::time),
    coalesce(nullif(trim(us.timezone), ''), 'Asia/Ho_Chi_Minh')
  into
    v_enabled,
    v_time,
    v_timezone
  from public.user_settings us
  where us.user_id = v_user_id;

  return jsonb_build_object(
    'enabled', coalesce(v_enabled, true),
    'time', coalesce(v_time, '08:00:00'::time),
    'timezone', v_timezone
  );
end;
$$;

create or replace function public.update_daily_alarm_settings(
  p_enabled boolean,
  p_time time default null,
  p_timezone text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_timezone text;
  v_existing_time time;
  v_enabled boolean := coalesce(p_enabled, true);
  v_time time;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  select
    coalesce(
      nullif(trim(p_timezone), ''),
      nullif(trim(us.timezone), ''),
      'Asia/Ho_Chi_Minh'
    ),
    us.daily_notification_time
  into
    v_timezone,
    v_existing_time
  from public.user_settings us
  where us.user_id = v_user_id;

  if v_timezone is null or trim(v_timezone) = '' then
    v_timezone := 'Asia/Ho_Chi_Minh';
  end if;

  v_time := coalesce(p_time, v_existing_time, '08:00:00'::time);

  insert into public.user_settings (
    user_id,
    timezone,
    daily_notification_enabled,
    daily_notification_time
  )
  values (
    v_user_id,
    v_timezone,
    v_enabled,
    v_time
  )
  on conflict (user_id) do update
    set timezone = v_timezone,
        daily_notification_enabled = v_enabled,
        daily_notification_time = v_time,
        updated_at = now();

  return jsonb_build_object(
    'enabled', v_enabled,
    'time', v_time,
    'timezone', v_timezone
  );
end;
$$;

revoke all on function public.get_daily_alarm_settings() from public;
revoke all on function public.get_daily_alarm_settings() from anon;
grant execute on function public.get_daily_alarm_settings() to authenticated;
grant execute on function public.get_daily_alarm_settings() to service_role;

revoke all on function public.update_daily_alarm_settings(boolean, time, text) from public;
revoke all on function public.update_daily_alarm_settings(boolean, time, text) from anon;
grant execute on function public.update_daily_alarm_settings(boolean, time, text) to authenticated;
grant execute on function public.update_daily_alarm_settings(boolean, time, text) to service_role;
