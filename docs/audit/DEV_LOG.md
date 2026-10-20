# Developer Change Log

Append-only log of merged PRs, keyed by GitHub username. Rows below "Automated entries start here" are appended automatically by `.github/workflows/dev-log.yml` when a PR merges into `main` — do not edit them by hand; fix mistakes with a follow-up PR instead. Rows above that line are a manual backfill from git history, added when this log was created.

See `docs/RULES.md` §4 for the rule this log enforces.

| Date | GitHub user | PR # | Area | Summary |
|---|---|---|---|---|
| 2026-09-12 | Roger-Chris | #100 | onboarding | Onboarding restructure (merge 1 of 2). |
| 2026-09-13 | Roger-Chris | #101 | onboarding | Onboarding restructure (merge 2 of 2). |
| 2026-09-13 | Roger-Chris | #102 | backend/edge-functions | Cleanup of on-device SLM experiment and superseded edge functions. |
| 2026-09-13 | Roger-Chris | #103 | docs | Removed 36 unused, obsolete, and historical markdown files. |
| 2026-09-13 | Roger-Chris | #104 | docs | Flattened docs structure to one level; reconciled architecture docs against code. |
| 2026-09-13 | Roger-Chris | #105 | backend/tooling | Removed redundant root `package.json`/`package-lock.json`. |

<!-- Automated entries start here — .github/workflows/dev-log.yml appends below this line -->
| 2026-09-13 | Roger-Chris | #107 | unspecified | Chore/audit rules skills devlog |
| 2026-09-17 | PaulBrytonRaj18 | #109 | frontend/companion_mode | Replaced the static marketing welcome screen with an accessible, zero-keyboard 6-step Assisted Profile Creation wizard for AI Companion Mode that feeds directly into the scheme recommendation engine, and resolved PostgreSQL check-constraint failures during cloud profile submission. |
| 2026-10-02 | Roger-Chris | #110 | unspecified | Production readiness: correctness, design system, accessibility (Phases 1–2, partial 3) |
| 2026-10-05 | Roger-Chris | #111 | unspecified | This PR delivers the complete, verified, and locked remediation of **MSME Catalog v3.1** (promoted to **Release `1.35.1-alpha`**), resolving all audit findings from `docs/audit/CATALOG_V3_1_AUDIT.md`, executing all remediation phases from `docs/audit/ANTIGRAVITY_FIX_PROMPT.md`, and completing the final verification housekeeping items from `docs/FINAL_VERIFICATION_1_35_1.md`. |
| 2026-10-17 | praveen-ofl | #113 | unspecified | feat(api): integrate MSS REST backend client, auth PKCE flow, and pro… |
| 2026-10-18 | Roger-Chris | #112 | unspecified | - Hindi UI localization across the app: language-aware translator + Hindi dictionary, ARB moves for hardcoded strings (en/ta/hi), Devanagari font, Home language menu, Hindi in the picker/Settings, Hindi activated in the release manifest. |
| 2026-10-19 | Roger-Chris | #114 | unspecified | - Replace Supabase with the MSS REST backend (`https://api.msmeschemes.org`) for auth, profile, onboarding, notifications, promotions, favorites and support tickets. Old Supabase material is archived in `docs/old_supabase/`. |
| 2026-10-19 | Roger-Chris | #115 | unspecified | fix(saarthi-agent): sort imports and apply ruff format to pass CI |
| 2026-10-20 | Roger-Chris | #116 | unspecified | Feat/multilingual search recommendations |
| 2026-10-20 | Roger-Chris | #117 | unspecified | Feat/multilingual search recommendations |
| 2026-10-20 | praveen-ofl | #118 | unspecified | feat(api): integrate push and sse notifications, password dialogs, an… |
