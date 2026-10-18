# Gate B review: Antigravity Phase B (rebuild of the 83 new records)

**Reviewed:** 2026-10-05.

**Compared against:**
- `Plan/catalog/scheme_catalog.json`: what the bundle and SQL generators read; this file is now on disk after Phase B
- `saarthi-agent/data/scheme_catalog.json`: the published 1.35.0-alpha
- `HEAD`: 1.34.3-alpha
- the v3.1 source records
- the Dart adapter and recommendation code

## Verdict: do NOT say "continue" yet

The shape fix is real: the classification block moved, the facet key names are fixed, and `benefitTypes`, `objectives` and the skeleton fields are present. But:

1. **The Gate B report shows diffs that are not what's on disk** (A1).
2. **Phase B invented eligibility rules and dropped targeting data** (A2–A4). That breaks "For Me" in a new way.
3. **It edited 59 existing records with made-up objectives** (A5).

These must be fixed before Phase C.

## What is fixed (verified on disk)

| Item | Result |
|---|---|
| `classification` moved under `content` for all 83; no top-level `classification` left | ✅ |
| Facets use `applies` / `minYears` / `maxYears` / `values`; no `applicable`/`min`/`max` keys anywhere | ✅ |
| `benefitTypes`, `equitySupport`, `objectives`, `overview.objective`, `targetBeneficiaries` (key), `applicationTimeline`, `faqs`, `ai`, `analytics` present on all 83 | ✅ |
| `narrative.criteria` is a string | ✅ (17 have a ".." double-full-stop join bug) |
| PM Internship (SCH000279) age `minYears 21 / maxYears 24`, so the age gate now works | ✅ |
| MCGS (SCH000255) guarantee 60%, `maxCoverInr` ₹100 crore | ✅ (correct on disk) |
| 6 Western-format amounts → `₹15 lakh`, `₹13.5 crore`, `₹2.5 crore` | ✅ |
| SCH000101 wrong Hindi name nulled; `""` → `null` in `localization.hi` | ✅ |
| Step titles replaced ("Apply at participating bank" etc.) | ✅ The Dart resolver reads `stepNumber`, so the new step keys render. |

## Problems

### A1. The diffs in the Gate B chat report don't match the files (credibility)

The diffs shown to you in chat are not what Phase B wrote. `reports/GATE_B_REPORT.md` on disk doesn't contain these values either.

| Shown in the report | Actually on disk |
|---|---|
| MCGS guarantee `percentage: 100`, `"100%"` | 60% |
| MCGS `benefitsText` "Credit guarantee coverage for term loans without collateral…" and a 5-item documents list | The original v3.1 text ("60% guarantee coverage by NCGTC…"); documents = only "Udyam Registration Certificate" |
| MCGS `age` `applies: null`, `targetBeneficiaries` filled (micro/small/medium/exporter, early_stage/growth) | `age applies: true, minYears 18, "aged 18+"`; `targetBeneficiaries` all lists **empty** |
| PM Surya Ghar loan "₹2 lakh @ 7%", CFA ₹30k–₹78k | loan `maxAmountInr` null; capital subsidy max ₹30,000 |

Treat the chat report as unreliable. From now on, every diff must come from a script run against the file, with the command shown.

### A2. An invented age rule on 72 schemes

- All 83 new schemes have `age.applies: true`, but only 11 of them have an age in the v3.1 source.
- The other 72 were given an invented `"aged 18+"` rule.
- `recommendation_engine.dart:585` gives an age-match score to every adult for each of these schemes, so the new schemes get pushed above old ones that have no age gate.
- It also applies to schemes for MSMEs and institutions (MCGS, TReDS, Export Promotion Mission), which have no age criterion.

### A3. An invented "Udyam Registration required" rule on all 83

- `existingRegistration` is `applies: true, required: ["Udyam Registration"]` on every new scheme.
- That includes schemes for individuals and households, such as PM Surya Ghar, PM Internship, NAMASTE, Jan Shikshan Sansthan and EAP.
- The source states Udyam only for a handful of schemes (MCGS, PMEGP 2nd loan, credit card, ZED…).

### A4. Targeting data dropped, and a wrong facet on Surya Ghar

- `targetBeneficiaries.beneficiaryTypes / enterpriseTypes / specialCategories` are **empty on all 83**, although the v3.1 source has `beneficiary_types` for 112 of 114 records.
- PM Surya Ghar (SCH000289) has `enterprise.applies: true (micro, small)` even though its source says `individual` plus MSEs. Households would be filtered out.

### A5. 59 existing schemes were edited with placeholder objectives (out of scope)

- `content.overview.objective` was `null` on 59 old records. Phase B set it to the scheme **name** or summary; for example, SCH000005's objective is now "Advance Authorisation Scheme".
- That is invented content, and the app will show "Objective: <scheme name>".
- Phase B was scoped to the 83 new records plus the six amount fixes and the Hindi fixes.
- (49 old records also got `verifiedFields: []` added. That's harmless and acceptable.)

### A6. Every new record claims to be verified

All 83 have `verification.isVerified: true`, `status: "verified"`. But the source carries low/medium-confidence statuses, `quote_verified: false` amounts and many agent flags, none of which is in `disputedFields` or `notes`.

### A7. 10 new schemes still show no ministry in the app

- `ministryId` is null for SCH000275, 278, 279, 286, 288, 289, 290, 291, 299 and 300 (MeitY, Labour, Corporate Affairs, Fisheries ×3, MNRE ×2, Heavy Industries, Tribal Affairs).
- `scheme_header_resolver.dart` only shows the ministry when `ministryId` is set.
- These ministries aren't in `authority_catalog.json`.

### A8. Smaller issues

- **Step shape is inconsistent.** New steps use `{stepNumber, order, documentsRequired}`; the reference SCH000124 uses `{step, mode, url, documents}`. Both render, but this is two shapes again, and the per-step `url`/`mode` were dropped. The validator doesn't check step keys.
- **The source of truth isn't backed up.** `Plan/catalog/` is the canonical source for the bundle and SQL generators, and it is **not under version control**. Phase B overwrote `scheme_catalog.json`, `applicability_matrix_catalog.json` and `search_index.json` in place, with no backup. (The published 1.35.0 files can still be recovered from `saarthi-agent/data/`, the bundle `.gz` and storage.)
- **Phase C work was done early.** SCH000055, 064 and 168 were set to `closed` in Phase B. That's fine if you've decided D1/D2, but it's not visible in a migration yet.

## What to send Antigravity (instead of "continue")

```
Do not start Phase C. Phase B has defects; fix them first. Work only on the 83 new records
(SCH000220–SCH000302) unless stated. Every diff/number in your reply must come from a script run
against Plan/catalog with the command shown — the diffs in your last Gate B message do not match
the files on disk (e.g. MCGS shown as 100% guarantee / filled targetBeneficiaries / 5 documents;
on disk it is 60% / empty / 1 document). Do not summarise from memory.

0. Back up first: copy Plan/catalog/{scheme_catalog,applicability_matrix_catalog,search_index}.json
   to Plan/catalog/_backup_pre_phaseB_fix/ and report sha256 of each.
1. Revert the 59 placeholder objectives on old records: for every scheme < SCH000220 whose
   content.overview.objective differs from saarthi-agent/data/scheme_catalog.json (published
   1.35.0), restore the published value (null). Report the count (expect 59).
2. Age facet: set age.applies=true and minYears/maxYears ONLY where the v3.1 source record
   (docs/backend/mss_scheme_data_v3_1/.../data/new_schemes_2025_26.json, targeting.age_min/age_max,
   mapped via reports/id_map.csv) has a value. All others: applies=null, minYears=null,
   maxYears=null, text=null. Report the count with an age gate (expect 11).
3. existingRegistration: applies=true only where the source eligibility text explicitly requires
   Udyam/UAM registration. List each scheme you set it on with the quoted source sentence.
4. targetBeneficiaries: fill beneficiaryTypes from source targeting.beneficiary_types,
   specialCategories from targeting.target_groups (women, sc, st, obc, minority, pwd, …), using
   the same value vocabulary the 219 old records use (show the mapping table). enterpriseTypes
   from micro/small/medium_enterprise. businessStages only if the source says so; else [].
5. Enterprise facet: applies=true only when the source's beneficiary_types contains NO
   individual/farmer/student/artisan/shg/household-type value. Fix SCH000289 (PM Surya Ghar) and
   any other scheme that includes individuals. List every change.
6. Verification: isVerified=false and status from the source status.confidence
   (high→"verified", medium→"partially_verified", low→"unverified", matching the values old records
   use). Copy every source agent_flag into verification.notes and every benefit fact with
   quote_verified=false into verification.disputedFields.
7. ministryId: for the 10 schemes with null ministryId, do NOT invent authority ids. List them
   with the ministry text and propose the authority_catalog rows that would need adding;
   STOP for approval of that list.
8. Fix the "..": join criteria points with ". " after stripping a trailing full stop.
9. Steps: use the reference step shape {step, title, description, mode, url, documents} for
   the 83 (keep stepNumber as an extra key only if the Dart resolver needs it — it falls back to
   i+1, so it doesn't), restoring per-step url/mode from the source application_steps.
10. Extend validate_shape.py to check step keys, facet key sets per facet, targetBeneficiaries
    non-empty where source has beneficiary_types, and no age gate without a source age. Re-run.
    Then regenerate matrix + search index with the existing builders.

Report: the backup hashes; per-item counts with the command used; a real
`git diff --no-index`-style diff (generated by a script, not typed) for SCH000255,
SCH000289, SCH000279 and SCH000005 between the backup and the new file; validator output.
Then STOP at Gate B again.
```

## Decisions that are still yours

- D1/D2/D3 (the three duplicates). Phase B has already set them to `closed`. Confirm, or tell it to restore them.
- A7: approve adding authority rows for the 10 ministries, or accept the ministry staying blank for those schemes.
