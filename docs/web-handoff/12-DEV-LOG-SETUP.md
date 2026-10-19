# Per-Developer Change Log — setup for mss-web

This mirrors a system already live and working in the main app's repo (`docs/audit/DEV_LOG.md` + `.github/workflows/dev-log.yml`), which auto-appends one row per merged PR keyed by the **GitHub username from the PR event** — not the local git commit email, which was found to vary per developer machine and isn't a reliable identity key once more than one person is committing.

## Why GitHub username, not git email

A merged PR's `pull_request.user.login` is the actual GitHub account that opened it — stable regardless of what email/name is configured in that developer's local `git config`. This matters as soon as a second developer joins the project; local emails are not guaranteed unique or consistent across machines, but GitHub logins are.

## Setup (one-time, when the mss-web repo exists)

1. Copy the three template files from `assets/dev-log/` in this handoff package into the new repo:

   ```bash
   mkdir -p .github
   cp path/to/docs/web-handoff/assets/dev-log/dev-log.yml .github/workflows/dev-log.yml
   cp path/to/docs/web-handoff/assets/dev-log/pull_request_template.md .github/pull_request_template.md
   cp path/to/docs/web-handoff/assets/dev-log/DEV_LOG.seed.md docs/DEV_LOG.md
   ```

2. **Edit `dev-log.yml`'s `LOG_FILE` variable** (marked `# EDIT ME`) if `DEV_LOG.md` ends up somewhere other than `docs/DEV_LOG.md` in the new repo's structure.

3. Commit and push all three files in one PR — merging that PR is itself the first entry the workflow will log (for every PR *after* this one; the setup PR itself has to be logged manually as a seed row if you want it recorded, same as the main repo backfilled its own history).

4. Confirm the workflow's `permissions: contents: write` is actually allowed — some org-level GitHub Actions settings restrict write permissions by default; if the workflow fails on its first real run with a permissions error, check Settings → Actions → General → Workflow permissions.

## How it behaves once live

- Every PR merged into `main` triggers the workflow.
- It reads the PR's `## Area` / `## Summary` sections (from the PR template) and falls back to the PR title if the template wasn't filled in.
- It appends one row to `DEV_LOG.md` and commits/pushes that single-line change back to `main` as `github-actions[bot]`.
- **Don't hand-edit rows below the "Automated entries start here" marker** — fix mistakes with a follow-up PR, the same rule as the main repo, so the log stays a trustworthy append-only record rather than something people quietly edit after the fact.

## What this does NOT do

- It doesn't gate merges (no CI check blocking a PR without a filled-in template) — it's a record-keeping tool, not an enforcement mechanism. Add a required-status-check separately if the team wants the Area/Summary fields to be mandatory rather than best-effort.
- It doesn't log anything for direct pushes to `main` (if branch protection ever allows those) — only PR merges are captured.
