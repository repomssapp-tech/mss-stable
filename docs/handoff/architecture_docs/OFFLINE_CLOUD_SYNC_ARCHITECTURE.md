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
