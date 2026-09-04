-- ===========================================================
-- Migration: rpc_status_filter_and_indexes
-- Project : IN Schemes (MSS App)
-- Purpose : Close three findings from the 2026-09-04 backend architecture/
--           security audit.
--
--           A. mss_scheme_detail / mss_lookup_catalog / mss_entity_record /
--              mss_finance_by_scheme read catalog.* directly with no
--              status filter, relying entirely on the GRANT layer
--              (service_role-only, per 20260828160500) to keep DRAFT/
--              ARCHIVED content from clients. Fail-safe regardless of
--              Edge Function correctness: filter status = 'PUBLISHED'
--              inside the RPC bodies themselves.
--
--           B. mss_relationships() returns rows pointing at DRAFT/ARCHIVED
--              target entities -- a published scheme can incidentally
--              reveal a draft authority/institution's name+existence via
--              this RPC, inconsistent with the "every sibling gates on
--              PUBLISHED" principle 20260901000100 established for
--              catalog.relationships' own RLS policy (which only checked
--              the *source*). mss_entity_record now also returns `status`
--              so mss_relationships can drop unpublished-target rows
--              entirely (not just null out the name).
--
--           C. Missing indexes on FK/RLS-filter columns: catalog.finance/
--              tax/export/csr/treds.scheme_id (queried by mss_scheme_detail
--              with `where scheme_id = ...`, all FK targets) and the
--              user_id/conversation_id columns most public.* RLS policies
--              filter on. Table sizes are small today (low hundreds of
--              rows) so non-concurrent CREATE INDEX is fine inside this
--              migration's transaction -- no CONCURRENTLY needed.
-- ===========================================================

begin;

-- ---------------------------------------------------------------------------
-- A + B. RPC status filtering.
-- ---------------------------------------------------------------------------

-- mss_entity_record gains a new OUT column (status), which Postgres won't
-- let CREATE OR REPLACE do in place for a RETURNS TABLE function. Drop the
-- dependent mss_relationships first (it's being replaced below anyway),
-- then mss_entity_record, then recreate both in dependency order.
drop function if exists public.mss_relationships(text);
drop function if exists public.mss_entity_record(text);

create function public.mss_entity_record("p_entity_id" text)
returns table (entity_type text, record_json jsonb, status text)
language plpgsql stable security definer
set search_path to 'public', 'catalog', 'extensions'
as $$
begin
  if p_entity_id like 'SCH%' then
    return query select 'scheme', s.record_json, s.status from catalog.scheme s where s.id = p_entity_id and s.status = 'PUBLISHED';
  elsif p_entity_id like 'AUTH%' then
    return query select 'authority', a.record_json, a.status from catalog.authority a where a.id = p_entity_id and a.status = 'PUBLISHED';
  elsif p_entity_id like 'INST%' then
    return query select 'institution', i.record_json, i.status from catalog.institution i where i.id = p_entity_id and i.status = 'PUBLISHED';
  elsif p_entity_id like 'FIN%' then
    return query select 'finance_product', f.record_json, f.status from catalog.finance f where f.id = p_entity_id and f.status = 'PUBLISHED';
  elsif p_entity_id like 'TAX%' then
    return query select 'tax_provision', t.record_json, t.status from catalog.tax t where t.id = p_entity_id and t.status = 'PUBLISHED';
  elsif p_entity_id like 'EXP%' then
    return query select 'export_benefit', e.record_json, e.status from catalog.export e where e.id = p_entity_id and e.status = 'PUBLISHED';
  elsif p_entity_id like 'CSR%' then
    return query select 'csr_provision', c.record_json, c.status from catalog.csr c where c.id = p_entity_id and c.status = 'PUBLISHED';
  elsif p_entity_id like 'TDS%' then
    return query select 'treds_platform', td.record_json, td.status from catalog.treds td where td.id = p_entity_id and td.status = 'PUBLISHED';
  elsif p_entity_id like 'KNOW%' then
    return query select 'knowledge_item', k.record_json, k.status from catalog.knowledge k where k.id = p_entity_id and k.status = 'PUBLISHED';
  elsif p_entity_id like 'APLM%' then
    return query select 'applicability_matrix', am.record_json, am.status from catalog.applicability_matrix am where am.id = p_entity_id and am.status = 'PUBLISHED';
  elsif p_entity_id like 'ENTC%' then
    return query select 'enterprise_classification', ec.record_json, ec.status from catalog.enterprise_classification ec where ec.id = p_entity_id and ec.status = 'PUBLISHED';
  elsif p_entity_id like 'PRIV%' then
    return query select 'msme_privilege', mp.record_json, mp.status from catalog.msme_privilege mp where mp.id = p_entity_id and mp.status = 'PUBLISHED';
  elsif p_entity_id like 'ENAB%' then
    return query select 'business_enablement', be.record_json, be.status from catalog.business_enablement be where be.id = p_entity_id and be.status = 'PUBLISHED';
  elsif p_entity_id like 'CLUS%' then
    return query select 'cluster_assistance', cl.record_json, cl.status from catalog.cluster_assistance cl where cl.id = p_entity_id and cl.status = 'PUBLISHED';
  elsif p_entity_id like 'CMN%' then
    return query select 'common_term', cm.record_json, cm.status from catalog.common cm where cm.id = p_entity_id and cm.status = 'PUBLISHED';
  end if;
end;
$$;

comment on function public.mss_entity_record(text) is
  'Returns entity_type/record_json/status for a published entity by ID. Fail-safe status='' PUBLISHED'' filter added 2026-09-04 -- previously relied entirely on the GRANT layer.';

create or replace function public.mss_finance_by_scheme("p_scheme_id" text)
returns table (id text, record_json jsonb)
language sql stable security definer
set search_path to 'public', 'catalog', 'extensions'
as $$
  select id, record_json from catalog.finance where scheme_id = p_scheme_id and status = 'PUBLISHED' order by id;
$$;

create or replace function public.mss_lookup_catalog("p_catalog" text)
returns table (id text, record_json jsonb)
language plpgsql stable security definer
set search_path to 'public', 'catalog', 'extensions'
as $$
begin
  if p_catalog = 'finance' then
    return query select f.id, f.record_json from catalog.finance f where f.status = 'PUBLISHED' order by f.id;
  elsif p_catalog = 'cluster_assistance' then
    return query select c.id, c.record_json from catalog.cluster_assistance c where c.status = 'PUBLISHED' order by c.id;
  elsif p_catalog = 'tax' then
    return query select t.id, t.record_json from catalog.tax t where t.status = 'PUBLISHED' order by t.id;
  elsif p_catalog = 'msme_privilege' then
    return query select m.id, m.record_json from catalog.msme_privilege m where m.status = 'PUBLISHED' order by m.id;
  elsif p_catalog = 'applicability_matrix' then
    return query select am.id, am.record_json from catalog.applicability_matrix am where am.status = 'PUBLISHED' order by am.id;
  end if;
end;
$$;

create or replace function public.mss_scheme_detail("p_scheme_id" text)
returns jsonb
language sql stable security definer
set search_path to 'public', 'catalog', 'extensions'
as $$
  select case when s.id is null then null else jsonb_build_object(
    'id', s.id,
    'scheme', s.record_json,
    'finance', coalesce((select jsonb_agg(f.record_json) from catalog.finance f where f.scheme_id = s.id and f.status = 'PUBLISHED'), '[]'::jsonb),
    'tax', coalesce((select jsonb_agg(t.record_json) from catalog.tax t where t.scheme_id = s.id and t.status = 'PUBLISHED'), '[]'::jsonb),
    'export', coalesce((select jsonb_agg(e.record_json) from catalog.export e where e.scheme_id = s.id and e.status = 'PUBLISHED'), '[]'::jsonb),
    'csr', coalesce((select jsonb_agg(c.record_json) from catalog.csr c where c.scheme_id = s.id and c.status = 'PUBLISHED'), '[]'::jsonb),
    'treds', coalesce((select jsonb_agg(td.record_json) from catalog.treds td where td.scheme_id = s.id and td.status = 'PUBLISHED'), '[]'::jsonb),
    'applicabilityMatrix', coalesce((select jsonb_agg(am.record_json) from catalog.applicability_matrix am where am.scheme_id = s.id and am.status = 'PUBLISHED'), '[]'::jsonb),
    'authority', (select a.record_json from catalog.authority a where a.id = s.primary_authority_id and a.status = 'PUBLISHED'),
    'institution', (select i.record_json from catalog.institution i where i.id = s.primary_institution_id and i.status = 'PUBLISHED')
  ) end
  from catalog.scheme s
  where s.id = p_scheme_id and s.status = 'PUBLISHED';
$$;

create or replace function public.mss_relationships("p_entity_id" text)
returns table (target_id text, target_type text, target_name text, relationship_type text, generated boolean)
language plpgsql stable security definer
set search_path to 'public', 'catalog', 'extensions'
as $$
begin
  return query
  select
    r.target_id,
    r.target_type,
    (er.record_json->'identity'->>'name') as target_name,
    r.relationship_type,
    coalesce((r.metadata->>'generated')::boolean, false) as generated
  from catalog.relationships r
  join lateral public.mss_entity_record(r.target_id) er on true
  where r.source_id = p_entity_id
  order by r.relationship_type, r.target_id;
end;
$$;

comment on function public.mss_relationships(text) is
  'Lists an entity''s relationships. Inner-joins mss_entity_record so an unpublished target is dropped entirely (2026-09-04) -- previously a published scheme could reveal a draft target''s name/existence.';

-- Dropping mss_entity_record/mss_relationships reset their privileges to the
-- Postgres default (EXECUTE granted to PUBLIC on a new SECURITY DEFINER
-- function). Re-assert the service_role-only posture 20260828160500 set --
-- CREATE OR REPLACE alone (used for the other three functions above) does
-- NOT reset privileges, but these two went through a real DROP.
revoke all on function public.mss_entity_record(text) from public, anon, authenticated;
grant execute on function public.mss_entity_record(text) to service_role;
revoke all on function public.mss_relationships(text) from public, anon, authenticated;
grant execute on function public.mss_relationships(text) to service_role;

-- ---------------------------------------------------------------------------
-- C. Missing indexes on FK/RLS-filter columns.
-- ---------------------------------------------------------------------------

create index if not exists idx_catalog_finance_scheme_id on catalog.finance (scheme_id);
create index if not exists idx_catalog_tax_scheme_id      on catalog.tax (scheme_id);
create index if not exists idx_catalog_export_scheme_id   on catalog.export (scheme_id);
create index if not exists idx_catalog_csr_scheme_id      on catalog.csr (scheme_id);
create index if not exists idx_catalog_treds_scheme_id    on catalog.treds (scheme_id);

do $$
declare
  pairs text[][] := array[
    ['recent_schemes', 'user_id'],
    ['saved_schemes', 'user_id'],
    ['ai_conversations', 'user_id'],
    ['ai_messages', 'conversation_id'],
    ['user_memory', 'user_id'],
    ['notifications', 'user_id'],
    ['feedback', 'user_id'],
    ['search_logs', 'user_id'],
    ['bug_reports', 'user_id'],
    ['sync_history', 'user_id'],
    ['startup_profiles', 'user_id'],
    ['questionnaire_sessions', 'startup_profile_id'],
    ['user_responses', 'session_id'],
    ['recommendations', 'startup_profile_id']
  ];
  pair text[];
  t text;
  c text;
begin
  foreach pair slice 1 in array pairs loop
    t := pair[1];
    c := pair[2];
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = t and column_name = c
    ) then
      execute format('create index if not exists %I on public.%I (%I)', 'idx_' || t || '_' || c, t, c);
    else
      raise notice 'public.%.% absent -- skipping index', t, c;
    end if;
  end loop;
end $$;

commit;

-- ===========================================================
-- Rollback (manual):
--   Function bodies: re-apply the prior CREATE OR REPLACE from
--   20260817020000_search_and_scheme_detail_rpcs.sql /
--   20260817030000_remaining_api_rpcs.sql / 20260805000000 (mss_entity_record
--   loses its ''status'' output column, which is an additive change -- any
--   caller destructuring by column name is unaffected, only a caller
--   destructuring by position order would break).
--   Indexes: drop index if exists <name>; (all listed above).
-- ===========================================================
