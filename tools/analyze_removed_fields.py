#!/usr/bin/env python3
"""Inspect all 39 removed fields between 1.35.1-alpha and 1.36.0-alpha:
- id, field, old text
- translation_jobs row (status, error if any)
- origin of the old value
- code file:line that blanked it
"""

import gzip
import json
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "tools"))
from db_inspect import query

# Load 1.35.1 and 1.36.0 bundles
p_bundle_path = REPO_ROOT / "scratch" / "storage_releases" / "1.35.1-alpha" / "catalog_bundle.json.gz"
c_bundle_path = REPO_ROOT / "scratch" / "storage_releases" / "1.36.0-alpha" / "catalog_bundle.json.gz"

p_bundle = json.loads(gzip.decompress(p_bundle_path.read_bytes()).decode("utf-8"))
c_bundle = json.loads(gzip.decompress(c_bundle_path.read_bytes()).decode("utf-8"))

p_schemes = {s["identity"]["id"]: s for s in p_bundle.get("scheme_catalog.json", {}).get("data", [])}
c_schemes = {s["identity"]["id"]: s for s in c_bundle.get("scheme_catalog.json", {}).get("data", [])}

# Field mapping between camelCase and snake_case
FIELD_MAP = {
    "name": "name",
    "shortName": "short_name",
    "summary": "summary",
    "objective": "objective",
    "description": "description",
    "benefitsText": "benefits_text",
    "eligibilityText": "eligibility_text",
    "applicationText": "application_text",
}

removed_fields = []
for sid in sorted(p_schemes.keys()):
    ps = p_schemes[sid]
    cs = c_schemes.get(sid, {})
    p_hi = ps.get("localization", {}).get("hi", {})
    c_hi = cs.get("localization", {}).get("hi", {})
    for f_camel, f_snake in FIELD_MAP.items():
        pv = p_hi.get(f_camel)
        cv = c_hi.get(f_camel)
        if (pv is not None and pv != "") and (cv is None or cv == ""):
            removed_fields.append({
                "entityId": sid,
                "field_camel": f_camel,
                "field_snake": f_snake,
                "old_text": pv,
            })

print(f"Total removed fields identified: {len(removed_fields)}")

# Query translation_jobs for these entityIds and field_names
entity_ids = sorted(list({r["entityId"] for r in removed_fields}))
ids_sql = "', '".join(entity_ids)
t_jobs = query(f"select entity_id, field_name, status, errors, source_text, translated_text from admin.translation_jobs where entity_type='scheme' and target_lang='hi' and entity_id in ('{ids_sql}');")
t_jobs_map = {(r["entity_id"], r["field_name"]): r for r in t_jobs}

# Query catalog.content currently in DB
c_content = query(f"select entity_id, name, short_name, summary, objective, description, benefits_text, eligibility_text, application_text, origin, engine from catalog.content where entity_type='scheme' and lang='hi' and entity_id in ('{ids_sql}');")
c_content_map = {r["entity_id"]: r for r in c_content}

# Output analysis
print(f"\n{'ID':<10} | {'Field':<16} | {'T_Job Status':<12} | {'Content DB Val':<15} | Old Text Sample")
print("-" * 100)
for r in removed_fields:
    sid = r["entityId"]
    f_camel = r["field_camel"]
    f_snake = r["field_snake"]
    old_text = r["old_text"]
    
    t_job = t_jobs_map.get((sid, f_snake))
    t_status = t_job["status"] if t_job else "NO_JOB_ROW"
    
    cc = c_content_map.get(sid, {})
    cc_val = cc.get(f_snake)
    cc_status = "PRESENT" if (cc_val is not None and cc_val != "") else "NULL/EMPTY"
    
    sample = (old_text[:60] + "...") if len(old_text) > 60 else old_text
    print(f"{sid:<10} | {f_camel:<16} | {t_status:<12} | {cc_status:<15} | {repr(sample)}")

# Save full JSON for inspection
out_file = REPO_ROOT / "scratch" / "removed_39_fields.json"
out_file.write_text(json.dumps({
    "count": len(removed_fields),
    "items": [
        {
            **r,
            "translation_job": t_jobs_map.get((r["entityId"], r["field_snake"])),
            "content_row": c_content_map.get(r["entityId"]),
        }
        for r in removed_fields
    ]
}, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"\nSaved detailed analysis to {out_file}")
