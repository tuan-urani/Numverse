-- Add birthday_matrix and name_matrix content in release v10.
-- Source release: mobile_assets_20260314_v9
-- Target release: mobile_assets_20260314_v10

begin;

do $$
declare
  rec record;
  v_release_id uuid;
  v_source_release_id uuid;
  v_numbers jsonb;
  v_birthday_payload jsonb;
  v_name_payload jsonb;
begin
  for rec in
    select *
    from (
      values
        ('vi'::text, 'mobile_assets_20260314_v10'::text, 'mobile_assets_20260314_v9'::text),
        ('en'::text, 'mobile_assets_20260314_v10'::text, 'mobile_assets_20260314_v9'::text)
    ) as t(locale, target_version, source_version)
  loop
    insert into public.numerology_ledger_releases (locale, version, status, notes)
    select
      rec.locale,
      rec.target_version,
      'draft',
      'Release v10: add birthday_matrix + name_matrix with count/axis/arrow mapping.'
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

    select jsonb_object_agg(
      n::text,
      jsonb_build_object(
        'strength',
        case
          when rec.locale = 'vi' then format('Nang luong so %s giup ban van hanh on dinh.', n)
          else format('Number %s supports stable execution energy.', n)
        end,
        'lesson',
        case
          when rec.locale = 'vi' then format('Bai hoc so %s la can bang va ky luat.', n)
          else format('Lesson of number %s is balance and discipline.', n)
        end,
        'strength_by_count',
        jsonb_build_object(
          '1',
          case
            when rec.locale = 'vi' then format('So %s xuat hien 1 lan: nang luong can bang.', n)
            else format('Number %s appears once: balanced energy.', n)
          end,
          '2_plus',
          case
            when rec.locale = 'vi' then format('So %s lap lai: nang luong noi troi can dieu huong ro.', n)
            else format('Number %s repeats: amplified energy needs clear direction.', n)
          end
        )
      )
      order by n
    )
    into v_numbers
    from generate_series(1, 9) as gs(n);

    v_birthday_payload := jsonb_build_object(
      'numbers', v_numbers,
      'physical_axis', jsonb_build_object(
        'name', case when rec.locale = 'vi' then 'Truc Hanh dong' else 'Action Axis' end,
        'description', case when rec.locale = 'vi' then 'Cot 1-4-7 the hien thuc thi.' else '1-4-7 reflects execution.' end,
        'present_description', case when rec.locale = 'vi' then 'Ban co xu huong bien y tuong thanh hanh dong.' else 'You convert ideas into action.' end,
        'missing_description', case when rec.locale = 'vi' then 'Can tang ky luat va cac buoc nho.' else 'Increase discipline and small execution steps.' end,
        'description_by_count', jsonb_build_object(
          '0', case when rec.locale = 'vi' then 'Truc hanh dong trong.' else 'Action axis is empty.' end,
          '1', case when rec.locale = 'vi' then 'Ban co nen hanh dong co ban.' else 'You have baseline action energy.' end,
          '2', case when rec.locale = 'vi' then 'Ban co kha nang thuc thi kha on.' else 'You have solid execution momentum.' end,
          '3', case when rec.locale = 'vi' then 'Truc hanh dong day du, loi the manh.' else 'Full action axis gives a strong advantage.' end
        )
      ),
      'mental_axis', jsonb_build_object(
        'name', case when rec.locale = 'vi' then 'Truc Tu duy' else 'Mental Axis' end,
        'description', case when rec.locale = 'vi' then 'Cot 3-6-9 the hien tu duy.' else '3-6-9 reflects cognition.' end,
        'present_description', case when rec.locale = 'vi' then 'Ban co tu duy tong hop tot.' else 'You carry good synthesis ability.' end,
        'missing_description', case when rec.locale = 'vi' then 'Can luyen lap ke hoach va cau truc.' else 'Train planning and structure.' end,
        'description_by_count', jsonb_build_object(
          '0', case when rec.locale = 'vi' then 'Truc tu duy trong.' else 'Mental axis is empty.' end,
          '1', case when rec.locale = 'vi' then 'Ban co nen tu duy co ban.' else 'You have baseline mental clarity.' end,
          '2', case when rec.locale = 'vi' then 'Tu duy kha on.' else 'Mental flow is fairly stable.' end,
          '3', case when rec.locale = 'vi' then 'Truc tu duy day du, tam nhin manh.' else 'Full mental axis supports strong perspective.' end
        )
      ),
      'emotional_axis', jsonb_build_object(
        'name', case when rec.locale = 'vi' then 'Truc Cam xuc' else 'Emotional Axis' end,
        'description', case when rec.locale = 'vi' then 'Cot 2-5-8 the hien cam xuc.' else '2-5-8 reflects emotional balance.' end,
        'present_description', case when rec.locale = 'vi' then 'Ban co kha nang dieu tiet cam xuc.' else 'You regulate emotions effectively.' end,
        'missing_description', case when rec.locale = 'vi' then 'Can luyen nhan dien cam xuc va ranh gioi.' else 'Practice emotional awareness and boundaries.' end,
        'description_by_count', jsonb_build_object(
          '0', case when rec.locale = 'vi' then 'Truc cam xuc trong.' else 'Emotional axis is empty.' end,
          '1', case when rec.locale = 'vi' then 'Ban co nen cam xuc co ban.' else 'You have baseline emotional sensing.' end,
          '2', case when rec.locale = 'vi' then 'Cam xuc kha can bang.' else 'Emotional flow is fairly balanced.' end,
          '3', case when rec.locale = 'vi' then 'Truc cam xuc day du, ket noi sau.' else 'Full emotional axis supports deep connection.' end
        )
      ),
      'arrows', jsonb_build_object(
        'determination', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Quyet tam' else 'Arrow of Determination' end,
          'numbers', jsonb_build_array(3, 5, 7),
          'present_description', case when rec.locale = 'vi' then 'Ban ben bi va theo duoi muc tieu den cung.' else 'You sustain effort under pressure.' end,
          'missing_description', case when rec.locale = 'vi' then 'Chia muc tieu thanh chang ngan de de theo doi.' else 'Split goals into short milestones.' end
        ),
        'planning', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Ke hoach' else 'Arrow of Planning' end,
          'numbers', jsonb_build_array(1, 2, 3),
          'present_description', case when rec.locale = 'vi' then 'Ban co kha nang lap ke hoach ro rang.' else 'You plan and prioritize clearly.' end,
          'missing_description', case when rec.locale = 'vi' then 'Dung checklist truoc viec quan trong.' else 'Use checklist before major tasks.' end
        ),
        'willpower', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Y chi' else 'Arrow of Willpower' end,
          'numbers', jsonb_build_array(4, 5, 6),
          'present_description', case when rec.locale = 'vi' then 'Ban co noi luc va giu cam ket tot.' else 'You have strong inner commitment.' end,
          'missing_description', case when rec.locale = 'vi' then 'Ren thoi quen lap lai de tang ky luat.' else 'Build discipline through repeatable routines.' end
        ),
        'activity', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Nang dong' else 'Arrow of Activity' end,
          'numbers', jsonb_build_array(1, 5, 9),
          'present_description', case when rec.locale = 'vi' then 'Ban chu dong va san sang bat dau nhanh.' else 'You are proactive and ready to initiate.' end,
          'missing_description', case when rec.locale = 'vi' then 'Can tang nhip hanh dong qua muc tieu ngan han.' else 'Increase action rhythm with short cycles.' end
        ),
        'sensitivity', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Nhay cam' else 'Arrow of Sensitivity' end,
          'numbers', jsonb_build_array(3, 6, 9),
          'present_description', case when rec.locale = 'vi' then 'Ban nhay ben boi canh va de dong cam.' else 'You are context-aware and empathic.' end,
          'missing_description', case when rec.locale = 'vi' then 'Luyen lang nghe sau truoc khi phan hoi.' else 'Practice deeper listening before reacting.' end
        ),
        'frustration', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Bon chon' else 'Arrow of Frustration' end,
          'numbers', jsonb_build_array(4, 5, 6),
          'present_description', case when rec.locale = 'vi' then 'Ban de bon chon khi thieu cau truc, nen quan tri nhip nghi.' else 'Restlessness can appear without structure; manage recovery cycles.' end,
          'missing_description', case when rec.locale = 'vi' then 'Ban giu nhip on dinh kha tot.' else 'You keep relatively stable rhythm.' end
        ),
        'success', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Thanh tuu' else 'Arrow of Success' end,
          'numbers', jsonb_build_array(7, 8, 9),
          'present_description', case when rec.locale = 'vi' then 'To hop nay ho tro thanh tuu dai han.' else 'This pattern supports long-term achievement.' end,
          'missing_description', case when rec.locale = 'vi' then 'Ket hop ky luat va tam nhin de tang ket qua.' else 'Blend discipline and vision to improve outcomes.' end
        ),
        'spirituality', jsonb_build_object(
          'title', case when rec.locale = 'vi' then 'Mui ten Tam thuc' else 'Arrow of Spirituality' end,
          'numbers', jsonb_build_array(1, 5, 9),
          'present_description', case when rec.locale = 'vi' then 'Ban ket noi duoc truc giac va hanh dong.' else 'You align intuition and action.' end,
          'missing_description', case when rec.locale = 'vi' then 'Can thoi gian tinh de ket noi gia tri cot loi.' else 'Take quiet time to reconnect with core values.' end
        )
      )
    );

    v_name_payload := jsonb_build_object(
      'numbers', v_numbers,
      'physical_axis', jsonb_build_object(
        'name', case when rec.locale = 'vi' then 'Truc Hanh dong' else 'Action Axis' end,
        'description', case when rec.locale = 'vi' then 'Muc do thuc thi the hien qua ten.' else 'Execution tendency shown by name pattern.' end,
        'present_description', case when rec.locale = 'vi' then 'Ten ho tro cach the hien chu dong va dang tin.' else 'Name supports proactive and reliable expression.' end,
        'missing_description', case when rec.locale = 'vi' then 'Can dung ngon ngu hanh dong ro rang hon.' else 'Use clearer action language.' end
      ),
      'mental_axis', jsonb_build_object(
        'name', case when rec.locale = 'vi' then 'Truc Tu duy' else 'Mental Axis' end,
        'description', case when rec.locale = 'vi' then 'Muc do cau truc tu duy khi bieu dat.' else 'Mental structure in communication.' end,
        'present_description', case when rec.locale = 'vi' then 'Ten ho tro trinh bay logic va mach lac.' else 'Name supports logical and coherent expression.' end,
        'missing_description', case when rec.locale = 'vi' then 'Can bo sung cau truc khi trinh bay y tuong.' else 'Add more structure when presenting ideas.' end
      ),
      'emotional_axis', jsonb_build_object(
        'name', case when rec.locale = 'vi' then 'Truc Cam xuc' else 'Emotional Axis' end,
        'description', case when rec.locale = 'vi' then 'Muc do ket noi cam xuc trong giao tiep.' else 'Emotional resonance in communication.' end,
        'present_description', case when rec.locale = 'vi' then 'Ten ho tro su dong cam va ket noi.' else 'Name supports empathy and connection.' end,
        'missing_description', case when rec.locale = 'vi' then 'Can bo sung ngon ngu cam xuc trong doi thoai.' else 'Use more emotional language in dialogue.' end
      ),
      'arrows', jsonb_build_object()
    );

    insert into public.numerology_contents (
      release_id,
      content_type,
      number_key,
      payload_jsonb
    )
    values
      (v_release_id, 'birthday_matrix', 'default', v_birthday_payload),
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
