create extension if not exists pgcrypto;

create table if not exists public.numerology_ledger_releases (
  id uuid primary key default gen_random_uuid(),
  locale text not null check (char_length(trim(locale)) > 0),
  version text not null check (char_length(trim(version)) > 0),
  status text not null check (status in ('draft', 'active', 'archived')),
  checksum text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  activated_at timestamptz
);

create table if not exists public.numerology_contents (
  id uuid primary key default gen_random_uuid(),
  release_id uuid not null references public.numerology_ledger_releases(id) on delete cascade,
  content_type text not null check (content_type in (
    'universal_day',
    'lucky_number',
    'daily_message',
    'angel_number',
    'number_library',
    'todaypersonalnumber',
    'month_personal_number',
    'year_personal_number'
  )),
  number_key text not null check (char_length(trim(number_key)) > 0),
  payload_jsonb jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists numerology_ledger_releases_active_locale_uidx
  on public.numerology_ledger_releases (locale)
  where status = 'active';

create index if not exists numerology_ledger_releases_locale_status_idx
  on public.numerology_ledger_releases (locale, status, updated_at desc);

create unique index if not exists numerology_contents_release_type_number_uidx
  on public.numerology_contents (release_id, content_type, number_key);

create index if not exists numerology_contents_release_type_number_idx
  on public.numerology_contents (release_id, content_type, number_key);

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_numerology_ledger_releases_updated_at'
  ) then
    create trigger set_numerology_ledger_releases_updated_at
    before update on public.numerology_ledger_releases
    for each row execute function public.set_updated_at();
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_numerology_contents_updated_at'
  ) then
    create trigger set_numerology_contents_updated_at
    before update on public.numerology_contents
    for each row execute function public.set_updated_at();
  end if;
end
$$;

alter table public.numerology_ledger_releases enable row level security;
alter table public.numerology_contents enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'numerology_ledger_releases'
      and policyname = 'numerology_ledger_releases_no_client_access'
  ) then
    create policy numerology_ledger_releases_no_client_access
      on public.numerology_ledger_releases
      for all
      to authenticated, anon
      using (false)
      with check (false);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'numerology_contents'
      and policyname = 'numerology_contents_no_client_access'
  ) then
    create policy numerology_contents_no_client_access
      on public.numerology_contents
      for all
      to authenticated, anon
      using (false)
      with check (false);
  end if;
end
$$;

create or replace function public.publish_ledger_release(p_release_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_release public.numerology_ledger_releases%rowtype;
  v_checksum text;
  v_content_count integer;
begin
  if auth.role() is not null and auth.role() <> 'service_role' then
    raise exception 'forbidden';
  end if;

  select *
  into v_release
  from public.numerology_ledger_releases
  where id = p_release_id
  for update;

  if not found then
    raise exception 'ledger_release_not_found';
  end if;

  if trim(v_release.locale) = '' then
    raise exception 'invalid_locale';
  end if;

  select count(*)
  into v_content_count
  from public.numerology_contents
  where release_id = p_release_id;

  if v_content_count = 0 then
    raise exception 'ledger_release_empty';
  end if;

  select encode(
    extensions.digest(
      coalesce(
        string_agg(
          concat_ws('|', content_type, number_key, payload_jsonb::text),
          E'\n'
          order by content_type, number_key
        ),
        ''
      ),
      'sha256'
    ),
    'hex'
  )
  into v_checksum
  from public.numerology_contents
  where release_id = p_release_id;

  update public.numerology_ledger_releases
  set status = 'archived',
      updated_at = now()
  where locale = v_release.locale
    and status = 'active'
    and id <> p_release_id;

  update public.numerology_ledger_releases
  set status = 'active',
      checksum = v_checksum,
      activated_at = now(),
      updated_at = now()
  where id = p_release_id;

  return jsonb_build_object(
    'release_id', p_release_id,
    'locale', v_release.locale,
    'version', v_release.version,
    'checksum', v_checksum,
    'content_count', v_content_count,
    'activated_at', now()
  );
end;
$$;

create or replace function public.get_ledger(
  p_locale text,
  p_client_version text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_requested_locale text := lower(coalesce(nullif(trim(p_locale), ''), 'vi'));
  v_release_id uuid;
  v_release_locale text;
  v_release_version text;
  v_release_checksum text;
  v_ledger jsonb;
begin
  select id, locale, version, checksum
  into v_release_id, v_release_locale, v_release_version, v_release_checksum
  from public.numerology_ledger_releases
  where status = 'active'
    and locale = v_requested_locale
  order by activated_at desc nulls last, updated_at desc
  limit 1;

  if v_release_id is null then
    select id, locale, version, checksum
    into v_release_id, v_release_locale, v_release_version, v_release_checksum
    from public.numerology_ledger_releases
    where status = 'active'
      and locale = 'vi'
    order by activated_at desc nulls last, updated_at desc
    limit 1;
  end if;

  if v_release_id is null then
    raise exception 'ledger_not_available';
  end if;

  if p_client_version is not null
     and trim(p_client_version) <> ''
     and trim(p_client_version) = v_release_version then
    return jsonb_build_object(
      'not_modified', true,
      'version', v_release_version,
      'checksum', coalesce(v_release_checksum, '')
    );
  end if;

  with type_group as (
    select
      content_type,
      jsonb_object_agg(number_key, payload_jsonb order by number_key) as content_by_number
    from public.numerology_contents
    where release_id = v_release_id
    group by content_type
  )
  select coalesce(
    jsonb_object_agg(content_type, content_by_number order by content_type),
    '{}'::jsonb
  )
  into v_ledger
  from type_group;

  return jsonb_build_object(
    'not_modified', false,
    'version', v_release_version,
    'checksum', coalesce(v_release_checksum, ''),
    'locale', v_release_locale,
    'ledger', v_ledger
  );
end;
$$;

revoke all on function public.publish_ledger_release(uuid) from public;
grant execute on function public.publish_ledger_release(uuid) to service_role;

revoke all on function public.get_ledger(text, text) from public;
grant execute on function public.get_ledger(text, text) to anon, authenticated, service_role;
