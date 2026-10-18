#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Part 2A localization audit. READ-ONLY -- writes nothing to any catalog.
Traces the real Tamil data (localization.ta blocks inside each
*_catalog.json record), not the dictionary/override tooling that produced it.
"""
import json, os
from collections import Counter, OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))

def load(f):
    return json.load(open(os.path.join(CAT, f), encoding="utf-8"))

LOCALIZED_CATALOGS = [
    "scheme_catalog.json", "common_catalog.json", "authority_catalog.json",
    "finance_catalog.json", "tax_catalog.json", "cluster_assistance_catalog.json",
    "institution_catalog.json", "csr_catalog.json", "export_catalog.json",
    "knowledge_catalog.json", "treds_catalog.json", "msme_privilege_catalog.json",
    "business_enablement_catalog.json", "enterprise_classification_catalog.json",
]

report = OrderedDict()
totals = {"records": 0, "withAnyTamil": 0}

for fname in LOCALIZED_CATALOGS:
    if not os.path.exists(os.path.join(CAT, fname)):
        report[fname] = "FILE NOT FOUND"
        continue
    cat = load(fname)
    data = cat["data"]
    n = len(data)
    field_present = Counter()
    field_total_nonnull_en = Counter()
    any_ta = 0
    for r in data:
        loc = r.get("localization", {})
        en = loc.get("en", {}) or {}
        ta = loc.get("ta", {}) or {}
        if any(ta.get(k) for k in ta):
            any_ta += 1
        for k, v in en.items():
            if v:  # only count fields that HAVE English content to translate
                field_total_nonnull_en[k] += 1
                if ta.get(k):
                    field_present[k] += 1
    totals["records"] += n
    totals["withAnyTamil"] += any_ta
    report[fname] = {
        "recordCount": n,
        "recordsWithAnyTamil": any_ta,
        "pctWithAnyTamil": round(any_ta / n, 4) if n else None,
        "perFieldCoverage": {
            k: {
                "nonNullEnglish": field_total_nonnull_en[k],
                "hasTamil": field_present.get(k, 0),
                "pct": round(field_present.get(k, 0) / field_total_nonnull_en[k], 4)
                       if field_total_nonnull_en[k] else None,
            }
            for k in field_total_nonnull_en
        },
    }

# ---- scheme_catalog.json critical-field breakdown by name (not just % rollup)
sch = load("scheme_catalog.json")["data"]
missing_by_field = Counter()
missing_examples = {}
for r in sch:
    en = r["localization"]["en"]
    ta = r["localization"]["ta"]
    for k, v in en.items():
        if v and not ta.get(k):
            missing_by_field[k] += 1
            missing_examples.setdefault(k, []).append(r["identity"]["id"])

# ---- common_catalog.json controlled-vocabulary coverage (category/sector/type terminology)
cmn = load("common_catalog.json")["data"]
termtype_cov = Counter()
termtype_total = Counter()
for r in cmn:
    tt = r["content"]["termType"]
    termtype_total[tt] += 1
    if r["localization"].get("ta", {}).get("label"):
        termtype_cov[tt] += 1

# ---- cross-reference resolution check: every id referenced via
# relationships.references must resolve to a real record (Tamil-bearing or not)
all_ids = {}
for fname in LOCALIZED_CATALOGS:
    p = os.path.join(CAT, fname)
    if os.path.exists(p):
        for r in load(fname)["data"]:
            all_ids[r["identity"]["id"]] = fname
bad_refs = []
for fname in LOCALIZED_CATALOGS:
    p = os.path.join(CAT, fname)
    if not os.path.exists(p):
        continue
    for r in load(fname)["data"]:
        for e in r.get("relationships", {}).get("references", []):
            if e["entityId"] not in all_ids:
                bad_refs.append((fname, r["identity"]["id"], e["entityId"]))

out = {
    "perCatalog": report,
    "totals": totals,
    "schemeMissingTamilByField": dict(missing_by_field),
    "schemeMissingTamilExamples": {k: v[:5] for k, v in missing_examples.items()},
    "commonCatalogTermTypeCoverage": {
        tt: {"total": termtype_total[tt], "withTamil": termtype_cov.get(tt, 0)}
        for tt in termtype_total
    },
    "unresolvedCrossReferences": bad_refs[:20],
    "unresolvedCrossReferenceCount": len(bad_refs),
}
json.dump(out, open(os.path.join(CAT, "audit_localization_2a.json"), "w", encoding="utf-8"),
           indent=2, ensure_ascii=False)

print("=== PER-CATALOG TAMIL COVERAGE ===")
for fname, r in report.items():
    if isinstance(r, str):
        print(fname, r); continue
    print(f"{fname:38} records={r['recordCount']:4} anyTamil={r['recordsWithAnyTamil']:4} ({r['pctWithAnyTamil']:.1%})")

print("\n=== SCHEME_CATALOG.JSON FIELD-LEVEL TAMIL GAPS (out of 219) ===")
for k, v in missing_by_field.most_common():
    print(f"   {k:18} missing={v:4}")

print("\n=== COMMON_CATALOG.JSON TERM-TYPE COVERAGE (controlled vocabulary / official terminology) ===")
for tt, total in termtype_total.most_common():
    cov = termtype_cov.get(tt, 0)
    print(f"   {tt:20} {cov}/{total}  ({cov/total:.1%})")

print(f"\nunresolvedCrossReferences: {len(bad_refs)}")
print("written: audit_localization_2a.json")
