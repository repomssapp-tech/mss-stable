# MSS Backend — Current State

**Generated:** 2026-08-16 · One-page answer to "what exists right now?" Full evidence in `BACKEND_PRE_B1_RECONCILIATION.md`; risk analysis in `BACKEND_DUPLICATION_RISK_REPORT.md`; forward plan in `BACKEND_EXECUTION_PLAN_V2.md`.

---

**Catalogs**: 15 source JSON files, 1216 entities total, tagged `1.33.0-alpha`, SHA-256-hashed individually (all 16 hashes recorded in `BACKEND_BASELINE_REPORT.md` §2, including `search_index.json`).

**Offline bundle**: works completely, end-to-end, today. `catalog_bundle.json.gz` + `release.json`, boot-time SHA-256 verified, 1216 entities, this is what the shipped Flutter app actually runs on. No dependency on anything below this line.

**Supabase**: schema deployed (`catalog.*` 11 data tables + `entity_registry`/`ai_metadata`, `admin.*` 15 tables, `public.profiles`/`notifications`/`startup_profiles`/`promo_alerts`). Data: 971/1216 entities imported (10 of 15 catalog files — `applicability_matrix`, `enterprise_classification`, `msme_privilege`, `business_enablement`, `cluster_assistance` are entirely missing, no table exists for them under any name). Release/version tables exist, 0 rows — `mss_catalog_meta()` live-recomputes instead.

**API**: 2 of ~11 documented routes are actually deployed and reachable (`/v1/meta`, `/v1/health`, both built this session). Every other route (`schemes`, `search`, `finance-products`, `tax`, `clusters`, `relationships`, `localization`, `privileges`) is fully implemented and tested **in Python** (`mss_api_rc1.py`, `api_tests.py`, claimed 119/119 passing, plausible but not independently re-run) but has never been deployed as an HTTP endpoint — Supabase Edge Functions run Deno/TypeScript, not Python, so this is a porting task, not a missing-feature task. 1 legacy function (`schemes-api`) is dead code querying tables the schema migration deleted, never deployed. 8 more functions are 17-line undeployed placeholders.

**Search**: `hybrid_search.py`, keyword+IDF (documented "Fix #2") + field-weighted (documented "Fix #1") ranking. Benchmarked **Top-1 80.2%, Top-5 92.1%** (210 queries, most recent run 2026-08-15T23:37) — this is the real non-regression floor going forward. A separate Dart port of the same engine exists for fully-offline client search, validated 210/210 against the Python original. Known real gap: Tamil semantic/intent tagging doesn't work (keyword matching does); confirmed by direct test in the handoff docs, not assumed.

**Recommendation/eligibility**: client-side (`recommendation_engine.dart`) fixed this session to use real structured-facet scoring, no server equivalent deployed. Server-side logic (`IntelligenceResolver.match_applicability()`) exists, tested, Python-only, unported.

**Localization**: 100% Tamil coverage on primary fields across all 10 Supabase-imported catalogs (measured directly, not estimated). One known gap: `knowledge_catalog.json.body`, 10/28 (35.7%). `ta_dictionary.py` (~359 terms) + `build_i18n.py` is the real, working translation pipeline. `LOCALIZATION_AUDIT.md` (MSS_App repo) is stale, reports the pre-fix state. `backend/catalog_ta_backfill/` is a smaller, superseded, self-marked-unapplied effort — not the source of truth.

**Resolver**: `intelligence_resolver.py`, fully implemented, used only by the offline Python layer, zero server-side references anywhere in `MSS_App/backend/`.

**Offline↔cloud sync**: server-side checksum detection works and was demonstrated end-to-end this session (edit in Supabase → `/v1/meta` checksum changed → reverted → checksum matched original exactly). Client-side, the equivalent check (`isStaleAgainst()`) exists but is never called — dead code. Download, atomic activation, and rollback do not exist anywhere in the codebase.

**Tests**: `api_tests.py` (15 functions, Python-layer only, claimed 119/119, not independently verified — no Python runtime in this environment). 5 catalog validators exist, unexecuted here for the same reason. `backend/supabase/tests/database/*.test.sql` (pgTAP, 3 files, 24 total assertions) — 2 of the 3 files reference tables the schema migration dropped (`public.schemes`, `scheme_documents`, `scheme_services`) and are now stale/broken. Flutter: `flutter analyze` clean, `flutter test` 141 passing / 4 pre-existing unrelated failures.

**Flutter boundary**: exactly one backend-motivated change made anywhere in Flutter this session — `MssApiClient.defaultBaseUrl` now points at the live `v1` Edge Function instead of `localhost:8000`. Everything else in `frontend/` is untouched by backend work.

**Known gaps, ranked by concreteness**:
1. 5 catalog files (245 entities) missing from Supabase — mechanical, low-risk to close.
2. Entire `/v1/*` query API undeployed — porting work, logic already correct.
3. Client-side sync trigger is dead code — small, real Flutter change needed, requires separate approval.
4. Download/atomic-activation/rollback don't exist at all — genuine new-build work.
5. `public.profiles` contradicts the documented privacy rule — a decision, not a bug fix.
6. Tamil semantic/intent search tagging doesn't work — known, tested, real quality gap.
7. Test/validator claims are unverified in this environment — need a Python runtime somewhere in the pipeline.
8. Two pgTAP test files are stale (reference dropped tables) — will fail if run as-is.
