# Stage B — Pass 2 (Fill-Only Enrichment), Batches 2–9 — Report

Extends `STAGE_B_PASS2_BATCH1_REPORT.md`'s pattern to the remaining 192
schemes, using only evidence already captured in batches 2–9's Pass 1
`results_N.json` notes (no new fetches this pass).

## Fields added

7 fills, all `content.applicationProcess.mode = "online"`, each backed by a
specific on-site statement (not just "the ministry has a website"):

| Scheme | Source | Evidence |
|---|---|---|
| SCH000092 | cluster.dcmsme.gov.in | Application procedures for Common Facility Centers described directly on-site |
| SCH000109 | pmvikas.minorityaffairs.gov.in | "login and registration options for various stakeholder groups" |
| SCH000123 | pmsvanidhi.mohua.gov.in | "loan applications, dashboards, and scheme information" |
| SCH000124 | pmvishwakarma.gov.in | "registration processes, multiple login portals for different user categories" |
| SCH000127 | pmmvy.wcd.gov.in | "application tracking, grievance filing" |
| SCH000152 | sidbi.in/en/business-loan | "Quick straight-through process" loan product page |
| SCH000196 | udyamregistration.gov.in | "the only Government Portal for MSME (Udyam) Registration" |

Guard-verified 0 fields changed outside these 7 `mode` values (plus their
`provenance.fieldSources[]`/`verification.missingFields[]` bookkeeping).

## Deliberately not filled, and why

- **`identity.status`**: every "unknown"-status candidate's only Pass-1
  evidence was a department/ministry *homepage* confirmation (SIDBI, TN
  MSME Online, TANSIDCO, DST, etc.), not scheme-specific live data. That's
  a materially weaker signal than the AABCS/NEEDS/UYEGP live-FY-application-stats
  pattern that justified fills in batch 1 — a live homepage doesn't confirm
  a specific scheme under it is still active. None filled.
- **`content.overview.lastUpdated`**: every "last updated" date found (BIRAC,
  WCD, DST, TN Govt) was a *homepage footer* date, not the specific scheme
  page's own date — same rejection already applied to DCMSME's homepage
  footer in the batch-1 report. None filled.
- **Contacts**: no phone/email numbers were captured in this round's
  `results_N.json` notes (batches 2–9's Pass 1 focused on domain/content
  confirmation, not contact extraction). Re-fetching to extract contacts
  would be new Pass-1 work, out of scope for a fill-only Pass 2 over
  already-verified evidence — logged as a follow-up, not fabricated.
- Two borderline candidates considered and dropped for insufficient
  directness: PMUY (application actually happens via third-party Oil
  Marketing Company portals, not pmuy.gov.in itself) and Skill India
  Digital Hub (a learning platform, not clearly an application mechanism
  for a specific scheme benefit).

## Validation

```
validate_base.py scheme_catalog.json   -> BASE VALIDATION PASSED — rules 1-30
validate_catalog.py                    -> VALIDATION PASSED — base 1-30, scheme 31-45, policy, batch gates
validate_cross_catalog.py              -> CROSS-CATALOG PASSED — 8880 references, 0 asymmetric
validate_i18n.py                       -> I18N INVARIANTS PASSED
```

217 `identity.id`s unchanged, same order. `finance_catalog.json`,
`tax_catalog.json`, `treds_catalog.json`, `csr_catalog.json` untouched.

`scheme_catalog.json` version now carries `+stageb.pass2.batches2-9`
appended to the full prior chain; `manifest.json`'s scheme-file entry
updated, release-level fields untouched.

## Status of Stage B overall

Pass 1: complete, all 217 schemes (batches 1–9).
Pass 2: batch 1 (25 schemes, 9 fills) + batches 2–9 (192 schemes, 7 fills)
— 16 total fills across 217 schemes. The low fill count for batches 2–9
relative to batch 1 reflects that Pass 1 verification calls for these
batches mostly confirmed *domain/institution* identity (homepage checks)
rather than fetching scheme-specific application/eligibility pages the way
batch 1's queue happened to include (AABCS, NEEDS, UYEGP description pages
were specifically in scope there). Remaining `null` fields across all 217
schemes stay honestly `null`, logged in each record's
`verification.missingFields[]`.
