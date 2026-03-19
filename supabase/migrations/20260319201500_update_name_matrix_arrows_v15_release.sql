-- Add name_matrix arrows content (currently empty {}) for vi/en.
-- Source release: CURRENT ACTIVE release per locale (vi/en)
-- Target release: mobile_assets_20260326_pro_max_name_matrix_arrows_v1 (vi/en)

begin;

do $$
declare
  rec record;
  v_release_id uuid;
  v_source_release_id uuid;
  v_source_version text;
  v_name_payload jsonb;
  v_arrows jsonb;
begin
  for rec in
    select *
    from (
      values
        ('vi'::text, 'mobile_assets_20260326_pro_max_name_matrix_arrows_v1'::text),
        ('en'::text, 'mobile_assets_20260326_pro_max_name_matrix_arrows_v1'::text)
    ) as t(locale, target_version)
  loop
    insert into public.numerology_ledger_releases (locale, version, status, notes)
    select
      rec.locale,
      rec.target_version,
      'draft',
      'Release v15: add name_matrix arrows payload for chart insights.'
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
    order by activated_at desc nulls last, updated_at desc
    limit 1;

    if v_release_id is null then
      raise exception 'missing_target_release_for_locale=%', rec.locale;
    end if;

    if v_source_release_id is null then
      raise exception 'missing_active_source_release locale=%', rec.locale;
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
    into v_name_payload
    from public.numerology_contents c
    where c.release_id = v_source_release_id
      and c.content_type = 'name_matrix'
      and c.number_key = 'default'
    limit 1;

    if v_name_payload is null then
      raise exception 'missing_name_matrix_payload_for_locale=%', rec.locale;
    end if;

    v_arrows := jsonb_build_object(
      'determination', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Quyết tâm' else 'Determination' end,
        'numbers', jsonb_build_array(3, 5, 7),
        'present_description', case when rec.locale = 'vi'
          then 'Tên của bạn tạo cảm giác bền bỉ, theo đuổi mục tiêu đến cùng.'
          else 'Your name energy conveys persistence and long-run commitment.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Hãy chốt mốc thời gian rõ để duy trì nhịp theo đuổi mục tiêu.'
          else 'Set clear milestones to keep your progress consistent.' end
      ),
      'planning', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Kế hoạch' else 'Planning' end,
        'numbers', jsonb_build_array(1, 2, 3),
        'present_description', case when rec.locale = 'vi'
          then 'Bạn có xu hướng trình bày ý tưởng theo cấu trúc rõ ràng.'
          else 'You tend to express ideas with clear structure and sequence.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Nên chia thông điệp thành mục tiêu, bước làm và thời hạn.'
          else 'Split communication into goal, steps, and timeline.' end
      ),
      'willpower', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Ý chí' else 'Willpower' end,
        'numbers', jsonb_build_array(4, 5, 6),
        'present_description', case when rec.locale = 'vi'
          then 'Bạn thể hiện nội lực tốt và khả năng giữ cam kết ổn định.'
          else 'You project steady inner drive and commitment discipline.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Duy trì thói quen nhỏ mỗi ngày để tăng độ bền ý chí.'
          else 'Build repeatable daily habits to strengthen consistency.' end
      ),
      'activity', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Năng động' else 'Activity' end,
        'numbers', jsonb_build_array(1, 5, 9),
        'present_description', case when rec.locale = 'vi'
          then 'Năng lượng tên cho thấy sự chủ động và phản ứng nhanh.'
          else 'Your name pattern reflects proactivity and fast response.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Ưu tiên hành động đầu tiên trong 24 giờ để giữ đà.'
          else 'Take the first concrete step within 24 hours to keep momentum.' end
      ),
      'sensitivity', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Nhạy cảm' else 'Sensitivity' end,
        'numbers', jsonb_build_array(3, 6, 9),
        'present_description', case when rec.locale = 'vi'
          then 'Bạn dễ nắm bắt cảm xúc người đối diện và phản hồi tinh tế.'
          else 'You naturally read emotional context and respond with nuance.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Lắng nghe sâu hơn trước khi phản hồi để tăng kết nối.'
          else 'Pause and listen deeper before responding to improve connection.' end
      ),
      'frustration', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Bồn chồn' else 'Frustration' end,
        'numbers', jsonb_build_array(4, 5, 6),
        'present_description', case when rec.locale = 'vi'
          then 'Khi áp lực tăng, bạn dễ bồn chồn; cần quản trị nhịp nghỉ hợp lý.'
          else 'Under pressure, restlessness can rise; pace recovery intentionally.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Bạn giữ nhịp tương đối ổn định và ít bị cuốn theo nôn nóng.'
          else 'You generally keep stable pace with lower impulsive tension.' end
      ),
      'success', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Thành tựu' else 'Success' end,
        'numbers', jsonb_build_array(7, 8, 9),
        'present_description', case when rec.locale = 'vi'
          then 'Tổ hợp này hỗ trợ tư duy kết quả và năng lực phát triển dài hạn.'
          else 'This pattern supports result focus and long-term growth.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Kết hợp tầm nhìn và kỷ luật tuần để cải thiện hiệu quả.'
          else 'Pair vision with weekly discipline to improve outcomes.' end
      ),
      'spirituality', jsonb_build_object(
        'title', case when rec.locale = 'vi' then 'Tâm thức' else 'Spirituality' end,
        'numbers', jsonb_build_array(1, 5, 9),
        'present_description', case when rec.locale = 'vi'
          then 'Bạn có khả năng kết nối trực giác với hành động thực tế.'
          else 'You can align intuition with practical action.' end,
        'missing_description', case when rec.locale = 'vi'
          then 'Dành khoảng lặng ngắn mỗi ngày để làm rõ giá trị cốt lõi.'
          else 'Use short daily quiet moments to reconnect with core values.' end
      )
    );

    v_name_payload := jsonb_set(v_name_payload, '{arrows}', v_arrows, true);

    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    values
      (v_release_id, 'name_matrix', 'default', v_name_payload)
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
