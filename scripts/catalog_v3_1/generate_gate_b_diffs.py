#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/catalog_v3_1/generate_gate_b_diffs.py

Generates exact, real git diff --no-index between Plan/catalog/_backup_pre_phaseB_fix/scheme_catalog.json
and Plan/catalog/scheme_catalog.json for SCH000005, SCH000255, SCH000279, and SCH000289.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

CAT_DIR = r"C:\Users\roger\OneDrive\Documents\Plan\catalog"
BACKUP_CAT = os.path.join(CAT_DIR, "_backup_pre_phaseB_fix", "scheme_catalog.json")
NEW_CAT = os.path.join(CAT_DIR, "scheme_catalog.json")


def main():
    with open(BACKUP_CAT, "r", encoding="utf-8") as f:
        b_data = {r["identity"]["id"]: r for r in json.load(f)["data"]}

    with open(NEW_CAT, "r", encoding="utf-8") as f:
        n_data = {r["identity"]["id"]: r for r in json.load(f)["data"]}

    target_schemes = ["SCH000005", "SCH000255", "SCH000279", "SCH000289"]

    for sid in target_schemes:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, suffix=".json") as f_b:
            json.dump(b_data[sid], f_b, indent=2, ensure_ascii=False)
            fb_path = f_b.name

        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, suffix=".json") as f_n:
            json.dump(n_data[sid], f_n, indent=2, ensure_ascii=False)
            fn_path = f_n.name

        cmd = ["git", "diff", "--no-index", fb_path, fn_path]
        res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")

        print(f"===========================================================================")
        print(f"REAL GIT DIFF --NO-INDEX: {sid} (Backup vs New)")
        print(f"Command: git diff --no-index a/{sid}.json b/{sid}.json")
        print(f"===========================================================================")
        out = res.stdout
        out = out.replace(fb_path, f"a/{sid}.json").replace(fn_path, f"b/{sid}.json")
        print(out)

        os.remove(fb_path)
        os.remove(fn_path)


if __name__ == "__main__":
    main()
