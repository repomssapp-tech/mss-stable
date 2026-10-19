import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
BACKEND_DIR = REPO_ROOT / "backend"
PLAN_CATALOG = Path(r"C:\Users\roger\OneDrive\Documents\Plan\catalog")

def run_cmd(cmd, cwd=None):
    res = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8",
        shell=(sys.platform == "win32")
    )
    if res.returncode != 0:
        raise RuntimeError(f"Command failed ({res.returncode}): {' '.join(cmd)}\nstdout: {res.stdout}\nstderr: {res.stderr}")
    return res.stdout

def parse_json_object(cli_output: str) -> dict:
    start = cli_output.index("{")
    end = cli_output.rindex("}")
    return json.loads(cli_output[start : end + 1])

def query_supabase(sql: str) -> list[dict]:
    tmp_sql = BACKEND_DIR / "temp_audit_query.sql"
    tmp_sql.write_text(f"{sql};", encoding="utf-8")
    try:
        out = run_cmd(["npx", "supabase", "db", "query", "--linked", "--file", str(tmp_sql)], cwd=BACKEND_DIR)
        parsed = parse_json_object(out)
        return parsed.get("rows", [])
    finally:
        if tmp_sql.exists():
            tmp_sql.unlink()

def extract_paths(obj, prefix="", depth=1, max_depth=4):
    paths = set()
    if depth > max_depth or not isinstance(obj, dict):
        return paths
    for k, v in obj.items():
        curr = f"{prefix}.{k}" if prefix else k
        paths.add(curr)
        if isinstance(v, dict):
            paths.update(extract_paths(v, curr, depth + 1, max_depth))
    return paths

def main():
    print("=" * 80)
    print("PHASE A: RE-AUDIT VERIFICATION REPORT")
    print("=" * 80)

    # 1. KEY-SHAPE DIFF
    print("\n--- 1. KEY-SHAPE DIFF (depth <= 4) ---")
    
    # A. scheme_catalog.json
    scheme_catalog_file = PLAN_CATALOG / "scheme_catalog.json"
    with open(scheme_catalog_file, "r", encoding="utf-8") as f:
        schemes_data = json.load(f)["data"]
    
    old_schemes = [s for s in schemes_data if int(s["identity"]["id"].replace("SCH", "")) <= 219]
    new_schemes = [s for s in schemes_data if int(s["identity"]["id"].replace("SCH", "")) >= 220]

    old_paths_per_scheme = [extract_paths(s) for s in old_schemes]
    common_old_paths = set.intersection(*old_paths_per_scheme) if old_paths_per_scheme else set()
    any_old_paths = set.union(*old_paths_per_scheme) if old_paths_per_scheme else set()

    new_paths_per_scheme = [extract_paths(s) for s in new_schemes]
    common_new_paths = set.intersection(*new_paths_per_scheme) if new_paths_per_scheme else set()
    any_new_paths = set.union(*new_paths_per_scheme) if new_paths_per_scheme else set()

    missing_in_new = sorted(list(common_old_paths - common_new_paths))
    extra_in_new = sorted(list(any_new_paths - any_old_paths))

    print(f"\n[Scheme Record JSON] (Old schemes: {len(old_schemes)}, New schemes: {len(new_schemes)})")
    print(f"Keys present in ALL 219 old schemes but MISSING in any of the 83 new schemes ({len(missing_in_new)}):")
    for p in missing_in_new:
        missing_count = sum(1 for pset in new_paths_per_scheme if p not in pset)
        print(f"  - {p:45} (missing in {missing_count}/{len(new_schemes)} new schemes)")

    print(f"\nKeys EXTRA in new schemes (never present in ANY of 219 old schemes) ({len(extra_in_new)}):")
    for p in extra_in_new:
        present_count = sum(1 for pset in new_paths_per_scheme if p in pset)
        print(f"  + {p:45} (present in {present_count}/{len(new_schemes)} new schemes)")

    # B. applicability_matrix_catalog.json
    matrix_file = PLAN_CATALOG / "applicability_matrix_catalog.json"
    with open(matrix_file, "r", encoding="utf-8") as f:
        matrix_data = json.load(f)["data"]
    
    old_m = [m for m in matrix_data if int(m["content"]["schemeId"].replace("SCH", "")) <= 219]
    new_m = [m for m in matrix_data if int(m["content"]["schemeId"].replace("SCH", "")) >= 220]

    old_m_paths = [extract_paths(m) for m in old_m]
    new_m_paths = [extract_paths(m) for m in new_m]

    common_old_m = set.intersection(*old_m_paths) if old_m_paths else set()
    any_old_m = set.union(*old_m_paths) if old_m_paths else set()

    common_new_m = set.intersection(*new_m_paths) if new_m_paths else set()
    any_new_m = set.union(*new_m_paths) if new_m_paths else set()

    missing_m = sorted(list(common_old_m - common_new_m))
    extra_m = sorted(list(any_new_m - any_old_m))

    print(f"\n[Applicability Matrix] (Old rows: {len(old_m)}, New rows: {len(new_m)})")
    print(f"Keys present in ALL 219 old matrices but MISSING in new matrices ({len(missing_m)}):")
    for p in missing_m:
        print(f"  - {p}")
    print(f"\nKeys EXTRA in new matrices ({len(extra_m)}):")
    for p in extra_m:
        print(f"  + {p}")

    # C. search_index.json
    search_file = PLAN_CATALOG / "search_index.json"
    with open(search_file, "r", encoding="utf-8") as f:
        search_data = json.load(f)["data"]
    
    scheme_searches = [s for s in search_data if s.get("entityType") == "scheme"]
    old_s = [s for s in scheme_searches if int(s["entityId"].replace("SCH", "")) <= 219]
    new_s = [s for s in scheme_searches if int(s["entityId"].replace("SCH", "")) >= 220]

    old_s_paths = [extract_paths(s) for s in old_s]
    new_s_paths = [extract_paths(s) for s in new_s]

    common_old_s = set.intersection(*old_s_paths) if old_s_paths else set()
    any_old_s = set.union(*old_s_paths) if old_s_paths else set()

    common_new_s = set.intersection(*new_s_paths) if new_s_paths else set()
    any_new_s = set.union(*new_s_paths) if new_s_paths else set()

    missing_s = sorted(list(common_old_s - common_new_s))
    extra_s = sorted(list(any_new_s - any_old_s))

    print(f"\n[Search Index Schemes] (Old scheme rows: {len(old_s)}, New scheme rows: {len(new_s)})")
    print(f"Keys present in ALL 219 old search indexes but MISSING in new ({len(missing_s)}):")
    for p in missing_s:
        print(f"  - {p}")
    print(f"\nKeys EXTRA in new search indexes ({len(extra_s)}):")
    for p in extra_s:
        print(f"  + {p}")

    # 2. RELATIONSHIP SYMMETRY
    print("\n--- 2. RELATIONSHIP SYMMETRY ---")
    sql_sym = """
    SELECT 
        (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'child_of') as total_child_of,
        (SELECT count(*) FROM catalog.relationships WHERE relationship_type = 'parent_of') as total_parent_of,
        (SELECT count(*) FROM catalog.relationships c 
         WHERE c.relationship_type = 'child_of' 
         AND NOT EXISTS (
             SELECT 1 FROM catalog.relationships p 
             WHERE p.relationship_type = 'parent_of' 
             AND p.source_id = c.target_id 
             AND p.target_id = c.source_id
         )) as asymmetric_child_of,
        (SELECT count(*) FROM catalog.relationships p 
         WHERE p.relationship_type = 'parent_of' 
         AND NOT EXISTS (
             SELECT 1 FROM catalog.relationships c 
             WHERE c.relationship_type = 'child_of' 
             AND c.source_id = p.target_id 
             AND c.target_id = p.source_id
         )) as asymmetric_parent_of;
    """
    sym_rows = query_supabase(sql_sym)
    if sym_rows:
        print(f"Live Query Result: {json.dumps(sym_rows[0], indent=2)}")

    sql_asym_details = """
    SELECT c.source_id, c.target_id, s.name_en as child_name, t.name_en as parent_name
    FROM catalog.relationships c 
    JOIN catalog.scheme s ON s.id = c.source_id
    JOIN catalog.scheme t ON t.id = c.target_id
    WHERE c.relationship_type = 'child_of' 
    AND NOT EXISTS (
        SELECT 1 FROM catalog.relationships p 
        WHERE p.relationship_type = 'parent_of' 
        AND p.source_id = c.target_id 
        AND p.target_id = c.source_id
    ) ORDER BY c.source_id;
    """
    asym_details = query_supabase(sql_asym_details)
    print(f"\nAsymmetric child_of rows without matching parent_of ({len(asym_details)} rows):")
    for r in asym_details:
        print(f"  child_of: {r['source_id']} ({r['child_name'][:30]}) -> parent: {r['target_id']} ({r['parent_name'][:30]})")

    # 3. COLUMNS CHECK
    print("\n--- 3. COLUMNS ON NEW SCHEMES (SCH000220 - SCH000302) ---")
    sql_cols = """
    SELECT 
        count(*) as total_new,
        count(*) FILTER (WHERE scheme_type IS NULL) as null_scheme_type,
        count(*) FILTER (WHERE government_level IS NULL) as null_government_level,
        count(*) FILTER (WHERE ministry IS NULL) as null_ministry,
        count(*) FILTER (WHERE department IS NULL) as null_department,
        count(*) FILTER (WHERE name_ta IS NULL) as null_name_ta
    FROM catalog.scheme 
    WHERE id >= 'SCH000220' AND id <= 'SCH000302';
    """
    col_rows = query_supabase(sql_cols)
    if col_rows:
        print(f"Live Query Result: {json.dumps(col_rows[0], indent=2)}")

    # 4. STATUS MATRIX
    print("\n--- 4. STATUS MATRIX (All 302 schemes) ---")
    sql_status = """
    SELECT 
        status, 
        is_active, 
        record_json->'identity'->>'status' as json_identity_status,
        count(*) as count,
        array_agg(id ORDER BY id) as ids
    FROM catalog.scheme 
    GROUP BY status, is_active, record_json->'identity'->>'status'
    ORDER BY count DESC;
    """
    status_rows = query_supabase(sql_status)
    allowed_combos = [
        ('PUBLISHED', True, 'active'),
        ('DRAFT', False, 'unknown'),
        ('ARCHIVED', False, 'closed')
    ]
    outside_combos = []
    if status_rows:
        for r in status_rows:
            is_allowed = (r['status'], r['is_active'], r['json_identity_status']) in allowed_combos
            tag = "[ALLOWED]" if is_allowed else "[OUTSIDE ALLOWED]"
            print(f"  {tag} status={r['status']}, is_active={r['is_active']}, identity.status={r['json_identity_status']}: count={r['count']}")
            if not is_allowed:
                outside_combos.append(r)
                print(f"     -> IDs: {r['ids']}")

    # 5. MIGRATION HISTORY
    print("\n--- 5. MIGRATION HISTORY (Remote vs Local) ---")
    sql_migs = """
    SELECT version, name FROM supabase_migrations.schema_migrations ORDER BY version;
    """
    remote_migs = query_supabase(sql_migs)
    remote_versions = {r['version'] for r in remote_migs}
    print(f"Total migrations recorded remotely in supabase_migrations.schema_migrations: {len(remote_versions)}")
    print(f"Latest remote migration recorded: {sorted(list(remote_versions))[-1] if remote_versions else 'None'}")

    local_mig_files = sorted([f for f in (BACKEND_DIR / "supabase" / "migrations").glob("*.sql")])
    print(f"Total migration files in backend/supabase/migrations/: {len(local_mig_files)}")

    unrecorded = []
    for f in local_mig_files:
        v = f.name.split("_")[0]
        if v not in remote_versions:
            unrecorded.append(f.name)

    print(f"\nLocal migration files NOT recorded in remote schema_migrations ({len(unrecorded)}):")
    for m in unrecorded:
        print(f"  - {m}")

    # 6. GIT HYGIENE
    print("\n--- 6. GIT STATUS & LARGE UNTRACKED FILES ---")
    git_status = run_cmd(["git", "status", "--short"], cwd=REPO_ROOT)
    print("Git status (first 25 lines):")
    for line in git_status.strip().splitlines()[:25]:
        print(f"  {line}")
    if len(git_status.strip().splitlines()) > 25:
        print(f"  ... and {len(git_status.strip().splitlines()) - 25} more files.")

    commits_ahead = run_cmd(["git", "rev-list", "--count", "main..HEAD"], cwd=REPO_ROOT).strip()
    print(f"\nCommits ahead of main (git rev-list --count main..HEAD): {commits_ahead}")

    print("\nUntracked files > 1 MB in working tree:")
    untracked_lines = run_cmd(["git", "ls-files", "--others", "--exclude-standard"], cwd=REPO_ROOT).splitlines()
    for l in untracked_lines:
        p = REPO_ROOT / l
        if p.is_file():
            sz = p.stat().st_size
            if sz > 1_000_000:
                print(f"  {sz:12,d} bytes  {l}")

    # 7. CONSUMERS
    print("\n--- 7. CODE CONSUMERS (Dart, TS, Python) ---")
    patterns = [
        ("content.classification / classification", ["classification['", "classification?['", "content['classification']", "content?['classification']"]),
        ("structured.*.applies / minYears / maxYears", ["'minYears'", "'maxYears'", "'applies'"]),
        ("benefitTypes", ["benefitTypes"]),
        ("targetBeneficiaries", ["targetBeneficiaries"]),
        ("objectives / overview.objective", ["'objectives'", "'objective'"]),
        ("identity.status", ["identity['status']", "identity?['status']", "'identity.status'"]),
    ]

    all_code_files = [REPO_ROOT / p for p in run_cmd(["git", "ls-files", "*.dart", "*.ts", "*.py"], cwd=REPO_ROOT).splitlines()]
    file_contents = {}
    for fpath in all_code_files:
        try:
            file_contents[fpath] = fpath.read_text(encoding="utf-8", errors="replace")
        except Exception:
            pass

    for label, terms in patterns:
        print(f"\n[Consumers of {label}]:")
        found_matches = set()
        for fpath, text in file_contents.items():
            rel = fpath.relative_to(REPO_ROOT)
            for term in terms:
                if term in text:
                    for idx, line in enumerate(text.splitlines(), 1):
                        if term in line and not line.strip().startswith("//") and not line.strip().startswith("#"):
                            found_matches.add((str(rel), idx, line.strip()[:90]))
        for f, lno, snippet in sorted(list(found_matches))[:15]:
            print(f"  {f}:{lno} -> {snippet}")
        if len(found_matches) > 15:
            print(f"  ... and {len(found_matches) - 15} more occurrences.")

    print("\n" + "=" * 80)
    print("END OF PHASE A RE-AUDIT SCRIPT")
    print("=" * 80)

if __name__ == "__main__":
    main()
