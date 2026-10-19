-- ===========================================================
-- Migration: catalog_meta_function
-- Project  : MSS - MSME Schemes Search
-- Purpose : Expose a live, checksum-derived catalog version/checksum so the
--           Flutter app's /v1/meta call (MssMeta.isStaleAgainst) can detect
--           when the Supabase-side catalog has changed since the app's last
--           sync, without the app ever needing to fetch the full catalog
--           unless it's actually stale. Recomputed live from catalog.* row
--           checksums on every call -- no separate release-bump step needed;
--           any edit made in Supabase Studio is reflected immediately.
-- ===========================================================

create or replace function public.mss_catalog_meta()
returns table (
  catalog_version text,
  catalog_checksum text,
  entity_counts jsonb
)
language sql
stable
security definer
set search_path = public, catalog, extensions
as $$
  with rows as (
    select 'common' as src, id, checksum from catalog.common
    union all select 'authority', id, checksum from catalog.authority
    union all select 'institution', id, checksum from catalog.institution
    union all select 'scheme', id, checksum from catalog.scheme
    union all select 'finance', id, checksum from catalog.finance
    union all select 'tax', id, checksum from catalog.tax
    union all select 'export', id, checksum from catalog.export
    union all select 'csr', id, checksum from catalog.csr
    union all select 'treds', id, checksum from catalog.treds
    union all select 'knowledge', id, checksum from catalog.knowledge
  ),
  agg as (
    select encode(digest(string_agg(checksum, '' order by src, id), 'sha256'), 'hex') as full_checksum
    from rows
  ),
  counts as (
    select jsonb_object_agg(src, n) as counts_json
    from (select src, count(*) as n from rows group by src) c
  )
  select
    substr(agg.full_checksum, 1, 16) as catalog_version,
    agg.full_checksum as catalog_checksum,
    coalesce(counts.counts_json, '{}'::jsonb) as entity_counts
  from agg, counts;
$$;

grant execute on function public.mss_catalog_meta() to anon, authenticated;
