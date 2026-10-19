# Search & Recommendation Algorithm — port spec

Source: `frontend/lib/services/hybrid_scheme_search.dart`, `recommendation/recommendation_engine.dart`, `models/scheme_filter.dart`, `docs/OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md` §4–8, `assets/data/search_taxonomy.json` and `assets/data/query_expansion.json` in this handoff package.

**Read the README's "open decision" section first** — this doc supports porting the algorithm to TypeScript (option B) OR just calling `/v1/search` (option A). If the team picks option A, most of this file is background context rather than something to implement.

## Overall formula

```
Score = Σ(Concept IDF × Field Weight) + Category + Benefit + Eligibility
Score = Score × StatusFactor
```

Sorted descending by score, ties broken by scheme ID ascending (deterministic — same input always produces the same order).

**All weights and vocab live in one canonical file, `search_taxonomy.json`** (copied into `assets/data/` in this package) — `WEIGHTS`, `STATUS_FACTOR`, `SHORT_TOKEN_VOCAB`, `RELATED_CONCEPTS`, plus 6 taxonomy tables. **A web port should read this same JSON file, not hardcode weight values** — it's already the single source of truth shared by the Dart, backend-TypeScript, and Python runtimes, and any web port becomes a 4th copy that must stay in sync with it.

## Tier-0: exact match (short-circuit)

Checked before the scored search runs. If any of these match, return **only** that scheme with score `1.0` and reason `"Exact scheme match"` — do not run the scored search at all:

1. Full normalized scheme name matches the query exactly.
2. The compacted query (whitespace/punctuation stripped) equals the scheme's acronym or short name.
3. Query tokens cover ≥60% of the scheme name's tokens.

Stop words never trigger this tier on their own.

## Scored search pipeline

1. **Normalize & tokenize** the query (see Query Expansion below).
2. **Score every scheme** on the weighted formula above; drop any with score ≤ 0.
3. **Sort**: score descending, then scheme ID ascending.
4. **Relative floor filter**: keep only results scoring ≥ `0.35 × maxScore` (drops long-tail noise once a strong match exists).
5. **Hard cap**: 25 results.
6. **Proper-name guard**: if the query has ≥3 meaningful tokens (looks like someone typing a specific scheme name) but the top score is < 4.0, return an **empty** result set rather than a low-confidence guess-list — this is a deliberate UX choice, not a bug, so replicate it.

## Query expansion

1. Tokenize with the pattern `[A-Za-z][A-Za-z0-9&-]{1,}` (Latin tokens) or 2+ char runs in the Tamil Unicode block.
2. Gate: only expand tokens that are ≥3 characters, OR are in the short-token allowlist `{sc, st, tn}` (from `SHORT_TOKEN_VOCAB` in the taxonomy file).
3. Look up each gated token in `query_expansion.json` (copied into `assets/data/` here) — e.g. Tanglish/regional terms like `kadan → loan/credit`, `magalir → women`.
4. Expansions are further gated against the catalog's own vocabulary (~1,840 words) before being added — don't expand into terms that don't actually appear in any scheme.
5. The **original token is always kept alongside its expansions**, never replaced.

## Filter facets (must match these exact string codes)

From `scheme_filter.dart` / `applySchemeFilters`:

| Facet group | Codes |
|---|---|
| `coverage` | `''` (any) \| `'nationwide'` |
| `state` | Free string; matched by substring + a nationwide fallback (see `schemeIsNationwide()` below) |
| `schemeTypes` | 7 fixed group IDs, each with its own keyword-needle list in code: `loans`, `subsidies`, `grants`, `guarantee`, `training`, `market`, `infra` |
| `beneficiaries` | 7 fixed codes: `women`, `sc`, `st`, `differently_abled`, `transgender`, `minority`, `ex_servicemen` |
| `category`, `ministry` | Free-text substring match |

`schemeIsNationwide()` normalizes the scheme's `state` field against a fixed exact-match set plus `allindia`/`panindia` prefixes — replicate this exact normalization so "nationwide" filtering produces identical results to the app.

**These codes must stay in sync with whatever backend/API the web filter UI talks to** — they're not just UI labels, they're the actual facet identifiers used in scoring and filtering logic across all runtimes.

## "For Me" eligibility scorer

From `recommendation_engine.dart`. Two tiers:

1. **~15 hand-tuned schemes** with hard-exclusion rules and bespoke weighted-point logic — these are scheme-specific overrides, not a general formula. If porting this exactly matters, these need to be enumerated individually from the source file rather than generalized.
2. **Generic default formula** for every other scheme, additive:

| Signal | Weight |
|---|---|
| State-scoped match | +0.20 |
| Nationwide scheme | +0.15 |
| Gender match | +0.25 |
| Community match | +0.20 |
| Age gate satisfied | +0.25 |
| Business-stage/role match | +0.25 |
| Education match | +0.15 |
| Industry keyword match | +0.20 |

- Floor: if zero reasons matched, score = `0.30` (never a hard zero once eligible at all).
- Document-completeness adjustment: `score × (0.8 + 0.2 × docsHave/docsRequired)` if the scheme requires documents the user hasn't indicated having.
- Clamp to `[0, 1]`.

**`forMeThreshold = 0.4`** — schemes scoring below this are excluded from "For Me" results.

**Gate before scoring at all:** `hasEnoughProfileForRecommendation` requires DOB + gender + state to be present on the profile. If not, show a "complete your profile" prompt instead of unscored/misleading results — don't silently score with missing data.

## Porting checklist

- [ ] Load `search_taxonomy.json` at runtime (don't hardcode weights) — same file both this handoff package and the main repo ship.
- [ ] Implement Tier-0 exact match as a short-circuit before scored search.
- [ ] Implement query expansion using `query_expansion.json`, with the vocab-gating step.
- [ ] Implement the exact post-filter sequence (floor → cap → proper-name guard) in that order — order matters for correctness.
- [ ] Use the same filter facet string codes verbatim.
- [ ] Implement `forMeThreshold = 0.4` and the profile-completeness gate before showing any "For Me" results.
- [ ] If exact numeric parity with the mobile app matters (e.g. a shared backend serving both), write parity tests against known query/scheme pairs, mirroring the existing `search_engine_parity_test.ts` pattern in `backend/supabase/functions/v1/`.
