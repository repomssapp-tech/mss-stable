# docs/claude docs: planning files written by Claude (planner/reviewer)

Repo root: `C:\development\MSS App\MSS_App`. This folder: `docs/claude docs/` (the path contains a space, so quote it).
Owner/approver: Roger. Executor: Antigravity. Planner/reviewer: Claude.

## Current files (authoritative)
| File | What it is |
|---|---|
| `MASTER_PLAN_hindi_localization.md` | The plan: decisions D1-D19, phases P0-P8, what is accepted and what is open. **Revision 5.** Supersedes the older copy at `docs/MASTER_PLAN_hindi_localization.md`. |
| `HINDI_SEARCH_ACCEPTANCE.md` | The 20 Hindi search queries, controls, pass mark and rules (version 2). |
| `hindi_search_queries.json` | Machine-readable copy of the same. The search test must be generated from this file. |
| `PROMPT_1_fix_pass.md` | Next task: fix pass after the release review (local only, no publish). |
| `PROMPT_2_search_acceptance.md` | Later task: run the Hindi search acceptance. Start only after Prompt 1 has been reviewed. |

## `archive/` (history, already executed; do not run)
`00_TASK_language_tables.md` and `lang_*.sql` were the first-phase task (audit, dry run, apply). The table was applied as the migration `content_table`; these copies are kept for reference only.

## Rules for the executor
1. Files in this folder are **read-only for you**. If something here is wrong or blocks you, say so in your report; do not edit it.
2. Do not start a prompt until the owner tells you to.
3. Evidence rules from the plan apply: paste raw output, paste the SQL you actually ran, `NOT RUN` when not run, stop on errors, no secrets in output.
4. If this folder and an older copy elsewhere in the repo disagree, this folder wins; report the difference.
