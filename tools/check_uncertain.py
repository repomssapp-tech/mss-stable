#!/usr/bin/env python3
import csv
import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def main():
    issues_path = "docs/backend/mss_scheme_data_v3_1/mss_scheme_data_v3_1/worklists/05_open_issues.csv"
    with open(issues_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            if "status" in r["issue_type"] or "close" in r["issue_type"] or "dup" in r["issue_type"]:
                print(f"[{r['our_id']}] {r['name_en'][:40]} | {r['issue_type']}")
                print(f"   Detail: {r['detail']}")
                print()

if __name__ == "__main__":
    main()
