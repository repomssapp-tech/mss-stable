# DESIGN NOTE — Phase P2: Hindi Content Pipeline

**Author:** Antigravity (Executor)  
**Target:** MSS App Catalog Hindi Localization (P2)  
**Date:** 2026-10-06  

---

## 1. Scope & Gap Summary
- **Scope (D6):** All central-level schemes (`government_level = 'central'` or `id = 'SCH000006'`, 218 total schemes), plus referenced authorities, institutions, and common terms.
- **Current Baseline:**
  - 128 central schemes have a Hindi name row seeded in P1 (from legacy booklet import).
  - 90 central schemes have zero Hindi rows.
  - Across the 8 core text fields (`name`, `short_name`, `summary`, `objective`, `description`, `benefits_text`, `eligibility_text`, `application_text`), exactly **1,266 field values** are missing Hindi translations where English exists.
- **Rules Applied:**
  - D7: Western digits 0-9 strictly enforced in Hindi text (no Devanagari numerals `०-९`).
  - D8: Non-empty existing Hindi translations are **never overwritten**.
  - D9: Any field failing the number check is **not written** to `catalog.content`, falls back to English, and is logged in `admin.translation_jobs` as `needs_review`.

---

## 2. Glossary & Protected Terms (Do-Not-Translate)
Acronyms and proper nouns preserved verbatim:
`PMEGP`, `MSME`, `CGTMSE`, `ZED`, `KVIC`, `Coir Board`, `NSIC`, `SIDBI`, `MUDRA`, `REGP`, `Udyam`, `UAM`, `GSTIN`, `PAN`, `DGFT`, `NABARD`, `RBI`, `CLCSS`, `SFURTI`, `ASPIRE`.

---

## 3. Resumable Batch Pipeline
- Script: `tools/translate_hindi_pipeline.py`.
- **Job States in `admin.translation_jobs`:**
  - `PENDING` -> `PROCESSING` -> `COMPLETED` (or `FAILED` with error `needs_review: <reason>`).
  - Idempotent: checks `catalog.content` and existing jobs; resumes from where it left off.
- **Validation Gates per Field:**
  1. *Number Check (Blocking):* Normalizes Devanagari digits to 0-9, extracts multiset of numbers (`\b\d+(\.\d+)?\b`). Verifies `Counter(numbers_en) == Counter(numbers_hi)`.
  2. *Script Check (Blocking):* Verifies output contains predominantly Devanagari Unicode characters (`\u0900-\u097F`), with acronyms and numerals preserved in Latin.
  3. *Length Ratio (Warning):* Flags if `len(hi) < 0.4 * len(en)` or `len(hi) > 3.0 * len(en)`.
- **Database Write:**
  - Writes to `catalog.content` (`origin = 'machine'`, `engine = 'google_translate'`, `verified = false`).
  - Calculates `source_checksum = catalog.content_checksum(...)`.
  - Re-evaluates fingerprint of existing data to guarantee zero regression on pre-existing data.
