create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'admin_users'
      and policyname = 'admin_users_no_client_access'
  ) then
    create policy admin_users_no_client_access
      on public.admin_users
      for all
      using (false)
      with check (false);
  end if;
end $$;

create or replace function public.is_admin_user(
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists(
    select 1
    from public.admin_users
    where user_id = coalesce(p_user_id, auth.uid())
  );
$$;

create or replace function public.assert_admin_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if not public.is_admin_user(v_user_id) then
    raise exception 'forbidden';
  end if;
end;
$$;

create or replace function public.admin_get_ledger_releases(
  p_locale text default null
)
returns table (
  id uuid,
  locale text,
  version text,
  status text,
  checksum text,
  notes text,
  content_count bigint,
  created_at timestamptz,
  updated_at timestamptz,
  activated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_locale text := lower(coalesce(nullif(trim(p_locale), ''), ''));
begin
  perform public.assert_admin_user();

  return query
  select
    r.id,
    r.locale,
    r.version,
    r.status,
    r.checksum,
    r.notes,
    (
      select count(*)
      from public.numerology_contents c
      where c.release_id = r.id
    ) as content_count,
    r.created_at,
    r.updated_at,
    r.activated_at
  from public.numerology_ledger_releases r
  where v_locale = '' or r.locale = v_locale
  order by
    case r.status
      when 'active' then 0
      when 'draft' then 1
      else 2
    end,
    coalesce(r.activated_at, r.updated_at) desc;
end;
$$;

create or replace function public.admin_get_ledger_contents(
  p_release_id uuid,
  p_content_type text default null,
  p_search text default null,
  p_limit integer default 300,
  p_offset integer default 0
)
returns table (
  id uuid,
  release_id uuid,
  content_type text,
  number_key text,
  payload_jsonb jsonb,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_content_type text := lower(coalesce(nullif(trim(p_content_type), ''), ''));
  v_search text := lower(coalesce(nullif(trim(p_search), ''), ''));
  v_limit integer := greatest(1, least(coalesce(p_limit, 300), 1000));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
begin
  perform public.assert_admin_user();

  if p_release_id is null then
    raise exception 'missing_release_id';
  end if;

  return query
  select
    c.id,
    c.release_id,
    c.content_type,
    c.number_key,
    c.payload_jsonb,
    c.updated_at
  from public.numerology_contents c
  where c.release_id = p_release_id
    and (v_content_type = '' or c.content_type = v_content_type)
    and (
      v_search = ''
      or lower(c.content_type) like ('%' || v_search || '%')
      or lower(c.number_key) like ('%' || v_search || '%')
    )
  order by c.content_type asc, c.number_key asc
  limit v_limit
  offset v_offset;
end;
$$;

create or replace function public.admin_upsert_ledger_content(
  p_release_id uuid,
  p_content_type text,
  p_number_key text,
  p_payload_jsonb jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_content_type text := lower(coalesce(nullif(trim(p_content_type), ''), ''));
  v_number_key text := trim(coalesce(p_number_key, ''));
  v_release_status text;
  v_content_id uuid;
begin
  perform public.assert_admin_user();

  if p_release_id is null then
    raise exception 'missing_release_id';
  end if;
  if v_content_type = '' then
    raise exception 'missing_content_type';
  end if;
  if v_number_key = '' then
    raise exception 'missing_number_key';
  end if;
  if p_payload_jsonb is null then
    raise exception 'missing_payload_jsonb';
  end if;
  if not public.is_valid_numerology_payload(p_payload_jsonb) then
    raise exception 'invalid_payload_jsonb';
  end if;

  select status
  into v_release_status
  from public.numerology_ledger_releases
  where id = p_release_id;

  if not found then
    raise exception 'ledger_release_not_found';
  end if;
  if v_release_status <> 'draft' then
    raise exception 'release_not_draft';
  end if;

  insert into public.numerology_contents (
    release_id,
    content_type,
    number_key,
    payload_jsonb
  )
  values (
    p_release_id,
    v_content_type,
    v_number_key,
    p_payload_jsonb
  )
  on conflict (release_id, content_type, number_key)
  do update
  set payload_jsonb = excluded.payload_jsonb,
      updated_at = now()
  returning id into v_content_id;

  return v_content_id;
end;
$$;

create or replace function public.admin_create_ledger_release_draft(
  p_locale text,
  p_version text,
  p_notes text default null,
  p_clone_from_release_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_locale text := lower(trim(coalesce(p_locale, '')));
  v_version text := trim(coalesce(p_version, ''));
  v_new_release_id uuid;
  v_clone_source_id uuid := p_clone_from_release_id;
begin
  perform public.assert_admin_user();

  if v_locale = '' then
    raise exception 'missing_locale';
  end if;
  if v_version = '' then
    raise exception 'missing_version';
  end if;

  if exists (
    select 1
    from public.numerology_ledger_releases
    where locale = v_locale
      and version = v_version
  ) then
    raise exception 'duplicate_release_version';
  end if;

  if v_clone_source_id is null then
    select id
    into v_clone_source_id
    from public.numerology_ledger_releases
    where locale = v_locale
      and status = 'active'
    order by activated_at desc nulls last, updated_at desc
    limit 1;
  end if;

  insert into public.numerology_ledger_releases (
    locale,
    version,
    status,
    notes
  )
  values (
    v_locale,
    v_version,
    'draft',
    nullif(trim(coalesce(p_notes, '')), '')
  )
  returning id into v_new_release_id;

  if v_clone_source_id is not null then
    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    select
      v_new_release_id,
      c.content_type,
      c.number_key,
      c.payload_jsonb
    from public.numerology_contents c
    where c.release_id = v_clone_source_id;
  end if;

  return v_new_release_id;
end;
$$;

create or replace function public.admin_publish_ledger_release(
  p_release_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_release public.numerology_ledger_releases%rowtype;
  v_checksum text;
  v_content_count integer;
  v_invalid_payload_count integer;
begin
  perform public.assert_admin_user();

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

  select count(*)
  into v_invalid_payload_count
  from public.numerology_contents
  where release_id = p_release_id
    and not public.is_valid_numerology_payload(payload_jsonb);

  if v_invalid_payload_count > 0 then
    raise exception 'ledger_release_invalid_payload';
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

revoke all on function public.is_admin_user(uuid) from public;
grant execute on function public.is_admin_user(uuid) to authenticated, service_role;

revoke all on function public.assert_admin_user() from public;
grant execute on function public.assert_admin_user() to authenticated, service_role;

revoke all on function public.admin_get_ledger_releases(text) from public;
grant execute on function public.admin_get_ledger_releases(text) to authenticated, service_role;

revoke all on function public.admin_get_ledger_contents(uuid, text, text, integer, integer) from public;
grant execute on function public.admin_get_ledger_contents(uuid, text, text, integer, integer) to authenticated, service_role;

revoke all on function public.admin_upsert_ledger_content(uuid, text, text, jsonb) from public;
grant execute on function public.admin_upsert_ledger_content(uuid, text, text, jsonb) to authenticated, service_role;

revoke all on function public.admin_create_ledger_release_draft(text, text, text, uuid) from public;
grant execute on function public.admin_create_ledger_release_draft(text, text, text, uuid) to authenticated, service_role;

revoke all on function public.admin_publish_ledger_release(uuid) from public;
grant execute on function public.admin_publish_ledger_release(uuid) to authenticated, service_role;
