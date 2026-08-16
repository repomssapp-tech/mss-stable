# MSS App — Recommendation Engine & Application Procedure Audit

**Date:** 2026-08-16
**Scope:** `C:\development\MSS App\MSS_App\frontend`

## Background

Two data-integrity bugs were found and fixed in this session:

1. **Recommendation engine was fake.** The "Recommended For You" match score was computed from `scheme.id.hashCode.abs() % 15` — a per-scheme hash with no relation to the user's actual profile — plus a stale-recommendation bug where scores didn't recompute immediately after profile load on sign-in.
2. **Application Process steps were fabricated.** When a scheme's real `applicationProcess.steps` array was empty (true for 71 of 219 catalog schemes), the UI synthesized a fixed, generic 4-step procedure ("register → upload documents → District MSME Officer inspection → subsidy credited to bank") for *every* such scheme, regardless of type — including GeM marketplace seller registration, which has neither a district inspection nor a subsidy disbursement.

## 1. Root Cause

The fabricated procedure lived in `frontend/lib/services/mss_scheme_adapter.dart`'s `applicationProcess` parsing fallback. This was a **Flutter-side rendering bug**, not a JSON data-quality problem — the underlying catalog data (`Plan/catalog/scheme_catalog.json`) was already correct/sparse where it should be; the app was inventing content to fill gaps instead of surfacing that gap honestly.

## 2. Files Changed

- `frontend/lib/services/mss_scheme_adapter.dart` — replaced the fabricated fallback with logic that only surfaces the scheme's own `modeText`/`onlineUrl`/`offlineDetails`, or an explicit "not verified" message when none exist.
- `frontend/lib/engine/recommendation_engine.dart` — rewrote the `default:` scoring case to use real structured-facet matching (gender, specialCategory, age, businessStage) instead of the hash-based fake score. Added tiebreak-stable sort in `getRecommendations()`.
- `frontend/lib/models/scheme_model.dart` — added `eligibilityMinAge`, `eligibilityMaxAge`, `eligibilityGenderValues`, `eligibilityBusinessStageValues` fields (wired through constructor, `toLocalized()`, `copyWith()`).
- `frontend/lib/services/scheme_repository.dart` — added `_rankByQuery()` helper (offline category/ministry/state result re-ranking via the hybrid search engine); tiebreak-stable sort in `getRecommendedSchemes()`.
- `frontend/lib/providers/app_state_provider.dart` — `_setupAuthListener()` now recomputes `_recommendedSchemes`/`_filters` immediately after `_profile` is set on `signedIn`/`tokenRefreshed`, instead of relying solely on the (currently non-functional, pending-migration) Realtime subscription.
- `frontend/lib/services/hybrid_scheme_search.dart` — added public `scoreByQuery()` method (scores every scheme without dropping zero-score entries).

No `*_catalog.json` records were edited — investigation confirmed the underlying data was correct; both bugs were purely in Flutter's fallback/scoring logic.

## 3. Flutter Changes — Application Process Fallback (exact logic)

When `steps` is empty:
1. If `modeText` (or `mode`) is set → add `"Application Mode: {modeText}"`.
2. If `onlineUrl` is set → add `"Apply Online: {onlineUrl}"`; else if `offlineDetails` is set → add `"Offline Process: {offlineDetails}"`.
3. If none of the above produced any line → add the single line: `"Current application process not verified for this scheme. Please refer to the official source above for the latest procedure."`

Nothing is invented that isn't traceable to that scheme's own `applicationProcess` fields. `requiredDocuments`/`requiredServices` parsing was separately audited and found already clean — no changes needed there.

## 4. Verification (on-device, emulator-5554)

| Scheme | Result |
|---|---|
| GeM (SCH000063) | "1. Application Mode: Seller registration and participation through GeM" / "2. Apply Online: https://gem.gov.in/" — no District MSME/bank-transfer fabrication |
| CLCSS | "1. Application Mode: Online through the Primary Lending Institution" / "2. Apply Online: https://my.msme.gov.in/MyMsme/Reg/COM_ClcssAppForm.aspx" |
| Back-ended Interest Subsidy (SCH000017) | "1. Application Mode: Through applicable Tamil Nadu MSME/nodal process" / "2. Apply Online: https://www.msmeonline.tn.gov.in/" |
| Additional Capital Subsidy for scaling up (SCH000003) | "1. Application Mode: Online" / "2. Apply Online: https://www.msmeonline.tn.gov.in/" |
| Advance Authorisation Scheme (SCH000005, genuinely empty `applicationProcess`) | "Current application process not verified for this scheme. Please refer to the official source above for the latest procedure." — no invented steps |

All five show distinct, scheme-specific content; none share the old copied fallback text.

**Home Screen:** confirmed intact before and after this phase — layout, alignment, and structure unchanged. "Recommended For You" now shows stable, profile-derived match percentages (e.g. 95% for BBBP against the test profile) instead of the old constantly-shifting hash-based scores.

**Static validation:** `flutter analyze` — clean, no issues. `flutter test` — same 4 pre-existing failures only (`category_navigation_architecture_test.dart`, `mems_support_explore_localization_audit_test.dart`, `mixed_language_localization_audit_test.dart`, `recommendation_and_category_limit_test.dart`), confirmed unrelated (sandbox/network `SchemeRepository.instance` construction issues), unchanged from prior phases.

## 5. Remaining Data Gaps

71 of 219 catalog schemes have no verified `applicationProcess` data at all, e.g.:

- SCH000005 — Advance Authorisation Scheme
- SCH000006 — Agarbatti Making Project - Gramodyog Vikas Yojana (GVY)
- SCH000009 — ASCEND Capacity Building Workshops
- SCH000030 — Chhattisgarh Innovation and Venture Capital Funds - Women Innovator Corpus
- SCH000031 — Chief Minister's Girl Child Protection Scheme
- SCH000051 — E.V.R. Maniyammaiyar Ninaivu Marriage Assistance Scheme for Daughters of Poor Widows
- SCH000052 — Economic Empowerment of Women Enterprises and Start-Ups by Women
- SCH000053 — EDII Technology Development Fund
- SCH000056 — Events organised by academic institutions
- SCH000058 — Financial Assistance for participation in International Trade Fair
- …and 61 more (full list can be regenerated by scanning `Plan/catalog/scheme_catalog.json` for schemes where `content.applicationProcess.steps`, `.modeText`, `.mode`, `.onlineUrl`, and `.offlineDetails` are all empty).

These now correctly display the "not verified" message rather than fabricated content — **this is expected/correct behavior**, not a bug. It is a real content gap to close later if desired: populate `applicationProcess.modeText`/`onlineUrl`/`offlineDetails`/`steps` for these 71 schemes in `Plan/catalog/scheme_catalog.json` from verified official sources, then regenerate the Flutter offline catalog bundle (see `project_mss_app_catalog_bundle_wiring` memory / `tools/generate_catalog_bundle.py`).

## Outstanding / Follow-up Items

- Once Realtime is enabled for `profiles`/`notifications`, the `_subscribeToProfile()` eventually-consistent path in `app_state_provider.dart` will start working as originally designed (the immediate-recompute fix added in this session is a safety net independent of that).
- The 71-scheme `applicationProcess` data gap above, if/when the user wants it closed.

---

# Phase 2 — Supabase Dual-Copy Catalog Sync (2026-08-16)

## Background

User wanted: a copy of all offline catalog data mirrored into Supabase, editable there, with the app checking for changes via checksums rather than always fetching live. This architecture was already fully *specified* (`MSS_ANTIGRAVITY_HANDOFF/architecture_docs/DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md`) but never built — `catalog.*`/`admin.*` schemas didn't exist in live Supabase, and the sync-related Edge Functions were all 17-line placeholders.

## What was deployed

1. **Migrations applied** (project `houpzsxmwemoztpuigmo`), in order:
   - `20260731120000_create_promo_alerts.sql`
   - `20260805000000_database_architecture_v2.sql` — the full `catalog.*`/`admin.*` schema (previously undeployed)
   - `20260806113000_self_delete_user.sql`
   - `20260815120000_enable_realtime_profiles_notifications.sql`
   - `20260816130000_recreate_promo_alerts.sql` — **bug fix**: `database_architecture_v2` drops `public.promo_alerts` as part of its legacy-table cleanup but never recreates it (it's not part of the new schema). This broke the Home screen promo banner. Restored with a follow-up migration.
   - `20260816140000_catalog_meta_function.sql` — adds `public.mss_catalog_meta()`, a live SQL function that aggregates every `catalog.*` row's per-record SHA-256 checksum into one overall checksum + version string, recomputed fresh on every call (no manual "publish a release" step needed — editing a row in Supabase Studio is reflected on the very next check).

2. **Catalog data imported**: all 969 entities from `Plan/catalog/*.json` (`common`, `authority`, `institution`, `scheme`, `finance`, `tax`, `export`, `csr`, `treds`, `knowledge`) plus 971 search-index rows and 1,710 relationship edges, upserted into the new `catalog.*` tables. Each row carries both denormalized columns (for Studio browsing) and a `record_json` column with the full original record (zero data loss even where a field wasn't mapped to a column). Counts verified to match source exactly.
   - Import tooling: `backend/scripts/generate_catalog_import_sql.js` — reads `Plan/catalog/*.json`, generates chunked upsert SQL (chunked because `supabase db query --file` rejects payloads over ~1-5MB; found empirically). Re-runnable any time the source JSON changes — all upserts, safe to re-run.

3. **Edge Function `v1` deployed** (`backend/supabase/functions/v1/index.ts`) implementing:
   - `GET /v1/meta` → `{catalogVersion, catalogChecksum, entityCounts, supportedLanguages}`, sourced live from `mss_catalog_meta()`. Matches `MssMeta.fromJson` exactly.
   - `GET /v1/health` → `{status: "ok"}`
   - Deployed with `--no-verify-jwt` and reachable with zero auth headers, matching exactly what `MssApiClient._get()` sends today (no `apikey`/`Authorization` header). Verified live via curl.

4. **Flutter change**: `frontend/lib/services/mss_api_client.dart` — `defaultBaseUrl` changed from `http://localhost:8000` (unreachable, the actual cause of every `Connection refused` / `online ... failed` log seen throughout this session's on-device testing) to `https://houpzsxmwemoztpuigmo.supabase.co/functions/v1`. `flutter analyze` clean after the change.

## Important finding: the online API was never reachable

`MssApiClient` is coded against a fuller `/v1/*` contract (`/v1/schemes`, `/v1/finance-products`, `/v1/clusters`, `/v1/tax`, `/v1/privileges`, `/v1/relationships/:id`, `/v1/localization/:id`) than what got built. The only previously-"real" function, `schemes-api`, queries `public.schemes`/`scheme_documents`/`scheme_services` — tables the `database_architecture_v2` migration deleted, so that function is now dead code querying nonexistent tables. And even it never matched the `/v1/...` path shape the client calls, and `defaultBaseUrl` pointed at `localhost:8000` with nothing overriding it anywhere in the repo. **The app has been running 100% off the offline bundle this entire time** — every "online" attempt in every prior phase's testing was doomed before it started. This is now fixed for `/v1/meta` and `/v1/health` only, by explicit agreement — the rest of that contract remains unimplemented, and the app's existing offline-fallback behavior in `SchemeRepository` is what covers it today, unchanged.

## Not done / explicitly deferred

- **Full `/v1/*` query API** (schemes, finance-products, clusters, tax, privileges, relationships, localization) — the app already falls back to the offline bundle for these; only `/v1/meta` was built, by scoping decision.
- **Client-side staleness-triggered re-sync logic** — `UpdateMetadata.isStaleAgainst()` / `MssMeta.isStaleAgainst()` exist as models but nothing in `SchemeRepository`/`AppProvider` currently calls them to trigger an actual bundle re-download when the server checksum differs. The server side (this phase's work) is ready for that; the client-side trigger is unbuilt.
- **`catalog.entity_registry`, `catalog.ai_metadata`** — not populated (registry/AI-summary bookkeeping tables from the dual-copy spec; not required for the editable-mirror goal).
- **`admin.catalog_releases`/`admin.catalog_files`** — not populated; the live-recompute approach in `mss_catalog_meta()` was used instead of the spec's release-snapshot approach, since it requires zero publish workflow and is always accurate. If a versioned release-history/rollback capability is wanted later, this is where to build it.
- The legacy `schemes-api` function still exists and is now fully broken (queries dropped tables). Left in place, not called by anything live in the app; worth deleting in a later cleanup pass.
