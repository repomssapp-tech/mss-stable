-- ===========================================================
-- Migration: rls_drift_guard
-- Project : IN Schemes (MSS App)
-- Purpose : M8 -- the recurrence guard in 20260818000000 is a one-shot
--           migration-time DO block covering only "RLS on, zero policies".
--           Replace it with a reusable function that also catches:
--             - RLS DISABLED on a base table in public/catalog/admin
--             - public.profiles SELECT drifting back to anon / PUBLIC /
--               USING(true)
--             - a sensitive public.* table gaining an anon-readable policy
--             - FORCE ROW LEVEL SECURITY missing on the PII / RBAC set
--
--           private.rls_coverage_violations() is called two ways:
--             1. here, at migration time -> `raise warning` (non-blocking,
--                surfaces in `supabase db reset` output on every PR via the
--                existing backend-database.yml job)
--             2. .github/workflows/rls-drift-check.yml -> weekly against the
--                LIVE project, hard-fails and opens an issue. That is the
--                real enforcement point, because dashboard edits never go
--                through `db reset`.
-- ===========================================================

begin;

create or replace function private.rls_coverage_violations()
returns table (scope text, object text, issue text)
language sql
stable
security definer
set search_path = ''
as $$
  -- 1. RLS enabled but no policy -> silent deny-all
  select 'zero-policy'::text,
         pg_catalog.format('%I.%I', n.nspname, c.relname),
         'RLS enabled but no policy (silent deny-all)'::text
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where c.relkind = 'r' and c.relrowsecurity
    and n.nspname in ('public','catalog','admin')
    and not exists (select 1 from pg_catalog.pg_policy p where p.polrelid = c.oid)
    and pg_catalog.format('%I.%I', n.nspname, c.relname) <> 'public.api_rate_limits'

  union all
  -- 2. base table with RLS switched OFF
  select 'rls-off',
         pg_catalog.format('%I.%I', n.nspname, c.relname),
         'row level security is DISABLED on a base table'
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where c.relkind = 'r' and not c.relrowsecurity
    and n.nspname in ('public','catalog','admin')

  union all
  -- 3. profiles SELECT must stay self-only
  select 'profiles-drift',
         pg_catalog.format('policy "%s"', pol.policyname),
         'public.profiles SELECT/ALL policy exposes rows to anon/PUBLIC or USING(true)'
  from pg_catalog.pg_policies pol
  where pol.schemaname = 'public' and pol.tablename = 'profiles'
    and pol.cmd in ('SELECT','ALL')
    and ( pol.roles && array['anon','public']::name[]
          or coalesce(pol.qual, 'true') in ('true','(true)') )

  union all
  -- 4. sensitive tables that must never be anon-readable
  select 'must-not-expose',
         pg_catalog.format('%I.%I via "%s"', pol.schemaname, pol.tablename, pol.policyname),
         'anon-readable permissive SELECT/ALL policy on a sensitive table'
  from pg_catalog.pg_policies pol
  where pol.schemaname = 'public'
    and pol.tablename in (
      'profiles','chat_logs','feedback','search_logs','sync_history','bug_reports',
      'notifications','saved_schemes','recent_schemes','ai_conversations','ai_messages',
      'user_memory','startup_profiles','questionnaire_sessions','user_responses','recommendations')
    and pol.permissive = 'PERMISSIVE'
    and pol.cmd in ('SELECT','ALL')
    and ( pol.roles && array['anon']::name[]
          or ( pol.roles && array['public']::name[]
               and coalesce(pol.qual, 'true') in ('true','(true)') ) )

  union all
  -- 5. FORCE RLS expected on the PII / RBAC set (see 20260901000400)
  select 'force-missing',
         pg_catalog.format('%I.%I', n.nspname, c.relname),
         'FORCE ROW LEVEL SECURITY expected but not set'
  from pg_catalog.pg_class c
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in (
      'profiles','startup_profiles','organizations','organization_memberships',
      'roles','user_roles','regions','user_regions','departments','beneficiary_categories')
    and c.relrowsecurity and not c.relforcerowsecurity;
$$;

comment on function private.rls_coverage_violations() is
  'Returns one row per RLS posture violation. Empty = healthy. Called at '
  'migration time (warning) and by the rls-drift-check workflow (hard fail).';

revoke all on function private.rls_coverage_violations() from public, anon, authenticated;
grant execute on function private.rls_coverage_violations() to service_role;

-- Migration-time surface: warn, do not block (the hard gate is the workflow).
do $$
declare
  report text;
begin
  select string_agg(scope || ' :: ' || object || ' -- ' || issue, E'\n' order by scope, object)
    into report
  from private.rls_coverage_violations();

  if report is not null then
    raise warning E'RLS drift / coverage gaps detected:\n%\n(enforced by .github/workflows/rls-drift-check.yml)', report;
  end if;
end $$;

commit;

-- ===========================================================
-- Rollback (manual):
--   drop function if exists private.rls_coverage_violations();
-- ===========================================================
