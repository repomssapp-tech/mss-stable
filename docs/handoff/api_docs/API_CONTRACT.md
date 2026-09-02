# MSS API Contract

Wire-level contract for the MSS API layer, refreshed against the current
validated release (219 schemes, Tamil localization complete, search
index and applicability matrix regenerated). **Specification only -- no
implementation, no Flutter/Dart, no Supabase, no GraphQL.**

**Corrected in this handoff package:** an earlier draft of this document
marked several endpoints `[SPEC]` (not yet implemented). Direct
inspection of the reference implementation
(`catalog/mss_api_rc1.py`, verified this phase) found finance-product
detail, cluster/tax/privilege endpoints, relationships, filters,
sorting, pagination, and Tamil localization fallback are **all already
implemented and tested** (`api_tests.py`, 119/119 passing). Those
sections below are corrected to `[LIVE]`. See
`api_docs/API_ENDPOINT_REFERENCE.md` for the full per-endpoint detail
this correction is based on -- that document is the authoritative
reference; treat any remaining discrepancy here in its favor.

`contractVersion: 1.0.0` (unchanged -- nothing about the wire shape
changed this phase, only the underlying data and this document's
accuracy)

Legend: **[LIVE]** implemented, tested, and confirmed in
`mss_api_rc1.py` · **[SPEC]** specified, not yet implemented.

---

## 0. Envelope (every response)

```jsonc
{
  "contractVersion": "1.0.0",
  "contract": "<response type>",
  "catalogVersion": "1.33.0-alpha+stageb.pass1.batch1+...+searchprofile",
  "generatedAt": "2026-08-15T00:00:00Z",
  "deterministic": true,
  "warnings": [],
  "page": {"limit": 20, "returned": 20, "nextCursor": null},
  "data": { }
}
```

`data` **xor** `error` -- never both. `generatedAt` is operational;
exclude it from any equality/determinism check.

---

## 1. `POST /v1/search` **[LIVE]**

Unchanged shape from the original contract (see `API_INTEGRATION_CONTRACT.md`
§1 for the full response schema and worked example). Two things did
change with the underlying data this phase:

- The corpus now includes 219 schemes (was 217) -- `search_index.json`
  was regenerated and re-verified to contain all of them, including the
  2 schemes added in a prior phase.
- The request field controlling query/response language is
  **`language`** (`"en"` or `"ta"`), not `lang` -- confirmed by reading
  `mss_api.py::_validate_search_request()` and `mss_api_rc1.py::search()`
  directly. `language` is display-only and never scopes which script a
  query can be typed in -- a Tamil-script query works with `language`
  left at its default `"en"`, and vice versa.
- **Verified live, corrected from an earlier draft's claim:**
  `query.detectedIntent` (industries/benefits/communities/intents tagging)
  is populated for English-language queries only. Tested directly against
  4 real queries: `"startup loan"` produced
  `{"benefits": ["loan"], "intents": ["LOAN_REQUEST","STARTUP_SUPPORT"]}`;
  the Tamil-script queries `"எம் எஸ் எம் ஈ கடன்"`, `"மூலதன மானியம்"`, and
  `"பெண்கள் தொழில் கடன்"` all returned every `detectedIntent` field empty.
  Tamil-script search still returns real, ranked results (keyword
  matching works on the indexed Tamil tokens) -- only the *intent-tagging*
  layer is English-only today. See
  `api_docs/SEARCH_IMPLEMENTATION_GUIDE.md` for what this means for a
  Tamil-language "why matched" explanation.

**Score is auditable:** `Σ(components[k] × weights[k])` reproduces
`score`. Unchanged this phase -- no ranking weight was touched.

---

## 2. `GET /v1/schemes/{id}` **[LIVE]**

`data` = full graph neighbourhood. Linked entities are **summaries**
(`{id, name, relationType}`), not embedded records -- the client already
holds the catalog bundle (see `MSS_API_DATA_PACKAGE/`) offline.

```jsonc
{"schemeId": "SCH000001", "name": "…", "schemeStatus": "active",
 "finance": [{"id": "FIN000001", "name": "…", "relationType": "offers"}],
 "tax": [], "treds": [], "csr": [], "authority": [], "institution": [],
 "export": [], "cluster": [], "privileges": [], "enablement": [], "knowledge": [],
 "applicability": {}, "confidence": {}, "nextActions": [],
 "dataIntegrity": {"missingReferences": []}}
```

`missingReferences` **must be empty** -- confirmed 0/219 this phase
(`validate_cross_catalog.py`: 1710 edges, 0 asymmetric, 8883 references
resolved). Non-empty means a dangling edge; treat as a data incident.

Empty `treds`/`csr`/`cluster`/`privileges`/`enablement`/`knowledge`
means **"not linked"**, *not* "failed to load."

---

## 3. `POST /v1/eligibility` **[LIVE]**

Unchanged shape; same tri-state contract as before (see
`API_INTEGRATION_CONTRACT.md` §3):

| State | Meaning | Must NOT render as |
|---|---|---|
| `matchedCriteria` | scheme records this value | -- |
| `unknownCriteria` | scheme records **nothing** for this facet | "you qualify" |
| `excludedByAll` | **all** facets that exclude (not just the first) | -- |

`eligible == (excludedByAll == [])`, always.

**Applicability matrix coverage is now 219/219** (was 217/219 mid-phase,
before the 2 newer schemes' matrix rows were backfilled) -- every
scheme, without exception, participates in profile-based filtering.

---

## 4. `GET /v1/schemes/{id}/finance` · `GET /v1/finance-products[/{id}]` **[LIVE]**

```jsonc
{"financeId": "FIN000077", "schemeId": "SCH000128",
 "type": "loan", "typeText": "Loan",
 "isRepayable": true, "isGuarantee": false,
 "amount": {"currency": "INR", "percentage": null, "percentageText": null,
            "maxInr": null, "maxText": "₹20 lakh", "minInr": null, "minText": null},
 "mode": null,
 "applicationUrl": "…",
 "conditions": [],
 "collateral": {"status": "not_required|guarantee_covered|required|not_specified",
                "guaranteeSupported": null, "guaranteeSchemeText": null},
 "providers": ["INST000001"],
 "citations": []}
```

**Coverage, contractual -- clients must not misread absence** (n=115
finance products, current figures):

| Field | Populated | `[]`/`null` means |
|---|---|---|
| `type` | 115/115 | -- |
| `amount.maxText` | 86/115 | not recorded |
| `amount.maxInr` | 34/115 | not recorded |
| `mode` (applicationRoute) | 31/115 | **not recorded**, not "offline" |
| `conditions` | 11/115 | **not recorded**, NOT "no conditions apply" |
| `interestRate.percent` | 10/115 | not recorded |
| `tenure.tenureMonths` | 10/115 | not recorded |

These are the current, re-verified figures (higher than the original
contract's 0/115 for `conditions`/`interestRate`/`tenure` -- data quality
work in prior phases closed part of this gap; it is not fully closed).

`collateral.status` -- `guarantee_covered` is **not** `not_required`. A
credit guarantee and a collateral waiver are different facts. Never
merge them in UI or filters.

**New this phase:** `finance_catalog.json` product `name` fields are now
100% Tamil-localized (was 0%) via a compositional fix -- see
`LOCALIZATION_CONTRACT.md`. A client requesting `language="ta"` on a finance
product now gets a real Tamil product name, not a fallback.

---

## 5. `GET /v1/clusters[/{id}]` · `/v1/tax[/{id}]` · `/v1/privileges[/{id}]` **[LIVE]**

Uniform list/detail shape, unchanged (see `API_INTEGRATION_CONTRACT.md`
§5). **Coverage numbers updated:** clusters **10** (was 2 -- 8 more CFC
records were added in a prior phase and are now correctly reflected in
`manifest.json`'s record count), privileges **1**, tax **13**. Still
genuinely thin disclosure -- `meta.entityCounts` should continue to
expose this so a client renders "limited coverage" rather than implying
exhaustiveness.

---

## 6. `GET /v1/relationships/{id}` **[LIVE]**

Unchanged shape. Graph invariants: **0 dangling references**, **0
asymmetric edges** -- re-confirmed this phase at 1710 edges / 8883
references / 0 asymmetric.

---

## 7. Citation object (used everywhere)

Unchanged -- see `API_INTEGRATION_CONTRACT.md` §7 for the full shape and
`sourceTier` table. `externalSource: false` ⇒ never render a "verified"
badge; this rule is unaffected by anything in this phase.

---

## 8. Next actions

Unchanged shape and hard rules (see `API_INTEGRATION_CONTRACT.md` §8).
Status counts, current: **active 95**, **unknown 112**, **closed 12**
(out of 219; the 2 newer schemes are both `active`, so the closed/unknown
counts are unchanged from the 217-scheme baseline).

---

## 9. Profile object

Current coverage (out of 219 schemes; the 2 newer schemes carry real
structured eligibility data, which is why `gender`/`community` moved):

| Field | Coverage | Notes |
|---|---|---|
| `gender` | 77/219 | `female` |
| `specialCategory` | 72/219 | `women, sc, st, differently_abled, transgender, minority, ex_servicemen` |
| `enterpriseType` | 37/219 | `micro, small, medium` |
| `businessStage` | 33/219 | `new, existing, expansion, diversification` |
| `state` | 36/219 | `IN-TN` |
| `sector` | 1/219 | `manufacturing, service` |
| `community` | **1/219** | now accepted as a real enum (`SC`, `ST`) rather than always `FILTER_NO_COVERAGE` -- see below |
| `district` | **0/219** | still accepted → `FILTER_NO_COVERAGE` |

**Changed this phase:** `community` was zero-coverage in the original
contract (always warned `FILTER_NO_COVERAGE`). It is not anymore --
SCH000218 (Stand-Up India) carries real `community: [SC, ST]` structured
eligibility. A client that hardcoded "community always warns" must
update that assumption; `district` remains genuinely zero-coverage and
still warns.

Unknown key or unknown enum ⇒ `INVALID_REQUEST`. **Never persisted,
never logged** -- see `PRIVACY_RULES.md` in this package.

---

## 10-12. Filters · Sorting · Pagination **[LIVE]**

Unchanged -- see `API_INTEGRATION_CONTRACT.md` §10-12. `status` defaults
to `["active","unknown"]`; excluding `unknown` now hides 112/219 (not
112/217, count unchanged in absolute terms since both new schemes are
`active`).

---

## 13. `GET /v1/meta` **[LIVE]**

```jsonc
{"catalogVersion": "…", "catalogChecksum": "sha256:…", "schemaVersion": "1.0.0",
 "entityCounts": {"scheme": 219, "finance_product": 115, "authority": 124,
                  "institution": 83, "knowledge_item": 28, "treds_platform": 16,
                  "csr_provision": 16, "tax_provision": 13, "export_benefit": 13,
                  "business_enablement": 4, "cluster_assistance": 10,
                  "msme_privilege": 1, "applicability_matrix": 219},
 "supportedLanguages": ["en","ta"],
 "profileDimensions": {"sector": {"schemesWithData": 1,
                                  "allowedValues": ["manufacturing","service"]},
                       "community": {"schemesWithData": 1,
                                     "allowedValues": ["SC","ST"]}},
 "localizationCoverage": {"scheme": 1.0, "finance": 1.0, "tax": 1.0,
                          "cluster_assistance": 1.0, "csr": 1.0, "treds": 1.0,
                          "msme_privilege": 1.0, "business_enablement": 1.0,
                          "common": 1.0, "authority": 1.0, "institution": 1.0,
                          "export": 1.0, "knowledge": 0.357},
 "rankingWeights": {}, "deterministic": true}
```

`entityCounts.enterprise_classification` is deliberately absent --
`enterprise_classification_catalog.json` is not part of the served
package (see `API_PACKAGE_VALIDATION_REPORT.md` for why it was traced
out). `localizationCoverage` -- the original contract marked this
`[SPEC]`/all-zero; it is now real, current data, mostly 100%, with
`knowledge` at 35.7% as the one honest holdout (see
`LOCALIZATION_CONTRACT.md`).

**Architecture correction (2026-08-17):** this endpoint is the
"lightweight metadata check" `RELEASE_MANIFEST_SPECIFICATION.md` §5
requires -- the app must be able to determine whether a catalog update
exists without downloading the full catalog, and `/v1/meta` already
satisfies that shape (small payload, no full-catalog transfer). What
this endpoint does **not** yet expose is release-artifact identity
(`releaseVersion`, `packageSha256`) as distinct from the live
`catalogVersion`/`catalogChecksum` shown above -- those two are computed
differently and serve different purposes; see
`architecture_docs/HASH_VERIFICATION_SPECIFICATION.md` §2 for why they
must not be conflated. A future implementation should extend this
response (or add a sibling endpoint) with the release-manifest fields,
without changing the existing `catalogVersion`/`catalogChecksum`/
`entityCounts` shape client code already depends on. See
`architecture_docs/OFFLINE_CLOUD_SYNC_ARCHITECTURE.md` for the full
corrected sync architecture this feeds into.

---

## 14. Errors

Unchanged -- see `API_INTEGRATION_CONTRACT.md` §14.
`INVALID_REQUEST` 400 · `UNKNOWN_SCHEME` 404 · `CURSOR_STALE` 409 ·
`CATALOG_UNAVAILABLE` 503 · `INTERNAL_ERROR` 500. Only 503/500 retryable.

---

## 15. Client obligations (non-negotiable, unchanged)

1. Never render `externalSource: false` as a verified citation.
2. Never treat `unknownCriteria` as "you qualify".
3. Never treat `guarantee_covered` as `not_required`.
4. Never treat empty `conditions` as "no conditions apply".
5. Never badge `status: unknown` as active -- and never hide it.
6. Never offer an application path when `status: closed`.
7. Never scope search by UI language.
8. Never parse `explanation` prose for data -- use `citations[]`/`matchReasons[]`.
9. Tolerate unknown response fields (forward compatibility).
10. Never persist a `profile` server-side.
11. **New:** never assume `community`/`district` are always zero-coverage
    -- check `meta.profileDimensions` at runtime; `community` now has
    real (if thin) data.
12. **New:** never assume `language="ta"` degrades to English for a
    scheme, finance product, or any of the other 10 fully-localized
    catalogs -- it only degrades for `knowledge_catalog.json` `body`
    text today, and that degradation is explicit via `warnings[]`/
    `available: false`, never silent.

---

## 16. Implementation status

Same 4 LIVE endpoints as the original contract; the 6 SPEC endpoints are
still unimplemented. **This handoff package changes the data underneath
the contract, not the contract's shape or the implementation status.**
See `FLUTTER_API_IMPLEMENTATION_PLAN.md` in this package for the
recommended next-phase implementation sequence -- planning only, no code
written.

**Not in scope and must not be started from this document:**
Flutter/Dart, UI/UX, Supabase connection, GraphQL, search ranking
changes.

---

## 17. Known gaps carried into this contract (updated)

- Finance `interestRate`/`tenure`/`conditions`: still thin (10-11/115),
  improved from the original contract's 0/115 but not closed.
- Clusters: 10 (was 2) -- improved coverage, still thin relative to the
  likely real universe of CFC projects.
- Tamil: ~99% across 13 catalogs (was 0% across 11 catalogs) --
  see `LOCALIZATION_CONTRACT.md` for the one remaining gap
  (`knowledge_catalog.json` body text, 18/28 records).
- `district` profile filter: still zero-coverage.
- Search: a bare Tamil "GST"-style query with no scheme keyword to match
  against returns empty -- see `SEARCH_INTEGRATION_CONTRACT.md`.

Every gap above is exposed through `warnings[]`, `meta`, `missingFields[]`
or an explicit `null`/`false`. **None is closed by inventing data.**
