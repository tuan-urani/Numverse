-- Backfill compatibility aspect-band keys for existing releases that only have
-- overall bands (excellent/good/moderate/effort).
--
-- This ensures app aspect insights can resolve keys like:
-- - life_path.excellent
-- - expression.good
-- - soul.moderate
-- - personality.effort
--
-- Strategy:
-- 1) Target releases with status active/draft and compatibility overall bands.
-- 2) Insert missing aspect-band rows by cloning payload from same-release overall band.
-- 3) Recompute checksum for affected active releases.

begin;

with target_releases as (
  select distinct r.id
  from public.numerology_ledger_releases r
  join public.numerology_contents c
    on c.release_id = r.id
   and c.content_type = 'compatibility_content'
   and c.number_key in ('excellent', 'good', 'moderate', 'effort')
  where r.status in ('active', 'draft')
),
inserted as (
  insert into public.numerology_contents (
    release_id,
    content_type,
    number_key,
    payload_jsonb
  )
  select
    tr.id,
    'compatibility_content',
    aspect.aspect_key || '.' || band.band_key,
    overall.payload_jsonb
  from target_releases tr
  cross join (
    values
      ('life_path'::text),
      ('expression'::text),
      ('soul'::text),
      ('personality'::text)
  ) as aspect(aspect_key)
  cross join (
    values
      ('excellent'::text),
      ('good'::text),
      ('moderate'::text),
      ('effort'::text)
  ) as band(band_key)
  join public.numerology_contents overall
    on overall.release_id = tr.id
   and overall.content_type = 'compatibility_content'
   and overall.number_key = band.band_key
  on conflict (release_id, content_type, number_key) do nothing
  returning release_id
),
affected_active_releases as (
  select distinct inserted.release_id
  from inserted
  join public.numerology_ledger_releases r
    on r.id = inserted.release_id
   and r.status = 'active'
),
recalculated_checksums as (
  select
    c.release_id,
    encode(
      extensions.digest(
        coalesce(
          string_agg(
            concat_ws('|', c.content_type, c.number_key, c.payload_jsonb::text),
            E'\n'
            order by c.content_type, c.number_key
          ),
          ''
        ),
        'sha256'
      ),
      'hex'
    ) as checksum
  from public.numerology_contents c
  join affected_active_releases a
    on a.release_id = c.release_id
  group by c.release_id
)
update public.numerology_ledger_releases r
set checksum = rc.checksum,
    updated_at = now()
from recalculated_checksums rc
where r.id = rc.release_id;

commit;
