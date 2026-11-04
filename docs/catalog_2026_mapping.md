# 2026 scheme catalog — source mapping (release 1.37.0-alpha)

The scheme catalog is built from `schemes_json_only` (central, Tamil Nadu,
Maharashtra). This page records how each source field is carried into the app
bundle, what comes from the legacy catalog, and how to rebuild.

## Pipeline

```
schemes_json_only/*_app_2026.json  (+ id maps, master files)          [source input, never modified]
        │  tools/build_scheme_supplement.py   legacy scheme_catalog.json -> scheme_supplement_legacy.json   [build input]
        │  tools/import_schemes_json.py       -> backend/catalog/source/scheme_catalog.json   (supplement merged here)
        │                                        scheme_id_map.json, schemes_import_report.json,
        │                                        docs/reports/scheme_merge_audit.json
        │  backend/catalog/source/build_applicability_matrix.py, build_crossrefs.py, build_search_index.py
        │  tools/build_catalog_release.py --offline     -> catalog_core.json.gz + catalog_<jurisdiction>.json.gz  (the runtime assets)
        │                                                  release.json             [build/publish artifact, not shipped]
        │  tools/verify_scheme_bundle.py                 -> docs/reports/scheme_bundle_verification_<tag>.json
        │  tools/catalog_size_report.py                  -> docs/reports/catalog_size_report_<tag>.json
        │  tools/release_gate.py (+ backend/catalog/declarations/<tag>.json)
        ▼
frontend/assets/catalog/catalog_*.json.gz  →  MssCatalogBundle → SchemeRepository → UI
```

## Runtime layout (bundleFormat 3): a core file and one pack per jurisdiction

The catalog ships as separate files in `frontend/assets/catalog/`, each compact
JSON, GZIP level 9, each a registry of sections keyed by catalog name:

| File | Holds | Needed |
|---|---|---|
| `catalog_core.json.gz` | every non-scheme catalog, `search_index.json` rows for non-schemes, `manifest.json`, `migrations.json` | always |
| `catalog_central.json.gz` | the 274 national schemes + their applicability and search-index rows | always (`required`) |
| `catalog_tamil_nadu.json.gz`, `catalog_maharashtra.json.gz`, ... | that jurisdiction's schemes + their applicability and search-index rows | optional; one per jurisdiction, found from `provenance.jurisdiction` |

Only `scheme_catalog.json`, `applicability_matrix_catalog.json` and
`search_index.json` are partitioned; in a pack they carry just `data`, and a
`pack.json` section names the pack. The core keeps each partitioned section's
`metadata` (describing the merged section) and a `packSlot`: where the packs'
rows go inside the core rows, so the merged order equals the old single-file
order (checked: merged sections are identical to the former bundle). Loading =
core + every installed pack, merged by `CatalogPacks.mergeInto` (Dart) /
`tools/catalog_packs.py` (Python).

`manifest.packs` (in the core) lists every file: `id`, `kind` (`core`|`jurisdiction`),
`file`, `jurisdiction`, `tenantId` (equal to the jurisdiction for now; branding and
access rules come with tenants), `required`, `languages`, per-section
`recordCounts`, `bytes` and `sha256`. The app checks each pack's SHA-256 against
the core manifest, so a pack can be downloaded, replaced or dropped on its own.
A pack that is listed but not installed is skipped (its counts are discounted);
a missing `required` pack is an error. The APK ships all packs; dropping a state
and re-downloading it later needs only the pack file and the manifest entry.

Hosting: each file is a static object at `/catalog/<release>/<file>`; publishing
or rolling back one state does not touch the others. `release.json` (a build
artifact) lists the core SHA-256 and the packs.

| Section | Content |
|---|---|
| `scheme_catalog.json` + 13 other `*_catalog.json` | the 15 entity catalogs (schemes, authorities, institutions, finance, tax, TReDS, CSR, export, knowledge, applicability matrix, enterprise classification, MSME privilege, business enablement, cluster assistance, common terms), each `{metadata, data[]}` |
| `search_index.json` | search tokens and scheme search profiles |
| `manifest.json` | one record: `bundleFormat`, `release{releaseTag, releasedAt, schemaVersion}`, `languages[{code, isActive}]` (the language kill switch), `languageRegistry.jurisdictions` (content and offered languages per jurisdiction, derived from the data), `recordCounts` per section, `entityCount` |
| `migrations.json` | `schemeIdMap`: pre-2026 id or legacy code to 2026 id |

What replaced the former side files:

| Former runtime file | Now |
|---|---|
| `catalog_pack_hi.json.gz`, `catalog_pack_ta.json.gz` | each entity's `localization.<lang>` (schemes already carried it; authority/institution name, reviewed flag, aliases and keywords moved onto the entity) |
| `release.json` | `manifest.json` section; `release.json` is still written by the build for the release gate and publishing |
| `scheme_id_map.json` | `migrations.json` section |
| `scheme_supplement_legacy.json` | merged into the schemes at build time; never shipped |

Integrity: a pack's hash cannot be stored inside itself, so the core manifest vouches
for every pack and the server's SHA-256 in `release.json` vouches for the core. The loader checks
the embedded per-section `recordCounts` (a truncated bundle is an error, never
an empty catalog), rejects a `bundleFormat` newer than the app supports, and
relies on gzip's CRC for corruption. A downloaded release is additionally
verified against the server's SHA-256 before it is installed.

Files that remain beside the bundle in `assets/catalog/`:
`translation_dictionary.json` and `translation_dictionary_hi.json`. They are the
phrase tables of the runtime translation engine (`CentralizedTranslator`), are
loaded at app start before the catalog, and are not catalog data.

Sizes (measured by `tools/catalog_size_report.py`, report in
`docs/reports/catalog_size_report_1.37.0-alpha.json`): runtime catalog assets
2,117,984 B (bundle 1,847,391 + packs 241,180 + release.json 3,625 + id map
25,788) became one 1,616,053 B file (-23.7%); the bundle went from 19.9 MB to
17.9 MB of JSON, ratio 11.1x. The saving comes from the language packs, whose
scheme rows duplicated the schemes' own text, and from the localization `*List`
fields, which repeated lists kept verbatim in `source`. All 1,601 entities and
all 1,018 former pack rows were compared after decompression: no content was
lost (only build timestamps differ).

The original `schemes_json_only` files are never modified. Only the three
`*_app_2026.json` files (and, for central and Tamil Nadu, the master files for
provenance) are read.

## Merge rule

1. A value present in the 2026 record always wins.
2. `scheme_supplement_legacy.json` fills only facets the 2026 record lacks:
   structured eligibility (gender, age, community, business stage, enterprise
   type, sector, special category), typed benefit breakdowns, detailed required
   documents, relationships (authority / institution / finance / tax / export),
   classification ids, target beneficiaries, search keywords/aliases and the
   verification block. Each entry is tagged `origin: "legacy_catalog"`.
3. Nothing is translated or invented. Facets absent from both sources are
   recorded in `verification.missingFields` (`content.requiredDocuments`,
   `content.applicationProcess.steps`, `content.schemeUrl`).

How the merge works (`fill_missing` in `tools/import_schemes_json.py`):

- Only absent values are gaps (`None`, `""`, `[]`, `{}`); `false` and `0` are
  real values and are never overwritten.
- Dicts merge key by key. Lists and scalars are never combined, so a document,
  benefit, URL or step cannot appear twice.
- Required documents: the 2026 list is the list. Legacy detail (issuing
  authority, mandatory flag, cost...) is attached only to a document whose name
  matches; legacy documents with no match are counted in the audit, not appended.
- A non-empty legacy value that differs from the kept 2026 value is logged as a
  conflict; the 2026 value stays.

The supplement is applied at build time only. `scheme_supplement_legacy.json`
stays in `backend/catalog/source/` as a **build input**, because the pre-2026
`scheme_catalog.json` it was derived from was replaced by this import (it
survives in git at `88830a3`); it is not an app asset. To rebuild it:
`git show 88830a3:backend/catalog/source/scheme_catalog.json > legacy.json`, then
`python tools/build_scheme_supplement.py --new-dir <schemes_json_only> --old legacy.json`.

Audit (`docs/reports/scheme_merge_audit.json`, regenerated by every import):
277 schemes matched a legacy record; 25 legacy schemes have no 2026
counterpart and are excluded (listed by id and name); gaps filled per facet;
legacy documents not matched; and every conflict with the kept and the legacy
value. Coverage: 224 central and 53 Tamil Nadu schemes matched; 129 of the 406
new schemes (79 Maharashtra, 50 central) have no previous record and carry only
2026 data.

## Field mapping

| 2026 source field | Bundle location |
|---|---|
| `id` | `identity.id`, `identity.code` |
| `name{lang}`, `short_name{lang}` | `localization.<lang>.name / shortName`; `identity.name / shortName` (English) |
| `description / benefits / eligibility {lang: [..]}` | `localization.<lang>.description / benefitsText / eligibilityText` (newline-joined) and `…List` (original list) |
| `how_to_apply.steps{lang}` | `localization.<lang>.applicationText / stepsList`; `content.applicationProcess.steps` (English) |
| `how_to_apply.mode` (+ `translations.<lang>`) | `content.applicationProcess.modeText`, `localization.<lang>.mode` |
| `how_to_apply.documents` (list / audience dict) | `content.requiredDocuments[]` (enriched by the supplement when the name matches); `localization.<lang>.documents` |
| `how_to_apply.apply_url / info_url / guidelines_url / procedure_sources` | `content.sources[]`, `content.schemeUrl` (info, else apply), `content.applicationProcess.onlineUrl` |
| `how_to_apply.portal` + file-level `portals{}` (Maharashtra) | `content.portalInfo` (resolved entry) |
| `how_to_apply.fees / prerequisite / deadline / application_status / procedure_type / status_checked_on` | `content.applicationProcess.*` |
| `authority`, `category` (+ `translations.<lang>`, `authority_ta`) | `localization.<lang>.authority / category`; `content.classification.government.departmentText` |
| `status{value,note,as_of}` | `identity.status`, `content.status`, `localization.<lang>.statusNote` |
| `benefit_facts` | `content.benefitFacts` (verbatim) |
| `contacts` (+ `translations.<lang>.contacts`) | `content.contacts` (verbatim), `localization.<lang>.contacts` |
| `alt_names` (list or `{lang: list}`), `legacy_id` | `search.aliases.<lang>`, `identity.legacyCodes` |
| `related_ids` | `relationships.references[]` (`relationType: related`) |
| `notes`, `notes_<lang>` | `localization.<lang>.notes` |
| `<lang>_is_machine_translation`, `name_source` | `provenance.translationFlags / nameSource` |
| master-file `field_sources`, `translation_meta`, `level_basis`, `source_scheme_id`, `pending_translation`, `documents_sources`, `internal_notes` | `provenance.master` (central, Tamil Nadu) |
| **the whole record** | `source` (verbatim; guarantees no field is lost) |

`level` → `content.classification.government.level` (`central` and
`central_state` are treated as central). Statuses `active`, `closed`,
`unknown`, `announced` are all shipped; only `closed` marks a scheme inactive.

## Languages

| Jurisdiction | Content languages in the data | Offered in the UI |
|---|---|---|
| Central | en, hi, ta | en, hi, ta |
| Tamil Nadu | en, ta | en, ta (Hindi falls back to English per field) |
| Maharashtra | en, hi, mr | en, hi, mr |

Hindi and Tamil text is part of every entity (`localization.hi`, `localization.ta`)
inside the one bundle. Which languages the release switches on, the content
languages found in the data, and the languages offered per jurisdiction are in
`manifest.languages` and `manifest.languageRegistry`, derived from the data (a
new state or language needs no code change; `OFFERED_LANGUAGES_BY_JURISDICTION`
in `tools/build_catalog_release.py` states the language policy and defaults to
the discovered languages that are switched on). Marathi is offered for
Maharashtra schemes only. The admin upload does not accept Marathi, so a server
release has none; the app copies it in from its shipped packs when it installs
one (`catalog_language_fill.dart`).

Content language is resolved by `ContentLanguageResolver`
(selected → English → any other present language); the UI language comes from
the ARB files and is independent of it. A new content language is discovered
from the catalog; its interface strings still need ARB resources and a locale
registration.

## Saved items

`migrations.json.schemeIdMap` in the bundle maps old ids and legacy codes to
2026 ids (894 entries: 406 ids from the three source id maps plus 488
legacy-code aliases; `backend/catalog/source/scheme_id_map.json` is its build
source). On first catalog load `AppProvider.loadSchemes` rewrites bookmarks,
recently viewed and saved-eligibility ids through it. Pre-2026 ids with no
counterpart are dropped; ids of any other shape are never removed.

## Rebuild

```bash
python tools/import_schemes_json.py --new-dir <schemes_json_only>        # merges the legacy supplement, writes the merge audit
(cd backend/catalog/source && python build_applicability_matrix.py && python build_crossrefs.py && python build_search_index.py)
python tools/build_catalog_release.py --offline --out-dir <tmp>          # then copy ONLY <tmp>/catalog_*.json.gz into frontend/assets/catalog (delete old ones first)
python tools/verify_scheme_bundle.py --new-dir <schemes_json_only> --bundle-dir frontend/assets/catalog
python tools/catalog_size_report.py --baseline <previous build dir> --current frontend/assets/catalog
python tools/release_gate.py --candidate <tmp> --previous <prev> --tag <tag> --local-only
```

Notes:

- `tools/build_catalog_release.py` writes copies of every source catalog and
  `release.json` into its `--out-dir`; those are build artifacts. Only
  `catalog_*.json.gz` (core + packs) goes into `frontend/assets/catalog`
  (`tools/publish_catalog_release.py` already copies just those files).
- The release gate takes the build directory as `--candidate`, because it needs
  `release.json`.
