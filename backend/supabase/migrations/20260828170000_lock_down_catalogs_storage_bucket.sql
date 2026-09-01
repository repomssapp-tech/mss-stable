-- ===========================================================
-- Migration: lock_down_catalogs_storage_bucket
-- Project : IN Schemes
-- Purpose : Close the largest remaining egress hole.
--
--           The `catalogs` bucket was public:true AND carried a blanket
--           "Public Access to catalogs bucket" SELECT policy over every
--           object. Verified with an unauthenticated HEAD -- no API key,
--           no session:
--
--             GET /storage/v1/object/public/catalogs/releases/
--                 1.33.0-alpha/scheme_catalog.json   -> 200, 7,368,610 bytes
--                 .../search_index.json              -> 200, 2,054,551 bytes
--
--           675 unauthenticated requests for scheme_catalog.json drains the
--           entire 5GB monthly egress allowance. This path bypasses the
--           Edge Function rate limiter, the PostgREST grants, and every
--           other control -- Storage is served straight off the CDN.
--
--           The app needs exactly ONE object from this bucket:
--           releases/<version>/catalog_bundle.json.gz (830 kB), fetched by
--           SupabaseCatalogReleaseSource.fetchPayload in
--           services/scheme_catalog_sync_service.dart. The other ~17 MB of
--           raw per-catalog JSON is publish-pipeline output that no client
--           reads.
-- ===========================================================

-- 1. Private bucket: kills the unauthenticated /object/public/... route
--    outright. Reads must now present an apikey and satisfy RLS below.
update storage.buckets
   set public = false
 where id = 'catalogs';

-- 2. Replace the blanket bucket-wide SELECT with a path-scoped one.
--    Clients may read the release bundle and nothing else; the raw
--    catalogs (scheme_catalog.json et al.) become unreachable to
--    anon/authenticated while staying available to the publisher role
--    through the existing "Admins/Publishers modify catalogs bucket"
--    policy, which is deliberately left untouched.
drop policy if exists "Public Access to catalogs bucket" on storage.objects;

create policy "Catalog bundle readable by app clients"
  on storage.objects
  for select
  to anon, authenticated
  using (
    bucket_id = 'catalogs'
    and name like 'releases/%/catalog_bundle.json.gz'
  );
