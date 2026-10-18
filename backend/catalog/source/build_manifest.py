#!/usr/bin/env python3
"""Regenerate manifest.json for the current catalog release."""
import json, os, hashlib
from collections import OrderedDict

CAT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
REL = "1.33.0-alpha"
AT = "2026-08-04T00:00:00Z"
SV = "1.0.0"

ALL = ["common_catalog.json", "authority_catalog.json", "institution_catalog.json",
       "scheme_catalog.json", "finance_catalog.json", "tax_catalog.json",
       "treds_catalog.json", "csr_catalog.json", "export_catalog.json",
       "knowledge_catalog.json", "search_index.json", "translations_en.json",
       "translations_ta.json"]

def canon(o): return json.dumps(o, sort_keys=True, separators=(",", ":"), ensure_ascii=False)

files, reserved = [], []
for f in ALL:
    p = os.path.join(CAT, f)
    if os.path.exists(p):
        c = json.load(open(p, encoding="utf-8"))
        files.append(OrderedDict([
            ("fileName", f), ("catalogName", c["metadata"]["catalogName"]),
            ("schemaVersion", c["metadata"]["schemaVersion"]),
            ("recordCount", c["metadata"]["recordCount"]),
            ("byteSize", os.path.getsize(p)),
            ("checksum", "sha256:" + hashlib.sha256(canon(c["data"]).encode()).hexdigest()),
            ("required", f in ("common_catalog.json", "scheme_catalog.json"))]))
    else:
        reserved.append(f)

data = [OrderedDict([
    ("catalogRelease", REL), ("schemaVersion", SV), ("releasedAt", AT),
    ("compatibility", {"minAppVersion": None, "supersedes": "1.0.0-alpha"}),
    ("stage", "A — document-derived (tiers 1-4). Identifiers resolved against "
              "common_catalog and authority_catalog. No network sourcing."),
    ("baseline", {"release": "1.0.0-alpha", "retainedAt": "catalog/stage_a_frozen/",
                  "immutable": True}),
    ("generationOrder", [{"phase": 1, "file": "common_catalog.json"},
                         {"phase": 2, "file": "authority_catalog.json"},
                         {"phase": 3, "file": "institution_catalog.json"},
                         {"phase": 4, "file": "scheme_catalog.json"}]),
    ("files", files), ("reservedFiles", reserved)])]

man = OrderedDict([
    ("metadata", OrderedDict([("catalogName", "manifest"), ("schemaVersion", SV),
                              ("catalogVersion", REL), ("generatedAt", AT),
                              ("language", "en"), ("recordCount", 1),
                              ("checksum", "sha256:" + hashlib.sha256(canon(data).encode()).hexdigest())])),
    ("data", data)])
json.dump(man, open(os.path.join(CAT, "manifest.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=2)
print(f"manifest.json -> {REL}  files={len(files)}  reserved={len(reserved)}")
for f in files:
    print(f"   {f['fileName']:26} {f['recordCount']:>5} records  {f['byteSize']:>9,} B  "
          f"{f['checksum'][:22]}…")
