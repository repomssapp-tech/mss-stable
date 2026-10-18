#!/usr/bin/env python3
"""Publishes a new MSS catalog release end-to-end, from edited source JSON in
Plan/catalog/ (or --source) all the way to a live release the app will pick
up automatically -- no Play Store release, no user action required.

This exists because that flow used to be five manual, error-prone steps
(rebuild the bundle, regenerate + apply catalog.* import SQL, upload to
Storage, flip the current-release pointer, verify) -- see
docs/specs/CATALOG_SPECIFICATIONS.md (Part 6) for
why the two-representation (catalog.* tables for the live API, Storage
release snapshot for the offline bundle) design requires doing both.

USAGE
    python tools/publish_catalog_release.py --target {local,linked} [--source PATH] [--yes]
    python tools/publish_catalog_release.py --target local --dry-run
    python tools/publish_catalog_release.py --target local --rollback-to 1.33.0-alpha

--target is required (no default) so an environment is always chosen
consciously -- there is no accidental-production footgun here. `local` talks
to a `supabase start` local stack (its own Postgres + Storage, seeded from
the exact same migrations as production -- a true schema mirror at zero
cost); `linked` talks to the real production project.

Before running for real: bump `catalogRelease` in Plan/catalog/manifest.json
to a new value. The script refuses to publish a release_version that's
already live, so this is the mechanism that prevents accidentally
re-publishing unchanged data under the same tag.

WHAT IT DOES (in order, each step confirmed before the next on failure):
  1. Reads release_version from manifest.json, checks it differs from what's
     currently live (via mss_current_release()) -- aborts otherwise.
  2. Regenerates catalog.* import SQL from source and applies every chunk,
     in order, via `supabase db query --file` -- this is what keeps the live
     /v1/* API in sync with the same source data.
  3. Builds the release bundle (catalog_bundle.json.gz + release.json) via
     generate_catalog_bundle.py, and copies the same bytes into
     frontend/assets/catalog/ so a fresh install also ships reasonably
     current data even before its first sync (real publish only).
  4. Uploads the merged bundle AND the 16 individual source files (15
     catalogs + search_index.json) to Storage under releases/<version>/,
     matching the original release's layout.
  5. Inserts the new admin.catalog_releases row (current) + one
     admin.catalog_files row per uploaded file + an
     admin.catalog_release_history 'published' entry, and demotes the
     previous current release -- this is the single moment the live app
     population starts seeing the new release_version.
  6. Verifies via a live mss_current_release() call that what's published
     matches what was just built (byte size + sha256), and that
     admin.catalog_files has exactly the 16 rows expected.

--dry-run runs steps 1-3 (regenerates the SQL and bundle locally) but makes
no Supabase calls, so you can sanity-check record counts/checksums first.

--rollback-to VERSION skips straight to a cheap pointer flip: sets
is_current=false on whatever is current and true on the named
already-published release, without touching catalog.* or Storage. Use this
if a publish goes out with bad data and you need the previous release live
again immediately.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.request
import uuid
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BACKEND_DIR = REPO_ROOT / "backend"
FRONTEND_ASSET_DIR = REPO_ROOT / "frontend" / "assets" / "catalog"
DEFAULT_SOURCE = REPO_ROOT / "backend" / "catalog" / "source"
SCRATCH_DIR = BACKEND_DIR / ".mss_publish_scratch"
BUCKET = "catalogs"

def _load_env_fallback():
    env_file = BACKEND_DIR / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

_load_env_fallback()

# New-format publishable key (sb_publishable_...) for the real project. Public
# by design -- the shipped Flutter app carries the same one -- but not hardcoded
# here; supply it via the environment (see backend/.env.example). Used only to
# verify a publish over the same public API surface every app instance uses.
PRODUCTION_URL = os.environ.get("SUPABASE_URL", "https://houpzsxmwemoztpuigmo.supabase.co")
PUBLISHABLE_KEY = os.environ.get("SUPABASE_PUBLISHABLE_KEY")

# Every file the release bundle covers -- 15 entity catalogs + the search
# index -- uploaded individually alongside the merged .gz so Storage mirrors
# the original release layout and admin.catalog_files stays reconciled.
RELEASE_FILES = [
    "common_catalog.json",
    "authority_catalog.json",
    "institution_catalog.json",
    "scheme_catalog.json",
    "finance_catalog.json",
    "tax_catalog.json",
    "treds_catalog.json",
    "csr_catalog.json",
    "export_catalog.json",
    "knowledge_catalog.json",
    "applicability_matrix_catalog.json",
    "enterprise_classification_catalog.json",
    "msme_privilege_catalog.json",
    "business_enablement_catalog.json",
    "cluster_assistance_catalog.json",
    "search_index.json",
]

# The integer app-compatibility schema version (SchemeCatalogStore
# .supportedSchemaVersion in the Flutter app). NOT the same thing as
# manifest.json's "schemaVersion" (a semver string describing the source
# catalog's own field layout, e.g. "1.0.0") -- only bump this if you're
# shipping a catalog shape that older installed app builds can't parse, and
# only after those app builds are already out via a real Play Store release.
APP_SCHEMA_VERSION = 1


class Env:
    """Resolves which Supabase (local stack vs. real production) every
    command in this run talks to. Constructed once from --target.

    `supabase db query --file` only supports multi-statement SQL scripts
    against the managed (--linked) API endpoint -- against --local/--db-url
    it fails with "cannot insert multiple commands into a prepared
    statement" (a real CLI limitation, confirmed by trying both --local and
    --db-url against the same file). So for target=="local" we bypass the
    CLI for SQL execution entirely and go straight through `docker exec
    <db_container> psql`, which is genuine Postgres and has no such
    restriction -- the local stack's own Postgres container, not a separate
    tool."""

    def __init__(self, target: str):
        self.target = target
        self.cli_flag = "--local" if target == "local" else "--linked"
        if target == "local":
            status = parse_json_object(
                run(["npx", "supabase", "status", "-o", "json"], cwd=BACKEND_DIR)
            )
            self.url = status["API_URL"]
            self.anon_key = status["ANON_KEY"]
            config = (BACKEND_DIR / "supabase" / "config.toml").read_text(encoding="utf-8")
            project_id = next(
                line.split("=", 1)[1].strip().strip('"')
                for line in config.splitlines()
                if line.strip().startswith("project_id")
            )
            self.db_container = f"supabase_db_{project_id}"
        else:
            if not PUBLISHABLE_KEY:
                raise SystemExit(
                    "Set SUPABASE_PUBLISHABLE_KEY (the sb_publishable_... key) in "
                    "the environment to publish/verify against production. Never "
                    "hardcode Supabase keys in source."
                )
            self.url = PRODUCTION_URL
            self.anon_key = PUBLISHABLE_KEY

    def db_query(self, sql_path: Path) -> str:
        """Applies a (possibly multi-statement) SQL script. Fire-and-forget
        -- use query_json() instead when you need structured results back."""
        if self.target == "local":
            result = subprocess.run(
                [
                    "docker", "exec", "-i", self.db_container,
                    "psql", "-U", "postgres", "-d", "postgres",
                    "-v", "ON_ERROR_STOP=1", "-f", "-",
                ],
                input=sql_path.read_bytes(),
                capture_output=True,
            )
            if result.returncode != 0:
                raise RuntimeError(
                    f"psql failed on {sql_path.name}: {result.stderr.decode('utf-8', errors='replace')}"
                )
            return result.stdout.decode("utf-8", errors="replace")
        return run(
            ["npx", "supabase", "db", "query", self.cli_flag, "--file", str(sql_path)],
            cwd=BACKEND_DIR,
        )

    def query_json(self, sql: str) -> list[dict]:
        """Runs a single read-only SQL statement (no trailing semicolon) and
        returns its rows as a list of dicts, uniformly across targets."""
        if self.target == "local":
            wrapped = f"select coalesce(json_agg(t), '[]'::json)::text from ({sql}) t;"
            result = subprocess.run(
                [
                    "docker", "exec", "-i", self.db_container,
                    "psql", "-U", "postgres", "-d", "postgres",
                    "-t", "-A", "-c", wrapped,
                ],
                capture_output=True,
            )
            if result.returncode != 0:
                raise RuntimeError(f"psql query failed: {result.stderr.decode('utf-8', errors='replace')}")
            return json.loads(result.stdout.decode("utf-8", errors="replace").strip())
        sql_path = SCRATCH_DIR / "query_json_tmp.sql"
        SCRATCH_DIR.mkdir(parents=True, exist_ok=True)
        sql_path.write_text(f"{sql};", encoding="utf-8")
        out = run(
            ["npx", "supabase", "db", "query", self.cli_flag, "--file", str(sql_path)],
            cwd=BACKEND_DIR,
        )
        return parse_json_object(out)["rows"]

    def storage_delete_prefix(self, prefix: str) -> None:
        """Deletes any existing objects under prefix in Storage before upload to avoid 409 KeyAlreadyExists."""
        if self.target == "local":
            return
        secret_key = os.environ.get("SUPABASE_SECRET_KEY")
        if not secret_key:
            return
        try:
            list_req = urllib.request.Request(
                f"{self.url}/storage/v1/object/list/{BUCKET}",
                data=json.dumps({"prefix": prefix, "limit": 100}).encode("utf-8"),
                headers={
                    "apikey": secret_key,
                    "Authorization": f"Bearer {secret_key}",
                    "Content-Type": "application/json",
                },
                method="POST",
            )
            with urllib.request.urlopen(list_req, timeout=15) as resp:
                items = json.loads(resp.read().decode("utf-8"))
            if not items:
                return
            names = [f"{prefix.rstrip('/')}/{item['name']}" for item in items]
            del_req = urllib.request.Request(
                f"{self.url}/storage/v1/object/{BUCKET}",
                data=json.dumps({"prefixes": names}).encode("utf-8"),
                headers={
                    "apikey": secret_key,
                    "Authorization": f"Bearer {secret_key}",
                    "Content-Type": "application/json",
                },
                method="DELETE",
            )
            with urllib.request.urlopen(del_req, timeout=15) as resp:
                resp.read()
            print(f"  cleaned {len(names)} existing object(s) under {prefix}/")
        except Exception as e:
            print(f"    (warning: storage_delete_prefix failed: {e})", file=sys.stderr)

    def storage_cp(self, local_rel_path: str, remote_object_path: str) -> str:
        last_exc = None
        for attempt in range(1, 4):
            try:
                return run(
                    [
                        "npx", "supabase", "storage", "cp",
                        local_rel_path,
                        f"ss:///{BUCKET}/{remote_object_path}",
                        "--experimental", self.cli_flag,
                    ],
                    cwd=BACKEND_DIR,
                )
            except Exception as e:
                last_exc = e
                if "KeyAlreadyExists" in str(e):
                    secret_key = os.environ.get("SUPABASE_SECRET_KEY")
                    if secret_key and self.target == "linked":
                        try:
                            del_req = urllib.request.Request(
                                f"{self.url}/storage/v1/object/{BUCKET}",
                                data=json.dumps({"prefixes": [remote_object_path]}).encode("utf-8"),
                                headers={
                                    "apikey": secret_key,
                                    "Authorization": f"Bearer {secret_key}",
                                    "Content-Type": "application/json",
                                },
                                method="DELETE",
                            )
                            with urllib.request.urlopen(del_req, timeout=15) as resp:
                                resp.read()
                        except Exception as del_err:
                            print(f"    (warning: failed to delete existing {remote_object_path}: {del_err})", file=sys.stderr)
                if attempt < 3:
                    print(f"    (storage_cp retry {attempt}/3 after error: {e})", file=sys.stderr)
                    time.sleep(3)
        raise last_exc

    def rpc(self, function_name: str, payload: dict) -> list | None:
        req = urllib.request.Request(
            f"{self.url}/rest/v1/rpc/{function_name}",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "apikey": self.anon_key,
                "Authorization": f"Bearer {self.anon_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read())


def run(cmd: list[str], cwd: Path | None = None) -> str:
    # On Windows, `npx` resolves to a .cmd shim that subprocess can't exec
    # directly without going through a shell.
    result = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8",
        shell=(sys.platform == "win32"),
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Command failed ({result.returncode}): {' '.join(cmd)}\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )
    return result.stdout


def parse_json_object(cli_output: str) -> dict:
    """Supabase CLI commands sometimes append trailing plain-text notices
    (e.g. "A new version of Supabase CLI is available...") after the JSON
    payload, so a plain json.loads(cli_output) can fail. Extract just the
    outermost {...} object."""
    start = cli_output.index("{")
    end = cli_output.rindex("}")
    return json.loads(cli_output[start : end + 1])


def mss_current_release(env: Env) -> dict | None:
    rows = env.rpc("mss_current_release", {})
    return rows[0] if rows else None


def read_manifest_release_version(source: Path) -> str:
    manifest = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    return manifest["data"][0]["catalogRelease"]


def step_apply_catalog_import(env: Env, source: Path) -> None:
    print("\n== Step 2/6: regenerating + applying catalog.* import SQL ==")
    import_dir = SCRATCH_DIR / "import_sql"
    if import_dir.exists():
        shutil.rmtree(import_dir)
    run(
        [
            "node",
            str(BACKEND_DIR / "scripts" / "generate_catalog_import_sql.js"),
            str(source),
            str(import_dir),
        ]
    )
    chunk_files = sorted(import_dir.glob("*.sql"))
    if not chunk_files:
        raise RuntimeError(f"No SQL chunks generated in {import_dir}")
    for chunk in chunk_files:
        print(f"  applying {chunk.name} ...")
        env.db_query(chunk)
    print(f"  applied {len(chunk_files)} chunk(s).")


def step_build_bundle(source: Path, update_shipped_asset: bool) -> dict:
    print("\n== Step 3/6: building release bundle + language packs ==")
    build_dir = SCRATCH_DIR / "bundle"
    if build_dir.exists():
        shutil.rmtree(build_dir)
    run(
        [
            sys.executable,
            str(REPO_ROOT / "tools" / "build_catalog_release.py"),
            "--source",
            str(source),
            "--out-dir",
            str(build_dir),
        ]
    )
    release = json.loads((build_dir / "release.json").read_text(encoding="utf-8"))

    if update_shipped_asset:
        # Byte-identical copy into the shipped Flutter assets
        FRONTEND_ASSET_DIR.mkdir(parents=True, exist_ok=True)
        shutil.copy2(build_dir / "catalog_bundle.json.gz", FRONTEND_ASSET_DIR / "catalog_bundle.json.gz")
        shutil.copy2(build_dir / "release.json", FRONTEND_ASSET_DIR / "release.json")
        for lang in ("hi", "ta"):
            pack_gz = build_dir / f"catalog_pack_{lang}.json.gz"
            if pack_gz.exists():
                shutil.copy2(pack_gz, FRONTEND_ASSET_DIR / f"catalog_pack_{lang}.json.gz")

    release["_build_dir"] = str(build_dir)
    return release


def step_upload_release_artifacts(env: Env, source: Path, release: dict, release_version: str) -> list[dict]:
    print("\n== Step 4/6: uploading release artifacts to Storage ==")
    build_dir = Path(release["_build_dir"])
    upload_root = SCRATCH_DIR / "upload"
    if upload_root.exists():
        shutil.rmtree(upload_root)
    upload_root.mkdir(parents=True)
    env.storage_delete_prefix(f"releases/{release_version}")

    uploaded_files = []

    # The merged bundle -- the only thing the app's sync path actually reads.
    bundle_scratch = upload_root / "catalog_bundle.json.gz"
    shutil.copy2(build_dir / "catalog_bundle.json.gz", bundle_scratch)
    env.storage_cp(
        str(bundle_scratch.relative_to(BACKEND_DIR)).replace("\\", "/"),
        f"releases/{release_version}/catalog_bundle.json.gz",
    )
    print(f"  uploaded catalog_bundle.json.gz ({release['bundleBytes']:,} bytes)")

    # The 16 individual source files, matching the original release layout
    # and keeping admin.catalog_files fully reconciled.
    for file_name in RELEASE_FILES:
        src_path = source / file_name
        raw_bytes = src_path.read_bytes()
        dest = upload_root / file_name
        shutil.copy2(src_path, dest)
        env.storage_cp(
            str(dest.relative_to(BACKEND_DIR)).replace("\\", "/"),
            f"releases/{release_version}/{file_name}",
        )
        uploaded_files.append(
            {
                "file_name": file_name,
                "checksum": hashlib.sha256(raw_bytes).hexdigest(),
                "byte_size": len(raw_bytes),
                "storage_path": f"releases/{release_version}/{file_name}",
                "lang": None,
            }
        )
    print(f"  uploaded {len(RELEASE_FILES)} individual source files")

    # Upload the 2 compressed language packs with lang set
    for lang in ("hi", "ta"):
        pack_name = f"catalog_pack_{lang}.json.gz"
        pack_src = build_dir / pack_name
        if pack_src.exists():
            raw_bytes = pack_src.read_bytes()
            dest = upload_root / pack_name
            shutil.copy2(pack_src, dest)
            env.storage_cp(
                str(dest.relative_to(BACKEND_DIR)).replace("\\", "/"),
                f"releases/{release_version}/{pack_name}",
            )
            uploaded_files.append(
                {
                    "file_name": pack_name,
                    "checksum": hashlib.sha256(raw_bytes).hexdigest(),
                    "byte_size": len(raw_bytes),
                    "storage_path": f"releases/{release_version}/{pack_name}",
                    "lang": lang,
                }
            )
            print(f"  uploaded {pack_name} ({len(raw_bytes):,} bytes, lang={lang})")

    return uploaded_files


def step_publish_release_row(env: Env, release: dict, release_version: str, uploaded_files: list[dict], set_current: bool = False) -> str:
    print(f"\n== Step 5/6: recording release row (set_current={set_current}) + reconciling catalog_files ==")
    release_id = str(uuid.uuid4())
    record_counts_json = json.dumps(release["recordCounts"]).replace("'", "''")

    lines = []
    if set_current:
        lines.append("update admin.catalog_releases set is_current = false where is_current = true;")
        status = "published"
        is_cur_val = "true"
    else:
        status = "candidate"
        is_cur_val = "false"

    lines.extend([
        "insert into admin.catalog_releases (",
        "  id, release_version, package_sha256, package_byte_size, schema_version,",
        "  record_counts, is_current, status, published_at, minimum_app_version, notes",
        ") values (",
        f"  '{release_id}',",
        f"  '{release_version}',",
        f"  '{release['bundleSha256']}',",
        f"  {release['bundleBytes']},",
        f"  {APP_SCHEMA_VERSION},",
        f"  '{record_counts_json}'::jsonb,",
        f"  {is_cur_val},",
        f"  '{status}',",
        "  now(),",
        "  '1.0.0',",
        "  'Published via tools/publish_catalog_release.py'",
        ");",
        "",
    ])
    for f in uploaded_files:
        lang_val = f"'{f['lang']}'" if f.get("lang") else "null"
        lines.append(
            "insert into admin.catalog_files (release_id, file_name, checksum, byte_size, storage_path, lang) "
            f"values ('{release_id}', '{f['file_name']}', '{f['checksum']}', {f['byte_size']}, '{f['storage_path']}', {lang_val});"
        )
    lines.append("")
    lines.append(
        f"insert into admin.catalog_release_history (release_id, action) "
        f"values ('{release_id}', '{status}');"
    )

    sql_path = SCRATCH_DIR / "publish_release_row.sql"
    sql_path.write_text("\n".join(lines), encoding="utf-8")
    env.db_query(sql_path)
    print(f"  {release_version} recorded in admin.catalog_releases (release_id={release_id}, status={status}, is_current={set_current}).")
    return release_id


def step_verify(env: Env, release: dict, release_version: str, release_id: str, expected_file_count: int, expect_current: bool = False) -> None:
    print("\n== Step 6/6: verifying state ==")
    if expect_current:
        live = mss_current_release(env)
        if live is None:
            raise RuntimeError("mss_current_release() returned nothing after publish.")
        if live["release_version"] != release_version:
            raise RuntimeError(
                f"Live release_version is {live['release_version']!r}, expected {release_version!r}."
            )
        if live["package_sha256"] != release["bundleSha256"]:
            raise RuntimeError("Live package_sha256 does not match the built bundle.")
        if live["package_byte_size"] != release["bundleBytes"]:
            raise RuntimeError("Live package_byte_size does not match the built bundle.")
        print("  mss_current_release() matches the published bundle exactly.")
    else:
        print(f"  candidate release {release_version} uploaded without flipping is_current.")
    print(f"    release_version={live['release_version']}")
    print(f"    package_sha256={live['package_sha256']}")
    print(f"    package_byte_size={live['package_byte_size']}")

    rows = env.query_json(f"select count(*) as n from admin.catalog_files where release_id = '{release_id}'")
    n = int(rows[0]["n"])
    if n != expected_file_count:
        raise RuntimeError(
            f"admin.catalog_files has {n} rows for release_id={release_id}, expected {expected_file_count}."
        )
    print(f"  admin.catalog_files reconciled: {n}/{expected_file_count} rows.")

    pack_rows = env.query_json(f"select file_name, lang, byte_size, checksum from admin.catalog_files where release_id = '{release_id}' and lang is not null order by lang")
    print(f"  admin.catalog_files packs with lang set ({len(pack_rows)} rows):")
    for pr in pack_rows:
        print(f"    file_name={pr['file_name']}, lang={pr['lang']}, checksum={pr['checksum']}")

    orphans = env.query_json(
        "select cf.id from admin.catalog_files cf "
        "left join admin.catalog_releases cr on cr.id = cf.release_id "
        "where cr.id is null"
    )
    if orphans:
        raise RuntimeError(f"{len(orphans)} admin.catalog_files row(s) reference a nonexistent release.")
    print("  no broken catalog_files -> catalog_releases references.")

    multi_current = env.query_json("select release_version from admin.catalog_releases where is_current = true")
    if len(multi_current) != 1:
        raise RuntimeError(f"Expected exactly 1 current release, found {len(multi_current)}: {multi_current}")
    print("  exactly one current release.")


def do_rollback(env: Env, target_version: str) -> None:
    print(f"Rolling back to {target_version} (pointer flip only, no data changes)...")
    live = mss_current_release(env)
    if live and live["release_version"] == target_version:
        print(f"{target_version} is already the current release. Nothing to do.")
        return

    SCRATCH_DIR.mkdir(parents=True, exist_ok=True)
    rows = env.query_json(f"select id from admin.catalog_releases where release_version = '{target_version}'")
    if not rows:
        raise RuntimeError(f"No release row found for release_version={target_version!r}. Nothing to roll back to.")
    target_id = rows[0]["id"]

    sql = f"""
update admin.catalog_releases set is_current = false where is_current = true;
update admin.catalog_releases set is_current = true, status = 'published'
  where release_version = '{target_version}';
insert into admin.catalog_release_history (release_id, action)
  values ('{target_id}', 'rolled_back');
"""
    sql_path = SCRATCH_DIR / "rollback.sql"
    sql_path.write_text(sql, encoding="utf-8")
    env.db_query(sql_path)
    live = mss_current_release(env)
    if live is None or live["release_version"] != target_version:
        raise RuntimeError(
            f"Rollback verification failed: mss_current_release() returned {live!r}"
        )
    print(f"OK -- {target_version} is now the current release again.")
    shutil.rmtree(SCRATCH_DIR, ignore_errors=True)


def do_flip_current(env: Env, target_version: str) -> None:
    print(f"Checking D17 Gate report before flipping {target_version} to current...")
    gate_report_file = REPO_ROOT / "docs" / "reports" / f"gate_{target_version}.json"
    if not gate_report_file.exists():
        raise SystemExit(
            f"D17 GUARD: No gate report found at {gate_report_file}. "
            f"Run `python tools/release_gate.py` to generate PASS report before flipping to current."
        )
    report = json.loads(gate_report_file.read_text(encoding="utf-8"))
    if report.get("overallStatus") != "PASS":
        raise SystemExit(
            f"D17 GUARD: Gate report for {target_version} has status {report.get('overallStatus')!r}. "
            "The release tool refuses to flip is_current unless the gate report is PASS."
        )
    print(f"  Gate report PASS verified ({gate_report_file.name}).")
    do_rollback(env, target_version)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", required=True, choices=["local", "linked"], help="Which Supabase to publish to: 'local' (supabase start stack) or 'linked' (real production).")
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--dry-run", action="store_true", help="Build locally only; no Supabase calls.")
    parser.add_argument("--yes", action="store_true", help="Skip the confirmation prompt.")
    parser.add_argument("--rollback-to", metavar="VERSION", help="Flip the current-release pointer back to an already-published version, without touching catalog.* or Storage.")
    parser.add_argument("--flip-current", metavar="VERSION", help="Flip is_current to specified candidate version after gate PASS verification.")
    parser.add_argument("--set-current", action="store_true", help="Flip is_current=true during publish (requires PASS gate report). Default publishes as non-current candidate.")
    args = parser.parse_args()

    env = Env(args.target)
    print(f"Target: {args.target} ({env.url})")

    if args.rollback_to:
        do_rollback(env, args.rollback_to)
        return

    if args.flip_current:
        do_flip_current(env, args.flip_current)
        return

    source: Path = args.source
    if not (source / "manifest.json").exists():
        raise SystemExit(f"No manifest.json found under {source}")

    release_version = read_manifest_release_version(source)
    print(f"Source: {source}")
    print(f"release_version (from manifest.json catalogRelease): {release_version}")

    # D16 immutability guard: refuse existing release version
    existing_rows = env.query_json(f"select id, release_version, status, is_current from admin.catalog_releases where release_version = '{release_version}'")
    if existing_rows:
        raise SystemExit(
            f"D16 GUARD: release_version {release_version!r} already exists in admin.catalog_releases "
            f"(status={existing_rows[0]['status']}, is_current={existing_rows[0]['is_current']}). "
            "A published release version is immutable. A failed publish or new change must use a new release version."
        )

    print("\n== Step 1/6: checking current live release ==")
    live = mss_current_release(env)
    current_version = live["release_version"] if live else None
    print(f"  currently live: {current_version}")

    if args.dry_run:
        SCRATCH_DIR.mkdir(parents=True, exist_ok=True)
        release = step_build_bundle(source, update_shipped_asset=False)
        print("\n-- dry run: no catalog.* import applied, no Storage upload, no pointer flip --")
        print(f"Would publish release_version={release_version}")
        print(f"  bundleSha256={release['bundleSha256']}")
        print(f"  bundleBytes={release['bundleBytes']}")
        print(f"  recordCounts={json.dumps(release['recordCounts'], indent=2)}")
        shutil.rmtree(SCRATCH_DIR, ignore_errors=True)
        return

    if not args.yes:
        answer = input(
            f"\nAbout to publish release_version={release_version!r} to {args.target} "
            f"(current: {current_version!r}). Continue? [y/N] "
        )
        if answer.strip().lower() != "y":
            print("Aborted.")
            return

    if args.set_current:
        gate_report_file = REPO_ROOT / "docs" / "reports" / f"gate_{release_version}.json"
        if not gate_report_file.exists():
            raise SystemExit(f"D17 GUARD: Gate report {gate_report_file.name} missing. Run release_gate.py first.")
        report = json.loads(gate_report_file.read_text(encoding="utf-8"))
        if report.get("overallStatus") != "PASS":
            raise SystemExit(f"D17 GUARD: Gate report {gate_report_file.name} has status {report.get('overallStatus')!r}, must be PASS.")

    SCRATCH_DIR.mkdir(parents=True, exist_ok=True)
    try:
        step_apply_catalog_import(env, source)
        release = step_build_bundle(source, update_shipped_asset=(args.target == "linked"))
        uploaded_files = step_upload_release_artifacts(env, source, release, release_version)
        release_id = step_publish_release_row(env, release, release_version, uploaded_files, set_current=args.set_current)
        step_verify(env, release, release_version, release_id, len(uploaded_files), expect_current=args.set_current)
        print(f"\nPublished {release_version} to {args.target} (is_current={args.set_current}).")
        if args.target == "linked" and args.set_current:
            print("Already-installed apps will pick it up on their next open/resume.")
        elif args.target == "linked":
            print(f"Candidate {release_version} is staged as non-current. Run release gate then `--flip-current {release_version}` to activate.")
    finally:
        shutil.rmtree(SCRATCH_DIR, ignore_errors=True)


if __name__ == "__main__":
    main()
