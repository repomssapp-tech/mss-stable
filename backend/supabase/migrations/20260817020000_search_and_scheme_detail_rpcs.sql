-- ===========================================================
-- Migration: search_and_scheme_detail_rpcs
-- Project  : MSS - MSME Schemes Search
-- Purpose : V2-B3 (API port). The v1 Edge Function's /v1/search and
--           /v1/schemes/{id} routes need to read catalog.* tables, but that
--           schema isn't exposed to PostgREST (config.toml only exposes
--           public/graphql_public -- confirmed empirically: anon-key REST
--           calls against catalog.* return 401). Rather than depend on
--           supabase-js's .schema() header-based switching working the same
--           way against the hosted project as local config.toml describes,
--           expose two public-schema RPC functions (security definer, same
--           proven pattern as mss_catalog_meta()) that do the catalog.*
--           reads server-side in SQL and return jsonb.
-- ===========================================================

create or replace function public.mss_search_data()
returns table (
  scheme_id text,
  name_en text,
  scheme_record jsonb,
  search_record jsonb
)
language sql
stable
security definer
set search_path = public, catalog, extensions
as $$
  select
    s.id as scheme_id,
    s.name_en,
    jsonb_build_object(
      'identity', jsonb_build_object(
        'status', coalesce(s.record_json->'identity'->'status', to_jsonb('unknown'::text)),
        'name', coalesce(s.record_json->'identity'->'name', to_jsonb(s.name_en))
      ),
      'ai', jsonb_build_object(
        'semanticTags', coalesce(s.record_json->'ai'->'semanticTags', '[]'::jsonb)
      )
    ) as scheme_record,
    jsonb_build_object(
      'tokens', coalesce(si.record_json->'tokens', '{}'::jsonb),
      'schemeSearchProfile', coalesce(si.record_json->'schemeSearchProfile', '{}'::jsonb)
    ) as search_record
  from catalog.scheme s
  left join catalog.search_index si on si.scheme_id = s.id;
$$;

grant execute on function public.mss_search_data() to service_role;

create or replace function public.mss_scheme_detail(p_scheme_id text)
returns jsonb
language sql
stable
security definer
set search_path = public, catalog, extensions
as $$
  select case when s.id is null then null else jsonb_build_object(
    'id', s.id,
    'scheme', s.record_json,
    'finance', coalesce((select jsonb_agg(f.record_json) from catalog.finance f where f.scheme_id = s.id), '[]'::jsonb),
    'tax', coalesce((select jsonb_agg(t.record_json) from catalog.tax t where t.scheme_id = s.id), '[]'::jsonb),
    'export', coalesce((select jsonb_agg(e.record_json) from catalog.export e where e.scheme_id = s.id), '[]'::jsonb),
    'csr', coalesce((select jsonb_agg(c.record_json) from catalog.csr c where c.scheme_id = s.id), '[]'::jsonb),
    'treds', coalesce((select jsonb_agg(td.record_json) from catalog.treds td where td.scheme_id = s.id), '[]'::jsonb),
    'applicabilityMatrix', coalesce((select jsonb_agg(am.record_json) from catalog.applicability_matrix am where am.scheme_id = s.id), '[]'::jsonb),
    'authority', (select a.record_json from catalog.authority a where a.id = s.primary_authority_id),
    'institution', (select i.record_json from catalog.institution i where i.id = s.primary_institution_id)
  ) end
  from catalog.scheme s
  where s.id = p_scheme_id;
$$;

grant execute on function public.mss_scheme_detail(text) to anon, authenticated;
