"""
Syncs Supabase Database Catalog to Plan/catalog JSON Files
and regenerates the frontend/assets/catalog/ offline bundle for release 1.35.0-alpha.
"""

from collections import OrderedDict
from datetime import datetime, timezone
import hashlib
import json
import os
import subprocess
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

PLAN_DIR = r"C:\Users\roger\OneDrive\Documents\Plan\catalog"
FRONTEND_ASSET_DIR = os.path.join("frontend", "assets", "catalog")
RELEASE_VERSION = "1.35.0-alpha"

def run_query_to_file(sql, out_json_path):
    tmp_sql = os.path.join("backend", "temp_sync_query.sql")
    with open(tmp_sql, "w", encoding="utf-8") as f:
        f.write(sql)
    
    cmd = ["npx", "supabase", "db", "query", "--linked", "--file", "temp_sync_query.sql"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    with open(out_json_path, "w", encoding="utf-8") as out_f:
        res = subprocess.run(cmd, cwd="backend", stdout=out_f, stderr=subprocess.PIPE, text=True, encoding="utf-8", errors="replace", env=env, shell=True)
    
    if os.path.exists(tmp_sql):
        os.remove(tmp_sql)
    return res.returncode

def extract_rows(out_json_path):
    with open(out_json_path, "r", encoding="utf-8") as f:
        content = f.read()
    start = content.find("{")
    if start == -1:
        raise ValueError("No JSON object found in output")
    data = json.loads(content[start:])
    return data.get("rows", [])

def main():
    print(f"==========================================================================")
    print(f"SYNCING DATABASE -> PLAN/CATALOG -> OFFLINE BUNDLE ({RELEASE_VERSION})")
    print(f"==========================================================================\n")

    os.makedirs("backend", exist_ok=True)
    temp_dump = os.path.join("backend", "temp_dump.json")

    # 1. Scheme Catalog
    print("1. Exporting catalog.scheme from database...")
    sql_scheme = "SELECT json_agg(record_json ORDER BY id) as records FROM catalog.scheme;"
    rc = run_query_to_file(sql_scheme, temp_dump)
    if rc != 0:
        print("ERROR querying catalog.scheme")
        sys.exit(1)
    schemes = extract_rows(temp_dump)[0]["records"]
    print(f"   Fetched {len(schemes)} schemes from database.")

    scheme_cat_path = os.path.join(PLAN_DIR, "scheme_catalog.json")
    with open(scheme_cat_path, "r", encoding="utf-8") as f:
        scheme_cat = json.load(f)
    
    scheme_cat["metadata"]["catalogVersion"] = RELEASE_VERSION
    scheme_cat["metadata"]["recordCount"] = len(schemes)
    scheme_cat["metadata"]["generatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    scheme_cat["data"] = schemes
    with open(scheme_cat_path, "w", encoding="utf-8") as f:
        json.dump(scheme_cat, f, indent=2, ensure_ascii=False)
    print(f"   Updated {scheme_cat_path} with {len(schemes)} records.")

    # 2. Applicability Matrix Catalog
    print("\n2. Exporting catalog.applicability_matrix from database...")
    sql_matrix = "SELECT json_agg(record_json ORDER BY id) as records FROM catalog.applicability_matrix;"
    rc = run_query_to_file(sql_matrix, temp_dump)
    if rc != 0:
        print("ERROR querying catalog.applicability_matrix")
        sys.exit(1)
    matrices = extract_rows(temp_dump)[0]["records"]
    print(f"   Fetched {len(matrices)} applicability matrix rows from database.")

    matrix_cat_path = os.path.join(PLAN_DIR, "applicability_matrix_catalog.json")
    with open(matrix_cat_path, "r", encoding="utf-8") as f:
        matrix_cat = json.load(f)
    
    matrix_cat["metadata"]["catalogVersion"] = RELEASE_VERSION
    matrix_cat["metadata"]["recordCount"] = len(matrices)
    matrix_cat["metadata"]["generatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    matrix_cat["data"] = matrices
    with open(matrix_cat_path, "w", encoding="utf-8") as f:
        json.dump(matrix_cat, f, indent=2, ensure_ascii=False)
    print(f"   Updated {matrix_cat_path} with {len(matrices)} records.")

    # 3. Search Index
    print("\n3. Exporting catalog.search_index from database...")
    sql_search = "SELECT json_agg(record_json ORDER BY id) as records FROM catalog.search_index;"
    rc = run_query_to_file(sql_search, temp_dump)
    if rc != 0:
        print("ERROR querying catalog.search_index")
        sys.exit(1)
    search_records = extract_rows(temp_dump)[0]["records"]
    print(f"   Fetched {len(search_records)} search_index records from database.")

    search_cat_path = os.path.join(PLAN_DIR, "search_index.json")
    with open(search_cat_path, "r", encoding="utf-8") as f:
        search_cat = json.load(f)
    
    search_cat["metadata"]["catalogVersion"] = RELEASE_VERSION
    search_cat["metadata"]["recordCount"] = len(search_records)
    search_cat["metadata"]["generatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    search_cat["data"] = search_records
    with open(search_cat_path, "w", encoding="utf-8") as f:
        json.dump(search_cat, f, indent=2, ensure_ascii=False)
    print(f"   Updated {search_cat_path} with {len(search_records)} records.")

    if os.path.exists(temp_dump):
        os.remove(temp_dump)

    # 4. Manifest Update
    print("\n4. Updating Plan/catalog/manifest.json...")
    manifest_path = os.path.join(PLAN_DIR, "manifest.json")
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    manifest["data"][0]["catalogRelease"] = RELEASE_VERSION
    manifest["data"][0]["releasedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    manifest["data"][0]["compatibility"]["supersedes"] = "1.34.3-alpha"
    
    # Update file entry counts
    for file_entry in manifest["data"][0]["files"]:
        fname = file_entry["fileName"]
        fpath = os.path.join(PLAN_DIR, fname)
        if os.path.exists(fpath):
            file_entry["byteSize"] = os.path.getsize(fpath)
            if fname == "scheme_catalog.json":
                file_entry["recordCount"] = len(schemes)
            elif fname == "applicability_matrix_catalog.json":
                file_entry["recordCount"] = len(matrices)
            elif fname == "search_index.json":
                file_entry["recordCount"] = len(search_records)

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"   Updated manifest.json -> {RELEASE_VERSION}.")

    # 5. Build Offline Bundle
    print("\n5. Generating Offline Bundle via tools/generate_catalog_bundle.py...")
    cmd_bundle = [
        sys.executable,
        os.path.join("tools", "generate_catalog_bundle.py"),
        "--source", PLAN_DIR,
        "--out-dir", FRONTEND_ASSET_DIR
    ]
    res_b = subprocess.run(cmd_bundle, capture_output=True, text=True, encoding="utf-8")
    print(res_b.stdout)
    if res_b.returncode != 0:
        print("ERROR running generate_catalog_bundle.py:")
        print(res_b.stderr)
        sys.exit(1)

    # 6. Verify release.json
    release_path = os.path.join(FRONTEND_ASSET_DIR, "release.json")
    with open(release_path, "r", encoding="utf-8") as f:
        rel = json.load(f)

    print("\n6. Verifying Bundle Manifest (frontend/assets/catalog/release.json)...")
    print(f"   releaseTag: {rel.get('releaseTag')}")
    print(f"   entityCount: {rel.get('entityCount')}")
    print(f"   searchIndexCount: {rel.get('searchIndexCount')}")
    print(f"   bundleBytes: {rel.get('bundleBytes'):,} bytes")
    print(f"   bundleSha256: {rel.get('bundleSha256')}")

    # Checks
    assert rel.get("releaseTag") == RELEASE_VERSION, f"Expected {RELEASE_VERSION}"
    assert rel.get("searchIndexCount") == len(search_records), f"searchIndexCount mismatch"
    assert rel.get("recordCounts", {}).get("scheme_catalog.json") == 302, "scheme count mismatch"
    assert rel.get("recordCounts", {}).get("applicability_matrix_catalog.json") == 302, "matrix count mismatch"
    assert rel.get("entityCount") == 1386, f"Expected entityCount 1386, got {rel.get('entityCount')}"

    print("\nALL OFFLINE BUNDLE INTEGRITY CHECKS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
