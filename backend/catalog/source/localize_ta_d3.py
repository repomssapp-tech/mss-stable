#!/usr/bin/env python3
"""Phase D3 — Tamil localization for the remaining non-scheme catalogs.

Reuses build_i18n.py's exact translate()/upgrade() pipeline (dictionary +
compositional pattern translation, protected-token masking, machine-Tamil
labelling) unchanged -- no new translation mechanism, per
MSS_Data_Completion_Policy_v1.0.md's "controlled fallback" tier. Only the
hardcoded CAT path (a stale absolute path from a prior session/environment)
is overridden to run against this checkout.

Targets the 11 catalogs that make up the ~302-record gap named in the task
brief (scheme_catalog.json, authority_catalog.json and common_catalog.json
are already 100% localized from a prior round and are not touched again).
"""
import sys, os, json
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_i18n
build_i18n.CAT = "."  # override stale absolute path; run relative to cwd

TARGETS = [
    "business_enablement_catalog.json",
    "cluster_assistance_catalog.json",
    "csr_catalog.json",
    "enterprise_classification_catalog.json",
    "export_catalog.json",
    "finance_catalog.json",
    "institution_catalog.json",
    "knowledge_catalog.json",
    "msme_privilege_catalog.json",
    "tax_catalog.json",
    "treds_catalog.json",
]

build_i18n.AT = "2026-08-15T00:00:00Z"


def ensure_ta_hi_blocks(fname):
    """4 catalogs (business_enablement, cluster_assistance,
    enterprise_classification, msme_privilege) never had localization.ta/.hi
    keys added -- normalize the schema to match every other catalog's shape
    (each en field present as null) before the translation pass writes into
    loc['ta']. Purely structural; no content changes."""
    path = os.path.join(".", fname)
    with open(path, encoding="utf-8") as fh:
        cat = json.load(fh)
    changed = False
    for r in cat["data"]:
        loc = r["localization"]
        if "ta" not in loc:
            loc["ta"] = {k: None for k in loc["en"]}
            changed = True
        if "hi" not in loc:
            loc["hi"] = {k: None for k in loc["en"]}
            changed = True
    if changed:
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(cat, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
    return changed


def main():
    stat = Counter()
    for f in TARGETS:
        if ensure_ta_hi_blocks(f):
            print(f"   [schema] {f}: added empty ta/hi blocks")
        cat = build_i18n.upgrade(f, stat)
        print(f"{f:45} records={len(cat['data']):4} checksum={cat['metadata']['checksum'][:22]}...")
    print()
    for k in sorted(stat):
        print(f"   {k:55} {stat[k]}")

if __name__ == "__main__":
    main()
