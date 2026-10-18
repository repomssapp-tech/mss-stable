#!/usr/bin/env python3
"""P7 Step 1(e): Rebuild to a scratch folder and compare the decompressed bundle/pack JSON hashes
(not the .gz bytes, which contain a timestamp) with the published release.
"""

import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRATCH_BUILD = REPO_ROOT / "backend" / ".mss_publish_scratch" / "p7_rebuild_test"
PUBLISHED_DIR = REPO_ROOT / "frontend" / "assets" / "catalog"

def main():
    print("=== Rebuilding release from repo source (backend/catalog/source) ===")
    SCRATCH_BUILD.mkdir(parents=True, exist_ok=True)
    cmd = [
        sys.executable,
        str(REPO_ROOT / "tools" / "build_catalog_release.py"),
        "--source", str(REPO_ROOT / "backend" / "catalog" / "source"),
        "--out-dir", str(SCRATCH_BUILD),
    ]
    res = subprocess.run(cmd, cwd=str(REPO_ROOT), capture_output=True, text=True, encoding="utf-8")
    if res.returncode != 0:
        print("STDOUT:", res.stdout)
        print("STDERR:", res.stderr)
        raise RuntimeError(f"Rebuild failed with code {res.returncode}")
    print(res.stdout)

    print("\n=== Comparing Decompressed JSON Hashes ===")
    targets = [
        "catalog_bundle.json.gz",
        "catalog_pack_hi.json.gz",
        "catalog_pack_ta.json.gz",
    ]

    all_matched = True
    for gz_name in targets:
        scratch_file = SCRATCH_BUILD / gz_name
        pub_file = PUBLISHED_DIR / gz_name

        if not scratch_file.exists():
            print(f"ERROR: {scratch_file} does not exist!")
            all_matched = False
            continue
        if not pub_file.exists():
            print(f"ERROR: {pub_file} does not exist!")
            all_matched = False
            continue

        raw_scratch = gzip.decompress(scratch_file.read_bytes())
        raw_pub = gzip.decompress(pub_file.read_bytes())

        sha_scratch = hashlib.sha256(raw_scratch).hexdigest()
        sha_pub = hashlib.sha256(raw_pub).hexdigest()

        print(f"File: {gz_name}")
        print(f"  Rebuilt decompressed sha256:  {sha_scratch} ({len(raw_scratch):,} bytes)")
        print(f"  Published decompressed sha256:{sha_pub} ({len(raw_pub):,} bytes)")

        if sha_scratch == sha_pub:
            print("  -> EXACT MATCH (Identical decompressed JSON content)")
        else:
            print("  -> MISMATCH!")
            all_matched = False

    # Also compare release.json
    rel_scratch = json.loads((SCRATCH_BUILD / "release.json").read_text(encoding="utf-8"))
    rel_pub = json.loads((PUBLISHED_DIR / "release.json").read_text(encoding="utf-8"))
    
    print("\nFile: release.json")
    print(f"  Rebuilt releaseTag: {rel_scratch.get('releaseTag')}")
    print(f"  Published releaseTag: {rel_pub.get('releaseTag')}")
    if rel_scratch.get("releaseTag") == rel_pub.get("releaseTag") and rel_scratch.get("activeLanguages") == rel_pub.get("activeLanguages"):
        print("  -> EXACT MATCH on tags and activeLanguages")
    else:
        print("  -> MISMATCH on release.json!")
        all_matched = False

    if not all_matched:
        sys.exit(1)
    print("\nALL DECOMPRESSED ARTIFACTS PROVED IDENTICAL TO PUBLISHED RELEASE!")

if __name__ == "__main__":
    main()
