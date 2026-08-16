import json
import urllib.request
import urllib.error

URL = "https://houpzsxmwemoztpuigmo.supabase.co"
KEY = "sb_publishable_SwlgaGsCt5N-97WwEq7tQw_aNT25VUI"

headers = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Accept": "application/json"
}

def query_url(endpoint):
    req = urllib.request.Request(f"{URL}{endpoint}", headers=headers)
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

print("=== 1. OpenAPI Spec (Exposed Tables) ===")
status, spec = query_url("/rest/v1/")
print(f"Status: {status}")
if status == 200 and isinstance(spec, dict) and "paths" in spec:
    paths = list(spec["paths"].keys())
    print("Exposed paths:")
    for p in paths:
        print(f"  - {p}")
    if "definitions" in spec:
        print("Definitions/Tables:")
        for d in spec["definitions"].keys():
            print(f"  - {d}")
else:
    print(f"Spec response: {spec}")

print("\n=== 2. Testing Specific Known Tables ===")
tables_to_test = [
    "profiles",
    "startup_profiles",
    "schemes",
    "documents",
    "questionnaire_sessions",
    "services",
    "notifications",
    "promo_alerts",
    "saved_schemes",
    "recent_schemes",
    "ai_conversations",
    "ai_messages",
    "catalog_releases",
    "catalog_files",
    "sync_logs",
    "entity_registry",
    "catalog_scheme"
]

for tbl in tables_to_test:
    st, res = query_url(f"/rest/v1/{tbl}?select=*&limit=1")
    print(f"Table '{tbl}': Status {st} -> {res if st != 200 else 'Exists (HTTP 200)'}")

print("\n=== 3. Checking Supabase Storage Buckets ===")
st_storage, res_storage = query_url("/storage/v1/bucket")
print(f"Storage buckets: Status {st_storage} -> {res_storage}")
