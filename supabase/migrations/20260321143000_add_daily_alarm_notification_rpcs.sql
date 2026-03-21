create unique index if not exists content_templates_domain_key_locale_uidx
  on public.content_templates (domain, template_key, locale);

insert into public.content_templates (
  domain,
  template_key,
  locale,
  title,
  summary_template,
  body_template,
  metadata_json
)
values
  (
    'notification',
    'daily_energy_alarm',
    'vi',
    'Năng lượng hôm nay',
    'Mở app để xem năng lượng hôm nay của bạn.',
    'Mở app để xem năng lượng hôm nay của bạn.',
    jsonb_build_object('type', 'daily_alarm')
  ),
  (
    'notification',
    'daily_energy_alarm',
    'en',
    'Numverse Daily Energy',
    'Open app to check your energy today.',
    'Open app to check your energy today.',
    jsonb_build_object('type', 'daily_alarm')
  ),
  (
    'notification',
    'daily_energy_alarm',
    'ja',
    'Numverse 今日のエネルギー',
    'アプリを開いて今日のエネルギーを確認しましょう。',
    'アプリを開いて今日のエネルギーを確認しましょう。',
    jsonb_build_object('type', 'daily_alarm')
  )
on conflict (domain, template_key, locale) do update
  set title = excluded.title,
      summary_template = excluded.summary_template,
      body_template = excluded.body_template,
      metadata_json = excluded.metadata_json,
      updated_at = now();

create or replace function public.get_daily_alarm_settings()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_enabled boolean := true;
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
    coalesce(nullif(trim(us.timezone), ''), 'Asia/Ho_Chi_Minh')
  into
    v_enabled,
    v_timezone
  from public.user_settings us
  where us.user_id = v_user_id;

  return jsonb_build_object(
    'enabled', coalesce(v_enabled, true),
    'time', '08:00:00',
    'timezone', v_timezone
  );
end;
$$;

create or replace function public.update_daily_alarm_settings(
  p_enabled boolean,
  p_time time default '08:00:00'::time,
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
  v_enabled boolean := coalesce(p_enabled, true);
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  select
    coalesce(
      nullif(trim(p_timezone), ''),
      nullif(trim(us.timezone), ''),
      'Asia/Ho_Chi_Minh'
    )
  into v_timezone
  from public.user_settings us
  where us.user_id = v_user_id;

  if v_timezone is null or trim(v_timezone) = '' then
    v_timezone := 'Asia/Ho_Chi_Minh';
  end if;

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
    '08:00:00'::time
  )
  on conflict (user_id) do update
    set timezone = v_timezone,
        daily_notification_enabled = v_enabled,
        daily_notification_time = '08:00:00'::time,
        updated_at = now();

  return jsonb_build_object(
    'enabled', v_enabled,
    'time', '08:00:00',
    'timezone', v_timezone
  );
end;
$$;

create or replace function public.get_daily_alarm_template(
  p_locale text default 'vi'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_locale text := lower(trim(coalesce(p_locale, 'vi')));
  v_selected_locale text;
  v_title text;
  v_body text;
begin
  v_locale := replace(v_locale, '-', '_');
  if position('_' in v_locale) > 0 then
    v_locale := split_part(v_locale, '_', 1);
  end if;
  if v_locale not in ('vi', 'en', 'ja') then
    v_locale := 'vi';
  end if;

  select
    ct.locale,
    nullif(trim(ct.title), ''),
    coalesce(
      nullif(trim(ct.summary_template), ''),
      nullif(trim(ct.body_template), '')
    )
  into
    v_selected_locale,
    v_title,
    v_body
  from public.content_templates ct
  where ct.domain = 'notification'
    and ct.template_key = 'daily_energy_alarm'
    and ct.locale in (v_locale, 'en', 'vi')
  order by
    case
      when ct.locale = v_locale then 0
      when ct.locale = 'en' then 1
      when ct.locale = 'vi' then 2
      else 3
    end,
    ct.updated_at desc
  limit 1;

  if v_title is null or v_title = '' then
    v_title := case
      when v_locale = 'en' then 'Numverse Daily Energy'
      when v_locale = 'ja' then 'Numverse 今日のエネルギー'
      else 'Năng lượng hôm nay'
    end;
  end if;

  if v_body is null or v_body = '' then
    v_body := case
      when v_locale = 'en' then 'Open app to check your energy today.'
      when v_locale = 'ja' then 'アプリを開いて今日のエネルギーを確認しましょう。'
      else 'Mở app để xem năng lượng hôm nay của bạn.'
    end;
  end if;

  return jsonb_build_object(
    'locale', coalesce(v_selected_locale, v_locale),
    'title', v_title,
    'body', v_body
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

revoke all on function public.get_daily_alarm_template(text) from public;
revoke all on function public.get_daily_alarm_template(text) from anon;
grant execute on function public.get_daily_alarm_template(text) to authenticated;
grant execute on function public.get_daily_alarm_template(text) to service_role;
