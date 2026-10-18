#!/usr/bin/env python3
"""Cross-examine all 131 draft schemes against 01_new_scheme_actions.csv and database."""

import csv
import json
from pathlib import Path
import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    # 1. Load clean 131 drafts
    with open("draft_schemes_clean.json", "r", encoding="utf-8") as f:
        drafts = json.load(f)

    # 2. Load 01_new_scheme_actions.csv
    actions_path = "docs/backend/mss_scheme_data_v3_1/mss_scheme_data_v3_1/worklists/01_new_scheme_actions.csv"
    action_map = {}
    if Path(actions_path).exists():
        with open(actions_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                cids = row.get("catalog_ids") or ""
                for cid in cids.split(","):
                    cid = cid.strip()
                    if cid.startswith("SCH"):
                        action_map[cid] = row

    # 3. Load batch audit results
    with open("reports/batch_audit/all_131_schemes_audit_raw.json", "r", encoding="utf-8") as f:
        audit_raw = json.load(f)
    audit_map = {a["id"]: a for a in audit_raw}

    print(f"Total drafts: {len(drafts)}")
    print(f"Drafts mapped to new actions: {len(action_map)}")

    draft_breakdown = {
        "old_drafts": [],  # SCH000001 - SCH000219 (70 schemes)
        "new_drafts": []   # SCH000220 - SCH000302 (61 schemes)
    }

    for d in drafts:
        sid = d["id"]
        num = int(sid.replace("SCH", ""))
        audit = audit_map.get(sid, {})
        action = action_map.get(sid, {})
        
        info = {
            "id": sid,
            "code": d.get("scheme_code"),
            "name": d.get("name_en"),
            "ministry": d.get("ministry"),
            "scheme_url": d.get("scheme_url"),
            "http_status": audit.get("primary_result", {}).get("status_code"),
            "page_title": audit.get("primary_result", {}).get("page_title"),
            "provisional": audit.get("provisional_status"),
            "action": action.get("action"),
            "proposed_status": action.get("proposed_record_status")
        }
        
        if num < 220:
            draft_breakdown["old_drafts"].append(info)
        else:
            draft_breakdown["new_drafts"].append(info)

    print(f"Old baseline drafts (SCH000001-219): {len(draft_breakdown['old_drafts'])}")
    print(f"New v3.1 additions drafted (SCH000220-302): {len(draft_breakdown['new_drafts'])}")

    print("\n--- SAMPLE NEW DRAFTS ---")
    for s in draft_breakdown["new_drafts"][:10]:
        print(f"[{s['id']}] {s['name'][:40]} | Action: {s['action']} | Proposed: {s['proposed_status']} | HTTP: {s['http_status']}")

    print("\n--- SAMPLE OLD DRAFTS ---")
    for s in draft_breakdown["old_drafts"][:10]:
        print(f"[{s['id']}] {s['name'][:40]} | HTTP: {s['http_status']} | Title: {s['page_title'][:30] if s['page_title'] else 'N/A'}")

if __name__ == "__main__":
    main()
