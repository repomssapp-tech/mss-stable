# Flutter Integration Plan

**Planning only. No code is written here.** This sequences the work of
connecting the existing Flutter app to the MSS API, using this handoff
package. **No UI redesign. No layout changes. Only the data source
changes** -- every screen keeps its current visual design; only where
its data comes from changes.

---

## Architecture correction (2026-08-17) -- offline catalog sync

Add a phase (or fold into Phase 3/6) for offline catalog sync, scoped
per `architecture_docs/OFFLINE_CLOUD_SYNC_ARCHITECTURE.md`,
`architecture_docs/UPDATE_FLOW_SPECIFICATION.md`, and
`architecture_docs/RELEASE_MANIFEST_SPECIFICATION.md`. Two things worth
knowing before planning that phase:

1. **Do not build a new sync mechanism from scratch.**
   `frontend/lib/services/scheme_catalog_sync_service.dart`
   (`SchemeCatalogSyncService`) already implements the throttle/dedup/
   compare/download/install control flow this needs -- it is currently
   wired into `app_state_provider.dart`'s startup and app-resume paths.
   The work is **adapting** its `SupabaseCatalogReleaseSource` to read
   from Supabase Storage + `admin.catalog_releases`/`catalog_files`
   (per the architecture docs above), not writing a second, parallel
   sync path.
2. **The adaptation is currently blocked on infrastructure, not
   Flutter code.** `SupabaseCatalogReleaseSource` today queries a
   `public.catalog_releases` table from an earlier, now-superseded
   schema that no longer exists in the live database (see
   `UPDATE_FLOW_SPECIFICATION.md` §6 for the full history). Before this
   phase can be implemented, a Storage bucket + release-publish pipeline
   needs to exist per `OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` §4/§11 --
   that is out of scope for the Flutter integration plan itself.

---

## Phase 1 -- Create API Client

Build a thin HTTP client wrapping the endpoints in
`api_docs/API_ENDPOINT_REFERENCE.md`. One method per endpoint (search,
schemeDetail, eligibility, financeProducts, schemeFinance, clusters,
tax, privileges, relationships, localization, meta, health).

- Base URL, timeout, and retry policy are deployment decisions not made
  by this plan.
- Retry only on `CATALOG_UNAVAILABLE`/`INTERNAL_ERROR` (503/500), per
  `api_docs/ERROR_HANDLING_GUIDE.md`.
- On `CURSOR_STALE`, the client should surface this distinctly so
  calling code can restart pagination from page 1, not retry blindly.
- Every request that touches search/eligibility must include the
  `profile` object handling `PRIVACY_RULES.md` requires: never log the
  raw request body if it contains `profile`, at this layer or any layer
  above it.

**Definition of done:** one client method per live endpoint, each
returning either the parsed success `data` or a typed error matching
`api_docs/ERROR_HANDLING_GUIDE.md`'s code list.

## Phase 2 -- Create/Verify Models

`flutter_models/mss_contract.dart` already exists and already covers
most response shapes (see `MODEL_MAPPING_GUIDE.md`). This phase is
**mostly verification, not creation**:

1. Confirm each existing model's `fromJson` against a real response
   from Phase 1's client (start with `examples/*.json` in this package,
   which are real, live-generated responses, not hand-written samples).
2. Write the models `MODEL_MAPPING_GUIDE.md` identifies as missing
   (scheme-detail shape, cluster/tax/privilege shapes, relationships
   shape, localization shape, and a `meta` shape verified against the
   live `metadata()`/`meta()` output).
3. Resolve the `collateralStatus` vs. `collateral.status` naming
   mismatch noted in `MODEL_MAPPING_GUIDE.md` before wiring the
   finance-products endpoint specifically.

**Definition of done:** every endpoint's response can be parsed into a
typed Dart object with no manual `Map` access left in calling code.

## Phase 3 -- Replace Local Repository Layer

Wherever the current app reads scheme/finance/tax/cluster data from a
local source (bundled JSON, mock data, or a previous data layer),
replace that repository implementation's internals with calls through
Phase 1's client -- **keep the repository interface/method signatures
the app's UI layer already calls**, so no widget/screen code needs to
change. This is the core "only replace data source" principle.

**Two-source pattern for Scheme Details specifically** (see
`SCREEN_DATA_MAPPING.md`): the repository method backing this screen
must combine a `schemeDetail()` API call (relationship/confidence data)
with a lookup into the bundled `data/MSS_API_DATA_PACKAGE/scheme_catalog.json`
(descriptive content) -- from the UI's perspective this is still one
repository call returning one combined model; the two-source
composition is a repository-layer implementation detail.

**Definition of done:** the app's existing screens render real API data
through the unchanged repository interface, with no widget code touched.

## Phase 4 -- Connect State Management

Wire Phase 3's repository calls into whatever state-management approach
the app already uses (Provider/Riverpod/Bloc/etc. -- this plan does not
prescribe one; see `STATE_MANAGEMENT_GUIDE.md` for state-shape
considerations that apply regardless of the chosen framework).

Key states to model per screen: loading, loaded, empty-result
(0 matches -- not an error), error (network/`CATALOG_UNAVAILABLE`/
`INTERNAL_ERROR`), and the `INVALID_REQUEST`/`UNKNOWN_*` cases from
`ERROR_HANDLING_GUIDE.md`, which are "this specific thing is wrong,"
not generic failures.

**Definition of done:** every screen's existing UI can express all 5
states above without a layout change, sourced from Phase 3's repository.

## Phase 5 -- Localization

Wire the app's existing locale mechanism to pass `language`/`lang`
through Phase 1's client on every relevant call (see
`api_docs/LOCALIZATION_IMPLEMENTATION_GUIDE.md` for the exact field
names per endpoint -- they are **not** consistent across endpoints,
verified). Implement the field-level fallback rule (Rule 3 in that
guide) at the repository or model layer, once, rather than in every
widget.

**Definition of done:** switching the app's locale to Tamil changes
displayed content field-by-field with correct English fallback, with no
widget-level fallback logic duplicated across screens.

## Phase 6 -- Testing

- Contract tests: assert every rule in `API_CONTRACT.md` §15 holds
  against real API responses (not mocks) at least once.
- Golden-path tests per screen: Home, Search (English + Tamil query),
  Scheme Details (both data sources), Finance, Tax, Cluster.
- Explicit test for the `district`/bare-Tamil-keyword search gaps
  documented in `SEARCH_IMPLEMENTATION_GUIDE.md` -- confirm the app
  degrades gracefully (empty state, not a crash) rather than assuming
  every query returns results.
- Explicit test for `knowledge_catalog.json` body-text Tamil fallback
  (18/28 records) if the app surfaces knowledge-base content anywhere.

**Definition of done:** the test suite from this phase passes against
the real API (or a deployment of it), not just against mocked responses.

---

## What this plan does not cover

- AI Companion and Saved Schemes screens (see `SCREEN_DATA_MAPPING.md`
  -- no backing API for either; separate scoping needed).
- Choice of state-management framework, HTTP client library, or
  dependency-injection approach -- app-specific decisions this plan
  doesn't make.
- Any UI/UX change -- explicitly out of scope for this entire handoff.
