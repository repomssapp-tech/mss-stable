# DEV 1: backend tasks 1.2, 1.3 and 1.4 (mss-backend)

Handoff written 2026-11-20. Tasks 1.1 and 1.5 are done in `MSS_App`. These three tasks need the `mss-backend` repository. That code is not on this machine or in the `Roger-Chris` GitHub account. `backend/README.md` says the server "lives in the separate `mss-backend` project".

Read this together with `DEV1.md` and `DEV-SHARED.md`. Those set the tasks; this file gives what is already decided in `MSS_App`, so the backend matches it.

## Before you start

- [ ] Get the `mss-backend` repository (path or GitHub URL) and access to it.
- [ ] Find out what "the MSS sync (see `CLAUDE.md`)" in `DEV1.md` means. Neither `CLAUDE.md` nor `AGENTS.md` in `MSS_App` describes it.
- [ ] Merge PR #201 first. It adds `questionnaire.json` and the keyed rules that 1.2 and 1.3 read: https://github.com/Roger-Chris/MSS_App/pull/201

Order, from `DEV1.md`: 1.2 and 1.4 in parallel, then 1.3.

## Inputs already in MSS_App (PR #201)

| File | What it is |
|---|---|
| `backend/catalog/msme_maharashtra_dataset_schema.csv` | Officials' 26 questions in en/mr/hi. UTF-8 **with BOM**: read as `utf-8-sig`. Byte-exact copy, marked `-text` in `.gitattributes`. |
| `backend/catalog/msme_maharashtra_eligibility_rules.json` | Officials' rules for CMEGP, PMEGP, PSI-2019, MUDRA and the MSME limits (April 2025). Byte-exact copy, never edited. |
| `backend/catalog/questionnaire.json` | Generated. The only source for questions, option value keys and answer shapes. |
| `backend/catalog/eligibility_rules.keyed.json` | Generated. The rules with every option display text replaced by its value key. Use this file in the engine, so no rule matches display text. |
| `backend/scripts/build_questionnaire.py` | Builds both generated files. `--check` fails if they are stale. CI runs it in `.github/workflows/questionnaire.yml`. |

### Value keys

Value keys are slugs of the English option text. They are stable and never translated. `+` becomes `plus` and `%` becomes `pct`.

Examples:
- `not_started_yet_aspiring`
- `3_plus_years`
- `7th_9th_pass`
- `0_5_pct`
- `village_rural`
- `city_urban`

### Answer shapes

Each field in `questionnaire.json` lists its own answer shape. Store and validate against these:

| Type | Fields | Answer |
|---|---|---|
| `single_select` | most | one value key, e.g. `"manufacturing"` |
| `multi_select` | `social_category`, `scheme_goal`, `special_focus_zone`, `assistance_needed`, `existing_registrations`, `aspiring_readiness_stage` | list of value keys |
| `boolean` | `family_prior_subsidy` | `true` / `false` |
| `boolean_with_district` | `is_maharashtra_domicile` | `{resident: bool, district: string}` |
| `location` | `business_location` | `{area: value key, district: string, taluka: string}` |
| `number` | `owner_age` | integer, 18–99 |
| `number_pair` | `employee_count_total_women` | `{total: int, women: int}` |
| `text_tags` | `product_keywords_or_nic` | list of strings |

**To confirm with DEV 2:** the `business_location` shape `{area, district, taluka}`. I chose it because `DEV-SHARED.md` does not define one.

## 1.2 Eligibility engine

Build pure functions: `evaluate(profile, scheme) -> {eligible, failed_rules[], boosters[], tier / subsidy %}`. Place them in `src/profiles` or a new `src/eligibility`, and read `eligibility_rules.keyed.json`.

### What to implement
- **Operators:**
  - `equals`, `in` and `any`.
  - `min` / `max`, where a `null` max means no limit.
  - `required`, `required_at_disbursement` and `recommended_for_kishore_and_above`.
- **Education order:** `below_7th_pass` < `7th_9th_pass` < `10th_pass` < `12th_iti_diploma` < `graduate_or_above`.
- **Education rules by project cost:** the CMEGP and PMEGP `conditional_rules`. PMEGP's rules also carry `if_sector`, which is a `business_nature` key.
- **Age relaxation:** CMEGP `owner_age` is 18–45 in general and 18–50 when `applies_when_any` matches.
- **Subsidy %:** `margin_money_subsidy_percent` is rural/urban × general/special. Its `based_on` names `business_location`, `owner_gender` and `social_category`, and none of them is a rule key, so the engine must handle all three.
- **Reasons:** return keys only. The app holds the text, in en/mr/hi.

### Tests
- One passing and one failing profile per scheme: CMEGP, PMEGP, PSI-2019, MUDRA.
- Age edges at 45, 46, 50 and 51.

### Mappings the engine has to choose: note each one and confirm with the officials
- **Project cost:** the questionnaire never asks for it. Derive a band from `machinery_investment_inr` (DEV-SHARED gap 4).
- **Own contribution:** the rules use `min_percent` 10 (general) and 5 (special). The options are bands: `0_5_pct`, `5_10_pct`, `more_than_10_pct`, `need_100_pct_support`. Decide which bands pass each minimum.
- **Rural or urban:** `village_rural` means rural and `city_urban` means urban. **`town` is not defined.**
- **"Special" for subsidy %:** not defined in the file. The closest list is CMEGP's age-relaxation `applies_when_any`: `woman`, `sc`, `st`, `person_with_disability_divyangjan`, `ex_serviceman`. Confirm before reusing it.
- **`max_project_cost_inr` keys:** they are display-like (`Manufacturing`, `Services`, `new_unit_manufacturing`, …) and were not keyed. Map them to `business_nature` yourself.

### Rule values to flag to the officials (do not change them)
- **PMEGP:** `business_age` allows `not_started_yet_aspiring` only. But its boosters include `expand_existing_business`, and its note allows upgradation (DEV-SHARED gap 2).
- **PSI-2019:** the `in` lists for `machinery_investment_inr` and `annual_turnover_inr` contain every option, so they never exclude anyone.
- **Source links:** the PSI-2019 and MUDRA `source_url`s are not official pages (gap 3).

## 1.3 Profile storage

- [ ] Add the 26 answers to the profile model and write a DB migration in `mss-backend/database`, using the shapes above.
- [ ] Multi-selects store lists of value keys. `employee_count_total_women` stores two ints, and the domicile stores a district.
- [ ] Validate every write against `questionnaire.json`. Reject unknown value keys, ages outside 18–99, and wrong shapes.
- [ ] Keep the old profile fields working until the app migrates: map old to new, and drop nothing.
- [ ] Update the OpenAPI spec and `API_DOCUMENTATION.txt`. The copy in `MSS_App/backend/New API Ref/` needs the same update.

## 1.4 Guest mode: backend

### Token
- Short-lived and read-only, with no PII.
- A separate **`guest` scope**.
- Reuse the pattern of the existing support guest session, but keep the two tokens apart:
  - The existing one is `POST /v1/support-tickets/guest-session`: public, returns `{guest_token, expires_at}`, lasts 24 hours, and is limited to 10 per minute per IP.
  - The app sends it as `X-Support-Guest`, and the docs say it "cannot authenticate /me or schemes".
  - A support token must never work as a guest token, and a guest token must never work as a support token.

### Allowed
- Browse and search schemes.
- Run eligibility on answers sent in the request. Nothing is stored.
- Saarthi, with limits.

### Blocked
- Saving to the server.
- Notifications.
- Profile sync.
- Support tickets under a user id.

### Other requirements
- **Rate limit:** by IP or device.
- **Upgrade path:** after sign-up, the guest's answers are posted once, then discarded on the server.
  - The app expects the route recorded in `frontend/lib/services/backend/pending_endpoints.dart`:
    ```
    POST /v1/me/guest-upgrade   {answers: {field_id: value}}
    ```
  - This path is an assumption. If the backend uses a different one, change `PendingEndpoints.guestUpgrade` to match.

### Tests
- A guest token cannot reach any write endpoint.
- An expired guest token returns a clear error code.
- A support token is refused where a guest token is needed, and the other way round.

### What the app does today (from the PR #202 and #204 work)
- Guest browsing, search and recommendations run on the offline catalog with no token, and there is no guest-token call yet. Add one in the app once the route exists. Likely first users: Saarthi and eligibility.
- Saving, notifications and profile sync are blocked in the UI: the "Sign in to use this" sheet.
- **After sign-in from guest mode:**
  - The app sends the guest's profile once through the existing profile write, tracked by the pref `guestAnswersUploadPending`.
  - The call to `/v1/me/guest-upgrade` is not wired yet. It needs this route and DEV 2's on-device questionnaire answers store.

## Definition of done (from DEV1.md)

- [ ] Backend unit tests are green, and a signed-in user is unaffected.
- [ ] One PR per task, each saying what was run and what was not verified.
- [ ] OpenAPI and `API_DOCUMENTATION.txt` are updated.
- [ ] Open items above are listed in each PR for the officials.
