-- Upgrade todaypersonalnumber variants from 3 -> 4 in a new release (v4).
-- Source release: mobile_assets_20260314_v3 (vi/en)
-- Target release: mobile_assets_20260314_v4 (vi/en)

begin;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v4'::text, 'mobile_assets_20260314_v3'::text),
    ('en'::text, 'mobile_assets_20260314_v4'::text, 'mobile_assets_20260314_v3'::text)
)
insert into public.numerology_ledger_releases (locale, version, status, notes)
select
  d.locale,
  d.version,
  'draft',
  'Release v4: todaypersonalnumber upgraded to 4 day-of-year variants.'
from desired d
where not exists (
  select 1
  from public.numerology_ledger_releases r
  where r.locale = d.locale
    and r.version = d.version
);

with desired(locale, version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v4'::text),
    ('en'::text, 'mobile_assets_20260314_v4'::text)
)
delete from public.numerology_contents c
using public.numerology_ledger_releases r
join desired d
  on d.locale = r.locale
 and d.version = r.version
where c.release_id = r.id;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v4'::text, 'mobile_assets_20260314_v3'::text),
    ('en'::text, 'mobile_assets_20260314_v4'::text, 'mobile_assets_20260314_v3'::text)
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

with today_base as (
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
  where r.version = 'mobile_assets_20260314_v4'
    and c.content_type = 'todaypersonalnumber'
    and c.number_key ~ '^[0-9]+$'
)
update public.numerology_contents c
set
  payload_jsonb = jsonb_build_object(
    'variants',
    jsonb_build_array(
      t.base_payload,
      public._numverse_make_todaypersonal_variant(t.base_payload, t.locale, 1),
      public._numverse_make_todaypersonal_variant(t.base_payload, t.locale, 2),
      public._numverse_make_todaypersonal_variant(t.base_payload, t.locale, 3)
    ),
    'variant_strategy',
    'day_of_year_mod'
  ),
  updated_at = now()
from today_base t
where c.id = t.id;

do $$
declare
  v_release_id uuid;
begin
  for v_release_id in
    select id
    from public.numerology_ledger_releases
    where version = 'mobile_assets_20260314_v4'
  loop
    perform public.publish_ledger_release(v_release_id);
  end loop;
end
$$;

commit;
