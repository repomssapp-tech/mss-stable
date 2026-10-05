import hashlib
import json
import os
import subprocess
import sys

def main():
    print("=" * 80)
    print("LIVE COMPREHENSIVE STATS & EVIDENCE REPORT")
    print("=" * 80)

    # 1. Local Bundle Proof
    bundle_path = os.path.join("frontend", "assets", "catalog", "catalog_bundle.json.gz")
    release_path = os.path.join("frontend", "assets", "catalog", "release.json")
    with open(bundle_path, "rb") as f:
        raw_bundle = f.read()
    bundle_sha = hashlib.sha256(raw_bundle).hexdigest()
    bundle_bytes = len(raw_bundle)

    with open(release_path, "r", encoding="utf-8") as f:
        release_meta = json.load(f)

    print("\n--- 1. OFFLINE BUNDLE INTEGRITY PROOF ---")
    print(f"File Path:                  {bundle_path}")
    print(f"On-Disk Size (bytes):       {bundle_bytes:,}")
    print(f"Computed SHA-256:           {bundle_sha}")
    print(f"release.json releaseTag:    {release_meta.get('releaseTag')}")
    print(f"release.json bundleSha256:  {release_meta.get('bundleSha256')}")
    print(f"release.json bundleBytes:   {release_meta.get('bundleBytes'):,}")
    print(f"release.json entityCount:   {release_meta.get('entityCount')}")
    print(f"release.json searchIndexes: {release_meta.get('searchIndexCount')}")
    sha_match = (bundle_sha == release_meta.get('bundleSha256'))
    bytes_match = (bundle_bytes == release_meta.get('bundleBytes'))
    print(f"SHA-256 Parity Match:       {'PROVEN (EXACT)' if sha_match else 'MISMATCH'}")
    print(f"Byte Size Parity Match:     {'PROVEN (EXACT)' if bytes_match else 'MISMATCH'}")

    # 2. Query Live Supabase State
    print("\n--- 2. LIVE SUPABASE DATABASE PROOF ---")
    sql = """
    SELECT json_build_object(
        'current_release', (SELECT row_to_json(r) FROM (SELECT release_version, package_sha256, package_byte_size, is_current, status, published_at FROM admin.catalog_releases WHERE is_current = true) r),
        'scheme_counts', (SELECT json_build_object(
            'total', count(*),
            'published', count(*) FILTER (WHERE status = 'PUBLISHED'),
            'draft', count(*) FILTER (WHERE status = 'DRAFT'),
            'archived', count(*) FILTER (WHERE status = 'ARCHIVED'),
            'active_flag_true', count(*) FILTER (WHERE is_active = true),
            'active_flag_false', count(*) FILTER (WHERE is_active = false),
            'central', count(*) FILTER (WHERE government_level = 'central'),
            'state', count(*) FILTER (WHERE government_level = 'state'),
            'has_valid_url', count(*) FILTER (WHERE scheme_url LIKE 'http%')
        ) FROM catalog.scheme),
        'applicability_matrix_count', (SELECT count(*) FROM catalog.applicability_matrix),
        'search_index_count', (SELECT count(*) FROM catalog.search_index),
        'relationships_count', (SELECT count(*) FROM catalog.relationships),
        'scheme_source_v3_1_count', (SELECT count(*) FROM catalog.scheme_source_v3_1),
        'staging_schemes_count', (SELECT count(*) FROM catalog.scheme_new_v3_1),
        'staging_matrix_count', (SELECT count(*) FROM catalog.applicability_matrix_new_v3_1),
        'catalog_files_reconciled', (SELECT count(*) FROM admin.catalog_files cf JOIN admin.catalog_releases cr ON cr.id = cf.release_id WHERE cr.is_current = true)
    ) as stats;
    """
    tmp_sql = os.path.join("backend", "temp_stats_query.sql")
    with open(tmp_sql, "w", encoding="utf-8") as f:
        f.write(sql)

    cmd = ["npx", "supabase", "db", "query", "--linked", "--file", "temp_stats_query.sql"]
    res = subprocess.run(cmd, cwd="backend", capture_output=True, text=True, encoding="utf-8", errors="replace", shell=True)
    if os.path.exists(tmp_sql):
        os.remove(tmp_sql)

    if res.returncode != 0:
        print(f"Error querying Supabase: {res.stderr}")
        return

    content = res.stdout
    start = content.find("{")
    if start != -1:
        data = json.loads(content[start:])
        stats = data.get("rows", [{}])[0].get("stats", {})
        cr = stats.get("current_release", {})
        sc = stats.get("scheme_counts", {})
        print(f"Current Live Release Version: {cr.get('release_version')}")
        print(f"Live Release SHA-256:         {cr.get('package_sha256')}")
        print(f"Live Release Bytes:           {cr.get('package_byte_size'):,}")
        print(f"Live Release Is Current:      {cr.get('is_current')}")
        print(f"Live Release Published At:    {cr.get('published_at')}")
        print(f"Catalog Files Reconciled:     {stats.get('catalog_files_reconciled')} files (expected 16)")
        print(f"\nScheme Table Counts (catalog.scheme):")
        print(f"  Total Rows:                 {sc.get('total')} (was 219 pre-migration)")
        print(f"  Status = PUBLISHED:         {sc.get('published')}")
        print(f"  Status = DRAFT:             {sc.get('draft')}")
        print(f"  Status = ARCHIVED:          {sc.get('archived')}")
        print(f"  is_active = True:           {sc.get('active_flag_true')}")
        print(f"  is_active = False:          {sc.get('active_flag_false')}")
        print(f"  Central Level Schemes:      {sc.get('central')}")
        print(f"  State Level Schemes:        {sc.get('state')}")
        print(f"  Valid HTTP(S) Scheme URLs:  {sc.get('has_valid_url')} / {sc.get('total')}")
        print(f"\nOther Core Catalog Tables:")
        print(f"  catalog.applicability_matrix: {stats.get('applicability_matrix_count')} rows")
        print(f"  catalog.search_index:         {stats.get('search_index_count')} rows")
        print(f"  catalog.relationships:        {stats.get('relationships_count')} rows")
        print(f"  catalog.scheme_source_v3_1:   {stats.get('scheme_source_v3_1_count')} rows (raw source archive)")
        print(f"  catalog.scheme_new_v3_1:      {stats.get('staging_schemes_count')} rows (staging copy)")
        print(f"  catalog.applicability_matrix_new_v3_1: {stats.get('staging_matrix_count')} rows (staging copy)")

    # 3. Reports Verification
    print("\n--- 3. REPORTS & ARTIFACTS ON DISK ---")
    reports = [
        ("Phase 0 Audit", "reports/phase0_audit_report.json"),
        ("Phase 1 Mapping Spec", "docs/catalog_v3_1_mapping.md"),
        ("Phase 2 Status Corrections", "reports/phase2_status_corrections_report.json"),
        ("Phase 3 Enrichment Conflicts", "reports/enrich_conflicts.csv"),
        ("Phase 3 Enrichment Summary", "reports/phase3_enrichment_report.json"),
        ("Phase 4 ID Allocation Map", "reports/id_map.csv"),
        ("Phase 5 Staging Test Report", "reports/phase5_staging_test_report.json"),
    ]
    for name, path in reports:
        exists = os.path.exists(path)
        sz = os.path.getsize(path) if exists else 0
        print(f"  {name:30} : {'EXISTS' if exists else 'MISSING'} ({sz:,} bytes) -> {path}")

    # 4. Migrations On Disk
    print("\n--- 4. MIGRATION SQL FILES PRODUCED ---")
    migrations = [
        "backend/supabase/migrations/20261004185000_catalog_v3_1_status_corrections.sql",
        "backend/supabase/migrations/20261004192000_catalog_v3_1_enrich_existing.sql",
        "backend/supabase/migrations/20261004193500_catalog_v3_1_add_schemes.sql",
        "backend/supabase/migrations/20261004200000_catalog_v3_1_staging_and_source.sql",
        "backend/supabase/migrations/20261004201500_catalog_v3_1_rewire_to_production.sql",
    ]
    for m in migrations:
        exists = os.path.exists(m)
        sz = os.path.getsize(m) if exists else 0
        print(f"  {os.path.basename(m):50} : {'EXISTS' if exists else 'MISSING'} ({sz:,} bytes)")

    print("\n" + "=" * 80)

if __name__ == "__main__":
    main()
