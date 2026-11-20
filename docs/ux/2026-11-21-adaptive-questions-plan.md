# Adaptive questions ("Smart assessment"): why results are thin, and the plan

Written 2026-11-21. **Plan only, no code yet.**

The feature lives in:
- `lib/widgets/assistant/smart_assessment_bottom_sheet.dart`;
- `smart_assessment/assessment_question_flows.dart`: 1,007 lines of hand-written flows;
- `smart_assessment/assessment_profile_matcher.dart`.

It opens from the category, ministry and state cards (`categories_screen.dart`) and from the home promo carousel.

## 1. What happens today

1. The card's title picks one of about 8 fixed flows by substring, e.g. `title.contains('women')` gives the women flow and `'business'` gives the business flow.
2. The questions ask about gender, caste, income and need. Each answer is stored as its **English option text**, even in Hindi, Marathi or Tamil, so translation is not the problem.
3. On submit, `computeSubmissionResults`:
   - **overwrites the user's profile** with the answers: gender, community, income band, employment and business stage, via `provider.updateProfile`;
   - turns answers into two filters by keyword: `schemeTypes` and `beneficiaries`;
   - `applyToProvider` sets those filters, and the user lands on the card's browse page with them applied.
4. `applySchemeFilters` intersects every filter: card base set ∩ scheme types ∩ beneficiaries.

## 2. Why so few results: measured on the shipped catalog (417 schemes in 4 packs)

| # | Cause | Evidence | Effect |
|---|---|---|---|
| R1 | **Beneficiary is a hard filter, but few schemes are tagged.** Picking "Female", or "woman" in a demographic answer, adds `beneficiaries: [women]`. | Only **100 of 417** schemes (24%) have any `specialCategories`; only **71** are tagged `women`, 30 `sc`, 28 `st`. | A woman sees only the 71 "women" schemes, minus the other filters. Most general schemes, which are open to women, disappear. This is the main cause. |
| R2 | **Scheme type is a hard filter from keyword guesses.** Words in the answer such as "loan", "market", "trade", "training" and "incubat" pick type groups. | **85 of 417** schemes (20%) have no `schemeType`, so any type filter drops them. Words like "market" also match options like "Finding buyers & marketing" and add unrelated groups. | One answer can drop a fifth of the catalog, and it narrows to types the user didn't ask for. |
| R3 | **Filters stack.** Card base set ∩ types ∩ beneficiaries. | Already noted in the code: one double-filter took "Business & MSME" from 309 to 83. | Each answer multiplies the loss; three answers often leave a handful or none. |
| R4 | **No fallback when results are thin.** | No zero- or low-result branch in the sheet or on the browse page. | The user ends on an empty or near-empty list with no way forward. |
| R5 | **Answers silently overwrite the real profile.** | `updatedProfile` replaces gender, community, `annualIncome`, `employmentStatus` and `businessStage`. A guest's answers change the local profile too. | Recommendations elsewhere change unexpectedly. A typo in a one-off check rewrites the account profile and syncs it. |
| R6 | **Fragile matching.** | Income comes from `qId.endsWith('q5')` and substrings like `'Under ₹1'` and `'₹2.5'`. Flows are chosen by title substrings. Nothing links to `questionnaire.json` or `eligibility_rules.keyed.json`. | Edits to the text break the logic quietly. Questions don't match the officials' 26 fields or the scheme rules. |
| R7 | **No reasons.** | Results are a plain filtered list. | The user can't tell why a scheme is shown or what's missing to qualify. |

## 3. Goal

After about 5–7 quick questions, a user, guest or signed-in, sees:
- **at least 5 schemes** ranked by fit, never an empty page;
- the reason for each, e.g. "for manufacturing units in Maharashtra";
- what's missing for near matches, e.g. "needs Udyam registration".

## 4. The new design

### 4.1 One source of questions
- Use `questionnaire.json`: the 26 officials' fields, en/mr/hi, with stable value keys. Copy it to the app in PR #201.
- Tamil and the non-Maharashtra flows: add the few general questions (state, gender, need) to the same file under a `general` scope. No hand-written flows.
- Delete the 1,007-line `assessment_question_flows.dart` once parity is checked.

### 4.2 Answers are stored, never written over the profile
- Answers go to `QuestionnaireAnswersStore` (goal 8 of the guest UX plan): `{field_id: value}`, validated against `questionnaire.json`.
- Fields the profile already answers are pre-filled and shown as "From your profile, change?".
- **"Save to my profile"** is an explicit button on the results, for signed-in users only. Guests keep answers on the phone and carry them over at sign-in, using the existing `guestAnswersUploadPending` path.

### 4.3 Score, don't filter
Each scheme gets a score from the answers:
- **Hard rules** (only where the scheme's rules say so): age limits, domicile, `business_age` for new-unit schemes, `org_structure`. A failed hard rule moves the scheme to "Not for you now", with the reason. It is never silently removed.
- **Fit points:**
  - `scheme_goal` and `assistance_needed` against the scheme type: +;
  - `business_nature` against the sector: +;
  - state applies: +;
  - `special_focus_zone` matches: +.
- **Category boost:** a woman, SC/ST or divyangjan answer **adds** points to schemes tagged for that group (`specialCategories`). It never excludes untagged schemes. This fixes R1.
- **Missing data is neutral.** A scheme with no `schemeType` or no tags is neither rewarded nor dropped. This fixes R2.
- **Engine:** reuse the 1.2 eligibility engine's rule evaluation (`evaluate(profile, scheme)`) when it lands. Until then, use the app's `RecommendationEngine` scoring, extended with the fields above.

### 4.4 Adaptive order: ask what matters next
- Start with 3 fixed questions: `scheme_goal`, `business_age`, and state or domicile.
- Then ask the field that **best splits the current top 30 candidates**: the field whose answer would change their ranking most. Skip fields that every candidate treats alike.
- Stop at 7 questions, or earlier when the top 5 can no longer change.
- Always allow "Skip" and "Show results now".

### 4.5 Results page
- **Three groups:**
  - **Good fit:** all hard rules pass, high score.
  - **Might fit:** a missing answer or a soft mismatch; shows "Answer 1 more question to confirm".
  - **Not for you now:** each with the failed rule, e.g. "Age limit is 45".
- **Minimum 5:** when "Good fit" has fewer than 5, fill from "Might fit", with a note.
- Each card shows **one reason line**, built from the rule and answer keys. The text comes from the ARB files, so it works in every language.
- Actions: open the scheme, save it (sign-in sheet for guests), "Change answers", "Save to my profile" (signed-in).

### 4.6 Entry points
- Keep the cards on the categories screen. The card only sets the **starting context**, e.g. women and business, and the first question. It no longer sets a filter.
- Add a home entry, "Check what you qualify for", the goal-3 item in the guest UX plan.

## 5. Phases

| Phase | Scope | Risk |
|---|---|---|
| **0: quick fixes, current code (1–2 days)** | (a) Turn `beneficiaries` into a ranking boost instead of a filter. (b) Drop the `schemeTypes` filter, or apply it only when 10 or more results would remain. (c) Stop `updateProfile` on submit; keep answers for the session. (d) Low-result fallback: under 5 results, show the card's full list with a note. (e) Tests: each card plus typical answers gives 5 or more results. | Low. These fix R1–R5 right away. |
| **1: answers store and questions from `questionnaire.json`** | `QuestionnaireAnswersStore`, the questionnaire-driven sheet with pre-fill from the profile, en/mr/hi plus the general scope. | Needs PR #201 merged. Shared with DEV 2's questionnaire UI, so agree on one widget. |
| **2: scoring, adaptive order, results groups** | §4.3–4.5 with reason keys | Uses the 1.2 engine when ready; `RecommendationEngine` until then |
| **3: measure** | Analytics events from the analytics plan (`questionnaire_progress`, `eligibility_checked`, `scheme_opened` from results); a dashboard of results per run and drop-off by question | Analytics plan phase 1 |

## 6. Tests and success measures

- **Golden tests:** 12 personas (the 5 in the guest UX plan × Maharashtra or Tamil Nadu, plus 2 edge cases). Each must get 5 or more "Good fit" or "Might fit" schemes, with the expected scheme in the top 5.
  - Example: an aspiring woman manufacturer in rural Maharashtra must get CMEGP and PMEGP in the top 5.
- **Unit tests:**
  - every hard rule at its edges (age 45/46/50/51, domicile);
  - a woman answer never removes an untagged general scheme;
  - submit never changes `UserProfile`.
- **Live, after analytics:**
  - median results per run of 8 or more;
  - under 5% of runs ending with no "Good fit";
  - completion rate per question, to drop or reorder weak questions.

## 7. Decisions needed

| # | Decision | Recommended |
|---|---|---|
| A | Do phase 0 now, before the redesign? | **Yes.** It fixes the empty results this week, with small changes in two files. |
| B | One questionnaire widget shared with DEV 2's profile questionnaire? | **Yes.** It avoids two question UIs and two answer formats. |
| C | Tamil Nadu and other states: same engine, with a general question set? | **Yes.** The officials' 26 fields are Maharashtra-led, but the engine and the results page are state-agnostic. |
