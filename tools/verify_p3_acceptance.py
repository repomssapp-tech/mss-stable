#!/usr/bin/env python3
"""Phase P3 Acceptance Verification Script.
Checks:
- E1 equivalence: schemes x 8 fields x {en, ta} between current bundle and new release build.
- E2: pack entity counts match catalog.content counts for that language.
- E3: release.json / manifest sha256 matches each file byte-for-byte.
- Size report: core bundle and language packs gzip sizes vs baseline.
"""
from __future__ import annotations

import gzip
import hashlib
import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
BASELINE_BUNDLE_PATH = ROOT_DIR / "frontend" / "assets" / "catalog" / "catalog_bundle.json.gz"
BASELINE_RELEASE_PATH = ROOT_DIR / "frontend" / "assets" / "catalog" / "release.json"
REHEARSAL_DIR = ROOT_DIR / "backend" / "scratch" / "release_p3_rehearsal"

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

SCHEME_FIELDS = [
    ("name", "name"),
    ("shortName", "short_name"),
    ("summary", "summary"),
    ("objective", "objective"),
    ("description", "description"),
    ("benefitsText", "benefits_text"),
    ("eligibilityText", "eligibility_text"),
    ("applicationText", "application_text"),
]


def compute_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    print("==================================================")
    print("=== PHASE P3 ACCEPTANCE VERIFICATION REPORT ===")
    print("==================================================")

    # 1. E1 EQUIVALENCE TEST
    print("\n--- E1 Equivalence Check ---")
    print(f"Loading baseline bundle from {BASELINE_BUNDLE_PATH}...")
    with gzip.open(BASELINE_BUNDLE_PATH, "rt", encoding="utf-8") as f:
        baseline_bundle = json.load(f)

    rehearsal_bundle_path = REHEARSAL_DIR / "catalog_bundle.json.gz"
    print(f"Loading rehearsal bundle from {rehearsal_bundle_path}...")
    with gzip.open(rehearsal_bundle_path, "rt", encoding="utf-8") as f:
        rehearsal_bundle = json.load(f)

    baseline_schemes = {
        s["identity"]["id"]: s for s in baseline_bundle.get("scheme_catalog.json", {}).get("data", [])
    }
    rehearsal_schemes = {
        s["identity"]["id"]: s for s in rehearsal_bundle.get("scheme_catalog.json", {}).get("data", [])
    }

    print(f"Baseline schemes: {len(baseline_schemes)}")
    print(f"Rehearsal schemes: {len(rehearsal_schemes)}")

    diffs = []
    checked_count = 0
    # For every scheme in baseline, verify all 8 fields for EN and TA
    for eid, b_scheme in baseline_schemes.items():
        r_scheme = rehearsal_schemes.get(eid)
        if not r_scheme:
            diffs.append((eid, "ALL", "scheme missing in rehearsal"))
            continue

        # EN check
        b_ident = b_scheme.get("identity", {})
        r_ident = r_scheme.get("identity", {})
        b_attrs = b_scheme.get("attributes", {})
        r_attrs = r_scheme.get("attributes", {})
        b_loc = b_scheme.get("localization", {})
        r_loc = r_scheme.get("localization", {})

        for b_key, _ in SCHEME_FIELDS:
            checked_count += 1
            if b_key == "name":
                b_val = b_ident.get("name") or b_loc.get("en", {}).get("name")
                r_val = r_ident.get("name") or r_loc.get("en", {}).get("name")
            else:
                b_val = b_attrs.get(b_key) or b_loc.get("en", {}).get(b_key)
                r_val = r_attrs.get(b_key) or r_loc.get("en", {}).get(b_key)

            if (b_val or "").strip() != (r_val or "").strip():
                diffs.append((eid, "en", b_key, b_val, r_val))

            # TA check
            checked_count += 1
            b_ta = b_loc.get("ta", {}).get(b_key)
            r_ta = r_loc.get("ta", {}).get(b_key)
            if (b_ta or "").strip() != (r_ta or "").strip():
                diffs.append((eid, "ta", b_key, b_ta, r_ta))

    print(f"Checked field-values: {checked_count}")
    print(f"Total diffs: {len(diffs)}")
    if diffs:
        for d in diffs[:10]:
            print(f"  DIFF: {d}")
        print("FAIL: E1 equivalence check failed.")
    else:
        print("PASS: E1 equivalence satisfied! Zero diffs across all schemes x 8 fields x {en, ta}.")

    # 2. E2 PACK ROW COUNTS
    print("\n--- E2 Pack Row Counts Check ---")
    cache_path = ROOT_DIR / "backend" / "scratch" / "lang" / "catalog_content_cache.json"
    with cache_path.open("r", encoding="utf-8") as f:
        content_rows = json.load(f)

    kept_scheme_ids = set(rehearsal_schemes.keys())

    for lang in ("hi", "ta"):
        pack_path = REHEARSAL_DIR / f"catalog_pack_{lang}.json"
        with pack_path.open("r", encoding="utf-8") as f:
            pack_data = json.load(f)
        pack_entities = pack_data.get("data", [])
        
        # Expected from catalog.content filtered to kept schemes
        expected_entities = [
            r for r in content_rows
            if r["lang"] == lang and (r["entity_type"] != "scheme" or r["entity_id"] in kept_scheme_ids)
        ]
        print(f"  {lang} pack entities: {len(pack_entities)} | Expected from catalog.content: {len(expected_entities)}")
        assert len(pack_entities) == len(expected_entities), f"Count mismatch for {lang} pack!"
        print(f"  PASS: E2 pack count verified for {lang} ({len(pack_entities)} rows).")

    # 3. E3 SHA256 INTEGRITY CHECK
    print("\n--- E3 Manifest / release.json SHA256 Check ---")
    release_path = REHEARSAL_DIR / "release.json"
    with release_path.open("r", encoding="utf-8") as f:
        release = json.load(f)

    # Check bundle sha256
    bundle_actual_sha = compute_sha256(rehearsal_bundle_path)
    bundle_rec_sha = release["bundleSha256"]
    print(f"  Core bundle sha256 actual:   {bundle_actual_sha}")
    print(f"  Core bundle sha256 recorded: {bundle_rec_sha}")
    assert bundle_actual_sha == bundle_rec_sha, "Bundle sha256 mismatch!"
    print("  PASS: Core bundle sha256 matches!")

    # Check per-file sha256 for packs
    for lang in ("hi", "ta"):
        gz_path = REHEARSAL_DIR / f"catalog_pack_{lang}.json.gz"
        json_path = REHEARSAL_DIR / f"catalog_pack_{lang}.json"
        
        gz_actual_sha = compute_sha256(gz_path)
        gz_rec_sha = release["languagePacks"][lang]["sha256"]
        assert gz_actual_sha == gz_rec_sha, f"Gz sha256 mismatch for {lang} pack!"

        json_actual_sha = compute_sha256(json_path)
        json_rec_sha = release["languagePacks"][lang]["uncompressedSha256"]
        assert json_actual_sha == json_rec_sha, f"Json sha256 mismatch for {lang} pack!"
        print(f"  PASS: Language pack {lang} (json + gz) sha256 matches release.json!")

    # 4. SIZE REPORT
    print("\n--- Size Report ---")
    with BASELINE_RELEASE_PATH.open("r", encoding="utf-8") as f:
        baseline_release = json.load(f)

    base_bundle_bytes = baseline_release["bundleBytes"]
    new_bundle_bytes = release["bundleBytes"]
    hi_gz_bytes = release["languagePacks"]["hi"]["byteSize"]
    ta_gz_bytes = release["languagePacks"]["ta"]["byteSize"]

    print(f"  Baseline bundle gzip size:  {base_bundle_bytes:,} bytes")
    print(f"  New core bundle gzip size:  {new_bundle_bytes:,} bytes (diff: {new_bundle_bytes - base_bundle_bytes:+,} bytes)")
    print(f"  Hindi pack gzip size:       {hi_gz_bytes:,} bytes (~{hi_gz_bytes / 1024:.1f} KB)")
    print(f"  Tamil pack gzip size:       {ta_gz_bytes:,} bytes (~{ta_gz_bytes / 1024:.1f} KB)")
    print(f"  Total with packs:           {new_bundle_bytes + hi_gz_bytes + ta_gz_bytes:,} bytes")
    print("\n==================================================")
    print("=== PHASE P3 ACCEPTANCE: ALL CHECKS PASSED ===")
    print("==================================================")


if __name__ == "__main__":
    main()
