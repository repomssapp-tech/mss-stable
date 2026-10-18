#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.1 Batch 1b -- fills 2 null department fields in scheme_catalog.json
from the same Tier-1 held document as enrich_finance_e1_batch1.py:
"Compendium of Schemes for MSMEs 2022" (MSME Dept, Govt of TN, Sep 2022).

SCH000011 (SAFE) and SCH000012 (ARISE) already have
implementingAgencyText="Small Industries Development Bank of India
(SIDBI)" from an earlier round; their departmentText is null. Both
schemes appear in the booklet's Table of Contents (p.6-7, Sl. 48-49)
grouped under the "Small Industries Development Bank of India"
implementing-agency heading, and their individual pages (84, 85) both
cite sidbi.in contact URLs -- same convention already used for every
other SIDBI-administered scheme in this catalog (SCH000059, SCH000061,
SCH000078, SCH000152, SCH000159, SCH000160 all carry
departmentText="Small Industries Development Bank of India (SIDBI)").
Applying the identical, already-established value for these two
same-agency records is mechanical consistency, not a new inference --
verified against both the TOC and the individual scheme pages before
writing, not assumed from the pattern alone.
"""
import json, hashlib

PATH = "scheme_catalog.json"
RETRIEVED_AT = "2026-08-15"
DEPT = "Small Industries Development Bank of India (SIDBI)"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)
recs = {r["identity"]["id"]: r for r in catalog["data"]}
changed = []

for sid, page in (("SCH000011", 85), ("SCH000012", 84)):
    r = recs[sid]
    g = r["content"]["classification"]["government"]
    assert g["departmentText"] is None
    assert g["implementingAgencyText"] == DEPT
    g["departmentText"] = DEPT
    r["provenance"].setdefault("fieldSources", []).append({
        "field": "content.classification.government.departmentText",
        "value": DEPT,
        "sourceTier": 1,
        "sourceType": "official_booklet_held",
        "organization": "MSME Department, Government of Tamil Nadu",
        "url": None,
        "retrievedAt": RETRIEVED_AT,
        "isBackfill": True,
        "supersededValue": None,
        "note": (f'"Compendium of Schemes for MSMEs 2022" Table of Contents (p.6-7) groups '
                 f'this scheme under implementing agency "Small Industries Development Bank '
                 f'of India"; page {page} confirms via its sidbi.in contact reference. Same '
                 f"value already used for every other SIDBI-administered scheme in this "
                 f"catalog -- applied for consistency, verified against the source, not "
                 f"assumed from the pattern."),
    })
    r["verification"]["missingFields"] = [
        m for m in r["verification"]["missingFields"]
        if m["field"] != "content.classification.government.departmentText"]
    r["metadata"]["updatedAt"] = RETRIEVED_AT + "T00:00:00Z"
    r["metadata"]["revision"] += 1
    changed.append(sid)


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("Changed:", changed)
