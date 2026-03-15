-- Add compatibility_content in release v12.
-- Source release: mobile_assets_20260314_v11 (vi/en)
-- Target release: mobile_assets_20260314_v12 (vi/en)

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
        ('vi'::text, 'mobile_assets_20260314_v12'::text, 'mobile_assets_20260314_v11'::text),
        ('en'::text, 'mobile_assets_20260314_v12'::text, 'mobile_assets_20260314_v11'::text)
    ) as t(locale, target_version, source_version)
  loop
    insert into public.numerology_ledger_releases (locale, version, status, notes)
    select
      rec.locale,
      rec.target_version,
      'draft',
      'Release v12: add compatibility_content by score band.'
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
    values
      (
        v_release_id,
        'compatibility_content',
        'excellent',
        jsonb_build_object(
          'strengths',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Hai bạn bổ trợ tự nhiên về nhịp sống và mục tiêu.',
              'Mức đồng điệu cao giúp giao tiếp đi vào trọng tâm.',
              'Năng lượng cảm xúc hỗ trợ nhau khi cần nâng đỡ.',
              'Có tiềm năng đồng hành dài hạn nếu giữ nhịp tôn trọng.'
            )
            else jsonb_build_array(
              'You naturally complement each other in rhythm and goals.',
              'Strong alignment supports clear and efficient communication.',
              'Emotional energy helps both partners feel supported.',
              'There is high long-term potential with mutual respect.'
            )
          end,
          'challenges',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Kỳ vọng cao có thể gây áp lực ngược.',
              'Dễ chủ quan khi mọi thứ đang thuận lợi.',
              'Mâu thuẫn nhỏ có thể bị bỏ qua quá lâu.'
            )
            else jsonb_build_array(
              'High expectations can create hidden pressure.',
              'It is easy to become complacent when things go well.',
              'Small conflicts can be postponed for too long.'
            )
          end,
          'advice',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Giữ check-in cảm xúc định kỳ.',
              'Thiết lập mục tiêu chung theo chu kỳ.',
              'Phân vai rõ khi ra quyết định quan trọng.',
              'Tôn trọng không gian riêng của nhau.'
            )
            else jsonb_build_array(
              'Keep regular emotional check-ins.',
              'Set shared goals by clear cycles.',
              'Clarify roles for major decisions.',
              'Respect each other’s personal space.'
            )
          end,
          'quote',
          case
            when rec.locale = 'vi'
              then 'Sự hòa hợp bền vững đến từ thấu hiểu nhất quán.'
            else 'Sustainable harmony is built through consistent understanding.'
          end
        )
      ),
      (
        v_release_id,
        'compatibility_content',
        'good',
        jsonb_build_object(
          'strengths',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Hai bạn có nền tảng tương hợp tốt.',
              'Nhiều điểm chung trong định hướng.',
              'Có khả năng nâng đỡ nhau khi áp lực.',
              'Mối quan hệ có dư địa phát triển dài hạn.'
            )
            else jsonb_build_array(
              'You have a solid compatibility foundation.',
              'There are many shared directions and values.',
              'You can support each other under pressure.',
              'The relationship has good long-term growth room.'
            )
          end,
          'challenges',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Khác biệt nhỏ trong giao tiếp dễ gây hiểu lầm.',
              'Nhịp hành động đôi lúc lệch pha.',
              'Dễ trì hoãn đối thoại khi va chạm nhẹ.'
            )
            else jsonb_build_array(
              'Minor communication differences may cause misunderstanding.',
              'Action pace can occasionally fall out of sync.',
              'Light conflicts may be postponed too often.'
            )
          end,
          'advice',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Thống nhất cách phản hồi khi bất đồng.',
              'Làm rõ ưu tiên ngắn hạn của từng người.',
              'Giữ một hoạt động kết nối cố định mỗi tuần.',
              'Đánh giá lại kỳ vọng chung định kỳ.'
            )
            else jsonb_build_array(
              'Agree on a response pattern during disagreements.',
              'Clarify short-term priorities for each person.',
              'Keep one fixed weekly bonding activity.',
              'Review shared expectations regularly.'
            )
          end,
          'quote',
          case
            when rec.locale = 'vi'
              then 'Tương hợp tốt là điểm khởi đầu mạnh cho hành trình dài.'
            else 'Good compatibility is a strong start for a long journey.'
          end
        )
      ),
      (
        v_release_id,
        'compatibility_content',
        'moderate',
        jsonb_build_object(
          'strengths',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Sự khác biệt tạo góc nhìn đa chiều.',
              'Có cơ hội học cách bổ sung cho nhau.',
              'Mỗi người có thể mở rộng vùng an toàn của đối phương.',
              'Tính thích nghi sẽ tăng khi cùng cam kết.'
            )
            else jsonb_build_array(
              'Differences bring broader perspectives.',
              'You can learn to complement each other.',
              'Each partner can expand the other’s comfort zone.',
              'Adaptability grows when commitment is mutual.'
            )
          end,
          'challenges',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Nhịp tư duy dễ lệch nếu thiếu kiên nhẫn.',
              'Xung đột giá trị nhỏ có thể lặp lại.',
              'Dễ phòng thủ khi cảm thấy không được thấu hiểu.'
            )
            else jsonb_build_array(
              'Thinking pace may diverge without patience.',
              'Small value conflicts can repeat over time.',
              'Defensiveness can appear when not feeling understood.'
            )
          end,
          'advice',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Ưu tiên lắng nghe trước khi phản biện.',
              'Thống nhất nguyên tắc xử lý mâu thuẫn từ sớm.',
              'Chia mục tiêu chung thành bước nhỏ.',
              'Ghi nhận tiến bộ thay vì chỉ nhìn vấn đề.'
            )
            else jsonb_build_array(
              'Prioritize listening before rebuttal.',
              'Agree on conflict rules early.',
              'Break shared goals into small steps.',
              'Track progress, not just problems.'
            )
          end,
          'quote',
          case
            when rec.locale = 'vi'
              then 'Khác biệt có thể trở thành sức mạnh khi cùng điều chỉnh.'
            else 'Differences can become strength when both adjust.'
          end
        )
      ),
      (
        v_release_id,
        'compatibility_content',
        'effort',
        jsonb_build_object(
          'strengths',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Mối quan hệ mang tiềm năng học bài học sâu.',
              'Có thể xây nền tảng mới từ sự trung thực.',
              'Nếu kiên định, hai bạn vẫn tạo được nhịp phù hợp.',
              'Thử thách hiện tại có thể trở thành bước trưởng thành lớn.'
            )
            else jsonb_build_array(
              'This relationship can teach deep life lessons.',
              'A new foundation can be built through honesty.',
              'With consistency, you can still find a workable rhythm.',
              'Current challenges can become major growth moments.'
            )
          end,
          'challenges',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Khác biệt lớn ở cách nhìn và phản ứng cảm xúc.',
              'Giao tiếp dễ rơi vào phòng thủ hoặc phán xét.',
              'Mất kết nối nhanh nếu thiếu cơ chế đối thoại rõ.'
            )
            else jsonb_build_array(
              'There are major differences in perspective and emotional response.',
              'Communication may become defensive or judgmental.',
              'Connection can drop quickly without clear dialogue structure.'
            )
          end,
          'advice',
          case
            when rec.locale = 'vi' then jsonb_build_array(
              'Đặt quy tắc tranh luận an toàn ngay từ đầu.',
              'Làm rõ ranh giới và nhu cầu cốt lõi.',
              'Sử dụng công cụ hỗ trợ giao tiếp khi cần.',
              'Đánh giá mối quan hệ bằng hành động thực tế.'
            )
            else jsonb_build_array(
              'Set safe conflict rules from the start.',
              'Clarify boundaries and core needs.',
              'Use communication support tools when needed.',
              'Evaluate the relationship through concrete actions.'
            )
          end,
          'quote',
          case
            when rec.locale = 'vi'
              then 'Tương hợp thấp đòi hỏi nỗ lực có kỷ luật và thay đổi thực chất.'
            else 'Low compatibility requires disciplined effort and real change.'
          end
        )
      )
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
