-- ===========================================================
-- Migration: release_byte_size
-- Project  : MSS - MSME Schemes Search
-- Purpose : V2-B6. CatalogManifest (Flutter) needs the release artifact's
--           byte size for its structural-validity check; add it and
--           extend mss_current_release() to expose it.
-- ===========================================================

alter table admin.catalog_releases
  add column if not exists package_byte_size integer;

comment on column admin.catalog_releases.package_byte_size is
  'Byte size of the release artifact (catalog_bundle.json.gz) as published to Supabase Storage.';

drop function if exists public.mss_current_release();

create function public.mss_current_release()
returns table (
  release_version text,
  package_sha256 text,
  package_byte_size integer,
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
    r.package_byte_size,
    r.schema_version,
    r.record_counts,
    r.published_at
  from admin.catalog_releases r
  where r.is_current = true and r.status = 'published'
  limit 1;
$$;

grant execute on function public.mss_current_release() to anon, authenticated;
