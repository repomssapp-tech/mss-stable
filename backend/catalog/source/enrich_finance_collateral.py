#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Finance collateral structuring — Phase 1 search-gap fix, issue 1.

Adds content.collateral to every finance_catalog.json record. Additive only:
no existing field is removed, renamed, or overwritten.

Source tier: 2 (previous verified extraction) for every populated value --
every fact used here is ALREADY PRESENT, verbatim, in the record's own
`content.description` / `content.eligibilityNotes` / `content.conditions`,
or (cross-checked) the linked scheme's `content.benefits.guarantee`. This is
structuring of existing text into a queryable field, not new research, so no
tier-5 web fetch was required or performed.

Hard rule enforced by this script, per explicit instruction: a record's
guarantee association (isGuarantee / benefits.guarantee.applicable) is NEVER
enough on its own to set collateral.status = "not_required". A guarantee
scheme and a collateral-free loan are different concepts:

    collateral requirement   -- does the LENDER require security from
                                 the borrower for THIS credit facility?
    credit guarantee coverage -- does a THIRD PARTY (e.g. CGTMSE/NCGTC)
                                 guarantee the lender against default,
                                 which is what typically ENABLES a lender
                                 to lend without collateral, but is not
                                 itself a statement about this facility?

Only an explicit textual statement ("collateral is not required",
"collateral-free credit") sets status = "not_required". Guarantee-scheme
records without such a statement get status = "guarantee_covered" --
correctly distinct, never conflated.
"""
import json, os, hashlib
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
AT = "2026-08-14T00:00:00Z"


def load(f): return json.load(open(os.path.join(CAT, f), encoding="utf-8"))
def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


# ---- explicit, hand-verified determinations -------------------------------
# Every entry here was read directly from the record's own existing text
# (see PHASE1_CATALOG_RELATIONSHIP_AUDIT-style spot check in
# SEARCH_ENGINE_VALIDATION_REPORT.md). No inference from guarantee
# association alone; the note explains what was actually read.
DETERMINATIONS = {
    "FIN000075": {  # SCH000124, PM Vishwakarma
        "status": "not_required",
        "guaranteeSupported": None,
        "guaranteeSchemeText": None,
        "notes": "content.description states verbatim: \"concessional collateral-free "
                 "enterprise-development credit\" -- explicit statement, not inferred.",
    },
    "FIN000077": {  # SCH000128, PMMY / Mudra
        "status": "not_required",
        "guaranteeSupported": None,
        "guaranteeSchemeText": None,
        "notes": "content.description states verbatim: \"Collateral is not required.\" "
                 "-- explicit statement, not inferred.",
    },
    "FIN000026": {  # SCH000038, CGTMSE
        "status": "guarantee_covered",
        "guaranteeSupported": True,
        "guaranteeSchemeText": "CGTMSE (Credit Guarantee Fund Trust for Micro and Small Enterprises)",
        "notes": "This IS the guarantee scheme (content.isGuarantee=true, scheme "
                 "benefits.guarantee.applicable=true). Deliberately NOT marked "
                 "collateral_required=not_required: the record's own text describes "
                 "guarantee-coverage mechanics only, never states a collateral "
                 "requirement outcome for the underlying credit facility. Publicly, "
                 "CGTMSE is widely understood to enable collateral-free lending, but "
                 "that inference is explicitly disallowed by this script's rule -- "
                 "status reflects only what the record itself states.",
    },
    "FIN000027": {  # SCH000039, CGSS
        "status": "guarantee_covered",
        "guaranteeSupported": True,
        "guaranteeSchemeText": "CGSS (Credit Guarantee Scheme for Startups, NCGTC)",
        "notes": "Same reasoning as FIN000026 -- this is the guarantee scheme itself; "
                 "guarantee-coverage mechanics only, no explicit collateral statement.",
    },
    "FIN000043": {  # SCH000064, "Guarantee Schemes for MSEs" -- references CGTMSE products
        "status": "not_specified",
        "guaranteeSupported": None,
        "guaranteeSchemeText": "References CGTMSE-linked products",
        "notes": "Scheme's own benefits.guarantee.applicable is null (not true) unlike "
                 "FIN000026/27 -- less certain than the two records above, correctly "
                 "left not_specified rather than guessed.",
    },
    "FIN000085": {  # SCH000140, NSIC Raw Material Assistance against bank guarantee
        "status": "required",
        "guaranteeSupported": False,
        "guaranteeSchemeText": None,
        "notes": "content.description states verbatim: \"Assistance against bank "
                 "guarantee is provided under NSIC terms.\" This is the OPPOSITE "
                 "direction from a credit-guarantee-covered loan: here the BORROWER "
                 "provides a bank guarantee AS security to NSIC, i.e. security is "
                 "required, not waived. Not a credit guarantee scheme benefiting the "
                 "borrower.",
    },
}


def build_collateral_block(fin_id):
    d = DETERMINATIONS.get(fin_id)
    if d:
        return OrderedDict([
            ("status", d["status"]),
            ("guaranteeSupported", d["guaranteeSupported"]),
            ("guaranteeSchemeText", d["guaranteeSchemeText"]),
            ("notes", d["notes"]),
        ])
    return OrderedDict([
        ("status", "not_specified"),
        ("guaranteeSupported", None),
        ("guaranteeSchemeText", None),
        ("notes", "No explicit collateral or guarantee statement found in "
                  "content.description / eligibilityNotes / conditions. Left "
                  "not_specified per MSS_Data_Completion_Policy_v1.0.md §5 -- "
                  "never guessed."),
    ])


def main():
    cat = load("finance_catalog.json")
    pre_content = {r["identity"]["id"]: json.dumps(r["content"], sort_keys=True)
                    for r in cat["data"]}

    touched, determined = 0, 0
    for r in cat["data"]:
        fid = r["identity"]["id"]
        if "collateral" in r["content"]:
            continue  # guard: never overwrite an already-populated field
        r["content"]["collateral"] = build_collateral_block(fid)
        touched += 1
        if fid in DETERMINATIONS:
            determined += 1
            r["provenance"].setdefault("fieldSources", [])
            r["provenance"]["fieldSources"].append({
                "field": "content.collateral", "sourceTier": 2,
                "sourceType": "previous_verified_extraction",
                "organization": None, "url": None, "retrievedAt": AT,
                "isBackfill": True, "supersededValue": None,
                "note": DETERMINATIONS[fid]["notes"],
            })
            r["provenance"]["transformationNotes"].append(
                f"content.collateral added: status={DETERMINATIONS[fid]['status']!r}, "
                "structured from existing record text, no new source consulted "
                "(enrich_finance_collateral.py)")
        else:
            r["verification"].setdefault("missingFields", [])
            r["verification"]["missingFields"].append({
                "field": "content.collateral.status",
                "reason": "No explicit collateral/guarantee statement in existing "
                          "record text; not resolved from external source this pass",
            })

    # ---- guard: nothing except content.collateral (+ the two provenance/verification
    # additions above) changed. Diff content with collateral stripped back out.
    bad = []
    for r in cat["data"]:
        fid = r["identity"]["id"]
        c2 = json.loads(json.dumps(r["content"]))
        c2.pop("collateral", None)
        if json.dumps(c2, sort_keys=True) != pre_content[fid]:
            bad.append(fid)
    if bad:
        print(f"ABORT -- fields outside content.collateral changed on {len(bad)} record(s): {bad[:5]}")
        raise SystemExit(1)

    prev_version = cat["metadata"]["catalogVersion"]
    new_version = prev_version + "+collateral-enrichment"
    ck = "sha256:" + hashlib.sha256(canon(cat["data"]).encode()).hexdigest()
    cat["metadata"]["checksum"] = ck
    cat["metadata"]["catalogVersion"] = new_version
    json.dump(cat, open(os.path.join(CAT, "finance_catalog.json"), "w", encoding="utf-8"),
               ensure_ascii=False, indent=2)

    print(f"finance_catalog.json: {touched} records got content.collateral "
          f"({determined} with an explicit source-backed determination, "
          f"{touched - determined} not_specified)")
    print(f"release {new_version}  checksum={ck[:26]}...  content guard passed (0 unrelated mutations)")


if __name__ == "__main__":
    main()
