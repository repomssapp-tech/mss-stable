# In-app analytics backbone: plan

For the current implementation handoff, use [analytics in the existing admin site](../handoff/analytics-admin-integration.md) and the [proposed mobile analytics API](../backend/mobile-analytics-api.md). The plan below is the earlier design discussion. Its broader collection proposals are outside the initial API.

Written 2026-11-21. **Plan only, no code yet.** App side: this repo. Server side (ingest route, tables, reports): the other dev's `mss-backend` work. The server parts below are a proposed contract, like `PendingEndpoints`.

Names follow the app's own identifiers:
- questionnaire `field_id`s and value keys from `backend/catalog/questionnaire.json` (PR #201),
- catalog scheme `id`,
- ISO state codes (`IN-MH`),
- app language codes (`en`, `hi`, `mr`, `ta`).

## 1. What the officials want to know

| # | Question | Metric |
|---|---|---|
| Q1 | How many people use the app (**footfall**)? | Daily, weekly and monthly active installs and sessions, split guest / signed-in, by language, state and mode (regular / companion) |
| Q2 | **Most searched schemes** | (a) top normalised search queries; (b) schemes opened from a search result; (c) schemes viewed by any route; (d) apply-link taps per scheme; (e) zero-result queries |
| Q3 | **Who searched what** | Q2 cut by the profile dimensions in §3, e.g. top schemes viewed by `owner_gender = woman` and `business_location.area = village_rural` in a district |
| Q4 | What people are looking for | `scheme_goal` and `assistance_needed` mix by district, `business_nature` and `business_age` |
| Q5 | Where the funnel loses people | Search, then result, then scheme opened, then eligibility checked, then apply link. Plus guest to sign-in, and from which prompt. |

"Most searched scheme" needs all of Q2 (a–e). Searches are free text, so the scheme a person wanted is only certain once they open it.

## 2. Constraints that shape the design

1. **Search runs on the phone.** It works offline against the catalog bundle, so the server never sees a query. Every event is sent by the app. Events queue on the phone and go up in batches. Nothing on the search, browse or recommendation path waits on the network (AGENTS.md invariant 1).
2. **Nothing collects the 14 features yet.** The 26-field questionnaire is on PR #201, but its UI (DEV 2) and the answers store (goal 8 in the guest UX plan) are not built. So:
   - **Phase 1** uses the profile fields that exist today (§3, "available now").
   - Demographic cuts on the new fields come in **phase 2**.
3. **Guests.** The current agreement keeps guest answers on the device, and the guest token has no PII (DEV-SHARED, DEV1 1.4). Sending guest demographics to the server would break that. **Decision A**.
4. **Privacy (DPDP Act 2023).**
   - The privacy policy (`privacy_policy_screen.dart` §1–2) lists "limited device, security, diagnostic or usage information … for secure and reliable operation". It gives no analytics or reporting purpose.
   - Linking searches to gender, social category or domicile needs:
     - a new policy version that names the purpose (aggregate reports to the scheme departments),
     - re-acceptance through the existing `POST /v1/me/legal-acceptances` versioning,
     - a consent switch in Settings.
   - Legal review is required before anything ships. **Decision B**.
5. **No raw identity in analytics.**
   - No name, email, phone, Aadhaar, PAN or exact address.
   - Free text (`product_keywords_or_nic`, search queries) is never tied to a user id.
   - Reports suppress any cell with fewer than **10** people (**Decision C** for the exact number).
6. **Deletion.** `DELETE /v1/me` must also remove the link between that user and their events. Aggregates already computed stay.

## 3. Dimensions: the 14 features in app names

| Feature (officials' words) | App `field_id` | Values (keys) | Available now? |
|---|---|---|---|
| Gender | `owner_gender` | `woman`, `man`, `other` | Yes, as `UserProfile.gender` (needs mapping) |
| Demography | no single field: `social_category`, `owner_age` (sent as a band: 18–25, 26–35, 36–45, 46–50, 51+), `education_level` | `general`, `sc`, `st`, `obc`, `minority`, `person_with_disability_divyangjan`, `ex_serviceman` | Partly: `UserProfile.community`, `dob`, `educationLevel` |
| Place of domicile | `is_maharashtra_domicile` | `{resident, district}`; district as LGD code | No |
| Place of business | `business_location` | `area`: `village_rural`, `town`, `city_urban`, plus district and taluka | Partly: `UserProfile.state`, `district` |
| Nature of business | `business_nature` | `manufacturing`, `services`, `trading_retail`, `agro_food_processing` | Partly: `UserProfile.businessIndustry` |
| Kind of scheme wanted | `scheme_goal` | `start_a_new_business`, `expand_existing_business`, `buy_machinery_upgrade_tech`, `daily_working_cash`, `marketing_export` | No |
| Age of business | `business_age` | `not_started_yet_aspiring`, `less_than_1_year`, `1_3_years`, `3_plus_years` | Partly: `UserProfile.businessStage` |
| Organisation structure | `org_structure` | `sole_owner_proprietorship`, `partnership`, `pvt_ltd`, `llp`, `co_operative`, `self_help_group_shg`, `not_registered_yet` | No |
| Special category (e.g. tribal area) | `special_focus_zone` | `tribal_area`, `aspirational_district`, `backward_taluka`, `industrial_estate_midc`, `none` | No |
| Assistance wanted (finance, technology, manpower, marketing) | `assistance_needed` | `money_loans_subsidy`, `machines_technology`, `hiring_staff_training`, `finding_buyers_marketing` | No |
| Digital literacy | `digital_literacy_level` | `basic_whatsapp_upi_only`, `moderate_can_fill_online_forms`, `advanced_accounting_e_commerce` | No |
| GI tag | `has_gi_tag` | `yes`, `no`, `not_sure` | No |
| Cluster or stand-alone | `cluster_membership` | `part_of_a_cluster`, `independent_stand_alone_unit`, `not_sure` | No |
| Export oriented | `export_status` | `yes_currently_exporting`, `planning_to_export`, `domestic_india_only` | No |
| Aware of tax laws | `tax_compliance_comfort` | `comfortable_with_taxes`, `need_basic_guidance`, `handled_by_a_ca_accountant` | No |

**Context dimensions, on every event:**
- `app_language`
- `nav_mode`: `regular` or `companion`
- `user_kind`: `guest` or `signed_in`
- `state_code`: from the profile or the guest state (`guestStateFor`)
- `app_version`, `platform`
- `catalog_release`: e.g. `schemes-8`

**Not used as dimensions:**
- money fields (`machinery_investment_inr`, `annual_turnover_inr`), until officials say they need them;
- `employee_count_total_women` (sent as a band only if needed);
- `product_keywords_or_nic` (free text).

## 4. Identity and sessions

- **`install_id`:** a random UUID created on first launch. It survives sign-out, like the tour records.
- **`session_id`:** a new id after 30 minutes in the background or on a cold start.
- **`user_ref`:** the server's own id when signed in. The server attaches it from the bearer token; the app never sends it. Guests have none.
- **Dimension snapshot:** when a session starts, and whenever the profile changes, the app sends one `profile_snapshot` event with the §3 values. Other events carry only `session_id`. Benefits:
  - every search can be cut by demographics,
  - the profile isn't repeated on each event,
  - a later profile change does not rewrite earlier sessions.
- **Snapshot schema version** = `questionnaire.json` `schema_version`, so reports can tell old answers from new.

## 5. Events (phase 1 unless marked)

| Event | When (where in the app) | Properties |
|---|---|---|
| `app_open` | Cold start finishes the splash (`splash_screen.dart`) | `launch_kind`: cold / warm |
| `session_start` | New session | context dimensions |
| `profile_snapshot` | Session start; profile saved; questionnaire answer saved (phase 2) | §3 values present, `schema_version` |
| `mode_chosen` | Mode screen Continue (`navigation_mode_screen.dart`) | `nav_mode` |
| `tour_finished` | Home or Saarthi tour ends (`HomeTour`, `SaarthiTour`) | `tour`: home / saarthi, `outcome`: completed / skipped |
| `search_submitted` | Query submitted (`search_screen.dart` `_triggerSearch`) | `query_norm`, `result_count`, `source`: typed / quick_pill / voice / category, `filters` (facet keys) |
| `search_zero_result` | `result_count == 0` | `query_norm`, `did_you_mean` (if shown) |
| `scheme_opened` | Scheme details opened (`SchemeDetailsScreen`) | `scheme_id`, `from`: search / home_top_schemes / featured / recommended / saved / saarthi / deeplink, `rank` (position in the list) |
| `scheme_apply_tapped` | Official link tapped (`_openOfficialUrl`) | `scheme_id`, `action_kind`: apply / info |
| `scheme_saved` | Bookmark toggled (signed-in only) | `scheme_id`, `saved` |
| `eligibility_checked` | Eligibility run (phase 2, with the 1.2 engine) | `scheme_id`, `eligible`, `failed_rule_keys` |
| `filter_used` | For me / facet / sort changed | `kind`, `value` |
| `saarthi_started` | Chat or voice starts | `mode`: voice / typed |
| `signin_prompt_shown` | `SignInRequiredSheet` shown | `feature`: save / alerts / saarthi / for_me / general |
| `signin_prompt_result` | Sheet closed | `result`: sign_in / not_now |
| `signin_completed` | First session after sign-in | `from_guest`: true / false |
| `questionnaire_progress` | Phase 2: field answered or skipped | `field_id`, `answered` (value goes in the snapshot, not here) |

**Query normalisation** (`query_norm`), on the phone before sending:
- lower-case, trimmed, with repeated spaces collapsed;
- digit runs of 6 or more replaced by `#` (phone, Aadhaar, PAN-like);
- emails and URLs removed;
- cut to 60 characters.

On the server, a query enters the "top queries" report only once at least 10 different installs have searched it. This drops rare and personal strings. **Mapping a query to a scheme** uses `scheme_opened` with `from = search` in the same session; no guessing from the text.

## 6. App side (`frontend/lib/services/analytics/`)

- **`AnalyticsService`**
  - `track(name, props)` appends to a local queue: a JSON lines file in app storage, at most 2,000 events; the oldest go first.
  - It is never awaited on a UI path, and failures are only logged.
- **Flush**
  - Every 60 s while the app is open, on going to the background, and on reconnect (`ConnectivityService`).
  - Up to 100 events per batch, sent with gzip to the ingest route.
  - On a 5xx or no network: keep the batch and back off (1 min, 5 min, 30 min).
  - On a 4xx: drop it.
- **Consent gate**
  - Nothing is queued until the user has accepted the analytics purpose (Decision B). After that, the Settings switch controls it.
  - When switched off: the queue is cleared and an `analytics_opt_out` marker is sent once.
- **Guests:** these follow Decision A.
- **Tests:**
  - unit tests for normalisation, queue limits and the consent gate;
  - a widget test that search, scheme open and apply still work offline with analytics on.
- **Pending route:** add `PendingEndpoints.analyticsEvents = '/analytics/events'` until the backend has it.

## 7. Server side: proposed contract (other dev)

**Ingest:** `POST /v1/analytics/events`, body `{install_id, events:[{name, ts, session_id, props}]}`.
- Auth:
  - a signed-in bearer token, which attaches `user_ref`;
  - or the 1.4 `guest` token;
  - or none, with a per-`install_id` rate limit. This choice is part of Decision A.
- Rate limits: 30 requests per minute per IP and 10 per minute per install.
- The server rejects names and properties not on an allow-list taken from §5. It never stores the IP or user agent with events; they are used only for rate limiting.

**Storage:**
- `analytics_events_raw`: kept for **90 days**, partitioned by day.
- `analytics_sessions`: session to snapshot.
- `analytics_daily_*`: aggregate tables, kept long term.
- On `DELETE /v1/me`, set `user_ref` to null in raw events and sessions.

**Nightly aggregates:**
- active installs and sessions by day × `user_kind` × `app_language` × `state_code` × `nav_mode`;
- top `scheme_id` by views, opens from search and apply taps;
- top `query_norm`, with the 10-install minimum;
- zero-result queries;
- crosstabs of scheme views × each §3 dimension, at district and state level;
- funnel counts (Q5).

**Reports:**
- an admin-only endpoint returning aggregate JSON or CSV;
- every cell under the minimum (Decision C) shows as `<10`;
- no row-level export.

**Dashboard:**
- the admin catalogue tool (backend operators) or a hosted sheet;
- filters: date range, state, district, language, user kind;
- views: footfall, top schemes, top queries, zero results, dimension cuts, funnel.

## 8. Phases

| Phase | Scope | Depends on |
|---|---|---|
| **0** | Decisions A–D; privacy policy text and legal review | Officials and legal |
| **1** | App: `AnalyticsService`, consent, the §5 events except eligibility and questionnaire, snapshot from current `UserProfile` fields. Server: ingest, raw store, footfall, top schemes and top queries. | 0; backend dev |
| **2** | Questionnaire answers in the snapshot (all 14 features), `eligibility_checked`, demographic crosstabs | PR #201 merged, the answers store (goal 8), DEV 2's questionnaire UI, the 1.2 engine |
| **3** | Dashboard polish, scheduled reports to departments, zero-result queries fed into catalog work | 1–2 |

## 9. Decisions needed

| # | Decision | Recommended |
|---|---|---|
| **A** | Do guests send events and demographics? | **Events yes, demographics only with consent.** Guests send anonymous events (`install_id`, no `user_ref`), so footfall and top schemes include them. Their profile snapshot goes only after they accept the analytics consent shown at the guest entry. This changes the earlier "guest answers stay on the device" agreement for the analytics purpose only; the officials and DEV 2 must agree. |
| **B** | Consent model | **Separate, optional analytics consent**, off until accepted. Asked after the first useful moment (first scheme opened), not at login. Policy re-versioned to name the purpose: aggregate reports to the scheme departments. Never sold, never row-level. |
| **C** | Minimum cell size in reports | **10** people per cell, district level and up. Taluka only if the cell is 25 or more. |
| **D** | Where reports live | Admin catalogue tool, **aggregate only**. Departments get CSV exports with the same suppression. |

---

## 10. Answers to the officials' open questions

I read "choose the best chance" as **pick the best option for each question**. Where a question asks for a scheme fact, I give what the official sources say, or keep the officials' value and mark it open. The rules file is not changed.

1. **PMEGP: can running businesses qualify?**
   - **Recommendation:** new units only for the first loan. Existing units qualify **only** through the **2nd loan for upgradation**, which is limited to **existing PMEGP/MUDRA units** that have repaid the first loan and show a profit record.
   - Second-loan terms: subsidy 15% (20% in the NER and hill states); project cost cap ₹1 crore for manufacturing and ₹25 lakh for services.
   - In the app: keep `business_age = not_started_yet_aspiring` for the main PMEGP rule. Add a separate "PMEGP 2nd loan" scheme entry for existing units.
   - Sources: [Invest India](https://investindia.gov.in/schemes-msmes-india/2nd-loan-gradation-existing-pmegpmudra-units), [2nd-loan guidelines (PDF)](https://www.svnit.ac.in/Unnat_Bharat/PI/pdf/Livelihood%20&%20Entreprenurship/Schemes%20by%20Government%20of%20India/PMEGP%20Pradhan%20Mantri%20Employment%20Generation%20Programme/Annexure%20II%20final-guidlines-for-2nd-loan.pdf), [myScheme PMEGP](https://myscheme.gov.in/schemes/pmegp). Confirm on the KVIC PMEGP portal before go-live.
2. **Official links**
   - **PSI-2019:** use the Government Resolution itself: PSI-2019/CR 46/IND-8, dated 16 September 2019, Industries, Energy and Labour Department ([copy on MIDC](https://www.midcindia.org/wp-content/uploads/2021/09/Package-Scheme-of-Incentives-2019.pdf)).
   - **Flag:** PSI-2019 ran "till 31 March 2024 or until the new scheme comes into force". Maharashtra has since notified the Industries, Investment and Services Policy 2025 ([PwC note, Jan 2026](https://www.pwc.in/assets/pdfs/news-alert/tax-insights/2026/pwc-india-tax-insights-6-january-2026-government-of-maharashtra-notifies-the-industries-investment-and-services-policy-2025.pdf)).
   - **Ask the officials:** should the app show PSI-2019, or the incentive scheme under the 2025 policy?
   - **MUDRA:** use the official MUDRA site, mudra.org.in, instead of jansamarth.in.
3. **Project cost vs machinery band**
   - **Recommendation: add a dedicated `project_cost_inr` question.**
   - The machinery bands (`up_to_rs_10_lakh`, `rs_10_lakh_2_5_crore_micro`, …) cannot separate the ₹5 lakh (PMEGP services), ₹10 lakh and ₹25 lakh (CMEGP) education thresholds.
   - Suggested bands: `up_to_5_lakh`, `5_10_lakh`, `10_25_lakh`, `25_50_lakh`, `50_lakh_1_crore`, `above_1_crore`.
   - Show it only for `scheme_goal` = start or expand, and only when PMEGP or CMEGP could apply.
4. **Industry divisions (Sathyan)**
   - **Recommendation: multiple selection**, up to 3 (many MSMEs span divisions).
   - All three languages (en, mr, hi), like the other fields, with stable value keys.
   - Ask Sathyan for a date. Until then, `business_nature` and `product_keywords_or_nic` cover it.
5. **Marathi QA:** ask the officials to name one Marathi reviewer from the Maharashtra team. They review the questionnaire and the scheme texts first, then the full app, using the existing `MSS_Marathi_Check.xlsx` inventory.
6. **Guest access:** **approve as built.**
   - Guests can browse, search, choose regular or Saarthi mode, see top schemes for their state, and (once built) check eligibility.
   - Sign-in is needed to save, get alerts, use Saarthi chat and voice, and sync. This is how the app works today (PRs #202 to #206).
7. **Scheme figures (priority): keep the officials' values, open until they confirm.** What the sources say:
   - **CMEGP age:** 18–45, and 18–50 for women, SC/ST, ex-servicemen and divyangjan. This matches the rules file and public sources, but there is no GR to cite yet.
   - **CMEGP project cost cap:** public sources conflict.
     - [myScheme](https://myscheme.gov.in/schemes/cmegp) and most guides say **₹50 lakh for manufacturing and ₹20 lakh for services**.
     - A [Free Press Journal report](https://www.freepressjournal.in/mumbai/raigad-gears-up-for-entrepreneurial-growth-with-revamped-chief-ministers-employment-generation-programme) cites a new GR raising it to **₹1 crore and ₹50 lakh**.
     - **Ask the officials for that GR's number and date.** Until then, show the ₹50L / ₹20L caps as current.
   - **Subsidy 15 / 25 / 25 / 35%** (urban general, urban special, rural general, rural special): this matches myScheme and the rules file. Confirm against the same GR, since a revision may change it.
