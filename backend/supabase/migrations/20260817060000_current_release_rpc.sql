-- ===========================================================
-- Migration: current_release_rpc
-- Project : IN Schemes
-- Purpose : V2-B6 (corrected architecture). Exposes the published release
--           artifact's identity (releaseVersion, packageSha256) via a
--           dedicated RPC, kept deliberately separate from
--           mss_catalog_meta()'s live catalog.* row-checksum aggregate --
--           per HASH_VERIFICATION_SPECIFICATION.md §2, these are two
--           different things computed two different ways and must not be
--           merged into one field.
-- ===========================================================

create or replace function public.mss_current_release()
returns table (
  release_version text,
  package_sha256 text,
  schema_version integer,
  record_counts jsonb,
  published_at timestamptz
)
language sql
stable
security definer
set search_path = public, admin, extensions
as $$
  select
    r.release_version,
    r.package_sha256,
    r.schema_version,
    r.record_counts,
    r.published_at
  from admin.catalog_releases r
  where r.is_current = true and r.status = 'published'
  limit 1;
$$;

grant execute on function public.mss_current_release() to anon, authenticated;
