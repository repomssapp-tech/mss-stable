#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.2 Step 2 -- graph consistency: remove exact duplicate
relationship edges (same entityId + relationType declared twice on one
record), found by the Phase E.0 audit's relationship scan (4 records in
export_catalog.json, 5 duplicate entries). Structural cleanup only: no
edge is added, retargeted, or reinterpreted -- only exact repeats of an
edge already present are dropped, keeping the first occurrence's
role/note. Scoped to export_catalog.json (the only catalog the E.0 audit
found duplicates in), not applied speculatively elsewhere.
"""
import json, hashlib

PATH = "export_catalog.json"

with open(PATH, encoding="utf-8") as f:
    catalog = json.load(f)

removed = []
for r in catalog["data"]:
    refs = r["relationships"]["references"]
    seen = set()
    deduped = []
    for ref in refs:
        key = (ref["entityId"], ref["relationType"])
        if key in seen:
            removed.append((r["identity"]["id"], key))
            continue
        seen.add(key)
        deduped.append(ref)
    if len(deduped) != len(refs):
        r["relationships"]["references"] = deduped
        r["metadata"]["updatedAt"] = "2026-08-15T00:00:00Z"
        r["metadata"]["revision"] += 1
        r["provenance"].setdefault("transformationNotes", []).append(
            "Phase E.2 (2026-08-15): removed duplicate relationship edge(s) "
            f"{[k for rid, k in removed if rid == r['identity']['id']]} -- exact "
            "repeats of an edge already present; no edge added or changed.")


def canon(o):
    return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


catalog["metadata"]["checksum"] = "sha256:" + hashlib.sha256(canon(catalog["data"]).encode()).hexdigest()

with open(PATH, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"Removed {len(removed)} duplicate edges: {removed}")
