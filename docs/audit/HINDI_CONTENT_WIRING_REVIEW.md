# Review: Antigravity's Hindi / `catalog.content` changes, and how they reach the app

**Checked:** 2026-10-06, against:
- the live Supabase database
- the repo working tree (`data/catalog-v3-1-migration`, uncommitted changes)
- the built language packs in `frontend/assets/catalog/`

## 1. What changed in Supabase

| Object | What it is | Rows |
|---|---|---:|
| `catalog.language` (new) | Language list plus an on/off switch: `en` ✅, `ta` ✅, `hi` ❌ (`is_active=false`) | 3 |
| `catalog.content` (new) | **One row per entity per language**: name, short_name, summary, objective, description, benefits_text, eligibility_text, application_text, aliases[], keywords[], plus origin/engine/verified/source_checksum | 1,374 |
| `admin.translation_jobs` (was empty) | Log of every machine translation: 1,478 COMPLETED, 44 FAILED (number-check failures) | 1,522 |
| `admin.catalog_files.lang` (new column) | Marks a release file as a language pack | – |
| Migrations | `20261005190312_content_table`, `20261006020000_add_lang_to_catalog_files` (both recorded remotely, **files not committed**) | |

`catalog.content` by language:

| Type | en | ta | hi |
|---|---:|---:|---:|
| scheme | 302 (human) | 219 (Claude machine) | 218 (90 Google Translate + 114 machine + 14 from the 2015 compendium) |
| authority | 131 | 124 | 131 (Google Translate) |
| institution | 83 | 83 | 83 (Google Translate) |

## 2. "It inserted the JSONs into the table": will that work?

**Yes, the database side is sound.** These are not raw JSON blobs:
- 0 rows have JSON stuffed into a text field.
- Every field is plain text in its own column.
- Every translation is tied to an English row by a foreign key.
- Numbers are checked against the English text, and each translation carries a checksum of the English it came from, so stale translations can be detected.

It's a better design than translations hidden inside `record_json`.

**But the app never reads these tables, and it isn't meant to.** The app is offline-first:

```
catalog.content  ──(tools/build_catalog_release.py)──►  catalog_bundle.json.gz      (core, English + legacy localization)
                                                       catalog_pack_hi.json.gz     (Hindi text only)
                                                       catalog_pack_ta.json.gz     (Tamil text only)
        ──(tools/publish_catalog_release.py)──► Supabase Storage + admin.catalog_releases
        ──(app)──► LanguagePackManager loads the pack → MssEntity/Scheme.resolveText():
                   pack value → legacy record_json.localization → English
```

`catalog.content` and `catalog.language` have **no grants to anon/authenticated and no RLS policies**. That's correct: the app must not query them directly, because that would break offline use and the rate-limit design.

So "wiring to the app" means building and publishing the packs, not adding Supabase queries.

## 3. Current state of the wiring (verified in code)

| Piece | Status |
|---|---|
| `tools/build_catalog_release.py` builds core + `hi` + `ta` packs | ✅ Packs exist in `frontend/assets/catalog/` (hi 48 KB / 363 entities, ta 37 KB / 317 entities) |
| `LanguagePackManager` (load from cache, then from the shipped asset) | ✅ Exists; called from `AppStateProvider` on language change |
| Per-field fallback (pack → legacy block → English) | ✅ In `mss_entity.dart`, `scheme_model.dart`, `localized_scheme.dart` |
| `app_hi.arb` (1,429 UI strings) + Hindi in the language picker | ✅ Exists, **uncommitted** |
| **Downloading packs from the server** | ❌ `installPackBytes()` exists but **nothing calls it**. Packs only come from the APK assets. A Hindi fix needs a new app build; the report's "on-demand download" isn't wired. |
| **Kill switch** | ❌ `catalog.language.hi.is_active=false` only affects the build script. The hi pack is already in the assets and the picker always shows "हिन्दी", so **the next APK ships Hindi to everyone**. |
| Release | ❌ Not published. The live release is still 1.35.1-alpha (713,188 bytes, no pack files, `catalog_files.lang` all null). The local `release.json` also says `1.35.1-alpha`, but its bundle is 762,222 bytes with a different SHA, so local and server have the same tag with different contents. |
| Git | ❌ The two new migration files, all of `frontend/lib` (l10n, models, pack manager), the packs, the tools and the reports are uncommitted |

## 4. Data defects to fix before Hindi goes live

1. **One Hindi alias is wrong on 84 schemes.**
   - "पीएम विश्वकर्मा" (PM Vishwakarma) was copied into `aliases` of 84 `hi` scheme rows. That includes MCGS-MSME and 77 other published schemes, and 62 entities in the shipped hi pack.
   - It's also in `record_json.search.aliases.hi` for 83 schemes.
   - Effect: in Hindi, searching "पीएम विश्वकर्मा" returns ~84 schemes, and the exact-name lookup is polluted.
   - It looks like a copy bug, probably from the SCH000124 template.
2. **88 "Hindi" names are still English.**
   - All 83 institutions and 5 of the new authorities (AUTH000126–131) have an English name in the `hi` row, labelled `origin=machine, engine=google_translate`.
   - The report says all 131 authorities and 83 institutions were translated. They weren't.
   - Either translate them or delete those `hi` rows so the English fallback is explicit, not mislabelled.
3. **Gaps fall back to English mid-screen.** The 44 number-check failures were blanked, so Hindi users will see English paragraphs inside Hindi screens:

   | Field | Scheme `hi` rows missing it |
   |---|---:|
   | summary | 14 |
   | benefits | 19 |
   | eligibility | 9 |
   | how-to-apply | 29 |

   That's acceptable for a beta; just know it will happen.
4. **Nothing is verified.** All Hindi is machine output (`verified=false`). `docs/reports/unverified_hindi.csv` lists 1,788 fields. At minimum, a Hindi speaker should review the **names of the 155 published schemes** before launch. Google-translated scheme names are often literal translations rather than the official Hindi name.
5. **There are two copies of the translations.** The text is in `catalog.content` **and** in `record_json.localization` / `search.aliases.hi` (218 Hindi names; the report says these are regenerated for older app builds). They match today (0 mismatches on names for en/ta/hi). But any manual edit to `record_json` will drift from `content`.
   - Rule going forward: edit only `catalog.content` and regenerate everything else.
   - The report's claim that the original tables were left byte-identical isn't true any more. `record_json` was changed in P2/P3.
6. **The APK carries an extra ~743 KB.** Uncompressed `catalog_pack_hi.json` and `catalog_pack_ta.json` sit next to the `.gz` files, and `pubspec.yaml` ships the whole `assets/catalog/` folder.

## 5. How to take it live (in order)

1. Fix §4 items 1, 2 and 6 in `catalog.content` (a migration), then regenerate.
2. **Decide how the kill switch works in the app.** Either:
   - (a) hide "हिन्दी" in the picker unless the shipped `release.json.languagePacks` has `hi` **and** the current server release lists `hi` as active; or
   - (b) don't ship the hi pack in the APK and download it only when active.

   Option (a) is smaller.
3. **Wire the server download.**
   - On sync, read `admin.catalog_files where lang=…` through the existing release RPC or the signed-URL path the core bundle already uses.
   - Download the pack, then call `installPackBytes(lang, bytes, sha256)`.
   - Then a Hindi text fix only needs a release, not an app update.
4. Bump to **1.36.0-alpha**: build with `build_catalog_release.py` and publish with `publish_catalog_release.py`. Check that the pack rows land in `admin.catalog_files` with `lang` set and that their SHAs match the asset files.
5. Commit everything on its own branch (`feat/hindi-localization`), not on top of PR #111.
6. Hindi review of the 155 published scheme names, then `update catalog.language set is_active=true where code='hi'`, then a new release.

## 6. Prompt for Antigravity

```
Hindi localization follow-up. Paste command output for every claim; do not mark anything done
without the query/command beside it.

A. Data fixes (one migration, catalog.content is the only source you edit; regenerate
   record_json.localization/search.aliases from it with the existing generator):
   1. Remove the alias 'पीएम विश्वकर्मा' from every hi row except SCH000124 (expect 84 rows touched in
      catalog.content; 83 in record_json after regeneration). Find and fix the code that copied it;
      show the line.
   2. For hi rows whose name has no Devanagari (expect 88: 83 institutions + AUTH000126–131):
      translate the name (same number-check rules) or DELETE the hi row so English fallback is
      explicit. Never store English text with origin='machine'.
   3. List every hi scheme row with a null field among summary/benefits_text/eligibility_text/
      application_text (expect 71 fields: 14+19+9+29). Do not fill them now — just the list.
B. App:
   4. Language picker shows 'hi' only when LanguagePackManager has a valid hi pack AND the
      current release manifest lists hi as active. Add a widget test for both states.
   5. Wire server download: during catalog sync, fetch pack metadata (admin.catalog_files rows with
      lang) via the same mechanism used for the core bundle, download, call installPackBytes with
      the sha256, fall back to the asset pack on failure. Unit test: bad sha → rejected, old pack kept.
   6. Remove catalog_pack_*.json (uncompressed) from assets; only .gz ships.
C. Release: build + publish 1.36.0-alpha (not 1.35.1). Paste: admin.catalog_releases row,
   admin.catalog_files rows for the packs with lang set, sha256 of the asset files, and confirm
   release.json releaseTag = 1.36.0-alpha. Keep catalog.language.hi.is_active = false.
D. Git: new branch feat/hindi-localization from origin/main after PR #111 merges; commit the two
   migrations already applied remotely (20261005190312, 20261006020000) unchanged, the tools,
   frontend changes, and docs. No screenshots in git.
E. Export the 155 PUBLISHED scheme Hindi names (id, English name, Hindi name, origin, engine) to
   docs/reports/hindi_names_for_review.csv for human review. STOP.
```
