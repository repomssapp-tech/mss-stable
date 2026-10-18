#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.2 Step 1 -- data reconciliation, not enrichment.

scheme_catalog.json's raw content.eligibility.structured.* / .
targetBeneficiaries.* enum fields are mostly empty (Phase E.0 audit:
0-35%), but applicability_matrix_catalog.json (built by
build_applicability_matrix.py from this SAME scheme content, one record
per scheme, checksum-linked via regeneratedFrom.sourceContentChecksum)
already holds the structured facets successfully derived from it. This is
exactly the brief's Step 1 example: information that already exists but
is not connected between two catalogs of the SAME project.

This script backfills the raw scheme fields FROM the matrix wherever the
raw field is empty and the matrix has a value -- gap-fill only, additive,
never overwrites a raw field that already has content. Source tier 4
("previous verified MSS JSON extraction") per
MSS_Data_Completion_Policy_v1.0.md sec 2 -- reusing the project's own
already-derived intelligence, not inventing anything.
"""
import json, hashlib
from collections import OrderedDict

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
am = {r["content"]["schemeId"]: r["content"]
      for r in json.load(open("applicability_matrix_catalog.json", encoding="utf-8"))["data"]}

FIELD_MAP = [
    # (raw dict getter, raw key, matrix key, human label)
    ("targetBeneficiaries", "enterpriseTypes", "enterpriseType", "enterprise type"),
    ("targetBeneficiaries", "businessStages", "businessStage", "business stage"),
    ("targetBeneficiaries", "specialCategories", "specialCategory", "special category"),
]
STRUCT_FIELD_MAP = [
    ("gender", "values", "gender", "gender"),
    ("enterprise", "types", "enterpriseType", "enterprise type"),
    ("businessStage", "values", "businessStage", "business stage"),
    ("specialCategory", "values", "specialCategory", "special category"),
    ("sector", "included", "sector", "sector"),
]

changed = []
field_touch_count = 0

for r in catalog["data"]:
    sid = r["identity"]["id"]
    a = am.get(sid)
    if not a:
        continue
    c = r["content"]
    touched_this_record = False

    tb = c["targetBeneficiaries"]
    for _, rawkey, mkey, label in FIELD_MAP:
        if not tb[rawkey] and a.get(mkey):
            tb[rawkey] = list(a[mkey])
            field_touch_count += 1
            touched_this_record = True

    es = c["eligibility"]["structured"]
    for group, rawkey, mkey, label in STRUCT_FIELD_MAP:
        if not es[group][rawkey] and a.get(mkey):
            es[group][rawkey] = list(a[mkey])
            field_touch_count += 1
            touched_this_record = True

    if touched_this_record:
        r["provenance"].setdefault("fieldSources", []).append({
            "field": "content.targetBeneficiaries.* / content.eligibility.structured.* "
                     "(enterpriseTypes, businessStages, specialCategories, gender.values, "
                     "enterprise.types, businessStage.values, specialCategory.values, "
                     "sector.included -- only the sub-fields that were empty)",
            "value": "backfilled from applicability_matrix_catalog.json",
            "sourceTier": 4,
            "sourceType": "previous_verified_extraction",
            "organization": None,
            "url": None,
            "retrievedAt": RETRIEVED_AT,
            "isBackfill": True,
            "supersededValue": None,
            "note": (f"applicability_matrix_catalog.json's record for this scheme "
                     f"(regeneratedFrom.sourceContentChecksum={a.get('regeneratedFrom', {}).get('sourceContentChecksum', '?')[:24]}...) "
                     f"already holds these facets, derived from this same scheme's content by "
                     f"build_applicability_matrix.py. Reconciliation only -- the matrix's own "
                     f"values are not re-derived or changed, only copied into the raw field "
                     f"that was previously empty despite the matrix already having the answer."),
        })
        # NOT removing the "content.eligibility.structured" missingFields entry here:
        # validate_catalog.py rule 40 requires that entry to remain whenever ANY facet's
        # applies is still None, and backfilling values[]/types[] on a few facets does not
        # resolve the others (age, turnover, investment, location, community, etc. are
        # untouched by this script and typically remain None). Leaving the entry as-is is
        # correct, not an oversight.
        r["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
        r["metadata"]["revision"] += 1
        changed.append(sid)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"Records touched: {len(changed)} / {len(catalog['data'])}")
print(f"Field-instances backfilled: {field_touch_count}")
