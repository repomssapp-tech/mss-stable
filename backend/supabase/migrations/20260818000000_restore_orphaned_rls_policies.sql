-- ===========================================================
-- Migration: restore_orphaned_rls_policies
-- Project : IN Schemes
-- Purpose : 20260805000000_database_architecture_v2.sql's blanket
--           `drop policy` loop (line ~629) wiped every RLS policy in
--           public/catalog/admin/storage, then only recreated a subset.
--           Live production (confirmed via `supabase db dump` against the
--           linked project) is missing policies four downstream migrations
--           either never restored or restored too permissively:
--             1. public.profiles has no INSERT policy at all -- blocks
--                profile creation for every user. A fix for this
--                (20260812112500_profiles_self_insert_policy.sql) exists
--                and is marked applied in schema_migrations, but its
--                policy is absent live -- this migration re-asserts it.
--             2. public.profiles SELECT is `to anon, authenticated using
--                (true)` -- any unauthenticated caller can read every
--                user's full profile (PII: dob, gender, disability,
--                annual_income, address, phone). No code path in the app
--                or in the /v1/* Edge Function (which uses the
--                service-role key, bypassing RLS entirely -- confirmed via
--                grep, see below) needs anon read access.
--             3/4. public.questionnaire_sessions / user_responses /
--                recommendations have RLS enabled with zero policies --
--                confirmed silently broken for questionnaire_sessions,
--                which the app actively queries for the resume-onboarding
--                banner.
--           A local `supabase db reset` + the recurrence guard added below
--           (section 8) surfaced 11 MORE orphaned tables beyond the 4 the
--           original audit found (that audit was scoped to tables the
--           Flutter app touches directly): questions, question_options,
--           and an entire admin/RBAC subsystem (organizations,
--           organization_memberships, roles, user_roles, regions,
--           user_regions, departments, beneficiary_categories, audit_log)
--           that the existing supabase/tests/database/0002_rls.test.sql
--           suite already exercises. All restored below (sections 6-7).
--
--           Running the actual pgTAP suite (not just db reset) also
--           surfaced a second, separate class of drift: v2's line 70
--           (`revoke all on schema private from public, anon,
--           authenticated`) stripped `authenticated`'s schema-level USAGE
--           on `private`, which 20260727000100_admin_foundation.sql had
--           granted -- needed for the private.has_role() /
--           private.has_region() / private.belongs_to_organization()
--           helper functions the policies above call. Restored in
--           section 9.
--
--           This migration is idempotent (`drop policy if exists` before
--           each `create policy`), so it's safe to apply regardless of
--           whatever the live drift actually is.
-- ===========================================================

-- 1. profiles INSERT -- restore verbatim from 20260812112500.
revoke all on table public.profiles from anon;
grant select, insert, update on table public.profiles to authenticated;
drop policy if exists "Profiles insert access" on public.profiles;
create policy "Profiles insert access"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

-- 2. profiles SELECT -- tighten to self-row only. Verified via grep across
-- backend/supabase/functions/v1/*.ts that every Supabase client call there
-- uses the service-role key (getServiceClient()), which bypasses RLS --
-- none of them depend on the anon-readable-to-everyone policy being tested
-- here. The Flutter app only ever does `.eq('id', uid)` self-lookups or a
-- realtime stream filtered to its own id.
drop policy if exists "Profiles select access" on public.profiles;
create policy "Profiles select access"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

-- 3. questionnaire_sessions -- restore from 20260714061850_013_rls.sql:40,
-- plus a matching WITH CHECK (the original was FOR ALL with only USING,
-- which lets an authenticated user INSERT/UPDATE a row pointing at another
-- user's startup_profile_id since WITH CHECK falls back to USING only for
-- UPDATE, not INSERT, when omitted -- adding it explicitly closes that).
drop policy if exists "Users manage own questionnaire sessions" on public.questionnaire_sessions;
create policy "Users manage own questionnaire sessions"
on public.questionnaire_sessions
for all
using (
    startup_profile_id in (
        select id from public.startup_profiles where user_id = auth.uid()
    )
)
with check (
    startup_profile_id in (
        select id from public.startup_profiles where user_id = auth.uid()
    )
);

-- 4. user_responses -- restore from 20260714061850_013_rls.sql:55, with
-- the same WITH CHECK hardening.
drop policy if exists "Users manage own responses" on public.user_responses;
create policy "Users manage own responses"
on public.user_responses
for all
using (
    exists (
        select 1
        from public.questionnaire_sessions qs
        join public.startup_profiles sp on qs.startup_profile_id = sp.id
        where qs.id = user_responses.session_id
          and sp.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.questionnaire_sessions qs
        join public.startup_profiles sp on qs.startup_profile_id = sp.id
        where qs.id = user_responses.session_id
          and sp.user_id = auth.uid()
    )
);

-- 5. recommendations -- restore from 20260714061850_013_rls.sql:72, with
-- the same WITH CHECK hardening.
drop policy if exists "Users view own recommendations" on public.recommendations;
create policy "Users view own recommendations"
on public.recommendations
for all
using (
    startup_profile_id in (
        select id from public.startup_profiles where user_id = auth.uid()
    )
)
with check (
    startup_profile_id in (
        select id from public.startup_profiles where user_id = auth.uid()
    )
);

-- 6. questions / question_options -- restore from
-- 20260714061860_hardening.sql:223-231 (simple public-read, no role
-- restriction in the originals).
drop policy if exists "Public can view questions" on public.questions;
create policy "Public can view questions"
on public.questions for select using (true);

drop policy if exists "Public can view question options" on public.question_options;
create policy "Public can view question options"
on public.question_options for select using (true);

-- 7. The admin/RBAC subsystem (organizations, organization_memberships,
-- roles, user_roles, regions, user_regions, departments,
-- beneficiary_categories, audit_log) -- restored verbatim from
-- 20260727000100_admin_foundation.sql:289-367. This entire subsystem was
-- silently orphaned by the same v2 blanket-drop loop; the recurrence guard
-- added below is what caught it during local verification of this
-- migration (it wasn't in the original 4-table audit, which was scoped to
-- tables the Flutter app touches directly -- this one isn't, but it's
-- still broken and covered by the same pgTAP suite in
-- supabase/tests/database/0002_rls.test.sql).
drop policy if exists "organizations_read_members" on public.organizations;
create policy organizations_read_members
on public.organizations for select to authenticated
using (private.belongs_to_organization(id));

drop policy if exists "organizations_update_administrators" on public.organizations;
create policy organizations_update_administrators
on public.organizations for update to authenticated
using (private.has_role(id, array['administrator']))
with check (private.has_role(id, array['administrator']));

drop policy if exists "organization_memberships_read_self_or_oversight" on public.organization_memberships;
create policy organization_memberships_read_self_or_oversight
on public.organization_memberships for select to authenticated
using (
  user_id = auth.uid()
  or private.has_role(organization_id, array['administrator', 'auditor'])
);

drop policy if exists "organization_memberships_manage_administrators" on public.organization_memberships;
create policy organization_memberships_manage_administrators
on public.organization_memberships for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

drop policy if exists "roles_read_authenticated" on public.roles;
create policy roles_read_authenticated
on public.roles for select to authenticated
using (true);

drop policy if exists "user_roles_read_self_or_oversight" on public.user_roles;
create policy user_roles_read_self_or_oversight
on public.user_roles for select to authenticated
using (
  user_id = auth.uid()
  or private.has_role(organization_id, array['administrator', 'auditor'])
);

drop policy if exists "user_roles_manage_administrators" on public.user_roles;
create policy user_roles_manage_administrators
on public.user_roles for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

drop policy if exists "regions_read_members" on public.regions;
create policy regions_read_members
on public.regions for select to authenticated
using (private.belongs_to_organization(organization_id));

drop policy if exists "regions_manage_administrators" on public.regions;
create policy regions_manage_administrators
on public.regions for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

drop policy if exists "user_regions_read_self_or_oversight" on public.user_regions;
create policy user_regions_read_self_or_oversight
on public.user_regions for select to authenticated
using (
  user_id = auth.uid()
  or private.has_role(organization_id, array['administrator', 'auditor'])
);

drop policy if exists "user_regions_manage_administrators" on public.user_regions;
create policy user_regions_manage_administrators
on public.user_regions for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

drop policy if exists "departments_read_members" on public.departments;
create policy departments_read_members
on public.departments for select to authenticated
using (private.belongs_to_organization(organization_id));

drop policy if exists "departments_manage_administrators" on public.departments;
create policy departments_manage_administrators
on public.departments for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

drop policy if exists "beneficiary_categories_read_members" on public.beneficiary_categories;
create policy beneficiary_categories_read_members
on public.beneficiary_categories for select to authenticated
using (private.belongs_to_organization(organization_id));

drop policy if exists "beneficiary_categories_manage_administrators" on public.beneficiary_categories;
create policy beneficiary_categories_manage_administrators
on public.beneficiary_categories for all to authenticated
using (private.has_role(organization_id, array['administrator']))
with check (private.has_role(organization_id, array['administrator']));

drop policy if exists "audit_log_read_oversight" on public.audit_log;
create policy audit_log_read_oversight
on public.audit_log for select to authenticated
using (private.has_role(organization_id, array['administrator', 'auditor']));

-- 8. Restore `authenticated`'s USAGE on the `private` helper schema,
-- stripped by v2's blanket revoke and never regranted. Needed for the
-- private.has_role() / private.has_region() / private.belongs_to_organization()
-- calls inside the policies restored above. `anon`/`public` intentionally
-- stay revoked -- these helpers are only meant to run in an authenticated
-- policy context.
grant usage on schema private to authenticated;

-- 9. Drop dead functions left behind by the v2 rewrite. Each references a
-- table v2 dropped (public.schemes / public.catalog_releases /
-- public.search_documents), so every one already fails at call time with
-- "relation does not exist" -- confirmed via `supabase db lint`, which
-- flagged all but admin_publish_scheme_catalog (a thin SQL wrapper around
-- publish_scheme_catalog, so lint's static check doesn't see the dead
-- reference, but it's equally broken transitively). None are called by the
-- Flutter app or the current v1 Edge Function (which uses newer
-- mss_search_data/mss_current_release RPCs); the only callers are the
-- legacy recommend/search Edge Functions, which are themselves superseded
-- by v1 and already 100% non-functional for this reason. Dropping these
-- changes no runtime behavior -- they cannot currently succeed regardless.
drop function if exists public.recommend_schemes(uuid);
drop function if exists public.search_schemes(vector);
drop function if exists public.admin_import_scheme_catalog(jsonb);
drop function if exists private.publish_scheme_catalog(text, boolean);
drop function if exists private.promote_catalog_release(uuid);
drop function if exists public.admin_publish_scheme_catalog(text, boolean);

-- 10. Recurrence guard -- fail loudly at migration time if any RLS-enabled
-- table in public/catalog/admin has zero policies, instead of silently
-- shipping a table nobody can read or write. This is exactly the class of
-- bug this migration fixes; the next blanket `drop policy` loop (if one is
-- ever written again) will now break the migration run immediately rather
-- than surface months later in an audit.
do $$
declare
    orphaned record;
    orphan_count integer := 0;
begin
    for orphaned in (
        select c.relname as tablename, n.nspname as schemaname
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where c.relrowsecurity = true
          and n.nspname in ('public', 'catalog', 'admin')
          and not exists (
              select 1 from pg_policies p
              where p.schemaname = n.nspname and p.tablename = c.relname
          )
          -- public.auth_user_id: a 1-column, no-PK, no-FK, uncommented table
          -- with RLS enabled and zero policies, present on production but in
          -- no migration file at all -- looks like ad-hoc debug cruft, not a
          -- real feature table. Explicitly excluded pending an owner
          -- decision (drop it vs. give it a real policy) rather than either
          -- guessing a policy for it or letting it block this migration.
          and not (n.nspname = 'public' and c.relname = 'auth_user_id')
          -- public.api_rate_limits: already present on production (created
          -- out-of-band, ahead of this migration in the sequence) with the
          -- exact shape 20260828000000_persistent_rate_limiter.sql defines
          -- and formally re-creates via `create table if not exists`. RLS
          -- enabled with zero client-facing policies is the correct,
          -- intentional posture there -- it's a service_role-only rate
          -- limiter bucket (`revoke all ... from anon, authenticated`, no
          -- policy needed since service_role bypasses RLS entirely).
          -- Excluded here so this guard doesn't fail on a table that isn't
          -- broken, just ahead of its own formal migration.
          and not (n.nspname = 'public' and c.relname = 'api_rate_limits')
    ) loop
        orphan_count := orphan_count + 1;
        raise warning 'RLS enabled with zero policies: %.%', orphaned.schemaname, orphaned.tablename;
    end loop;

    if orphan_count > 0 then
        raise exception '% table(s) have RLS enabled with zero policies -- see warnings above. Every RLS-enabled table must have at least one policy, or it silently becomes unreadable/unwritable for anon and authenticated alike.', orphan_count;
    end if;
end $$;
