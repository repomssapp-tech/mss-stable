import json
import urllib.request
import urllib.error

URL = "https://houpzsxmwemoztpuigmo.supabase.co"
KEY = "sb_publishable_SwlgaGsCt5N-97WwEq7tQw_aNT25VUI"

def query_table(tbl, schema="public"):
    headers = {
        "apikey": KEY,
        "Authorization": f"Bearer {KEY}",
        "Accept": "application/json",
        "Profile": schema,
        "Accept-Profile": schema
    }
    req = urllib.request.Request(f"{URL}/rest/v1/{tbl}?select=*&limit=1", headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            data = resp.read().decode('utf-8')
            return resp.status, json.loads(data)
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        try:
            return e.code, json.loads(body)
        except:
            return e.code, body
    except Exception as e:
        return 0, str(e)

candidate_tables = [
    "profiles",
    "startup_profiles",
    "questionnaire_sessions",
    "notifications",
    "saved_schemes",
    "recent_schemes",
    "ai_conversations",
    "ai_messages",
    "departments",
    "user_roles",
    "search_logs",
    "user_regions",
    "catalog_releases",
    "catalog_files",
    "sync_logs",
    "import_batches",
    "entity_registry",
    "common",
    "authority",
    "institution",
    "scheme",
    "finance",
    "tax",
    "export",
    "csr",
    "treds",
    "search_index"
]

print("=== Probing Public Schema Tables ===")
for tbl in candidate_tables:
    st, res = query_table(tbl, "public")
    if st == 200:
        print(f"[PUBLIC] '{tbl}': EXISTS (200)")
    else:
        hint = res.get('hint', '') if isinstance(res, dict) else ''
        print(f"[PUBLIC] '{tbl}': {st} {hint}")

print("\n=== Probing Catalog Schema Tables ===")
for tbl in ["entity_registry", "scheme", "authority", "institution", "finance", "tax", "export", "csr", "treds", "search_index", "common"]:
    st, res = query_table(tbl, "catalog")
    print(f"[CATALOG] '{tbl}': {st} -> {res if st == 200 else res.get('message', res)}")

print("\n=== Probing Admin Schema Tables ===")
for tbl in ["catalog_releases", "catalog_files", "import_batches", "roles", "admins", "event_log"]:
    st, res = query_table(tbl, "admin")
    print(f"[ADMIN] '{tbl}': {st} -> {res if st == 200 else res.get('message', res)}")

print("\n=== Checking Storage Buckets ===")
headers = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Accept": "application/json"
}
req = urllib.request.Request(f"{URL}/storage/v1/bucket", headers=headers)
try:
    with urllib.request.urlopen(req) as resp:
        buckets = json.loads(resp.read().decode('utf-8'))
        print(f"Storage Buckets (count {len(buckets)}): {buckets}")
except Exception as e:
    print(f"Storage buckets error: {e}")
