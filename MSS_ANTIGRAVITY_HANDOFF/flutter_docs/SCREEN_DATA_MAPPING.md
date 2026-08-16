# Screen Data Mapping

Every API field named below is confirmed live -- see
`api_docs/API_ENDPOINT_REFERENCE.md` for full request/response shapes.
Two screens (AI Companion, Saved Schemes) have **no backing API today**
-- documented honestly rather than mapped to something that doesn't
exist.

---

## Home Screen

**Required API:** `POST /v1/search` (a broad/empty or trending query --
this document does not prescribe what query text Home should send; that
is a product decision outside this handoff's scope).

**Fields:**
- `results[].schemeId`, `.name`, `.score` -- card identity/title
- `results[].matchReasons[]` -- "why recommended" chip/subtitle
- `results[].assistance[]` -- benefit summary badges (already fully
  enriched, no second call needed)
- `results[].confidence.level`/`.schemeStatus` -- trust/status indicator
  (never hide `status: "unknown"`, per `API_CONTRACT.md` §15 rule 5)
- `results[].nextActions[]` -- primary CTA button (`apply_online` etc.)

## Search Screen

**Required API:** `POST /v1/search`

**Fields:**
- Request: `query`, `language`, `profile`, `filters`, `page`, `sort` --
  see `api_docs/SEARCH_IMPLEMENTATION_GUIDE.md` and
  `api_docs/PAGINATION_AND_FILTER_GUIDE.md`
- Response: same result shape as Home, plus `page` for
  infinite-scroll/pagination and `query.detectedIntent` if the UI shows
  a "searching for: loan, women-owned" style chip (English queries only
  -- see the Tamil caveat in `SEARCH_IMPLEMENTATION_GUIDE.md` §4)

## Scheme Card (reusable component, used on Home/Search/Eligibility results)

**Required API:** whichever endpoint produced the result list
(`/v1/search` or `/v1/eligibility`) -- no separate call.

**Fields:**
- `schemeId`, `name`, `status`/`schemeStatus`
- `confidence` (level + `statusUnconfirmed` derived from `schemeStatus == "unknown"`)
- `assistance[0]` (or a summarized "starting from ₹X" derived from
  `assistance[].amount`) for a one-line benefit teaser
- `nextActions[0]` for the card's CTA

## Scheme Details

**Two sources, not one -- document this distinction explicitly, since
it's the single most likely point of confusion for a blind integrator:**

**Metadata (from API):** `GET /v1/schemes/{id}` -- relationship
summaries (`finance`/`tax`/`cluster`/etc. as `{id,name,relationType}`),
`applicability`, `confidence`, `nextActions`, `dataIntegrity`.

**Extended content (from the local catalog bundle,
`data/MSS_API_DATA_PACKAGE/scheme_catalog.json`, NOT from a live API
call):**
```
overview            → content.overview.summary / .description / .objective
eligibility          → content.eligibility.eligibilityText  (localization.ta for Tamil)
benefits              → content.benefits.benefitsText
documents             → content.requiredDocuments[]
application process   → content.applicationProcess
```
This split is deliberate (documented in the reference implementation's
own code comments, not a gap): re-shipping full scheme text on every
detail-screen API call would duplicate several MB of already-local
catalog data per request. Look these 5 fields up by `schemeId` directly
in the bundled JSON your app already has on disk. If your app does NOT
ship a bundled copy of `MSS_API_DATA_PACKAGE/`, this is a product
decision to make before Scheme Details can be built -- either bundle
the data package with the app, or request that a future API phase add a
"full content" endpoint (not built today; see
`api_docs/API_ENDPOINT_REFERENCE.md`'s closing note).

**Enrichment note:** `finance`/`tax`/etc. from `GET /v1/schemes/{id}`
are id-only stubs, unlike `/v1/search`'s fully-embedded `assistance[]`.
To show full finance-product detail on this screen, either call
`GET /v1/finance-products/{id}` per linked id, or look it up in the
bundled `finance_catalog.json` the same way as the 5 content fields
above.

## Finance Screen

**Required API:** `GET /v1/finance-products` (list) or
`GET /v1/finance-products/{id}` (detail) or
`GET /v1/schemes/{id}/finance` (scoped to one scheme)

**Fields:** `type`/`typeText`, `isRepayable`, `isGuarantee`,
`amount.{percentage,maxInr,maxText,minInr,minText}` (also available as
`subsidyPercentage`/`minimumAssistanceInr`/`maximumAssistanceInr` --
same values, alternate names, per `api_docs/API_ENDPOINT_REFERENCE.md`
§4), `interestRate`, `repaymentTenure`, `collateral.status`,
`conditions[]`, `applicationUrl`, `providers[]`.

**Coverage caveat to design around:** `conditions`/`interestRate`/
`repaymentTenure` are populated on only ~10/115 records -- the screen
must render a clear "not recorded" state for these, not a blank space
that looks broken.

## Tax Screen

**Required API:** `GET /v1/tax` (list) or `GET /v1/tax/{id}` (detail)

**Fields:** `name`, `provisionKind`, `governmentLevel`, `appliesToMsme`,
`jurisdiction`, `exemptions`, `deductions`, `dueDates`,
`filingFrequency`, `evidencedInSchemes[]`.

**Coverage caveat:** only 13 tax provisions total, catalog-wide. Design
for a short list, not a paginated browse experience.

## Cluster Screen

**Required API:** `GET /v1/clusters` (list) or `GET /v1/clusters/{id}` (detail)

**Fields:** `clusterName`, `sector`/`sectorText`, `districts[]`,
`financialSupport` (disjoint object, own `applicable` flag),
`nonFinancialSupport` (disjoint object, own `applicable` flag,
`supportTypes[]`), `relatedSchemeIds[]`.

**Coverage caveat:** 10 records total. `financialSupport.applicable` and
`nonFinancialSupport.applicable` must be checked independently -- a
cluster can have one, both, or neither.

## AI Companion

**No backing API exists.** Confirmed by inspecting the full method list
of `mss_api.py`/`mss_api_rc1.py` -- there is no chat, conversational,
or LLM-backed endpoint anywhere in this backend. If this screen is part
of the product scope, it needs an entirely separate service (and a
separate integration plan) -- it is **not** part of this handoff
package. Do not attempt to wire this screen to any endpoint documented
here; none of them serve it.

## Saved Schemes

**No backing API exists** for server-side persistence, and this is by
deliberate design, not an oversight -- `PRIVACY_RULES.md` (in
`MSS_API_INTEGRATION_PACKAGE/`) explicitly states any saved-schemes
feature belongs in a **separate user-data service** with its own
privacy review, kept apart from this read-only catalog-serving layer.

**What this means for Flutter today:** "Saved Schemes" must be
implemented as **local, on-device storage** (e.g. a local database
keyed on `schemeId`), re-hydrating each saved scheme's display data by
calling `GET /v1/schemes/{id}` (or reading the bundle, per the Scheme
Details section above) at render time. Do not build or expect a
`/v1/saved-schemes` endpoint -- it does not exist and building one is
explicitly out of scope for this API layer without a separate,
dedicated privacy-reviewed phase.
