# Search Implementation Guide

How Flutter should perform search against the MSS API. Every claim below
was tested directly against the live reference implementation
(`mss_api_rc1.py`) this phase -- not assumed from an older document.

---

## 1. The flow

```
Flutter (user types "women startup loan")
   ↓
API request  POST /v1/search  { query, language, profile, filters, page }
   ↓
Search engine (hybrid_search.py) -- keyword (IDF) + semantic-tag matching
   ↓
Ranking (mss_api.py) -- Σ(components × weights) = score, deterministic
   ↓
Response -- ranked results + matchReasons + citations + assistance + confidence
   ↓
Flutter renders result list
```

Nothing in this flow is asynchronous or eventually-consistent -- the same
request against the same catalog version always returns the same
response (`deterministic: true` in the envelope, and this is actually
enforced/tested, not just claimed).

## 2. The request shape

```json
{
  "query": "women startup loan",
  "language": "en",
  "profile": {},
  "filters": {},
  "page": {"limit": 20, "offset": 0}
}
```

See `examples/search_request.json` for a real request and
`examples/search_response.json` for its real, full response.

**Field notes:**
- `query` -- required, 1-500 characters. This is the only required field.
- `language` -- **exact key name, not `lang`** (verified directly in
  `mss_api.py`; see `API_ENDPOINT_REFERENCE.md` §1's gotcha callout).
  Controls the *response's* language-facing behavior; it does **not**
  restrict what script the query itself can be typed in.
- `profile` -- optional structured facets (`gender`, `enterpriseType`,
  `state`, etc. -- full list in `PAGINATION_AND_FILTER_GUIDE.md`).
  Omitting it or sending `{}` searches without eligibility scoping.
- `filters` -- optional post-ranking predicates (`status`,
  `minimumAssistance`, `collateralRequired`, etc.) -- see
  `PAGINATION_AND_FILTER_GUIDE.md` for the full set and validation rules.
- `page` -- `{limit, offset}` for the first page; use the returned
  `page.nextCursor` for subsequent pages (cursor-based, see
  `PAGINATION_AND_FILTER_GUIDE.md`).

## 3. Keyword search

The engine tokenizes `query` and matches against each entity's indexed
`tokens.en`/`tokens.ta` (both present in `search_index.json` for every
entity). Matched terms are weighted by IDF (rarer terms score higher) --
this is visible in `results[].rankingSignals.components.keyword`.

## 4. Semantic / tag-based matching

Separately from raw keyword overlap, the engine tags the query with
higher-level concepts (`detectedIntent.industries`/`.benefits`/
`.communities`/`.intents`) and matches against each entity's own semantic
tags (derived from its content at index-build time). This is what lets
`"women startup loan"` match a scheme whose text says "women
entrepreneurs" without an exact word match.

**Verified this phase: intent-tagging is English-only.** A Tamil-script
query (e.g. `"எம் எஸ் எம் ஈ கடன்"`) still keyword-matches correctly
against indexed Tamil tokens and returns real, ranked, relevant-looking
results -- but `detectedIntent` comes back with every field empty for
Tamil script, tested against 3 different Tamil queries. **Practical
consequence for Flutter:** don't build a "detected: loan request" chip
or similar UI cue that depends on `detectedIntent` for a Tamil-language
search bar -- it will always be empty there. Keyword-driven results and
`matchReasons[]` explanations still work in Tamil.

## 5. Filters

Applied **after** ranking, as predicates only -- they never change a
result's score or relative order among results that pass. See
`PAGINATION_AND_FILTER_GUIDE.md` for the full filter list and validation
rules (unknown filter key or wrong value type → `INVALID_REQUEST`).

## 6. Sorting

`sort.by`: `"relevance"` (default, the engine's own order) | `"name"` |
`"confidence"`. Every non-relevance sort appends `schemeId` as a
tiebreak internally -- pagination stays stable across pages regardless
of sort choice.

## 7. Pagination

Cursor-based, not offset-based, past page 1. See
`PAGINATION_AND_FILTER_GUIDE.md`.

## 8. Match score

`results[].score` is the sum of `rankingSignals.components[k] ×
rankingSignals.weights[k]` across all components (`keyword`, `semantic`,
`category`, `eligibility`, `benefit`). This is not a black box -- a
client (or a test) can recompute it from the response alone and it will
match exactly.

## 9. "Why matched" explanation

Two complementary sources, both in every result:
- `matchReasons[]` -- structured, one entry per matching dimension
  (`{"dimension": "keyword", "detail": "matched term(s) by rarity: …"}`).
  **Use this to build UI**, not the prose string below.
- `explanation` -- a single human-readable sentence combining the above.
  Safe to display directly, but **never parse it for data** (per
  `API_CONTRACT.md` §15 rule 8) -- it's prose, not a contract.

## 10. Tamil search example

**Query:** `"பெண்கள் தொழில் கடன்"` (women business loan)

**Request actually sent and tested:**
```json
{"query": "பெண்கள் தொழில் கடன்", "language": "ta"}
```

**Real response summary (from the live test this phase):**
```
rank 1  SCH000007  Annai Therasa Ninaivu Marriage Assistance Scheme for Orphan Girls   score 4.7842
rank 2  SCH000096  Mission Saksham Anganwadi and Poshan 2.0                            score 4.7842
rank 3  SCH000097  Mission Shakti                                                       score 4.7842
rank 4  SCH000149  Scheme for Adolescent Girls (SAG)                                    score 4.7842
rank 5  SCH000008  Annal Ambedkar Business Champions Scheme                             score 3.7546
```

**Honest read of this result, not glossed over:** keyword matching on
"பெண்கள்" (women) pulled in several women/child-welfare schemes whose
Tamil text contains that word, ahead of schemes more specifically about
business loans. `detectedIntent` was empty (per §4), so there was no
semantic boost toward "business"/"loan" concepts for this Tamil query the
way there would be for the English equivalent. **This is a genuine,
current search-quality gap for Tamil queries**, not a bug in the request
-- flag it for whoever owns search-ranking work; it is explicitly out of
scope to fix as part of this documentation-only handoff (search ranking
logic must not be modified per this task's boundaries).

Full response saved at `examples/tamil_response.json` for reference.

## 11. What NOT to build

- Don't debounce-search on every keystroke without a delay -- this is a
  full ranked search over the whole corpus, not a prefix-autocomplete
  index.
- Don't cache search results keyed only on `query` text -- `profile` and
  `filters` change the result set and must be part of any cache key.
- Don't build UI that assumes `detectedIntent` is always populated (§4).
- Don't scope search by the app's current UI language -- `language` in
  the request is display-only (`API_CONTRACT.md` §15 rule 7); a user
  should be able to type an English query while the app UI is in Tamil,
  and vice versa.
