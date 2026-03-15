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
      'life_challenge',
      'compatibility_content'
    )
  );
