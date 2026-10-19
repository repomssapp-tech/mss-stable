-- ===========================================================
-- Migration: optimize_search_rpc_and_security
-- Project  : MSS - MSME Schemes Search
-- Purpose : Performance & Security Optimization for /v1/search
--           1. Prunes mss_search_data() payload from 5.15MB down to <250KB (>95% reduction)
--              by returning only fields consumed by HybridSearchEngine:
--              - identity.status, identity.name, ai.semanticTags
--              - tokens (en, ta), schemeSearchProfile
--           2. Revokes public execution from anon & authenticated roles to eliminate
--              bulk catalog scraping via PostgREST.
--           3. Restricts execution privilege strictly to service_role.
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

-- Security Hardening: Revoke public access, grant strictly to service_role
revoke all on function public.mss_search_data() from public, anon, authenticated;
grant execute on function public.mss_search_data() to service_role;
