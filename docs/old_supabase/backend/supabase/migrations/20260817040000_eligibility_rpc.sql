-- ===========================================================
-- Migration: eligibility_rpc
-- Project  : MSS - MSME Schemes Search
-- Purpose : V2-B5 (API port). Backs POST /v1/eligibility, the port of
--           IntelligenceResolver.match_applicability(). Extends
--           mss_lookup_catalog() (added in 20260817030000) with an
--           'applicability_matrix' case via create-or-replace rather than
--           editing that already-applied migration file -- migrations are
--           immutable once deployed.
-- ===========================================================

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
  elsif p_catalog = 'applicability_matrix' then
    return query select am.id, am.record_json from catalog.applicability_matrix am order by am.id;
  end if;
end;
$$;

grant execute on function public.mss_lookup_catalog(text) to anon, authenticated;
