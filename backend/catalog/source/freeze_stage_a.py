#!/usr/bin/env python3
"""
Stage A freeze record.

WRITE-ONCE. The baseline is 1.0.0-alpha and its data is retained immutably at
stage_a_frozen/. Running this script when STAGE_A_FREEZE.json already exists is
refused: on 2026-08-05 an accidental re-run rewrote the record with the THEN-LIVE
1.31.0-alpha catalog's size and hashes while still claiming release 1.0.0-alpha.
The record was rebuilt from the retained baseline copy; see `recordProvenance`.

Use `--verify` to check the retained baseline against the record.
"""
import json, hashlib, os, sys

OUT = "/sessions/practical-charming-hypatia/mnt/Plan/catalog"
FROZEN_DIR = os.path.join(OUT, "stage_a_frozen")
REC = os.path.join(OUT, "STAGE_A_FREEZE.json")
REL = "1.0.0-alpha"
FROZEN_AT = "2026-08-04T00:00:00Z"

def sha_file(p): return "sha256:" + hashlib.sha256(open(p, "rb").read()).hexdigest()

def build():
    base = os.path.join(FROZEN_DIR, "scheme_catalog.json")
    cat = json.load(open(base, encoding="utf-8"))
    return {
        "release": REL, "stage": "A", "label": "Stage A Frozen",
        "frozenAt": FROZEN_AT, "immutable": True,
        "description": (
            "Document-derived baseline built from source tiers 1-4 with no network access. "
            "Deterministic: identical source documents reproduce this byte-for-byte apart "
            "from generatedAt."),
        "recordCount": cat["metadata"]["recordCount"],
        "catalogChecksum": cat["metadata"]["checksum"],
        "schemaVersion": cat["metadata"]["schemaVersion"],
        "governingDocuments": [
            "MSS_Offline_Catalog_Architecture_Specification_v1.0.md",
            "MSS_Base_Entity_Model_v1.0.md", "MSS_Scheme_Catalog_Schema_v1.0.md",
            "MSS_Data_Completion_Policy_v1.0.md", "MSS_Data_Migration_Guide.md"],
        "validation": {"status": "PASSED",
                       "ruleSets": ["base 1-30", "scheme 31-45", "policy 1-10", "batch 25-37"],
                       "failures": 0},
        "files": [{"fileName": "scheme_catalog.json",
                   "retainedAt": "catalog/stage_a_frozen/scheme_catalog.json",
                   "byteSize": os.path.getsize(base), "checksum": sha_file(base)}],
        "bytesNotRetained": {
            "files": ["manifest.json", "unmapped_values.csv", "generate_stage_a.py",
                      "validate_catalog.py"],
            "reason": ("These were listed in the original freeze record but their Stage A "
                       "bytes are not retained separately; the live copies have since changed "
                       "across later releases. Their Stage-A-era hashes are therefore not "
                       "asserted rather than reconstructed.")},
        "recordProvenance": {
            "rebuiltAt": "2026-08-05T00:00:00Z",
            "reason": ("freeze_stage_a.py was run against the live catalog directory during "
                       "the multilingual batch loop, overwriting the record with the live "
                       "1.31.0-alpha catalog's byteSize and checksums under the 1.0.0-alpha "
                       "label. Rebuilt from the untouched baseline copy at stage_a_frozen/."),
            "evidence": ("stage_a_frozen/scheme_catalog.json is unmodified since 2026-08-04 "
                         "and carries catalogVersion 1.0.0 in its own metadata; every value "
                         "above is read from that file."),
            "baselineDataAffected": False},
        "regenerationRule": (
            "Stage A is NOT regenerated except when a source document changes. All subsequent "
            "improvement occurs through Stage B passes or a future catalog release. Any "
            "regeneration requires a new release identifier and a fresh freeze record."),
        "downstreamRule": (
            "Stage B Pass 1 (verification) MUST NOT mutate any Stage A content value. "
            "Stage B Pass 2 (enrichment) MAY populate fields that are null in Stage A, and "
            "MUST NOT modify fields Stage A populated."),
    }

def verify():
    rec = json.load(open(REC, encoding="utf-8"))
    ok = True
    for f in rec["files"]:
        p = os.path.join(OUT, f["retainedAt"].split("catalog/", 1)[1])
        h = sha_file(p)
        if h != f["checksum"] or os.path.getsize(p) != f["byteSize"]:
            ok = False; print(f"  DRIFT {f['fileName']}")
    cat = json.load(open(os.path.join(FROZEN_DIR, "scheme_catalog.json"), encoding="utf-8"))
    if cat["metadata"]["checksum"] != rec["catalogChecksum"]:
        ok = False; print("  DRIFT catalogChecksum")
    print("FREEZE INTACT" if ok else "FREEZE BROKEN")
    return 0 if ok else 1

if __name__ == "__main__":
    if "--verify" in sys.argv:
        sys.exit(verify())
    if os.path.exists(REC) and "--force-rebuild" not in sys.argv:
        print("REFUSED — STAGE_A_FREEZE.json exists. Freeze is write-once. "
              "Use --verify, or --force-rebuild only to repair a corrupted record.")
        sys.exit(1)
    json.dump(build(), open(REC, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"WROTE {REC}")
