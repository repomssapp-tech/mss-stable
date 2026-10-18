import hashlib
import json
from pathlib import Path
from db_inspect import query

def main():
    print("=== admin.catalog_releases ===")
    cr_rows = query("select id, release_version, package_sha256, package_byte_size, schema_version, is_current, status, published_at from admin.catalog_releases where release_version = '1.36.0-alpha'")
    print(json.dumps(cr_rows, indent=2, default=str))

    print("\n=== admin.catalog_files pack rows with lang ===")
    cf_rows = query("select cf.file_name, cf.checksum, cf.byte_size, cf.storage_path, cf.lang, cr.release_version from admin.catalog_files cf join admin.catalog_releases cr on cr.id = cf.release_id where cf.lang is not null and cr.release_version = '1.36.0-alpha' order by cf.lang")
    print(json.dumps(cf_rows, indent=2, default=str))

    print("\n=== catalog.language row for hi ===")
    lang_rows = query("select * from catalog.language where code = 'hi'")
    print(json.dumps(lang_rows, indent=2, default=str))

    print("\n=== Asset sha256 checksums ===")
    asset_dir = Path("frontend/assets/catalog")
    for f in sorted(asset_dir.iterdir()):
        if f.is_file():
            h = hashlib.sha256(f.read_bytes()).hexdigest()
            print(f"{f.name}: sha256={h} ({f.stat().st_size:,} bytes)")

    print("\n=== release.json releaseTag ===")
    rel = json.loads((asset_dir / "release.json").read_text(encoding="utf-8"))
    print(f"releaseTag = {rel.get('releaseTag')}")
    print(f"activeLanguages = {rel.get('activeLanguages')}")
    print(f"languages = {json.dumps(rel.get('languages'), indent=2)}")

if __name__ == "__main__":
    main()
