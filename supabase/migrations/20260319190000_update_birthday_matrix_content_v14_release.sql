-- Refresh birthday_matrix copy with production-quality number narratives (remove dummy placeholders).
-- Source release: ACTIVE mobile_assets_20260326_pro_max* per locale (vi/en)
-- Target release: mobile_assets_20260326_pro_max_matrix_refresh_v1 (vi/en)

begin;

do $$
declare
  rec record;
  v_release_id uuid;
  v_source_release_id uuid;
  v_source_version text;
  v_numbers jsonb;
  v_birthday_payload jsonb;
begin
  for rec in
    select *
    from (
      values
        ('vi'::text, 'mobile_assets_20260326_pro_max'::text, 'mobile_assets_20260326_pro_max_matrix_refresh_v1'::text),
        ('en'::text, 'mobile_assets_20260326_pro_max'::text, 'mobile_assets_20260326_pro_max_matrix_refresh_v1'::text)
    ) as t(locale, source_version_prefix, target_version)
  loop
    insert into public.numerology_ledger_releases (locale, version, status, notes)
    select
      rec.locale,
      rec.target_version,
      'draft',
      'Release v14: refresh birthday_matrix number narratives and count-based guidance.'
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

    select id, version
    into v_source_release_id, v_source_version
    from public.numerology_ledger_releases
    where locale = rec.locale
      and status = 'active'
      and version like rec.source_version_prefix || '%'
    order by activated_at desc nulls last, updated_at desc
    limit 1;

    if v_release_id is null then
      raise exception 'missing_target_release_for_locale=%', rec.locale;
    end if;

    if v_source_release_id is null then
      raise exception 'source_26_pro_max_not_active locale=% prefix=%', rec.locale, rec.source_version_prefix;
    end if;

    if v_source_version = rec.target_version then
      raise exception 'target_version_matches_active_source locale=% version=%',
        rec.locale,
        rec.target_version;
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

    select c.payload_jsonb
    into v_birthday_payload
    from public.numerology_contents c
    where c.release_id = v_source_release_id
      and c.content_type = 'birthday_matrix'
      and c.number_key = 'default'
    limit 1;

    if v_birthday_payload is null then
      raise exception 'missing_birthday_matrix_payload_for_locale=%', rec.locale;
    end if;

    select jsonb_object_agg(
      n::text,
      jsonb_build_object(
        'strength',
        case
          when rec.locale = 'vi' then format('Số %s là một trụ năng lượng tự nhiên trong biểu đồ ngày sinh của bạn.', n)
          else format('Number %s acts as a natural energy pillar in your birth chart.', n)
        end,
        'lesson',
        case
          when rec.locale = 'vi' then format('Bài học của số %s là dùng năng lượng này đúng nhịp và đúng mục tiêu.', n)
          else format('The lesson of number %s is to use this energy with timing and intention.', n)
        end,
        'strength_by_count',
        jsonb_build_object(
          '1',
          case
            when rec.locale = 'vi' then format('Số %s xuất hiện 1 lần: năng lượng nền vừa đủ, dễ cân bằng và phát triển bền vững.', n)
            else format('Number %s appears once: foundational energy is balanced and sustainable.', n)
          end,
          '2',
          case
            when rec.locale = 'vi' then format('Số %s xuất hiện 2 lần: đây là lợi thế nổi bật nếu bạn tập trung đúng hướng.', n)
            else format('Number %s appears twice: this becomes a clear advantage when focused well.', n)
          end,
          '3_plus',
          case
            when rec.locale = 'vi' then format('Số %s lặp lại nhiều: năng lượng tăng mạnh, cần kỷ luật để tránh quá đà.', n)
            else format('Number %s repeats often: amplified energy needs discipline to avoid excess.', n)
          end
        ),
        'lesson_by_count',
        jsonb_build_object(
          '0',
          case
            when rec.locale = 'vi' then format('Thiếu số %s: bạn cần rèn bù bằng thói quen nhỏ và môi trường hỗ trợ phù hợp.', n)
            else format('Missing number %s: build this quality through small habits and supportive context.', n)
          end,
          '1',
          case
            when rec.locale = 'vi' then format('Số %s có 1 lần: bài học là duy trì sự đều đặn để năng lượng không ngắt quãng.', n)
            else format('Number %s appears once: the lesson is consistency so this energy stays stable.', n)
          end,
          '2_plus',
          case
            when rec.locale = 'vi' then format('Số %s lặp lại: bài học là tiết chế và định hướng để dùng sức mạnh đúng chỗ.', n)
            else format('Number %s repeats: the lesson is regulation and direction for effective use.', n)
          end
        )
      )
      order by n
    )
    into v_numbers
    from generate_series(1, 9) as gs(n);

    v_birthday_payload := jsonb_set(v_birthday_payload, '{numbers}', v_numbers, true);

    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    values
      (v_release_id, 'birthday_matrix', 'default', v_birthday_payload)
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
