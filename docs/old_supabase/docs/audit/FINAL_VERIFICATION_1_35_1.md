# Final verification: catalog release 1.35.1-alpha

**Checked:** 2026-10-05, against:
- the live Supabase database
- the shipped bundle `frontend/assets/catalog/catalog_bundle.json.gz`
- branch `data/catalog-v3-1-migration` (PR #111), compared with `origin/main`

I didn't trust the report's own numbers. Every ✅ below comes from my own query or script.

## Verdict

**The catalog migration is now correct.** The audit and Gate B defects are fixed in the database and in the bundle.

Before merging PR #111, three housekeeping items remain (§2). They don't affect what users see. §3 lists product points to be aware of.

## 1. Verified fixed

| Item | Live result |
|---|---|
| Release | `1.35.1-alpha` current, SHA `cea438e9…`, 713,188 bytes, 171 schemes in bundle |
| Status contract | Only `PUBLISHED/true/active` 155, `DRAFT/false/unknown` 131, `ARCHIVED/false/closed` 16. No "archived" left |
| Parent/child | child_of 85 / parent_of 85, **0 asymmetric** |
| Successors | DAY-NULM ↔ DJAY-S (SCH000302); IES ↔ SCH000258, both directions |
| Duplicates (D1–D3) | SCH000055 → SCH000095, SCH000064 → SCH000038 (`merged_into`; the report says `duplicate_of`, which is wrong but harmless); SCH000168 → SCH000218 (`duplicate_of`); SCH000082 child of SCH000035 |
| Record shape | 0 schemes with top-level `classification`; 0 missing `content.classification`; 0 NULL `scheme_type`/`government_level`/`ministry` on new rows |
| Invented age rules | Gone: 11 age gates, which matches the 11 source records with an age (was 83) |
| Invented Udyam rule | Gone: 9 schemes, down from 83 |
| PM Surya Ghar | Enterprise facet no longer applies; beneficiaries include `individual` |
| Target beneficiaries | Filled on 81/83. The 2 empty ones (SCH000228, SCH000232) have none in the source either |
| Verification honesty | 0 `isVerified=true`; 32 verified / 45 partially / 6 unverified, taken from the source confidence |
| 59 placeholder objectives on old schemes | Reverted (59 null again) |
| Ministries | 10 schemes now resolve to 7 new authority rows (AUTH000125–131) with the standard record shape |
| CGTMSE | `maxCoverInr` ₹10 crore |
| ".." joins in criteria | 0 |
| Bundle integrity | 171 schemes / 171 matrix rows / 930 search rows; 0 dangling scheme references; state-scheme locations unchanged from main |
| Staging tables | Dropped; `scheme_source_v3_1` kept (393 rows) |
| `create_scheme_draft` | `anon` EXECUTE = false; no longer flagged by the advisor |
| Tests | The weakened assertions from 1.35.0 (hard-coded 251, "archived stays active") are gone. New contract and screen tests were added |
| Git | Branch rebased onto `origin/main`: 5 commits, no `frontend/lib` changes, `graphify-out` in `.gitignore`, `CLAUDE.md`/`.gitattributes` not touched |

## 2. Fix before merging PR #111

1. **The migration history was made to match by deleting remote records, not by restoring files.** The remote history no longer lists 5 migrations that are recorded as applied:
   - `20260905150256_publish_release_1_34_0_alpha`
   - `20260905160607_add_mss_team_test_scheme`
   - `20260905161148_publish_release_1_34_1_alpha_test_scheme`
   - `20260905163012_remove_mss_team_test_scheme`
   - `20260905163332_publish_release_1_34_2_alpha_cleanup`

   The "83/83 parity" was reached by removing them. Their effects are still in the database; only the audit trail was lost.

   **Fix:** look for the files in git history (`git log --all -- '*publish_release_1_34*' '*mss_team_test_scheme*'`). Restore them to `backend/supabase/migrations/`, then `supabase migration repair --status applied <version>` for each. If they can't be found, add a short `docs/runbooks/migration_history_note.md` that records what they did and why they're absent.
2. **22 MB of screenshots (89 PNGs) are committed in `reports/screenshots/`.** That permanently bloats the repo.
   - Remove them from the branch (`git rm -r --cached reports/screenshots` plus a `.gitignore` entry) before merging, and squash.
   - Attach the 6–8 key ones to the PR description instead.
3. **The search-ranking fixture was regenerated without a review.** `scheme_search_rank_stability_expected.json` has +9,018 lines.
   - Ask for the top-5-per-query diff between `origin/main` and HEAD for the golden queries, and confirm no important scheme dropped out of its query.
   - The report's "0 diffs" only means the Dart and Python engines agree with each other.

## 3. Product points to be aware of (decisions, not defects)

- **Hiding drafts (D4) shrank the app from 219 visible schemes to 171.**
  - 109 older DRAFT schemes are now hidden, including **44 Tamil Nadu state schemes**. Only 16 TN state schemes remain visible.
  - Anyone who had saved one of the hidden schemes will lose it from Saved. Check that the Saved tab handles a missing ID without an error.
  - If you want those TN schemes back, the next step is reviewing and publishing them, not un-hiding drafts.
- **Discover counts include the 16 closed schemes.** "Uttar Pradesh: 155" counts closed schemes such as DAY-NULM and IES. This is older behaviour, but worth filtering to active.
- **URL check: only 3 of 83 new-scheme links returned 200.** 45 were blocked (401/403) and 35 timed out from the test machine. That proves nothing either way. Spot-check the 61 published ones by hand in a phone browser, starting with the ones flagged `app_relevance: high`.
- **Tamil:** none of the 61 published new schemes have Tamil (your choice in D5), so Tamil-mode users see them in English.
- **Hindi:** the data is in the catalog, but the app has no Hindi locale yet. The report's 4-step roadmap for adding one is accurate.
- **Remaining security advisor warnings** (none from this work):
  - `check_support_ticket_rate_limit` is callable without signing in.
  - Leaked-password protection is off; it's a dashboard toggle (Auth → Passwords).
  - `mss_current_release` (anon) and `delete_user` (authenticated) look intentional.

## 4. Short prompt for Antigravity (the §2 items only)

```
Catalog 1.35.1 is verified; do NOT change catalog data. Three housekeeping items on
data/catalog-v3-1-migration, each with command output pasted:

1. Migration history: the remote history no longer lists 20260905150256, 20260905160607,
   20260905161148, 20260905163012, 20260905163332. Search git history on all branches for those
   files; restore them into backend/supabase/migrations/ unchanged, then run
   `supabase migration repair --status applied <version>` for each and paste
   `supabase migration list`. If a file cannot be found, do not invent its SQL — write
   docs/runbooks/migration_history_note.md listing it and STOP.
2. Remove reports/screenshots/ from the branch (git rm -r --cached, add to .gitignore). Keep
   them locally. Pick the 8 most important screenshots and list their paths so Kishaunjith
   can attach them to the PR.
3. For frontend/test/fixtures/scheme_search_rank_stability_expected.json: print, for every
   query in the fixture, the top-5 scheme names on origin/main vs HEAD side by side, and flag
   any query whose previous #1 result is no longer in the top 5. Do not regenerate anything.

Then update the PR description and stop.
```
