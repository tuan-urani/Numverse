create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  language text not null default 'vi',
  timezone text not null default 'Asia/Ho_Chi_Minh',
  daily_notification_enabled boolean not null default true,
  daily_notification_time time,
  marketing_opt_in boolean not null default false,
  analytics_opt_in boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if to_regprocedure('public.set_updated_at()') is not null
     and not exists (
       select 1
       from pg_trigger
       where tgname = 'set_user_settings_updated_at'
     ) then
    create trigger set_user_settings_updated_at
    before update on public.user_settings
    for each row execute function public.set_updated_at();
  end if;
end
$$;

alter table public.user_settings enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_settings'
      and policyname = 'user_settings_select_own'
  ) then
    create policy user_settings_select_own
      on public.user_settings for select to authenticated
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
      and tablename = 'user_settings'
      and policyname = 'user_settings_insert_own'
  ) then
    create policy user_settings_insert_own
      on public.user_settings for insert to authenticated
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
      and tablename = 'user_settings'
      and policyname = 'user_settings_update_own'
  ) then
    create policy user_settings_update_own
      on public.user_settings for update to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
      with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);
  end if;
end
$$;

create table if not exists public.content_templates (
  id uuid primary key default gen_random_uuid(),
  domain text not null,
  template_key text not null,
  locale text not null default 'vi-VN',
  title text not null,
  summary_template text not null,
  body_template text not null,
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if to_regprocedure('public.set_updated_at()') is not null
     and not exists (
       select 1
       from pg_trigger
       where tgname = 'set_content_templates_updated_at'
     ) then
    create trigger set_content_templates_updated_at
    before update on public.content_templates
    for each row execute function public.set_updated_at();
  end if;
end
$$;

alter table public.content_templates enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'content_templates'
      and policyname = 'content_templates_select_authenticated'
  ) then
    create policy content_templates_select_authenticated
      on public.content_templates for select to authenticated
      using (true);
  end if;
end
$$;

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

revoke all on function public.get_daily_alarm_template(text) from public;
revoke all on function public.get_daily_alarm_template(text) from anon;
grant execute on function public.get_daily_alarm_template(text) to authenticated;
grant execute on function public.get_daily_alarm_template(text) to service_role;
