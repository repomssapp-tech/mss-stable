#!/usr/bin/env python3
"""Detailed analysis of draft schemes to identify active vs closed status."""

import json
from pathlib import Path
import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    with open("draft_schemes_clean.json", "r", encoding="utf-8") as f:
        schemes = json.load(f)

    with open("reports/batch_audit/all_131_schemes_audit_raw.json", "r", encoding="utf-8") as f:
        audit_raw = json.load(f)

    audit_map = {a["id"]: a for a in audit_raw}

    results = []
    for s in schemes:
        sid = s["id"]
        audit = audit_map.get(sid, {})
        name = s.get("name_en") or ""
        code = s.get("scheme_code") or ""
        ministry = s.get("ministry") or ""
        url = s.get("scheme_url") or ""
        
        results.append({
            "id": sid,
            "code": code,
            "name": name,
            "ministry": ministry,
            "url": url,
            "http_status": audit.get("primary_result", {}).get("status_code"),
            "page_title": audit.get("primary_result", {}).get("page_title"),
            "reachable": audit.get("primary_result", {}).get("reachable", False),
            "provisional": audit.get("provisional_status"),
            "evidence": audit.get("evidence_note")
        })

    # Print summary table
    print(f"Total schemes analyzed: {len(results)}")
    
    # Categorization
    unreachable = [r for r in results if not r["reachable"]]
    print(f"\nUnreachable count ({len(unreachable)}):")
    for u in unreachable:
        print(f"  {u['id']} | {u['code']} | {u['name'][:40]} | HTTP {u['http_status']} | {u['url'][:50]}")

if __name__ == "__main__":
    main()
