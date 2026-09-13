# Offline Discovery, Search & Recommendation Architecture

**Audience:** Mobile engineers, backend architects, and voice agent developers working on scheme search, categorization, eligibility scoring, or catalog synchronization.

This is the single authoritative architecture specification for how the MSS application serves scheme discovery — including search ranking, query expansion, category browsing, filtering, and "For Me" eligibility recommendations — completely offline on-device, and how catalog data and user profiles are synchronized with the cloud.

---

## Table of Contents
1. [Core Architectural Principles](#1-core-architectural-principles)
2. [Catalog Bundle: The Offline Data Layer](#2-catalog-bundle-the-offline-data-layer)
3. [Scheme Access Layer: `SchemeRepository`](#3-scheme-access-layer-schemerepository)
4. [Search Ranking Engine: `HybridSchemeSearch`](#4-search-ranking-engine-hybridschemesearch)
5. [Deep Dive: Lexical Query Expansion (Phase 4 Option A)](#5-deep-dive-lexical-query-expansion-phase-4-option-a)
6. [Facet Filtering Subsystem: `applySchemeFilters`](#6-facet-filtering-subsystem-applyschemefilters)
7. [Recommendation Engine: "For Me" Eligibility Scorer](#7-recommendation-engine-for-me-eligibility-scorer)
8. [User Profile Lifecycle & Storage](#8-user-profile-lifecycle--storage)
9. [Catalog Release, Distribution & Multi-Consumer Sync](#9-catalog-release-distribution--multi-consumer-sync)
10. [API Routing & Edge Functions](#10-api-routing--edge-functions)
11. [Data Integrity, Security & Failure Modes](#11-data-integrity-security--failure-modes)
12. [Module Map & Parity Invariants](#12-module-map--parity-invariants)

---

## 1. Core Architectural Principles

| Principle | Meaning & Enforcement |
|---|---|
| **100% Offline for Discovery** | Every scheme read — search queries, category browsing, detailed view, eligibility recommendations — is served entirely on-device from a bundled, verified catalog. No network call sits on the user search critical path. |
| **Server is for Sync, Not Queries** | The Supabase `POST /v1/search` edge function exists and is deployed, but has **no client runtime caller**; it is the planned path for server-side voice agents. Citizen queries are processed locally in-process. |
| **Deterministic & Explainable** | Search ranking and recommendation scoring are pure functions over versioned data (no per-query LLM hallucination). The same input always produces identical scores and human-readable explanation reasons. |
| **One Algorithm, Three Runtimes** | The exact same search ranking math is implemented across three runtimes: Dart (`frontend/`), TypeScript (`backend/`), and Python (`saarthi-agent/`). They share one canonical taxonomy dictionary and are locked together by automated parity tests. |
| **One Source of Truth Per Concern** | Catalog data $\rightarrow$ `MssCatalogBundle`. Scheme access $\rightarrow$ `SchemeRepository`. Search $\rightarrow$ `HybridSchemeSearch`. Filtering $\rightarrow$ `applySchemeFilters`. Eligibility $\rightarrow$ `RecommendationEngine`. |
| **Resilient Profile Rehydration** | The user profile is cached locally in `SharedPreferences` and rehydrated from Supabase via **additive merge**, never blind overwrite, ensuring local scoring inputs are never blanked by partial network data. |

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

---

## 2. Catalog Bundle: The Offline Data Layer

### 2.1 Shipped Artifacts
The Flutter application ships an immutable, compressed catalog asset:
`frontend/assets/catalog/catalog_bundle.json.gz` — a single gzip-compressed JSON object mapping catalog names to record lists. It contains **all 15 catalog files plus `search_index.json` and `manifest.json`**:

```
scheme_catalog.json            219   ← the schemes (SCH000001..SCH000219)
common_catalog.json            344
authority_catalog.json         124
institution_catalog.json        83
finance_catalog.json           115
tax_catalog.json                13
treds_catalog.json              16
csr_catalog.json                16
export_catalog.json             13
knowledge_catalog.json          28
applicability_matrix_catalog…  219
enterprise_classification_…     11
msme_privilege_catalog.json      2
business_enablement_catalog…     7
cluster_assistance_catalog…     10
search_index.json              971   (one record per entity, all types)
manifest.json                    1
```

Accompanying descriptor: `frontend/assets/catalog/release.json` — integrity descriptor defining `releaseTag`, `bundleSha256`, `entityCount`, `searchIndexCount`, and a per-file SHA-256 map.

*Current baseline release:* **`1.34.3-alpha`** (219 schemes / 1,220 entities / 971 search-index records).

### 2.2 Loading Architecture: `MssCatalogBundle.load()`
`frontend/lib/services/catalog/mss_catalog_bundle.dart` loads the catalog into memory once per application lifespan using a memoized static Future:

```
load()  ── once per app lifespan (memoised in a static Future) ──►
  │
  ├─ 1. Is there an "installed release"?
  │      app dir: .../app_flutter/mss_catalog_cache/<version>/catalog_bundle.json.gz
  │      + active_manifest.json pointing at it.
  │      This is a NEWER bundle fetched at runtime by the catalog-sync flow (§9).
  │      Its SHA-256 was verified at install time.
  │      → decompress + parse in worker isolate via compute(), return.
  │
  └─ 2. Otherwise fall back to the SHIPPED ASSET
         rootBundle.load('assets/catalog/catalog_bundle.json.gz')
         → verify sha256(bytes) == release.json.bundleSha256
           (skipped only under overrideChecksumForTest: true in tests)
         → decompress + parse in worker isolate via compute(), return.
```

- `MssCatalogBundle.invalidate()` clears the memoized future when a catalog update is installed, so the next access loads the fresh release.
- On real devices, the app typically serves the verified OTA release from `mss_catalog_cache/`. Shipped assets serve as the indestructible fallback.

### 2.3 Models: Raw Entity vs. UI Projection
- **`MssEntity` (`lib/models/mss_entity.dart`):** Immutable raw entity representation keeping the full source JSON (`entity.raw`) plus typed accessors (`identity`, `content`, `search`, `getLocalizedName('en'|'ta')`, `getLocalizedAttribute`).
- **`MssSchemeAdapter.toScheme(entity, bundle, langCode)` (`lib/services/catalog/mss_scheme_adapter.dart`):** Projects `MssEntity` into the flat `Scheme` model (`lib/models/scheme_model.dart`) consumed by UI screens (`name`, `state`, `governmentLevel`, `category`, `benefits`, `eligibility`, `glanceChips`, `nameTa`, etc.).
  - *Adapter Rules:* Nationwide schemes normalize `state` to `"All India"` / `"Pan-India"`. Non-central schemes without state text default to `"Tamil Nadu"`. `Scheme.governmentLevel` defaults to `"Central"` on the model, so use `schemeIsNationwide(scheme)` rather than `governmentLevel` to identify nationwide schemes.

---

## 3. Scheme Access Layer: `SchemeRepository`

`frontend/lib/services/catalog/scheme_repository.dart` is the singleton gateway through which screens access schemes:

| Method | Implementation Source |
|---|---|
| `getAllSchemes()` | `bundle.schemes` $\rightarrow$ `Scheme` list (cached in-memory) |
| `searchSchemes(query)` | `HybridSchemeSearch.rank()` $\rightarrow$ `List<Scheme>` (pure relevance list) |
| `searchSchemeMatches(query, limit)` | `HybridSchemeSearch.rank()` $\rightarrow$ `List<SchemeSearchMatch>` (keeps scores & matched reasons for voice/assistant UIs) |
| `getSchemesByCategory / ByMinistry / ByState` | Keyword `.where()` over catalog, then `_rankByQuery` re-orders by query relevance |
| `getSchemeById(id)` | `bundle.getEntity(id)` $\rightarrow$ `Scheme` |
| `getCategoryCounts(profile)` | Dynamic counts for home and browse category cards |
| `getProfile / createProfile / updateProfile` | Supabase `public.profiles` & `startup_profiles` CRUD (§8) |

`searchSchemes` incorporates in-flight de-duplication and a 15-second memo cache to prevent redundant isolate computation during rapid typing.

---

## 4. Search Ranking Engine: `HybridSchemeSearch`

### 4.1 Multi-Runtime Parity
Search ranking is implemented across three runtimes:
- **Dart (Flutter):** `frontend/lib/services/search/hybrid_scheme_search.dart`
- **TypeScript (Edge Function):** `backend/supabase/functions/v1/search_engine.ts`
- **Python (Saarthi Voice):** `saarthi-agent/src/hybrid_search.py`

All three implement the exact same ranking algorithm:
$$\text{Score} = \sum (\text{Concept IDF} \times \text{Field Weights}) + \text{Category Score} + \text{Benefit Score} + \text{Eligibility Score}$$
multiplied by a status factor, tie-broken by scheme ID ascending.

### 4.2 Canonical Vocabulary (`search_taxonomy.json`)
All tunable inputs (`SHORT_TOKEN_VOCAB`, 6 taxonomy tables: industries, benefits, collateral, treds, communities, intents; `RELATED_CONCEPTS`, `WEIGHTS`, `STATUS_FACTOR`, token regex, and semantic query groups) live in **one canonical JSON**:
`backend/catalog/search_taxonomy.json`

Local copies are mirrored at:
- `backend/supabase/functions/_shared/search_taxonomy.json` (Edge Function bundle)
- `frontend/assets/search/search_taxonomy.json` (Flutter asset)
- `saarthi-agent/data/search_taxonomy.json` (Docker context)

*Never edit local runtime copies directly.* Update `backend/catalog/search_taxonomy.json` and mirror it.

### 4.3 Search Entry Points: `search()` vs. `rank()`
```
engine.search(query, {topN})          ── PARITY-LOCKED CORE ──
   Deterministic IDF-weighted concept scoring over search_index fields.
   Drops entries scoring <= 0. Sort: score desc, entityId asc.
   Golden-fixture tested (backend/catalog/search_parity_golden.json) and
   mirrored by Deno v1/search_engine.ts and Python hybrid_search.py.

HybridSchemeSearch.rank(query, bundle, {limit})   ── FLUTTER WRAPPER ──
   1. exactEntityMatches(query)   → name/acronym/alias fast-path
        Tier 1: query == normalised scheme name / alias
        Tier 2: compact query == identity.acronym / shortName (e.g. "pmegp")
        Tier 3: multi-word query covering >=60% of scheme name tokens
        Common stop words (loan, subsidy, women) never trigger exact matches.
        → If matched: returns ONLY exact matches (score 1.0, reason "Exact scheme match").
   2. else engine.search(query)
        → Floor filter: keep scores >= 0.35 * maxScore
        → Cap: first 25 results
        → Proper-name guard: if query has >=3 meaningful tokens but maxScore < 4.0,
          return [] ("No schemes found") to prevent common-word noise.
```

---

## 5. Deep Dive: Lexical Query Expansion (Phase 4 Option A)

### 5.1 Problem Statement & Architectural Choice
Users search using varied vocabulary:
- **Acronyms:** `"PMEGP"`, `"MUDRA"`, `"CGTMSE"`, `"NEEDS"`, `"TREAD"`, `"WEP"`.
- **Tamil Transliterations (Tanglish):** `"kadan"` (loan), `"udavi"` (assistance), `"thozhil"` (business), `"magalir"` (women), `"maniyam"` (subsidy), `"thittam"` (scheme).
- **Institutional Abbreviations:** `"MoMSME"`, `"KVIC"`, `"SIDBI"`, `"TANSIM"`.
- **Colloquial Aliases:** `"tea stall"`, `"street vendor"`, `"student startup"`, `"handicraft"`.

**Architectural Decision:** **Option A (Lexical Query Expansion)** was selected over Option B (pgvector online search, 300-500ms latency to Sydney) and Option C (on-device 90MB SLMs). It delivers +4–8% top-1 accuracy improvement with 0ms added latency, 100% offline safety, and zero API costs.

### 5.2 Tokenization & Expansion Mechanics
In both Dart and TypeScript engines:
1. Query tokens are extracted via `RegExp(r'[A-Za-z][A-Za-z0-9&-]{1,}|[஀-௿]{2,}')`.
2. Gating: tokens must be $\ge 3$ characters or in `shortTokenVocab` (`{'sc', 'st', 'tn'}`).
3. **Expansion Point:** Expansion occurs **before** catalog vocabulary gating:
   - If token `tok` exists in `query_expansion.json`, its expansion tokens are added to `forms`.
   - The set is then filtered against the 1,840-word catalog `_vocab`.
   - The original token is never discarded; expanded synonyms provide alternative pathways with naturally lower IDF weights.

### 5.3 Verified Expansion Dictionary (`assets/search/query_expansion.json`)
Every target expansion term is verified against the 1,840-word catalog vocabulary:

| Query Token | Expansion Target Words in `_vocab` | Target Scheme Example |
| :--- | :--- | :--- |
| `pmegp` | `["prime", "minister", "employment", "generation", "programme"]` | SCH000130 (TN130 PMEGP) |
| `mudra` / `pmmy` | `["pradhan", "mantri", "mudra", "yojana"]` | SCH000131 (TN131 PMMY) |
| `cgtmse` | `["credit", "guarantee", "fund", "micro"]` | SCH000007 (TN007 CGTMSE) |
| `needs` | `["entrepreneur", "enterprise", "development"]` | SCH000087 (TN087 NEEDS) |
| `tread` | `["trade", "entrepreneurship", "assistance", "development", "women"]` | SCH000185 (TN185 TREAD) |
| `wep` | `["women", "entrepreneurship", "platform"]` | SCH000216 (TN216 WEP) |
| `kadan` | `["loan", "credit", "கடன்"]` | Loan / Credit |
| `udavi` | `["subsidy", "grant", "assistance", "உதவி"]` | Assistance / Grant |
| `thozhil` | `["business", "enterprise", "industry", "employment", "தொழில்"]` | Enterprise |
| `magalir` | `["women", "மகளிர்"]` | Women |
| `stand up india` | `["stand-up", "women", "sc", "st", "enterprise"]` | SCH000181 (Stand-Up India) |
| `street vendor` | `["svanidhi", "street", "vendor", "vendors"]` | SCH000133 (PM SVANidhi) |
| `tea stall` | `["svanidhi", "vendor", "micro", "street"]` | SCH000133 (PM SVANidhi) |

---

## 6. Facet Filtering Subsystem: `applySchemeFilters`

`frontend/lib/models/scheme_filter.dart` contains the pure filtering engine used by both `SearchScreen` and `SearchResultsScreen`.

Filter state lives in `AppProvider.filters` (`Map<String, dynamic>`, empty by default — never seeded automatically by profile):

| Filter Key | Value Type | Matching Logic |
|---|---|---|
| `coverage` | `''` \| `'nationwide'` | Evaluates `schemeIsNationwide(scheme)` |
| `state` | `String` | `schemeIsNationwide(s) || s.state.contains(state)` |
| `schemeTypes` | `List<SchemeTypeGroup.id>` | Intersects scheme type, category, and benefit chips |
| `beneficiaries` | `List<String>` (`women`, `sc`, `st`, etc.) | Intersects `scheme.specialCategories` |
| `category` | `String` | Matches `category`, `sector`, or `searchKeywords` |
| `ministry` | `String` | Substring match on `sponsoringBody` or `issuingBody` |

**Helper Functions:**
- `schemeIsNationwide(scheme)`: Checks whether `scheme.state` normalizes to `india`, `national`, `nationwide`, `central`, `all states`, or starts with `allindia`/`panindia`. (The only reliable nationwide check).
- `activeSchemeFilterCount(filters)`: Computes the numeric badge count for the UI.
- `schemeFacetCount(...)`: Computes preview counts for chips in the filter sheet.

---

## 7. Recommendation Engine: "For Me" Eligibility Scorer

`frontend/lib/services/recommendation/recommendation_engine.dart` is a **pure, additive, explainable eligibility engine**. It is not a filter; it answers "how well does this scheme fit my profile?"

### 7.1 Recommendation Result
```dart
class RecommendationResult {
  final double score;                 // 0.0 .. 1.0
  int get percentage => (score * 100).round();
  final List<String> matchingReasons; // e.g. "Age: your age (24) is within 18–35"
  final List<String> missingRequirements;
  final List<String> missingDocuments;
}
```

### 7.2 Scoring Algorithm
```
score = 0.0
derive profile factors: age, isTN, isFemale, isSCST, isSpecialCommunity, isStudent
scan scheme.requiredDocuments → calculate missingDocuments[] against profile

switch (scheme.id):
  // ~15 hand-tuned high-impact schemes:
  NEEDS / PMEGP / STANDUP_INDIA / MUDRA / WEP / TREAD / KALAIGNAR_KAIVINAI / ...
      Encodes official eligibility rules: hard exclusions call disqualified()
      returning 0.0 immediately (e.g. non-TN resident on state-only scheme).
      Soft criteria add specific weighted points.

  default:
      // Generic evaluation for all other catalog schemes:
      + 0.20  if scheme scoped to profile's state
      + 0.15  if scheme is nationwide
      + 0.25  if scheme is gender-scoped and profile matches
      + 0.20  if scheme.specialCategories intersects profile community
      + 0.25  if profile age falls within scheme age gate
      + 0.25  if profile business stage matches scheme stage or role matches theme
      + 0.15  if profile education level satisfies scheme requirement
      + 0.20  if profile industry appears in scheme sector/category/keywords
      if score == 0 and no reasons: score = 0.30 (findable, but below For-Me bar)

// Document readiness factor:
if score > 0 and missingDocuments is not empty:
    score *= 0.8 + 0.2 * (docsHave / docsRequired)
return score.clamp(0.0, 1.0)
```

### 7.3 Thresholds & Integration
- **`forMeThreshold = 0.4`:** Schemes scoring $\ge 0.4$ qualify for the "For Me" view.
- **`hasEnoughProfileForRecommendation(profile)`:** Requires date of birth, gender, and state. If incomplete, the view renders a "Complete your profile" prompt rather than un-scored results.
- **`computeForMeView(master, profile, filters)`:** Filters master catalog schemes by eligibility ($\ge 0.4$), then applies active UI facet filters. It never dumps the entire catalog.

---

## 8. User Profile Lifecycle & Storage

### 8.1 Model & Storage Targets
`frontend/lib/models/user_profile.dart` (`UserProfile`) supports three serialization targets:
- `toJson()`: Local `SharedPreferences` cache (camelCase, preserves every field).
- `toSupabase()`: `public.profiles` database row (snake_case, columns only).
- `fromJson(map)`: Handles both camelCase (local cache) and snake_case (DB row).

Business-specific attributes (`businessStage`, `businessIndustry`, `fundingRequired`, `registrationNumbers`) map to `public.startup_profiles`.

### 8.2 Additive Rehydration (`mergeFrom`)
To prevent network or partial DB rows from blanking local profile data, rehydration uses an **additive merge**:
```
App Startup:
1. Load local cache via SessionCacheService.loadProfile() → instant profile available.
2. If authenticated → fetch public.profiles + public.startup_profiles.
3. Rehydrate: _profile = _profile.mergeFrom(dbProfile)
     - For each field, DB value wins ONLY if non-null and non-empty.
     - Where DB row is empty, local cached value is preserved.
     - Booleans OR together; dates/income prefer non-zero/non-null values.
4. Save merged result to local cache.
5. If local had fields missing in DB, updateProfile() pushes merged state back to Supabase.
```

---

## 9. Catalog Release, Distribution & Multi-Consumer Sync

### 9.1 The Release Lifecycle in Supabase
1. **Source of Truth:** PostgreSQL `catalog.*` schema (15 tables + `catalog.search_index`).
2. **Release Snapshot:** An immutable release is registered in `admin.catalog_releases` (`release_version`, `package_sha256`, `package_byte_size`, `schema_version`, `record_counts`, `published_at`, `is_current`).
3. **Discovery RPC:** Cheap single-row version check callable by unauthenticated clients:
   ```sql
   SELECT * FROM public.mss_current_release();
   ```
4. **Storage Bucket:** Release bundle published to Supabase Storage:
   `catalogs/releases/<release_version>/catalog_bundle.json.gz`

### 9.2 Consumer Sync Matrix

| Consumer | Mechanism | Sync Frequency | Fallback Strategy |
|---|---|---|---|
| **Flutter App** | `SchemeCatalogSyncService` checks `mss_current_release()`; downloads bundle to `mss_catalog_cache/` if version/hash changes. | Throttled to max 1 check per hour (in-memory timestamp). | Shipped asset `assets/catalog/catalog_bundle.json.gz`. Never blocks UI. |
| **Supabase Edge Function (`v1`)** | Direct SQL queries to `catalog.scheme` and `catalog.search_index` via service-role client. | Always live on every invocation. | None needed (stateless database queries). |
| **Saarthi Voice Agent (Python)** | `CatalogSyncService` checks `mss_current_release()`; downloads bundle to `saarthi-agent/data/`. | Throttled to max 1 check per hour (persisted to `last_sync_check.json`). | Pre-bundled files in Docker image. Never blocks agent startup. |

---

## 10. API Routing & Edge Functions

HTTP routes run on Deno via Supabase Edge Functions under `backend/supabase/functions/`:

| Function | Route / Role | Security & Access |
|---|---|---|
| `v1` | Primary API Gateway (`/v1/meta`, `/v1/health`, `POST /v1/search`, `/v1/schemes/{id}`) | JWT verified (`verify_jwt = true`). Rate-limited by IP via `public.api_rate_limits`. |
| `livekit-token` | Generates authenticated voice session tokens | Authenticated session required. Injects profile into LiveKit metadata. |
| `publishCatalog` | Broadcasts `catalog_sync` realtime event | Service-role key required. |
| `rollbackRelease` | Reverts current catalog to previous release | Service-role key required. |
| `sarvam-chat` | Text chat completions proxy to Sarvam AI | Authenticated session + per-user token ceiling. |
| `search`, `recommend` | **Retired** (`410 GONE`) | Kept as stubs informing legacy clients to upgrade. |

### CORS & Rate Limiting
- **CORS:** Computed dynamically per request via `_shared/cors.ts`. Origins are checked against an explicit allowlist (dev origins). Non-matching origins receive no CORS header. Wildcard `'*'` is strictly prohibited.
- **Rate Limiting:** `v1/index.ts` enforces persistent rate limits backed by `public.api_rate_limits` using atomic `INSERT ... ON CONFLICT DO UPDATE` sliding windows. Fails closed on database errors.

---

## 11. Data Integrity, Security & Failure Modes

### 11.1 Integrity Checks

| Asset | Verification Check |
|---|---|
| Shipped Catalog Bundle | `release.json.bundleSha256 == sha256(rootBundle.load(...))` |
| Downloaded OTA Bundle | Manifest `package_sha256 == sha256(downloaded_bytes)` before installation |
| Search Parity | `backend/catalog/search_parity_golden.json` evaluated against Dart and TypeScript engines in CI |
| Taxonomy Parity | SHA-256 identical across Flutter, Edge Function, and Saarthi data assets |
| Database RLS | `FORCE ROW LEVEL SECURITY` on all public profile and RBAC tables |

### 11.2 Failure Modes & Resilience

| Failure Scenario | System Behavior |
|---|---|
| Device completely offline | 100% discovery works. Catalog, search ranking, and recommendations operate locally. |
| Corrupt OTA update | `MssCatalogBundle.load()` detects hash error, logs warning, falls back to shipped asset. |
| Corrupt shipped asset | Returns empty list (`const []`) to prevent app crash; renders empty search state. |
| Supabase profile fetch fails | Local cached profile is preserved (`mergeFrom` never called with null); "For Me" remains operational. |
| Partial DB profile row | `mergeFrom` retains local values for blank columns, then writes full profile back to Supabase. |
| Cache wiped while logged in | On next launch, `getProfile()` rehydrates full profile from Supabase columns. |
| Query matches no schemes | Returns empty list (`[]`) triggering "No schemes found" UI state (never dumps catalog). |

---

## 12. Module Map & Parity Invariants

### 12.1 Module Map

```
frontend/lib/
├── models/
│   ├── mss_entity.dart               # Raw catalog entity model
│   ├── scheme_model.dart             # UI-facing scheme model
│   ├── scheme_filter.dart            # Pure filter matcher & schemeIsNationwide
│   └── user_profile.dart             # Profile model, 3 serializers, mergeFrom
├── services/
│   ├── catalog/
│   │   ├── mss_catalog_bundle.dart   # Compressed catalog bundle loader & cache
│   │   ├── mss_scheme_adapter.dart   # Entity -> Scheme projection
│   │   ├── scheme_repository.dart    # Singleton access point for schemes
│   │   ├── scheme_catalog_store.dart # OTA catalog installation & manifest store
│   │   └── scheme_catalog_sync_service.dart # Background update polling
│   ├── recommendation/
│   │   └── recommendation_engine.dart # Pure "For Me" eligibility scoring engine
│   └── search/
│       ├── hybrid_scheme_search.dart # Parity-locked search ranker
│       └── scheme_understanding_engine.dart # Natural language query understanding
└── providers/
    └── app_state_provider.dart       # State management & profile synchronization
```

### 12.2 Invariants — Do Not Break
1. **The Parity Triad Moves Together:** `HybridSchemeSearch.search()`, `search_engine.ts`, `hybrid_search.py`, `search_taxonomy.json`, and `search_parity_golden.json` must be updated together.
2. **Search is Never Profile-Weighted by Default:** Search relevance ranking is pure keyword/taxonomy matching. Profile signals apply only when the user toggles the "For Me" chip or selects "Best match for me" sort.
3. **Filters Never Auto-Seed from Profile:** `AppProvider.filters` initializes empty (`{}`). Profile data does not pre-populate search filters.
4. **`computeForMeView` Never Returns the Entire Catalog:** Only schemes scoring $\ge 0.4$ are returned. If the profile is incomplete, it returns an empty list with a prompt to complete the profile.
5. **Profile Rehydration is Additive:** `_profile = _profile.mergeFrom(dbProfile)` is mandatory. Direct assignment (`_profile = dbProfile`) is strictly forbidden.
