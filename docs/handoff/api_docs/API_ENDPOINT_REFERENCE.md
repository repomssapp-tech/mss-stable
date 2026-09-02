# API Endpoint Reference

Every endpoint below is confirmed **live** in the reference implementation
(`catalog/mss_api_rc1.py`, which wraps and extends `catalog/mss_api.py`)
and covered by the existing `api_tests.py` suite (119/119 passing). This
is the authoritative endpoint list for this handoff -- if any other
document in this package disagrees, this one is correct (see the note at
the top of `API_CONTRACT.md`).

**HTTP method/URL columns below are the recommended REST mapping** --
the Python functions themselves are transport-agnostic (plain functions
returning dicts; see `FLUTTER_INTEGRATION_PLAN.md` Phase 1). No HTTP
framework is bound yet; whoever implements the transport layer chooses
the actual routing, but should follow this mapping unless there's a
strong reason not to.

---

## 1. Search

**Endpoint:** Search schemes by free-text query, optionally filtered/scoped by profile.
**HTTP method:** `POST`
**URL:** `/v1/search`
**Purpose:** The primary discovery surface -- Home and Search screens both use this.

**Request:**
```json
{
  "query": "women startup loan",
  "language": "en",
  "profile": {},
  "filters": {},
  "page": {"limit": 5, "offset": 0}
}
```
See `examples/search_request.json` for this exact request.

**Response:** See `examples/search_response.json` (full, real response --
not truncated). Key shape:
```json
{
  "contractVersion": "1.0.0",
  "contract": "search_response",
  "warnings": [],
  "page": {"limit": 5, "offset": 0, "returned": 5, "total": 50, "nextCursor": "…"},
  "data": {
    "query": {"text": "…", "language": "en", "detectedIntent": {"intents": [], "benefits": [], "communities": []}},
    "resultCount": 5,
    "results": [{
      "rank": 1, "schemeId": "SCH000021", "name": "…", "score": 9.6,
      "rankingSignals": {"components": {}, "weights": {}},
      "matchReasons": [{"dimension": "keyword", "detail": "…"}],
      "explanation": "…",
      "citations": [],
      "confidence": {"level": "…", "verificationStatus": "…"},
      "assistance": [],
      "authority": [],
      "applicability": null,
      "nextActions": []
    }]
  }
}
```

**⚠ Verified gotcha:** the request field is **`language`**, not `lang`
(the §7 Localization endpoint below uses `lang` instead -- the two
endpoints are inconsistent with each other; this was checked directly in
both functions' source, not assumed). Sending `"lang": "ta"` to `/v1/search`
is silently ignored and the query runs as `language: "en"` -- confirmed
by direct test. Also verified directly: `query.detectedIntent` populates
for English queries (`"startup loan"` → `benefits: ["loan"]`,
`intents: ["LOAN_REQUEST","STARTUP_SUPPORT"]`) but is **always empty for
Tamil-script queries**, tested against 3 real Tamil queries. Tamil search
still returns real ranked results -- only intent-tagging is English-only.

**Fields explanation:**
- `query.detectedIntent` -- what the search engine understood from the
  query text (industries, benefit types, communities, intents). Display
  only; do not use it to pre-fill filters silently.
- `results[].score` -- the ranking score. Auditable:
  `Σ(rankingSignals.components[k] × rankingSignals.weights[k])`
  reproduces it exactly.
- `results[].assistance`/`authority` -- **full** linked-record data
  (finance products, authorities), not just id references -- these are
  ready to render directly.
- `results[].applicability` -- `null` unless a `profile` was sent in the
  request.
- See `SEARCH_IMPLEMENTATION_GUIDE.md` for the full search flow.

**Error cases:**
| Code | Cause |
|---|---|
| `INVALID_REQUEST` | missing `query`, query >500 chars, unknown `profile` key, unknown enum value in a known key, bad `filters`/`page` shape |
| `CATALOG_UNAVAILABLE` | server-side load failure (503, retryable) |

See `examples/error_response.json` for a real `INVALID_REQUEST` body.

**Flutter usage:** Call on every keystroke-debounced query change and on
filter/profile change. Never call per-character without debouncing --
this is a full ranked search, not an autocomplete lookup.

---

## 2. Scheme Detail

**Endpoint:** Full relationship neighbourhood for one scheme.
**HTTP method:** `GET`
**URL:** `/v1/schemes/{schemeId}`
**Purpose:** Scheme Details screen's *metadata* tab (not its content --
see `SCREEN_DATA_MAPPING.md`).

**Request:** `{"schemeId": "SCH000021"}`

**Response:** See `examples/scheme_details_response.json` (real,
generated from this exact scheme). Key shape:
```json
{
  "schemeId": "SCH000021", "name": "…", "schemeStatus": "active",
  "finance": [{"id": "FIN000005", "name": "…", "relationType": "offers"}],
  "tax": [], "treds": [], "csr": [], "authority": [], "institution": [],
  "export": [], "cluster": [], "privileges": [], "enablement": [], "knowledge": [],
  "applicability": {}, "confidence": {}, "nextActions": [],
  "dataIntegrity": {"missingReferences": []}
}
```

**Fields explanation:** `finance`/`tax`/etc. are **id + name summaries
only** (`{id, name, relationType}`), NOT the full linked record --
different from `/v1/search`'s `assistance`/`authority` fields, which
ARE fully enriched. To show full finance-product detail for a linked
`id`, either call `GET /v1/finance-products/{id}` (§4 below) or look the
id up directly in the bundled `finance_catalog.json` (both work; the
endpoint is simpler, the bundle lookup is one HTTP round-trip cheaper).
`dataIntegrity.missingReferences` must always be `[]` -- non-empty means
a data incident, not a client-side condition to handle gracefully.

**Error cases:** `UNKNOWN_SCHEME` (404) if `schemeId` doesn't exist.

**Flutter usage:** Call once when a user opens a scheme's detail screen.
Combine with a bundle lookup (see `SCREEN_DATA_MAPPING.md` Scheme
Details) for the descriptive content this endpoint doesn't carry.

---

## 3. Eligibility / Applicability

**Endpoint:** Profile-based structured eligibility match across all schemes.
**HTTP method:** `POST`
**URL:** `/v1/eligibility`
**Purpose:** "Which schemes am I eligible for" -- a profile-driven list,
distinct from free-text search.

**Request:**
```json
{"profile": {"enterpriseType": "micro", "state": "IN-TN"},
 "onlyEligible": false, "limit": 50}
```

**Response:**
```json
{"profile": {"enterpriseType": "micro", "state": "IN-TN"},
 "resultCount": 3,
 "results": [{"rank": 1, "schemeId": "SCH000200", "name": "…",
   "eligible": true,
   "matchedCriteria": ["enterpriseType", "state"],
   "unknownCriteria": [],
   "excludedByAll": [],
   "excludedBy": null,
   "confidence": {}}]}
```

**Fields explanation -- tri-state, contractual:**
| Field | Meaning | Must NOT render as |
|---|---|---|
| `matchedCriteria` | scheme records this value | -- |
| `unknownCriteria` | scheme records **nothing** for this facet | "you qualify" |
| `excludedByAll` | **all** facets that exclude this scheme | -- |

`eligible == (excludedByAll == [])`, always -- a client can rely on this
invariant rather than re-deriving it.

**Error cases:** `INVALID_REQUEST` if `profile` is missing/empty, unknown
key, unknown enum value, or `limit` isn't a positive integer.

**Flutter usage:** The "Eligibility Check" / profile-filter feature. Do
not conflate with search -- this is structured facets only, no free text.

---

## 4. Finance Products

**Endpoint:** List all finance products, get one by id, or get all
linked to one scheme.
**HTTP method:** `GET`
**URL:** `/v1/finance-products` (list) · `/v1/finance-products/{financeId}` (detail) · `/v1/schemes/{schemeId}/finance` (by scheme)
**Purpose:** Finance screen.

**Request (list):** `{"page": {"limit": 20, "offset": 0}}`
**Request (by scheme):** `{"schemeId": "SCH000128"}`

**Response (detail shape, used in both list items and single-item
response):**
```json
{"financeId": "FIN000077", "schemeId": "SCH000128", "schemeName": "…",
 "assistanceClass": "financial_assistance",
 "type": "loan", "typeText": "Loan",
 "isRepayable": true, "isGuarantee": false,
 "amount": {"currency": "INR", "percentage": null, "maxInr": null,
            "maxText": "₹20 lakh", "minInr": null, "minText": null,
            "subsidyPercentage": null, "minimumAssistanceInr": null,
            "maximumAssistanceInr": null},
 "interestRate": {"percent": null, "text": null},
 "repaymentTenure": {"durationMonths": null, "tenureMonths": null},
 "collateral": {"status": "not_required|guarantee_covered|required|not_specified"},
 "conditions": [], "mode": null, "applicationUrl": "…",
 "providers": ["INST000001"], "description": "…",
 "verificationStatus": "…", "provenance": {}}
```

**Fields explanation:** `amount` carries the **same values under two
naming conventions** (`maxInr` AND `maximumAssistanceInr`, `percentage`
AND `subsidyPercentage`) -- both are populated together, deliberately,
so a client doesn't need to special-case which endpoint it called. Use
whichever naming is more convenient; they will never disagree.
`isGuarantee: true` (credit guarantee) and `collateral.status:
"not_required"` (collateral waiver) are **different facts** -- never
merge them into one "no collateral needed" flag.

**Coverage caveats (n=115, current):** `conditions` populated on 11/115,
`interestRate.percent` on 10/115, `repaymentTenure.tenureMonths` on
10/115, `mode` on 31/115. All correctly `null`/`[]` when not recorded --
never render these as "zero"/"none required."

**Error cases:** `UNKNOWN_ENTITY` (financeId not found), `UNKNOWN_SCHEME`
(schemeId not found on the by-scheme route).

**Flutter usage:** Finance screen list/detail, and the "Benefits" section
of Home/Scheme-Details cards (already embedded via `/v1/search`'s
`assistance[]`, so a separate call isn't always needed there).

---

## 5. Clusters / Tax / Privileges

**Endpoint:** List or get-by-id for each of 3 thin catalogs.
**HTTP method:** `GET`
**URL:** `/v1/clusters[/{clusterId}]` · `/v1/tax[/{taxId}]` · `/v1/privileges[/{privilegeId}]`
**Purpose:** Cluster screen and Tax screen.

**Request (list):** `{"page": {"limit": 20}}`
**Request (detail):** `{"clusterId": "CLUS000001"}` (or `taxId`/`privilegeId`)

**Response (cluster detail):**
```json
{"clusterId": "CLUS000001", "clusterName": "…",
 "sector": null, "sectorText": "…",
 "districts": [], "eligibleEnterprise": [],
 "financialSupport": {"applicable": null, "maxAmountInr": null},
 "nonFinancialSupport": {"applicable": true, "supportTypes": ["common_facility_center"], "description": "…"},
 "administeringAuthorityId": null, "relatedSchemeIds": [],
 "verificationStatus": "…", "provenance": []}
```

**Response (tax detail):**
```json
{"taxId": "TAX000001", "name": "…", "provisionKind": "…",
 "governmentLevel": "…", "appliesToMsme": true, "jurisdiction": "…",
 "exemptions": null, "deductions": null, "dueDates": null,
 "filingFrequency": null, "evidencedInSchemes": [],
 "verificationStatus": "…", "provenance": []}
```

**Response (privilege detail):**
```json
{"privilegeId": "PRIV000001", "name": "…", "privilegeType": "…",
 "privilegeClass": "statutory_right|scheme_benefit",
 "statute": "…", "summary": "…", "tenderBenefits": null,
 "delayedPaymentProtection": {}, "billDiscounting": null,
 "compliance": null, "verificationStatus": "…",
 "missingFields": [], "provenance": []}
```

**Fields explanation:** `financialSupport`/`nonFinancialSupport` are
**disjoint objects, each with its own `applicable` flag** -- this
structurally prevents a non-monetary support item (e.g. a shared
facility) from collapsing into `amount: 0`. Check `applicable` on each
independently.

**Data thinness (disclosed, not a bug):** 10 clusters, 13 tax
provisions, 1 privilege, total. A list response with ≤3 items carries a
`sparse_catalog` warning automatically.

**Error cases:** `UNKNOWN_ENTITY` if the requested id doesn't exist.

**Flutter usage:** Cluster screen, Tax screen. Always render the
disclosed-thinness warning where present -- don't let an empty/short
list look like a loading failure.

---

## 6. Relationships

**Endpoint:** Full edge list for any entity (not just schemes).
**HTTP method:** `GET`
**URL:** `/v1/relationships/{entityId}`
**Purpose:** Graph exploration -- "what else is connected to this
finance product / authority / etc." Useful for a "related items" UI
section beyond what Scheme Detail already surfaces.

**Request:** `{"entityId": "SCH000001"}`

**Response:**
```json
{"entityId": "SCH000001", "entityType": "scheme",
 "edgeCount": 3,
 "edges": [{"targetId": "FIN000001", "targetType": "finance_product",
            "targetName": "…", "relationType": "offers",
            "direction": "outbound", "generated": false, "resolved": true}],
 "traversable": ["finance","tax","treds","csr","authority","institution",
                 "export","cluster","privileges","enablement","knowledge"],
 "dataIntegrity": {"missingReferences": []}}
```

**Fields explanation:** `edges[].targetName` is included so a client can
render a related-item chip without a second lookup. `resolved: false`
would mean a dangling reference -- confirmed 0 across the whole catalog
(1710 edges, 0 unresolved).

**Error cases:** `UNKNOWN_ENTITY` if `entityId` doesn't exist anywhere in
the catalog.

**Flutter usage:** Optional/advanced -- most screens are served by the
more specific endpoints above; use this only for a generic "explore
connections" feature if one is built.

---

## 7. Localization

**Endpoint:** Field-level translation status and content for one entity.
**HTTP method:** `GET`
**URL:** `/v1/localization/{entityId}?lang=ta`
**Purpose:** The mechanism behind Tamil display -- see
`LOCALIZATION_IMPLEMENTATION_GUIDE.md` for the full flow.

**Request:** `{"entityId": "SCH000001", "lang": "ta"}`

**Response (Tamil available):**
```json
{"entityId": "SCH000001", "entityType": "scheme", "lang": "ta",
 "available": true,
 "fields": {"name": "…", "shortName": null, "summary": "…", "description": "…",
            "objective": "…", "eligibilityText": "…", "benefitsText": "…",
            "applicationText": "…"},
 "fallbackLang": null,
 "provenance": {"method": "llm_contextual_translation", "engine": "Claude",
                "status": "machine", "isApproved": false,
                "reviewRequired": true, "official": false}}
```

**Response (Tamil not available, e.g. `knowledge_catalog.json` body text):**
```json
{"entityId": "KNOW000001", "entityType": "knowledge_item", "lang": "ta",
 "available": false, "fields": {"title": null, "body": null},
 "fallbackLang": "en",
 "provenance": {"official": false}}
```

**Fields explanation:** `available` is a per-**record** flag (true if
`name`/`title` translated); individual `fields` values can still be
`null` even when `available: true` (field-level, not record-level
completeness). `provenance.isApproved` is `false` on every record in
this catalog today -- see `LOCALIZATION_IMPLEMENTATION_GUIDE.md` rule 4.

**Error cases:** `INVALID_REQUEST` (unsupported `lang`), `UNKNOWN_ENTITY`.

**Flutter usage:** See `LOCALIZATION_IMPLEMENTATION_GUIDE.md` -- this
endpoint exists for cases where a client needs translation *metadata*
(is this official? machine-generated?) separately from the translated
content itself, which is also available inline on every other endpoint
via each field being an `{en, ta}`-shaped... **correction, important:**
catalog fields are NOT wire-shaped as `{en, ta}` pairs on other
endpoints -- other endpoints return the single language requested via
`lang`. This dedicated endpoint is the one place both languages'
metadata can be inspected together. Most screens should pass `lang` to
the endpoint they're already calling (§1-6) rather than making a
separate localization call per field.

---

## 8. Meta / Metadata

**Endpoint:** Catalog version, entity counts, coverage stats.
**HTTP method:** `GET`
**URL:** `/v1/meta`
**Purpose:** Cache-invalidation check -- **the only call needed online**
in an offline-first design (compare `catalogVersion` to the cached tag;
re-download the bundle only on mismatch).

**Request:** none.

**Response:**
```json
{"catalogVersion": "…", "catalogChecksum": "sha256:…", "schemaVersion": "1.0.0",
 "entityCounts": {"scheme": 219, "finance_product": 115, "…": "…"},
 "supportedLanguages": ["en","ta"],
 "profileDimensions": {"sector": {"schemesWithData": 1, "allowedValues": ["manufacturing","service"]}},
 "localizationCoverage": {"scheme": 1.0, "knowledge": 0.357},
 "rankingWeights": {}, "deterministic": true}
```

**Fields explanation:** `profileDimensions` tells a client which
`profile`/`filters` values are worth offering in a picker (a dimension
with `schemesWithData: 0` should not be a dead-end filter option in the
UI). `localizationCoverage` per catalog -- use to decide whether to show
a "partial Tamil" indicator.

**Flutter usage:** Call at app startup and periodically; drive local
bundle refresh logic from `catalogVersion`.

---

## 9. Health

**Endpoint:** Liveness/diagnostic check.
**HTTP method:** `GET`
**URL:** `/v1/health`
**Purpose:** Ops/monitoring, not a screen data source.

**Response:**
```json
{"status": "ok", "rcVersion": "1.0.0-rc1", "contractVersion": "1.0.0",
 "catalogChecksum": "sha256:…", "catalogsLoaded": 13, "schemeCount": 219,
 "loadSeconds": 0.39}
```

**Flutter usage:** Not needed by the app directly -- useful for a
deploy-verification script or an ops dashboard.

---

## Endpoints NOT implemented (confirmed absent, not guessed)

Saved schemes / favorites, user accounts, and any AI-companion/chat
endpoint **do not exist** in `mss_api.py`/`mss_api_rc1.py` -- there is no
persistence layer in this backend at all (by design, see
`PRIVACY_RULES.md`). See `SCREEN_DATA_MAPPING.md` for what this means
for the Saved Schemes and AI Companion screens.
