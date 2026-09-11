# Full Context: Catalog Release `searchIndexCount` Discrepancy Bug

**Document Version:** 1.0  
**Target Milestone:** Catalog Release Manifest Integrity Fix  
**Severity:** Medium (Metadata discrepancy / Manifest inconsistency)  
**Impacted Files:**
- `tools/generate_catalog_bundle.py`
- `frontend/assets/catalog/release.json`
- `frontend/test/mss_catalog_bundle_test.dart`
- `STALE_DOCS.md` (Item B1)
- `docs/handoff/architecture_docs/DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md`

---

## 1. Executive Summary & Root Cause Analysis

### 1.1 The Bug
In `frontend/assets/catalog/release.json`, line 11 defines:
```json
"entityCount": 1216,
"searchIndexCount": 1216,
```
However, the actual `search_index.json` payload bundled inside `catalog_bundle.json.gz` (with SHA-256 `5fb4d8213a041928497179367d018e33acd8a6aba441d08af23227e633d32eee`) contains exactly **971** search projection records.

### 1.2 Root Cause in Generator Script
In `tools/generate_catalog_bundle.py`:
```python
# Lines 82-85: entity_count counts records across the 15 INDEXED_CATALOGS
if filename in INDEXED_CATALOGS:
    data = catalog.get("data", [])
    record_counts[filename] = len(data)
    entity_count += len(data)  # = 1216

# Lines 110-111: release dictionary construction
release = {
    ...
    "entityCount": entity_count,        # 1216 (Correct)
    "searchIndexCount": entity_count,   # 1216 (BUG: Copied from entity_count instead of search_index.json count)
    ...
}
```
`search_index.json` is categorized in `EXTRA_FILES` (files carried for reference/indexing but not indexed into `byId`/`byCatalog`). The generator script improperly assigned `entity_count` (1216) to `searchIndexCount` instead of calculating `len(bundle["search_index.json"]["data"])` (971).

---

## 2. Architectural Impact & Invariant Verification

### 2.1 SHA-256 Bundle Integrity Invariant
- `catalog_bundle.json.gz` contains:
  - 15 indexed catalog files (`common_catalog.json`, `scheme_catalog.json`, etc. = 1,216 entities)
  - `search_index.json` (971 records)
  - `manifest.json` (1 record)
- `bundleSha256` in `release.json` (`ccc3251ae2dccaf04039b4148a719717e6f0593d85dc4b1e6a223695896ee9d7`) is the SHA-256 hash of the **compressed bytes** of `catalog_bundle.json.gz`.
- `release.json` is a **standalone metadata descriptor** that sits alongside `catalog_bundle.json.gz`.
- **Key Insight:** Correcting `"searchIndexCount": 971` in `release.json` does **not** invalidate `bundleSha256` because `catalog_bundle.json.gz` itself is unmodified.

### 2.2 Client Consumption Impact
- `MssCatalogBundle._finishLoading()` verifies:
  1. `sha256(compressedBytes) == releaseJson['bundleSha256']` (Passes).
  2. Parses `search_index.json` entries where `entityType == 'scheme'` (219 scheme profiles) into `MssCatalogBundle.searchProfiles` (Passes).
- `SchemeCatalogStore.readActiveManifest()` reads `manifest.json` / `release.json` without depending on `searchIndexCount`.
- Therefore, fixing `searchIndexCount: 971` fixes metadata accuracy across build tools, manifest validators, and API checks without introducing any breaking changes or runtime regressions.

---

## 3. Detailed Fix Specifications

### 3.1 Fix Bundle Generator Tool (`tools/generate_catalog_bundle.py`)
Update record counting to compute `search_index_count` from `bundle.get("search_index.json", {}).get("data", [])`:
```python
search_index_data = bundle.get("search_index.json", {}).get("data", [])
search_index_count = len(search_index_data)

release = {
    ...
    "entityCount": entity_count,
    "searchIndexCount": search_index_count,
    ...
}
```

### 3.2 Update Shipped Asset (`frontend/assets/catalog/release.json`)
Update line 11:
```json
-  "searchIndexCount": 1216,
+  "searchIndexCount": 971,
```

### 3.3 Add Unit Test Verification (`frontend/test/mss_catalog_bundle_test.dart`)
Add an explicit test asserting:
1. `releaseJson['entityCount'] == 1216`
2. `releaseJson['searchIndexCount'] == 971`
3. `(bundleJson['search_index.json']['data'] as List).length == releaseJson['searchIndexCount']`

### 3.4 Update Documentation
Update `STALE_DOCS.md` item B1 and `DUAL_COPY_CATALOG_RELEASE_SPECIFICATION.md` to reflect the resolution of the bug.

---

## 4. Verification Plan

1. Run `flutter test test/mss_catalog_bundle_test.dart` to verify checksum validation and record count matching.
2. Run full test suite `flutter test` to ensure zero regressions across catalog bundle tests, mapping tests, and search tests.
3. Run `flutter analyze` to ensure clean static analysis.
