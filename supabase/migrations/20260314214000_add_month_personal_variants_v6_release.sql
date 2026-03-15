-- Add day-of-year variants for month_personal_number in a new release (v6).
-- Source release: mobile_assets_20260314_v5 (vi/en)
-- Target release: mobile_assets_20260314_v6 (vi/en)

begin;

create or replace function public._numverse_make_month_personal_variant(
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
      when coalesce(p_base->>'keyword', '') = '' then ''
      when p_shift = 1
        then case when p_locale = 'vi'
          then 'Nhịp ngày: '
          else 'Daily pulse: '
        end || (p_base->>'keyword')
      when p_shift = 2
        then case when p_locale = 'vi'
          then 'Trọng tâm hôm nay: '
          else 'Today focus: '
        end || (p_base->>'keyword')
      else case when p_locale = 'vi'
        then 'Gợi ý mở rộng: '
        else 'Extended cue: '
      end || (p_base->>'keyword')
    end as keyword_text,
    case
      when coalesce(p_base->>'hero_title', '') = '' then ''
      when p_shift = 1
        then (p_base->>'hero_title') || case when p_locale = 'vi'
          then ' · Điều chỉnh'
          else ' · Recalibrate'
        end
      when p_shift = 2
        then (p_base->>'hero_title') || case when p_locale = 'vi'
          then ' · Cân bằng'
          else ' · Balance'
        end
      else (p_base->>'hero_title') || case when p_locale = 'vi'
        then ' · Mở rộng'
        else ' · Expand'
      end
    end as hero_title_text
)
select
  jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(
          jsonb_set(
            jsonb_set(
              p_base,
              '{keyword}',
              to_jsonb((select keyword_text from prep)),
              true
            ),
            '{hero_title}',
            to_jsonb((select hero_title_text from prep)),
            true
          ),
          '{focus}',
          public._numverse_rotate_jsonb_array(
            coalesce(p_base->'focus', '[]'::jsonb),
            p_shift
          ),
          true
        ),
        '{steps}',
        public._numverse_rotate_jsonb_array(
          coalesce(p_base->'steps', '[]'::jsonb),
          p_shift
        ),
        true
      ),
      '{priorities}',
      public._numverse_rotate_jsonb_array(
        coalesce(p_base->'priorities', '[]'::jsonb),
        p_shift
      ),
      true
    ),
    '{cautions}',
    public._numverse_rotate_jsonb_array(
      coalesce(p_base->'cautions', '[]'::jsonb),
      p_shift
    ),
    true
  );
$$;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v6'::text, 'mobile_assets_20260314_v5'::text),
    ('en'::text, 'mobile_assets_20260314_v6'::text, 'mobile_assets_20260314_v5'::text)
)
insert into public.numerology_ledger_releases (locale, version, status, notes)
select
  d.locale,
  d.version,
  'draft',
  'Release v6: month_personal_number uses day_of_year_mod variants.'
from desired d
where not exists (
  select 1
  from public.numerology_ledger_releases r
  where r.locale = d.locale
    and r.version = d.version
);

with desired(locale, version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v6'::text),
    ('en'::text, 'mobile_assets_20260314_v6'::text)
)
delete from public.numerology_contents c
using public.numerology_ledger_releases r
join desired d
  on d.locale = r.locale
 and d.version = r.version
where c.release_id = r.id;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v6'::text, 'mobile_assets_20260314_v5'::text),
    ('en'::text, 'mobile_assets_20260314_v6'::text, 'mobile_assets_20260314_v5'::text)
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

with month_base as (
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
  where r.version = 'mobile_assets_20260314_v6'
    and c.content_type = 'month_personal_number'
    and c.number_key ~ '^[0-9]+$'
)
update public.numerology_contents c
set
  payload_jsonb = jsonb_build_object(
    'variants',
    jsonb_build_array(
      m.base_payload,
      public._numverse_make_month_personal_variant(m.base_payload, m.locale, 1),
      public._numverse_make_month_personal_variant(m.base_payload, m.locale, 2),
      public._numverse_make_month_personal_variant(m.base_payload, m.locale, 3)
    ),
    'variant_strategy',
    'day_of_year_mod'
  ),
  updated_at = now()
from month_base m
where c.id = m.id;

do $$
declare
  v_release_id uuid;
begin
  for v_release_id in
    select id
    from public.numerology_ledger_releases
    where version = 'mobile_assets_20260314_v6'
  loop
    perform public.publish_ledger_release(v_release_id);
  end loop;
end
$$;

commit;
