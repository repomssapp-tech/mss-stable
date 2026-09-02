# Production Catalog Publish Checklist

Prepared after a full staging validation of `tools/publish_catalog_release.py`
against a local Supabase stack (`supabase start`, exact schema mirror of
production via the same migrations) on 2026-08-16. See "Staging validation
results" below for what was actually exercised and confirmed. **This
checklist has not yet been run against production `--target linked`.**

## What this does, in one sentence

Publishes an edited `Plan/catalog/` (or `--source PATH`) as the new catalog
release: every already-installed app picks it up automatically on its next
open/resume -- no Play Store release, no user action.

## Pre-flight (do this before touching production)

1. Edit the source data under `Plan/catalog/` (or your `--source` path).
2. Bump `catalogRelease` in `Plan/catalog/manifest.json` to a new value.
   The script refuses to publish a release_version that's already live --
   this is the safety net against accidentally re-publishing an unchanged
   tag.
3. Run a dry run first:
   ```
   python tools/publish_catalog_release.py --target linked --dry-run
   ```
   This regenerates the bundle locally and prints `bundleSha256`,
   `bundleBytes`, and `recordCounts` -- **no Supabase calls are made**.
   Sanity-check the record counts match what you expect (e.g. did you
   actually add the scheme you meant to add? did any catalog's count drop
   unexpectedly, which usually means a source file got truncated?).
4. Review `git diff` / `git status` -- a dry run does not touch any repo
   file, so if anything under `frontend/assets/catalog/` shows as modified
   at this point, something is wrong; stop and investigate before
   proceeding.

## Execution

```
python tools/publish_catalog_release.py --target linked
```

You'll be asked to confirm (`About to publish release_version=... to ALL
live users`). Read the currently-live version shown and make sure it's the
one you expect to be replacing. Pass `--yes` only for scripted/CI use where
a human already reviewed the dry run.

The script then, in order:
1. Confirms `release_version` differs from what's currently live.
2. Regenerates and applies `catalog.*` import SQL (keeps the live `/v1/*`
   API in sync with the same source data) -- ~24 chunked SQL files, applied
   via `supabase db query --linked --file`.
3. Builds the release bundle and copies it into
   `frontend/assets/catalog/` (so the next app build also ships current
   data). **This modifies a tracked repo file** -- commit it as part of the
   same change that prompted the data update, or `git checkout` it back if
   you don't want the shipped-asset copy to move yet.
4. Uploads the merged bundle + all 16 individual source files to Storage
   under `releases/<version>/`.
5. Inserts the new `admin.catalog_releases` row (current) + 16
   `admin.catalog_files` rows + an `admin.catalog_release_history`
   'published' entry, and demotes the previous current release (demoted,
   never deleted).
6. Verifies live `mss_current_release()` matches what was just built, plus
   `admin.catalog_files` row count and referential integrity.

If any step fails, **nothing after it has run** -- e.g. a failure at step 4
means the pointer was never flipped, so production keeps serving the old
release untouched.

## Post-publish verification (do this regardless of how confident you are)

1. `mss_current_release()` returns the new `release_version` and a
   `package_sha256` that matches what the script printed.
2. Spot-check one changed record via the live API (e.g.
   `mss_scheme_detail` for a scheme you edited) to confirm the *content*
   change is visible, not just the version tag.
3. If you have a spare device/emulator with the app already installed and
   signed in: force-stop and relaunch it, then confirm (via `adb logcat`
   filtering for `MssCatalogBundle`) that it installs and loads the new
   release. Not required for every publish, but worth doing for anything
   beyond a trivial text fix.
4. Keep an eye on your Supabase project's logs/error rate for a few
   minutes after publishing -- a bad `record_json` shape wouldn't fail the
   publish script (it doesn't validate business logic, only structural
   things like file existence and hashes) but could break a specific
   scheme's detail page.

## Rollback (if something looks wrong after publishing)

```
python tools/publish_catalog_release.py --target linked --rollback-to <previous-version>
```

This only flips `is_current`/`status` on `admin.catalog_releases` -- it does
**not** touch `catalog.*` row content or Storage. So a rollback restores
which release *new syncs* pull, but doesn't undo the `catalog.*` upserts
from the bad publish (those already had correct checksums for whatever
content you gave the script -- if the *content itself* was wrong, e.g. a
typo in a scheme name, you need to fix the source and publish again with a
new version, not just roll back the pointer).

Any device that already fully downloaded and installed the bad release
before you rolled back will re-sync down to the restored version on its
next open (same detection mechanism as any other version change) -- the
[`SchemeCatalogStore`](frontend/lib/services/scheme_catalog_store.dart)
keeps the previous release's files on disk until a new install fully
succeeds, so this downgrade is exactly as safe as any other publish.

## Known constraints

- **Windows + `npx`**: the script shells out via `cmd.exe` on Windows for
  `npx supabase ...` calls -- this is already handled, not something you
  need to do manually.
- **`admin.catalog_files.checksum`/`storage_path` are per-release** -- a
  rollback doesn't delete the bad release's `catalog_files` rows or Storage
  objects, it just stops it being current. They stay around as a normal
  historical (`status='published'`, `is_current=false`) release, not an
  "orphan" -- nothing references them as broken, and nothing deletes them
  automatically. Clean up manually via the Supabase dashboard if a
  particular test/bad release needs to be fully removed from Storage.
- **`--target` has no default** -- you must always type `local` or `linked`
  explicitly. There is no footgun where omitting a flag accidentally hits
  production.

## Staging validation results (2026-08-16)

Run against a `supabase start` local stack (Docker-based, exact schema
mirror via the same migrations `--linked` production runs), seeded with a
byte-for-byte baseline matching production (`package_sha256` matched
production's real hash exactly: `ccc3251ae2dccaf...`).

Published test release `1.33.0-alpha-script-test1` with `--target local`,
then confirmed:

| Check | Result |
|---|---|
| Release pointer update | `mss_current_release()` returned the new version/hash immediately after publish |
| `catalog_files` generation | 16/16 rows inserted, `checksum` verified against a downloaded object's actual SHA-256 |
| Storage artifact creation | All 17 objects present (16 source files + merged bundle); bundle downloaded and hash-matched |
| SHA-256 generation | Bundle hash + all 16 per-file hashes verified against re-downloaded bytes |
| Manifest correctness | `admin.catalog_releases` row fields match `CatalogManifest.fromReleaseRpc()`'s expected shape exactly |
| Row reconciliation | All 15 `catalog.*` tables summed to 1216 rows post-publish (no loss/duplication) |
| Flutter sync compatibility | Bundle's 17 top-level keys and `mss_current_release()`'s field names match what the Dart client code parses, byte-identical structure to the real production bundle verified earlier this session |
| Rollback process | `--rollback-to 1.33.0-alpha` restored the original pointer; verified via live RPC |
| Previous release pointer restored | Confirmed `is_current=true` back on `1.33.0-alpha` |
| No catalog content changed | `catalog.scheme` row checksum for a spot-checked record matched production's real value exactly |
| Hashes unchanged | Same as above |
| No orphan releases | Both releases present with valid, non-null, correctly-scoped `catalog_files` |
| No broken references | Explicit `catalog_files -> catalog_releases` LEFT JOIN check found zero dangling rows |
| Production untouched | `mss_current_release()` against production showed the exact same `published_at` timestamp before and after this entire staging exercise |

One real bug was found and fixed during this validation: `supabase db query
--file` cannot execute multi-statement SQL scripts against `--local` or
`--db-url` connections (only against the managed `--linked` API endpoint --
confirmed by testing both). The script now routes local execution through
`docker exec <db_container> psql` instead, which has no such restriction.
This is a `--target local`-only code path; `--target linked` was always
using the working CLI path and is unaffected.
