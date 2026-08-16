-- ===========================================================
-- Migration: release_artifact_columns
-- Project : IN Schemes
-- Purpose : V2-B6 (corrected architecture). Extends admin.catalog_releases
--           with the fields OFFLINE_CLOUD_SYNC_ARCHITECTURE.md /
--           RELEASE_MANIFEST_SPECIFICATION.md require that the table
--           didn't have: a semantic release_version (the existing
--           `version` column is a bare auto-increment bigint, not a
--           "1.35.0"-style string) and a package_sha256 (only per-file
--           hashes existed, on catalog_files.checksum). Also points
--           catalog_files.storage_path at the real "catalogs" Storage
--           bucket instead of local filesystem paths (set in V2-B2 before
--           any bucket existed).
-- ===========================================================

alter table admin.catalog_releases
  add column if not exists release_version text,
  add column if not exists package_sha256 text,
  add column if not exists record_counts jsonb;

comment on column admin.catalog_releases.release_version is
  'Semantic release identity, e.g. "1.33.0-alpha" -- distinct from `version` (bare auto-increment) and from `schema_version`. See RELEASE_MANIFEST_SPECIFICATION.md.';
comment on column admin.catalog_releases.package_sha256 is
  'SHA-256 of the release artifact as a whole. Distinct from catalog.* row-checksum aggregation (mss_catalog_meta()) -- see HASH_VERIFICATION_SPECIFICATION.md §2.';
comment on column admin.catalog_releases.record_counts is
  'Per-catalog entity counts for this release, mirroring release.json''s recordCounts.';
