# MSS Backend Execution Plan V2

**Generated:** 2026-08-16 · Supersedes the original B0-B11 roadmap · Built from the findings in `BACKEND_PRE_B1_RECONCILIATION.md` and `BACKEND_DUPLICATION_RISK_REPORT.md`, not from the original phase list.

**Governing principle, carried forward from the original roadmap and reinforced by this audit**: port and extend what already works (`mss_api_rc1.py`, `hybrid_search.py`, `intelligence_resolver.py`, `ta_dictionary.py`, `generate_catalog_import_sql.js`, `mss_catalog_meta()`). Do not redesign logic that is already implemented and tested. Every phase still requires validation + a report + a rollback path, per the original standing rules.

---

## Why this order, not B0-B11's order

The original roadmap assumed backend work starts from a design vacuum (hence B1 "endpoint audit," B6 "search backend," B7 "recommendation engine" as build-from-scratch phases, sequenced *after* B4/B5 Supabase work). The reconciliation found the opposite: **the hard design work is already done and tested in Python; the schema is already deployed; what's missing is almost entirely porting and wiring.** That changes the critical path:

1. Catalog parity has to come before anything else touches Supabase data, or later phases build against an incomplete mirror.
2. Release/manifest completion has to come before API porting, because the ported endpoints (`/v1/meta` especially) are supposed to reflect a real release, not an ad-hoc live-recompute forever.
3. API porting is one continuous body of work (same technique, same oracle, same target runtime) — splitting it by old-roadmap phase names (B1/B6/B7 as separate efforts) would just reintroduce the risk of drift between them. It's grouped here as one porting track, endpoint-by-endpoint.
4. Sync completion (download/atomic/rollback) depends on the release system from step 2 being real, not live-recomputed.
5. Privacy and validation are correctly independent — they can run in parallel with steps 3-4 rather than waiting.

---

## V2-B1 — Catalog Parity Closure
**Goal**: Supabase actually mirrors the 1216-entity offline bundle, not 971/1216.
**Depends on**: nothing (schema-additive only).
**Tasks**:
- Add 5 new tables to the `catalog` schema (migration, additive only — no drops): `applicability_matrix`, `enterprise_classification`, `msme_privilege`, `business_enablement`, `cluster_assistance`. Follow the existing hybrid pattern (`id`, `version`, `status`, `checksum`, `record_json` + a few denormalized columns per catalog, matching what `scheme`/`authority`/etc. already do).
- Extend `backend/scripts/generate_catalog_import_sql.js` to cover these 5 files.
- Import, verify counts (target: 1216 total across 15 files), verify `mss_catalog_meta()`'s `entityCounts` reflects all 15.
**Validation**: row counts match `release.json`'s `recordCounts` exactly for all 15 files.
**Rollback**: additive migration — drop the 5 new tables if needed, zero impact on the other 10.

## V2-B2 — Release Manifest Completion
**Goal**: a real, persisted release record replaces the current live-recompute-only approach; manifest gets the missing fields.
**Depends on**: V2-B1 (a release should reflect the complete catalog).
**Tasks**:
- Add `perFileSha256` (map) and `releaseId` (UUID) to `tools/generate_catalog_bundle.py`'s output and `release.json`.
- Populate `admin.catalog_releases` (one row, `status='published'`, `is_current=true`) and `admin.catalog_files` (one row per catalog file, with checksum + byte size) reflecting the current state.
- Decide and document: does `/v1/meta` keep using live-recompute (`mss_catalog_meta()`, simple, always-accurate, no publish step) or switch to reading the persisted release row (matches the original DUAL_COPY spec more closely, supports versioned rollback later)? **Recommendation**: keep live-recompute for `catalogChecksum`/`catalogVersion` (it's simpler and can't drift), but also persist release rows for audit/rollback history — the two aren't mutually exclusive.
**Validation**: `admin.catalog_releases` has exactly one current row; its checksum matches `mss_catalog_meta()`'s live output at the moment of publish.
**Rollback**: `admin.catalog_releases`/`catalog_files` are pure audit data — deleting rows has no effect on `catalog.*` itself.

## V2-B3 — API Port: Search & Scheme Detail
**Goal**: `GET /v1/schemes`, `GET /v1/schemes/{id}`, `POST /v1/search` become real, deployed Edge Functions.
**Depends on**: V2-B1 (needs complete data to search over — otherwise `applicability_matrix`-dependent results will be wrong).
**Tasks**:
- Port `hybrid_search.py`'s Fix #1 (field weighting) + Fix #2 (corpus IDF) scoring to TypeScript, reading from `catalog.*` tables (or from `record_json` if simpler to port field-for-field first, optimize later).
- Port `mss_api_rc1.py`'s `search()` wrapper behavior: filters, sorting, cursor pagination, `rankingSignals` component breakdown.
- Port scheme detail (`GET /v1/schemes/{id}`) using `IntelligenceResolver`'s merge logic.
- **Acceptance oracle**: for every query/response pair `api_tests.py` checks, the TypeScript port must produce the same result. Don't invent new test cases first — reproduce the existing ones.
**Validation**: benchmark rerun (see V2-B9) must not regress below Top-1 80.2% / Top-5 92.1%.
**Rollback**: new functions, additive — disable/undeploy if broken, `/v1/meta`/`/v1/health` unaffected.

## V2-B4 — API Port: Finance, Tax, Cluster, Relationships, Privileges, Localization
**Goal**: remaining documented `/v1/*` routes become real.
**Depends on**: V2-B1, can run in parallel with V2-B3 (different code paths, same porting technique).
**Tasks**: same porting technique per endpoint, using `intelligence_resolver.py`'s relationship-traversal logic and `mss_api_rc1.py`'s per-endpoint response shaping. Localization endpoint reuses the already-100%-complete `localization.ta.*` data — this is a thin serving layer, not new translation work.
**Validation**: same acceptance-oracle approach against `api_tests.py`.
**Rollback**: additive.

## V2-B5 — Recommendation / Eligibility Endpoint
**Goal**: `POST /v1/eligibility` becomes real, backed by the tested, hallucination-free facet-matching logic.
**Depends on**: V2-B1, V2-B3 (shares infrastructure/patterns with the search port).
**Tasks**: port `IntelligenceResolver.match_applicability()`. Apply the same "never fabricate, show real gaps honestly" discipline this session already enforced client-side in `recommendation_engine.dart` and `mss_scheme_adapter.dart` — this is a natural continuation of that principle into the backend.
**Validation**: cross-check against `api_tests.py`'s eligibility-related assertions.
**Rollback**: additive.

## V2-B6 — Offline↔Cloud Sync Completion
**Goal**: the currently-dead `isStaleAgainst()` check actually does something; downloads, atomic activation, and rollback get built.
**Depends on**: V2-B2 (needs a real release/manifest to compare against, not just a live checksum).
**Tasks** (staged, lowest-risk first):
1. Wire `isStaleAgainst()` into `scheme_repository.dart` at the point where `getMetadata()` is already called — start with detection + logging/telemetry only, no download yet. **This is a Flutter change** — flag explicitly for approval before touching, per the standing "don't touch Flutter" rule; this phase can be written and reviewed without being merged until approved.
2. Design and build update download: fetch a new bundle from Supabase Storage (needs a storage bucket — see the original DUAL_COPY spec's Phase 6 finding that 0 buckets exist today) or reconstruct from `catalog.*` query results.
3. Atomic activation: write-to-temp + verify-checksum + swap, never leaving the app with a partially-updated bundle.
4. Rollback: keep the previous verified bundle available until the new one is confirmed working; wire `rollbackRelease` for real (replacing its current placeholder).
**Validation**: simulate a Supabase-side edit (as demonstrated manually this session) and confirm the app actually picks it up end-to-end, not just that the checksum changes.
**Rollback**: this phase *is* the rollback mechanism — build it defensively, test the rollback path itself before shipping the forward path.

## V2-B7 — Privacy Reconciliation
**Goal**: resolve the contradiction between `STATE_MANAGEMENT_GUIDE.md`'s "never persist profile data server-side" rule and `public.profiles`'s actual permanent storage of gender/community/disability/veteran.
**Depends on**: nothing — can run in parallel with any of the above.
**Tasks**: decide (with the user) whether the documented rule or the deployed behavior is correct going forward; either update the schema (add opt-in gating, anonymization, or deletion-on-request) or update the documentation to match reality — don't leave them contradicting each other silently.
**Validation**: documentation and deployed schema agree.
**Rollback**: N/A, this is a decision + doc/schema alignment, not a risky migration.

## V2-B8 — Automated Backend Validation
**Goal**: stop relying on claimed-but-unverified test results.
**Depends on**: V2-B3/V2-B4 substantially complete (need something real to test).
**Tasks**:
- Get a Python-capable environment (this session's environment has none) and actually run `api_tests.py` (verify the claimed 119/119) and the 5 `validate_*.py` scripts for the first time in this reconciliation process.
- Add HTTP-level tests against the real deployed endpoints (something that doesn't exist yet at all — `api_tests.py` only tests the Python layer in-process).
- Wire the benchmark (`evaluate_benchmark.py` against `benchmark_v1.json`) as a regression gate: fail if Top-1 drops below 80.2% or Top-5 below 92.1%.
**Validation**: this phase's own output is the validation.
**Rollback**: N/A, test infrastructure only.

## V2-B9 — Production Release Packaging
**Goal**: the final handoff package.
**Depends on**: everything above.
**Tasks**: assemble `MSS_BACKEND_RELEASE/` (api/, schemas/, supabase/, migrations/, docs/, release/, validators/, examples/) per the original roadmap's B11 structure — that part of the original plan was fine, it's just now the last step instead of independent of everything else.

---

## Explicitly deferred / not in this plan

- Tamil semantic/intent-tagging extension (`detectedIntent` beyond English) — real, confirmed gap, but not blocking; schedule after V2-B4 if prioritized.
- `knowledge_catalog.json.body` Tamil gap (10/28) — a data task for `Plan/catalog`, not a backend-architecture task; independent of this plan.
- ML model release rollback (`BACKEND_MLOPS_PRD.md`) — different subsystem, not part of catalog backend work.
- The legacy `schemes-api` and 8 placeholder functions — recommend deleting `schemes-api` (dead, queries dropped tables) once V2-B3/B4 supersede it; the placeholders can be deleted or their names/routes repurposed during porting, whichever avoids the fewest merge conflicts at the time.
