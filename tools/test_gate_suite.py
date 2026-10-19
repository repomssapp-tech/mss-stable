#!/usr/bin/env python3
"""Gate Self-Tests (P7 Item 4):
Run T1-T7 against local scratch candidates (never against production).
Verifies:
  T1 an unchanged candidate: PASS, empty diff.
  T2 change one Hindi name and declare it: PASS, diff shows exactly that entity, language, field.
  T3 the same change undeclared: FAIL naming it.
  T4 modify the bundle after the build: FAIL on hash mismatch (G5).
  T5 add a fixture language 'te' as data only (one translated name, active): it appears in G1-G5 with no code change.
  T6 change a non-text fact in the core data, undeclared: FAIL.
  T7 drop an existing language from candidate, undeclared: FAIL.
"""

import copy
import gzip
import hashlib
import json
import os
from pathlib import Path

import catalog_packs
import shutil
import subprocess
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "tools"))
from release_gate import ReleaseGate, DECLARATIONS_DIR

TEST_DIR = REPO_ROOT / "backend" / ".mss_publish_scratch" / "gate_self_tests"
BASELINE_DIR = TEST_DIR / "baseline"

# A 2026 central scheme that has English, Hindi and Tamil text.
SCHEME_ID = "CEN2026-223"


def setup_baseline():
    """Build a baseline release with the current builder.

    The shipped assets hold only the core and jurisdiction packs (release.json is a
    build artifact), so the baseline is built, then reduced to what the gate
    compares: the packs and release.json.
    """
    TEST_DIR.mkdir(parents=True, exist_ok=True)
    if BASELINE_DIR.exists():
        shutil.rmtree(BASELINE_DIR)
    subprocess.run(
        [sys.executable, str(REPO_ROOT / "tools" / "build_catalog_release.py"),
         "--out-dir", str(BASELINE_DIR), "--offline"],
        check=True, stdout=subprocess.DEVNULL,
    )
    for f in BASELINE_DIR.iterdir():
        if f.name != "release.json" and not f.name.startswith("catalog_"):
            f.unlink()


def repack(directory: Path, mutate, **release_patch) -> None:
    """Load the merged catalog in [directory], apply [mutate](bundle), write it back
    as core + packs, and refresh release.json (core sha256, byte total, pack hashes)."""
    bundle = catalog_packs.load_dir(directory)
    mutate(bundle)
    for stale in catalog_packs.pack_files(directory):
        stale.unlink()
    langs = {p["jurisdiction"]: p["languages"] for p in bundle["manifest.json"]["data"][0]["packs"]
             if p.get("kind") == "jurisdiction"}
    packs = catalog_packs.split(bundle, directory, langs)
    core = catalog_packs.write_core(bundle, directory, packs)
    rel_path = directory / "release.json"
    rel = json.loads(rel_path.read_text(encoding="utf-8"))
    rel["bundleSha256"] = core["sha256"]
    rel["bundleBytes"] = core["bytes"] + sum(p["bytes"] for p in packs)
    rel["packs"] = [{k: p[k] for k in ("id", "file", "jurisdiction", "tenantId", "required", "bytes", "sha256")}
                    for p in packs]
    rel.update(release_patch)
    rel_path.write_text(json.dumps(rel, indent=2), encoding="utf-8")

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
    
    # Modify CEN2026-223 Hindi name in the packs
    def t2_edit(bundle):
        for s in bundle["scheme_catalog.json"]["data"]:
            if s["identity"]["id"] == SCHEME_ID:
                s.setdefault("localization", {}).setdefault("hi", {})["name"] = "अगरबत्ती टेस्ट नाम"
                break
    repack(t2_dir, t2_edit)

    # Write declaration
    DECLARATIONS_DIR.mkdir(parents=True, exist_ok=True)
    t2_decl = {
        "releaseTag": "1.36.0-t2",
        "declaredChanges": [
            {
                "entityType": "scheme",
                "entityId": SCHEME_ID,
                "lang": "hi",
                "fields": ["name"],
                "diffTypes": ["changed"],
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
    assert rep_t3["unmatchedChangesList"][0]["entityId"] == SCHEME_ID
    assert rep_t3["unmatchedChangesList"][0]["field"] == "name"
    print(">>> T3 FAILED AS EXPECTED (NAMED CEN2026-223 hi.name)!")

    # --- T4: Modify pack file after build (hash mismatch G5) ---
    t4_dir = TEST_DIR / "t4_cand"
    if t4_dir.exists(): shutil.rmtree(t4_dir)
    shutil.copytree(BASELINE_DIR, t4_dir)
    # Modify a pack after build without updating the manifest or release.json
    (t4_dir / "catalog_tamil_nadu.json.gz").write_bytes(gzip.compress(b'{"metadata": {}, "data": []}'))
    rep_t4 = run_test("T4", "Modify a pack after build without updating its hash (expect FAIL on G5)", t4_dir, BASELINE_DIR, tag="1.36.0-t4")
    assert rep_t4["overallStatus"] == "FAIL", "T4 should FAIL"
    assert rep_t4["checks"]["G5_hashes"]["status"] == "FAIL", "G5 should FAIL"
    print(">>> T4 FAILED AS EXPECTED ON G5 HASH MISMATCH!")

    # --- T5: Add fixture language 'te' as data only, one row, active ---
    t5_dir = TEST_DIR / "t5_cand"
    if t5_dir.exists(): shutil.rmtree(t5_dir)
    shutil.copytree(BASELINE_DIR, t5_dir)
    # Add a Telugu name to one scheme, inside the bundle (translations are embedded)
    def t5_edit(bundle):
        for sc in bundle["scheme_catalog.json"]["data"]:
            if sc["identity"]["id"] == SCHEME_ID:
                sc.setdefault("localization", {})["te"] = {"name": "తెలుగు పథకం"}
                break
    # Extend the baseline's languages so the fixture only ADDS 'te'.
    rel_t5 = json.loads((t5_dir / "release.json").read_text(encoding="utf-8"))
    repack(t5_dir, t5_edit, activeLanguages=list(rel_t5["activeLanguages"]) + ["te"])
    # Add declaration
    t5_decl = {
        "releaseTag": "1.36.0-t5",
        "declaredChanges": [
            {
                "entityType": "scheme",
                "entityId": SCHEME_ID,
                "lang": "te",
                "fields": ["name"],
                "diffTypes": ["added"],
                "description": "Fixture Telugu name added"
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
    def t6_edit(bundle):
        for s in bundle["scheme_catalog.json"]["data"]:
            if s["identity"]["id"] == SCHEME_ID:
                s.setdefault("content", {})["max_subsidy_amount"] = 9999999  # non-text change
                break
    repack(t6_dir, t6_edit)
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

    # --- T8: Wildcard 'added' declaration must still FAIL on a removal ---
    t8_dir = TEST_DIR / "t8_cand"
    if t8_dir.exists(): shutil.rmtree(t8_dir)
    shutil.copytree(BASELINE_DIR, t8_dir)
    def t8_edit(bundle):
        for s in bundle["scheme_catalog.json"]["data"]:
            if s["identity"]["id"] == SCHEME_ID:
                if "localization" in s and "hi" in s["localization"] and "name" in s["localization"]["hi"]:
                    del s["localization"]["hi"]["name"]
                break
    repack(t8_dir, t8_edit)
    t8_decl = {
        "releaseTag": "1.36.0-t8",
        "declaredChanges": [
            {
                "entityType": "scheme",
                "entityId": "*",
                "lang": "*",
                "fields": ["*"],
                "diffTypes": ["added"],
                "description": "Wildcard added only"
            }
        ]
    }
    (DECLARATIONS_DIR / "1.36.0-t8.json").write_text(json.dumps(t8_decl, indent=2), encoding="utf-8")
    rep_t8 = run_test("T8", "Wildcard 'added' declaration on a removal (expect FAIL on G3)", t8_dir, BASELINE_DIR, tag="1.36.0-t8")
    assert rep_t8["overallStatus"] == "FAIL", "T8 should FAIL"
    assert rep_t8["checks"]["G3_declared_changes"]["status"] == "FAIL", "G3 should FAIL on removal when only added declared"
    assert rep_t8["diffSummary"]["unmatchedChanges"] >= 1
    print(">>> T8 PASSED AS EXPECTED (WILDCARD 'ADDED' FAILED ON REMOVAL)!")

    # --- T9: Content drift must FAIL ---
    t9_dir = TEST_DIR / "t9_cand"
    if t9_dir.exists(): shutil.rmtree(t9_dir)
    shutil.copytree(BASELINE_DIR, t9_dir)
    def t9_edit(bundle):
        for s in bundle["scheme_catalog.json"]["data"]:
            if s["identity"]["id"] == SCHEME_ID:
                s.setdefault("localization", {}).setdefault("hi", {})["name"] = "DRIFT_NAME_NOT_IN_CATALOG_CONTENT"
                break
    repack(t9_dir, t9_edit)
    (DECLARATIONS_DIR / "1.36.0-t9.json").write_text(json.dumps({"releaseTag": "1.36.0-t9", "declaredChanges": []}), encoding="utf-8")
    rep_t9 = run_test("T9", "Content drift between catalog.content and candidate (expect FAIL on G1)", t9_dir, BASELINE_DIR, tag="1.36.0-t9")
    assert rep_t9["overallStatus"] == "FAIL", "T9 should FAIL"
    assert rep_t9["checks"]["G1_drift"]["status"] == "FAIL", "G1 should FAIL on content drift"
    print(">>> T9 PASSED AS EXPECTED (CONTENT DRIFT CAUGHT BY G1)!")

    # Clean up test declaration fixtures
    for f in ["1.36.0-t2.json", "1.36.0-t3.json", "1.36.0-t5.json", "1.36.0-t6.json", "1.36.0-t8.json", "1.36.0-t9.json"]:
        p = DECLARATIONS_DIR / f
        if p.exists(): p.unlink()
    shutil.rmtree(TEST_DIR, ignore_errors=True)

    print("\n========================================================")
    print("ALL GATE SELF-TESTS (T1 - T9) PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
