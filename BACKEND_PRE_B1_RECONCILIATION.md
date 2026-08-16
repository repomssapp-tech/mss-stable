# MSS Backend — Pre-B1 Historical Reconciliation

**Generated:** 2026-08-16 · **Scope:** read-only audit · **No code, schema, data, or docs were modified producing this.**

This is the canonical evidence document. `BACKEND_DUPLICATION_RISK_REPORT.md`, `BACKEND_EXECUTION_PLAN_V2.md`, and `BACKEND_CURRENT_STATE.md` all reference the matrix and findings here rather than repeating them.

---

## The one finding that reframes everything

**"[LIVE]" in the `MSS_ANTIGRAVITY_HANDOFF/` docs does not mean "deployed and reachable over HTTP."** It means "implemented in `mss_api_rc1.py` and passing in `api_tests.py` (local Python test run)."

Verified directly: `mss_api_rc1.py`'s own docstring says *"Transport-agnostic: returns plain dicts, imports no web framework, binds no port."* It subclasses `mss_api.py`'s `MssApi`, which likewise states *"binds no port."* Neither is, or has ever been, an HTTP server. `api_tests.py` is a real 456-line test harness with 15 test functions (`test_valid_search`, `test_filters`, `test_pagination`, `test_stale_cursor`, `test_resolver_traversal`, `test_financial_assistance`, `test_cluster_tax_privilege`, `test_localization`, `test_determinism`, `test_error_handling`, etc.) — genuine, specific, and its claimed numbers cross-check against independently-observed facts (e.g. its "1710 edges, 0 asymmetric" claim for `validate_cross_catalog.py` exactly matches the 1710-row count found in the live `catalog.relationships` Supabase table, imported independently this session from the same source data). There is no reason to doubt the "119/119 passing" claim for what it actually tests: the Python functions, called in-process.

**What this means for B1**: the API's business logic (search ranking, eligibility matching, finance/tax/cluster/relationships/localization responses, pagination, filtering, error codes) is already fully designed, implemented, and tested — in Python, un-deployed. B1 is not "design and build the API." B1 is **"port the already-correct, already-tested Python logic into Deno/TypeScript Edge Functions"** (Supabase Edge Functions cannot run Python), the same move already made once this session for `/v1/meta`. Redesigning the ranking/eligibility/pagination logic from scratch would be pure duplicated, lower-quality work.

---

## Completed-Work Matrix

| Capability | Existing Implementation | Location | Status | Do Again? |
|---|---|---|---|---|
| Supabase `catalog.*`/`admin.*` schema | Full schema (11 data tables + entity_registry + ai_metadata in `catalog`; 15 tables in `admin`) | `backend/supabase/migrations/20260805000000_database_architecture_v2.sql`, deployed this session | **DEPLOYED** | No |
| Supabase catalog data | 971/1216 entities imported (10 of 15 catalog files) | `catalog.common/authority/institution/scheme/finance/tax/export/csr/treds/knowledge`, live | **PARTIAL** | Extend, don't redo — see §Missing Catalogs |
| Release/version metadata (`admin.catalog_releases`, `admin.catalog_files`) | Tables exist, schema-ready, **0 rows** | Supabase `admin` schema | **MISSING** (schema present, unpopulated) | Populate, schema is fine |
| `GET /v1/meta` | Live Edge Function, checksum-aggregated | `backend/supabase/functions/v1/index.ts`, deployed this session | **DONE** | No |
| `GET /v1/health` | Live Edge Function | same file | **DONE** | No |
| `GET /v1/schemes`, `GET /v1/schemes/{id}` | Fully implemented + tested in Python (`test_missing_entity`, `test_resolver_traversal`) | `Plan/catalog/mss_api_rc1.py`, `mss_api.py` | **SOURCE_ONLY** (0/219 HTTP-reachable) | **No — port existing logic** |
| `POST /v1/search` | Fully implemented (`hybrid_search.py` Fix#1 field-weighting + Fix#2 corpus IDF) + tested (`test_valid_search`, `test_empty_search`, `test_filters`, `test_pagination`, `test_stale_cursor`, `test_sorting`, `test_no_ranking_drift`, `test_determinism`) | `Plan/catalog/hybrid_search.py`, `mss_api_rc1.py` | **SOURCE_ONLY** | **No — port existing logic** |
| `GET /v1/finance-products[/{id}]`, `/v1/schemes/{id}/finance` | Implemented + tested (`test_financial_assistance`) | `mss_api_rc1.py` | **SOURCE_ONLY** | **No — port existing logic** |
| `GET /v1/tax[/{id}]`, `/v1/clusters[/{id}]`, `/v1/privileges[/{id}]` | Implemented + tested (`test_cluster_tax_privilege`) | `mss_api_rc1.py` | **SOURCE_ONLY** | **No — port existing logic** |
| `GET /v1/relationships/{id}` | Implemented + tested (`test_resolver_traversal`); 1710 edges / 0 dangling, cross-verified against live Supabase `catalog.relationships` row count | `mss_api_rc1.py`, `intelligence_resolver.py` | **SOURCE_ONLY** | **No — port existing logic** |
| `GET /v1/localization/{id}` | Implemented + tested (`test_localization`) | `mss_api_rc1.py` | **SOURCE_ONLY** | **No — port existing logic** |
| Legacy `schemes-api` Deno function | Queries `public.schemes`/`scheme_documents`/`scheme_services` — all dropped by the v2 migration | `backend/supabase/functions/schemes-api/index.ts` | **SOURCE_ONLY, DEAD** (never deployed; would be dead code even if deployed) | No — delete in cleanup, don't extend |
| 8 placeholder Edge Functions (`buildCatalog`, `checkCatalogVersion`, `downloadCatalog`, `exportCatalog`, `generateManifest`, `publishCatalog`, `rollbackRelease`, `validateCatalog`) | 17-line stub returning a placeholder message each | `backend/supabase/functions/*/index.ts` | **SOURCE_ONLY** | Repurpose names/intent where they match V2 phases, don't design from scratch |
| Recommendation / eligibility engine (server-side) | `IntelligenceResolver.match_applicability()` — deterministic tri-state facet matching, tested; contract-documented as `POST /v1/eligibility` | `intelligence_resolver.py` | **SOURCE_ONLY** | **No — port existing logic** |
| Recommendation engine (Flutter client-side) | Real structured-facet scoring (this session replaced a hash-based fake score) | `frontend/lib/engine/recommendation_engine.dart` | **DONE** (client-side only, no server equivalent deployed) | No |
| Search backend (deployed service) | None | — | **MISSING** | Build via porting `hybrid_search.py`, not redesigning |
| Tamil search (data layer) | 100% primary-field coverage across all 10 Supabase-imported catalogs (measured directly); ~99% across 13-15 per handoff docs, one known gap: `knowledge_catalog.json.body` 10/28 (35.7%) | `Plan/catalog/*_catalog.json` via `ta_dictionary.py` + `build_i18n.py` pipeline | **DONE** (data) | No |
| Tamil search (query/ranking layer) | Keyword+IDF matching works in Tamil; semantic/intent tagging (`detectedIntent`) confirmed **English-only** by direct test in `SEARCH_IMPLEMENTATION_GUIDE.md` — a real, currently-open quality gap, not a documentation error | `hybrid_search.py` | **PARTIAL** (known, tested limitation) | Extend intent-tagging to Tamil; don't rebuild keyword layer |
| Tamil search synonyms (roadmap's example: கடன்→loan) | `ta_dictionary.py`'s `KEYWORDS_TA` (~110 terms) already exists | `Plan/catalog/ta_dictionary.py` | **PARTIAL** | Audit coverage gaps against real query logs before writing anything new — don't duplicate |
| Import pipeline (formal spec) | 18-step transactional design (manifest→checksum→validate→import→audit) | `MSS_Catalog_Import_Specification_v1.0.md` | **DOCUMENTED_ONLY** — no implementing script found anywhere | Build for real, following this spec |
| Import pipeline (working, ad-hoc) | Chunked upsert SQL generator, used successfully this session for 10/15 catalogs | `backend/scripts/generate_catalog_import_sql.js` | **PARTIAL** (works, but no manifest/checksum-manifest/audit-trail/rollback) | Extend this, don't replace it |
| Release manifest generation (offline) | `release.json` with `bundleSha256`, `recordCounts`, etc. | `tools/generate_catalog_bundle.py`, `frontend/assets/catalog/release.json` | **DONE** | No |
| Release manifest — `perFileSha256` field | Proposed in spec, not implemented | `DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md` §3 | **DOCUMENTED_ONLY** | Add the field + generator logic |
| SHA-256 generation (offline bundle) | `bundleSha256` over compressed asset, verified at Flutter boot | `mss_catalog_bundle.dart` | **DONE** | No |
| SHA-256 generation (Supabase, per-row) | `checksum` column populated on every imported row | `catalog.*` tables | **DONE** | No |
| SHA-256 generation (Supabase, live aggregate) | `public.mss_catalog_meta()` — recomputes on every call | Supabase, deployed this session | **DONE** | No |
| Offline manifest | `release.json`, loaded and verified at boot | `frontend/assets/catalog/release.json` | **DONE** | No |
| Offline bundle | 1216 entities, gzip+checksum, actively used by the shipped app | `frontend/assets/catalog/catalog_bundle.json.gz` | **DONE** | No |
| Update detection (server side) | `/v1/meta` live, checksum changes on real edits — demonstrated end-to-end this session (edit → checksum changed → reverted → checksum matched original) | Supabase `v1` function | **DONE** | No |
| Update detection (client side) | `isStaleAgainst()` exists on `UpdateMetadata`/`MssMeta` models, **zero call sites** anywhere in `scheme_repository.dart` — dead code | `frontend/lib/models/mss_contract.dart:854`, `mss_models.dart:579` | **PARTIAL** (method exists, never invoked) | Wire it up, logic itself is fine |
| Update download | No code path re-downloads the bundle anywhere | — | **MISSING** | Build |
| Atomic update / activation | No fields or methods exist for this on any model | — | **MISSING** | Build |
| Rollback (catalog/release) | `rollbackRelease` Edge Function is an unwired 17-line placeholder | `backend/supabase/functions/rollbackRelease/index.ts` | **SOURCE_ONLY** | Build for real |
| Rollback (unrelated ML model releases) | Full PRD describing `POST /v1/admin/model-releases/{id}/rollback` — **different subsystem** (voice/edge-AI model versioning, not catalog data) | `backend/docs/product/BACKEND_MLOPS_PRD.md` | **DOCUMENTED_ONLY, OUT OF SCOPE** | Not relevant to catalog rollback — don't conflate |
| API tests | 15 test functions, real assertions, plausible 119/119 pass claim (not independently re-run — no Python runtime here) | `Plan/catalog/api_tests.py` | **SOURCE_ONLY / tests the Python layer, not any deployed endpoint** | Reuse as acceptance oracle when porting to TS |
| Catalog validators | 5 scripts exist (`validate_base.py`, `validate_catalog.py`, `validate_cross_catalog.py`, `validate_i18n.py`, `validate_provenance.py`) | `Plan/catalog/` | **SOURCE_ONLY** (not executed in this environment — no Python) | No — get a Python-capable environment and run them, don't rewrite |
| `IntelligenceResolver` | Fully implemented, used by `mss_api.py`/`hybrid_search.py`/`app_response.py`; **zero references anywhere in `MSS_App/backend/`** | `Plan/catalog/intelligence_resolver.py` | **SOURCE_ONLY** | **No — port existing logic** |
| Privacy rules (documented) | "Profile object must never be persisted or logged server-side" | `flutter_docs/STATE_MANAGEMENT_GUIDE.md` | **DOCUMENTED_ONLY** | — |
| Privacy rules (actual deployed behavior) | `public.profiles` permanently stores `gender`, `community`, `disability`, `veteran` with no opt-in gate | Supabase, live | **CONTRADICTS the documented rule** | Reconcile in B9-equivalent phase |

### Missing Catalogs — explicit determination (Section 3 of the audit spec)

Checked directly against `information_schema.tables` for `catalog`/`admin` schemas — no table under any name corresponds to these five:

| Catalog | Entities (offline bundle) | Supabase status |
|---|---:|---|
| `applicability_matrix_catalog.json` | 219 | **MISSING** — no table under any name |
| `enterprise_classification_catalog.json` | 11 | **MISSING** |
| `msme_privilege_catalog.json` | 1 | **MISSING** |
| `business_enablement_catalog.json` | 4 | **MISSING** |
| `cluster_assistance_catalog.json` | 10 | **MISSING** |

None are "present under a different name" — the `catalog` schema has exactly the 11 tables listed in the matrix above and nothing else.

---

## API Reality Classification (Section 4)

| Endpoint | SOURCE_EXISTS | DEPLOYED | FUNCTIONAL | TESTED | DOCUMENTED |
|---|:---:|:---:|:---:|:---:|:---:|
| `/v1/meta` | ✅ | ✅ | ✅ | ✅ (live curl, this session) | ✅ |
| `/v1/health` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/v1/schemes`, `/v1/schemes/{id}` | ✅ (Python) | ❌ | N/A (not reachable) | ✅ (Python, `api_tests.py`) | ✅ |
| `/v1/search` | ✅ (Python) | ❌ | N/A | ✅ (Python) | ✅ |
| `/v1/finance-products[/{id}]` | ✅ (Python) | ❌ | N/A | ✅ (Python) | ✅ |
| `/v1/tax` | ✅ (Python) | ❌ | N/A | ✅ (Python) | ✅ |
| `/v1/clusters` | ✅ (Python) | ❌ | N/A | ✅ (Python) | ✅ |
| `/v1/relationships` | ✅ (Python) | ❌ | N/A | ✅ (Python) | ✅ |
| `/v1/localization` | ✅ (Python) | ❌ | N/A | ✅ (Python) | ✅ |
| `/v1/privileges` | ✅ (Python) | ❌ | N/A | ✅ (Python) | ✅ |

"SOURCE_EXISTS" for these 8 rows means the Python reference implementation and its tests — never a TypeScript/Deno source file, since none exists.

---

## Search Work (Section 5)

- **Ranking implementation**: `hybrid_search.py`, keyword (IDF-weighted) + semantic/tag matching, deterministic scoring (`Σ(rankingSignals.components[k] × weights[k])`).
- **Fix #1** (confirmed in code, `hybrid_search.py:182`): field weighting, unchanged since introduction.
- **Fix #2** (confirmed in code, `hybrid_search.py:85`): corpus IDF / term-rarity weighting — smoothed IDF `ln((N+1)/(df+1))+1`.
- **Benchmark**: `Plan/catalog/benchmark_v1_results.json`, most recent run **2026-08-15T23:37**. **Top-1 relevance 80.2%, Top-5 recall 92.1%** (210 queries, 177 scored, 29 data-gap, 4 unscored). Treat this artifact, not the roadmap's rounded numbers, as authoritative.
- **Tamil search limitation**: keyword/IDF matching works in Tamil; `detectedIntent` (industries/benefits/communities/intents semantic tagging) is confirmed English-only by direct test against 3-4 real Tamil queries in `SEARCH_IMPLEMENTATION_GUIDE.md`. This is a genuine, currently-open quality gap.
- **Search index version/hash**: `search_index.json` SHA-256 `5fb4d8213a041928497179367d018e33acd8a6aba441d08af23227e633d32eee`, 971 records, imported into `catalog.search_index` this session.
- A **separate Dart port** of this same search engine exists and is validated 210/210 against the Python original, for fully-offline in-app search (prior session, see `project_mss_app_search_engine_port` memory) — this is the client-side equivalent of the same logic, already working, unrelated to the backend porting task above.

---

## Localization (Section 6)

- **Coverage** (measured directly against live JSON, primary field per catalog): all 10 Supabase-imported catalogs are **100%** Tamil-complete at the primary name/label/title field. `knowledge_catalog.json`'s secondary `body` field is 10/28 (35.7%) — the one real, documented gap.
- **Terminology dictionary**: `ta_dictionary.py`, ~359 distinct terms across `ACRONYMS` (58, never-translated), `TERMS` (~250), `STATES_TA`, `DISTRICTS_TA`, `KEYWORDS_TA` (~110 search keywords), plus Category A (transliterated: MSME, GST, EMI) / Category B (glossed: PMEGP, PMMY, CGTMSE, SIDBI, TReDS, DPIIT, PMFME, ODOP) acronym handling.
- **Protected-terminology mechanism**: lives in `build_i18n.py` (the shared translation engine), not in `ta_dictionary.py` itself — protects IDs/URLs/emails/phone/numbers/currency/%/dates/acronyms from translation.
- **`LOCALIZATION_AUDIT.md`** (MSS_App repo, dated 2026-08-07) is now **stale** — it correctly identified the "284 records / 7 catalogs at 0%" gap, which the later `Plan/catalog` D3/Task1-3 scripts (dated 2026-08-15) closed. It reports the pre-fix state, not current reality.
- **`backend/catalog_ta_backfill/`** (MSS_App repo) is a separate, smaller, superseded "Stage 6" effort — 5 overlay JSON files, each explicitly self-marked `"NOT yet applied to the live Supabase catalog schema"`. Predates and is made obsolete by the `Plan/catalog` work. Do not merge this — the real, complete translations already live in the source catalog JSON.
- This work is considered **DONE** for the data layer per the roadmap's own instruction ("considered completed unless the audit discovers an actual implementation inconsistency") — no inconsistency found beyond the known `knowledge.body` gap.

---

## Offline/Cloud Architecture (Section 7)

| Piece | Classification | Evidence |
|---|---|---|
| Local release | **DONE** | `mss_catalog_bundle.dart` loads + SHA-256-verifies the bundled asset at boot; throws on mismatch |
| Cloud release | **PARTIAL** | Schema (`admin.catalog_releases`/`catalog_files`) exists, unpopulated; live-recompute (`mss_catalog_meta()`) used instead this session |
| Hash comparison | **PARTIAL** | Server-side works and is live; client-side method exists (`isStaleAgainst`) but is never called |
| Update download | **MISSING** | No download code path exists anywhere |
| Update validation | **MISSING** | Nothing to validate — no download exists |
| Atomic activation | **MISSING** | No fields/methods on any model |
| Rollback | **SOURCE_ONLY** | `rollbackRelease` Edge Function is an unwired placeholder |

`tools/generate_catalog_bundle.py` is a developer-run build script, not a runtime component — confirmed it's never invoked by the app itself.

---

## Antigravity Handoff vs Reality (Section 8)

The handoff docs are **internally inconsistent with themselves**, not just with deployed reality: `API_CONTRACT.md` §1-13 individually labels ~9 endpoint groups `[LIVE]` with specific test evidence, but its own §16 "Implementation status" section states *"Same 4 LIVE endpoints as the original contract; the 6 SPEC endpoints are still unimplemented."* Read charitably, §1-13's `[LIVE]` labels are accurate for the Python reference layer (which is what this reconciliation independently confirmed), and §16 is a stale leftover from an earlier draft that was never fully updated — but a reader arriving fresh (as e.g. a hypothetical "Antigravity" agent would) could easily walk away either over- or under-estimating what's actually deployed depending on which section they read first. **This ambiguity is itself worth fixing** in whatever doc set survives past this reconciliation.

Other contradictions found:
- Record counts: `api_docs/` consistently cites **219 schemes**; `DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md`'s example manifests cite **217** — the architecture doc's examples predate 2 later-added schemes.
- `HANDOFF_README.md` says the API's business logic is "complete and validated," which is true for the Python layer and misleading for anyone assuming that means "deployed."

No handoff doc was rewritten as part of this audit, per the stop condition.

---

## Historical Reconstruction Summary (Section 1)

**A. Catalog/data**: A long staged pipeline in `Plan/catalog/` (stage A → stage B (2 passes, 9 batches) → enrichment → verification batches E4/E5 → localization D3/Task1-3 → final gate) produced the current 15-file, 1216-entity release tagged `1.33.0-alpha`.

**B. Search**: `hybrid_search.py` with two named, code-documented improvements ("Fix #1" field weighting, "Fix #2" corpus IDF), validated against a 210-query benchmark reaching 80.2%/92.1% Top-1/Top-5 as of 2026-08-15T23:37. A separate Dart port exists for fully-offline client-side search, validated 210/210 against this same Python engine in a prior session.

**C. Localization**: `ta_dictionary.py` + `build_i18n.py` + phased scripts (D3, Task1-3) took Tamil coverage from the 0%-across-7-catalogs state `LOCALIZATION_AUDIT.md` documented (2026-08-07) to 100% primary-field coverage today (2026-08-15). A separate, smaller, explicitly-unmerged "Stage 6" backfill effort exists in the MSS_App repo and is superseded.

**D. Intelligence resolver**: `intelligence_resolver.py` implements cross-catalog joins and eligibility matching; used exclusively by the offline Python query layer, never wired server-side.

**E. API/data package prep**: `mss_api_rc1.py` ("Phase C") implements the full documented `/v1/*` contract as transport-agnostic Python, tested by `api_tests.py`.

**F. Antigravity handoff**: a large documentation set written to hand this project to a different AI agent, scoped to "Flutter integration only," internally inconsistent about what "LIVE" means (see above).

**G. Supabase deployment**: schema deployed this session (0% deployed before, per the handoff's own Phase 6 audit); 971/1216 entities imported; `/v1/meta`/`/v1/health` built and deployed as real TypeScript Edge Functions this session — the first (and only) time any part of the documented API contract was actually ported to a deployable form.

**H. Current API source**: 1 legacy dead function (`schemes-api`, never deployed, queries dropped tables), 8 undeployed placeholders, 1 real deployed function (`v1`), 1 unrelated deployed function (`livekit-token`).

**I. Flutter changes**: exactly one — `MssApiClient.defaultBaseUrl` now points at the live `v1` function instead of `localhost:8000`.

**J. Offline bundle**: works end-to-end, is what the shipped app actually runs on today, unaffected by any of the above.
