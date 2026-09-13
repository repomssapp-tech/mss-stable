# MSS Catalog Release, Sync & Verification Specifications

**Audience:** Developers and operators working on the MSS catalog release pipeline, offline sync service, and Supabase catalog mirror.

## Table of Contents

1. [Part 1: Catalog Entity & Import Specification](#part-1-catalog-entity-import-specification)
2. [Part 2: Dual-Copy Catalog Release & Single Source-of-Truth Architecture](#part-2-dual-copy-catalog-release-single-source-of-truth-architecture)
3. [Part 3: Release Manifest Specification (release.json)](#part-3-release-manifest-specification-release.json)
4. [Part 4: Hash Verification Specification](#part-4-hash-verification-specification)
5. [Part 5: Offline / Cloud Sync Architecture Specification](#part-5-offline-cloud-sync-architecture-specification)
6. [Part 6: Update Flow State Machine & Storage Pointer Specification](#part-6-update-flow-state-machine-storage-pointer-specification)

---

# Part 1: Catalog Entity & Import Specification

# MSS Catalog Import Specification v1.0

## Document Information

-   **Project:** MSS (MSME Scheme Search)
-   **Version:** 1.0
-   **Status:** Draft for Implementation
-   **Purpose:** Define the complete import contract between generated
    JSON catalogs and the Supabase Database Architecture v2.0.

------------------------------------------------------------------------

# 1. Purpose

This specification defines the deterministic import pipeline used to
load generated MSS JSON catalogs into Supabase.

The importer shall:

-   Preserve entity IDs.
-   Preserve provenance.
-   Preserve localization.
-   Preserve AI metadata.
-   Preserve relationships.
-   Support full and incremental imports.
-   Be transaction-safe and idempotent.

------------------------------------------------------------------------

# 2. Scope

Applies to all MSS catalog JSON files:

1.  common_catalog.json
2.  authority_catalog.json
3.  institution_catalog.json
4.  finance_catalog.json
5.  tax_catalog.json
6.  export_catalog.json
7.  csr_catalog.json
8.  treds_catalog.json
9.  scheme_catalog.json
10. search_index.json

------------------------------------------------------------------------

# 3. Import Architecture

``` text
Generated JSON Catalogs
        │
        ▼
Manifest Validation
        │
        ▼
Checksum Validation
        │
        ▼
Schema Validation
        │
        ▼
Catalog Import Engine
        │
        ▼
Supabase Database
        │
        ├── catalog tables
        ├── entity registry
        ├── relationships
        └── import batches
```

------------------------------------------------------------------------

# 4. Import Order

The following order is mandatory:

1.  common
2.  authority
3.  institution
4.  finance
5.  tax
6.  export
7.  csr
8.  treds
9.  scheme
10. search_index

Dependencies must exist before dependent catalogs are imported.

------------------------------------------------------------------------

# 5. Import Lifecycle

1.  Load manifest.
2.  Verify schema version.
3.  Verify release version.
4.  Verify file checksums.
5.  Validate JSON schema.
6.  Validate entity IDs.
7.  Open database transaction.
8.  Import catalog entities.
9.  Update entity registry.
10. Resolve relationships.
11. Commit transaction.
12. Generate import report.

Any fatal failure shall rollback the entire transaction.

------------------------------------------------------------------------

# 6. Entity Mapping

Each imported entity shall populate:

-   Hybrid relational columns
-   record_json (canonical entity)
-   entity_registry
-   relationship records
-   import metadata

The complete JSON entity must remain intact inside `record_json`.

------------------------------------------------------------------------

# 7. Validation Rules

Every entity must validate:

-   Required fields
-   JSON schema
-   Entity ID format
-   Version
-   Checksum
-   Localization block
-   Provenance block
-   Verification block
-   AI block
-   Analytics block

------------------------------------------------------------------------

# 8. Relationship Resolution

Relationships shall be resolved using immutable IDs.

Supported relationships include:

-   Scheme → Authority
-   Scheme → Institution
-   Scheme → Finance
-   Scheme → Tax
-   Scheme → Export
-   Scheme → CSR
-   Scheme → TReDS
-   Scheme → Search Index

Broken references are fatal validation errors.

------------------------------------------------------------------------

# 9. Conflict Handling

  Condition            Action
  -------------------- -----------------------
  Duplicate ID         Reject import
  Invalid checksum     Reject import
  Missing dependency   Rollback
  Schema mismatch      Reject import
  Duplicate checksum   Skip unchanged record

------------------------------------------------------------------------

# 10. Rollback Strategy

Any fatal validation or database error must:

1.  Rollback transaction.
2.  Preserve previous database state.
3.  Record failure in import_batches.
4.  Generate failure report.

------------------------------------------------------------------------

# 11. Incremental Imports

Importer must support:

-   Full release import
-   Single catalog import
-   Single entity import
-   Incremental update based on checksum

------------------------------------------------------------------------

# 12. Import Batch Tracking

Each import creates an `admin.import_batches` record including:

-   Batch ID
-   Release Version
-   Catalogs Imported
-   Start Time
-   End Time
-   Duration
-   Status
-   Errors
-   Warnings

------------------------------------------------------------------------

# 13. Logging

Every import shall log:

-   Start
-   Completion
-   Imported entities
-   Updated entities
-   Skipped entities
-   Warnings
-   Errors
-   Relationship count

------------------------------------------------------------------------

# 14. Security

Only authorized roles may execute imports.

-   Administrator
-   Publisher
-   Editor (if permitted)

Anonymous users cannot import catalogs.

------------------------------------------------------------------------

# 15. Version Compatibility

Importer shall verify:

-   Manifest version
-   Catalog schema version
-   Database schema version
-   Minimum supported application version

------------------------------------------------------------------------

# 16. Acceptance Tests

The importer is accepted only if:

-   Manifest validation passes.
-   Checksums validate.
-   All entities import successfully.
-   Relationships resolve.
-   Entity registry updates correctly.
-   Localization remains unchanged.
-   Provenance remains unchanged.
-   Round-trip import/export succeeds.
-   Import report is generated.

------------------------------------------------------------------------

# 17. Round-Trip Requirement

The following workflow must be lossless:

``` text
JSON Catalog
     ↓
Import
     ↓
Database
     ↓
Export
     ↓
JSON Catalog
```

The exported catalog must be structurally identical to the imported
catalog except for approved metadata (checksums, timestamps, release
identifiers).

------------------------------------------------------------------------

# 18. Idempotency

Importing the same catalog multiple times shall produce the same
database state.

Requirements:

-   No duplicate entities.
-   Immutable IDs preserved.
-   Unchanged records skipped by checksum.
-   Import batch still recorded for audit.

------------------------------------------------------------------------

# 19. Success Criteria

Phase 2 is complete only when:

-   All catalogs import successfully.
-   No schema changes are required for future catalogs.
-   Database and JSON remain structurally compatible.
-   Referential integrity is preserved.
-   All validation suites pass.
-   Import is repeatable, deterministic, and auditable.

---

# Part 2: Dual-Copy Catalog Release & Single Source-of-Truth Architecture

# Dual-Copy Catalog Release & Single Source-of-Truth Architecture Specification

> **Document Status:** Architectural Specification & Manifest Proposal (Phase 5)  
> **Target System:** MSS Platform (Flutter Offline Catalog + Supabase Online Catalog)  
> **Aligned References:**  
>  - `DATABASE_ARCHITECTURE.md` (Repo Root — Supabase v2.0 Schema & Tables)  
>  - `MSS_Catalog_Import_Specification_v1.0.md` (Repo Root — Deterministic Importer Spec)  
>  - `MSS_ANTIGRAVITY_HANDOFF/api_docs/API_ENDPOINT_REFERENCE.md` (REST API Contract)  

---

## 1. Executive Summary & Source-of-Truth Hierarchy

This specification formalizes the **Dual-Copy Catalog Architecture** for the MSS Platform.

The app ships an offline bundled copy of the verified government scheme catalog (`catalog_bundle.json.gz` + `release.json`). To support online API search, real-time eligibility scoring, and live updates without requiring full Play Store application updates, a **second copy** of the verified catalog lives in the Supabase Cloud Database.

### 1.1 Source-of-Truth Flowchart

```text
  MSS VERIFIED RELEASE PIPELINE (Single Source of Truth)
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
   OFFLINE APP COPY                SUPABASE COPY
   (Flutter bundled asset)         (Cloud database tables)
         │                               │
         └───────────────┬───────────────┘
                         ▼
                 HASH VERIFICATION
                         │
                         ▼
                 Release Integrity
```

```text
  Source-of-truth hierarchy:

  SOURCE / VERIFIED CATALOG (The pipeline release builder)
             │
             ▼
      RELEASE PACKAGE (Manifest + Bundled Gzip Asset)
             │
      ┌──────┴──────┐
      ▼             ▼
  OFFLINE       SUPABASE
    COPY          COPY
```

### 1.2 Non-Negotiable Architecture Rules

1. **Identical Dataset Guarantee**: The offline app catalog bundle and the Supabase database catalog represent **the exact same verified release package**. They are NEVER separately or manually edited datasets.
2. **No Direct Supabase Catalog Editing**: Supabase is an online read/query mirror and update distribution endpoint. It MUST NEVER become a place where scheme catalog data is created, edited, or mutated out-of-band. All catalog mutations must pass through the canonical catalog release pipeline.
3. **Cryptographic Hash Verification**: Both copies are hash-verified against the release manifest checksum before being loaded by the client app or imported into Supabase.

---

## 2. Current Baseline Investigation: Release & Manifest Mechanics

### 2.1 Actual `release.json` Structure
An audit of `frontend/assets/catalog/release.json` establishes the baseline metadata format currently shipped with the app:

```json
{
  "releaseTag": "1.33.0-alpha",
  "schemaVersion": "1.0.0",
  "releasedAt": "2026-08-04T00:00:00Z",
  "bundleAsset": "assets/catalog/catalog_bundle.json.gz",
  "bundleBytes": 632296,
  "bundleSha256": "32d647183d61081f7400aba3a8679d5e9fd77915e28863c9fc72365d6fe0f0bc",
  "uncompressedBytes": 9145232,
  "entityCount": 969,
  "searchIndexCount": 969,
  "recordCounts": {
    "authority_catalog.json": 124,
    "common_catalog.json": 344,
    "csr_catalog.json": 16,
    "export_catalog.json": 13,
    "finance_catalog.json": 115,
    "institution_catalog.json": 83,
    "knowledge_catalog.json": 28,
    "scheme_catalog.json": 217,
    "search_index.json": 969,
    "tax_catalog.json": 13,
    "treds_catalog.json": 16
  }
}
```

### 2.2 How `MssCatalogBundle` Validates the Manifest
The Flutter asset loader ([`frontend/lib/services/mss_catalog_bundle.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/mss_catalog_bundle.dart)) enforces strict boot-time verification:

1. **Asset Loading**: Reads `release.json` string and `catalog_bundle.json.gz` bytes.
2. **SHA-256 Calculation**: Computes `sha256.convert(compressedBytes)` over the raw compressed asset bytes.
3. **Checksum Assertion**: Compares the actual hash string against `releaseJson['bundleSha256']`.
4. **Failure Reaction**: If the checksums mismatch, `MssCatalogBundle` throws a fatal `Catalog bundle SHA-256 checksum mismatch` exception, halting initialization to prevent corrupted catalog state.
5. **Decompression & Parsing**: Upon checksum pass, offloads gzip decompression and JSON decoding to a background Dart isolate via `compute()`.

---

## 3. Release Manifest Specification & Extension Proposal

To support dual-copy verification between the local Flutter asset bundle and the Supabase cloud database copy, the release manifest should be extended with additional cryptographic and traceability fields.

### 3.1 Field-by-Field Proposal Matrix

| Field | Type | Existing in `release.json` | Proposed Addition | Purpose & Integrity Role |
|---|---|:---:|:---:|---|
| `releaseTag` | `String` | YES | Preserved | Human-readable version tag (e.g. `1.33.0-alpha`). |
| `schemaVersion` | `String` | YES | Preserved | DTO/Database contract version (e.g. `1.0.0`). |
| `releasedAt` | `String` | YES | Preserved | ISO 8601 generation timestamp (`2026-08-04T00:00:00Z`). |
| `bundleAsset` | `String` | YES | Preserved | Relative asset path in Flutter app bundle. |
| `bundleBytes` | `int` | YES | Preserved | Compressed byte length of `catalog_bundle.json.gz`. |
| `bundleSha256` | `String` | YES | Preserved | SHA-256 hash of the **compressed** `.json.gz` asset. |
| `uncompressedBytes` | `int` | YES | Preserved | Total byte size of uncompressed JSON payload. |
| `entityCount` | `int` | YES | Preserved | Total catalog entities across all files (969). |
| `searchIndexCount` | `int` | YES | Preserved | Total search index records (969). |
| `recordCounts` | `Map<String, int>` | YES | Preserved | Per-catalog record counts (`scheme_catalog.json`: 217, etc.). |
| **`releaseId`** | `String (UUIDv4)` | NO | **NEW** | Unique UUID v4 identifying this specific release build across local logs and Supabase `admin.catalog_releases(id)`. |
| **`uncompressedSha256`** | `String` | NO | **NEW** | SHA-256 hash of the **uncompressed** JSON payload. Allows Supabase importer to verify data payload after decompression. |
| **`perFileSha256`** | `Map<String, String>` | NO | **NEW** | SHA-256 checksum map for each individual component file (`scheme_catalog.json`, `finance_catalog.json`, etc.), matching `MSS_Catalog_Import_Specification_v1.0.md` step 4. |
| **`minSupportedAppVersion`** | `String` | NO | **NEW** | Minimum Flutter app build version required to parse this release schema. |

### 3.2 Proposed Extended `release_manifest.json` Example

```json
{
  "releaseId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "releaseTag": "1.33.0-alpha",
  "schemaVersion": "1.0.0",
  "minSupportedAppVersion": "2.0.0",
  "releasedAt": "2026-08-04T00:00:00Z",
  "bundleAsset": "assets/catalog/catalog_bundle.json.gz",
  "bundleBytes": 632296,
  "bundleSha256": "32d647183d61081f7400aba3a8679d5e9fd77915e28863c9fc72365d6fe0f0bc",
  "uncompressedBytes": 9145232,
  "uncompressedSha256": "8f4e2a1b9c3d7e5f6a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f",
  "entityCount": 969,
  "searchIndexCount": 969,
  "recordCounts": {
    "authority_catalog.json": 124,
    "common_catalog.json": 344,
    "csr_catalog.json": 16,
    "export_catalog.json": 13,
    "finance_catalog.json": 115,
    "institution_catalog.json": 83,
    "knowledge_catalog.json": 28,
    "scheme_catalog.json": 217,
    "search_index.json": 969,
    "tax_catalog.json": 13,
    "treds_catalog.json": 16
  },
  "perFileSha256": {
    "authority_catalog.json": "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0",
    "common_catalog.json": "b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef01",
    "scheme_catalog.json": "c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef012",
    "finance_catalog.json": "d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0123"
  }
}
```

---

## 4. Dual-Copy Verification & Synchronization Workflow

The following step-by-step specification defines how the two copies stay aligned without manual database drift.

### 4.1 Pipeline & Ingestion Lifecycle

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. BUILD RELEASE                                                        │
│    - Catalog pipeline generates 11 component JSON files                 │
│    - Computes perFileSha256, bundleSha256, uncompressedSha256           │
│    - Outputs catalog_bundle.json.gz & release_manifest.json             │
└─────────────────────────────────────────────────────────────────────────┘
                                     │
           ┌─────────────────────────┴─────────────────────────┐
           ▼                                                   ▼
┌─────────────────────────────────────┐   ┌───────────────────────────────┐
│ 2A. FLUTTER BUNDLE EMBEDDING        │   │ 2B. SUPABASE INGESTION        │
│  - Bundled as local app asset.      │   │  - Invokes Import Spec v1.0.  │
│  - MssCatalogBundle validates       │   │  - Validates release_manifest.│
│    bundleSha256 at app startup.     │   │  - Populates catalog.* schema.│
│                                     │   │  - Inserts admin.catalog_rels.│
└─────────────────────────────────────┘   └───────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. RUNTIME PARITY AUDIT (GET /v1/meta)                                  │
│    - Flutter client requests GET /v1/meta                               │
│    - Compares local catalogVersion & bundleSha256 against server meta   │
│    - Matching hashes = Seamless hybrid operation                        │
│    - Differing hashes = Background update available                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Alignment Verification Rules
- **Server Metadata Alignment**: The `GET /v1/meta` REST endpoint returns `catalogVersion` and `catalogChecksum`. The server MUST return the exact `bundleSha256` value from `release_manifest.json`.
- **Parity Check**: When the Flutter app connects to `MssApiClient`, `SchemeRepository` evaluates `isStaleAgainst(cachedVersion)`. If local `bundleSha256 == server.catalogChecksum`, the client and server operate on 100% identical data.

---

## 5. Inspection Findings & Open Questions Resolution (Phase 6 Read-Only Audit)

Based on a read-only empirical inspection of the production Supabase environment (`https://houpzsxmwemoztpuigmo.supabase.co`) and backend repository resources, the Phase 5 open questions have been evaluated and resolved as follows:

### 5.1 Question 1: Checksum Scope Alignment
* **Status**: **Answered**
* **Finding**: `bundleSha256` (the compressed asset hash) is the primary checksum verified at runtime by Flutter's `MssCatalogBundle.load` and surfaced via `GET /v1/meta` (`catalogChecksum`).
* **Resolution**: Both the client `MssCatalogBundle` and the database `admin.catalog_releases` schema use `bundleSha256` as the authoritative release signature. `uncompressedSha256` is retained in `release_manifest.json` as a secondary verification field during Supabase DB import.

### 5.2 Question 2: Supabase Storage Bucket vs Database Table Partitioning
* **Status**: **Answered & Clarified**
* **Finding**: Read-only inspection of the remote Supabase project returned **0 Storage Buckets** (`storage.buckets` = `[]`). Furthermore, PostgREST table queries confirmed that `catalog.*` and `admin.*` schemas do not exist yet in live Supabase (`406 Invalid schema: catalog` / `406 Invalid schema: admin`).
* **Resolution**: To support online updates and API querying, the future database deployment phase must:
  1. Apply `20260805000000_database_architecture_v2.sql` to create `catalog.*` and `admin.*` schemas.
  2. Provision a public Supabase Storage bucket (e.g. `catalog-releases`) to host `.json.gz` bundle assets.

### 5.3 Question 3: Automated Trigger Mechanisms for Database Ingestion
* **Status**: **Answered**
* **Finding**: 12 Deno Edge Functions exist under `backend/supabase/functions/` (including `publishCatalog`, `buildCatalog`, `exportCatalog`). Inspection of `publishCatalog/index.ts` showed it is currently a **placeholder endpoint** returning `{"message": "publishCatalog placeholder"}`. No CI workflow or automated trigger currently executes catalog database imports automatically.
* **Resolution**: Release ingestion is currently manual / CLI-driven via `python catalog/mss_api.py` per `MSS_Catalog_Import_Specification_v1.0.md`. Automated deployment will require finishing `publishCatalog` or wiring GitHub Actions.

### 5.4 Question 4: Telemetry (`public.sync_logs`) Availability
* **Status**: **Answered**
* **Finding**: Probing `public.sync_logs` returned `404 Could not find the table 'public.sync_logs'`. Only user profile and user interaction tables (`profiles`, `saved_schemes`, `recent_schemes`, `ai_conversations`, `search_logs`) exist in the live `public` schema today.
* **Resolution**: `public.sync_logs` does not exist yet in the live database. Client sync telemetry cannot be logged until `20260805000000_database_architecture_v2.sql` is applied in a future migration phase.

---

# Part 3: Release Manifest Specification (release.json)

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

---

# Part 4: Hash Verification Specification

# Hash Verification Specification

> **Document status:** New specification, part of the offline/cloud sync architecture correction (see `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`).
> **Implementation status:** Documentation only.

---

## 1. Algorithm

SHA-256, exclusively, for every hash in this system: package hash, per-file hashes, and (independently) the live per-row checksum scheme already in use in `catalog.*` tables and `public.mss_catalog_meta()`.

## 2. What gets hashed

| Hash | Computed over | Purpose |
|---|---|---|
| `packageSha256` | The exact bytes of the release artifact (the compressed bundle, or — if the multi-file architecture is preserved — a well-defined deterministic combination of the constituent files) | Identity/integrity of the release as a whole; what the client compares against the manifest before and after download |
| per-file SHA-256 | Each individual catalog JSON file's exact bytes | Lets a client (or the pipeline) verify a single file without re-hashing the whole package; also enables partial-integrity diagnosis if a download is corrupted |
| `catalog.*` row `checksum` (existing, unrelated) | Each row's `JSON.stringify`-serialized record (see `backend/scripts/generate_catalog_import_sql.js`) | Table-layer drift detection only (`public.mss_catalog_meta()`'s live aggregate) — **not** comparable to `packageSha256` or the offline bundle's `bundleSha256`, since it uses a different serialization scheme over different data (Postgres rows, not the source files' raw bytes). Keep these two hash families conceptually separate; do not attempt to make them equal. |

## 3. Local vs. cloud comparison

```
LOCAL:
  releaseVersion = 1.34.0
  packageSha256  = ABC...

CLOUD:
  releaseVersion = 1.35.0
  packageSha256  = XYZ...

If releaseVersion or packageSha256 differ → update candidate exists.
```

The comparison is release-identity based (`releaseVersion` + `packageSha256`), not a re-derivation or partial comparison. Either value differing is sufficient to trigger the update flow in `UPDATE_FLOW_SPECIFICATION.md`.

## 4. What a hash proves — and what it does not

**A hash proves integrity and identity of the artifact.** It confirms:
- The downloaded bytes are exactly the bytes that were published under that `releaseVersion`.
- The artifact was not corrupted in transit or tampered with.

**A hash does NOT prove the underlying catalog information is factually correct.** Whether a scheme's eligibility criteria, benefit amounts, or application URL are accurate is the responsibility of the MSS catalog verification pipeline (`Plan/catalog/validate_*.py`, provenance/fieldSources tracking, human review workflow) — entirely separate from hash verification. A release can be perfectly hash-verified and still contain a factual data error; hash verification only guarantees the client received precisely what was published, not that what was published is correct.

## 5. Verification points

The client verifies the downloaded artifact's hash **before** activating it, per the flow in `UPDATE_FLOW_SPECIFICATION.md`:

1. Download release artifact to temporary storage.
2. Compute SHA-256 of the downloaded bytes.
3. Compare against the `packageSha256` declared in the release's manifest (fetched via the lightweight metadata check, before the download started).
4. **Mismatch → reject the download, keep the current active release, do not activate.**
5. Match → proceed to the remaining validation steps (schema compatibility, JSON structure, IDs, relationships, localization, search compatibility) before activation.

Hash verification is necessary but not sufficient for activation — it is the first of several validation gates, not the only one.

## 6. Relationship to existing manifest fields

`frontend/assets/catalog/release.json` already carries `bundleSha256` (package-level) and `perFileSha256` (per-file, added in V2-B2) in exactly this shape. `admin.catalog_files.checksum` (populated in V2-B2) already stores one SHA-256 per catalog file. No new hash *mechanism* is needed — this document formalizes how the existing hashes are to be used for verification, and draws the boundary against the separately-existing, differently-computed `catalog.*` row-checksum scheme (§2) so the two are never confused with each other.

---

# Part 5: Offline / Cloud Sync Architecture Specification

# Offline/Cloud Sync Architecture — Corrected Specification

> **Document status:** Architecture correction, supersedes the "assemble a payload from Supabase tables on demand" approach described informally during V2-B6 planning. Aligns with and extends `DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md`.
> **Implementation status:** Documentation only. No Supabase tables, no Storage buckets, no Flutter/Dart code, no API routes were created or modified in producing this document.

---

## 1. Core principle

MSS is an **offline-first application with a remotely synchronized catalog**. The Flutter app must never require a new APK/build for a data-only catalog update. Achieving this requires **two synchronized representations of the same verified MSS release**, plus the app's own local copy — three places, one release identity, always:

```
                    MSS VERIFIED RELEASE
                              |
             +----------------+----------------+
             |                                 |
             ↓                                 ↓
      Supabase Tables                   Supabase Storage
      (online API/query layer)          (immutable release artifact)
             |                                 |
             ↓                                 ↓
       API queries                    Flutter synchronization
                                                |
                                                ↓
                                     Flutter local catalog
                                                |
                                                ↓
                                     Offline application
```

**Supabase Tables** and **Supabase Storage** must always correspond to the *same* release. `Storage = 1.36.0` while `Tables = 1.35.0` is a deployment inconsistency, not a valid state — see §7.

## 2. Role separation (do not conflate these)

| Layer | Role | What it is NOT |
|---|---|---|
| Supabase Tables (`catalog.*`, `admin.*`) | Online API/query layer: search, scheme lookup, finance, tax, clusters, relationships, localization, eligibility, and every other documented `/v1/*` operation (see `API_CONTRACT.md`) | Not the source the Flutter app downloads from for offline sync |
| Supabase Storage | Immutable release artifacts — the exact bytes the Flutter app downloads and verifies | Not queried directly by the API layer; not rebuilt from tables on demand |
| Flutter local catalog | The offline copy actually used by the running app | Not authoritative — always traceable back to a specific release |

**Do not replace the existing API architecture with Storage downloads** — the API (`v1` Edge Function + RPCs built in V2-B3/B4/B5) continues to query structured Supabase table data exactly as it does today. Storage is exclusively for the release-artifact sync path.

**Do not construct an on-demand download payload by re-serializing `catalog.*` table rows at request time.** A release artifact must be a specific, immutable, pre-built, hash-verifiable package — not something reconstructed fresh (and potentially differently) on every request. See §3.

## 3. Why on-demand table assembly is wrong

An endpoint that builds `{scheme: [...], finance: [...], ...}` fresh from `catalog.*` on every call cannot satisfy:

- **Immutability** — two calls a second apart could differ if a row changed mid-way, with no way to know which "version" was actually downloaded.
- **Hash-verifiability of a specific release** — there is no fixed byte sequence to hash; `packageSha256` would need to be computed per-request, defeating the purpose of a manifest-declared, pre-known hash the client checks *before* downloading.
- **Atomicity across catalogs** (§6) — an on-demand assembly could observe `scheme` mid-update and `finance` pre-update in the same response, producing an internally inconsistent release that was never actually published as a unit.

A release must be built once, hashed once, published once, and served byte-identically to every client that requests that version thereafter.

## 4. Supabase Storage layout

```
releases/
  1.34.0/
    catalog_bundle.json.gz
    manifest.json
  1.35.0/
    catalog_bundle.json.gz
    manifest.json
  1.36.0/
    catalog_bundle.json.gz
    manifest.json
```

- Each release directory is **immutable** once published. Never overwrite `releases/1.35.0/*` after publication.
- If catalog data changes, publish a **new** release directory (`1.35.1`, `1.36.0`, etc.) — never mutate an existing one.
- If the multi-file catalog architecture (15 separate JSON files, as currently used by `tools/generate_catalog_bundle.py`) is preserved rather than a single bundle, the release folder holds all constituent files, but the *release as a whole* is still one atomic, versioned unit — see §6.
- Retain previous releases per a retention policy (exact policy TBD by the team; not specified further here) rather than deleting immediately — this is what makes rollback (§8) possible.

## 5. Release identity

Every release carries:

| Field | Purpose |
|---|---|
| `releaseVersion` | Semantic version identifying this exact release (e.g. `1.35.0`) — distinct from `schemaVersion`, see §9 |
| `schemaVersion` | Contract/schema compatibility version |
| `generatedAt` | ISO-8601 build timestamp |
| `packageSha256` | SHA-256 of the release artifact as a whole |
| per-file SHA-256 | SHA-256 of each constituent catalog file |
| record counts | Per-catalog entity counts, for a cheap sanity check independent of the hash |
| package metadata | Anything else needed to describe the release (byte sizes, catalog list, etc.) |

**Do not use timestamps alone to determine whether an update exists.** Two releases published seconds apart must be distinguished by `releaseVersion`/`packageSha256`, not by comparing `generatedAt` values (clock skew, re-publishes, and retries make timestamp-only comparison unreliable).

## 6. Atomic release requirement

**Never update individual catalogs independently.**

```
BAD:                              GOOD:
scheme_catalog   → new            Release 1.35.0
finance_catalog  → old              +-- scheme
tax_catalog      → new              +-- finance
                                     +-- tax
                                     +-- treds
                                     +-- localization
                                     +-- relationships
                                     +-- search
                                          |
                                          ↓
                                   validate entire release
                                          |
                                          ↓
                                   activate entire release
```

The active Flutter catalog must always correspond to exactly one `releaseVersion` — never a mix of catalog files from different releases.

## 7. Cross-layer consistency

Supabase Tables and Supabase Storage must represent the same release at any given time. If a release is published to Storage but the corresponding table sync (`catalog.*` import, per V2-B1's pipeline) hasn't run yet — or vice versa — that is a **deployment inconsistency** to be explicitly flagged (e.g. in `admin.catalog_releases`/monitoring), not silently tolerated. The canonical release pipeline (§11) exists specifically to keep these in lockstep.

## 8. Rollback

- If a newly downloaded release fails validation (§ see `UPDATE_FLOW_SPECIFICATION.md`) or is later discovered to be defective, the Flutter client must be able to retain or revert to the previous valid local release.
- **Do not delete the previous local release until the new one has been successfully validated and activated.**
- Supabase Storage retains previous immutable releases per the retention policy, so a client (or an operator) can roll back to an earlier `releaseVersion` if a published release is later found to be bad.

## 9. Release version vs. schema version

These are independent and must not be conflated:

- **Release version** (`1.35.0 → 1.36.0`): a data-only catalog update. Downloadable and activatable **without an application rebuild**.
- **Schema version** (`1.0 → 2.0`): a contract-shape change the installed app may not understand. The Flutter client must **reject** an incompatible schema version rather than attempt to parse it (and must never crash on an unrecognized schema — see `UPDATE_FLOW_SPECIFICATION.md` §Failure Behaviour).

Example: `releaseVersion 1.35.0 → 1.36.0` with `schemaVersion 1.0 → 1.0` is a normal, transparent background update. `schemaVersion 1.0 → 2.0` at any `releaseVersion` requires a compatible app version to consume it.

## 10. Offline bundle (current state, do not disturb)

The Flutter application currently ships with a bundled release (`frontend/assets/catalog/catalog_bundle.json.gz` + `release.json`) as its initial offline baseline. **This document does not delete, replace, or otherwise modify that bundle.** It remains the shipped baseline until a future implementation phase wires the sync flow described here and validates it end-to-end. The bundled release is not to be treated as "the final new release" merely because it currently exists — it is the starting point the sync mechanism will eventually supersede via downloaded updates, once built.

## 11. Canonical release pipeline

```
Verified MSS catalog data
        ↓
Generate release package
        ↓
Validate all catalogs
        ↓
Validate relationships
        ↓
Validate localization
        ↓
Validate search
        ↓
Generate manifest
        ↓
Calculate SHA-256 hashes
        ↓
Create immutable release
        ↓
Publish to Supabase Storage
        ↓
Synchronize corresponding structured data to Supabase Tables
        ↓
Expose release metadata through the API
```

Both Storage and Tables must be updated together as part of publishing one release — see §7.

## 12. Relationship to existing artifacts

This corrects and extends, rather than replaces, prior work:

- `DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md` already establishes the source-of-truth hierarchy (verified release → offline app copy + Supabase copy) and proposed the `releaseId`/`perFileSha256` manifest fields — this document makes explicit that the "Supabase copy" side has two distinct parts (Tables for API, Storage for sync artifact), which the original spec did not separate.
- `admin.catalog_releases` / `admin.catalog_files` (created by migration `20260805000000_database_architecture_v2.sql`, populated for the first time in V2-B2) already have most of the right shape for tracking release identity (`id`, `schema_version`, `status`, `is_current`, `published_at` on `catalog_releases`; `file_name`, `checksum`, `byte_size`, `storage_path` on `catalog_files`). See `RELEASE_MANIFEST_SPECIFICATION.md` §4 for the specific field-level gap analysis (`storage_path` currently points at local filesystem paths, not a Storage bucket) and what remains to be built.
- `frontend/assets/catalog/release.json` (extended in V2-B2 with `releaseId` and `perFileSha256`) already carries most of the fields §5 requires — see `RELEASE_MANIFEST_SPECIFICATION.md` §3 for the exact mapping.
- `frontend/lib/services/scheme_catalog_sync_service.dart` (`SchemeCatalogSyncService`, `SupabaseCatalogReleaseSource`) already implements the shape of the update flow this document describes (throttle, fetch manifest, compare, download, install) — it currently points at a `public.catalog_releases` table from an earlier, now-architecturally-superseded schema (a "four-section JSON" format tied to `public.schemes` etc., created by `20260730090000_catalog_releases.sql`) that no longer exists in the live database. This document's job is to specify what it *should* point at instead; a future implementation phase adapts the existing service, not a new one — see `UPDATE_FLOW_SPECIFICATION.md` §6.

---

# Part 6: Update Flow State Machine & Storage Pointer Specification

# Update Flow Specification

> **Document status:** New specification, part of the offline/cloud sync architecture correction (see `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`).
> **Implementation status:** Documentation only. No Flutter/Dart code was modified producing this document. `frontend/lib/services/scheme_catalog_sync_service.dart` is described below exactly as it exists today, unmodified.

---

## 1. Flow

```
APP STARTS
    ↓
Read local release manifest
    ↓
Application continues using local catalog immediately
    ↓
Check cloud release metadata (lightweight -- see RELEASE_MANIFEST_SPECIFICATION.md §5)
    ↓
Compare local release/hash with cloud release/hash
    ↓
If identical:
    do nothing
    ↓
If newer release exists:
    ↓
download new release to TEMPORARY storage
    ↓
verify SHA-256
    ↓
verify manifest
    ↓
verify schema compatibility
    ↓
validate JSON structure
    ↓
validate IDs
    ↓
validate relationships
    ↓
validate localization
    ↓
validate search compatibility
    ↓
ONLY THEN activate new release
    ↓
delete old release after successful activation
```

The application is **never blocked** on the network check — it starts and serves the existing local catalog immediately, and the cloud check runs afterward (this matches the "no full-catalog download for a metadata check" principle in `RELEASE_MANIFEST_SPECIFICATION.md` §5, and the existing `unawaited(syncSchemeCatalog())` call pattern already present in `app_state_provider.dart`, described in §6).

## 2. Failure behaviour

If **any** step in the download/validation chain fails:

- hash mismatch
- corrupted download
- invalid JSON
- invalid manifest
- schema incompatibility
- relationship validation failure
- localization validation failure
- search-compatibility validation failure
- network interruption

**Do not replace the current local catalog.** Keep the currently active release. The application must remain fully usable offline regardless of what happened during the update attempt. A failed update is a no-op from the user's perspective — never a degraded or broken state.

## 3. Temporary storage requirement

The downloaded release must land in temporary storage first, and only move to the active location after every validation step in §1 passes. This is what makes §2's guarantee possible — the currently-active release is never touched until a full replacement is proven safe.

## 4. Rollback

Once a new release is activated, the previous release is not deleted immediately (see `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §8) — it is retained so the client can revert if the newly activated release is later found to be defective. Exact retention duration/count is not specified here; a future implementation should define this alongside the Storage-side retention policy so client and server sides agree on how far back rollback can reach.

## 5. Schema-version rejection, not crash

Per `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §9: if a cloud release's `schemaVersion` is incompatible with what the installed app understands, the client must **reject** that release (treat it the same as a failed validation, per §2) rather than attempt to parse it or crash. The app continues on its current local release until a compatible app update is installed.

## 6. Relationship to the existing `SchemeCatalogSyncService`

A working implementation of most of this flow **already exists** in the codebase and is already wired into the app's lifecycle — this specification describes what it should be doing, not something built from scratch:

- `frontend/lib/services/scheme_catalog_sync_service.dart` — `SchemeCatalogSyncService` already implements: in-flight de-duplication, a 15-minute throttle window, an 8-second timeout, manifest fetch, local-vs-remote comparison (`local?.id == remote.id && local?.sha256 == remote.sha256`), payload fetch, and install (`_store.install(remote, payload)`).
- `frontend/lib/providers/app_state_provider.dart` already calls `unawaited(syncSchemeCatalog())` both during `_loadState()` (app start, matching §1's "application continues using local catalog immediately, cloud check runs after") and on `AppLifecycleState.resumed` (matching a reasonable "check again when the app comes back to foreground" policy, not specified further here).
- `CatalogSyncResult`/`CatalogSyncOutcome` already models exactly the failure taxonomy §2 requires: `unchanged`, `updated`, `offline`, `incompatible`, `rejected`, `throttled` — `incompatible` already exists specifically for the schema-version rejection case in §5, and `offline`/`rejected` already exist for the network/validation-failure cases in §2.

**What is out of date**: `SchemeCatalogSyncService`'s `SupabaseCatalogReleaseSource.fetchCurrentManifest()`/`fetchPayload()` query a `public.catalog_releases` table (created by an earlier migration, `20260730090000_catalog_releases.sql`) tied to a now-superseded `public.schemes`-based "four-section JSON" catalog format. That table does not exist in the live database as of this document (confirmed empty/absent during this session's reconciliation work, independent of and prior to the `catalog.*` schema built in V2-B1 through V2-B5). This is why the sync check has been silently returning `CatalogSyncOutcome.offline` on every app run — not because of anything built this session, but because its data source predates and was superseded by the architecture documented here and in `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`.

**A future implementation phase should adapt `SupabaseCatalogReleaseSource`** to read from Supabase Storage (per `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §4) and `admin.catalog_releases`/`admin.catalog_files` (per `RELEASE_MANIFEST_SPECIFICATION.md` §4) instead of the old `public.catalog_releases` table — reusing the existing service's control flow (throttle, dedup, outcome modeling), not replacing it with a second, parallel sync mechanism. This document does not perform that adaptation; it specifies what the adaptation should target.

## 7. Validation steps, expanded

Per §1, "validate" is not one step but several, run in sequence after hash verification passes:

1. **Manifest verification** — the downloaded artifact's actual contents match what the manifest declared (record counts, file list).
2. **Schema compatibility** — `schemaVersion` is one this app build understands (§5).
3. **JSON structure validation** — every catalog file parses and matches the expected top-level shape (`{metadata, data}`).
4. **ID validation** — entity IDs are well-formed and internally consistent (no duplicate IDs within a catalog).
5. **Relationship validation** — cross-catalog references resolve (mirroring the existing `IntelligenceResolver.validate()` / `validate_cross_catalog.py` checks already run offline in the catalog pipeline).
6. **Localization validation** — localization blocks are structurally present where expected (not a content-correctness check — see `HASH_VERIFICATION_SPECIFICATION.md` §4 on the distinction between integrity and correctness).
7. **Search compatibility validation** — `search_index.json` (or equivalent) is present and internally consistent with the scheme catalog it indexes.

Any failure at any of these steps triggers §2's failure behaviour.

---

