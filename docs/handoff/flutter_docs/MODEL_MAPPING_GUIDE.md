# Model Mapping Guide

`flutter_models/mss_contract.dart` **already exists and already
implements** `fromJson` parsing for every response shape in
`api_docs/API_CONTRACT.md`. This document is a reference for how JSON
wire fields map onto that existing Dart code -- **no Dart file is
touched by this document or this handoff.**

*(Referenced elsewhere as "FLUTTER_DATA_MAPPING.md" -- this is the
same document; there is no separate file by that name in this handoff
package.)*

---

## Architecture correction (2026-08-17) -- release metadata models

`UpdateMetadata` (`mss_contract.dart`) and `MssMeta` (`mss_models.dart`)
already have `catalogVersion`/`catalogChecksum` fields and an
`isStaleAgainst(cachedCatalogVersion)` method -- this is the **live
row-checksum** comparison (`public.mss_catalog_meta()`'s aggregate),
not yet the **release-artifact** identity
(`releaseVersion`/`packageSha256`) described in
`architecture_docs/RELEASE_MANIFEST_SPECIFICATION.md`. These are two
different comparisons for two different purposes -- see
`architecture_docs/HASH_VERIFICATION_SPECIFICATION.md` §2. If/when
`/v1/meta` is extended with release-manifest fields (per
`API_CONTRACT.md` §13's correction note), `UpdateMetadata`/`MssMeta`
will need new fields for them; do not overload the existing
`catalogVersion`/`catalogChecksum` fields to mean both things.

---

## `SchemeResult` (search/eligibility result item)

Read directly from `mss_contract.dart`'s `SchemeResult.fromJson`:

| JSON key(s) | Dart field | Notes |
|---|---|---|
| `rank` | `rank` (`int`) | |
| `schemeId` | `schemeId` (`String`) | |
| `name` | `name` (`String`) | |
| `status` **or** `schemeStatus` | `status` (`SchemeStatus`) | Already handles both key names -- `/v1/search` results use `status`, `/v1/schemes/{id}` uses `schemeStatus`; the model accepts either without you writing any glue code |
| `score` **or** `matchScore` | `matchScore` (`double`) | Same dual-key tolerance already built in |
| `rankingSignals` | `rankingSignals` (`RankingSignals`) | |
| `matchReasons` | `matchReasons` (`List<MatchReason>`) | |
| `explanation` | `explanationText` (`String`) | Key name changes (`explanation` → `explanationText`) -- already handled |
| `assistance` | `assistance` (`List<FinanceBenefit>`) | |
| `applicability` **or** `eligibility` | `eligibility` (`EligibilityMatch?`) | Already handles both |
| `authority` | `authority` (`List<AuthorityRef>`) | |
| `citations` | `citations` (`List<Citation>`) | |
| `applicationState` | `applicationState` | Derived from `status`/`nextActions` if the key is absent from the response -- **`applicationState` is not currently emitted by any live endpoint**, so this derivation path is what actually runs in practice; verify this still gives the right result if `applicationState` is ever added to the API later |
| `nextActions` | `nextActions` (`List<NextAction>`) | |
| `confidence` | `confidence` (`DataConfidence?`) | |

## `FinanceBenefit`

Maps `/v1/search`'s `assistance[]` entries and `/v1/finance-products`'
detail response. Field-for-field mapping is direct (no key renaming) --
see `mss_contract.dart` line ~556 for the exact list: `type`, `typeText`,
`isRepayable`, `isGuarantee`, `amount` (nested `BenefitAmount`),
`mode`, `applicationUrl`, `conditions`, `collateralStatus`, `providers`.

**One naming note:** the API's `/v1/finance-products` response (§4 of
`api_docs/API_ENDPOINT_REFERENCE.md`) uses `collateral.status` (nested
object); the search-embedded `assistance[]` entries use a flatter
`collateralStatus` (per `mss_api.py::_finance_assistance()`). Confirm
which shape `FinanceBenefit.fromJson` expects before wiring the
finance-products endpoint specifically -- it was written against the
search-embedded shape first.

## `BenefitAmount`

`currency`, `percentage`, `percentageText`, `maxInr`, `maxText`,
`minInr`, `minText` -- direct mapping, no renaming. The
`/v1/finance-products` endpoint's alternate names
(`subsidyPercentage`/`minimumAssistanceInr`/`maximumAssistanceInr`) are
**not** currently consumed by this model -- they carry the same values
as `percentage`/`minInr`/`maxInr`, so no data is lost by ignoring them,
but don't expect `BenefitAmount.fromJson` to read them.

## `DataConfidence`

`level` (`ConfidenceLevel`), `verificationStatus`, `schemeStatus`,
`missingFieldCount`, `basis` -- direct mapping. Exposes
`statusUnconfirmed` as a computed getter
(`schemeStatus == SchemeStatus.unknown`) -- use this getter, don't
re-derive it, so the "never badge unknown as active" rule
(`API_CONTRACT.md` §15 rule 5) stays enforced in exactly one place.

## `Citation`

`sourceName`, `organization`, `url`, `retrievedDate`, `sourceTier`,
`sourceId`, `externalSource`, `origin`, `isPrimary` -- direct mapping.
Exposes `isLiveOfficialFetch` (`sourceTier == 5 && externalSource`) and
`isOpenable` (`url` non-empty) as computed getters -- use these, don't
re-derive (enforces `API_CONTRACT.md` §15 rule 1: never render
`externalSource: false` as verified).

## `AuthorityRef`, `MatchReason`, `NextAction`, `RankingSignals`,
`DetectedIntent`, `ResponseWarning`

All direct field-for-field mappings from their respective JSON shapes in
`api_docs/API_ENDPOINT_REFERENCE.md` -- no renaming, no derivation
beyond what's noted above. Read the class definitions in
`mss_contract.dart` directly if a specific field's source key is
ambiguous; they are short (10-20 lines each) and already written.

## What has NO existing Dart model yet

Checked `mss_contract.dart`'s full class list (`Citation`,
`BenefitAmount`, `MatchReason`, `DataConfidence`, `AuthorityRef`,
`DetectedIntent`, `ResponseWarning`, `RankingSignals`, `NextAction`,
`FinanceBenefit`, `EligibilityMatch`, `Explanation`, `SchemeResult`,
`UpdateMetadata`, `MSSSearchResponse`, `MSSApiError`) against the full
live endpoint list in `api_docs/API_ENDPOINT_REFERENCE.md`:

- **No model for** `GET /v1/schemes/{id}`'s scheme-detail response shape
  specifically (the relationship-summary lists, `dataIntegrity`) --
  `SchemeResult` covers the search-result shape, not this one.
- **No model for** cluster/tax/privilege list-detail responses (§5).
- **No model for** the `relationships()` endpoint's edge-list response (§6).
- **No model for** the `localization()` endpoint's response (§7).
- **No model for** `/v1/meta`'s response beyond the partial
  `UpdateMetadata` class (verify its field list against §8's actual shape
  before relying on it -- it was not built against the current `meta()`
  implementation's exact output).

None of these gaps are filled by this handoff -- per the task's
boundary, no Dart file is created or modified here. This section exists
so a future Flutter-integration phase knows exactly which models still
need writing, rather than assuming `mss_contract.dart` is complete for
every endpoint.
