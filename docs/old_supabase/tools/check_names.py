import json
from pathlib import Path
import subprocess
import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sql = """
select entity_id, lang, name, short_name from catalog.content where entity_id in ('SCH000271', 'SCH000280') order by entity_id, lang;
"""
p = Path(__file__).resolve().parent.parent / 'backend' / 'scratch' / 'lang' / 'test_name.sql'
p.write_text(sql, encoding='utf-8')
cmd = f'npx supabase db query --linked --file "{p}"'
res = subprocess.run(cmd, cwd='backend', shell=True, capture_output=True, text=True, encoding='utf-8')
print(res.stdout)
