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
As evaluated and documented in `SEARCH_OPTIONS.md`, three architectural paths were scoped for Phase 4:
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
