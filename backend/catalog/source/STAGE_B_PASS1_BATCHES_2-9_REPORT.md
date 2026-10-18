# Stage B — Pass 1 (Verification), Batches 2–9 — Report

Continuation of `STAGE_B_PASS1_BATCH1_REPORT.md`. Completes Pass 1
verification across the entire 217-scheme catalog (batches 1–9,
`SCH000001`–`SCH000217`). Same process each batch: `stage_b.py queue N` →
WebFetch every queued URL (approved-domain allowlist only,
`MSS_Data_Completion_Policy_v1.0.md` §4.3) → record outcomes in
`results_N.json` → verify queue/results URL sets match exactly → back up →
`stage_b.py apply N` → re-run `validate_base.py`, `validate_catalog.py`,
`validate_cross_catalog.py` → confirm `identity.id` list unchanged (217,
same order) → delete backup.

## Batch summary

| Batch | Schemes | Distinct URLs | Reachable | Unreachable | `apply` guard |
|---|---|---:|---:|---:|---|
| 2 | SCH000026–SCH000050 | 23 | 11 | 12 | 0 mutations |
| 3 | SCH000051–SCH000075 | 12 | 6 | 6 | 0 mutations |
| 4 | SCH000076–SCH000100 | 25 | 14 | 11 | 0 mutations |
| 5 | SCH000101–SCH000125 | 32 | 15 | 17 | 0 mutations |
| 6 | SCH000126–SCH000150 | 23 | 14 | 9 | 0 mutations |
| 7 | SCH000151–SCH000175 | 19 | 10 | 9 | 0 mutations |
| 8 | SCH000176–SCH000200 | 22 | 16 | 6 | 0 mutations |
| 9 | SCH000201–SCH000217 (17 schemes, partial batch) | 9 | 5 | 4 | 0 mutations |
| **Total, batches 2–9** | **192 schemes** | **165** | **91** | **74** | **all clean** |
| Batch 1 (prior round) | 25 schemes | 31 | 22 | 9 | 0 mutations |
| **Grand total, all 9 batches** | **217 schemes** | **196** | **113** | **83** | **all clean** |

After batch 9: **170 of 217 schemes** (78%) carry at least one
`verification.verifiedFields[]` entry; 339 total verified-field entries,
142 disputed/unreachable-field entries recorded (never silently dropped —
each unreachable URL's baseline value is retained and the disagreement is
logged, per policy §3.1 rule 4).

## Recurring failure patterns (aggregated across all 9 batches)

| Cause | Approx. occurrences | Note |
|---|---:|---|
| TLS certificate validation failure | ~25 | Several `.gov.in` subdomains present certs that don't validate cleanly (self-signed / mismatched chain) — a real infrastructure issue on the government side, not a policy problem |
| HTTP 403 Forbidden | ~20 | `www.msme.gov.in` in particular returned 403 on **every single path** fetched across all 9 batches — the ministry's main portal appears to actively block this fetch tool's user agent |
| Connection refused (ECONNREFUSED) | ~15 | Often transient — several hosts (`nsic.co.in`, `innovative.msme.gov.in`, `sfurti.msme.gov.in`) alternated between reachable and refused across different batches on the same day |
| DNS timeout | `kviconline.gov.in` failed on **every attempt across all 9 batches** | Persistent, not transient — worth flagging to whoever maintains that scheme's application URL |
| "Page Moved" / empty body | ~8 | `www.dgft.gov.in` and `www.msmeonline.tn.gov.in` (root) repeatedly returned this; client-rendered pages the fetch tool can't execute JS for |
| Two redirect cases, handled correctly | 3 | `naanmudhalvan.tn.gov.in`→`skilldevelopment.tn.gov.in` and `sipcot.tn.gov.in`→`sipcotweb.tn.gov.in` (both still `.tn.gov.in`, approved — followed); `mha.gov.in`→ a Devanagari IDN outside `.gov.in`/`.nic.in` — **not followed**, logged as unreachable rather than silently trusted |

## Non-approved hosts encountered (never fetched — logged for a future, deliberate domain-allowlist decision, per policy §4.3.1)

Aggregated across all 8 queue reports (batches 2–9): `cgtmse.in`,
`ncgtc.in`, `sidbivcf.in`, `startuptn.in`, `indianspices.com`,
`www.mudra.org.in`, `www.fametn.com`, `udyam-sakhi.com`, `www.tncdw.org`,
`www.vkp-tnrtp.org`, `www.state.gov`, `sbi.co.in`,
`investingintamilnadu.com`, `www.centralbankofindia.co.in`,
`www.bankofbaroda.in`, `spicesboard.in:8004`, `scsthub.in`,
`www.msmemart.com`, `www.cgtmse.in`.

Two of these are worth flagging specifically: **`cgtmse.in`** and
**`ncgtc.in`** — the actual CGTMSE/NCGTC guarantee-scheme domains — appeared
repeatedly as skipped references from schemes discussing credit guarantees
(the same collateral/guarantee distinction from
`SEARCH_ENGINE_VALIDATION_REPORT.md` Issue 1). Amending the allowlist to
include them (a deliberate, separate decision per §4.3.1, not made here)
would let a future Stage B pass verify collateral/guarantee facts
first-hand rather than relying only on `scheme_catalog.json`'s and
`finance_catalog.json`'s already-extracted text.

## Validation — every batch, confirmed clean

All 9 `apply` runs reported `content mutations=0 (guard passed)`. Final
full regression after batch 9:

```
validate_base.py scheme_catalog.json   -> BASE VALIDATION PASSED — rules 1-30
validate_catalog.py                    -> VALIDATION PASSED — base 1-30, scheme 31-45, policy, batch gates
validate_cross_catalog.py              -> CROSS-CATALOG PASSED — 8880 references checked, 0 asymmetric
validate_i18n.py                       -> I18N INVARIANTS PASSED — English byte-identical, Tamil unchanged
intelligence_resolver.py (self-check)  -> RESOLVER VALIDATION PASSED — 217/217 schemes, 0 mismatches
```

217 `identity.id`s confirmed unchanged, same order, after every one of the
9 batches. `finance_catalog.json`, `tax_catalog.json`, `treds_catalog.json`,
`csr_catalog.json` untouched by this work (Pass 1 only ever writes to
`scheme_catalog.json`'s `verification` block and `manifest.json`'s
scheme-file entry).

`scheme_catalog.json`'s `catalogVersion` now reads:
```
1.33.0-alpha+stageb.pass1.batch1+stageb.pass2.batch1+stageb.pass1.batch2+
stageb.pass1.batch3+stageb.pass1.batch4+stageb.pass1.batch5+stageb.pass1.batch6+
stageb.pass1.batch7+stageb.pass1.batch8+stageb.pass1.batch9
```
— the full, auditable chain of every pass applied, release-level
`manifest.json` fields untouched throughout.

## What's next

**Pass 1 (verification) is now complete for all 217 schemes.** Not done,
and out of scope for this round:

- **Pass 2 (fill-only enrichment) for batches 2–9** — only batch 1 has had
  Pass 2 run (per the user's own earlier explicit scoping: "Only after
  batch 1 Pass 2 is approved continue batches 2-9," which was about Pass 1
  continuation, not an automatic Pass-2 extension). Batches 2–9's 91
  reachable URLs are a ready-made input for a future Pass 2 pass following
  the same pattern as `stage_b_pass2.py`.
- **The 83 unreachable URLs** are logged with specific failure reasons in
  each `results_N.json`, not silently dropped — a human retry (different
  fetch method for client-rendered pages, cert-chain investigation for the
  TLS failures) could recover a meaningful fraction of them, especially the
  ~20 `www.msme.gov.in` 403s, which look like tool-specific blocking rather
  than genuine unavailability.
- **Domain allowlist review** for `cgtmse.in`/`ncgtc.in` in particular, per
  above.
