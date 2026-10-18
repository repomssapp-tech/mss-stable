#!/usr/bin/env python3
"""Sync audited statuses and URLs into Plan/catalog/scheme_catalog.json."""

import json
from pathlib import Path
import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    REPO_ROOT = Path(__file__).resolve().parent.parent
    plan_path = REPO_ROOT / "backend" / "catalog" / "source" / "scheme_catalog.json"
    if not plan_path.exists():
        print(f"Error: {plan_path} does not exist!")
        sys.exit(1)

    with open("reports/batch_audit/verified_schemes_final.json", "r", encoding="utf-8") as f:
        verified_list = json.load(f)

    verified_map = {v["id"]: v for v in verified_list}

    with open(plan_path, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    schemes = catalog.get("data", [])
    updated_count = 0

    for s in schemes:
        sid = s.get("identity", {}).get("id")
        if sid in verified_map:
            v = verified_map[sid]
            new_status = v["new_status"]  # "active" or "closed"
            v_url = v["verified_url"]

            # 1. Update identity
            s["identity"]["status"] = new_status
            s["identity"]["is_active"] = (new_status == "active")

            # 2. Update content
            if "content" not in s:
                s["content"] = {}
            s["content"]["scheme_url"] = v_url

            # 3. Update verification
            if "verification" not in s:
                s["verification"] = {}
            s["verification"]["auditStatus"] = "web_agent_verified_2026_10"
            s["verification"]["auditEvidence"] = v["evidence"]

            updated_count += 1

    # Check status distribution
    statuses = {}
    for s in schemes:
        st = s.get("identity", {}).get("status")
        statuses[st] = statuses.get(st, 0) + 1

    print(f"Successfully updated {updated_count} schemes in {plan_path.name}")
    print(f"New status distribution: {statuses}")

    # Write back to Plan
    with open(plan_path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    print("Saved updated Plan/catalog/scheme_catalog.json")

if __name__ == "__main__":
    main()
