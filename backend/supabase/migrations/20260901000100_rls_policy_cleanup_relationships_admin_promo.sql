-- ===========================================================
-- Migration: rls_policy_cleanup_relationships_admin_promo
-- Project  : MSS - MSME Schemes Search
-- Purpose : Medium-severity RLS cleanups from the 2026-09-01 audit. None of
--           these are exploitable today (catalog.* and admin.* are not in
--           config.toml `schemas`, and the app is JWT-gated), but each is a
--           latent exposure or an inconsistency with the rest of the policy
--           set.
--
--   M4. catalog.relationships is the only catalog.* table whose read policy
--       is USING (true) -- every sibling gates on status = 'PUBLISHED'. It
--       leaks the dependency graph for DRAFT / ARCHIVED entities. Gate it on
--       the source entity being published in catalog.entity_registry.
--
--   M5. admin.catalog_files / admin.catalog_releases carry leftover
--       "Public view ..." SELECT policies for {anon,authenticated}. Dead
--       today (admin schema unexposed) but they would instantly leak the
--       release manifest + storage paths if admin were ever added to the
--       API. The real client path is public.mss_current_release() (one row,
--       SECURITY DEFINER). Drop the dead policies; staff policies remain.
--
--   M6. public.promo_alerts and public.feature_requests are readable by
--       anon (promo_alerts via a bare TO PUBLIC policy, feature_requests via
--       an explicit {anon,authenticated} policy). The app requires auth
--       everywhere else; move both to authenticated-only. Non-sensitive
--       content, so this is hygiene / attack-surface reduction, not a leak
--       fix.
--       NOTE: verify the exact promo_alerts policy name against your live DB
--       first (audit query 3). The drop below covers the name from
--       20260731120000 / 20260816130000; if live differs, add that name.
-- ===========================================================

begin;

-- ---------------------------------------------------------------------------
-- M4. catalog.relationships -- gate reads on a published source entity.
-- ---------------------------------------------------------------------------
drop policy if exists "Anon/Public read relationships" on catalog.relationships;
drop policy if exists "Public read relationships for published entities" on catalog.relationships;

create policy "Public read relationships for published entities"
on catalog.relationships
for select
to anon, authenticated
using (
  exists (
    select 1
    from catalog.entity_registry er
    where er.entity_id = catalog.relationships.source_id
      and er.status = 'PUBLISHED'
      and er.is_deleted = false
  )
);

-- ---------------------------------------------------------------------------
-- M5. admin.* -- remove dead public-facing SELECT policies.
-- ---------------------------------------------------------------------------
drop policy if exists "Public view catalog files"    on admin.catalog_files;
drop policy if exists "Public view catalog releases" on admin.catalog_releases;

-- ---------------------------------------------------------------------------
-- M6. public.promo_alerts / public.feature_requests -- authenticated-only read.
-- ---------------------------------------------------------------------------
drop policy if exists "Allow public read access to promo_alerts" on public.promo_alerts;
drop policy if exists "Authenticated read promo_alerts" on public.promo_alerts;
create policy "Authenticated read promo_alerts"
on public.promo_alerts
for select
to authenticated
using (true);
revoke select on table public.promo_alerts from anon;

drop policy if exists "Public read feature requests" on public.feature_requests;
drop policy if exists "Authenticated read feature requests" on public.feature_requests;
create policy "Authenticated read feature requests"
on public.feature_requests
for select
to authenticated
using (true);
revoke select on table public.feature_requests from anon;

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   drop policy if exists "Public read relationships for published entities"
--     on catalog.relationships;
--   create policy "Anon/Public read relationships" on catalog.relationships
--     for select to anon, authenticated using (true);
--   create policy "Public view catalog files" on admin.catalog_files
--     for select to anon, authenticated using (true);
--   create policy "Public view catalog releases" on admin.catalog_releases
--     for select to anon, authenticated using (status = 'published');
--   drop policy if exists "Authenticated read promo_alerts" on public.promo_alerts;
--   create policy "Allow public read access to promo_alerts" on public.promo_alerts
--     for select using (true);
--   grant select on table public.promo_alerts to anon;
--   drop policy if exists "Authenticated read feature requests" on public.feature_requests;
--   create policy "Public read feature requests" on public.feature_requests
--     for select to anon, authenticated using (true);
--   grant select on table public.feature_requests to anon;
--   commit;
-- ===========================================================
