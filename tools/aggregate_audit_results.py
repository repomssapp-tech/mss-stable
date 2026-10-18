#!/usr/bin/env python3
"""Aggregates batch audit results and analyzes closures, failures, and active schemes."""

import json
from pathlib import Path
import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    audit_dir = Path("reports/batch_audit")
    all_schemes = []
    for i in range(1, 7):
        p = audit_dir / f"batch_{i}_results.json"
        if p.exists():
            with open(p, "r", encoding="utf-8") as f:
                all_schemes.extend(json.load(f))

    print(f"Total schemes aggregated: {len(all_schemes)}")

    # Sort by ID
    all_schemes.sort(key=lambda s: s["id"])

    # Save consolidated
    full_path = audit_dir / "all_131_schemes_audit_raw.json"
    with open(full_path, "w", encoding="utf-8") as f:
        json.dump(all_schemes, f, indent=2, ensure_ascii=False)

    active_schemes = [s for s in all_schemes if s["provisional_status"] == "active"]
    closed_schemes = [s for s in all_schemes if s["provisional_status"] == "closed"]
    search_schemes = [s for s in all_schemes if s["provisional_status"] == "requires_agent_search"]

    print(f"Active count: {len(active_schemes)}")
    print(f"Closed count: {len(closed_schemes)}")
    print(f"Requires Agent Search: {len(search_schemes)}")

    print("\n" + "="*80)
    print("CLOSED SCHEMES CANDIDATES:")
    print("="*80)
    for s in closed_schemes:
        print(f"[{s['id']}] {s['scheme_code']} - {s['name_en']}")
        print(f"   URL: {s['primary_url']}")
        print(f"   Signals: {s['primary_result'].get('closure_signals')}")
        print(f"   Evidence: {s['evidence_note']}")
        print()

    print("="*80)
    print("REQUIRES AGENT SEARCH (Failed endpoints):")
    print("="*80)
    for s in search_schemes:
        print(f"[{s['id']}] {s['scheme_code']} - {s['name_en']}")
        print(f"   URL: {s['primary_url']}")
        print(f"   Error: {s['primary_result'].get('status_code')} - {s['primary_result'].get('error')}")
        print()

if __name__ == "__main__":
    main()
