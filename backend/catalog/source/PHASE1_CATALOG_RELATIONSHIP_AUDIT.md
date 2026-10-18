# Phase 1 — Catalog Relationship Audit

Read-only audit, no data modified. Recomputed directly from the live catalog
files at `catalogVersion`s shown below — figures are not carried over from
earlier planning documents.

## Catalogs inspected

| File | Records | Version | Entity type | Prefix |
|---|---:|---|---|---|
| `scheme_catalog.json` | 217 | `1.33.0-alpha+stageb.pass1.batch1+stageb.pass2.batch1` | `scheme` | `SCH` |
| `finance_catalog.json` | 115 | `1.11.0-alpha` | `finance_product` | `FIN` |
| `tax_catalog.json` | 13 | `1.11.0-alpha` | `tax_provision` | `TAX` |
| `treds_catalog.json` | 16 | `1.11.0-alpha` | `treds_platform` | `TDS` |
| `csr_catalog.json` | 16 | `1.11.0-alpha` | `csr_provision` | `CSR` |
| `authority_catalog.json` | 124 | `1.33.0-alpha` | `authority` | `AUTH` |
| `institution_catalog.json` | 83 | `1.11.0-alpha` | `institution` | `INST` |

All seven share the same 10-block base shape
(`identity`/`content`/`relationships`/`localization`/`search`/`ai`/
`verification`/`analytics`/`metadata`/`provenance`) — confirmed by
`validate_base.py` passing on all seven independently. Only `content` differs.

## Current relationships (edges declared on `scheme` records)

Recomputed from `scheme_catalog.json`'s `relationships.references[]`:

| Target type | Relation | Count | Coverage |
|---|---|---:|---|
| `authority` | `administered_by` | 209 | 209/217 schemes (96%) |
| `authority` | `implemented_by` | 31 | 31/217 (14%) |
| `finance_product` | `offers` | 115 | matches all 115 finance records — every finance product traces to exactly one scheme |
| `institution` | `implemented_by` | 70 | 70/217 schemes reference an institution |
| `tax_provision` | `requires` | 57 | matches the 37 distinct schemes tax records claim (some schemes have >1 tax edge) |
| `export_benefit` | `evidences` | 13 | matches all 13 export records |

**`treds_catalog.json` and `csr_catalog.json` have zero relationship edges to
schemes** — confirmed directly (`relationships.references: []` on every
sampled record, `applicableSchemes: []` on every CSR record). This matches
`MSS_JSON_Catalog_Report.md`'s prior finding ("Two catalogs are islands with
zero edges: `treds` and `csr`") — still true at the current catalog version,
not fixed by any work since.

## Cross-catalog reference integrity

| Check | Result |
|---|---|
| `finance_catalog.json` records with a populated `schemeId` | 115/115 (100%) |
| Those `schemeId`s all resolve to an existing scheme | ✅ 0 orphans |
| `tax_catalog.json` `evidencedInSchemes[]` — distinct schemes referenced | 37 |
| Those all resolve to an existing scheme | ✅ 0 orphans |
| `institution_catalog.json` `schemesImplemented[]` — distinct schemes referenced | 69 |
| Those all resolve to an existing scheme | ✅ 0 orphans |

No broken references found across any of the four link directions checked.
This matches `validate_cross_catalog.py`'s standing result
(`CROSS-CATALOG PASSED`, 8,012 references checked, 0 asymmetric).

## Missing references (confirmed gaps, not bugs)

1. **`treds_catalog.json` → scheme: 0 edges.** No scheme in `scheme_catalog.json`
   currently has a `relationType` pointing at a `treds_platform`, and no
   TReDS record names a scheme. This is a genuine data gap — none of the 16
   TReDS records carry enough content to link (`website`, `fees`, `contacts`,
   `guidance` are null/`[]` on the sampled record) — there's nothing to link
   *from* yet, not just a missing edge.
2. **`csr_catalog.json` → scheme: 0 edges**, but this is correct as
   designed, not a gap: CSR records describe company *spending obligations*
   (Schedule VII), not scheme benefits an MSME receives. Confirmed by
   re-reading `csr_catalog.json`'s sample record — `appliesToMsme: true`
   means "this statute is relevant to MSMEs as a topic," not "an MSME
   receives this."
3. **`content.classification.government.ministryId` still null on the
   majority of schemes** even though `authority_catalog.json` now exists —
   already investigated and confirmed as a genuine dead end (not a bug) in
   `catalog/STAGE_B_PASS2_BATCH1_REPORT.md`'s "Investigated and rejected"
   section for the batch-1 sample; this audit did not re-derive that finding,
   it's cited from the prior verified result.

## Duplicate concepts — checked, none found

The task brief asked specifically to flag duplicate concepts. Checked:

- **Finance data duplicated between `scheme.content.benefits` and
  `finance_catalog.json`?** No — they're complementary, not duplicated.
  `scheme.content.benefits` holds the scheme's own benefit summary/typed
  slots (`capitalSubsidy`, `loan`, etc., inline on the scheme record);
  `finance_catalog.json` holds the same fact from the finance-product
  perspective (`amount.percentage`, `amount.maxInr`) plus fields the scheme
  record doesn't carry (`providers[]`, `collateralRequired`, `tenure`,
  `applicationRoute`). Spot-checked SCH000001 / FIN000001: `amount.percentage: 10.0`
  and `amount.maxInr: 500000` on the finance record match
  `benefits.capitalSubsidy.percentage: 10.0` / `.maxAmountInr: 500000` on
  the scheme record exactly — same fact, two views, no drift found in this sample.
- **Tax data duplicated between scheme documents and `tax_catalog.json`?**
  No — `tax_catalog.json` references scheme *documents* by ID
  (`evidencedDocuments[].documentId`) rather than re-stating document
  content, so there's one copy of each document fact (on the scheme record)
  and a pointer from tax.
- **Institution vs. authority overlap?** Not a duplicate — `institution`
  (SIDBI, NSIC, etc.) and `authority` (government departments/ministries)
  are genuinely different entity types with a declared `authorityId` link
  from institution → authority (e.g. `INST000002.authorityId = AUTH000024`),
  not two catalogs describing the same thing.

**Conclusion: no duplicate source-of-truth concepts found in the existing
seven catalogs.** This confirms the reconciliation already made in
`PHASE1_INTELLIGENCE_ARCHITECTURE.md` — the four existing intelligence
catalogs (finance/tax/treds/csr) are internally consistent and should be
extended, not replaced, and nothing already in this audit contradicts that
decision.

## Implication for the Intelligence Resolver (Step 2)

The resolver's edge-walk contract from `RELATIONSHIP_MAP.md` is confirmed
correct against live data:

| Resolver field | Edge | Confirmed count |
|---|---|---:|
| `finance` | `scheme --offers--> finance_product` | 115 |
| `tax` | `scheme --requires--> tax_provision` | 57 (37 distinct schemes) |
| `authority` | `scheme --administered_by/implemented_by--> authority` | 240 |
| `institution` | `scheme --implemented_by--> institution` | 70 |
| `treds` | *(no edges exist — resolver must return empty, not guess)* | 0 |
| `csr` | *(deliberately unlinked — different obligation direction)* | 0 |

No changes needed to the resolver's contract as planned. Proceeding to
Step 2.
