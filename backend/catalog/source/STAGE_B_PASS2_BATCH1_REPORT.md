# Stage B — Pass 2 (Fill-Only Enrichment), Batch 1 — Report

**Scope:** `SCH000001`–`SCH000025` only, per explicit user instruction to run one
full end-to-end enrichment cycle before touching batches 2–9. Goal: verified
missing-data completion, not URL verification (that was Pass 1).

## Schemes processed

25 (`SCH000001`–`SCH000025`). 9 fields filled across 9 records. 16 records
in the batch received no fill this pass — either because targeted fields
were already populated, or because no evidence meeting the policy's tier/domain
bar was found (see "Still missing" below).

## Fields added

| Scheme | Field | Value | Source | Tier | Confidence |
|---|---|---|---|---|---|
| SCH000006 | `identity.status` | `active` | dcmsme.gov.in operational guidelines page | 5 | medium |
| SCH000016 | `content.applicationProcess.mode` | `online` | aim.gov.in | 5 | high |
| SCH000017 | `content.applicationProcess.mode` | `online` | msmeonline.tn.gov.in | 5 | medium |
| SCH000021 | `content.applicationProcess.mode` | `online` | istart.rajasthan.gov.in | 5 | medium |
| SCH000014 | `content.overview.lastUpdated` | `2024-01-03` | aim.gov.in/atal-incubation-centres.php | 5 | high |
| SCH000018 | `content.overview.lastUpdated` | `2025-08-19` | nsic.co.in/Schemes/CreditFacilitationThroughBank | 5 | high |
| SCH000020 | `content.overview.lastUpdated` | `2026-08-03` | spniwcd.wcd.gov.in/beti-bachao-beti-padhao | 5 | high |
| SCH000011 | `content.contacts.national[]` | SIDBI HQ phone (4 numbers) | sidbi.in | 5 | medium |
| SCH000012 | `content.contacts.national[]` | SIDBI HQ phone (4 numbers) | sidbi.in | 5 | medium |

Every addition carries a full `provenance.fieldSources[]` entry (URL, tier,
organization, `retrievedAt: 2026-08-14`, confidence, `isBackfill: true`,
`supersededValue: null`). Nothing outside these 9 fields changed — verified by
a hard guard in `stage_b_pass2.py` that snapshots every record before the run
and aborts if anything other than the 9 intended paths differs (0 aborts).

`content.applicationProcess.mode` was mapped to the value `"online"` only —
the catalog's existing controlled vocabulary (already used on 44 other
records) — never a new enum value invented for this run (see "Investigated
and rejected" below on why `"offline"` was deliberately not introduced).

## Investigated and rejected (not filled, and why)

These were checked against available Pass-1 evidence and explicitly **not**
filled, to keep the "never fabricate" rule real rather than nominal:

- **`content.classification.government.ministryId` / `departmentId` /
  `implementingAgencyIds`** (still null on 13 / 5 / 3 records respectively in
  this batch) — **already fully resolved** by the existing `build_phase4.py`
  pass (exact normalised-name join against `authority_catalog.json`, rule R1).
  Checked every remaining null directly: the source text is either
  `"Not applicable (State scheme)"`, `null`, `"Not specified in a current
  official source located"`, or a generic phrase with no proper authority
  name (e.g. `"Government of Tamil Nadu social welfare administration"`), or
  a genuine name with no matching entry in the 124-record authority catalog
  (`"Government of Rajasthan"` — not present at all). No further tier-2 match
  is possible without creating new authority entities, which is out of scope.
- **`content.applicationProcess.mode` for SCH000018** (NSIC branch scheme) —
  stored `modeText` reads *"Approach nearest NSIC branch / show interest
  through NSIC"*, i.e. an in-person process, not an online portal, even
  though an `onlineUrl` is on record (it points to the scheme's descriptive
  page, not an application portal). Mapping it to `"online"` would have been
  wrong. The catalog has no `"offline"`/in-person enum value anywhere (only
  `"online"` is used, 44 times) — introducing one is a vocabulary decision
  outside this pass's scope, so the field was left `null` rather than force
  a fit. Same reasoning applied to SCH000013 (addressed to a named official —
  offline in substance) and SCH000025 (AIF partner-fund process, not a direct
  application channel) — left null.
- **`identity.status` for SCH000021** (Bhamashah Techno Fund via iStart
  Rajasthan) — the iStart portal itself is confirmed live, but that only
  proves the *portal* is active, not this specific fund, which can close
  while the portal stays up. No fund-specific confirmation was fetched.
  Left `unknown` rather than inferred from the parent portal's liveness.
- **`identity.status` for SCH000019** (Beekeeping GVY) — its only source is
  `kviconline.gov.in`, which failed DNS resolution in Pass 1. I initially
  assumed it shared the same DCMSME operational-guidelines page as SCH000006
  (Agarbatti); checking the actual queue mapping showed it does not — SCH000019
  has no successfully-fetched source at all. Left `unknown`.
- **`content.overview.lastUpdated` for SCH000006 / SCH000009 / SCH000019 /
  SCH000022 and others** — either no page-level "last updated" marker was
  visible in the fetch, or the only date found (e.g. DCMSME homepage footer:
  "11 Aug 2026") belongs to the site's global footer, not the specific scheme
  subpage, so attributing it to that scheme's `lastUpdated` would misrepresent
  the source. Left `null`.

## Fields still missing after this pass

Unchanged from Pass 1 baseline for everything not listed above — in
particular, for the whole batch:

- `content.applicationProcess.steps` (25/25) — no source in hand describes a
  numbered application procedure; would need per-scheme portal navigation
  beyond a single homepage/description fetch, not attempted this pass.
- `content.applicationTimeline` (25/25) — no cycle/deadline data found on any
  fetched page.
- `content.contacts.state` / `.district` / `.helplines` (25/25, and
  `.national` on 23/25) — SIDBI (2 records) is the only case with a clean,
  attributable contact number on an approved domain.
- `content.applicationProcess.onlineUrl` (still null on 9/25 after this pass)
  — SCH000005, 6, 9, 11, 12, 13, 15, 19, 22 — no confirmed application-portal
  URL found; several of these sources are unreachable (see Pass 1 report:
  cert failure, DNS failure, HTTP 403) or point to descriptive pages rather
  than an application channel.
- `localization.hi` (all 217, not just this batch) — the project's existing
  Tamil localisation was done as its own dedicated `build_i18n.py` pass with
  a proper translation-provenance schema (`ta_overrides.json`,
  `dictionaryVersion`, `fieldMethods`, batch-wide consistency). Doing Hindi
  ad hoc for 25 records here would fragment that approach and leave 192
  records inconsistent with these 25. Recommend running Hindi as its own
  dedicated pass across all 217, mirroring how Tamil was done, not folding it
  into Stage B batches.

## Manual review required

- **SIDBI contacts (SCH000011, SCH000012)**: both schemes already carry
  `identity.status: "closed"` (historical facility). The added contact is
  SIDBI's general institutional HQ number, not a scheme-specific helpline —
  flagged in the `fieldSources[]` note so a human can judge whether a closed
  scheme should surface a live contact number at all, or whether it's still
  useful as "who to ask about this historical scheme."
- **21 disputed/unreachable URLs from Pass 1** (`tnlegalservices.tn.gov.in`
  cert failure, `www.msme.gov.in` 403, `www.kviconline.gov.in` /
  `dbtindia.gov.in` DNS failure, `www.dgft.gov.in` "Page Moved") continue to
  block any Pass 2 fill that would have relied on them (SCH000005, 7, 9, 13,
  19, 22 in particular). These need a human retry — possibly via a
  browser-rendered fetch or a different entry URL — before Pass 2 can add
  anything for those schemes.
- **`"offline"` enum decision**: at least 2 schemes in this batch alone
  (SCH000013, SCH000018) have clear evidence of an in-person/offline
  application process with nowhere valid to record it as an enum value.
  Recommend a deliberate schema decision (not an inline Stage B change) on
  whether to add `"offline"` to `content.applicationProcess.mode`'s
  vocabulary.

## Validation

Ran after apply:

```
validate_base.py scheme_catalog.json   -> BASE VALIDATION PASSED — rules 1-30
validate_catalog.py                    -> VALIDATION PASSED — base 1-30, scheme 31-45, policy, batch gates
validate_cross_catalog.py              -> CROSS-CATALOG PASSED — 8012 references checked, 0 asymmetric
```

Also confirmed directly: all 217 `identity.id`s unchanged and in the same
order before/after; record count unchanged (217); no `content` field changed
outside the 9 targeted paths (guard in `stage_b_pass2.py`, 0 aborts).

`scheme_catalog.json` version: `1.33.0-alpha+stageb.pass1.batch1` →
`1.33.0-alpha+stageb.pass1.batch1+stageb.pass2.batch1`. `manifest.json`'s
scheme-file entry updated (checksum, byte size); release-level fields
untouched, same discipline as the Pass 1 batch-1 apply.

## Stop point

Per instruction, **batches 2–9 do not start until this report is reviewed and
approved.**
