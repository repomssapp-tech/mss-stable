# Work status — UI/UX & search remediation

**Branch:** `fix/discover-counts-and-search-filter` (pushed, in sync with origin at `c256fc0`)
**Base for PR:** `main` (already contains everything else; the branch adds exactly the 6 commits below)
**Last updated:** 2026-09-04
**Test baseline:** `flutter test` -> 226 passing · `flutter analyze` -> clean (1 pre-existing unrelated warning in `saarthi_welcome_screen.dart`)

---

## DONE this session

### Phase 3 — Discover counts + "For Me" filter
- **`3c4fe59` `fix(discover): derive counts from the catalog`**
  - New pure `DiscoverCounts` class in `categories_screen.dart` (`compute`, `schemesFor`, `matchesCategory/Ministry/State`). `_loadDynamicCounts()` now calls `getAllSchemes()` -> `DiscoverCounts.compute()` — no `getSchemesBy*`, no `/v1/search`, deterministic.
  - Drilldown handlers route through `DiscoverCounts.schemesFor(...)` -> `SearchResultsScreen(initialSchemes:)`.
  - `search_results_screen.dart` gained an `initialSchemes` param.
  - Corrected values: national baseline 153, TN 213, MH 154; MSME 69, Finance 5, Education/Health 0.
  - Test: `frontend/test/discover_counts_test.dart` (7 tests) — recomputes each grouping, asserts `compute()` matches, pins absolutes.
- **`b2d8d17` `fix(search): additive RecommendationEngine`**
  - `recommendation_engine.dart` `evaluate`: base `1.0 -> 0.0`; hard exclusions early-return `0.0`; additive weights awarded only on a substantive facet match. New API: `forMeThreshold` (0.4), `hasEnoughProfileForRecommendation`, `forMeSchemes`.
  - `search_screen.dart`: pure top-level `applyProviderFacetFilters`, `computeForMeView(...) -> ForMeViewResult`, `enum ForMeEmptyState { none, completeProfile, noMatches }`. FilterPanel facets now applied in all modes. Two distinct empty states.
  - Results: Female/SC/Tamil Nadu/25/UG/MSME -> **141/219** (was ~211); Karnataka 98/219; +FilterPanel state=Karnataka 20/219; empty profile 0.
  - Tests: `for_me_filter_shrinks_test.dart`, `for_me_profile_eligibility_test.dart`.

### Phase 4 — Semantic search (REPORT delivered; CODE pending, see below)
- **`4ecf0f5` `docs(search): SEARCH_OPTIONS.md`** — Options A/B/C scoped. **User chose Option A** (query expansion). Code not started.

### Phase 5 — Profile form defects
- **`1c45dc8` `fix(profile): visible +91 prefix, DOB placeholder, no step-2 overflow, strict 6-digit pincode`**
  - `+91` moved from `InputDecoration.prefixText` -> always-rendered `prefixIcon` slot.
  - DOB: `DD/MM/YYYY` placeholder; filled value now `dd/MM/yyyy`.
  - Step 2: counter stacked above heading (was a `spaceBetween` Row with no flexible child -> collided at 320 dp / 1.30x text scale); top-bar title + "OR FILL MANUALLY" divider made overflow-safe; step-4 section labels + choice chips ellipsis-bounded.
  - Pincode: digits-only + hard 6-cap input formatters; inline "Enter 6 digits"; Continue greys until every required field valid + pincode == 6.
  - Phone: same defect class — digits-only, exactly 10 before Continue.
  - Test: `frontend/test/profile_onboarding_overflow_test.dart` (all four steps at 320x568 / `TextScaler 1.30`, no RenderFlex overflow + the +91/DOB/pincode behaviours). Also fixes the previously-failing `production_surface_accessibility_test.dart > profile onboarding controls validate safely on narrow phone`.

### Phase 6 — Spacing consistency (PARTIAL by spec; FULL ROLLOUT pending, see below)
- **`33b2fa2` `refactor(spacing): introduce AppSpacing scale, migrate Discover + Profile flows`**
  - New `frontend/lib/utils/app_spacing.dart` — `AppSpacing.{none,hairline,xs,tight,sm,md,lg,xl,xxl,xxxl}` = `{0,2,4,6,8,12,16,20,24,32}`.
  - Migrated 7 files (Discover + Profile, ~365 refs) via one mechanical transform (`scratchpad/migrate_spacing.py`). Real pixel moves: `10->8` (29x), `14->16` (26x), both <=2 px, tests green.
  - Enforcement: `frontend/test/spacing_scale_test.dart` — fails on a bare spacing literal in the migrated flows (`// spacing-ok` escape hatch) and on any drift of the scale set.
  - `SPACING.md` — inventory (1157 sites / 40 files), scale rationale, full-rollout cost.
  - One literal kept: `SizedBox(width: 40)` in `about_you_profile_screen.dart` (centering counterweight, marked `// spacing-ok`).

### Phase 7 — Documentation truth pass (REPORT ONLY — explicitly out of scope for fixes)
- **`c256fc0` `docs: STALE_DOCS.md`** — grouped list. **User instruction: leave Phase 7 out of the fix work.** Not touching it.

---

## PENDING — requested, not yet done

### P1. Phase 4 Option A — query expansion  (NOT STARTED)

**Goal:** synonym / alias / abbreviation / transliteration expansion at query time so the lexical engine stops missing on vocabulary (PMEGP <-> full name, Tamil transliteration, colloquial -> concept). Expected 80.2% -> ~84-88% top-1. Fully offline, no model, no DB, no contract change.

**Design (from investigation this session):**
- Engine: `frontend/lib/services/hybrid_scheme_search.dart`.
  - `SchemeSearchTaxonomy` (`:13`) holds the controlled-vocab tables; `normalize()` (`:154`) + `expandRelated()` (`:170`).
  - Query -> concepts happens in `_queryConcepts()` (`:374`): each raw token becomes a `_Concept(forms:Set<String>, idf:double)`; `forms` is vocab-gated against `_vocab`; one shared IDF per concept (docFreq of the union).
  - `_keywordScoreIdf()` (`:411`) matches `concept.forms intersect scheme token fields`.
- **Integration point:** in `_queryConcepts()`, after building base `forms` for a token, if an expansion dictionary contains that token (or a phrase in the raw query), add its expansion tokens into `forms` **before** the `_vocab.contains` gate. This keeps the original token, folds extras in at the concept's (now broader, lower) IDF — i.e. "expansions add optional lower-weight tokens, never replace the query" (matches the SEARCH_OPTIONS.md write-up).
- **New asset:** `frontend/assets/search/query_expansion.json` — `Map<String, List<String>>` (query token -> extra single tokens). Add to `pubspec.yaml` assets. Load once (like the catalog bundle).
- **Server mirror:** `backend/supabase/functions/v1/search_engine.ts` — same expansion applied identically so online and offline agree (the TS engine is a field-for-field port). NOT yet read this session — read it first, find its query-normalize step, mirror the dictionary (inline or as a bundled JSON).
- **Test:** extend the search corpus test — a set of abbreviation / transliteration / colloquial queries that currently miss and should now hit top-1. Keep the existing 80.2% corpus green (no regression).

**Open sub-questions to resolve while implementing:**
1. Catalog token vocabulary is not yet enumerated — the per-scheme `tokens.en` / `schemeSearchProfile` live inside `search_index.json` (or the scheme records) in `catalog_bundle.json.gz`. **Extract the real token vocab first** so expansion values map to tokens that actually exist, otherwise the vocab gate drops them silently.
2. Multi-word aliases ("stand up india", "prime minister employment") — need phrase matching on the raw lowercased query, not just per-token. Decide: phrase table alongside the token table, or rely on hyphen-splitting only for v1.
3. Where to load the JSON on the client without an async gap in the sync `_queryConcepts` path.

### P2. Spacing — FULL ROLLOUT to the rest of the app  (NOT STARTED)

**Scope:** ~790 remaining `EdgeInsets` / `SizedBox` / gap literals across **33 files** (list + counts in `SPACING.md` section 5; biggest: `msme_module_details_screen.dart` 89, `home_screen.dart` 71, `voice_assistant_overlay.dart` 64, `scheme_details_screen.dart` 59, `saarthi_home_screen.dart` 58, `notifications_screen.dart` 56, `help_support_screen.dart` 54).

**How:**
1. Extend `TARGETS` in `scratchpad/migrate_spacing.py` to every file under `lib/` that has spacing literals. The script already: rewrites `EdgeInsets.*`/`SizedBox`/`Wrap`/grid spacing, snaps off-scale values, inserts the app_spacing import — **fix the relative-path depth per directory** (`lib/widgets/` needs `../utils/`, `lib/screens/` needs `../utils/`, `lib/screens/regular_mode/` needs `../../utils/`).
2. `flutter analyze` — expect 0 new errors.
3. Extend `_enforcedFiles` in `frontend/test/spacing_scale_test.dart` to the full set.
4. `flutter test` — full suite must stay green. Watch widget/golden tests for shifted layouts from the `10->8` / `14->16` snaps.
5. Manual QA gap: no screenshots. Flag any file where a snap looks risky; add `// spacing-ok` for a genuine layout measurement or hand-pick the step.

**Risk:** value snaps across 33 screens with no visual QA. Split into per-flow commits (companion mode / scheme detail / home / settings+legal / notifications / widgets) so review is manageable.

### P3. "For Me" threshold tuning + STARTUP_TN / KALAIGNAR_KAIVINAI  (NOT STARTED)

**Current state after `b2d8d17`:** filter now actually filters (complete profile ~64% pass, was ~96%). Not tuned to a target rate. `STARTUP_TN` and `KALAIGNAR_KAIVINAI` land ~0.30 for a matching Tamil Nadu user -> excluded from "For Me".

**To do:**
- Decide a target pass-rate for a fully specified profile (suggest ~25-40% of 219 — a recommendation surface should be selective) and adjust `RecommendationEngine` additive weights / `forMeThreshold` to hit it. File: `frontend/lib/engine/recommendation_engine.dart`.
- Fix the two named schemes so a matching TN user clears 0.4 — check their facet constraints in the catalog and the named-scheme `switch` in `evaluate()`; award for the state + sector + community match they legitimately have rather than special-casing the score upward.
- Update `for_me_filter_shrinks_test.dart` / `for_me_profile_eligibility_test.dart`: tighten the populated-count assertion to the new target band; add explicit fixtures for `STARTUP_TN` and `KALAIGNAR_KAIVINAI` asserting `score >= forMeThreshold` for a matching TN profile.

---

## Explicitly NOT in scope (do not do)
- **Phase 4 Options B (pgvector) and C (bundled embeddings)** — reported in `SEARCH_OPTIONS.md`; user chose A only.
- **Phase 7 doc edits** — user said leave Phase 7 out. `STALE_DOCS.md` stands as the deliverable.
- Do not run anything against production Supabase; do not deactivate API keys.

## Resume checklist
1. `cd "C:/development/MSS App/MSS_App" && git checkout fix/discover-counts-and-search-filter && git pull`
2. `cd frontend && flutter test` -> expect 226 passing.
3. Pick up P1 / P2 / P3 above. Separate commit per item. Keep the PR body in sync (which displayed numbers were wrong + since when: Discover counts wrong since `2b8c7d8` 2026-08-07; "For Me" never filtered since initial commit `389da9e` 2026-07-15).
