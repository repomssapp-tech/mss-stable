# Prompt 1: Hindi fix pass (local only)

Read first, in this order: `docs/claude docs/README.md`, then `docs/claude docs/MASTER_PLAN_hindi_localization.md`
(decisions D2, D8, D9, D15-D19; phases P2, P3, P7). Those files are read-only for you.

Rules: local only. Do NOT publish, flip current, push, or touch release 1.36.0-alpha. No secrets in output.
Paste raw output for every item. Use committed scripts for any change, never `python -c`. Stop on an unexplained error.

1. **Removals.** List all 39 Hindi fields removed between 1.35.1-alpha and 1.36.0-alpha (id, field, old text). For each: its
   `admin.translation_jobs` row (status), the origin of the old value, and the file:line that blanked it.
2. **Restore (D8, D9).** Restore the 39 values from the 1.35.1-alpha bundle into `backend/catalog/source` with a committed script,
   then rebuild `catalog.content` through the normal import. If a restored value fails the number check, keep it and flag it for review.
3. **Name changes.** Show the 2 Hindi name changes (SCH000271, SCH000280) and the 2 whitespace trims (SCH000076) for human review. Do not revert.
4. **Non-Devanagari text.** For all 8 Hindi text fields (not only name) in `catalog.content` and in the hi pack, count and list ids
   whose text has no Devanagari. Also list `translation_jobs` rows where translated_text = source_text but status is COMPLETED.
5. **Gate and generator fixes (D17, P7 item 2).**
   (a) `release.json.perFileSha256` must hash the exact stored bytes; prove it on one file.
   (b) `release_gate.py`: G1 compares content and reads `catalog.content`; G2 covers every catalog file plus `search.aliases` and
   `search.keywords` and reports added/changed/removed; G5 hashes the objects downloaded from storage.
   (c) Declarations must state `diffTypes`; a wildcard defaults to `added` only.
   Add self-tests: T8 a wildcard "added" declaration must still FAIL on a removal; T9 a content drift must FAIL.
6. **Coverage.** Classify the 21 active schemes that have no Hindi in the pack as central or state (id, English name).
   The ids: SCH000001 002 003 004 008 017 028 047 048 074 084 093 098 105 107 115 181 183 185 200 213.
7. **Failing tests.** Run the 2 failing tests 3 times each, alone, on a clean `origin/main` worktree and on the branch:
   `test/guards/color_tokens_test.dart` and `test/scheme_understanding_corpus_test.dart`. For the second, paste the real threshold
   and the measured times.
8. **Commit hygiene.** Show which commits hold the four `search_taxonomy.json` copies. Revise the split proposal to include them.
   Do not run it. Do not commit `docs/reports/gate_1.36.0-alpha.json` (it compared a folder to itself).
9. **Candidate.** Build 1.36.1-alpha into a scratch folder only. Run the gate against 1.35.1-alpha and against 1.36.0-alpha and paste
   the full reports. Do not write a declaration; the owner supplies it.

STOP and report. Use the report template in the plan.
