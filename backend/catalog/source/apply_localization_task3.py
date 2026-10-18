# -*- coding: utf-8 -*-
"""Tamil Localization Completion Phase, Task 3 -- run the existing
build_i18n.upgrade() pipeline against the 5 previously zero-coverage
catalogs (cluster_assistance, csr, treds, msme_privilege,
business_enablement), now that ta_overrides.json carries contextual
entries for their content and ta_dictionary.py carries the extracted
reusable domain terms. Scoped to exactly these 5 files -- does not touch
scheme_catalog.json, common_catalog.json, authority_catalog.json, or the
2 partially-covered catalogs (knowledge_catalog, enterprise_classification),
which were out of this task's stated scope.
"""
import sys, os
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_i18n as bi
bi.CAT = os.path.dirname(os.path.abspath(__file__))
bi.AT = "2026-08-15T00:00:00Z"

TARGETS = [
    "cluster_assistance_catalog.json",
    "csr_catalog.json",
    "treds_catalog.json",
    "msme_privilege_catalog.json",
    "business_enablement_catalog.json",
]


def ensure_ta_hi_blocks(fname):
    """CLUS000005-CLUS000010 (added later, Phase D2/E1) never got ta/hi
    localization keys added at all -- same gap localize_ta_d3.py fixed for
    4 catalogs originally, recurring here for records created afterward.
    Purely structural (each en field present as null); no content change."""
    import json
    path = os.path.join(bi.CAT, fname)
    cat = json.load(open(path, encoding="utf-8"))
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
        json.dump(cat, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    return changed


def main():
    stat = Counter()
    for f in TARGETS:
        if ensure_ta_hi_blocks(f):
            print(f"   [schema] {f}: added missing ta/hi blocks to some records")
        cat = bi.upgrade(f, stat)
        print(f"{f:40} records={len(cat['data']):4} checksum={cat['metadata']['checksum'][:22]}...")
    print()
    for k in sorted(stat):
        print(f"   {k:55} {stat[k]}")


if __name__ == "__main__":
    main()
