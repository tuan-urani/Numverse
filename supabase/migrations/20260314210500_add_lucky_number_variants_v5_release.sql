-- Add day-of-year variants for lucky_number in a new release (v5).
-- Source release: mobile_assets_20260314_v4 (vi/en)
-- Target release: mobile_assets_20260314_v5 (vi/en)

begin;

create or replace function public._numverse_make_lucky_number_variant(
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
      when coalesce(p_base->>'message', '') = '' then ''
      when p_shift = 1
        then case when p_locale = 'vi'
          then 'Gợi ý hôm nay: '
          else 'Today''s cue: '
        end || (p_base->>'message')
      when p_shift = 2
        then case when p_locale = 'vi'
          then 'Nhịp năng lượng hiện tại: '
          else 'Current energy rhythm: '
        end || (p_base->>'message')
      else case when p_locale = 'vi'
        then 'Thông điệp mở rộng: '
        else 'Extended message: '
      end || (p_base->>'message')
    end as message_text
)
select
  jsonb_set(
    jsonb_set(
      jsonb_set(
        p_base,
        '{message}',
        to_jsonb((select message_text from prep)),
        true
      ),
      '{how_to_use}',
      public._numverse_rotate_jsonb_array(
        coalesce(p_base->'how_to_use', '[]'::jsonb),
        p_shift
      ),
      true
    ),
    '{situations}',
    public._numverse_rotate_jsonb_array(
      coalesce(p_base->'situations', '[]'::jsonb),
      p_shift
    ),
    true
  );
$$;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v5'::text, 'mobile_assets_20260314_v4'::text),
    ('en'::text, 'mobile_assets_20260314_v5'::text, 'mobile_assets_20260314_v4'::text)
)
insert into public.numerology_ledger_releases (locale, version, status, notes)
select
  d.locale,
  d.version,
  'draft',
  'Release v5: lucky_number uses day_of_year_mod variants.'
from desired d
where not exists (
  select 1
  from public.numerology_ledger_releases r
  where r.locale = d.locale
    and r.version = d.version
);

with desired(locale, version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v5'::text),
    ('en'::text, 'mobile_assets_20260314_v5'::text)
)
delete from public.numerology_contents c
using public.numerology_ledger_releases r
join desired d
  on d.locale = r.locale
 and d.version = r.version
where c.release_id = r.id;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v5'::text, 'mobile_assets_20260314_v4'::text),
    ('en'::text, 'mobile_assets_20260314_v5'::text, 'mobile_assets_20260314_v4'::text)
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

with lucky_base as (
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
  where r.version = 'mobile_assets_20260314_v5'
    and c.content_type = 'lucky_number'
    and c.number_key ~ '^[0-9]+$'
)
update public.numerology_contents c
set
  payload_jsonb = jsonb_build_object(
    'variants',
    jsonb_build_array(
      l.base_payload,
      public._numverse_make_lucky_number_variant(l.base_payload, l.locale, 1),
      public._numverse_make_lucky_number_variant(l.base_payload, l.locale, 2),
      public._numverse_make_lucky_number_variant(l.base_payload, l.locale, 3)
    ),
    'variant_strategy',
    'day_of_year_mod'
  ),
  updated_at = now()
from lucky_base l
where c.id = l.id;

do $$
declare
  v_release_id uuid;
begin
  for v_release_id in
    select id
    from public.numerology_ledger_releases
    where version = 'mobile_assets_20260314_v5'
  loop
    perform public.publish_ledger_release(v_release_id);
  end loop;
end
$$;

commit;
