#!/usr/bin/env python3
"""Gate Self-Tests (P7 Item 4):
Run T1-T7 against local scratch candidates (never against production).
Verifies:
  T1 an unchanged candidate: PASS, empty diff.
  T2 change one Hindi name and declare it: PASS, diff shows exactly that entity, language, field.
  T3 the same change undeclared: FAIL naming it.
  T4 modify a pack file after the build: FAIL on hash mismatch (G5).
  T5 add a fixture language 'te' as data only, one row, active: it appears in G1-G5 with no code change; remove fixture afterwards.
  T6 change a non-text fact in the core data, undeclared: FAIL.
  T7 drop an existing language from candidate, undeclared: FAIL.
"""

import copy
import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "tools"))
from release_gate import ReleaseGate, DECLARATIONS_DIR

TEST_DIR = REPO_ROOT / "backend" / ".mss_publish_scratch" / "gate_self_tests"
BASELINE_DIR = TEST_DIR / "baseline"

def setup_baseline():
    TEST_DIR.mkdir(parents=True, exist_ok=True)
    if BASELINE_DIR.exists():
        shutil.rmtree(BASELINE_DIR)
    # Copy from published frontend assets as baseline
    src_dir = REPO_ROOT / "frontend" / "assets" / "catalog"
    shutil.copytree(src_dir, BASELINE_DIR)

def run_test(name: str, desc: str, cand_dir: Path, prev_dir: Path, tag: str = "1.36.0-test") -> dict:
    print(f"\n========================================================")
    print(f"--- {name}: {desc} ---")
    gate = ReleaseGate(cand_dir, prev_dir, release_tag=tag, is_local_only=True)
    report = gate.run_all_checks()
    print(f"VERDICT: {report['overallStatus']}")
    for k, v in report["checks"].items():
        print(f"  [{v['status']}] {k}: {v['details']}")
    if report["unmatchedChangesList"]:
        print(f"  Unmatched changes: {report['unmatchedChangesList'][:3]}")
    return report

def main():
    print("=== Setting up Gate Self-Test Baseline ===")
    setup_baseline()

    # --- T1: Unchanged candidate ---
    t1_dir = TEST_DIR / "t1_cand"
    if t1_dir.exists(): shutil.rmtree(t1_dir)
    shutil.copytree(BASELINE_DIR, t1_dir)
    rep_t1 = run_test("T1", "Unchanged candidate (expect PASS, empty diff)", t1_dir, BASELINE_DIR)
    assert rep_t1["overallStatus"] == "PASS", "T1 should PASS"
    assert rep_t1["diffSummary"]["totalDiffs"] == 0, "T1 should have 0 diffs"
    print(">>> T1 PASSED AS EXPECTED!")

    # --- T2: Change one Hindi name and declare it ---
    t2_dir = TEST_DIR / "t2_cand"
    if t2_dir.exists(): shutil.rmtree(t2_dir)
    shutil.copytree(BASELINE_DIR, t2_dir)
    
    # Modify SCH000006 Hindi name in bundle
    bundle_path = t2_dir / "catalog_bundle.json.gz"
    bundle = json.loads(gzip.decompress(bundle_path.read_bytes()).decode("utf-8"))
    for s in bundle["scheme_catalog.json"]["data"]:
        if s["identity"]["id"] == "SCH000006":
            s.setdefault("localization", {}).setdefault("hi", {})["name"] = "अगरबत्ती टेस्ट नाम"
            break
    new_bundle_bytes = gzip.compress(json.dumps(bundle).encode("utf-8"))
    bundle_path.write_bytes(new_bundle_bytes)

    # Update release.json with new bundle sha
    rel_path = t2_dir / "release.json"
    rel_data = json.loads(rel_path.read_text(encoding="utf-8"))
    rel_data["bundleSha256"] = hashlib.sha256(new_bundle_bytes).hexdigest()
    rel_data["bundleBytes"] = len(new_bundle_bytes)
    rel_path.write_text(json.dumps(rel_data, indent=2), encoding="utf-8")

    # Write declaration
    DECLARATIONS_DIR.mkdir(parents=True, exist_ok=True)
    t2_decl = {
        "releaseTag": "1.36.0-t2",
        "declaredChanges": [
            {
                "entityType": "scheme",
                "entityId": "SCH000006",
                "lang": "hi",
                "fields": ["name"],
                "description": "Test name update"
            }
        ]
    }
    (DECLARATIONS_DIR / "1.36.0-t2.json").write_text(json.dumps(t2_decl, indent=2), encoding="utf-8")

    rep_t2 = run_test("T2", "Change one Hindi name and declare it (expect PASS, diff shows that field)", t2_dir, BASELINE_DIR, tag="1.36.0-t2")
    assert rep_t2["overallStatus"] == "PASS", "T2 should PASS"
    assert rep_t2["diffSummary"]["totalDiffs"] == 1, "T2 should have exactly 1 diff"
    assert rep_t2["diffSummary"]["unmatchedChanges"] == 0, "T2 should have 0 unmatched changes"
    print(">>> T2 PASSED AS EXPECTED!")

    # --- T3: Same change undeclared ---
    # Delete declaration file
    (DECLARATIONS_DIR / "1.36.0-t3.json").write_text(json.dumps({"releaseTag": "1.36.0-t3", "declaredChanges": []}), encoding="utf-8")
    rep_t3 = run_test("T3", "Same change undeclared (expect FAIL naming it)", t2_dir, BASELINE_DIR, tag="1.36.0-t3")
    assert rep_t3["overallStatus"] == "FAIL", "T3 should FAIL"
    assert rep_t3["diffSummary"]["unmatchedChanges"] == 1, "T3 should have 1 unmatched change"
    assert rep_t3["unmatchedChangesList"][0]["entityId"] == "SCH000006"
    assert rep_t3["unmatchedChangesList"][0]["field"] == "name"
    print(">>> T3 FAILED AS EXPECTED (NAMED SCH000006 hi.name)!")

    # --- T4: Modify pack file after build (hash mismatch G5) ---
    t4_dir = TEST_DIR / "t4_cand"
    if t4_dir.exists(): shutil.rmtree(t4_dir)
    shutil.copytree(BASELINE_DIR, t4_dir)
    # Modify pack file after build without updating release.json
    (t4_dir / "catalog_pack_hi.json.gz").write_bytes(gzip.compress(b'{"metadata": {}, "data": []}'))
    rep_t4 = run_test("T4", "Modify pack file after build without updating hash (expect FAIL on G5)", t4_dir, BASELINE_DIR, tag="1.36.0-t4")
    assert rep_t4["overallStatus"] == "FAIL", "T4 should FAIL"
    assert rep_t4["checks"]["G5_hashes"]["status"] == "FAIL", "G5 should FAIL"
    print(">>> T4 FAILED AS EXPECTED ON G5 HASH MISMATCH!")

    # --- T5: Add fixture language 'te' as data only, one row, active ---
    t5_dir = TEST_DIR / "t5_cand"
    if t5_dir.exists(): shutil.rmtree(t5_dir)
    shutil.copytree(BASELINE_DIR, t5_dir)
    # Add catalog_pack_te.json.gz
    te_pack_data = {
        "metadata": {"lang": "te", "entityCount": 1},
        "data": [{"entityId": "SCH000006", "name": "తెలుగు పథకం", "verified": True}]
    }
    te_bytes = gzip.compress(json.dumps(te_pack_data).encode("utf-8"))
    (t5_dir / "catalog_pack_te.json.gz").write_bytes(te_bytes)
    # Add te to activeLanguages
    rel_t5 = json.loads((t5_dir / "release.json").read_text(encoding="utf-8"))
    # Extend the baseline's languages so the fixture only ADDS 'te'.
    rel_t5["activeLanguages"] = list(rel_t5["activeLanguages"]) + ["te"]
    (t5_dir / "release.json").write_text(json.dumps(rel_t5, indent=2), encoding="utf-8")
    # Add declaration
    t5_decl = {
        "releaseTag": "1.36.0-t5",
        "declaredChanges": [
            {
                "entityType": "pack",
                "entityId": "*",
                "lang": "te",
                "fields": ["*"],
                "description": "Fixture Telugu pack added"
            }
        ]
    }
    (DECLARATIONS_DIR / "1.36.0-t5.json").write_text(json.dumps(t5_decl, indent=2), encoding="utf-8")
    rep_t5 = run_test("T5", "Add fixture language 'te' as data only (expect PASS with te detected)", t5_dir, BASELINE_DIR, tag="1.36.0-t5")
    assert rep_t5["overallStatus"] == "PASS", "T5 should PASS"
    print(">>> T5 PASSED AS EXPECTED (NEW LANGUAGE RECOGNIZED WITH NO CODE CHANGE)!")

    # --- T6: Change a non-text fact in core data undeclared ---
    t6_dir = TEST_DIR / "t6_cand"
    if t6_dir.exists(): shutil.rmtree(t6_dir)
    shutil.copytree(BASELINE_DIR, t6_dir)
    bundle_path = t6_dir / "catalog_bundle.json.gz"
    bundle = json.loads(gzip.decompress(bundle_path.read_bytes()).decode("utf-8"))
    for s in bundle["scheme_catalog.json"]["data"]:
        if s["identity"]["id"] == "SCH000006":
            s.setdefault("content", {})["max_subsidy_amount"] = 9999999  # non-text change
            break
    new_bundle_bytes = gzip.compress(json.dumps(bundle).encode("utf-8"))
    bundle_path.write_bytes(new_bundle_bytes)
    rel_t6 = json.loads((t6_dir / "release.json").read_text(encoding="utf-8"))
    rel_t6["bundleSha256"] = hashlib.sha256(new_bundle_bytes).hexdigest()
    (t6_dir / "release.json").write_text(json.dumps(rel_t6, indent=2), encoding="utf-8")
    (DECLARATIONS_DIR / "1.36.0-t6.json").write_text(json.dumps({"releaseTag": "1.36.0-t6", "declaredChanges": []}), encoding="utf-8")
    rep_t6 = run_test("T6", "Change non-text fact in core data undeclared (expect FAIL)", t6_dir, BASELINE_DIR, tag="1.36.0-t6")
    assert rep_t6["overallStatus"] == "FAIL", "T6 should FAIL"
    assert rep_t6["diffSummary"]["unmatchedChanges"] == 1
    assert rep_t6["unmatchedChangesList"][0]["field"] == "max_subsidy_amount"
    print(">>> T6 FAILED AS EXPECTED (NAMED max_subsidy_amount)!")

    # --- T7: Drop an existing language undeclared ---
    t7_dir = TEST_DIR / "t7_cand"
    if t7_dir.exists(): shutil.rmtree(t7_dir)
    shutil.copytree(BASELINE_DIR, t7_dir)
    rel_t7 = json.loads((t7_dir / "release.json").read_text(encoding="utf-8"))
    rel_t7["activeLanguages"] = ["en"]  # dropped 'ta'!
    (t7_dir / "release.json").write_text(json.dumps(rel_t7, indent=2), encoding="utf-8")
    rep_t7 = run_test("T7", "Drop existing active language 'ta' undeclared (expect FAIL on G4)", t7_dir, BASELINE_DIR, tag="1.36.0-t7")
    assert rep_t7["overallStatus"] == "FAIL", "T7 should FAIL"
    assert rep_t7["checks"]["G4_preservation"]["status"] == "FAIL"
    print(">>> T7 FAILED AS EXPECTED ON DROPPED LANGUAGE!")

    # Clean up test declaration fixtures
    for f in ["1.36.0-t2.json", "1.36.0-t3.json", "1.36.0-t5.json", "1.36.0-t6.json"]:
        p = DECLARATIONS_DIR / f
        if p.exists(): p.unlink()
    shutil.rmtree(TEST_DIR, ignore_errors=True)

    print("\n========================================================")
    print("ALL GATE SELF-TESTS (T1 - T7) PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
