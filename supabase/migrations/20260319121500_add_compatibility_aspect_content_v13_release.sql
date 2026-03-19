-- Add compatibility_content entries per aspect-band in release v13.
-- Source release: mobile_assets_20260314_v12 (vi/en)
-- Target release: mobile_assets_20260319_v13 (vi/en)
-- Safe clone strategy:
-- 1) Ensure target release exists
-- 2) Copy missing rows from source release (without deleting current target data)
-- 3) Create missing aspect-band keys by cloning target overall band (fallback to source)
-- 4) Never overwrite existing aspect-band rows

begin;

do $$
declare
  rec record;
  v_release_id uuid;
  v_source_release_id uuid;
begin
  for rec in
    select *
    from (
      values
        ('vi'::text, 'mobile_assets_20260319_v13'::text, 'mobile_assets_20260314_v12'::text),
        ('en'::text, 'mobile_assets_20260319_v13'::text, 'mobile_assets_20260314_v12'::text)
    ) as t(locale, target_version, source_version)
  loop
    insert into public.numerology_ledger_releases (locale, version, status, notes)
    select
      rec.locale,
      rec.target_version,
      'draft',
      'Release v13: add compatibility_content keys by aspect and score band.'
    where not exists (
      select 1
      from public.numerology_ledger_releases r
      where r.locale = rec.locale
        and r.version = rec.target_version
    );

    select id
    into v_release_id
    from public.numerology_ledger_releases
    where locale = rec.locale
      and version = rec.target_version
    limit 1;

    select id
    into v_source_release_id
    from public.numerology_ledger_releases
    where locale = rec.locale
      and version = rec.source_version
    limit 1;

    if v_release_id is null or v_source_release_id is null then
      raise exception 'missing_release_for_locale=%', rec.locale;
    end if;

    -- Clone missing rows from source release without deleting target data.
    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    select
      v_release_id,
      c.content_type,
      c.number_key,
      c.payload_jsonb
    from public.numerology_contents c
    where c.release_id = v_source_release_id
    on conflict (release_id, content_type, number_key) do nothing;

    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    select
      v_release_id,
      'compatibility_content',
      a.aspect || '.' || b.band,
      coalesce(target_band.payload_jsonb, src.payload_jsonb)
    from (
      values
        ('life_path'::text),
        ('expression'::text),
        ('soul'::text),
        ('personality'::text)
    ) as a(aspect)
    cross join (
      values
        ('excellent'::text),
        ('good'::text),
        ('moderate'::text),
        ('effort'::text)
    ) as b(band)
    left join public.numerology_contents target_band
      on target_band.release_id = v_release_id
     and target_band.content_type = 'compatibility_content'
     and target_band.number_key = b.band
    join public.numerology_contents src
      on src.release_id = v_source_release_id
     and src.content_type = 'compatibility_content'
     and src.number_key = b.band
    where coalesce(target_band.payload_jsonb, src.payload_jsonb) is not null
    on conflict (release_id, content_type, number_key) do nothing;
  end loop;
end
$$;

commit;
