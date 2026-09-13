# Search Ranking & Catalog Data Architecture

**Audience:** any developer picking up this codebase after the 2026-09
audit-fix work. This is the authoritative "how it actually works, and why
it's built this way" reference for two things that used to be duplicated
across the codebase and silently drifted out of sync: **the search ranking
engine** and **the catalog data each service reads**.

If you're about to add a fourth place that declares scheme-search logic, or
a service that reaches into `catalog.*` tables directly instead of going
through the documented paths below — stop and read this first. This exact
mistake already happened once (see "History: what went wrong before" at the
bottom) and cost a multi-session audit to find and fix.

---

## 1. The core principle

There is **one search ranking algorithm**, implemented three times (once per
runtime), and **one catalog release**, consumed by three services in three
different ways. Every place this document says "one X, N copies," the
reason is always the same: **each runtime has a different deployment
model that makes a single shared file physically impossible**, so instead
of fighting that, each copy is kept honest by an automated **parity test**
that fails CI the moment the copies disagree.

```
                    ┌─────────────────────────┐
                    │   Supabase (source of    │
                    │   truth for catalog data)│
                    │  catalog.* tables,       │
                    │  admin.catalog_releases  │
                    └────────────┬─────────────┘
                                 │ publish (Storage bucket `catalogs`)
                                 │ releases/<version>/catalog_bundle.json.gz
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
     Flutter app          v1 edge function     Saarthi voice agent
   (mobile, offline-    (Deno, Supabase Edge   (Python, LiveKit
    first, ships a         Functions, reads      worker process,
    build-time bundle,     catalog.scheme /       ships a build-time
    OTA-syncs a fresher     catalog.search_index    bundle, syncs a
    one at runtime)         directly via SQL)       fresher one at
                                                     startup)
```

Each of the three runtimes above has **its own copy** of:

1. **The search ranking parameters** (taxonomy tables, weights, IDF regex,
   query expansions) — see §2.
2. **The catalog data itself** (scheme records + search-index profiles) —
   see §3.

Both are guarded by parity tests. Never edit one copy without also updating
its siblings and re-running the parity suite (§4).

---

## 2. The search ranking engine

### 2.1 Where it lives

| Runtime | File | Role |
|---|---|---|
| TypeScript (Supabase Edge Function) | `backend/supabase/functions/v1/search_engine.ts` | Server-side `/v1/search` route |
| Dart (Flutter app) | `frontend/lib/services/search/hybrid_scheme_search.dart` | Offline, on-device search — the actual live search path for regular users today |
| Python (Saarthi voice agent) | `saarthi-agent/src/hybrid_search.py` | Voice-driven catalog lookup (`search_scheme_catalog` tool) |

All three implement the **exact same algorithm**: taxonomy-based query
tagging → IDF-weighted keyword scoring → category/eligibility/benefit/
semantic sub-scores → a weighted sum → a status-aware multiplicative factor
→ deterministic sort (score desc, then scheme ID asc as a tiebreak). This is
a direct, field-for-field, method-for-method port across all three
languages. **It is not three independently-tuned rankers that happen to look
similar** — if you find yourself improving the ranking quality in only one
of these files, you are re-introducing the exact bug this session fixed.

### 2.2 The shared parameters (single source of truth)

All of the tunable inputs — `SHORT_TOKEN_VOCAB`, the 6 taxonomy tables
(industries/benefits/collateral/treds/communities/intents),
`RELATED_CONCEPTS`, `WEIGHTS`, `STATUS_FACTOR`, `STATUS_TO_CONCEPT`, the
token regex, `semanticQueryGroups`, and `queryExpansions` — live in exactly
**one canonical JSON file**:

```
backend/catalog/search_taxonomy.json
```

**Never hand-edit a value in `search_engine.ts`, `hybrid_scheme_search.dart`,
or `hybrid_search.py`/`search_taxonomy.py` directly.** Edit the canonical
file, then copy it over each runtime's local copy:

| Runtime | Local copy | Why not just import the canonical file directly? |
|---|---|---|
| TS | `backend/supabase/functions/_shared/search_taxonomy.json` | Supabase Edge Function deployment bundles `supabase/functions/**`; a relative import reaching outside that tree is unverified and risky to rely on for a deployed function. `_shared/` is inside the tree and already proven to deploy correctly (`_shared/cors.ts` uses the same pattern). |
| Dart | `frontend/assets/search/search_taxonomy.json` | Flutter's asset bundler was tested with a `../` path reaching outside the project tree (see the `pubspec.yaml` asset declaration history) — it built for web but landed the file *outside* the normal `assets/` prefix in the output, an inconsistency that isn't safe to assume also works correctly for a real Android/iOS build. A conventional in-tree asset avoids that risk entirely. |
| Python | `saarthi-agent/data/search_taxonomy.json` | The Saarthi Docker image's build context is scoped to `saarthi-agent/`; it cannot see `backend/catalog/` at build time. |

Each runtime keeps `queryExpansions` **inside** `search_taxonomy.json` too
(TypeScript and Python read it from there); Dart continues to read a
parallel `frontend/assets/search/query_expansion.json` for historical
reasons, and a parity test asserts the two stay byte-identical (§2.4).

### 2.3 Updating a shared parameter — the procedure

1. Edit `backend/catalog/search_taxonomy.json` only.
2. Copy it over all three local copies:
   - `backend/supabase/functions/_shared/search_taxonomy.json`
   - `frontend/assets/search/search_taxonomy.json`
   - `saarthi-agent/data/search_taxonomy.json`
3. If you touched `queryExpansions`, also update
   `frontend/assets/search/query_expansion.json` to match.
4. Regenerate the golden parity fixture (§2.4) if the change is intended to
   alter ranking output. If it isn't supposed to change output, the parity
   tests should still pass unmodified — if they don't, you've found a bug.
5. Run all three engines' test suites (Dart, Deno, pytest) before
   committing.

### 2.4 Parity tests — what actually catches drift

Three parity test files, one per language, each doing the same two checks:

| Test file | Checks |
|---|---|
| `frontend/test/search_taxonomy_parity_test.dart` | (1) local `search_taxonomy.json` byte-equals the canonical copy. (2) local `queryExpansions` byte-equals `query_expansion.json`. (3) `HybridSchemeSearch` reproduces the golden fixture. |
| `backend/supabase/functions/v1/search_engine_parity_test.ts` | Same three checks for the TypeScript engine. |
| `saarthi-agent/tests/test_hybrid_search_parity.py` | Same three checks for the Python engine. |

The **golden fixture**, `backend/catalog/search_parity_golden.json`, is a
recorded set of `{query, results: [{schemeId, score}]}` entries for 25 fixed
queries (seeded from `frontend/test/hybrid_search_quality_test.dart`), run
once against real catalog data through one engine (Dart, at the time this
was built) and checked into the repo. All three engines are asserted
against this **same fixture** — not against each other directly — so a
CI failure always names exactly which engine diverged and from what
expected output.

**If you deliberately change the ranking algorithm** (not just the
taxonomy data, the actual scoring logic), you must regenerate this fixture
from whichever engine you consider authoritative, then re-verify the other
two still match it. There is a throwaway-test-based procedure for this in
the commit history (search for `_dump_parity_fixture_test.dart` in git log)
— it loads the real catalog bundle, runs the 25 queries, and writes the
JSON. Do this deliberately, never as a side effect of "the test was
failing so I updated the fixture."

**This exact mechanism already caught one real, pre-existing bug**:
`search_engine.ts`'s hardcoded `QUERY_EXPANSIONS` had silently drifted from
`query_expansion.json`, missing "tax" and "exemption" entries. The
deployed server had been ranking tax-related voice/API queries measurably
worse than the offline app, with zero errors and zero test failures, for
an unknown length of time — because nothing was comparing the two files'
*content*, only their *existence*. Don't remove or weaken these tests to
make a change land faster.

---

### 2.5 Deep Dive: Lexical Query Expansion Architecture & Implementation

# Full Context: Query Expansion Architecture & Implementation (Phase 4 Option A)

**Document Version:** 1.0  
**Target Milestone:** Phase 4 Option A (P1) — Lexical Query Expansion  
**Applies to:** Offline Flutter Client (`HybridSchemeSearch`) & Online Supabase Edge Function (`/v1/search` / `search_engine.ts`)  
**Baseline Performance:** 80.2% Top-1 / 92.1% Top-5  
**Target Performance:** 84%–88% Top-1 without regressing baseline  

---

## 1. Executive Summary & Architectural Motivation

### 1.1 The Core Problem
In the MSS (Micro & Small Scheme) application, users search for government business schemes, grants, subsidies, and loans using highly diverse vocabulary:
- **Acronyms & Short Names:** Users frequently type acronyms like `"PMEGP"`, `"MUDRA"`, `"CGTMSE"`, `"NEEDS"`, `"TREAD"`, or `"WEP"`.
- **Tamil Transliterations (Tanglish):** Many Tamil entrepreneurs search using Latin-script transliterations such as `"kadan"` (loan), `"udavi"` (assistance), `"thozhil"` (business), `"magalir"` (women), `"maniyam"` (subsidy), or `"thittam"` (scheme).
- **Institutional Abbreviations:** Searchers reference departments or agencies like `"MoMSME"`, `"KVIC"`, `"SIDBI"`, `"DPIIT"`, or `"TANSIM"`.
- **Colloquial & Informal Phrasing:** Queries such as `"tea stall"`, `"street vendor"`, `"old age"`, or `"student startup"` do not match the formal bureaucratic scheme titles directly.

Because the underlying search engine is lexical (TF-IDF keyword matching + taxonomy scoring), queries that miss on *vocabulary* rather than *concept* score low or fail completely.

### 1.2 Why Option A (Query Expansion)?
During the Phase 4 architectural evaluation, three architectural paths were scoped:
1. **Option A (Lexical Query Expansion):** Client & server dictionary expansion. Zero latency impact, zero API cost, completely offline-safe, preserves the 100% offline contract, +4–8% top-1 accuracy improvement.
2. **Option B (pgvector in Supabase):** Online-only vector search with hosted embeddings. Adds 300–500ms network latency to Sydney (`ap-southeast-2`), incurs per-query API costs, and creates a bimodal UX where offline users get worse results than online users.
3. **Option C (Bundled Embeddings + Edge Model):** Reintroduces on-device SLMs (Qwen / MiniLM) requiring a 20–90 MB download and first-run cold starts, contradicting the project's explicit architectural decision to remove edge AI models.

**The User and Project Decision:** Implement **Option A only**.

### 1.3 The Non-Negotiable Contract: Dual-Sided Parity
MSS operates on a strict **online-first / offline-fallback contract**:
1. **Online Path:** The Flutter client sends `POST /v1/search` to the Supabase Edge Function (`backend/supabase/functions/v1/search_engine.ts`).
2. **Offline Fallback:** When offline or on timeout (2500 ms), the client executes `HybridSchemeSearch.rank()` (`frontend/lib/services/hybrid_scheme_search.dart`) against the local `catalog_bundle.json.gz`.
3. **Equivalence Rule:** The query expansion logic and dictionary mapping must be **field-for-field identical** across both Dart and TypeScript engines so results never diverge based on connectivity.

---

## 2. Deep Dive: Catalog Vocabulary & Tokenization Mechanics

### 2.1 The Shipped Catalog
- Total Schemes: **219** (in `scheme_catalog.json`)
- Search Profiles: **219** (in `search_index.json` where `entityType == 'scheme'`)
- Token Universe (`_vocab`): **1,840 distinct tokens** extracted across:
  - `tokens.en` (English tokens, lowercase)
  - `tokens.ta` (Tamil script Unicode tokens `[஀-௿]`, e.g. `கடன்`, `உதவி`, `தொழில்`)
  - `loanType`, `subsidyType`, `taxBenefits`, `clusters`, `industryTags`, `benefitTags`

### 2.2 Token Extraction & Concept Building (`_queryConcepts`)
In both `hybrid_scheme_search.dart` and `search_engine.ts`, the query is parsed into `_Concept` objects:
```dart
// Tokenization regex
final _tokenRe = RegExp(r'[A-Za-z][A-Za-z0-9&-]{1,}|[஀-௿]{2,}');

// Gating condition: token must be >= 3 chars or in shortTokenVocab {'sc', 'st', 'tn'}
bool isSearchableToken(String token) =>
    token.length >= 3 || shortTokenVocab.contains(token.toLowerCase());
```

For each extracted token `tok`:
1. Base forms are generated: `forms = {tok}`.
2. Hyphenated tokens are split: `tok.split('-')`.
3. Stemming variants are checked against `_vocab`: `tok.endsWith('s')` and `${tok}s`.
4. Gating filter is applied:
   ```dart
   final gated = forms.where(_vocab.contains).toSet();
   forms = gated.isEmpty ? {tok} : gated;
   ```
5. Document frequency and IDF are calculated:
   ```dart
   final docFreq = _schemeEntries
       .where((e) => forms.intersection(_entryTerms(e)).isNotEmpty)
       .length;
   concepts.add(_Concept(forms, _idf(docFreq)));
   ```
   Where `_idf(docFreq) = ln((nDocs + 1) / (docFreq + 1)) + 1`.

### 2.3 The Integration Point for Query Expansion
Expansion must occur **before** the `_vocab.contains` gate:
- For a query token `tok`, if the expansion dictionary contains `tok`, its mapped expansion tokens are added to `forms`.
- The `_vocab.contains` gate then filters the expanded set, ensuring only valid catalog terms remain.
- **Why this preserves accuracy:**
  1. The original token is never replaced.
  2. If the user typed a specific keyword that exists in the scheme, it matches.
  3. The extra tokens provide alternative entry points for schemes that express the same concept with different words.
  4. Because `forms` now represents the union of synonyms, its `docFreq` is higher, and its IDF weight is naturally lower ("softer") than a hyper-specific unique match.

---

## 3. Verified Expansion Dictionary Specifications

All candidate expansion tokens have been verified directly against the 1,840-word catalog `_vocab`. Every token listed below is guaranteed to exist in the catalog search profiles.

### 3.1 Scheme Acronyms ↔ Full Official Forms
| Query Token | Expansion Forms (in `_vocab`) | Target Scheme Example |
| :--- | :--- | :--- |
| `pmegp` | `["prime", "minister", "employment", "generation", "programme"]` | SCH000130 (TN130 PMEGP) |
| `mudra` | `["pradhan", "mantri", "mudra", "yojana"]` | SCH000131 (TN131 PMMY) |
| `pmmy` | `["mudra", "pradhan", "mantri", "yojana"]` | SCH000131 (TN131 PMMY) |
| `cgtmse` | `["credit", "guarantee", "fund", "micro"]` | SCH000007 (TN007 CGTMSE) |
| `needs` | `["entrepreneur", "enterprise", "development"]` | SCH000087 (TN087 NEEDS) |
| `tread` | `["trade", "entrepreneurship", "assistance", "development", "women"]` | SCH000185 (TN185 TREAD) |
| `wep` | `["women", "entrepreneurship", "platform"]` | SCH000216 (TN216 WEP) |
| `uyegp` | `["unemployed", "youth", "employment", "generation", "programme"]` | SCH000200 (TN200 UYEGP) |
| `tanseed` | `["startup", "seed", "fund", "grant"]` | SCH000182 (TN182 TANSEED) |
| `clcss` | `["credit", "linked", "capital", "subsidy"]` | SCH000010 (TN010 CLCSS) |
| `pmfme` | `["food", "processing", "enterprises", "micro"]` | SCH000128 (TN128 PMFME) |
| `pmkvy` | `["kaushal", "vikas", "skill", "training"]` | SCH000129 (TN129 PMKVY) |

### 3.2 Institutional Abbreviations
| Query Token | Expansion Forms (in `_vocab`) | Context |
| :--- | :--- | :--- |
| `momsme` | `["msme", "ministry", "enterprises"]` | Ministry of MSME |
| `kvic` | `["khadi", "village", "industries"]` | Khadi & Village Industries |
| `sidbi` | `["small", "industries", "development", "bank"]` | SIDBI refinancing & loans |
| `dpiit` | `["industry", "trade", "promotion"]` | DPIIT Startup Recognition |
| `tansim` | `["startup", "tamil", "nadu", "innovation"]` | Tamil Nadu Startup Mission |

### 3.3 Tamil Transliterations (Tanglish ↔ English & Tamil Script)
In the catalog, Tamil fields are indexed in UTF-8 Tamil script. Users frequently type phonetic English words. Expansion connects Tanglish to both English and Tamil script tokens:
| Query Token | Expansion Forms (in `_vocab`) | Meaning |
| :--- | :--- | :--- |
| `kadan` | `["loan", "credit", "கடன்"]` | Loan / Credit |
| `udavi` | `["subsidy", "grant", "assistance", "உதவி"]` | Financial Assistance |
| `thozhil` | `["business", "enterprise", "industry", "employment", "தொழில்"]` | Business / Enterprise |
| `magalir` | `["women", "மகளிர்"]` | Women / Female |
| `maniyam` | `["subsidy", "மானியம்"]` | Subsidy |
| `thittam` | `["scheme", "programme", "திட்டம்"]` | Government Scheme |
| `vivasayi` | `["agriculture", "agricultural", "farm"]` | Farmer / Agriculture |
| `velai` | `["employment", "skill", "training"]` | Employment / Work |

### 3.4 Multi-Word Phrases & Colloquial Aliases
Multi-word phrases represent queries where individual words might be stopwords or ambiguous on their own:
| Phrase Key | Injected Concept Forms (in `_vocab`) | Rationale |
| :--- | :--- | :--- |
| `stand up india` | `["stand-up", "women", "sc", "st", "enterprise"]` | "up" is <3 chars; maps to Stand-Up India |
| `street vendor` | `["svanidhi", "street", "vendor", "vendors"]` | PM SVANidhi street vendor support |
| `tea stall` | `["svanidhi", "vendor", "micro", "street"]` | Colloquial micro-vendor search |
| `student startup` | `["student", "innovation", "youth", "startup"]` | Student innovation & incubation |
| `handicraft` | `["craftspeople", "artisans"]` | Handloom & handicraft artisans |
| `handloom` | `["artisans", "handicrafts"]` | Weaving & handloom enterprises |

---

## 4. Multi-Word Phrase Matching Strategy

### The Problem with Pure Single-Token Expansion
If a query contains `"stand up india"`:
- `"stand"` is tokenized.
- `"up"` has length 2 and is discarded by `isSearchableToken` (`length < 3`).
- `"india"` has a very high document frequency (`docFreq ≈ 153`), resulting in low IDF.
- The catalog token is actually hyphenated: `"stand-up"`. Without phrase matching, the user misses the Stand-Up India scheme!

### The Multi-Word Phrase Solution
In `_queryConcepts(String query)`:
1. Normalize query text to lower-case: `final queryLower = ' ${query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')} ';`
2. For each key in `queryExpansionMap` that contains whitespace (multi-word phrase):
   - If `queryLower.contains(' $phrase ')`:
     - Collect its expanded tokens.
     - Filter against `_vocab`: `final gated = forms.where(_vocab.contains).toSet();`
     - Add as a dedicated `_Concept(gated, _idf(docFreq))` with a unique key.
3. Proceed with single-token concept building for the remaining tokens.
4. This cleanly resolves multi-word aliases without altering single-token scoring.

---

## 5. Synchronous Loading Architecture (Zero Async Gap)

### The Constraint
`HybridSchemeSearch.search()` and `_queryConcepts()` are synchronous functions. Introducing an `await rootBundle.loadString(...)` directly inside `_queryConcepts()` would break the synchronous API contract, requiring rewriting call sites across screens, adapters, and repositories.

### The Solution
1. **Asset Storage:** The dictionary lives at `frontend/assets/search/query_expansion.json`.
2. **Asset Registration:** Registered in `frontend/pubspec.yaml` under `flutter.assets`:
   ```yaml
   assets:
     - assets/catalog/
     - assets/search/
   ```
3. **Bundle Integration:** `MssCatalogBundle.load()` loads `query_expansion.json` alongside `catalog_bundle.json.gz`:
   ```dart
   final expansionJsonStr = await rootBundle.loadString('assets/search/query_expansion.json');
   final expansionMap = (jsonDecode(expansionJsonStr) as Map<String, dynamic>).map(
     (k, v) => MapEntry(k, (v as List).cast<String>()),
   );
   ```
   Stored as `bundle.queryExpansions`.
4. **Fallback & Testing:** `HybridSchemeSearch` retains a `const Map<String, List<String>> defaultExpansions` or static cache, allowing synchronous initialization in test environments where `MssCatalogBundle` is constructed directly.

---

## 6. Server-Side Parity: Supabase Edge Function

### File: `backend/supabase/functions/v1/search_engine.ts`
The TypeScript search engine mirrors `HybridSchemeSearch` field-for-field.
1. The expansion dictionary is placed in `backend/supabase/functions/v1/query_expansion.json` (or bundled as a TypeScript constant `QUERY_EXPANSIONS`).
2. Inside `HybridSearchEngine.queryConcepts(query: string)`:
   - Check multi-word phrase keys against `query.toLowerCase()`.
   - For single tokens, merge `QUERY_EXPANSIONS[tok]` into `forms` before checking `this.vocab.has(f)`.
   - Compute `docFreq` and `idf` identically to Dart.
3. This ensures that the online `/v1/search` endpoint and offline fallback return **identical rankings and scores** for expanded queries.

---

## 7. Testing & Quality Assurance Plan

### 7.1 New Unit Test Suite: `frontend/test/query_expansion_search_test.dart`
1. **Dictionary Integrity Test:** Asserts that every expansion target word in `query_expansion.json` exists in `MssCatalogBundle.schemes` token vocabulary (`_vocab`).
2. **Acronym Resolution Test:** Verifies `"pmegp"` ranks `SCH000130` as #1 with reasons explaining keyword match.
3. **Tanglish Resolution Test:** Verifies `"kadan"` returns loan schemes and `"udavi"` returns subsidy schemes.
4. **Phrase Expansion Test:** Verifies `"stand up india"` resolves to `SCH000181` / Stand-Up India.
5. **Colloquial Resolution Test:** Verifies `"tea stall"` ranks PM SVANidhi (`SCH000133`) in top-3.

### 7.2 Non-Regression Test
- Run `frontend/test/scheme_understanding_corpus_test.dart` to verify `Recall@3 >= 0.92`.
- Run `frontend/test/discover_counts_test.dart`, `for_me_filter_shrinks_test.dart`, and `spacing_scale_test.dart` to confirm zero regressions across earlier completed phases.
- Target search accuracy: **84%–88% Top-1**.


---

## 3. Catalog data: source of truth, publishing, and sync

### 3.1 Source of truth

The canonical catalog data lives in Supabase Postgres, schema `catalog`:
15 per-type tables (`catalog.scheme`, `catalog.authority`,
`catalog.institution`, `catalog.finance`, `catalog.tax`, `catalog.treds`,
`catalog.csr`, `catalog.export`, `catalog.knowledge`,
`catalog.applicability_matrix`, `catalog.enterprise_classification`,
`catalog.msme_privilege`, `catalog.business_enablement`,
`catalog.cluster_assistance`, `catalog.common`), plus
`catalog.search_index` (a derived, flat search-only projection —
`schemeSearchProfile` + tokenized `tokens.en`/`tokens.ta` per entity) and
`catalog.entity_registry` (canonical entity index, kept in sync via
triggers — see `docs/DATABASE_ARCHITECTURE.md` §3.1 for the full schema).

**`catalog.*` is never exposed to PostgREST directly** (no
`Access-Control-Allow-Origin`, no anon/authenticated grants on the schema
itself). All read access goes through `public`-schema `SECURITY DEFINER`
RPC functions (§5) or through the `v1` Edge Function, which queries
`catalog.*` using the service-role client.

A **release** is a point-in-time, immutable snapshot of that data,
tracked in `admin.catalog_releases` (`release_version`, `package_sha256`,
`package_byte_size`, `schema_version`, `record_counts`, `published_at`,
`is_current`, `status`). The current release's identity is exposed
through one lightweight, anon-callable RPC:

```sql
select * from public.mss_current_release();
-- returns: release_version, package_sha256, package_byte_size,
--          schema_version, record_counts, published_at
```

This RPC is intentionally cheap — a single-row lookup, no joins across
the 15 catalog tables — specifically so every consumer can check "is my
local copy current?" without the cost of diffing actual content. **Use
this RPC for any future version-check need; do not invent a second one.**

The actual release **artifact** (`catalog_bundle.json.gz` — a gzip'd JSON
containing all 15 catalogs + `search_index.json` + a manifest) is
published to Supabase Storage:

```
bucket: catalogs
path:   releases/<release_version>/catalog_bundle.json.gz
```

### 3.2 How each consumer gets the data

#### Flutter app (the reference implementation — copy this pattern, don't reinvent it)

- **Build-time bundle**: `frontend/assets/catalog/catalog_bundle.json.gz`,
  declared in `pubspec.yaml`, always present, always the fallback of last
  resort.
- **Runtime sync**: `frontend/lib/services/scheme_catalog_sync_service.dart`
  (`SchemeCatalogSyncService` + `SupabaseCatalogReleaseSource`):
  1. Calls `mss_current_release()`.
  2. Compares the result against the locally installed manifest
     (`SchemeCatalogStore`'s `readActiveManifest()`) by
     `release_version` **and** `sha256` (`CatalogManifest.sameReleaseAs`).
  3. If unchanged: does nothing.
  4. If changed: downloads `releases/<version>/catalog_bundle.json.gz`
     from the `catalogs` Storage bucket, verifies its SHA-256, and installs
     it via `SchemeCatalogStore.install()`.
  5. Throttled to once per hour (`Duration(hours: 1)`), tracked via an
     in-memory `_lastCheck` timestamp on a process-lifetime singleton —
     safe for Flutter because a mobile app process genuinely lives for the
     whole user session.
- **Load path**: `MssCatalogBundle.load()` prefers the installed OTA
  release if present and its checksum re-verifies; falls back to the
  shipped asset on any failure. See Part 5 of
  `docs/specs/CATALOG_SPECIFICATIONS.md` for
  the full state machine.

#### `v1` Edge Function (TypeScript)

Does **not** sync a file at all — it's a stateless server function that
queries `catalog.scheme` / `catalog.search_index` directly via SQL on every
request, using the service-role client. There is no "stale copy" problem
here because there is no copy; the query always sees the current
production data. This is the simplest of the three consumers by
construction.

#### Saarthi voice agent (Python)

Mirrors the Flutter pattern almost exactly — see
`saarthi-agent/src/catalog_sync.py` (`CatalogSyncService`):

1. Calls `mss_current_release()` via a direct REST call (`aiohttp`,
   `POST {SUPABASE_URL}/rest/v1/rpc/mss_current_release`) — there's no
   `supabase-py` dependency in this project, so this is a thin manual
   HTTP client, not a SDK wrapper.
2. Compares against a local manifest sidecar file,
   `saarthi-agent/data/catalog_manifest.json` (not committed —
   see `.gitignore`).
3. If unchanged: does nothing. If changed: downloads the same
   `catalog_bundle.json.gz` from the same Storage bucket, verifies SHA-256,
   extracts `scheme_catalog.json` and `search_index.json` (filtered to
   `entityType == 'scheme'`, matching `MssCatalogBundle`'s own filter) and
   overwrites the local files.
4. Throttled to once per hour — but **persisted to disk**
   (`saarthi-agent/data/last_sync_check.json`), not held only in memory.
   This is the one deliberate deviation from the Flutter pattern: LiveKit
   may run each job in its own subprocess (`AgentServer.setup_fnc` receives
   a `JobProcess`), so an in-memory timestamp on a Python object cannot be
   trusted to survive between jobs the way a mobile app's process-lifetime
   singleton can. If you ever confirm the worker process model is
   long-lived and single-instance, the disk persistence is still correct
   (and harmless) — do not remove it without first proving the process
   model has changed.
5. Wired into `agent.py` via `server.setup_fnc`, which LiveKit calls once
   per worker process before it starts accepting jobs — the closest
   equivalent to "at app startup."
6. **Never blocks or crashes startup.** Every failure mode (network,
   timeout, checksum mismatch, schema-version incompatibility) logs a
   warning and leaves whatever's already on disk untouched. The Docker
   image's bundled copy of `scheme_catalog.json`/`search_index.json` is
   always the fallback of last resort, exactly like Flutter's bundled
   asset.

**If you build a fourth consumer of this catalog** (a new service, a new
client), follow this same three-step shape: cheap version check via
`mss_current_release()` → conditional download from the `catalogs` bucket
→ checksum verify before installing → throttled, disk-or-process-lifetime
persisted, never blocking startup on failure. Do not invent a different
sync protocol.

---

## 4. API routing (Supabase Edge Functions)

All HTTP routes are Deno-based Supabase Edge Functions under
`backend/supabase/functions/`:

| Function | Purpose |
|---|---|
| `v1` | The real API gateway — `/v1/meta`, `/v1/health`, `POST /v1/search`, `/v1/schemes/{id}[...]`, etc. Deployed as a function literally named `v1` so the client's hardcoded `/v1/meta` path resolves through Supabase's `.../functions/v1/v1/meta` routing quirk — see the header comment in `v1/index.ts` before renaming anything. |
| `livekit-token` | Issues LiveKit room tokens for the voice agent, after authenticating the caller's Supabase session and attaching their profile as job metadata. |
| `publishCatalog` | Broadcasts a realtime `catalog_sync` channel event after a new release is published — a notification hook, not a data-import function. Requires presenting the service-role key itself (not just a valid user session) since it's meant only for trusted backend/admin callers. |
| `rollbackRelease` | Promotes a previous catalog release by UUID via `public.mss_rollback_release(uuid)` and broadcasts a catalog sync event. Requires service-role authentication. |
| `sarvam-chat` | Proxies conversational queries to Sarvam AI text chat completion API with temperature, token ceiling, and rate limiting. |
| `db-change-notify` | Generic Postgres-trigger-driven realtime broadcaster. |
| `search`, `recommend` | **Retired** (`410 GONE`) — kept only so old clients get a clear error instead of a 404. Do not resurrect these; their target RPCs (`search_schemes`, `recommend_schemes`) were dropped as dead code. |

**Shared code lives in `backend/supabase/functions/_shared/`** — anything
placed there is available to every function (it's inside the deployment
tree, per §2.2's table). Currently: `cors.ts` and `search_taxonomy.json`.

### 4.1 CORS

Every function computes its CORS headers **per request**, not once at
module load, via `_shared/cors.ts`'s `buildCorsHeaders(req)`. It reflects
the request's `Origin` header only if it matches an explicit allowlist
(currently: localhost dev origins; the Flutter app itself sends no
`Origin` header at all, so it needs no entry). Any origin not on the list
gets **no** `Access-Control-Allow-Origin` header at all — not a wildcard.

If a real production web origin needs access, add it to
`ALLOWED_ORIGINS` in `_shared/cors.ts`. **Never revert to `'*'`** — that
was finding 3.1 in the original audit, already fixed once.

### 4.2 Rate limiting

`v1/index.ts` enforces a global per-IP rate limit (`RATE_LIMITS`,
persistent, backed by `public.api_rate_limits`) on every route except
`/v1/health` (exempted so uptime probes never consume budget), plus
tighter per-minute/per-day/global-per-day limits specifically on
`POST /v1/search`, since that route pulls the full corpus and carries
essentially all of the egress cost. All three limits fail **closed**: if
the rate-limit check itself can't be evaluated, the request is rejected,
not allowed through.

---

## 5. DB requesting patterns

### 5.1 The RPC boundary

Nothing outside `public`-schema `SECURITY DEFINER` functions (or the
service-role-authenticated Edge Functions) ever touches `catalog.*`,
`admin.*`, or `private.*` directly. Client code — Flutter, the voice
agent, any future consumer — calls a `public.mss_*` RPC or hits `/v1/*`;
it never runs raw SQL against `catalog.scheme` etc. This is deliberate
defense-in-depth, not an accident: several `catalog.*` functions
(`mss_search`, `mss_localized_text`, `mss_search_document`) are themselves
**out-of-band objects** — created directly against production, not by any
tracked migration (see `20260829160000_harden_exposed_functions.sql`'s
`to_regprocedure(...) is not null` guards, and the correction migration
`20260905080758`/`20260905111658` this session had to write after
discovering that "0 code references" checks that only grep app source
directories miss references living inside SQL function bodies). **If you
write a migration that revokes or alters a function/table based on a
"nothing references this" grep, also grep the migrations directory itself
for `CREATE OR REPLACE FUNCTION` bodies, and check `pg_get_functiondef()`
against production directly** — a source-tree grep is not sufficient
evidence of "unused."

### 5.2 RLS posture

Every `public`-schema table with user data has RLS enabled and **forced**
(`FORCE ROW LEVEL SECURITY`) — see `docs/DATABASE_ARCHITECTURE.md` §5 for
the full policy inventory and the `rls-drift-check.yml` workflow that
guards it weekly. `catalog.*` tables don't need RLS at all (they're never
exposed to PostgREST), but **do** carry triggers
(`catalog.sync_entity_registry`) that keep `catalog.entity_registry` in
sync with the 15 per-type tables automatically — see §3.1 above and the
migration `20260905122008_populate_and_sync_entity_registry.sql` for why
this exists (the originally-planned import function,
`admin_import_scheme_catalog`, does not exist in this database; the
trigger approach was chosen specifically so a manual backfill wouldn't go
stale the next time someone publishes a release through whatever
out-of-band process currently loads the 15 catalog tables).

### 5.3 Table archival is a rename, not a drop — and isn't free

Zero-row, zero-*app-code*-reference tables in this codebase are archived
by `RENAME TO _deprecated_<name>`, never dropped, specifically because a
prior archival pass renamed 4 tables
(`organization_memberships`, `user_roles`, `regions`, `user_regions`) that
turned out to be referenced by `SECURITY DEFINER` RLS-helper functions
(`private.has_role`, `private.has_region`, `private.belongs_to_organization`)
— breaking those functions in production with zero live user impact only
because nothing was calling them yet. **Before archiving any table, grep
`pg_proc` definitions in production (not just the source tree) for its
name.** The migration `20260905111658_restore_load_bearing_rbac_tables.sql`
is the fix-forward correction for this exact mistake; read it before
repeating the pattern.

---

## 6. History: what went wrong before (so it doesn't happen again)

This document exists because, before the 2026-09 audit-fix work:

- **Search ranking** was implemented three times independently, with no
  automated check that they agreed. The TypeScript copy's query-expansion
  dictionary silently drifted from the Dart copy's, degrading server-side
  search quality for an unknown period with zero errors.
- **The voice agent's catalog** was a snapshot frozen at Docker-build
  time, with no sync mechanism at all — the "three-week-stale catalog"
  problem.
- **CORS** was `'*'` everywhere.
- **A table archival pass** archived load-bearing tables because its
  "is this referenced anywhere" check only grepped application source
  code, not SQL function bodies.
- **A migration's own "already-verified `0` references" claim** turned out
  to be based on an incomplete grep scope (missed `backend/supabase/tests/`
  and `backend/supabase/seed/`), breaking `db:reset`/`db:test` in CI.

None of these were caught by manual review at the time they landed. All
of them were eventually caught by either (a) a parity/equality test that
compares two things that are supposed to agree, or (b) actually running
`db:reset`/`db:test`/`pytest`/`flutter test` against a fresh environment
instead of trusting that "it worked before." **When you build something
new that's supposed to have exactly one source of truth across multiple
runtimes, build the parity test in the same change, not as a follow-up.**
