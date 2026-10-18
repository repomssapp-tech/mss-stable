#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Phase E.0 -- Complete Data Population Audit. READ ONLY.

Walks every *_catalog.json, computes a leaf-field population matrix
(path -> total/filled/missing/coverage%), and writes JSON summaries this
script's caller (write_audit_report.py) turns into the markdown report.
Never writes to any catalog file.
"""
import json, os, sys
from collections import defaultdict, OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))


def load(f):
    with open(os.path.join(CAT, f), encoding="utf-8") as fh:
        return json.load(fh)


def is_empty(v):
    if v is None:
        return True
    if isinstance(v, str) and v.strip() == "":
        return True
    if isinstance(v, (list, dict)) and len(v) == 0:
        return True
    return False


def walk(obj, prefix, out):
    """Collect (path -> filled/missing) for every leaf scalar, and for every
    list also record whether it's empty vs non-empty as a leaf itself."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            walk(v, f"{prefix}.{k}" if prefix else k, out)
    elif isinstance(obj, list):
        out[prefix].append(0 if is_empty(obj) else 1)
        # Also descend into list-of-dict items under a normalized path, so
        # e.g. relationships.references[].relationType is tracked too.
        if obj and isinstance(obj[0], dict):
            for item in obj:
                walk(item, f"{prefix}[]", out)
    else:
        out[prefix].append(0 if is_empty(obj) else 1)


def audit_catalog(fname):
    cat = load(fname)
    records = cat["data"]
    field_stats = defaultdict(list)
    for r in records:
        walk(r, "", field_stats)
    rows = []
    for path, vals in sorted(field_stats.items()):
        total = len(vals)
        filled = sum(vals)
        rows.append({
            "field": path, "total": total, "filled": filled,
            "missing": total - filled,
            "coveragePct": round(100 * filled / total, 1) if total else 0.0,
        })
    return {
        "catalog": fname,
        "recordCount": len(records),
        "catalogVersion": cat["metadata"].get("catalogVersion"),
        "fields": rows,
    }


def main():
    targets = sys.argv[1:] or sorted(
        f for f in os.listdir(CAT) if f.endswith("_catalog.json")
    )
    results = OrderedDict()
    for f in targets:
        results[f] = audit_catalog(f)
    out_path = os.path.join(CAT, "audit_field_population.json")
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(results, fh, ensure_ascii=False, indent=2)
    print(f"wrote {out_path} -- {len(results)} catalogs audited")
    for f, r in results.items():
        n_fields = len(r["fields"])
        avg_cov = (sum(x["coveragePct"] for x in r["fields"]) / n_fields) if n_fields else 0
        print(f"  {f:45} records={r['recordCount']:5} fields_tracked={n_fields:4} avg_field_coverage={avg_cov:5.1f}%")


if __name__ == "__main__":
    main()
