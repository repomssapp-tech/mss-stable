-- ===========================================================
-- Migration: catalog_meta_function_v2
-- Project : IN Schemes
-- Purpose : catalog_parity_closure (20260817000000) added 5 new catalog
--           tables (applicability_matrix, enterprise_classification,
--           msme_privilege, business_enablement, cluster_assistance).
--           mss_catalog_meta()'s aggregation must include them or /v1/meta
--           silently under-reports the true catalog state. create or
--           replace, same return shape, no drop needed.
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
    union all select 'applicability_matrix', id, checksum from catalog.applicability_matrix
    union all select 'enterprise_classification', id, checksum from catalog.enterprise_classification
    union all select 'msme_privilege', id, checksum from catalog.msme_privilege
    union all select 'business_enablement', id, checksum from catalog.business_enablement
    union all select 'cluster_assistance', id, checksum from catalog.cluster_assistance
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
