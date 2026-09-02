# Release Manifest Specification

> **Document status:** New specification, part of the offline/cloud sync architecture correction (see `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`).
> **Implementation status:** Documentation only. Field mappings below describe existing artifacts as they are today; no files were regenerated or modified producing this document (`release.json`'s current content was last changed in V2-B2, prior to this correction).

---

## 1. Required manifest fields

Every release must declare, at minimum:

```json
{
  "releaseVersion": "1.35.0",
  "schemaVersion": "1.x.x",
  "generatedAt": "2026-08-17T00:00:00Z",
  "packageSha256": "...",
  "perFileSha256": { "scheme_catalog.json": "...", "...": "..." },
  "recordCounts": { "scheme_catalog.json": 219, "...": 0 },
  "catalogCount": 219
}
```

This is the **lightweight metadata** the API must expose so the Flutter app can determine whether an update exists **without downloading the entire catalog** — see §5.

## 2. Field definitions

| Field | Type | Definition |
|---|---|---|
| `releaseVersion` | string (semver-like) | Identifies this exact release. Distinct from `schemaVersion` — see `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §9. |
| `schemaVersion` | string | Contract/schema compatibility version. A client must reject a `schemaVersion` it doesn't understand rather than attempt to parse it. |
| `generatedAt` | ISO-8601 string | Build timestamp. Informational only — **not** used to determine staleness (see `HASH_VERIFICATION_SPECIFICATION.md` §3; comparison is by `releaseVersion`/`packageSha256`). |
| `packageSha256` | hex string | SHA-256 of the release artifact as a whole. |
| `perFileSha256` | map<filename, hex string> | SHA-256 of each constituent catalog file. |
| `recordCounts` | map<filename, int> | Per-catalog entity counts — a cheap sanity check independent of hashing. |
| `catalogCount` | int | Total entity count across all catalogs in the release (sum of `recordCounts`). |

## 3. Mapping onto the existing offline manifest (`frontend/assets/catalog/release.json`)

The field names in the current file predate this specification and don't match 1:1, but the *coverage* is already nearly complete:

| This spec's field | Current `release.json` field | Status |
|---|---|---|
| `releaseVersion` | `releaseTag` (e.g. `"1.33.0-alpha"`) | **Present, different name.** `releaseTag` already functions as the release version; a future implementation should either rename it to `releaseVersion` or treat them as synonyms explicitly in code, not silently. |
| `schemaVersion` | `schemaVersion` | Present, same name. |
| `generatedAt` | `releasedAt` | Present, different name, same meaning. |
| `packageSha256` | `bundleSha256` | Present, different name, same meaning (SHA-256 of the compressed bundle asset). |
| `perFileSha256` | `perFileSha256` | **Present, same name** — added in V2-B2, covers all 15 catalog files + `search_index.json`. |
| `recordCounts` | `recordCounts` | Present, same name, covers the 15 indexed catalogs. |
| `catalogCount` | `entityCount` | Present, different name, same meaning. |
| (new) `releaseId` | `releaseId` (UUID) | Present, added in V2-B2 — not part of this spec's minimum field set but retained as an additional unique identifier distinct from the human-readable `releaseVersion`/`releaseTag`. |

**Conclusion: the existing manifest format already structurally supports this specification.** No new fields need to be invented; the remaining work (not performed by this document, per the "documentation only" scope) is (a) reconciling the naming (`releaseTag`→`releaseVersion`, `bundleSha256`→`packageSha256`, etc. — either a rename or an explicit alias layer) and (b) actually publishing this manifest to Supabase Storage alongside the artifact it describes, which does not happen today.

## 4. Mapping onto `admin.catalog_releases` / `admin.catalog_files`

These tables (schema created by `20260805000000_database_architecture_v2.sql`, first populated in V2-B2) are the Supabase Tables-side release bookkeeping described in `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §12:

| This spec's field | `admin.catalog_releases` / `admin.catalog_files` column | Status |
|---|---|---|
| `releaseVersion` | `catalog_releases.version` (bigint, auto-increment identity) | **Gap.** The current column is a simple incrementing integer, not a semantic version string like `1.35.0`. A future implementation needs a `release_version text` (or similar) column, or must define a deterministic mapping from the integer to a semver string. |
| `schemaVersion` | `catalog_releases.schema_version` | Present. |
| `generatedAt` | `catalog_releases.published_at` | Present, same meaning. |
| `packageSha256` | *(none)* | **Gap.** `catalog_releases` has no package-level hash column today — only per-file hashes exist, on `catalog_files.checksum`. A future implementation needs a `package_sha256` column on `catalog_releases`, or a deterministic aggregate function over its `catalog_files` rows (distinct from `mss_catalog_meta()`'s live per-row-checksum aggregate, per `HASH_VERIFICATION_SPECIFICATION.md` §2). |
| `perFileSha256` | `catalog_files.checksum`, one row per file | Present, correct shape (join on `release_id`). |
| `recordCounts` | *(none directly)* | **Gap.** Not currently tracked per-release on these tables; would need to be added or derived. |
| storage location of the artifact | `catalog_files.storage_path` | **Present but currently wrong content.** V2-B2 populated this with local filesystem paths (`Plan/catalog/<file>.json`) since no Storage bucket existed at the time. Once a Storage bucket exists (per `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §4), this column should be updated to hold the actual Storage object path (e.g. `releases/1.35.0/scheme_catalog.json`). |

## 5. API exposure requirement

The metadata check must be **lightweight** — the API must **not** require downloading the full catalog merely to determine whether an update exists. `GET /v1/meta` (already live, built in this session) already returns a lightweight `catalogVersion`/`catalogChecksum`/`entityCounts` payload computed without transferring the full catalog — the same design principle this specification requires, just currently sourced from the live `catalog.*` row-checksum aggregate (`public.mss_catalog_meta()`) rather than a published release's manifest. A future implementation should either (a) extend `/v1/meta`'s response to include `releaseVersion`/`packageSha256` sourced from `admin.catalog_releases`, or (b) add a dedicated lightweight endpoint for release-metadata specifically, keeping the existing `/v1/meta` contract (used by the currently-shipped `MssApiClient.getMetadata()`) unchanged. Either approach must not regress the "no full-catalog download for a metadata check" property `/v1/meta` already has.

## 6. Do not use timestamp-only comparison

Reiterating `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §5: `generatedAt`/`releasedAt`/`published_at` are informational fields, never the basis for an update decision. Update decisions compare `releaseVersion` and/or `packageSha256`.
