#!/usr/bin/env python3
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
plan_manifest = REPO_ROOT / "backend" / "catalog" / "source" / "manifest.json"
if plan_manifest.exists():
    data = json.loads(plan_manifest.read_text(encoding="utf-8"))
    data["metadata"]["catalogVersion"] = "1.36.0-alpha"
    data["data"][0]["catalogRelease"] = "1.36.0-alpha"
    data["data"][0]["compatibility"]["supersedes"] = "1.35.1-alpha"
    plan_manifest.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Updated {plan_manifest} to 1.36.0-alpha")
else:
    print(f"Plan manifest {plan_manifest} not found")
