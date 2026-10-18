#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.2 Step 3 -- applicability-aware completeness (READ ONLY).
Replaces raw field-presence counting with per-record-type "is this field
even relevant" gating, per the brief's own training-scheme vs loan-scheme
example. Writes audit_quality_e2.json only."""
import json, os
from collections import Counter, OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))


def load(f):
    with open(os.path.join(CAT, f), encoding="utf-8") as fh:
        return json.load(fh)


def filled(v):
    if v is None:
        return False
    if isinstance(v, str):
        return v.strip() != ""
    if isinstance(v, (list, dict)):
        return len(v) > 0
    return True


def pct(n, d):
    return round(100 * n / d, 1) if d else 0.0


out = OrderedDict()
sch = load("scheme_catalog.json")["data"]
N = len(sch)

# ---------------------------------------------------------------------
# 1. SCHEME QUALITY -- fields every scheme needs regardless of type
# ---------------------------------------------------------------------
SCHEME_UNIVERSAL = [
    ("identity.name", lambda r: r["identity"]["name"]),
    ("content.overview.summary", lambda r: r["content"]["overview"]["summary"]),
    ("content.overview.description", lambda r: r["content"]["overview"]["description"]),
    ("content.classification.schemeType", lambda r: r["content"]["classification"]["schemeType"]),
    ("content.classification.government.departmentText", lambda r: r["content"]["classification"]["government"]["departmentText"]),
    ("content.targetBeneficiaries.description", lambda r: r["content"]["targetBeneficiaries"]["description"]),
    ("content.requiredDocuments", lambda r: r["content"]["requiredDocuments"]),
    ("content.applicationProcess.mode", lambda r: r["content"]["applicationProcess"]["mode"]),
]
scheme_quality_rows = []
for field, getter in SCHEME_UNIVERSAL:
    f = sum(1 for r in sch if filled(getter(r)))
    scheme_quality_rows.append({"field": field, "total": N, "filled": f, "coveragePct": pct(f, N)})
scheme_quality_avg = sum(r["coveragePct"] for r in scheme_quality_rows) / len(scheme_quality_rows)
out["scheme_quality"] = {"avgPct": round(scheme_quality_avg, 1), "rows": scheme_quality_rows}

# ---------------------------------------------------------------------
# 2. FINANCIAL QUALITY -- applicability-aware (per Phase E.1 sec 5 method,
#    re-verified after Phase E.1's batch-1 enrichment)
# ---------------------------------------------------------------------
fin = load("finance_catalog.json")["data"]
FN = len(fin)
fin_applic = 0
fin_filled = 0
per_field = Counter()
per_field_total = Counter()
for r in fin:
    c = r["content"]
    is_repay = c.get("isRepayable") is True
    is_guar = c.get("isGuarantee") is True
    checks = [
        ("assistanceType", True, filled(c["productType"])),
        ("minimumAmount", True, filled(c["amount"]["minInr"])),
        ("maximumAmount", True, filled(c["amount"]["maxInr"])),
        ("subsidyPercentage", True, filled(c["amount"]["percentage"])),
        ("interestRate", is_repay, filled(c["interestRate"]["percent"])),
        ("tenure", is_repay, filled(c["tenure"]["tenureMonths"])),
        ("collateralRequirement", is_repay or is_guar, filled(c["collateral"]["status"]) and c["collateral"]["status"] != "not_specified"),
        ("guaranteeInformation", is_repay or is_guar, filled(c["collateral"].get("guaranteeSupported"))),
        ("source", True, filled(r["provenance"].get("primarySourceId"))),
        ("verificationStatus", True, filled(r["verification"]["status"])),
    ]
    for key, applic, fil in checks:
        if applic:
            fin_applic += 1
            per_field_total[key] += 1
            if fil:
                fin_filled += 1
                per_field[key] += 1
out["financial_quality"] = {
    "applicabilityAwarePct": round(100 * fin_filled / fin_applic, 1),
    "rawPctAllFieldsAllRecords": None,  # computed below for comparison
    "byField": {k: {"filled": per_field[k], "applicable": per_field_total[k],
                     "pct": pct(per_field[k], per_field_total[k])} for k in per_field_total},
}
raw_total = 0
raw_filled = 0
for r in fin:
    c = r["content"]
    for path in (c["productType"], c["amount"]["minInr"], c["amount"]["maxInr"], c["amount"]["percentage"],
                 c["interestRate"]["percent"], c["tenure"]["tenureMonths"],
                 c["collateral"]["status"] if c["collateral"]["status"] != "not_specified" else None,
                 c["collateral"].get("guaranteeSupported"), r["provenance"].get("primarySourceId"),
                 r["verification"]["status"]):
        raw_total += 1
        if filled(path):
            raw_filled += 1
out["financial_quality"]["rawPctAllFieldsAllRecords"] = pct(raw_filled, raw_total)

# ---------------------------------------------------------------------
# 3. ELIGIBILITY QUALITY -- structured facets + applicability_matrix
# ---------------------------------------------------------------------
am = {r["content"]["schemeId"]: r["content"] for r in load("applicability_matrix_catalog.json")["data"]}
elig_fields = ["gender", "enterpriseType", "businessStage", "specialCategory", "sector"]
elig_rows = []
for f in elig_fields:
    n_am = sum(1 for v in am.values() if v.get(f))
    elig_rows.append({"field": f, "applicabilityMatrixCoveragePct": pct(n_am, len(am))})
# structured raw (post-reconciliation)
struct_rows = []
for group, key in (("gender", "values"), ("enterprise", "types"), ("businessStage", "values"),
                    ("specialCategory", "values"), ("sector", "included")):
    n = sum(1 for r in sch if filled(r["content"]["eligibility"]["structured"][group][key]))
    struct_rows.append({"field": f"eligibility.structured.{group}.{key}", "coveragePct": pct(n, N)})
out["eligibility_quality"] = {"applicabilityMatrix": elig_rows, "rawStructuredPostReconciliation": struct_rows}

# ---------------------------------------------------------------------
# 4. APPLICABILITY QUALITY (district/cluster/community -- matrix-level)
# ---------------------------------------------------------------------
appl_rows = []
for f in ("district", "cluster", "community"):
    n = sum(1 for v in am.values() if v.get(f))
    appl_rows.append({"field": f, "coveragePct": pct(n, len(am))})
out["applicability_quality"] = appl_rows

# ---------------------------------------------------------------------
# 5. SEARCH READINESS (unchanged mechanism, re-measured)
# ---------------------------------------------------------------------
idx = [e for e in load("search_index.json")["data"] if e["entityType"] == "scheme"]
IN_ = len(idx)
search_rows = []
for dim, path in (("industryTags", "industryTags"), ("loanType", "loanType"),
                    ("clusters", "clusters"), ("taxBenefits", "taxBenefits")):
    f = sum(1 for e in idx if (e.get("schemeSearchProfile") or {}).get(path))
    search_rows.append({"field": dim, "coveragePct": pct(f, IN_)})
out["search_readiness"] = search_rows

# ---------------------------------------------------------------------
# 6. LOCALIZATION QUALITY
# ---------------------------------------------------------------------
ta_name = sum(1 for r in sch if filled(r["localization"]["ta"].get("name")))
ta_desc = sum(1 for r in sch if filled(r["localization"]["ta"].get("description")))
official = sum(1 for r in sch if r["provenance"].get("translations", {}).get("ta", {}).get("isApproved") is True)
out["localization_quality"] = {
    "taNamePct": pct(ta_name, N), "taDescriptionPct": pct(ta_desc, N),
    "officialPct": pct(official, N),
}

with open(os.path.join(CAT, "audit_quality_e2.json"), "w", encoding="utf-8") as fh:
    json.dump(out, fh, ensure_ascii=False, indent=2)

print(json.dumps({k: (v if not isinstance(v, dict) or len(str(v)) < 200 else "...") for k, v in out.items()}, indent=2, ensure_ascii=False, default=str)[:500])
print("wrote audit_quality_e2.json")
