import json
from pathlib import Path
import subprocess
import sys
import time

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

def query_sql(sql: str, retries: int = 3):
    p = Path(__file__).resolve().parent.parent / "backend" / "scratch" / "lang" / "inspect.sql"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(sql + ";", encoding="utf-8")
    cmd = f'npx supabase db query --linked --file "{p}"'
    for attempt in range(retries):
        res = subprocess.run(cmd, cwd=str(Path(__file__).resolve().parent.parent / "backend"), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
        if res.returncode == 0:
            out = res.stdout
            start_idx = out.find("{")
            if start_idx != -1:
                return json.loads(out[start_idx:]).get("rows", [])
        time.sleep(1)
    print("FAILED QUERY AFTER RETRIES:")
    print("RETURNCODE:", res.returncode)
    print("STDERR:", res.stderr)
    print("STDOUT:", res.stdout)
    return []

def main():
    print("=== Verification for Part A ===")
    
    # 1. Alias in catalog.content
    q1 = """
    SELECT 
        (SELECT count(*) FROM catalog.content WHERE lang = 'hi' AND 'पीएम विश्वकर्मा' = ANY(aliases)) AS content_count_with_alias,
        (SELECT count(*) FROM catalog.scheme WHERE record_json #> '{search,aliases,hi}' ? 'पीएम विश्वकर्मा') AS scheme_json_count_with_alias,
        (SELECT count(*) FROM catalog.content WHERE lang = 'hi' AND name !~ '[\u0900-\u097F]') AS no_devanagari_count,
        (SELECT count(*) FROM catalog.content WHERE entity_type = 'institution' AND lang = 'hi') AS institution_hi_count
    """
    rows = query_sql(q1)
    if rows:
        r = rows[0]
        print(f"1. catalog.content hi rows with alias 'पीएम विश्वकर्मा': {r.get('content_count_with_alias')}")
        print(f"   catalog.scheme record_json hi rows with alias 'पीएम विश्वकर्मा': {r.get('scheme_json_count_with_alias')}")
        print(f"2. catalog.content hi rows with NO Devanagari in name: {r.get('no_devanagari_count')}")
        print(f"   catalog.content hi institutions count: {r.get('institution_hi_count')}")

    # Check the one row that DOES have the alias
    q_sch124 = "SELECT entity_id, aliases FROM catalog.content WHERE entity_id = 'SCH000124' AND lang = 'hi'"
    r_sch = query_sql(q_sch124)
    print(f"   SCH000124 in catalog.content: {r_sch}")

    # Check AUTH000126-131
    q_auth = "SELECT entity_id, name FROM catalog.content WHERE entity_type = 'authority' AND entity_id IN ('AUTH000126', 'AUTH000127', 'AUTH000128', 'AUTH000129', 'AUTH000130', 'AUTH000131') AND lang = 'hi' ORDER BY entity_id"
    r_auth = query_sql(q_auth)
    print("\n   AUTH000126-131 in catalog.content:")
    for a in r_auth:
        print(f"     {a['entity_id']}: {a['name']}")

if __name__ == "__main__":
    main()
