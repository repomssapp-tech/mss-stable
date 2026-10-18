# Stage B — Pass 1 (Verification), Batch 1 — Report

**Scope of this pilot:** scheme catalog only, batch 1 of 9 (`SCH000001`–`SCH000025`),
per the user's decision to pilot one entity end-to-end before extending further.
Phases 1–3 of the requested workflow (inventory, architecture, baseline) already
exist as living documents in this repo and were not duplicated — see "Existing
documentation used" below.

## What ran

`catalog/stage_b.py queue 1` had already produced `queue_1.json` (31 distinct
URLs, 56 field references, 3 skipped as non-approved hosts) in an earlier
session; 6 of the 31 URLs had results recorded. This run:

1. Fetched the remaining 25 URLs via `WebFetch`, restricted to `content.sources[].url`
   and `content.applicationProcess.onlineUrl` fields already present in the
   frozen Stage-A baseline (Pass 1 only *confirms existing values* — it never
   writes to `content`, per `MSS_Data_Completion_Policy_v1.0.md` §4.4.1).
2. Recorded every outcome in `results_1.json` (ok/unreachable + note + retrieval
   date, 2026-08-14).
3. Ran `stage_b.py apply 1`, which writes only to `verification.verifiedFields[]`
   / `verification.disputedFields[]` and is guarded to abort if any `content`
   block changes.

## Result

- 23 of 25 scheme records in the batch got at least one verification entry.
- 56 field references processed: **35 confirmed**, **21 unreachable** (baseline
  retained, flagged for human review — never overwritten, per policy §3.1 rule 4).
- Guard passed: **0 content mutations**. Confirmed via `validate_base.py`,
  `validate_catalog.py`, `validate_cross_catalog.py` — all green after apply.
- `scheme_catalog.json` version: `1.33.0-alpha` → `1.33.0-alpha+stageb.pass1.batch1`.
  `manifest.json`'s scheme-file entry (checksum, byte size) updated; the
  release-wide `catalogRelease` (shared by 10 other files) was left untouched.

### Unreachable / disputed (21) — needs human follow-up, not auto-resolved

| Host issue | URLs affected |
|---|---|
| TLS certificate failure | `tnlegalservices.tn.gov.in` (×2) |
| HTTP 403 | `www.msme.gov.in` (×2 paths) |
| DNS failure | `www.kviconline.gov.in`, `dbtindia.gov.in` |
| "Page Moved" / no content | `www.dgft.gov.in` |
| Client-rendered / empty body (from earlier session) | `www.msmeonline.tn.gov.in` (×2 paths) |
| Reachable but binary/PDF text not extractable — reachability confirmed, content unconfirmed | 5 PDFs (dgft, aim, msmeonline×2, istart.rajasthan) |

None of these caused a content change — they're recorded as disputes for
whoever does the human/manual follow-up (retry with a browser-rendered fetch,
or re-check the cert chain for `tnlegalservices.tn.gov.in`).

## Two bugs found and fixed in `stage_b.py` and the validators

The scripts in `catalog/` were written for a different sandbox path
(`/sessions/practical-charming-hypatia/mnt/Plan/catalog`) and hadn't been run
in this environment before. Fixed to resolve paths relative to the script file
in `stage_b.py`, `validate_base.py`, `validate_catalog.py`,
`validate_cross_catalog.py`.

More substantively, `cmd_apply`'s safety guard and version-bump logic were
wrong for the catalog's *current* state:

1. **Guard compared live `content` against the frozen 1.0.0-alpha baseline**,
   not against the state immediately before this apply. Since the catalog has
   gone through several legitimate content-changing phases since Stage A froze
   (crossrefs, i18n, phase-4 resolution — all documented in
   `PRODUCTION_PROGRESS.md`), that comparison flagged 209/217 records as
   "mutated" on a run that hadn't touched `content` at all. Fixed to snapshot
   `content` immediately before the run and diff against that.
2. **Version/manifest bump assumed `manifest.json` was scheme-only** (`files[0]`
   = the scheme file, hardcoded version string `"1.0.1-passl"`). `manifest.json`
   is actually a whole-release manifest across all 11 catalog files;
   `scheme_catalog.json` is `files[3]`. The original code would have silently
   overwritten `common_catalog.json`'s checksum/size in the manifest and
   clobbered the release version `1.33.0-alpha` down to `1.0.1-passl` — losing
   the version lineage for every other catalog. Fixed to look up the file
   entry by name and derive the new version as a suffix on the current one
   (`1.33.0-alpha+stageb.pass1.batch1`), touching only the scheme file's entry.

I caught this by re-running validators and diffing metadata before committing
to the result — the first `apply 1` run was reverted from a backup before the
fix, so nothing bad landed in the live catalog.

## Existing documentation used (not duplicated)

| Requested phase | Already covered by |
|---|---|
| Phase 1 — inventory | `MSS_JSON_Catalog_Report.md` (12 files, 969 entities, per-file record counts) |
| Phase 2 — architecture | `MSS_Base_Entity_Model_v1.0.md`, `MSS_Offline_Catalog_Architecture_Specification_v1.0.md` |
| Phase 3 — baseline / gaps | `PRODUCTION_PROGRESS.md` (3,841 `missingFields` entries across 217 records, per-field coverage tables) |
| Source hierarchy / tiers / domain allowlist | `MSS_Data_Completion_Policy_v1.0.md` — more detailed than the ad-hoc tier list in the task brief; used as-is |

## What's left for the scheme catalog (not done in this pilot)

- Batches 2–9 (`SCH000026`–`SCH000217`) — same Pass 1 process, ~250 more refs.
- Pass 2 (enrichment: filling `null` fields such as `contacts`, `applicationProcess.mode`,
  `applicationTimeline`) — policy requires this run as a separate, explicitly-scoped
  pass from Pass 1; not attempted here.
- Domain allowlist amendment for the 3 skipped `indianspices.com` URLs and the
  28 non-approved hosts noted in `PRODUCTION_PROGRESS.md` — requires a deliberate
  policy amendment (§4.3.1), not something to do inline.

Say the word if you want batch 2 run next, or Pass 2 (fill-only enrichment)
started on batch 1's already-verified records.
