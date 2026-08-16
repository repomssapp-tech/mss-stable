# MSS Backend — Duplication Risk Report

**Generated:** 2026-08-16 · Full evidence lives in `BACKEND_PRE_B1_RECONCILIATION.md` — this document only states the risk and the specific redirect.

---

## Critical: the original roadmap would have silently redesigned already-correct, already-tested logic

The single biggest risk in the original B0-B11 plan was **B6 (Search Backend)**, **B7 (Recommendation Engine)**, and part of **B1 (API RC Stabilization)**. As written, each reads like a from-scratch design task ("Requirements: Input: `{query, language, profile, filters}` ... Output: `{results: [...]}`"). All three already exist, fully implemented and tested, in `Plan/catalog/`:

| Old roadmap phase | Would have rebuilt | Already exists as | Risk if rebuilt from scratch |
|---|---|---|---|
| B1 (endpoint audit + build) | Search/scheme/finance/tax/cluster/relationships/localization endpoint logic | `mss_api_rc1.py`, tested by `api_tests.py` (15 test functions) | Lower-quality reimplementation, loses "no ranking drift" structural guarantee (`api_tests.py`'s `test_no_ranking_drift` specifically asserts the RC1 wrapper never re-scores/re-sorts — a new implementation would need to reprove this) |
| B6 (Search Backend) | Semantic + keyword search, Tamil support, ranking explanation | `hybrid_search.py` with named Fix #1 (field weighting) and Fix #2 (corpus IDF), benchmarked at 80.2%/92.1% Top-1/Top-5 | Regression risk against a benchmark that took multiple fix rounds to reach (8 dated result snapshots on disk: BASELINE, FIX1, FIX2, D5_FIX3, ROUND3, etc. — this number didn't come easily) |
| B7 (Recommendation Engine) | Profile-based eligibility matching, "no AI hallucination, catalog-grounded only" | `IntelligenceResolver.match_applicability()` — deterministic, tri-state, already matches the exact "no hallucination" requirement | Duplicate design effort for a solved problem |
| B8 (Tamil Backend Intelligence, synonym examples) | கடன்→loan style synonym table | `ta_dictionary.py`'s `KEYWORDS_TA` (~110 terms) | Writing new synonyms without checking this first risks contradicting the existing (protected-terminology-aware) dictionary |

**The actual remaining work for all four is the same shape of task**: port working, tested Python into Deno/TypeScript Edge Functions, using `api_tests.py`'s existing assertions as the correctness oracle during the port — not redesign the logic. This is the same move already made once, successfully, for `/v1/meta` this session.

---

## Secondary duplication risks

**Import pipeline (old B5)**: a working, if simpler, importer already exists (`backend/scripts/generate_catalog_import_sql.js`, used successfully this session for 10/15 catalogs). The formal spec (`MSS_Catalog_Import_Specification_v1.0.md`) describes a more complete 18-step design (manifest, per-file checksums, `admin.import_batches` audit trail, rollback-on-failure) with no implementation. **Redirect**: extend the working script toward the spec's guarantees, don't write a second, parallel importer.

**Release manifest (old B2)**: `release.json` already has most of the proposed fields (`releaseTag`, `schemaVersion`, `bundleSha256`, `recordCounts`, etc.). Only `perFileSha256` and a `releaseId` are genuinely missing. **Redirect**: extend `tools/generate_catalog_bundle.py`'s output, don't design a new manifest schema.

**Rollback (old B1/implicit)**: `backend/docs/product/BACKEND_MLOPS_PRD.md` describes a full rollback system in detail — but it's for **ML model releases** (the voice/edge-AI subsystem), a completely different subsystem from catalog data. **Risk**: reading this PRD while planning catalog rollback could lead to importing irrelevant design decisions (or worse, colliding table/endpoint names) from a system that solves a different problem. **Redirect**: catalog rollback needs its own design; the PRD is not reusable here beyond general pattern inspiration.

**Tamil localization (old B8, translation-pass framing)**: the roadmap phrasing ("Backend handling: language=en / language=ta ... Missing → English fallback") implies localization work is still needed. The *data* is done (100% primary-field coverage, measured directly). What's actually missing is only the **serving layer** — an endpoint that reads the already-translated `localization.ta.*` fields and applies the fallback rule, which is itself already implemented and tested in `mss_api_rc1.py`'s `localization()` method. **Redirect**: this is an API-porting task (see the critical section above), not a translation task.

**`checkCatalogVersion` placeholder function**: the old roadmap's B1 example list implicitly suggested building version-checking from scratch. This session already built the equivalent (`/v1/meta`) using a different, arguably better approach (live-recompute vs. the placeholder's presumed static-check design). **Redirect**: `checkCatalogVersion` as a separate function is now redundant — either delete it or repurpose its name for something else in V2's plan, don't build out its original placeholder intent.

---

## What is genuinely new work (no prior implementation to duplicate)

- Porting any of the 8 tested-but-undeployed Python endpoints to Deno/TypeScript (execution work, not design work — see above).
- Importing the 5 missing catalog files into Supabase (schema needs new tables; no prior attempt exists).
- Populating `admin.catalog_releases`/`catalog_files` with a real release record (tables exist, never written to).
- Wiring `isStaleAgainst()` into an actual call site in `scheme_repository.dart` (the check logic exists; the trigger wiring does not — this is a small, real Flutter change, flagged separately since the roadmap says don't touch Flutter).
- Update download / atomic activation / catalog rollback (confirmed MISSING, no prior art in this codebase at all).
- Extending Tamil intent/semantic tagging beyond English (confirmed PARTIAL, a real open gap, not something to duplicate — something to extend).
- Reconciling the `public.profiles` permanent-sensitive-columns issue against the documented privacy rule.
- Getting a Python-capable environment to actually execute `api_tests.py` and the 5 validators for the first time in this reconciliation process (their pass/fail state is currently *claimed*, not independently *proven*, from this environment).
