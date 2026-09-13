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

