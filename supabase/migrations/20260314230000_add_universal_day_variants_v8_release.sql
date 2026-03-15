-- Add day-of-year variants for universal_day in a new release (v8).
-- Source release: mobile_assets_20260314_v7 (vi/en)
-- Target release: mobile_assets_20260314_v8 (vi/en)

begin;

create or replace function public._numverse_make_universal_day_variant(
  p_base jsonb,
  p_locale text,
  p_shift integer
)
returns jsonb
language sql
immutable
as $$
with prep as (
  select
    case
      when coalesce(p_base->>'title', '') = '' then ''
      when p_shift = 1
        then (p_base->>'title') || case when p_locale = 'vi'
          then ' · Điều chỉnh'
          else ' · Recalibrate'
        end
      when p_shift = 2
        then (p_base->>'title') || case when p_locale = 'vi'
          then ' · Cân bằng'
          else ' · Balance'
        end
      else (p_base->>'title') || case when p_locale = 'vi'
        then ' · Mở rộng'
        else ' · Expand'
      end
    end as title_text,
    case
      when coalesce(p_base->>'energy_theme', '') = '' then ''
      when p_shift = 1
        then case when p_locale = 'vi'
          then 'Nhịp ngày: '
          else 'Daily pulse: '
        end || (p_base->>'energy_theme')
      when p_shift = 2
        then case when p_locale = 'vi'
          then 'Trọng tâm hôm nay: '
          else 'Today focus: '
        end || (p_base->>'energy_theme')
      else case when p_locale = 'vi'
        then 'Gợi ý mở rộng: '
        else 'Extended cue: '
      end || (p_base->>'energy_theme')
    end as energy_theme_text,
    case
      when coalesce(p_base->>'energy_manifestation', '') = '' then ''
      when p_shift = 1
        then case when p_locale = 'vi'
          then 'Biểu hiện thực tế: '
          else 'Practical signal: '
        end || (p_base->>'energy_manifestation')
      when p_shift = 2
        then case when p_locale = 'vi'
          then 'Điểm nhấn trong ngày: '
          else 'Day highlight: '
        end || (p_base->>'energy_manifestation')
      else case when p_locale = 'vi'
        then 'Góc nhìn mở rộng: '
        else 'Extended angle: '
      end || (p_base->>'energy_manifestation')
    end as energy_manifestation_text
)
select
  jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(
          p_base,
          '{title}',
          to_jsonb((select title_text from prep)),
          true
        ),
        '{energy_theme}',
        to_jsonb((select energy_theme_text from prep)),
        true
      ),
      '{energy_manifestation}',
      to_jsonb((select energy_manifestation_text from prep)),
      true
    ),
    '{keywords}',
    public._numverse_rotate_jsonb_array(
      coalesce(p_base->'keywords', '[]'::jsonb),
      p_shift
    ),
    true
  );
$$;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v8'::text, 'mobile_assets_20260314_v7'::text),
    ('en'::text, 'mobile_assets_20260314_v8'::text, 'mobile_assets_20260314_v7'::text)
)
insert into public.numerology_ledger_releases (locale, version, status, notes)
select
  d.locale,
  d.version,
  'draft',
  'Release v8: universal_day uses day_of_year_mod variants.'
from desired d
where not exists (
  select 1
  from public.numerology_ledger_releases r
  where r.locale = d.locale
    and r.version = d.version
);

with desired(locale, version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v8'::text),
    ('en'::text, 'mobile_assets_20260314_v8'::text)
)
delete from public.numerology_contents c
using public.numerology_ledger_releases r
join desired d
  on d.locale = r.locale
 and d.version = r.version
where c.release_id = r.id;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v8'::text, 'mobile_assets_20260314_v7'::text),
    ('en'::text, 'mobile_assets_20260314_v8'::text, 'mobile_assets_20260314_v7'::text)
)
insert into public.numerology_contents (
  release_id,
  content_type,
  number_key,
  payload_jsonb
)
select
  target.id,
  source.content_type,
  source.number_key,
  source.payload_jsonb
from desired d
join public.numerology_ledger_releases target
  on target.locale = d.locale
 and target.version = d.version
join public.numerology_ledger_releases source_release
  on source_release.locale = d.locale
 and source_release.version = d.source_version
join public.numerology_contents source
  on source.release_id = source_release.id;

with universal_base as (
  select
    c.id,
    r.locale,
    case
      when jsonb_typeof(c.payload_jsonb->'variants') = 'array'
        and jsonb_array_length(c.payload_jsonb->'variants') > 0
        then c.payload_jsonb->'variants'->0
      else c.payload_jsonb
    end as base_payload
  from public.numerology_contents c
  join public.numerology_ledger_releases r
    on r.id = c.release_id
  where r.version = 'mobile_assets_20260314_v8'
    and c.content_type = 'universal_day'
    and c.number_key ~ '^[0-9]+$'
)
update public.numerology_contents c
set
  payload_jsonb = jsonb_build_object(
    'variants',
    jsonb_build_array(
      u.base_payload,
      public._numverse_make_universal_day_variant(u.base_payload, u.locale, 1),
      public._numverse_make_universal_day_variant(u.base_payload, u.locale, 2),
      public._numverse_make_universal_day_variant(u.base_payload, u.locale, 3)
    ),
    'variant_strategy',
    'day_of_year_mod'
  ),
  updated_at = now()
from universal_base u
where c.id = u.id;

do $$
declare
  v_release_id uuid;
begin
  for v_release_id in
    select id
    from public.numerology_ledger_releases
    where version = 'mobile_assets_20260314_v8'
  loop
    perform public.publish_ledger_release(v_release_id);
  end loop;
end
$$;

commit;
