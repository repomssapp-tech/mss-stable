#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase G release-candidate audit. READ-ONLY -- writes nothing to any
catalog file. Produces a JSON dump of findings for the human-authored
MSS_RELEASE_CANDIDATE_AUDIT.md to draw on.
"""
import json, os
from collections import Counter, defaultdict

CAT = os.path.dirname(os.path.abspath(__file__))

def load(f):
    return json.load(open(os.path.join(CAT, f), encoding="utf-8"))

sch = load("scheme_catalog.json")["data"]
fin = load("finance_catalog.json")["data"]

def empty(v):
    if v is None:
        return True
    if isinstance(v, str):
        s = v.strip().lower()
        return s == "" or s in ("not entered", "not asserted", "n/a", "none")
    if isinstance(v, (list, dict)):
        return len(v) == 0
    return False

FIELD_PATHS = {
    "schemeName": lambda r: r["identity"]["name"],
    "shortDescription": lambda r: r["localization"]["en"].get("summary"),
    "description": lambda r: r["localization"]["en"].get("description"),
    "overview": lambda r: r["content"]["overview"].get("summary") if "overview" in r["content"] else None,
    "keywords": lambda r: r["search"]["keywords"]["en"] if r.get("search") else None,
    "eligibility": lambda r: r["content"]["eligibility"]["narrative"].get("criteria"),
    "benefits": lambda r: r["content"]["benefits"].get("summary"),
    "requiredServices": lambda r: r["content"]["applicationProcess"].get("services"),
    "requiredDocuments": lambda r: r["content"].get("requiredDocuments"),
    "applicationProcess": lambda r: r["content"]["applicationProcess"].get("mode"),
}

def field_sourced(rec, field_key_guess):
    if field_key_guess == "requiredDocuments":
        # documents carry their own per-item sourceUrl rather than an
        # aggregate fieldSources[] entry -- check that directly instead of
        # the fieldSources path substring match used for other fields.
        docs = rec["content"].get("requiredDocuments") or []
        return bool(docs) and any(d.get("sourceUrl") for d in docs)
    prov = rec.get("provenance") or {}
    for fs in prov.get("fieldSources") or []:
        if field_key_guess in (fs.get("field") or ""):
            return True
    return False

FIELD_SOURCE_HINTS = {
    "eligibility": "eligibility",
    "benefits": "benefits",
    "applicationProcess": "applicationProcess",
    "requiredDocuments": "requiredDocuments",
    "overview": "overview",
    "description": "description",
    "shortDescription": "summary",
}

classification = defaultdict(Counter)
per_field_examples = defaultdict(lambda: defaultdict(list))

for r in sch:
    rid = r["identity"]["id"]
    status = r["verification"]["status"]
    for fname, getter in FIELD_PATHS.items():
        try:
            val = getter(r)
        except (KeyError, TypeError):
            val = None
        is_empty = empty(val)
        hint = FIELD_SOURCE_HINTS.get(fname)
        sourced = field_sourced(r, hint) if hint else None

        # Only eligibility / benefits / applicationProcess / requiredDocuments carry
        # discrete per-field provenance (fieldSources[] entries citing that exact
        # path). name / shortDescription / description / overview / keywords are
        # descriptive/derived fields with no separate field-level source trail in
        # this catalog -- for those, the record's overall verification.status is
        # the only honest signal available, so we use it directly rather than
        # inventing a field-level distinction the data doesn't support.
        HAS_FIELD_PROVENANCE = {"eligibility", "benefits", "applicationProcess", "requiredDocuments"}

        if fname == "requiredServices" and is_empty:
            cls = "NOT_APPLICABLE"   # most schemes route through documents, not a discrete "service"
        elif is_empty:
            cls = "NOT_VERIFIED" if fname != "requiredServices" else "NOT_APPLICABLE"
        elif fname not in HAS_FIELD_PROVENANCE:
            cls = "VERIFIED" if status == "verified" else ("PARTIALLY_VERIFIED" if status == "partially_verified" else "NOT_VERIFIED")
        else:
            if sourced and status == "verified":
                cls = "VERIFIED"
            elif sourced or status == "partially_verified":
                cls = "PARTIALLY_VERIFIED"
            else:
                cls = "NOT_VERIFIED"
        classification[fname][cls] += 1
        if cls == "NOT_VERIFIED" and len(per_field_examples[fname]["NOT_VERIFIED"]) < 5:
            per_field_examples[fname]["NOT_VERIFIED"].append(rid)

print("=== CRITICAL FIELD CLASSIFICATION (n=219 schemes) ===")
for fname in FIELD_PATHS:
    print(f"\n{fname}:")
    for cls, n in classification[fname].most_common():
        print(f"   {cls:20s} {n:4d}  ({n/219:.1%})")

# ---- financial intelligence audit (finance_catalog.json, 115 records) ----
print("\n\n=== FINANCIAL INTELLIGENCE (n=%d finance products) ===" % len(fin))
fin_fields = {
    "assistanceType (productType)": lambda r: r["content"].get("productType"),
    "minAmountInr": lambda r: r["content"]["amount"].get("minInr"),
    "maxAmountInr": lambda r: r["content"]["amount"].get("maxInr"),
    "subsidyPercentage": lambda r: r["content"]["amount"].get("percentage"),
    "interestRatePercent": lambda r: r["content"]["interestRate"].get("percent"),
    "repaymentTenureMonths": lambda r: r["content"]["tenure"].get("tenureMonths") or r["content"]["tenure"].get("durationMonths"),
    "collateralRequired": lambda r: r["content"].get("collateralRequired"),
    "collateralStatus (structured)": lambda r: (r["content"].get("collateral") or {}).get("status"),
    "guaranteeCoveragePercent": lambda r: r["content"].get("coveragePercent"),
    "maxCoverInr (guarantee cap)": lambda r: r["content"].get("maxCoverInr"),
    "conditions": lambda r: r["content"].get("conditions"),
}
# not_applicable-aware: isGuarantee=False records legitimately have no
# coveragePercent/maxCoverInr; isRepayable=False records legitimately have
# no interestRate/tenure. A bare null count would misreport these as gaps.
fin_missing = Counter()
fin_not_applicable = Counter()
for r in fin:
    is_guarantee = r["content"].get("isGuarantee")
    is_repayable = r["content"].get("isRepayable")
    for fname, getter in fin_fields.items():
        try:
            v = getter(r)
        except (KeyError, TypeError):
            v = None
        is_null = v is None or v == [] or v == "not_specified"
        if not is_null:
            continue
        if fname in ("guaranteeCoveragePercent", "maxCoverInr (guarantee cap)") and is_guarantee is False:
            fin_not_applicable[fname] += 1
        elif fname in ("interestRatePercent", "repaymentTenureMonths") and is_repayable is False:
            fin_not_applicable[fname] += 1
        else:
            fin_missing[fname] += 1
print("MISSING (null, no NOT_APPLICABLE exemption) -- out of %d finance products:" % len(fin))
for fname, n in fin_missing.most_common():
    print(f"   {fname:32s} {n:4d}  ({n/len(fin):.1%})")
print("\nNOT_APPLICABLE (null, but structurally correct -- e.g. non-guarantee product has no coveragePercent):")
for fname, n in fin_not_applicable.most_common():
    print(f"   {fname:32s} {n:4d}  ({n/len(fin):.1%})")

json.dump({
    "schemeFieldClassification": {k: dict(v) for k, v in classification.items()},
    "notVerifiedExamples": {k: dict(v) for k, v in per_field_examples.items()},
    "financeMissingCounts": dict(fin_missing),
    "financeNotApplicableCounts": dict(fin_not_applicable),
}, open(os.path.join(CAT, "audit_release_candidate_g.json"), "w"), indent=2)
print("\nwritten: audit_release_candidate_g.json")
