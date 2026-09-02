# Pagination and Filter Guide

Every value/constant below was read directly from `mss_api_rc1.py`/
`mss_api.py` -- exact numbers, not approximations.

---

## Pagination

**Cursor-based.** Request the first page with `{"limit": N, "offset": 0}`
(or omit `page` entirely for the default). Subsequent pages use the
`nextCursor` string returned in the previous response's `page` object --
do not construct or guess a cursor value; it's an opaque, base64-encoded
token embedding `(catalogVersion, sortField, lastId, offset)`.

**Limits:** `limit` must be an integer, `1..100` (`MAX_LIMIT = 100`).
Default `20` (`DEFAULT_LIMIT`) if omitted. Values outside this range →
`INVALID_REQUEST`.

**Response shape:**
```json
{"page": {"limit": 20, "offset": 0, "returned": 20, "total": 219, "nextCursor": "eyJ..."}}
```
`nextCursor` is `null` when there are no more pages -- use its presence,
not a comparison of `returned < limit`, to decide whether to request
another page (both are reliable, but `nextCursor` is the documented
contract signal).

**Cursor staleness:** the cursor embeds the catalog version at encode
time. If the catalog is updated between page 1 and a later page request,
decoding the old cursor raises `CURSOR_STALE` (see
`ERROR_HANDLING_GUIDE.md`). **On this error, restart from page 1** --
do not retry the same cursor.

**Search's own `topN`/legacy limit:** the base search call
(`mss_api.py`) separately accepts `topN`, 1-50 (`MAX_TOP_N`), default 10.
`mss_api_rc1.py`'s wrapping `search()` internally always requests up to
50 and applies `page.limit` afterward for consistency with every other
endpoint's pagination -- **use `page.limit`, not `topN`, when calling
through the RC1 layer** (the layer this whole handoff package targets).

## Filters

Applied strictly **after** ranking -- they narrow the result set without
ever changing which item is more relevant than another among survivors.

**Complete list** (`SCALAR_FILTERS`, verified exhaustive by reading the
source constant directly):

| Filter | Type | Notes |
|---|---|---|
| `status` | string or array of strings | e.g. `"active"`, `["active","unknown"]`. **Excluding `"unknown"` hides schemes whose real-world status is simply unrecorded (112 of 219) -- they are not confirmed closed.** The API emits a `filter_scope` warning if you exclude `unknown`; don't silence it, surface it. |
| `governmentLevel` | string or array of strings | e.g. `"state"`, `"central"` |
| `assistanceType` | string | |
| `department` | string | |
| `beneficiary` | string | |
| `cluster` | string | |
| `taxBenefit` | string | |
| `collateralRequired` | boolean | must be a real bool, not `"true"`/`1` |
| `minimumAssistance` | number | |
| `maximumAssistance` | number | |

Sending any key outside this list, or the wrong type for a typed key
(e.g. a string for `collateralRequired`), returns `INVALID_REQUEST` with
`error.detail` listing the supported filter names.

**Not a filter -- routes to eligibility matching instead:** `state`,
`district`, `sector`, `gender`, `enterpriseType`, `businessStage`, and
the other profile facets belong in the `profile` object (used by
`/v1/search`'s `profile` field and `/v1/eligibility`), not `filters`.
Sending one of these under `filters` is rejected as unknown -- this is a
deliberate design split (post-ranking predicate vs. eligibility
scoring), not an oversight.

## Sorting

`sort.by`: one of `"relevance"` (default), `"name"`, `"confidence"`.
Any other value → `INVALID_REQUEST`.

- `"relevance"` -- the search engine's own ranked order, untouched.
- `"name"` -- alphabetical by scheme name, then `schemeId` as a tiebreak.
- `"confidence"` -- highest confidence level first, then score, then
  `schemeId` as a tiebreak.

**Every sort mode is deterministic across repeated identical requests**
-- the `schemeId` tiebreak exists specifically so two items that would
otherwise compare equal don't reorder between calls.

## Combining filters + profile + sort + pagination in one request

All four are independent and composable:
```json
{
  "query": "loan",
  "profile": {"enterpriseType": "micro", "state": "IN-TN"},
  "filters": {"status": ["active", "unknown"], "collateralRequired": false},
  "sort": {"by": "confidence"},
  "page": {"limit": 20}
}
```
Order of application (verified from the source): rank by query/profile
→ filter → sort → paginate. Filtering never re-ranks; sorting (other
than `"relevance"`) discards the ranked order entirely and imposes its
own, still deterministically.
