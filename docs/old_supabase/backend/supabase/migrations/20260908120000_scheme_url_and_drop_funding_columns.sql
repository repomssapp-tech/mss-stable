-- ===========================================================
-- Migration: scheme_url_and_drop_funding_columns
-- Project  : MSS - MSME Schemes Search
-- Purpose  : Formalise the manually-added catalog.scheme.scheme_url column,
--            mirror it into record_json so it flows to the offline bundle /
--            mss_scheme_detail, and drop the two unused denormalised funding
--            columns.
--
--            scheme_url is the canonical official application/landing URL per
--            scheme. The Flutter app's "Apply Now" action uses it directly
--            (replacing content.applicationProcess.onlineUrl). Every scheme
--            has a value; there is no fallback in the client.
-- ===========================================================

begin;

-- 1. scheme_url column. Already added ad-hoc via the Supabase Table Editor;
--    `if not exists` keeps this migration idempotent against that state.
alter table catalog.scheme
  add column if not exists scheme_url text;

comment on column catalog.scheme.scheme_url is
  'Canonical official application/landing URL for the scheme. Authoritative '
  'source for the app "Apply Now" action (replaces '
  'content.applicationProcess.onlineUrl). Mirrored into '
  'record_json -> content -> schemeUrl by this migration and by the import '
  'pipeline going forward.';

-- 2. Mirror scheme_url into record_json at content.schemeUrl -- the shape the
--    Flutter MssSchemeAdapter reads (entity.content['schemeUrl']) and the
--    shape mss_scheme_detail() returns (it emits record_json verbatim as
--    `scheme`). The BEFORE UPDATE trigger catalog.mss_recompute_row_checksum()
--    recomputes catalog.scheme.checksum = sha256(record_json::text) on this
--    write automatically, so mss_catalog_meta() drift detection stays green.
update catalog.scheme
set record_json = jsonb_set(
      record_json,
      '{content,schemeUrl}',
      to_jsonb(scheme_url),
      true
    )
where scheme_url is not null and scheme_url <> '';

-- 3. Drop the two unused denormalised funding columns. No catalog.* RPC
--    (mss_scheme_detail / mss_lookup_catalog / mss_entity_record / the search
--    RPCs), edge function, or index references them -- the funding figures
--    live in record_json -> content -> benefits. catalog_scheme_filter_idx is
--    on (government_level, state, scheme_type), unaffected.
alter table catalog.scheme drop column if exists minimum_funding_amount;
alter table catalog.scheme drop column if exists maximum_funding_amount;

commit;

-- ===========================================================
-- Rollback (manual):
--   begin;
--   alter table catalog.scheme
--     add column if not exists minimum_funding_amount numeric(15,2),
--     add column if not exists maximum_funding_amount numeric(15,2);
--   update catalog.scheme
--     set record_json = record_json #- '{content,schemeUrl}';
--   -- scheme_url column intentionally left in place; drop separately if
--   -- truly required:
--   --   alter table catalog.scheme drop column if exists scheme_url;
--   commit;
-- ===========================================================
