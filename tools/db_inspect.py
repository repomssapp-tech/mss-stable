import json
from pathlib import Path
import subprocess
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

def query(sql: str):
    p = Path(__file__).resolve().parent.parent / "backend" / "scratch" / "lang" / "inspect.sql"
    p.write_text(sql + ";", encoding="utf-8")
    cmd = f'npx supabase db query --linked --file "{p}"'
    res = subprocess.run(cmd, cwd=str(Path(__file__).resolve().parent.parent / "backend"), shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if res.returncode != 0:
        print("RETURNCODE:", res.returncode)
        print("STDERR:", res.stderr)
        print("STDOUT:", res.stdout)
        return []
    out = res.stdout
    start_idx = out.find("{")
    if start_idx == -1:
        return []
    return json.loads(out[start_idx:]).get("rows", [])

if __name__ == "__main__":
    sql = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "select column_name, data_type, is_nullable from information_schema.columns where table_schema = 'admin' and table_name = 'catalog_files' order by ordinal_position;"
    rows = query(sql)
    for r in rows:
        print(r)
