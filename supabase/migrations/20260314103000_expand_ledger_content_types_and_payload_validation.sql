alter table if exists public.numerology_contents
  drop constraint if exists numerology_contents_content_type_check;

alter table if exists public.numerology_contents
  add constraint numerology_contents_content_type_check
  check (
    content_type in (
      'universal_day',
      'lucky_number',
      'daily_message',
      'angel_number',
      'number_library',
      'todaypersonalnumber',
      'month_personal_number',
      'year_personal_number',
      'life_path_number',
      'expression_number',
      'soul_urge_number',
      'mission_number',
      'birthday_matrix',
      'name_matrix',
      'life_pinnacle',
      'life_challenge'
    )
  );

alter table if exists public.numerology_contents
  drop constraint if exists numerology_contents_payload_jsonb_object_check;

alter table if exists public.numerology_contents
  add constraint numerology_contents_payload_jsonb_object_check
  check (jsonb_typeof(payload_jsonb) = 'object');

create or replace function public.is_valid_numerology_payload(p_payload jsonb)
returns boolean
language plpgsql
immutable
set search_path = public
as $$
begin
  if jsonb_typeof(p_payload) <> 'object' then
    return false;
  end if;

  if p_payload ? 'variants' then
    if jsonb_typeof(p_payload -> 'variants') <> 'array' then
      return false;
    end if;
    if jsonb_array_length(p_payload -> 'variants') = 0 then
      return false;
    end if;
  end if;

  return true;
end;
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
  v_invalid_payload_count integer;
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
