"""
Fix Applicability Matrix record_json structure for APLM000220 - APLM000302:
Sets canonical identity (id: APLM..., entityType: applicability_matrix)
and content (schemeId: SCH...) matching the MssEntity contract.
"""

import json
import os
import re
import subprocess
import sys

def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return text.strip("-")

def run_query(sql):
    tmp_path = os.path.join("backend", "temp_am_fix.sql")
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(sql)
    cmd = ["npx", "supabase", "db", "query", "--linked", "--file", "temp_am_fix.sql"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    res = subprocess.run(cmd, cwd="backend", capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, shell=True)
    if os.path.exists(tmp_path):
        os.remove(tmp_path)
    return res.stdout, res.stderr, res.returncode

def parse_rows(stdout):
    idx = stdout.find("{")
    if idx != -1:
        data = json.loads(stdout[idx:])
        return data.get("rows", [])
    return []

def main():
    print("Fetching new applicability matrix rows from database...")
    fetch_sql = """
SELECT am.id, am.scheme_id, s.name_en, am.status, am.department_authority_id, am.record_json
FROM catalog.applicability_matrix am
JOIN catalog.scheme s ON s.id = am.scheme_id
WHERE am.scheme_id >= 'SCH000220' AND am.scheme_id <= 'SCH000302'
ORDER BY am.scheme_id;
"""
    out, err, rc = run_query(fetch_sql)
    if rc != 0:
        print("Error fetching matrix rows:", err)
        sys.exit(1)
    
    rows = parse_rows(out)
    print(f"Found {len(rows)} matrix rows to format.")

    updates = []
    updates_staged = []

    for r in rows:
        aplm_id = r["id"]
        scheme_id = r["scheme_id"]
        name_en = r["name_en"]
        status = r["status"]
        min_id = r.get("department_authority_id")
        old_rj = r.get("record_json") or {}

        targeting = old_rj.get("targeting") or {}
        eligibility = old_rj.get("eligibility") or {}

        new_rj = {
            "identity": {
                "id": aplm_id,
                "entityType": "applicability_matrix",
                "code": scheme_id,
                "language": "en",
                "name": f"Applicability Matrix — {name_en}",
                "slug": f"applicability-{slugify(name_en)}",
                "status": "active" if status == "PUBLISHED" else "draft",
            },
            "content": {
                "schemeId": scheme_id,
                "governmentLevel": "central",
                "agency": [min_id] if min_id else [],
                "department": min_id,
                "targeting": targeting,
                "eligibility": eligibility,
            },
            "relationships": {
                "references": [
                    {
                        "relationship": "applies_to",
                        "targetCatalog": "scheme",
                        "targetId": scheme_id,
                        "type": "parent"
                    }
                ]
            },
            "localization": {"en": {}},
            "metadata": {
                "catalogVersion": "1.35.0-alpha",
                "recordStatus": "published" if status == "PUBLISHED" else "draft",
                "schemaVersion": "1.0.0"
            }
        }

        rj_str = json.dumps(new_rj, ensure_ascii=False).replace("'", "''")
        updates.append(f"UPDATE catalog.applicability_matrix SET record_json = '{rj_str}'::jsonb WHERE id = '{aplm_id}';")
        updates_staged.append(f"UPDATE catalog.applicability_matrix_new_v3_1 SET record_json = '{rj_str}'::jsonb WHERE id = '{aplm_id}';")

    batch_sql = "BEGIN;\n" + "\n".join(updates) + "\n" + "\n".join(updates_staged) + "\nCOMMIT;"
    print("Executing updates on linked database...")
    u_out, u_err, u_rc = run_query(batch_sql)
    if u_rc != 0:
        print("Error updating matrix rows:", u_err)
        sys.exit(1)
    print("Applicability matrix record_json successfully updated in DB.")

if __name__ == "__main__":
    main()
