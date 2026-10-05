"""Generates the three Phase 1 example record_json objects:
1. ADD_NEW: NEW2026-001 -> SCH000220
2. ADD_CHILD: MSME2526-002 -> SCH000221 (child of SCH000130)
3. ENRICH_EXISTING: SCH000124 enriched from MSME2526-078
"""
from __future__ import annotations

import csv
import gzip
import json
import sys
from pathlib import Path

# Ensure builder and enricher can be imported
sys.path.insert(0, str(Path(__file__).resolve().parent))
from builder import map_v3_1_to_record_json
from enricher import enrich_existing_record

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DATA_DIR = REPO_ROOT / "docs" / "backend" / "mss_scheme_data_v3_1" / "mss_scheme_data_v3_1" / "data"
WORKLIST_DIR = REPO_ROOT / "docs" / "backend" / "mss_scheme_data_v3_1" / "mss_scheme_data_v3_1" / "worklists"
REPORTS_DIR = REPO_ROOT / "reports"
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

# 1. Load source data
with open(DATA_DIR / "new_schemes_2025_26.json", "r", encoding="utf-8") as f:
    v3_data = json.load(f)
v3_schemes = {s["id"]: s for s in v3_data["schemes"]}

# 2. Load open issues
open_issues_map = {}
with open(WORKLIST_DIR / "05_open_issues.csv", "r", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        open_issues_map.setdefault(row["our_id"], []).append(row)

# 3. Load hindi backfill
hindi_backfill = {}
with open(WORKLIST_DIR / "04_hindi_backfill.csv", "r", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        hindi_backfill[row["catalog_id"]] = row

# 4. Load baseline bundle SCH000124
with gzip.open(REPO_ROOT / "frontend" / "assets" / "catalog" / "catalog_bundle.json.gz", "rt", encoding="utf-8") as f:
    bundle = json.load(f)
raw_schemes = bundle["scheme_catalog.json"]["data"]
sch124_baseline = next(s for s in raw_schemes if s.get("identity", {}).get("id") == "SCH000124")

# ─────────────────────────────────────────────────────────────
# Example 1: ADD_NEW (NEW2026-001 -> SCH000220)
# ─────────────────────────────────────────────────────────────
rec_new = map_v3_1_to_record_json(
    v3_rec=v3_schemes["NEW2026-001"],
    allocated_id="SCH000220",
    action="ADD_NEW",
    parent_sch_id=None,
    open_issues=open_issues_map.get("NEW2026-001"),
)
out_new_path = REPORTS_DIR / "example_ADD_NEW_NEW2026-001.json"
with open(out_new_path, "w", encoding="utf-8") as f:
    json.dump(rec_new, f, indent=2, ensure_ascii=False)
print(f"Generated {out_new_path}")

# ─────────────────────────────────────────────────────────────
# Example 2: ADD_CHILD (MSME2526-002 -> SCH000221, child of SCH000130)
# ─────────────────────────────────────────────────────────────
rec_child = map_v3_1_to_record_json(
    v3_rec=v3_schemes["MSME2526-002"],
    allocated_id="SCH000221",
    action="ADD_CHILD",
    parent_sch_id="SCH000130",  # MSME2526-001 PMEGP maps to SCH000130
    open_issues=open_issues_map.get("MSME2526-002"),
)
out_child_path = REPORTS_DIR / "example_ADD_CHILD_MSME2526-002.json"
with open(out_child_path, "w", encoding="utf-8") as f:
    json.dump(rec_child, f, indent=2, ensure_ascii=False)
print(f"Generated {out_child_path}")

# ─────────────────────────────────────────────────────────────
# Example 3: ENRICH_EXISTING (SCH000124 from MSME2526-078)
# ─────────────────────────────────────────────────────────────
rec_enriched, conflicts, diff = enrich_existing_record(
    existing=sch124_baseline,
    v3_rec=v3_schemes["MSME2526-078"],
    hindi_row=hindi_backfill.get("SCH000124"),
    open_issues=open_issues_map.get("MSME2526-078"),
)
out_enriched_path = REPORTS_DIR / "example_ENRICH_EXISTING_SCH000124.json"
with open(out_enriched_path, "w", encoding="utf-8") as f:
    json.dump(rec_enriched, f, indent=2, ensure_ascii=False)
print(f"Generated {out_enriched_path}")

out_diff_path = REPORTS_DIR / "example_ENRICH_EXISTING_diff_SCH000124.json"
with open(out_diff_path, "w", encoding="utf-8") as f:
    json.dump({
        "catalog_id": "SCH000124",
        "enrich_source": "MSME2526-078",
        "diff_summary": diff,
        "conflicts": conflicts,
    }, f, indent=2, ensure_ascii=False)
print(f"Generated {out_diff_path}")
