# Runbook: Adding a New Language to MSS App Catalog

This runbook documents the step-by-step operational procedure for adding any new language (e.g., Telugu `te`, Kannada `kn`, Malayalam `ml`, Marathi `mr`, etc.) to the MSS App catalog and frontend interface.

---

## 1. System Architecture & Decisions Register

The multilingual catalog architecture is designed around these foundational decisions:
- **D1 (Single Table):** All translations live in `catalog.content (entity_type, entity_id, lang)`. Adding a language requires **no schema changes (no DDL)**, only inserting rows.
- **D3 (Per-Field Fallback):** When a translated field is missing or unverified, the resolver falls back to English for that specific field.
- **D7 (Western Digits):** Numerical digits across all Indic translations must use Western digits `0-9` (no script-specific numerals).
- **D8 (Preserve Existing):** Translations never overwrite non-empty existing human or approved translations.
- **D9 (Number Check Gate):** Any translated field that fails the number multiset check is excluded from writing; it falls back to English and is logged in `admin.translation_jobs` as `needs_review`.
- **D10 (Disabled by Default):** New languages are inserted into `catalog.language` with `is_active = false`. The language pack is enabled only after testing and verification.
- **D13 (Stale Exclusion):** If the English source changes after a translation was produced, the translation is marked stale and excluded from distribution until refreshed.

---

## 2. Prerequisites & Tools

Ensure the following tools are available in the repository:
- Python 3.10+ with `psycopg2` / `requests` / standard libraries.
- Flutter SDK (with `flutter gen-l10n`).
- Supabase CLI linked to target project (`npx supabase db query --linked`).
- Release scripts in `tools/`:
  - `tools/build_catalog_release.py`
  - `tools/export_unverified_hindi.py` (adaptable per language)
  - `tools/import_verified_hindi.py` (adaptable per language)

---

## 3. Step-by-Step Execution Procedure

### Step 1: Database Registration via Migration (D10, D14)
Never insert languages directly via the Supabase dashboard. Create a tracked migration:

1. Create migration file `backend/supabase/migrations/<TIMESTAMP>_add_language_<code>.sql`:
   ```sql
   -- Register new language code in catalog.language (is_active = false initially)
   insert into catalog.language (code, name_native, is_active)
   values ('<lang_code>', '<Native Name in Script>', false)
   on conflict (code) do nothing;
   ```
2. Apply migration cleanly:
   ```bash
   cd backend
   npx supabase db push --linked
   ```

---

### Step 2: Establish In-Scope Entities & Glossary
1. Identify the target entity scope:
   - Central schemes: `where government_level = 'central'`
   - State schemes: if applicable to the region.
   - Supporting authorities, institutions, and common terms.
2. Define a translation glossary to protect proper names and acronyms:
   - Acronyms: `PMEGP`, `MSME`, `CGTMSE`, `MUDRA`, `SIDBI`, `KVIC`, `ZED`.
   - Currency & symbols: `₹`, `Cr`, `Lakh`.
   - Official portals: `udyamregistration.gov.in`, `jansamarth.in`.

---

### Step 3: Run Translation Pipeline & Integrity Checks (D7, D8, D9)
1. Run batch translation pipeline for all in-scope schemes and entities.
2. For each field:
   - **Number check:** Extract numerical multisets from English and translated text:
     $$\text{multiset}(\text{English numbers}) == \text{multiset}(\text{Translated numbers})$$
   - If numbers differ, **do not write translated text**. Log to `admin.translation_jobs` with status `FAILED` and `needs_review: number_mismatch`.
   - If numbers match, write to `catalog.content`:
     - `origin = 'machine'`
     - `engine = '<engine_name>'`
     - `verified = false`
     - `source_checksum = catalog.content_checksum(...)`
3. Verify zero number violations exist in the database:
   ```bash
   python tools/verify_p2_acceptance.py
   ```

---

### Step 4: Build Release Bundle & Language Pack (Phase P3)
1. Run the release build tool (defaults to in-repo master `backend/catalog/source` per D15):
   ```bash
   python tools/build_catalog_release.py --version <VERSION>
   ```
2. This produces in `scratch/<VERSION>`:
   - `catalog_bundle.json.gz` (core English facts)
   - `catalog_pack_<lang>.json.gz` (deterministic Gzip)
   - `release.json` (SHA-256 manifest and counts)

3. Run the Release Gate (D17) before publishing:
   ```bash
   python tools/release_gate.py --candidate scratch/<VERSION> --report docs/reports/gate_<VERSION>.json
   ```
   Must pass checks G1 through G6.

4. Publish candidate as non-current (D17) with immutability check (D16):
   ```bash
   python tools/publish_catalog_release.py --candidate-dir scratch/<VERSION>
   ```
   Flip `is_current` only in a separate step requiring PASS gate report:
   ```bash
   python tools/publish_catalog_release.py --flip-current <VERSION> --report docs/reports/gate_<VERSION>.json
   ```

---

### Step 5: App Localization (Frontend ARB & Resolver)
1. Generate the ARB file:
   - Translate `frontend/lib/l10n/app_en.arb` to `frontend/lib/l10n/app_<lang>.arb`.
   - Verify that missing keys count is exactly **0**:
     ```bash
     python -c "import json; en=json.load(open('frontend/lib/l10n/app_en.arb')); tg=json.load(open('frontend/lib/l10n/app_<lang>.arb')); print('Missing:', set(en) - set(tg))"
     ```
2. Run code generation:
   ```bash
   cd frontend
   flutter gen-l10n
   ```
3. Add the language entry to `frontend/lib/screens/regular_mode/language_selection_screen.dart`.
4. Run integration tests:
   ```bash
   flutter test test/language_pack_and_resolver_test.dart
   ```

---

### Step 6: Human Verification Loop (Phase P6)
1. **Export unverified content:**
   ```bash
   python tools/export_unverified_hindi.py --output docs/reports/unverified_<lang>.csv
   ```
2. Reviewers edit translations in CSV/Google Sheets (English side-by-side with translated text).
3. **Import verified content:**
   ```bash
   python tools/import_verified_hindi.py --input docs/reports/unverified_<lang>.csv --reviewer "<Reviewer Name>" --apply
   ```
   The import tool automatically re-verifies number matching, updates `source_checksum`, and sets `verified = true`, `origin = 'human'`.

---

### Step 7: Staging Verification & Parity Checks
1. Execute stale translation checks:
   ```sql
   -- Verify 0 stale rows exist
   select * from catalog.content c
   join (
     select entity_type, entity_id, catalog.content_checksum(name, short_name, summary, objective, description, benefits_text, eligibility_text, application_text) as chk
     from catalog.content where lang = 'en'
   ) e on e.entity_type = c.entity_type and e.entity_id = c.entity_id
   where c.lang = '<lang>' and c.source_checksum != e.chk;
   ```
2. Run full test suite:
   ```bash
   cd frontend
   flutter test test/mss_catalog_bundle_test.dart
   flutter test test/search_taxonomy_parity_test.dart
   ```

---

### Step 8: Production Activation (Rollout)
1. Flip the activation switch in Supabase:
   ```sql
   update catalog.language
   set is_active = true
   where code = '<lang_code>';
   ```
2. The language pack is now live. New app builds and existing clients querying the release API can download and cache the language pack on demand.

---

## 4. Emergency Kill Switch / Rollback Procedure

If translation defects, crash reports, or severe issues arise post-launch:
1. **Instant Server-Side Rollback:**
   ```sql
   update catalog.language
   set is_active = false
   where code = '<lang_code>';
   ```
2. Re-run `python tools/build_catalog_release.py` and publish the release manifest.
3. **App Behavior:**
   - Client detects `is_active = false` from the release manifest.
   - Resolver silently falls back to English content (D3).
   - No crash, no broken UI, and **no emergency app store release required**.
