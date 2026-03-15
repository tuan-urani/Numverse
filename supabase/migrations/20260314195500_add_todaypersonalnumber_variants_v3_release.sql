-- Create v3 ledger release and add day-of-year variants for todaypersonalnumber.
-- Source release: mobile_assets_20260314_v2 (vi/en)
-- Target release: mobile_assets_20260314_v3 (vi/en)

begin;

create or replace function public._numverse_rotate_jsonb_array(
  p_array jsonb,
  p_shift integer
)
returns jsonb
language sql
immutable
as $$
with elems as (
  select value, ordinality - 1 as idx
  from jsonb_array_elements(coalesce(p_array, '[]'::jsonb)) with ordinality
),
len as (
  select count(*)::int as n from elems
),
rotated as (
  select
    e.value,
    ((e.idx - (p_shift % nullif(l.n, 0)) + l.n) % l.n) as new_idx
  from elems e
  cross join len l
  where l.n > 0
)
select case
  when (select n from len) = 0 then coalesce(p_array, '[]'::jsonb)
  else (select jsonb_agg(value order by new_idx) from rotated)
end;
$$;

create or replace function public._numverse_make_todaypersonal_variant(
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
      when coalesce(p_base->>'quote', '') = '' then ''
      when p_shift = 1
        then case when p_locale = 'vi'
          then 'Gợi ý hôm nay: '
          else 'Today''s cue: '
        end || (p_base->>'quote')
      else case when p_locale = 'vi'
        then 'Thông điệp bổ sung: '
        else 'Extra message: '
      end || (p_base->>'quote')
    end as quote_text,
    case
      when coalesce(p_base->>'daily_rhythm', '') = '' then ''
      when p_shift = 1
        then (p_base->>'daily_rhythm') || case when p_locale = 'vi'
          then ' · Cân chỉnh'
          else ' · Recalibrate'
        end
      else (p_base->>'daily_rhythm') || case when p_locale = 'vi'
        then ' · Kết nối'
        else ' · Align'
      end
    end as rhythm_text
)
select
  jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(
          jsonb_set(
            p_base,
            '{quote}',
            to_jsonb((select quote_text from prep)),
            true
          ),
          '{daily_rhythm}',
          to_jsonb((select rhythm_text from prep)),
          true
        ),
        '{detail}',
        public._numverse_rotate_jsonb_array(coalesce(p_base->'detail', '[]'::jsonb), p_shift),
        true
      ),
      '{hint_actions}',
      public._numverse_rotate_jsonb_array(coalesce(p_base->'hint_actions', '[]'::jsonb), p_shift),
      true
    ),
    '{should_do}',
    public._numverse_rotate_jsonb_array(coalesce(p_base->'should_do', '[]'::jsonb), p_shift),
    true
  );
$$;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v3'::text, 'mobile_assets_20260314_v2'::text),
    ('en'::text, 'mobile_assets_20260314_v3'::text, 'mobile_assets_20260314_v2'::text)
)
insert into public.numerology_ledger_releases (locale, version, status, notes)
select
  d.locale,
  d.version,
  'draft',
  'Release v3: todaypersonalnumber uses day_of_year_mod variants.'
from desired d
where not exists (
  select 1
  from public.numerology_ledger_releases r
  where r.locale = d.locale
    and r.version = d.version
);

with desired(locale, version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v3'::text),
    ('en'::text, 'mobile_assets_20260314_v3'::text)
)
delete from public.numerology_contents c
using public.numerology_ledger_releases r
join desired d
  on d.locale = r.locale
 and d.version = r.version
where c.release_id = r.id;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v3'::text, 'mobile_assets_20260314_v2'::text),
    ('en'::text, 'mobile_assets_20260314_v3'::text, 'mobile_assets_20260314_v2'::text)
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

update public.numerology_contents c
set
  payload_jsonb = jsonb_build_object(
    'variants',
    jsonb_build_array(
      c.payload_jsonb,
      public._numverse_make_todaypersonal_variant(c.payload_jsonb, r.locale, 1),
      public._numverse_make_todaypersonal_variant(c.payload_jsonb, r.locale, 2)
    ),
    'variant_strategy',
    'day_of_year_mod'
  ),
  updated_at = now()
from public.numerology_ledger_releases r
where c.release_id = r.id
  and r.version = 'mobile_assets_20260314_v3'
  and c.content_type = 'todaypersonalnumber'
  and c.number_key ~ '^[0-9]+$';

do $$
declare
  v_release_id uuid;
begin
  for v_release_id in
    select id
    from public.numerology_ledger_releases
    where version = 'mobile_assets_20260314_v3'
  loop
    perform public.publish_ledger_release(v_release_id);
  end loop;
end
$$;

commit;
