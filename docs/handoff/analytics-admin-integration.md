# Mobile analytics in the existing admin site

This handoff is for the backend and admin engineers. Add an Analytics section to the existing admin site. The companion [API contract](../backend/mobile-analytics-api.md) is proposed. The mobile app currently emits only opt-in Smart Assessment QA logs for synthetic runs. Production charts should show **Awaiting instrumentation** until the API is deployed, consent is configured and the corresponding app version has shipped.

## Reports and measurement

| Admin view | What to show | Evidence and limits |
|---|---|---|
| Reach and engagement | Daily, weekly and monthly active installs, sessions, returning installs, sessions per install, feature entry counts | Count distinct opted-in install IDs in the selected window. An install can be reset or shared. Recompute uniques over the whole window instead of adding daily uniques. |
| Discover and search | Searches by source, zero-result rate, result-count distribution, common catalog topic keys, screen-to-detail conversion, first opened rank, facet usage | Search executes on device. Capture the displayed count and an optional catalog taxonomy key. Link scheme opens by search interaction ID. Search intent is unknown if no known topic matches. |
| Scheme interest | Details opened by scheme and entry point, saves, apply-link launches, detail-to-apply conversion | An external link launch indicates outbound interest. The app cannot see an application submission, decision or payout. |
| Smart Assessment | Starts, completions, abandons, per-question reach and skips, median viable results, zero viable results, no Good fit, opens by fit group | Use an assessment interaction ID. Report only fields and action counts. For interrupted runs without a close event, mark abandonment after the agreed inactivity window, with the last observed step. Good fit and Might fit are app ranking labels. |
| Account and guest flows | Guest visits, sign-in prompts by feature, accepted prompts, successful sign-ins, guest-to-account conversion, save/alert access | Keep mode at event time. Attribute an upgrade only when the client observes sign-in after a guest flow. Guest identity and questionnaire answers stay outside the initial telemetry contract. |
| Profile completion | Starts, section reached, section saved, completion rate, time to finish, resume, sync failure category | Use section keys for basic details, location, about you and eligibility. Count confirmed cloud saves separately from local draft saves. Never include the form values. |
| Catalogue health | Catalog release mix, local load failure rate, retry outcomes, fallback frequency | Only include error codes from an allow-list. A missing signal cannot distinguish a healthy install from an install with telemetry off. |
| Onboarding and accessibility | Language and mode selection, tour started/completed/skipped, screen or flow drop-offs, coarse accessibility feature usage if approved | Use explicit app events. Language, mode and platform are descriptive dimensions. Avoid collecting OS settings unless specifically approved. |
| Performance and integrations | Coarse startup and search latency bands, auth or sync outcome rates, notification permission outcomes, delivery/open rates, Saarthi entry and outcome | Device durations are reported by coarse buckets. Use server/provider records for delivery. Separate permission denied from a delivery failure. Never collect transcripts, debug payloads or permission contents. |
| Eligibility usage | Checks started/completed, rule-key failure counts, outcome counts and open-to-check conversion | Enable after the eligibility engine lands and the events have an approved payload. Pre-screening is distinct from an official decision. |

Break down the first release by date, app version, platform, language, regular/companion mode and guest/signed-in mode. Roll out state-level reporting only after approval for the source and granularity. Later, review opportunities for district and broad profile cohorts against the data actually collected and the consent in force. Report unknown explicitly. Do not infer caste, income, age, gender, geography or business activity from names, browsing, language, IP addresses or free text. Raw query text and demographics are outside the initial API.

## Build and release order

1. Implement ingest, idempotent storage and aggregate queries using the API contract. Schedule aggregation in the backend and expose only aggregates through the existing admin authorization. Restricted source data should remain server-side.
2. Start with Reach, Discover, Scheme interest, Smart Assessment and Profile. Track event coverage by app version, known consent scope and schema version. Show delayed uploads and withheld groups as separate conditions from genuine zeros.
3. Apply a minimum of 10 distinct installs per released cell as the proposed initial rule. Confirm the threshold before launch. Suppress complementary cells and totals where subtraction would reveal a suppressed count. Apply the same rules to downloads and all filter combinations.
4. Roll up by event date in Asia/Kolkata and show that timezone in the UI. Store timestamps in UTC and keep receipt time separately. Reprocess late arrivals within the accepted window. Include numerator, denominator, sample size and measured date window wherever a rate appears.
5. Validate with synthetic fixtures across both modes: duplicate retries do not inflate metrics, profile sections count correctly after a resume, rankings sum to the displayed result counts, anonymous search correlation stays scoped to one search, and small cells remain suppressed in exports. Include revoked consent, account deletion and guest-to-sign-in transitions.
6. Ship behind a release flag after privacy and consent review, on a staged app rollout. Use a synthetic admin tenant for QA and confirm chart totals against known fixtures before treating them as decision data.

Existing backend logs may support service volume and errors if source coverage is known. They cannot recover historical on-device searches, answer progress or offline browsing. Funnel comparisons start when the corresponding client events ship.
