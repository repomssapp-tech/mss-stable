#!/usr/bin/env python3
"""P7 Step 1: Move source into repo (D15).
(a) Read-only inventory of OneDrive folder: size, last-modified, sha256, which tools read it.
(b) Dated backup copy outside OneDrive with sha256 list.
(c) Copy to repo path (backend/catalog/source/) and prove every sha256 identical.
"""

from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil

ONEDRIVE_SOURCE = Path(r"C:\Users\roger\OneDrive\Documents\Plan\catalog")
REPO_ROOT = Path(__file__).resolve().parent.parent
TARGET_SOURCE = REPO_ROOT / "backend" / "catalog" / "source"
BACKUP_DIR = Path(r"C:\development\catalog_source_backup_20261006")

def get_file_info(fpath: Path) -> dict:
    stat = fpath.stat()
    sha = hashlib.sha256(fpath.read_bytes()).hexdigest()
    mtime = datetime.fromtimestamp(stat.st_mtime).isoformat()
    return {
        "name": fpath.name,
        "size": stat.st_size,
        "mtime": mtime,
        "sha256": sha,
        "over_50mb": stat.st_size > 50 * 1024 * 1024,
    }

def collect_codebase_contents() -> dict[str, str]:
    codebase = {}
    scan_roots = [
        REPO_ROOT / "tools",
        REPO_ROOT / "scripts",
        REPO_ROOT / "backend" / "catalog",
        REPO_ROOT / "backend" / "supabase" / "functions",
        REPO_ROOT / "frontend" / "lib",
    ]
    ignored_parts = {".mss_publish_scratch", "scratch", "node_modules", "__pycache__", ".git"}
    for sdir in scan_roots:
        if not sdir.exists():
            continue
        for root, dirs, files in os.walk(sdir):
            dirs[:] = [d for d in dirs if d not in ignored_parts]
            for file in files:
                if file.endswith((".py", ".sql", ".sh", ".js", ".ts", ".dart")):
                    p = Path(root) / file
                    try:
                        codebase[str(p.relative_to(REPO_ROOT)).replace("\\", "/")] = p.read_text(encoding="utf-8", errors="ignore")
                    except Exception:
                        pass
    return codebase

def main():
    print("=== P7 Step 1(a): Inventory of OneDrive Source ===")
    if not ONEDRIVE_SOURCE.exists():
        raise RuntimeError(f"Source does not exist: {ONEDRIVE_SOURCE}")

    codebase = collect_codebase_contents()
    print(f"Loaded {len(codebase)} repo files for reader reference scanning.")

    inventory = []
    files = [f for f in ONEDRIVE_SOURCE.iterdir() if f.is_file()]
    print(f"Total files in source: {len(files)}")

    over_50mb_files = []
    for f in sorted(files, key=lambda x: x.name):
        info = get_file_info(f)
        readers = [
            repo_file for repo_file, content in codebase.items()
            if f.name in content
        ]
        info["readers"] = sorted(readers)
        inventory.append(info)
        if info["over_50mb"]:
            over_50mb_files.append(info["name"])

    print(f"Files over 50 MB: {over_50mb_files if over_50mb_files else 'None'}")

    report_path = REPO_ROOT / "docs" / "reports" / "source_inventory_p7.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    print(f"Saved inventory to {report_path}")

    # Also summary markdown for report
    md_summary_path = REPO_ROOT / "docs" / "reports" / "SOURCE_INVENTORY_P7.md"
    md_lines = [
        "# P7 Source Inventory (OneDrive: Plan/catalog)",
        f"- Total files: {len(files)}",
        f"- Files > 50 MB: {len(over_50mb_files)}",
        "",
        "| File Name | Size (bytes) | SHA-256 | Readers in Repo |",
        "|---|---|---|---|",
    ]
    for item in inventory:
        r_str = ", ".join(item["readers"]) if item["readers"] else "None"
        if len(r_str) > 80:
            r_str = f"{len(item['readers'])} files"
        md_lines.append(f"| `{item['name']}` | {item['size']:,} | `{item['sha256'][:16]}...` | {r_str} |")
    md_summary_path.write_text("\n".join(md_lines), encoding="utf-8")
    print(f"Saved summary to {md_summary_path}")

    print("\n=== P7 Step 1(b): Dated Backup Outside OneDrive ===")
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup_hashes = {}
    for f in files:
        dest = BACKUP_DIR / f.name
        shutil.copy2(f, dest)
        dest_sha = hashlib.sha256(dest.read_bytes()).hexdigest()
        backup_hashes[f.name] = dest_sha
    
    # Verify backup hashes
    backup_mismatches = []
    for item in inventory:
        fname = item["name"]
        if backup_hashes.get(fname) != item["sha256"]:
            backup_mismatches.append(fname)
    if backup_mismatches:
        raise RuntimeError(f"Backup sha256 mismatch for: {backup_mismatches}")
    print(f"Backup created at {BACKUP_DIR} ({len(files)} files, all sha256 verified identical).")

    print("\n=== P7 Step 1(c): Copy to backend/catalog/source/ ===")
    TARGET_SOURCE.mkdir(parents=True, exist_ok=True)
    target_hashes = {}
    for f in files:
        dest = TARGET_SOURCE / f.name
        shutil.copy2(f, dest)
        dest_sha = hashlib.sha256(dest.read_bytes()).hexdigest()
        target_hashes[f.name] = dest_sha

    # Verify target hashes
    target_mismatches = []
    for item in inventory:
        fname = item["name"]
        if target_hashes.get(fname) != item["sha256"]:
            target_mismatches.append(fname)
    if target_mismatches:
        raise RuntimeError(f"Target sha256 mismatch for: {target_mismatches}")
    print(f"Copied to {TARGET_SOURCE} ({len(files)} files, all sha256 proved identical).")

if __name__ == "__main__":
    main()
