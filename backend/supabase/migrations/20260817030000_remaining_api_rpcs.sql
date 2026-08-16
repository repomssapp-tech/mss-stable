-- ===========================================================
-- Migration: remaining_api_rpcs
-- Project : IN Schemes
-- Purpose : V2-B4 (API port continued). Backs GET /v1/finance-products,
--           GET /v1/schemes/{id}/finance, GET /v1/clusters, GET /v1/tax,
--           GET /v1/privileges, GET /v1/relationships/{id},
--           GET /v1/localization/{id}. Same security-definer RPC pattern as
--           mss_catalog_meta()/mss_search_data()/mss_scheme_detail() --
--           catalog.* isn't PostgREST-exposed, so these do the reads
--           server-side and hand back record_json for the Edge Function to
--           reshape into the documented response fields (mss_api_rc1.py's
--           _finance_record/_cluster_map/_tax_map/_privilege_map are ported
--           in TypeScript, not SQL -- much easier to keep in sync with the
--           Python mapper functions there than in nested jsonb_build_object
--           calls here).
-- ===========================================================

-- ---- flat catalog readers (finance / cluster_assistance / tax / msme_privilege) ----

create or replace function public.mss_lookup_catalog(p_catalog text)
returns table (id text, record_json jsonb)
language plpgsql
stable
security definer
set search_path = public, catalog, extensions
as $$
begin
  if p_catalog = 'finance' then
    return query select f.id, f.record_json from catalog.finance f order by f.id;
  elsif p_catalog = 'cluster_assistance' then
    return query select c.id, c.record_json from catalog.cluster_assistance c order by c.id;
  elsif p_catalog = 'tax' then
    return query select t.id, t.record_json from catalog.tax t order by t.id;
  elsif p_catalog = 'msme_privilege' then
    return query select m.id, m.record_json from catalog.msme_privilege m order by m.id;
  end if;
end;
$$;

grant execute on function public.mss_lookup_catalog(text) to anon, authenticated;

create or replace function public.mss_finance_by_scheme(p_scheme_id text)
returns table (id text, record_json jsonb)
language sql
stable
security definer
set search_path = public, catalog, extensions
as $$
  select id, record_json from catalog.finance where scheme_id = p_scheme_id order by id;
$$;

grant execute on function public.mss_finance_by_scheme(text) to anon, authenticated;

-- ---- generic entity resolver: id prefix -> (entity_type, record_json) ----
-- Every entity id across the 15 catalogs is prefixed distinctively (SCH,
-- AUTH, INST, FIN, TAX, EXP, CSR, TDS, KNOW, APLM, ENTC, PRIV, ENAB, CLUS,
-- CMN) so this dispatches by prefix rather than scanning all 15 tables.

create or replace function public.mss_entity_record(p_entity_id text)
returns table (entity_type text, record_json jsonb)
language plpgsql
stable
security definer
set search_path = public, catalog, extensions
as $$
begin
  if p_entity_id like 'SCH%' then
    return query select 'scheme', s.record_json from catalog.scheme s where s.id = p_entity_id;
  elsif p_entity_id like 'AUTH%' then
    return query select 'authority', a.record_json from catalog.authority a where a.id = p_entity_id;
  elsif p_entity_id like 'INST%' then
    return query select 'institution', i.record_json from catalog.institution i where i.id = p_entity_id;
  elsif p_entity_id like 'FIN%' then
    return query select 'finance_product', f.record_json from catalog.finance f where f.id = p_entity_id;
  elsif p_entity_id like 'TAX%' then
    return query select 'tax_provision', t.record_json from catalog.tax t where t.id = p_entity_id;
  elsif p_entity_id like 'EXP%' then
    return query select 'export_benefit', e.record_json from catalog.export e where e.id = p_entity_id;
  elsif p_entity_id like 'CSR%' then
    return query select 'csr_provision', c.record_json from catalog.csr c where c.id = p_entity_id;
  elsif p_entity_id like 'TDS%' then
    return query select 'treds_platform', td.record_json from catalog.treds td where td.id = p_entity_id;
  elsif p_entity_id like 'KNOW%' then
    return query select 'knowledge_item', k.record_json from catalog.knowledge k where k.id = p_entity_id;
  elsif p_entity_id like 'APLM%' then
    return query select 'applicability_matrix', am.record_json from catalog.applicability_matrix am where am.id = p_entity_id;
  elsif p_entity_id like 'ENTC%' then
    return query select 'enterprise_classification', ec.record_json from catalog.enterprise_classification ec where ec.id = p_entity_id;
  elsif p_entity_id like 'PRIV%' then
    return query select 'msme_privilege', mp.record_json from catalog.msme_privilege mp where mp.id = p_entity_id;
  elsif p_entity_id like 'ENAB%' then
    return query select 'business_enablement', be.record_json from catalog.business_enablement be where be.id = p_entity_id;
  elsif p_entity_id like 'CLUS%' then
    return query select 'cluster_assistance', cl.record_json from catalog.cluster_assistance cl where cl.id = p_entity_id;
  elsif p_entity_id like 'CMN%' then
    return query select 'common_term', cm.record_json from catalog.common cm where cm.id = p_entity_id;
  end if;
end;
$$;

grant execute on function public.mss_entity_record(text) to anon, authenticated;

-- ---- relationships: read the pre-flattened edge table, resolve target
-- names via mss_entity_record() ----

create or replace function public.mss_relationships(p_entity_id text)
returns table (target_id text, target_type text, target_name text, relationship_type text, generated boolean)
language plpgsql
stable
security definer
set search_path = public, catalog, extensions
as $$
begin
  return query
  select
    r.target_id,
    r.target_type,
    (select (er.record_json->'identity'->>'name') from public.mss_entity_record(r.target_id) er limit 1) as target_name,
    r.relationship_type,
    coalesce((r.metadata->>'generated')::boolean, false) as generated
  from catalog.relationships r
  where r.source_id = p_entity_id
  order by r.relationship_type, r.target_id;
end;
$$;

grant execute on function public.mss_relationships(text) to anon, authenticated;
