-- Add life-based core number content types in a new release (v9).
-- Source release: mobile_assets_20260314_v8 (vi/en)
-- Target release: mobile_assets_20260314_v9 (vi/en)

begin;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v9'::text, 'mobile_assets_20260314_v8'::text),
    ('en'::text, 'mobile_assets_20260314_v9'::text, 'mobile_assets_20260314_v8'::text)
)
insert into public.numerology_ledger_releases (locale, version, status, notes)
select
  d.locale,
  d.version,
  'draft',
  'Release v9: add life-based core numbers (life_path, soul_urge, expression, mission).'
from desired d
where not exists (
  select 1
  from public.numerology_ledger_releases r
  where r.locale = d.locale
    and r.version = d.version
);

with desired(locale, version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v9'::text),
    ('en'::text, 'mobile_assets_20260314_v9'::text)
)
delete from public.numerology_contents c
using public.numerology_ledger_releases r
join desired d
  on d.locale = r.locale
 and d.version = r.version
where c.release_id = r.id;

with desired(locale, version, source_version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v9'::text, 'mobile_assets_20260314_v8'::text),
    ('en'::text, 'mobile_assets_20260314_v9'::text, 'mobile_assets_20260314_v8'::text)
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

with desired(locale, version) as (
  values
    ('vi'::text, 'mobile_assets_20260314_v9'::text),
    ('en'::text, 'mobile_assets_20260314_v9'::text)
),
types(content_type, vi_label, en_label) as (
  values
    ('life_path_number'::text, 'Số chủ đạo'::text, 'Life Path Number'::text),
    ('soul_urge_number'::text, 'Số linh hồn'::text, 'Soul Urge Number'::text),
    ('expression_number'::text, 'Số biểu đạt'::text, 'Expression Number'::text),
    ('mission_number'::text, 'Số sứ mệnh'::text, 'Mission Number'::text)
),
numbers(number_key) as (
  values
    ('1'::text),
    ('2'::text),
    ('3'::text),
    ('4'::text),
    ('5'::text),
    ('6'::text),
    ('7'::text),
    ('8'::text),
    ('9'::text),
    ('11'::text),
    ('22'::text),
    ('33'::text)
),
seed_rows as (
  select
    d.locale,
    t.content_type,
    n.number_key,
    jsonb_build_object(
      'title',
      case
        when d.locale = 'vi' then t.vi_label || ' ' || n.number_key
        else t.en_label || ' ' || n.number_key
      end,
      'description',
      case
        when d.locale = 'vi'
          then 'Nội dung seed cho ' || t.vi_label || ' ' || n.number_key || '.'
        else 'Seed content for ' || t.en_label || ' ' || n.number_key || '.'
      end,
      'interpretation',
      case
        when d.locale = 'vi'
          then 'Bản seed v9. Bạn có thể chỉnh trực tiếp payload JSONB trên Supabase Admin.'
        else 'v9 seed payload. You can edit this JSONB directly in Supabase Admin.'
      end,
      'keywords',
      case
        when d.locale = 'vi'
          then jsonb_build_array(t.vi_label, 'Con số ' || n.number_key, 'Numerology')
        else jsonb_build_array(t.en_label, 'Number ' || n.number_key, 'Numerology')
      end
    ) as payload_jsonb
  from desired d
  cross join types t
  cross join numbers n
)
insert into public.numerology_contents (
  release_id,
  content_type,
  number_key,
  payload_jsonb
)
select
  target.id,
  s.content_type,
  s.number_key,
  s.payload_jsonb
from seed_rows s
join public.numerology_ledger_releases target
  on target.locale = s.locale
 and target.version = 'mobile_assets_20260314_v9'
on conflict (release_id, content_type, number_key)
do update
set
  payload_jsonb = excluded.payload_jsonb,
  updated_at = now();

do $$
declare
  v_release_id uuid;
begin
  for v_release_id in
    select id
    from public.numerology_ledger_releases
    where version = 'mobile_assets_20260314_v9'
  loop
    perform public.publish_ledger_release(v_release_id);
  end loop;
end
$$;

commit;
