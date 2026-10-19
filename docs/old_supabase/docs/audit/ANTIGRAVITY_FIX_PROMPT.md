# Task: Fix the catalog v3.1 migration (release 1.35.0-alpha → 1.35.1-alpha)

An independent audit (`CATALOG_V3_1_AUDIT.md`, in this folder) checked your 1.35.0-alpha work against the live database. It found real defects, and several statements in `CATALOG_V3_1_MIGRATION_REPORT.md` that are false. Read the audit in full first.

This task fixes those defects. **It is not a rewrite.** The parts the audit marks ✅ stay as they are.

Repo: `MSS_App`, branch `data/catalog-v3-1-migration`. Supabase project: `houpzsxmwemoztpuigmo`.

## Decisions (filled in by Kishaunjith; do not change them)

| # | Decision | Answer |
|---|---|---|
| D1 | ESDP: SCH000095 canonical, SCH000055 archived | YES |
| D2 | SCH000064 archived as CGTMSE duplicate | YES |
| D3 | SCH000082 Mahila Coir Yojana | child of SCH000035 |
| D4 | DRAFT schemes in the app | hide from bundle |
| D5 | Machine Tamil for the 83 new schemes | leave English-only |
| D6 | Staging tables `*_new_v3_1` | drop in this release |
| D7 | Revoke anon+authenticated EXECUTE on `public.create_scheme_draft` | YES |

If any answer is still in `<...>` form, stop and ask. Do not guess.

## Hard rules

1. **Evidence or it didn't happen.** Every number and claim in your reports must come with the exact query or command and its raw output, pasted right next to it. Re-run every query **after** the last write of the phase. The last report quoted validation numbers that were later invalidated (parent_of 85 → actually 36); that must not happen again. Never write "verified", "proven", "100%" or "PASSED" without the output beside it.
2. **Don't weaken tests to make them pass.** You may change a count only when the new count is the correct expected value **and** you explain why in the report. You may not:
   - replace a general assertion with a hard-coded number (e.g. `documentsMappedCount == 251`)
   - change an assertion so that it accepts a bug (e.g. "Archived … remain active in UI adapter")
   - regenerate golden/parity files without first showing the ranking diff for the queries that changed
3. **One shape for all catalog records.** Every scheme row must have exactly the same `record_json` key structure as the existing records, using `SCH000124` from `HEAD:saarthi-agent/data/scheme_catalog.json` as the reference. The same applies to `applicability_matrix` (reference: `APLM000124`) and `search_index` (reference: the SCH000124 row). Build new records **from the reference skeleton** with the reference generators, not from scratch.
4. **Make changes the repo's way.** Every DB change goes through migration files applied with the Supabase CLI, so that they appear in `supabase_migrations.schema_migrations`. After that: regenerate the bundle, publish `1.35.1-alpha` with `tools/publish_catalog_release.py`, and cache-bust. No ad-hoc SQL writes.
5. **Scope.** Only catalog data, the catalog scripts and tests, the release, and the security fix in Phase F. Do not touch:
   - Flutter UI or the l10n files
   - `CLAUDE.md` or `.gitattributes`
   - auth, RLS on non-catalog tables, voice
   - `AppStateProvider`
6. **Stop at every gate** (end of each phase). Wait for "continue".

## Using agents and skills

- **Skills:** load the installed `supabase` and `supabase-postgres-best-practices` skills (see `skills-lock.json`) before Phase A. Skills guide *how* to do things; they do not widen scope, and these rules win if they conflict.
- **Agents:** sub-agents may only do read-only work or generate files in parallel. Examples:
  - one per batch of ~20 schemes for record rebuilding (keep each parent in the same batch as its children)
  - one for the test review
  - one for URL HEAD checks
- **Only the main agent** writes to the database, applies migrations, regenerates the bundle or publishes. It re-validates every sub-agent output itself before using it.
- **Graph:** use `graphify query` / `graphify explain` to find every consumer of a field before changing its shape (e.g. `graphify query "who reads content.classification"`). Run `graphify update .` at the end. Do **not** commit `graphify-out/`.

---

## Phase A: Re-audit (read-only)

Run and paste the output of each:
1. **Key-shape diff.** For every `record_json` path (to depth 4), list the keys that are present in all 219 old schemes but missing in any new one, and the keys that are extra in new ones. Do the same for `applicability_matrix` and `search_index`.
2. **Relationship symmetry.** Count `child_of` rows that have no matching `parent_of`, and the reverse. List them.
3. **Columns.** Count new rows (`SCH000220`–`SCH000302`) where `scheme_type`, `government_level`, `ministry`, `department` or `name_ta` is NULL.
4. **Status matrix.** Every distinct (`status`, `is_active`, `record_json.identity.status`) combination, with counts and IDs, for any combination outside {PUBLISHED/true/active, DRAFT/false/unknown, ARCHIVED/false/closed}.
5. **Migration history.** List `supabase_migrations.schema_migrations` against `backend/supabase/migrations/`, and every file not recorded remotely.
6. **Git.** Run `git status`, `git log main..HEAD --oneline | wc -l`, and list the untracked files over 1 MB.
7. **Consumers.** Use graphify plus grep to list every Dart, TS and Python consumer of: `content.classification`, `structured.*.applies`/`minYears`/`maxYears`, `benefitTypes`, `targetBeneficiaries`, `objectives`, and `identity.status`.

**GATE A.** Report the numbers and confirm they match the audit. If anything differs, explain why.

## Phase B: Rebuild the 83 new records to the catalog shape (files only, no DB)

In `scripts/catalog_v3_1/rebuild_to_reference_shape.py`, for each new scheme:

1. **Start from the reference skeleton.** Deep-copy SCH000124's `record_json` structure with every leaf set to null, empty list or empty object exactly as the old records do. Then fill it.
2. **classification.** Move the top-level `classification` into `content.classification` with the reference fields: `government{level, levelText, ministryId, ministryText, departmentId, departmentText, states, statesText, country, districts, districtsText, implementingAgencyIds, implementingAgencyText}`, `schemeType`, `schemeTypeText`, `sectors`, `sectorsText`, `categories`, `tags`. `schemeType` must be a value from the existing `common_catalog` scheme_type vocabulary.
3. **Columns.** Fill `scheme_type`, `government_level`, `ministry`, `department` and `state` from the same values, using the same rule as the existing generator.
4. **benefits.** Fill `benefitTypes` from the buckets that have `applicable=true`. Add `equitySupport` to the skeleton. Format every `*Text` amount with the app's `formatInr` rules (lakh/crore, e.g. `₹2.5 crore`, `₹15 lakh`, `₹15,000`). Also fix the 6 existing fields on SCH000103, SCH000136 and SCH000144.
5. **eligibility.structured.** Convert to the reference facet shape: `{text, applies, minYears, maxYears}` for age; `{text, applies, values}` for gender, community, specialCategory and businessStage; `{text, applies, included, excluded}` for sector; `{text, applies, types, constitution}` for enterprise; `{text, applies, states, districts, areaTypes, country}` for location; `{text, applies, required}` for existingRegistration; `{text, applies, minInr, maxInr}` for turnover and investment.
   - `applies=true` **only** when the source actually restricts on that facet.
   - Do not set `location.areaTypes = ["rural","urban"]` for schemes that apply everywhere; that is not a restriction.
   - `narrative.criteria` must be a **string** (join the points), as in the reference.
6. **Other content fields.**
   - `content.objectives[]` and `overview.objective` come from the description points; drop `overview.objectives` and `overview.keyPointers`.
   - Fill `content.targetBeneficiaries` from targeting.
   - Add `applicationTimeline` and `faqs` with the reference null/empty values.
7. **applicationProcess.steps.** Replace the generic "Step N" titles with a short imperative title taken from the step text (≤ 6 words, e.g. "Apply at participating bank").
8. **ai / analytics / provenance / verification.**
   - Add `ai` and `analytics` exactly as the existing pipeline does. If an `ai` generator exists (`mss-ai-derive`), say so and use it. Otherwise use the reference null skeleton with `reviewRequired: true`.
   - Fill `provenance.primarySourceId`, `contributingSourceIds`, `fieldSources`, `extractedAt`, `extractionMethod` and `defaultSourceTier`.
   - Fill `verification.isVerified`, `researchStatus` and `missingFields`. List every empty section in `missingFields` the same way old records do: documents, contacts, timeline, Tamil.
9. **Hindi.** Store `null`, never `""`. Remove the Hindi name on SCH000101 (a generic 2015 name, wrong for MSME Global Mart). For each of the other 2015 name-only rows, list the Hindi name next to the English name so Kishaunjith can reject any that look wrong.
10. **applicability_matrix and search_index.** Rebuild the 83 matrix rows with the **existing** `build_applicability_matrix.py`, the same way old rows were made: gender, community, location, specialCategory, enterpriseType, sector, businessStage, districtText, sectorText. Rebuild the 83 search_index rows with the existing search generator, so content includes keywords and aliases the same way as old rows. No raw v3.1 `targeting` blocks.
11. **Tamil (only if D5 = run).** Use the existing Tamil pipeline. Mark the result `provenance.translations.ta.status = "machine"`, `reviewRequired: true`.
12. **Validator.** Write `scripts/catalog_v3_1/validate_shape.py`. It fails if any scheme, matrix or search row's key structure differs from the reference, or if any facet uses `applicable`/`min`/`max` keys. Run it on all 302 schemes.

**GATE B.** Report:
- validator output (0 failures)
- 3 full before/after diffs: SCH000255 (MCGS), SCH000289 (PM Surya Ghar), SCH000220 (PMEGP 2nd loan)
- a table of the 83 rows' `scheme_type`, `government_level` and `ministry` values

## Phase C: Relationships and status fixes (one migration, test on a branch DB)

Migration `<ts>_catalog_v3_1_fix_relationships_and_status.sql`:

1. **parent_of.** Insert a matching `parent_of` for every `child_of` that lacks one (49 rows). Update `record_json.relationships.references` on both sides, in the existing style.
2. **Successor links.**
   - Add `related_to` from SCH000043 → SCH000302 and back, with metadata `{"relation":"successor"}`.
   - Do the same from SCH000070 → SCH000258 (NEW2026-004, interest subvention under the Export Promotion Mission; confirm in `reports/id_map.csv`).
3. **Duplicates (apply D1/D2/D3).** An archived duplicate gets DB `status='ARCHIVED'`, `is_active=false`, `identity.status='closed'` (the app contract has three values: active / closed / unknown), and a `merged_into` / `duplicate_of` link to the canonical row. This covers SCH000168 always, and SCH000055 / SCH000064 / SCH000082 as decided. If D2 = NO, restore SCH000064 to its pre-migration values from `HEAD:saarthi-agent/data/scheme_catalog.json`.
4. **CGTMSE (SCH000038).**
   - Set `guarantee.maxCoverInr = 100000000` (₹10 crore, w.e.f. 01.04.2025).
   - Add the condition "Booklet 2025-26 text states ₹5 crore; ceiling enhanced to ₹10 crore w.e.f. 01.04.2025".
   - Add the source and a `verification.notes` entry.
5. **D6 = drop:** drop the four `*_new_v3_1` staging tables. Keep `scheme_source_v3_1`, and set `ALTER TABLE … FORCE ROW LEVEL SECURITY` on it.

**GATE C.** Report:
- branch DB results for every Phase A query
- asymmetric count = 0
- status matrix with only the three allowed combinations

## Phase D: Apply data migration B, plus repair the migration history

1. Generate one data migration from the Phase B output: `<ts>_catalog_v3_1_reshape_new_records.sql`. Use `UPDATE`s keyed by id, not delete-and-reinsert.
2. Use `supabase migration repair --status applied` to record the five `20261004*` migrations that were already applied by hand, **after** confirming their effects are present. Do the same for the five September files missing from the remote history, if their effects are present. If any effect is not present, report it; do not mark it applied.
3. Apply the Phase C and D migrations to a branch DB first, then (after approval) to production, with `supabase db push`.

**GATE D.** Report the `schema_migrations` listing showing every local file recorded, and all Phase A queries re-run on production.

## Phase E: Tests (restore their meaning), bundle, release

1. **Revert the weakened assertions:**
   - `documentsMappedCount == totalSchemes`. If some schemes really have no documents, assert that every scheme without documents lists `content.requiredDocuments` in `verification.missingFields`.
   - Delete the "Archived … remain active" assertion. Assert instead that no scheme in the bundle has an `identity.status` outside {active, closed, unknown}, and that closed schemes are not active.
2. **Add new tests:**
   - Shape contract: every scheme has the reference key structure (port `validate_shape.py` to a Dart test on the bundle).
   - For SCH000255, `SchemeHeaderResolver` returns non-empty ministry and scheme type.
   - For SCH000255, the eligibility resolver produces the structured facets.
   - Every `child_of` has a matching `parent_of` in the bundle.
3. **Golden/parity files.** Show the top-5 diff per golden query between 1.34.3 and the new data. Regenerate only after the diff is listed in the report.
4. **D4 = hide:** filter `status <> 'PUBLISHED'` rows out of the bundle in the bundle generator. Update the counts tests with the reason.
5. Regenerate the bundle and publish **1.35.1-alpha** with `tools/publish_catalog_release.py`. Then check:
   - DB SHA = `release.json` = local gz = storage object (paste all four)
   - `record_counts`
   - **HEAD-check every `scheme_url` of the 83 new rows plus the 30 enriched rows; report non-200s.**
6. Run `flutter test` and `flutter analyze`. Paste the summary lines plus the names of any skipped tests.
7. **Device check (Windows host).**
   - Run the app in debug on an emulator.
   - Screenshot the detail screen for SCH000255, SCH000289 and SCH000124 (header, eligibility, benefits, how to apply), in English and Tamil.
   - Screenshot the PMEGP (SCH000130) parent screen showing its 2nd-loan component.
   - Screenshot "For Me" for a test profile (e.g. 30-year-old woman, Tamil Nadu, micro manufacturing): MCGS must appear, and PM Internship (SCH000279, age 21–24) must not.

**GATE E.** Report the screenshots and outputs.

## Phase F: Security (only if D7 = YES)

1. Migration: `REVOKE EXECUTE ON FUNCTION public.create_scheme_draft(...) FROM anon, authenticated, public;` and set `search_path`.
2. Before changing `check_support_ticket_rate_limit` and `mss_current_release` (both anon-executable definer functions), list which app code calls them, using graphify plus grep. Do not change them unless the app does not need anon access; report instead.
3. Re-run the security advisor and paste the result.

## Phase G: Git and handoff

1. **Rebase.** Rebase the catalog work onto `main` so the PR does not carry the 35 `fix/production-readiness` commits. If that's not possible cleanly, stop and report.
2. **Commit only catalog changes:**
   - migrations
   - `scripts/catalog_v3_1/` (no `__pycache__`, no `temp_check.sql`)
   - tests
   - bundle and `release.json`
   - `saarthi-agent/data/*`
   - `docs/catalog_v3_1_mapping.md`
   - `reports/`
3. **Do not commit:**
   - `CLAUDE.md`, `.gitattributes`, `app_localizations_ta.dart`: leave these unstaged for Kishaunjith.
   - `graphify-out/`: add it to `.gitignore`.
   - `docs/backend/mss_scheme_data_v3_1/`: leave it unstaged and ask.
4. **Run `graphify update .`** but do not commit the output.
5. **Rewrite `CATALOG_V3_1_MIGRATION_REPORT.md`.**
   - Correct the false statements listed in the audit (§2 P1-3 and §3).
   - Every number must have its query beside it.
   - Add a "Known open items" section listing anything not done.
6. Open the PR. Its description lists D1–D7 as decided, all open items, and the device screenshots.
