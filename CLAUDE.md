# MSS App — Data Layer Integration: Handoff Brief

This file is a handoff brief for continuing the MSS catalog/API data-layer
integration in Claude Code, directly in this repo. It summarizes what's
already done, what's verified, what's still open, and hard constraints that
have applied throughout. A companion phase-by-phase log with full prompt/
result history lives at
`C:\Users\roger\OneDrive\Documents\Plan\ANTIGRAVITY_HANDOFF_SESSION_TRACKER.md`
if you need more detail than this summary — read it if you need the
blow-by-blow, but this file should be enough to keep working.

## Two separate workspaces — don't confuse them

- **`C:\Users\roger\OneDrive\Documents\Plan`** — the catalog-engineering
  workspace. Contains the original data-generation work: scheme
  verification batches, search benchmarks, localization reports, release
  audits, and its own copies of `MSS_API_DATA_PACKAGE/` and
  `MSS_API_INTEGRATION_PACKAGE/`.
- **This repo (`C:\development\MSS App\MSS_App`)** — the production Flutter
  app. Contains its own copy of the handoff package at
  `MSS_ANTIGRAVITY_HANDOFF/`.

**Important:** these two locations both have an `API_CONTRACT.md`, and they
are NOT the same content. `Plan/MSS_API_INTEGRATION_PACKAGE/API_CONTRACT.md`
is an **older, uncorrected draft** that still marks several endpoints
`[SPEC]`. The copy already in this repo at
`MSS_ANTIGRAVITY_HANDOFF/api_docs/API_CONTRACT.md` is the **corrected**
version — it explicitly documents that those endpoints were verified `[LIVE]`
against `mss_api_rc1.py` (119/119 tests passing). **Always use the docs
inside this repo's `MSS_ANTIGRAVITY_HANDOFF/`, not the `Plan/` workspace's
copies**, if the two ever seem to disagree.

The catalog *data* itself (`MSS_API_DATA_PACKAGE/*.json`) is verified
byte-identical between both locations (same `1.33.0-alpha` release,
checksums match) — no conflict there, just the docs.

## What's already done (Phases 1-6, verified)

All of this was built phase-by-phase via Antigravity (Gemini Flash), with
each phase's output checked before moving on. Constraints held throughout:
no UI/UX changes, no search-ranking changes, no new backend endpoints, no
Supabase tables/GraphQL created, no catalog source data altered.

1. **Investigation** — confirmed app conventions: models in flat
   `frontend/lib/models/`, `SchemeRepository` (singleton) at
   `frontend/lib/services/scheme_repository.dart` is the single class all
   screens call, `package:http` (no dio/chopper) is the HTTP convention.
2. **API client** — `frontend/lib/services/mss_api_client.dart`. All 15
   endpoints in `API_ENDPOINT_REFERENCE.md` mapped, returns raw JSON,
   matches the app's existing `http.Client` injection pattern. `flutter
   analyze` clean.
3. **Models** — `frontend/lib/models/mss_contract.dart` +
   `mss_models.dart` installed (moved from `test/flutter_models/`, which
   still holds the verification harnesses). 4 real-vs-fixture mismatches
   found and fixed (notably: `FinanceBenefit.collateral.status` is nested,
   not flat `collateralStatus`; `/v1/search` wraps results in a `data`
   envelope). `dart verify_contract.dart` 67/67,
   `verify_models.dart` 63/63.
4. **Repository wiring** — `SchemeRepository` now does online-first (via
   `MssApiClient`) with offline fallback (via `MssCatalogBundle` +
   `frontend/assets/catalog/catalog_bundle.json.gz`) for all 13 public
   methods, through `MssSchemeAdapter` (extended, not duplicated) into the
   existing UI-facing `Scheme` model. Public method signatures unchanged.
   Non-retryable errors (404/`UNKNOWN_SCHEME`) correctly return
   not-found instead of silently falling back. New test:
   `test/flutter_models/verify_repository.dart`, 17/17 passing (actually
   exercises offline-fallback, online-routing, and the 404 case with
   mocked HTTP, not just claimed).
5. **Cleanup** — full-project `flutter analyze`: 0 issues. Deleted 2
   confirmed-superseded docs (`backend/docs/api_docs.md`,
   `MSS_Supabase_Database_Architecture_v2.0.md`); everything else audited
   and correctly left alone.
6. **Dual-copy architecture spec (docs only, no implementation)** — wrote
   `MSS_ANTIGRAVITY_HANDOFF/architecture_docs/
   DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md` describing the
   offline-bundle + future-Supabase-copy architecture with hash
   verification. Did a **read-only** inspection of the real Supabase
   project (same one used for profiles/auth) — confirmed `catalog.*` and
   `admin.*` schemas, `public.sync_logs`, and any Storage buckets **do
   not exist yet** in the live project; only planned in a migration file
   not yet applied. No tables/rows were created — this was explicitly
   scoped as read-only.

## Two open issues found (not yet fixed — need a decision or fix)

### 1. The app is currently 100% offline in practice, silently

`MssApiClient.defaultBaseUrl` defaults to `http://localhost:8000`, only
overridable via `--dart-define=MSS_API_BASE_URL=...`. Grepped the whole
repo — that dart-define is set **nowhere** (no `.env`, no launch config, no
CI/build script). So every "online-first" call fails to connect (localhost
unreachable from any real device/emulator), is classified retryable, and
silently falls back to the offline bundle. No visible error — it just quietly
serves `catalog_bundle.json.gz` (969 entities/217 schemes) and the offline
`IntelligentSchemeSearch.rank()` scorer instead of the real API, always.
**Needs**: a real backend base URL from the user, and a decision on how to
configure it (dart-define in the release build command vs. an `.env`
loaded at startup vs. something else).

### 2. The offline bundle is missing 5 of 15 catalog files

`catalog_bundle.json.gz` only packages 11 of the 15 catalog files present in
`MSS_ANTIGRAVITY_HANDOFF/data/MSS_API_DATA_PACKAGE/`. Missing entirely:
`applicability_matrix_catalog.json` (219 records),
`enterprise_classification_catalog.json` (11),
`msme_privilege_catalog.json` (1), `business_enablement_catalog.json` (4),
`cluster_assistance_catalog.json` (10). Combined with issue #1, this means
`MssApiClient.getClusters()` / `getPrivileges()` and anything relying on
business-enablement or applicability-matrix data have **zero offline
fallback** — those UI surfaces show empty whenever the live API isn't
reachable, which today is always. Also: `manifest.json` says
`scheme_catalog.json` has 219 records; the bundle's `release.json` says 217
— a 2-record discrepancy not yet explained.
**Needs**: regenerate `catalog_bundle.json.gz` from the full 15-file
package (or decide those 5 catalogs don't need offline support), and
investigate the 217-vs-219 scheme gap.

## Genuinely not-yet-done (gap vs. a broader integration checklist)

A separate, more exhaustive integration checklist (data-integrity tests
across scheme/finance/tax/cluster reference resolution, a fixed list of
representative search queries in both `en`/`ta`, a real production build,
and a formal `MSS_API_FLUTTER_INTEGRATION_REPORT.md` deliverable) has NOT
been run yet. `verify_repository.dart` covers the core online/offline/
error-path logic but not that specific broader checklist. If picking this
up, treat it as the next real task — but skip re-doing Phases 1-6 above,
they're done and verified.

## Standing constraints (still apply to anything further)

- Do not modify UI/UX, layouts, spacing, typography, colors, navigation,
  or existing screens/cards unless technically required for integration —
  and if so, document exactly what and why.
- Do not implement a second search/ranking engine in Dart — the
  server-side search/resolver is authoritative; Flutter consumes its
  output.
- Do not re-translate catalog content in Flutter — Tamil localization
  already lives in the catalog data (`localization.ta` fields); consume it,
  don't regenerate it. Static UI strings (ARB files) are a separate system
  from dynamic catalog content — don't mix the two.
- Do not create Supabase tables/migrations/GraphQL unless explicitly
  authorized for that specific step (the dual-copy Supabase work is
  design-only so far, confirmed nothing exists live yet).
- Do not alter verified catalog source data to make integration easier.
- Preserve protected technical terms (GST, MSME, PMEGP, SIDBI, CGTMSE,
  TReDS, EMI, DPIIT, etc.) untranslated.
