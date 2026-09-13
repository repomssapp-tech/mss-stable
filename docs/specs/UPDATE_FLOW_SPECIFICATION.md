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
