-- Add life_pinnacle and life_challenge content types in a new release (v11).
-- Source release: mobile_assets_20260314_v10 (vi/en)
-- Target release: mobile_assets_20260314_v11 (vi/en)

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
        ('vi'::text, 'mobile_assets_20260314_v11'::text, 'mobile_assets_20260314_v10'::text),
        ('en'::text, 'mobile_assets_20260314_v11'::text, 'mobile_assets_20260314_v10'::text)
    ) as t(locale, target_version, source_version)
  loop
    insert into public.numerology_ledger_releases (locale, version, status, notes)
    select
      rec.locale,
      rec.target_version,
      'draft',
      'Release v11: add life_pinnacle and life_challenge content types.'
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

    delete from public.numerology_contents where release_id = v_release_id;

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
    where c.release_id = v_source_release_id;

    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    select
      v_release_id,
      'life_pinnacle',
      source.number_key,
      jsonb_build_object(
        'theme',
        case
          when rec.locale = 'vi' then format('Đỉnh cao số %s', source.number_key)
          else format('Pinnacle %s', source.number_key)
        end,
        'description',
        case
          when rec.locale = 'vi'
            then format('Đây là nội dung seed cho đỉnh cao số %s. Bạn có thể chỉnh JSONB trong Supabase Admin.', source.number_key)
          else format('Seed content for pinnacle %s. You can edit this JSONB in Supabase Admin.', source.number_key)
        end,
        'opportunities',
        case
          when rec.locale = 'vi'
            then format('Cơ hội phát triển chính của giai đoạn mang năng lượng %s.', source.number_key)
          else format('Primary growth opportunity for phase energy %s.', source.number_key)
        end,
        'advice',
        case
          when rec.locale = 'vi'
            then format('Gợi ý hành động thực tế cho đỉnh cao số %s.', source.number_key)
          else format('Action guidance for pinnacle number %s.', source.number_key)
        end
      )
    from (
      values
        ('1'::text), ('2'::text), ('3'::text), ('4'::text), ('5'::text),
        ('6'::text), ('7'::text), ('8'::text), ('9'::text), ('11'::text), ('22'::text)
    ) as source(number_key)
    on conflict (release_id, content_type, number_key)
    do update
    set
      payload_jsonb = excluded.payload_jsonb,
      updated_at = now();

    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    select
      v_release_id,
      'life_challenge',
      source.number_key,
      jsonb_build_object(
        'theme',
        case
          when rec.locale = 'vi' then format('Thử thách số %s', source.number_key)
          else format('Challenge %s', source.number_key)
        end,
        'description',
        case
          when rec.locale = 'vi'
            then format('Đây là nội dung seed cho thử thách số %s. Bạn có thể chỉnh JSONB trong Supabase Admin.', source.number_key)
          else format('Seed content for challenge %s. You can edit this JSONB in Supabase Admin.', source.number_key)
        end,
        'opportunities',
        case
          when rec.locale = 'vi'
            then format('Cơ hội vượt qua và trưởng thành với thử thách %s.', source.number_key)
          else format('Growth opportunity when navigating challenge %s.', source.number_key)
        end,
        'advice',
        case
          when rec.locale = 'vi'
            then format('Lời khuyên thực hành cho thử thách số %s.', source.number_key)
          else format('Practical advice for challenge number %s.', source.number_key)
        end
      )
    from (
      values
        ('0'::text), ('1'::text), ('2'::text), ('3'::text), ('4'::text),
        ('5'::text), ('6'::text), ('7'::text), ('8'::text)
    ) as source(number_key)
    on conflict (release_id, content_type, number_key)
    do update
    set
      payload_jsonb = excluded.payload_jsonb,
      updated_at = now();

    perform public.publish_ledger_release(v_release_id);
  end loop;
end
$$;

commit;
