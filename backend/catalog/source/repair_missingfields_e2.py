#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Repair pass: reconcile_eligibility_e2.py's first (flawed) run had removed
the aggregated 'content.eligibility.structured' missingFields entry
unconditionally for every touched record, which validate_catalog.py rule 40
correctly flagged (26 records now fail: unresolved facets exist but are no
longer logged). This restores the entry, computed fresh from the actual
current 'applies' state of each facet -- using the exact wording convention
already used elsewhere in this catalog (see SCH000005), not fabricated."""
import json, hashlib

FACETS = ["age", "gender", "enterprise", "businessStage", "sector", "turnover",
          "investment", "location", "community", "specialCategory", "existingRegistration"]

with open("scheme_catalog.json", encoding="utf-8") as f:
    catalog = json.load(f)

fixed = []
for r in catalog["data"]:
    st = r["content"]["eligibility"]["structured"]
    unresolved = [fct for fct in FACETS if st[fct]["applies"] is None]
    has_entry = any(m["field"] == "content.eligibility.structured"
                     for m in r["verification"]["missingFields"])
    if unresolved and not has_entry:
        r["verification"]["missingFields"].append({
            "field": "content.eligibility.structured",
            "reason": f"Facets not determinable from available sources: {', '.join(unresolved)}",
        })
        fixed.append(r["identity"]["id"])


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open("scheme_catalog.json", "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"Repaired {len(fixed)} records: {fixed}")
