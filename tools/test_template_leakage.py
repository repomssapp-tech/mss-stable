#!/usr/bin/env python3
"""Template-leakage test (P7 item 5):
For records generated from a skeleton (SCH000124), verify that no new record holds
a non-empty skeleton value it should not have (the 'PM Vishwakarma alias on 84 schemes' bug class).
"""

import json
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_SCHEMES = REPO_ROOT / "backend" / "catalog" / "source" / "scheme_catalog.json"

def test_template_leakage():
    print("=== Running Template-Leakage Test (P7 Item 5) ===")
    if not SOURCE_SCHEMES.exists():
        raise RuntimeError(f"File not found: {SOURCE_SCHEMES}")

    data = json.loads(SOURCE_SCHEMES.read_text(encoding="utf-8"))
    schemes = data.get("data", [])
    print(f"Loaded {len(schemes)} schemes from source master.")

    leaks = []
    for s in schemes:
        sid = s.get("identity", {}).get("id")
        if sid == "SCH000124":
            continue

        aliases = s.get("search", {}).get("aliases", {})
        hi_aliases = aliases.get("hi", [])
        if "पीएम विश्वकर्मा" in hi_aliases:
            leaks.append(f"{sid}: found 'पीएम विश्वकर्मा' in search.aliases.hi")

        ta_aliases = aliases.get("ta", [])
        if "பிஎம் விஸ்வகர்மா" in ta_aliases:
            leaks.append(f"{sid}: found 'பிஎம் விஸ்வகர்மா' in search.aliases.ta")

        # Check name leakage
        hi_name = s.get("localization", {}).get("hi", {}).get("name") or ""
        if "विश्वकर्मा" in hi_name and "vishwakarma" not in s.get("identity", {}).get("name", "").lower():
            leaks.append(f"{sid}: unexpected 'विश्वकर्मा' in hi.name")

    if leaks:
        print(f"FAILED: Found {len(leaks)} template leakage instance(s):")
        for l in leaks[:10]:
            print(f"  - {l}")
        sys.exit(1)
    else:
        print("PASS: 0 template leakage instances found across all scheme records.")

if __name__ == "__main__":
    test_template_leakage()
