# Offline-First & Recommendation Architecture

**Scope.** How the MSS app serves scheme discovery — search, browse, filter,
and "For Me" recommendations — entirely on-device, and how the user profile
that powers recommendations is collected, stored, and kept in sync.

**Companion docs.** `docs/SEARCH_AND_CATALOG_ARCHITECTURE.md` (search
internals), `docs/DATABASE_ARCHITECTURE.md` (Supabase schema).

---

## 1. Principles

| Principle | What it means here |
|---|---|
| **Offline-first for discovery** | Every scheme read — search, category browse, detail, recommendations — is served from a bundled, integrity-checked catalog on the device. No network call is on the critical path. |
| **The server is for background sync, not queries** | `POST /v1/search` exists and is deployed but has **no runtime caller**; it is the planned path for the Saarthi voice agent. Live scheme queries are 100% local. |
| **Deterministic & explainable** | Search ranking and recommendation scoring are pure functions over versioned data (no per-request LLM call). The same input always yields the same output, and both produce human-readable reasons. |
| **One source of truth per concern** | Catalog → `MssCatalogBundle`. Scheme access → `SchemeRepository`. Search → `HybridSchemeSearch`. Facet filtering → `applySchemeFilters`. Eligibility scoring → `RecommendationEngine`. |
| **Profile: local cache is resilient, DB is authoritative-when-present** | The profile is cached in `SharedPreferences` and rehydrated from Supabase with a **merge**, not a blind replace, so a partial DB row or a cache clear never silently wipes scoring inputs. |

---

## 2. The catalog bundle — offline data layer

### 2.1 What ships

`frontend/assets/catalog/catalog_bundle.json.gz` — a single gzip'd JSON
object whose keys are catalog file names. It contains **all 15 catalog
files plus `search_index.json` and `manifest.json`**:

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

`frontend/assets/catalog/release.json` — the integrity descriptor:
`releaseTag`, `bundleSha256`, `entityCount`, `searchIndexCount`, and a
per-file SHA-256 map.

Current release: **`1.34.3-alpha`**, 219 schemes / 1220 entities / 971
search-index records.

### 2.2 How it loads — `MssCatalogBundle.load()`

`frontend/lib/services/catalog/mss_catalog_bundle.dart`

```
load()  ── once per app lifespan (memoised in a static Future) ──►
  │
  ├─ 1. Is there an "installed release"?
  │      app dir: .../app_flutter/mss_catalog_cache/<version>/catalog_bundle.json.gz
  │      + active_manifest.json pointing at it.
  │      This is a NEWER bundle fetched at runtime by the catalog-sync
  │      flow (see §2.3). Its SHA-256 was verified at install time.
  │      → decompress + parse, return.
  │
  └─ 2. Otherwise fall back to the SHIPPED ASSET
         rootBundle.load('assets/catalog/catalog_bundle.json.gz')
         → verify sha256(bytes) == release.json.bundleSha256   (skipped only
           under `overrideChecksumForTest: true`, used by unit tests)
         → decompress + parse, return.

Decompression + JSON parse run OFF the UI isolate via `compute()`.
```

- `MssCatalogBundle.invalidate()` clears the memoised future (used after a
  catalog sync so the next `load()` picks up the new installed release).
- **Practical consequence:** on a real device the app is usually serving a
  runtime-fetched `1.34.3-alpha` from `mss_catalog_cache/`, not the asset.
  Tests always use the asset with the checksum override.

### 2.3 What the bundle exposes

```dart
class MssCatalogBundle {
  List<MssEntity> get schemes;                 // byCatalog['scheme'] — 219 MssEntity
  MssEntity? getEntity(String id);
  Map<String, Map<String,dynamic>> searchProfiles;   // from search_index.json, keyed by entityId:
                                                     //   tokens.{en,ta}, schemeSearchProfile.*
  Map<String, List<String>> queryExpansions;         // from query_expansion.json
  // + relationship helpers: getAuthoritiesForScheme, getFinanceProductsForScheme, …
}
```

`MssEntity` (`lib/models/mss_entity.dart`) is an immutable wrapper that
**keeps the full raw JSON** (`entity.raw`) plus typed accessors
(`identity`, `content`, `search`, `getLocalizedName('en'|'ta')`,
`getLocalizedAttribute`). Nothing is flattened away.

### 2.4 The UI-facing model — `Scheme`

Screens never touch `MssEntity`. `MssSchemeAdapter.toScheme(entity, bundle,
langCode)` (`lib/services/mss_scheme_adapter.dart`) projects an `MssEntity`
into the flat `Scheme` model (`lib/models/scheme_model.dart`): `id`, `name`,
`state`, `governmentLevel`, `schemeType`, `category`, `sector`,
`targetBeneficiary`, `specialCategories`, `benefits`, `eligibility*`,
`requiredDocuments`, `glanceChips`, local(`nameTa`, `overviewTa`), etc.

> **Adapter quirks worth knowing:** a national scheme's `state` becomes
> `"All India"`/`"Pan-India"`; a non-central scheme with no `statesText`
> **defaults to `"Tamil Nadu"`**. `Scheme.governmentLevel` **defaults to
> `"Central"`** on the model, so it cannot be used to tell national from
> state schemes — use `schemeIsNationwide(scheme)` (§4.3) instead.

---

## 3. `SchemeRepository` — the single access point

`frontend/lib/services/scheme_repository.dart` — a singleton every screen
calls. Discovery is **offline-only**; the class imports `supabase_flutter`
solely for the `profiles` table (§7).

| Method | Backed by |
|---|---|
| `getAllSchemes()` | `bundle.schemes` → `Scheme` list (cached) |
| `searchSchemes(query)` | `HybridSchemeSearch.rank()` → `List<Scheme>` (score dropped) |
| `searchSchemeMatches(query, limit)` | `HybridSchemeSearch.rank()` → `List<SchemeSearchMatch>` (score + reasons kept; voice/conversational UIs) |
| `getSchemesByCategory / ByMinistry / ByState` | keyword `.where()` over the catalog, then `_rankByQuery` re-orders by `HybridSchemeSearch.scoreByQuery` without dropping members |
| `getSchemeById(id)` | `bundle.getEntity` → `Scheme` |
| `getCategoryCounts(profile)` | catalog counts for the "Browse Categories" cards |
| `getProfile / createProfile / updateProfile` | Supabase `profiles` + `startup_profiles` (§7) |

In-flight de-duplication + a 15-second memo cache wrap `searchSchemes` /
`searchSchemeMatches`.

---

## 4. Search subsystem — `HybridSchemeSearch`

`frontend/lib/services/hybrid_scheme_search.dart`. Offline port of
`Plan/catalog/hybrid_search.py`; see the search-architecture doc for the
full ranking maths. Summary here because recommendations sit next to it.

### 4.1 Two entry points

```
engine.search(query, {topN})          ── PARITY-LOCKED ──
   deterministic IDF-weighted concept scoring over search_index fields.
   Drops entries scoring <= 0. Sort: score desc, entityId asc.
   Golden-fixture tested (backend/catalog/search_parity_golden.json) and
   byte-for-byte mirrored by the Deno v1/search_engine.ts port.
   ⇒ never change scoring here without regenerating the golden + TS port.

HybridSchemeSearch.rank(query, bundle, {limit})   ── the wrapper the app uses ──
   1. exactEntityMatches(query)   → a name/acronym/alias LOOKUP tier
        tier 1: query == a normalised scheme name / alias
        tier 2: compact query == identity.acronym / shortName  (e.g. "pmegp")
        tier 3: multi-word query covering >=60% of one scheme's name tokens
        common single words (loan, subsidy, women, …) never trigger a tier.
        → if non-empty, return ONLY those (score 1.0, reason "Exact scheme match").
   2. else engine.search(query)
        → drop the weak tail:  keep score >= 0.35 * maxScore
        → cap:                 first 25
        → "looks like a proper-name query" guard: if >=3 meaningful tokens
          and maxScore < 4.0 → return [] ("not available"), so an absent
          scheme name yields the empty state instead of common-word noise.
```

`exactEntityMatches`, `_kRelevanceFloorRatio` (0.35), `_kMaxResults` (25)
and the name-lookup guard live in the **wrapper only** — `search()`,
`_scoreEntry`, `search_taxonomy.json` and the golden are untouched by them.

### 4.2 Query normalisation

- `SchemeSearchTaxonomy.normalize()` → concept tags (industries, benefits,
  collateral, treds, communities, intents) via substring match over
  `assets/search/search_taxonomy.json`.
- `_queryConcepts()` → phrase expansion (`assets/search/query_expansion.json`,
  e.g. `pmegp → prime minister employment generation programme`), per-token
  expansion, vocab-gated ±plural, IDF per concept (`ln((N+1)/(df+1))+1`).

### 4.3 `schemeIsNationwide(scheme)`

Lives in `lib/models/scheme_filter.dart`, used by search screens and the
filter matcher. Returns true when `scheme.state` normalises to a national
marker (`india`, `national`, `nationwide`, `central`, `all states`, …) or
starts with `allindia` / `panindia` — catching messy labels like
`"Pan-India / coir sector"`. **This is the only reliable national test**
(the model's `governmentLevel` default makes it useless).

---

## 5. Filter subsystem — `applySchemeFilters`

`frontend/lib/models/scheme_filter.dart` — **one pure matcher**, called by
both `search_screen` and `search_results_screen`.

Filter state lives in `AppProvider.filters` (`Map<String,dynamic>`, empty by
default — the profile never seeds it). Meaningful keys:

| key | value | matches |
|---|---|---|
| `coverage` | `''` \| `'nationwide'` | `schemeIsNationwide` only |
| `state` | a state name | `schemeIsNationwide(s) \|\| s.state contains <state>` |
| `schemeTypes` | list of `SchemeTypeGroup.id` | any selected group's needle-set hits `schemeType/category/benefitTypes/glanceChips` |
| `beneficiaries` | list of codes (`women`,`sc`,`st`,…) | `s.specialCategories` intersects |
| `category` | free text | keyword match on `category/sector/searchKeywords` (set by "Browse Categories" cards) |
| `ministry` | free text | tolerant contains on `sponsoringBody/issuingBody/name` (set by ministry cards) |

`SchemeTypeGroup`s (human buckets over the catalog's raw `schemeType`):
Loans & credit · Subsidies · Grants & equity · Guarantee · Training ·
Market & export · Infrastructure.

Helpers: `activeSchemeFilterCount(f)` (the `Filter · N` badge),
`hasActiveSchemeFilters(f)`, `schemeFacetCount(catalog, current, dim,
value)` (the "if I also pick this → N results" preview).

### 5.1 Filter UI

- **Strip** (above results, only while searching): `Filter · N` · `For Me` ·
  `Sort ▾`. Sort options: **Relevance** (keep incoming order), **Best match
  for me** (`RecommendationEngine.percentage` desc), **Scheme name (A-Z)**.
- **Sheet** (`lib/widgets/filter_panel.dart`): a fixed 2/3-column chip grid —
  **Coverage** (Nationwide / <profile state>, mutually-exclusive counts that
  add up to 219), **What it offers**, **For** (chips with < 4 schemes are
  hidden). "Use my profile" prefills coverage + infers Women/SC/ST/etc. from
  the profile's gender/community/disability/veteran. Footer: live
  `Show N schemes`.

---

## 6. Recommendation engine — "For Me"

`frontend/lib/engine/recommendation_engine.dart`. A **pure, additive,
explainable** eligibility scorer. It is *not* a filter — it answers "does
this scheme apply to me, and how well".

### 6.1 The result

```dart
class RecommendationResult {
  final double score;                 // 0.0 .. 1.0
  int get percentage => (score*100).round();
  final List<String> matchingReasons; // "Age: your age (24) is within 18–35"
  final List<String> missingRequirements;
  final List<String> missingDocuments;
}
```

### 6.2 `evaluate(profile, scheme)` — the algorithm

```
score = 0.0                       ── every scheme starts at ZERO ──

derive: age (from dob), isTN, isFemale (female|transgender),
        isSCST, isSpecialCommunity (sc|st|obc|minority|ews), isStudent
scan scheme.requiredDocuments → build missingDocuments[] from profile gaps

switch (scheme.id):                ── ~15 hand-tuned rules ──
  NEEDS / PMEGP / STANDUP_INDIA / MUDRA / WEP / TREAD / KALAIGNAR_KAIVINAI /
  STARTUP_TN / POST_MATRIC / MERIT_MEANS / INSPIRE / PRAGATI / …
      each encodes that scheme's real eligibility: hard exclusions call
      `disqualified()` → returns score 0.0 immediately (wrong state for a
      state-exclusive scheme, non-female for a women-only scheme, …);
      soft matches ADD the relevant facet weight.

  default:                         ── generic branch for every other scheme ──
      + _wState (0.20)          if scheme is scoped to the profile's state
      + _wNationalCoverage (0.15) if scheme is nationwide
      + _wGender (0.25)        if scheme is gender-scoped and the profile matches
      + _wCommunity (0.20)    if scheme.specialCategories ∩ profile categories
      + _wAge (0.25)          if scheme declares an age gate and age is in range
      + _wSectorStage (0.25) if scheme declares business stages and the
                              profile's stage (via _mapBusinessStage) is one,
                              OR the onboarding role ↔ scheme theme lines up
                              (founder ↔ "startup/incubator/…",
                               artisan ↔ "handicraft/handloom/…")
      + _wEducation (0.15)    if the scheme's education rule is satisfied
      + _wSector (0.20)       if profile.businessIndustry literally appears in
                              scheme.sector/category/keywords
      if score == 0 and no reasons:  score = 0.3   (findable, but well below
                                                    the For-Me bar — absence
                                                    of a match, not a match)

── after the switch ──
if score > 0 and missingDocuments not empty:
    score *= 0.8 + 0.2 * (docsHave / docsRequired)     ── readiness penalty
return score.clamp(0, 1)
```

Design intent baked into the weights: a scheme that is **silent** on a
facet earns nothing; a purely state-scoped scheme sits at 0.20, *below*
`forMeThreshold`, until a second signal (role/theme, age, gender, …) lifts
it over. This is deliberate — it stops "every TN scheme" from flooding
"For Me" for a TN user with a sparse profile.

### 6.3 Gates & thresholds

```dart
static const double forMeThreshold = 0.4;      // a scheme is "for me" at >= 0.4
hasEnoughProfileForRecommendation(profile)      // needs dob + gender + state
                                               // (else the view is "complete
                                               //  your profile", never scored)
```

### 6.4 Where the engine is used

| Caller | Use |
|---|---|
| `computeForMeView` (§6.5) | the "For Me" results set |
| `search_screen` / `search_results_screen` — `Sort: Best match for me` | order results by `percentage` (opt-in; never the default) |
| `SchemeCard` | the "96% Match · Highly relevant" badge (only shown when the For-Me chip is on) |
| `SchemeRepository.getRecommendedSchemes` | the home "Recommended for you" rail (its own lighter additive scorer starting at 0.5) |
| `AppProvider._recommendedSchemes` | recomputed on every profile change |

### 6.5 `computeForMeView` — composing the view

`lib/screens/regular_mode/search_screen.dart` (pure, unit-tested):

```
computeForMeView(master, profile, filters) →
  if !hasEnoughProfileForRecommendation(profile)
        → ForMeViewResult([], completeProfile)
  gated   = master.where(e => evaluate(profile, e).score >= forMeThreshold)
  filtered = applySchemeFilters(gated, filters)          // facet chips still apply
  → ForMeViewResult(filtered,
        filtered.isEmpty ? noMatches : none)             // NEVER the whole catalog
```

The "For Me" chip in the strip toggles `_activeFilter == 'For Me'`. When on,
`_applyFiltersAndSort` routes results through `computeForMeView` and shows
the match-% badge; when off, regular search is a pure relevance lookup with
zero profile influence.

---

## 7. Profile lifecycle & storage

### 7.1 The model

`frontend/lib/models/user_profile.dart` — `UserProfile` (mutable fields).
Three serialisers:

| method | target | notes |
|---|---|---|
| `toJson()` | local `SharedPreferences` cache | camelCase keys, every field |
| `toSupabase()` | `public.profiles` row | snake_case, only fields with a column |
| `fromJson(map)` | **both** local and DB rows | reads camelCase *and* snake_case, so one factory covers both |

Business fields (`businessStage`, `businessIndustry`, `existingBusiness`,
`fundingRequired`, `registrationNumbers`) map to a separate
`public.startup_profiles` row.

### 7.2 Supabase schema (project `houpzsxmwemoztpuigmo`)

```
public.profiles  (id = auth.users.id, RLS: auth.uid() = id)
  id · email · name · photo_url · language · navigation_mode · applicant_type
  state · district · city · pincode · house · area
  dob · gender · community · religion · qualification · education_level
  first_gen_graduate · disability · veteran · annual_income
  is_profile_complete · notifications · theme · phone
  created_at · updated_at · last_login_at

public.startup_profiles  (user_id → profiles.id, one active row per user)
  profile_name · description · industry · applicant_type · business_stage
  business_registered · funding_required_amount · funding_purpose
  is_first_generation_entrepreneur · registration_numbers · is_active · …
```

Migrations of record:
`backend/supabase/migrations/20260728150000_create_profiles.sql`,
`…_unify_user_profiles.sql`,
`…20260818010000_add_profile_religion_and_first_gen.sql`,
`…20260906010000_add_profile_education_level_and_address.sql`,
`…20260906020000_drop_redundant_profile_address_columns.sql`.

> Address is intentionally **granular** (`house / area / city / district /
> state / pincode`). A combined `address` column and duplicate `street` /
> `village` columns were removed — the onboarding form wrote one
> "Door/Street" value into both `house` and `street`.

### 7.3 The round-trip (why the profile doesn't reset)

```
STARTUP  (AppProvider._loadState)
  1. read local cache first:  SessionCacheService.loadProfile()
       → _profile is immediately the last-known-good profile
  2. if a Supabase session exists → _subscribeToProfile(uid) + a one-shot
       getProfile(uid) refresh

getProfile(uid)  (SchemeRepository)
  read public.profiles row
  + read the user's active public.startup_profiles row
  + merge the startup fields into the row map
  → UserProfile.fromJson(mergedMap)

REHYDRATE  (every auth-state change / login / background sync)
  _profile = _profile.mergeFrom(dbProfile)          ── NOT a blind replace
       mergeFrom: for each field, dbProfile wins ONLY if it carries a value;
                  where the DB row is blank (partial data), the local value
                  is kept. Bools OR together. dob/income: non-null/non-zero wins.
  SessionCacheService.saveProfile(_profile)          ── persist the merged result
  if !_profile.matchesStored(dbProfile):             ── DB was missing something
       SchemeRepository.updateProfile(_profile)      ── push it back; DB self-heals

WRITE  (onboarding step / edit)
  provider.updateProfile(next)  →  local saveProfile  +  toSupabase upsert
  startup_profiles is only upserted when the user actually gave business
  data (no more writing 'Technology' / 'Idea' / 'Student' placeholders).

CLEAR CACHE
  SessionCacheService.clearSession() → prefs.clear().
  Next startup: local cache empty → getProfile() rehydrates from Supabase.
  Because the DB now holds every collected field and mergeFrom is additive,
  the profile comes back whole, not blank.
```

**Fields that feed `RecommendationEngine`** — `state`, `gender`, `dob`
(→age), `community`, `religion`, `first_gen_graduate`, `disability`,
`veteran`, `annual_income`, `employment_status`, `education_level`,
`business_stage`, `business_industry` — all now persist and rehydrate. If
any of these silently blanks, "For Me" quality degrades with no error.

---

## 8. End-to-end flows

### 8.1 Text search

```
SearchScreen TextField
  → _onSearchTextChanged (300 ms debounce)
  → _triggerSearch(query)
      → SchemeRepository.searchSchemes(query)
          → HybridSchemeSearch.rank(query, bundle)     (§4.1)
      → _masterSearchResults = results  (engine relevance order)
  → _applyFiltersAndSort()
      1. applySchemeFilters(results, provider.filters)     (§5)  — skipped in For-Me mode
      2. if For-Me chip on → computeForMeView(...)          (§6.5)
      3. sort:  Relevance = keep order
                Best match for me = RecommendationEngine.percentage desc
                Scheme name (A-Z)
  → _searchResults → result cards
```

An acronym/name query (`PMEGP`, `CGTMSE`, `NEEDS`) returns exactly that
scheme via `exactEntityMatches`; a broad query (`MSME loans`,
`women entrepreneur schemes`) returns a bounded, floor-trimmed relevance
list; an unknown scheme name returns the "No schemes found" empty state.

### 8.2 Browse by category / ministry / state

```
Search idle → "Browse Categories" card  OR  smart_assessment_bottom_sheet
  → sets AppProvider.filters['category'|'ministry'|'state']
  → SearchResultsScreen(type: 'category'|…, title)
      → _loadBaseSchemes: SchemeRepository.getSchemesByCategory(title) etc.
      → _getFilteredSchemes: applySchemeFilters(base, provider.filters)
                             + text refine + sort
```

### 8.3 "For Me"

```
Strip "For Me" chip  OR  idle "For Me" highlight card
  → _activeFilter = 'For Me'
  → _triggerSearch('For Me')  → getAllSchemes()  → computeForMeView       (§6.5)
  → results = eligible (score >= 0.4) ∩ active facet chips
     empty-state = completeProfile | noMatches | none
```

---

## 9. Data integrity & provenance

| Mechanism | Guarantee |
|---|---|
| `release.json.bundleSha256` vs `sha256(asset bytes)` | the shipped catalog asset is intact |
| installed-release manifest SHA-256 (verified at install) | a runtime-fetched newer catalog is intact |
| `backend/catalog/search_parity_golden.json` + `search_taxonomy_parity_test.dart` (Flutter) + `v1/search_engine_parity_test.ts` (Deno) | the Dart `HybridSchemeSearch.search()` and the Deno `HybridSearchEngine` produce identical ids + scores for a frozen query set |
| `search_taxonomy.json` byte-identical in `frontend/assets/search/`, `backend/supabase/functions/_shared/`, `backend/catalog/` | the three engines share one ranking vocabulary |
| RLS `auth.uid() = id` on `public.profiles` | a user can only read/write their own profile row |

**Version note.** The bundled asset is `1.34.3-alpha` (219 schemes, 1,220 entities,
971 search records, released 2026-09-08). Tests run against the asset with
`overrideChecksumForTest: true`.

---

## 10. Failure modes

| Situation | Behaviour |
|---|---|
| No network, ever | Full discovery works — catalog + search + recommendations are local. Only profile *sync* and the (unused) `/v1/search` need the network. |
| Corrupt / unreadable installed release | `load()` logs and falls back to the shipped asset. |
| Corrupt shipped asset (checksum mismatch) | `load()` throws; `SchemeRepository` catches and returns `const []` → empty results, no crash. |
| Supabase `getProfile` fails / offline | local cached profile is retained (`mergeFrom` is never called with a null); "For Me" keeps working on cached data. |
| Partial / blank DB profile row | `mergeFrom` keeps the local value for every field the row leaves blank, then pushes the fuller profile back to the DB. |
| Cache cleared while logged in | local profile is empty on next start; `getProfile()` rehydrates it whole from Supabase (all scoring fields now have columns). |
| Profile too sparse for scoring | `hasEnoughProfileForRecommendation` false → "For Me" shows "complete your profile", never a scored list, never the catalog. |
| Search query matches nothing | `rank()` returns `[]` → "No schemes found for '<query>'" empty state (not a catalog dump). |

---

## 11. Module map

| Concern | File |
|---|---|
| Offline catalog load + integrity | `lib/services/catalog/mss_catalog_bundle.dart` |
| Raw entity model | `lib/models/mss_entity.dart` |
| Entity → UI model | `lib/services/catalog/mss_scheme_adapter.dart` (+ sub-parsers in `adapter/`) |
| UI scheme model | `lib/models/scheme_model.dart` |
| Single scheme access point | `lib/services/catalog/scheme_repository.dart` |
| Search engine (parity-locked core + `rank` wrapper) | `lib/services/search/hybrid_scheme_search.dart` |
| Search taxonomy / expansions | `assets/search/search_taxonomy.json`, `assets/search/query_expansion.json` |
| Natural language query understanding | `lib/services/search/scheme_understanding_engine.dart` (+ rules, extractor, evaluator) |
| Voice/conversational search | `lib/services/search/intelligent_scheme_search.dart` |
| Facet filter model + matcher + `schemeIsNationwide` | `lib/models/scheme_filter.dart` |
| Filter sheet UI | `lib/widgets/scheme/filter_panel.dart` |
| Recommendation engine | `lib/engine/recommendation_engine.dart` |
| "For Me" view composition + search screen | `lib/screens/regular_mode/search_screen.dart` (+ `search/` sub-widgets) |
| Results / drill-down screen | `lib/screens/regular_mode/search_results_screen.dart` |
| User profile model + 3 serialisers + `mergeFrom` | `lib/models/user_profile.dart` |
| Local profile cache | `lib/services/account/session_cache_service.dart` |
| App state, profile sync, controllers | `lib/providers/app_state_provider.dart` (+ 7 sub-controllers in `controllers/`) |
| Onboarding wizard | `lib/screens/regular_mode/basic_profile_screen.dart` (+ 4 modular step forms in `basic_profile/`) |
| Server search (deployed, no runtime caller) | `backend/supabase/functions/v1/search_engine.ts`, `v1/index.ts` |
| Profile tables | `backend/supabase/migrations/*profiles*.sql` |

---

## 12. Invariants — do not break

1. **`HybridSchemeSearch.search()` / `_scoreEntry` / `search_taxonomy.json` /
   the golden fixture** move together, across Dart *and* the Deno port.
   Lookup/floor/cap logic goes in the `rank()` wrapper, not `search()`.
2. **Regular search is never profile-weighted.** Profile influence is opt-in:
   the "For Me" chip and the "Best match for me" sort only.
3. **`AppProvider.filters` is never seeded from the profile.** It starts `{}`.
4. **`computeForMeView` never returns the catalog** — only a scored, gated,
   facet-filtered subset, or an empty list + an empty-state enum.
5. **Profile rehydration is `mergeFrom`, not `=`.** A DB fetch must not be
   able to blank a locally-known field.
6. **Every field that feeds `RecommendationEngine` has a `public.profiles`
   column and is in `toSupabase()` + `fromJson()`.** Adding a scored field
   means adding a column.
