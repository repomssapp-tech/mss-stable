# DISCOVERY.md — P0 Discovery and Audit (Hindi Localization)

This document answers the 12 discovery questions for Phase P0 based on verified facts from the codebase and Supabase database (`houpzsxmwemoztpuigmo`).

---

### 1. Which script(s) build the release files from the catalog tables
- **Orchestrator script:** [`tools/publish_catalog_release.py`](file:///c:/development/MSS%20App/MSS_App/tools/publish_catalog_release.py)
- **Bundle builder:** [`tools/generate_catalog_bundle.py`](file:///c:/development/MSS%20App/MSS_App/tools/generate_catalog_bundle.py)
- **Inputs:** JSON files in `Plan/catalog/` (or specified via `--source PATH`), `Plan/catalog/manifest.json`.
- **Outputs:**
  - `catalog_bundle.json.gz` (gzipped merged catalog bundle containing all entity catalogues)
  - `release.json` (uncompressed manifest with checksums, byte sizes, entity counts, schema version)
  - 15 individual catalog JSON files + `search_index.json`
  - Mirrored into `frontend/assets/catalog/`
- **Compression & Naming:** Gzip compression (`.json.gz`) for `catalog_bundle.json.gz`; `identity` (uncompressed `.json`) for individual catalog files in storage.
- **Execution:** Invoked via CLI: `python tools/publish_catalog_release.py --target linked` (or `local`).

---

### 2. Release publish flow
- **Database tables:** `admin.catalog_releases`, `admin.catalog_files`, `admin.catalog_release_history`.
- **Flow in `tools/publish_catalog_release.py`:**
  1. Reads `release_version` from `Plan/catalog/manifest.json`.
  2. Regenerates `catalog.*` import SQL from source and applies chunks to Supabase.
  3. Builds `catalog_bundle.json.gz` + `release.json` locally.
  4. Uploads bundle and 16 files to Supabase Storage bucket `catalogs` under `releases/<version>/`.
  5. Inserts new `admin.catalog_releases` record with `is_current = true`, status `'published'`, `package_sha256`, `package_byte_size`, `record_counts`.
  6. Demotes previous current release (`update admin.catalog_releases set is_current = false where is_current = true`).
  7. Inserts one row per uploaded file into `admin.catalog_files`.
- **Test / Non-current channel:** `--rollback-to <version>` or publishing with `is_current = false` allows non-current staging.

---

### 3. App side: download, parse, cache, and upgrade
- **Dart classes:**
  - [`frontend/lib/services/scheme_catalog_sync_service.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/scheme_catalog_sync_service.dart): `SchemeCatalogSyncService`, `SupabaseCatalogReleaseSource` handles checking release metadata, downloading bundle, and caching.
  - [`frontend/lib/services/catalog/mss_catalog_bundle.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/catalog/mss_catalog_bundle.dart): `MssCatalogBundle` parses entity catalogs from JSON/Gzip and indexes them in memory.
  - [`frontend/lib/services/catalog/mss_scheme_adapter.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/catalog/mss_scheme_adapter.dart): Adapts `MssEntity` into UI models.
- **Where `localization` and `name_ta` are read:**
  - [`frontend/lib/models/mss_entity.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/models/mss_entity.dart): `getLocalizedName(lang)` reads `raw['localization'][lang]['name']`.
  - [`frontend/lib/models/scheme_model.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/models/scheme_model.dart): `Scheme.nameTa`, `getLocalizedName(langCode)`.
  - [`frontend/lib/models/localized_scheme.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/models/localized_scheme.dart): `LocalizedScheme.fromScheme(scheme, langCode)`.
  - [`frontend/lib/services/catalog/adapter/scheme_header_resolver.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/catalog/adapter/scheme_header_resolver.dart): `nameTa`.
  - [`frontend/lib/services/catalog/adapter/scheme_adapter_text_utils.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/catalog/adapter/scheme_adapter_text_utils.dart): `name_ta`.
  - [`frontend/lib/services/search/hybrid_scheme_search.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/search/hybrid_scheme_search.dart): Reads `e.getLocalizedName('en')`, `e.getLocalizedName('ta')`.
- **UI Interface Screens:** Screens access schemes via `AppStateProvider` (`frontend/lib/providers/app_state_provider.dart`), `MssCatalogBundle`, and `SchemeAdapter`.

---

### 4. Language setting
- **Database storage:** `public.profiles.language` (character varying, default `'en'`).
- **Constraints on `profiles.language`:** None in database (Query I2 returned `[]` check constraints).
- **Local storage & state:** Stored in SharedPreferences and managed by `AppStateProvider` via `_selectedLanguage` and `_languageReconciler`.
- **Allowed values:** App currently whitelists `'en'` and `'ta'` in `AppStateProvider` and `AppLocalizations`.

---

### 5. ARB / i18n setup
- **Location:** [`frontend/lib/l10n/`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/l10n/)
- **Languages present:** `app_en.arb`, `app_ta.arb`.
- **Key count:** Exactly **1,429 keys** present in both `app_en.arb` and `app_ta.arb`.
- **Hindi strings:** None currently in ARB files (`app_hi.arb` does not exist).

---

### 6. Search: HybridSchemeSearch
- **File:** [`frontend/lib/services/search/hybrid_scheme_search.dart`](file:///c:/development/MSS%20App/MSS_App/frontend/lib/services/search/hybrid_scheme_search.dart)
- **Indexed fields:** `identity.acronym`, `identity.shortName`, localized names for `'en'` and `'ta'`, search aliases (`e.search['aliases']['en']`, `['ta']`).
- **Devanagari / Indic text handling:** Currently, `_normLookup` uses `replaceAll(RegExp(r'[^a-z0-9]+'), ' ')`, which strips non-ASCII scripts. Must be updated to retain Indic Unicode characters (`\p{L}`).
- **Embedding model:** On-device search uses deterministic taxonomy keyword scoring (`assets/search/search_taxonomy.json`) and exact lookup entries; no remote embedding model required for core search.
- **Voice path:** Transcripts from speech-to-text / Sarvam pass directly into `HybridSchemeSearch.search(query)`.

---

### 7. `catalog.common`
- **Row count:** 344 rows.
- **Structure:** Top-level keys in `record_json`: `ai`, `metadata`, `verification`, `content`, `localization`, `identity`, `search`, `relationships`, `provenance`, `analytics`.
- **Display text:** `identity.name` (and `localization.<lang>.name`), `ai.summary`. Represent common terms (states, sectors, entity classifications, document types).

---

### 8. Existing 128 Hindi names/fields provenance
- **Source:** Query F on `catalog.scheme.record_json->'provenance'->'translations'->'hi'`:
  - 114 schemes: `status: 'machine'`, `engine: null`, `is_approved: null`
  - 15 schemes: `status: 'official_2015_name_only'`, `engine: null`, `is_approved: null`
  - 15 schemes: `status: 'none'`, `engine: null`, `is_approved: null`
- **Result:** Seeds into `catalog.content` with `origin = 'imported'`, `verified = false`.

---

### 9. Environments
- **Remote:** Only one remote environment: Supabase project `houpzsxmwemoztpuigmo` (live production database).
- **Local:** Local Supabase emulator stack (`supabase start`, CLI target `local`).

---

### 10. Existing tests and CI layout
- **Flutter tests:** `frontend/test/` (unit, widget, and golden tests, executed with `flutter test`).
- **Backend / Python tests:** `scripts/`, `saarthi-agent/tests/`, `tools/`.
- **CI Workflows:** `.github/workflows/` (contains flutter build, backend checks, dev-log generation).

---

### 11. Fonts
- **Configuration:** `frontend/pubspec.yaml` specifies `google_fonts: ^8.1.0`.
- **Font families used:** `GoogleFonts.inter()` and `GoogleFonts.poppins()`.
- **Hindi / Devanagari support:** Android OS and Flutter GoogleFonts fallback safely to system Noto Sans Devanagari. Verified in standard Flutter Text widgets.

---

### 12. Size baseline
- **Current live release:** `1.35.1-alpha` (release version 9, `is_current = true`).
- **Gzip bundle size (`package_byte_size`):** 713,188 bytes (~713 KB).
- **Uncompressed individual file sizes (sample):**
  - `scheme_catalog.json`: 7,368,610 bytes (~7.37 MB)
  - `common_catalog.json`: 2,230,621 bytes (~2.23 MB)
  - `finance_catalog.json`: 1,423,747 bytes (~1.42 MB)
  - `authority_catalog.json`: 1,095,398 bytes (~1.10 MB)
  - `applicability_matrix_catalog.json`: 894,710 bytes (~895 KB)
  - `institution_catalog.json`: 649,267 bytes (~649 KB)
  - Total uncompressed: ~14.5 MB.
