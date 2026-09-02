# MSS API Data Package

Standalone production data package. Contains only the JSON files an API
layer actually needs to serve the MSS catalog -- traced from the real
runtime code paths (`mss_api.py`, `mss_api_rc1.py`, `hybrid_search.py`,
`intelligence_resolver.py`, `app_response.py`), not guessed. See
`../API_PACKAGE_VALIDATION_REPORT.md` for the full trace and validation
results.

## Contents (16 files)

**Entity catalogs (14) -- loaded by `IntelligenceResolver`:**
`scheme_catalog.json`, `finance_catalog.json`, `tax_catalog.json`,
`treds_catalog.json`, `csr_catalog.json`, `authority_catalog.json`,
`institution_catalog.json`, `export_catalog.json`,
`cluster_assistance_catalog.json`, `msme_privilege_catalog.json`,
`business_enablement_catalog.json`, `knowledge_catalog.json`,
`applicability_matrix_catalog.json`, `common_catalog.json`.

`common_catalog.json` is included even though the current resolver
doesn't dereference it at runtime, because other catalogs' fields
(`productFamilyId`, `documentTypeId`, etc.) reference its ids by
convention -- excluding it would make the package's own relationship
graph incomplete from a self-contained validation standpoint.

**Search (1):** `search_index.json` -- loaded by `HybridSearch`. Already
contains both English and Tamil tokens/keywords for every entity; no
separate localization file is needed for search.

**Integrity (1):** `manifest.json` -- per-file checksum/record-count
ledger. Not read by the serving code today, but included so a receiving
team can verify package integrity without recomputing checksums from
scratch, and per this task's explicit "validate manifest checksums"
requirement.

## What's deliberately NOT here

- `enterprise_classification_catalog.json` -- traced and confirmed: no
  other catalog references its ids, and no runtime code loads it. Genuinely
  unused by the current serving layer.
- `translation_dictionary.json`, `ta_overrides.json`, `ta_dictionary.py` --
  build-time translation tooling. Tamil content is already inside every
  catalog's own `localization.ta` fields; these tools produced it but are
  never read to serve it.
- Any `*_statistics.json`, `queue_*.json`, `results_*.json`,
  `benchmark_*.json`, `stage_a_frozen/`, or `build_*.py`/`validate_*.py`
  script -- development/build-time artifacts, not runtime data.
- `mss_api.py` / `mss_api_rc1.py` / `hybrid_search.py` /
  `intelligence_resolver.py` / `app_response.py` themselves -- this is a
  **data** package; the existing Python reference implementation is the
  paired serving code, described in `API_CONTRACT.md` and
  `FLUTTER_API_IMPLEMENTATION_PLAN.md` in the integration package, not
  duplicated here.

## Standalone validation

`validate_package.py` in this directory imports nothing from outside it
and resolves every path relative to itself -- run it from inside this
directory (`python validate_package.py`) and it validates JSON
integrity, id uniqueness, relationship resolution, localization
completeness, search-index consistency, and manifest checksum agreement
using only the files present here. See
`../API_PACKAGE_VALIDATION_REPORT.md` for the full run output.

## Version

Source catalog version: `1.33.0-alpha+stageb.pass1.batch1+...+searchprofile`
(219 schemes). Package built 2026-08-15 from the fully-validated,
localization-complete release state.
