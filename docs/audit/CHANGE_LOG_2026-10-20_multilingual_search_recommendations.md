# Change log: multilingual search, "Did you mean", and recommendation engine fixes

Branch: `feat/multilingual-search-recommendations` · Logged: 2026-10-20 (work started 2026-10-19)

`DEV_LOG.md` is appended by CI when a PR merges; this file is the detailed record
for this branch.

## Why

The recommendation engine and the search index were written for one English
catalog. The app ships English, Hindi and Tamil, and a profile stores the *label
the user tapped* (`பெண்`, `महिला`), so non-English profiles were scored wrongly,
and Hindi/Tamil queries could only match a scheme's name, never what it does.

## Design decisions

- **No ML.** Embeddings were evaluated and rejected, consistent with
  `docs/old_supabase/docs/OFFLINE_DISCOVERY_AND_SEARCH_ARCHITECTURE.md` §5.1, which
  chose lexical query expansion over server-side pgvector and over on-device
  models. Everything below is deterministic, offline, and derived from the
  catalog's own text.
- **Platform features where they exist.** Spelling: the search fields now enable
  Flutter's built-in spell check (the system spell checker on Android and iOS),
  instead of relying only on hand-built correction. The catalog-based suggestion
  is kept alongside it, because the platform checker does not know scheme words
  (acronyms, programme names) and cannot promise a correction finds results.

## Changes

### Recommendation engine (`frontend/lib/services/recommendation/`)
- **`profile_canonicalizer.dart` (new):** maps gender, community, education,
  employment, disability and religion from any app language (and from English
  voice facts) to one English value before scoring. One label table per field
  (Hindi "अन्य" is both gender-Other and community-Others). Labels come from the
  app's own ARB files, not a second hand-kept list.
- **`indian_states.dart` (new):** all states/UTs in English, Hindi and Tamil, so a
  typed or geocoded state (`தமிழ்நாடு`, `तमिलनाडु`) matches the English catalog.
- **`recommendation_engine.dart`:** profile canonicalised once per run; the
  dead per-scheme rules removed (724 -> 460 lines); an industry typed in
  Hindi/Tamil matches English scheme text through the shared taxonomy; scheme and
  profile state are compared by state, not spelling. Public API unchanged.
- **Bugs fixed:**
  1. Gender/community saved as a localized label never matched, so Hindi and Tamil
     women were hard-excluded from women-only schemes.
  2. All 20 hard-coded scheme ids (`NEEDS`, `PMEGP`, ...) are gone from the 2026
     catalog (`CEN2026-###`), so every special-case rule was dead code.
  3. The form stores disability as `Yes`/`No`; the engine treated anything but
     `none` as differently-abled, crediting the priority category to everyone.
  4. English education labels (`School (10th / 12th)`) never equalled `'School'`.

### Search (`frontend/lib/services/search/`, shared taxonomy)
- **Taxonomy:** 163 Hindi/Tamil terms in `search_taxonomy.json` (industries,
  benefits, collateral, TReDS, communities, intents), kept byte-identical across
  `backend/catalog/`, `frontend/assets/search/` and `saarthi-agent/data/`.
- **Query expansions:** 146 Hindi, Tamil and romanised entries in
  `queryExpansions` / `query_expansion.json`; every target verified against the
  catalog vocabulary (74 targets no scheme indexes were dropped, not shipped).
- **`indic_search_support.dart` (new), used by `hybrid_scheme_search.dart`:**
  - indexes each scheme's own Hindi and Tamil summary / description / benefits /
    eligibility / category text (previously only the Hindi *name* was searched);
    words in more than 20% of schemes are dropped by document frequency;
  - suffix tolerance for Hindi/Tamil query words (`கொள்முதலுக்காக` ->
    `கொள்முதல்`), bounded to a 7-character suffix and 4-character roots.
- **`spell_suggester.dart` (new) + `didYouMean`:** "Did you mean" from the
  catalog's own vocabulary using edit distance (no model), working on Unicode code
  points so Hindi/Tamil are corrected too. A suggestion is shown only if it finds
  schemes and beats what was typed.
- **Voice agent (`saarthi-agent/src/search_taxonomy.py`):** `normalize()` stripped
  all non-ASCII, so no Hindi/Tamil taxonomy term could ever match; it now keeps
  Devanagari and Tamil like the Dart engine.

### UI
- Platform spell check (`SpellCheckConfiguration`) on both search fields
  (`search_input_section.dart`, `search_results_screen.dart`), through
  `utils/spell_check.dart`. It is enabled only when Flutter reports a native
  spell checker (`nativeSpellCheckServiceDefined`: Android and iOS devices).
  **Enabling it unconditionally is not safe:** on web, desktop and in tests
  Flutter asserts, which failed 13 widget tests until this gate was added.
  Whether Hindi/Tamil are checked depends on the device having those
  dictionaries (not verifiable in CI).
- "Did you mean" line on the search screen (empty state and results header) and
  on `SearchResultsScreen` (empty state). New string `searchDidYouMean` in the
  three ARBs and regenerated localizations. Uses `AppColors`, `AppRadius` and
  `AppTextStyles`, so the design-system guards stay green.

## Measured results

Held-out set, run through the real engine: 300 queries per language: 100 direct
scheme names, 100 inferable by meaning, 100 indirect/situational; exactly half of
each level misspelled (typos injected by a seeded script). The inferable and
indirect queries were written by hand and mechanically checked to contain **none**
of the Hindi/Tamil/romanised words added in this branch. hit@5, equal weight over
all cells:

| | Before | After indexing + suffixes | After + "Did you mean" tap |
|---|---|---|---|
| All languages | 57.7% | 69.0% | 74.3% |
| Difficulty-weighted (levels 1:2:3) | 46.6% | 60.8% | 66.8% |
| Hindi, indirect (L3) | 24% / 32% | 56% / 48% | |
| Tamil, inferable (L2) | 32% / 34% | 76% / 50% | |
| Tamil queries returning nothing | 10-36% | 0-2% | |

(clean / misspelled). Direct-name search was already 94-100% in every language
and stayed there. English meaning-based search (L2 60%, L3 44%) is unchanged.

Earlier 20-intent check (English/Hindi/Tamil): vocabulary alone moved Tamil 14 -> 19
and Hindi 19 -> 20; with the text index Tamil is 20/20.

## Tests added or changed
- `recommendation_multilingual_test.dart`: canonicaliser, states, and a
  whole-catalog property test (same person in en/hi/ta -> identical scores). Six of
  its tests fail against the previous engine.
- `multilingual_search_parity_test.dart`: 20 intents x 3 languages, exact floors.
- `spell_suggestion_test.dart`, `did_you_mean_widget_test.dart` (includes a check
  that the search field enables the platform spell checker).
- `tool/search_eval_runner_test.dart`: inert unless `SEARCH_EVAL_FILE` /
  `SEARCH_EVAL_OUT` are set; runs an eval file and records ranks.
- `for_me_profile_eligibility_test.dart`: fixtures moved to catalog-style ids.

## Known limits and follow-ups
- **Native-speaker review needed** for the Hindi/Tamil taxonomy terms, expansions
  and the new "Did you mean" wording.
- **Still hand-authored:** the taxonomy/expansion terms, the state-name table and
  a few label aliases. Google options that could replace parts of this need a
  decision (network/billing for Cloud Translation, or on-device models, which this
  project has ruled out); the geocoding plugin can return English state names
  directly, which would remove the state table for GPS-filled addresses only.
- **The 900-query eval set is not in the repo** (it was generated outside it); only
  the runner is. Rebuild a set before relying on the numbers above for new work.
- The held-out Hindi/Tamil queries avoided every word added here, so some are less
  natural than real usage (e.g. a colloquial word for "women"); the Hindi/Tamil
  figures are probably pessimistic. Levels 2-3 were sampled from central schemes
  only (the only pack with all three languages).
- Those figures were measured on a set also used to choose the two index changes;
  both changes are general (no query-specific words), but a fresh held-out set is
  the right next check.
- English meaning-based search is capped by lexical matching; the catalog has no
  structured income, education or disability eligibility facets, so those profile
  fields cannot be scored.
- `frontend/pubspec.lock` is rewritten by Flutter on every test run; deliberately
  not part of this branch.

## Follow-up: Hindi/Tamil stemming, voice-agent parity, emulator runs
- **Stemming:** `indic_stemmer.dart` (Snowball lightweight Hindi stemmer port plus a
  conservative Tamil suffix stripper built from suffixes mined from the catalog's
  own text). `IndicVocabulary` matches words that share a stem before falling back
  to the older prefix rule. `saarthi-agent/src/indic_stemmer.py` mirrors it; both
  are tested against `frontend/test/fixtures/indic_stem_cases.json`.
- **Voice agent parity:** `saarthi-agent/src/indic_search.py` + `hybrid_search.py`
  now index each scheme's own Hindi/Tamil text and match inflected words (golden
  parity test unchanged and passing).
- **Tried and dropped:** catalog-derived Hindi/Tamil -> English expansions
  (Dice association over parallel catalog text). On the 900-query set they lowered
  Hindi hit@5 73.7 -> 72.0 and Tamil 73.3 -> 71.3, so they are not shipped.
  Stemming alone: overall hit@5 71.8% (75.8% with did-you-mean) vs 71.1% / 75.2% before.
- **Emulator runs** (headless Android emulator, 300 cases per language, real app UI
  via `integration_test/search_emulator_test.dart`; helpers in `tools/search_eval_*.py`):
  - English: system spell checker flagged 148/150 misspelt queries and suggested the
    right word for 232/296 misspelt words; 19/150 false alarms on clean queries.
    hit@5 by level 97 / 64 / 44% (100 / 68 / 50% with did-you-mean).
  - Tamil: **the system spell checker has no Tamil dictionary** (probe returns no
    spans), so Tamil/Hindi rely on the catalog-based "Did you mean". hit@5 by level
    96 / 68 / 56% (100 / 73 / 60% with did-you-mean).
  - Hindi: same, no system dictionary. hit@5 98 / 66 / 57% (100 / 70 / 61%).
  - Installing a Tamil/Hindi keyboard does not add a spell-check dictionary here;
    on real devices Gboard's own checker is not exposed to apps.
- Caveat: the eval queries were also used while tuning, so these are not fully held out.

## Follow-up: indirect queries (English text index)
- **Cause found:** the prebuilt English index holds only ~20 name-like tokens per
  scheme, so a query using words that appear only in a scheme's summary or
  description ("cooking gas", "sewer cleaners") could not reach it.
- **Fix:** index each scheme's English summary / description / benefits /
  eligibility text as a field (weight 0.8), dropping words found in more than 20%
  of schemes (data-derived stopwords). Same in `saarthi-agent` (`english_text_tokens`).
  No ML, no hand-written word lists.
- **Result (900-query set, hit@5):** English overall 68.3% -> 85.3% (with
  did-you-mean 72.7% -> 88.7%); inferable queries 64% -> 88%, indirect 44% -> 71%.
  Direct-name queries unchanged (97%). All three languages combined 70.6% -> 77.6%
  (81.0% with did-you-mean).
- **Hindi/Tamil unchanged** (73.7% each): their queries use words that are not in
  the schemes' Hindi/Tamil text, a translation-vocabulary gap rather than a ranking
  one. Tried without gain: Indic text weight 1.0; adding stem variants for words
  already in the vocabulary (Hindi down, Tamil up, net zero).
- Weight 0.8 was chosen from 0.3 / 0.5 / 0.8 / 1.0 on the same query set (0.8 and
  1.0 tied), so the English gain is slightly optimistic.
- `backend/catalog/search_parity_golden.json` regenerated from the Dart engine; the
  Python engine reproduces it exactly. The archived TypeScript engine was not updated.
- `multilingual_search_parity_test` floors: en 18 -> 19, ta 20 -> 19 (one Tamil query's
  English expansions now also match descriptions).

## Follow-up: fresh real-world-phrased set and weight tuning
- `tools/search_eval_realworld.py` builds 120 queries (60 en, 30 hi, 30 ta; a third
  with one dropped-letter typo) phrased like online scheme searches, each aimed at one
  scheme, none a bare generic word. Web search returned scheme-guide pages but no
  query-volume logs, so the phrasing follows those pages; the targets were labelled
  by hand against the catalog. Split dev/test alternately.
- Before tuning: hit@5 88% overall (en 92, hi 80, ta 90).
- Tuned on **dev only**: Hindi/Tamil text-field weight 0.8 -> 1.2 (English text weight
  0.5-1.2 made no real difference, kept 0.8). Held-out **test** half: 90% -> 92% overall
  (Hindi 80 -> 87). Old 900-query set unchanged (77.6% overall).
- Small samples (60 queries per half): treat differences of a few points as noise.

## Follow-up: Firebase push notifications (FCM)
- `android/app/google-services.json` (project `mss-app-sch`, package `com.inschemes.app`;
  public client config, no server key) + Google services Gradle plugin; `firebase_core`
  and `firebase_messaging` added. The debug APK builds and contains the config.
- `PushNotificationService`: asks for notification permission after sign-in (a refusal
  never blocks login or the inbox), then `PUT /v1/me/push-devices/:installation_uuid`
  with `{"token", "platform":"android"}` using the Node bearer. Re-registers on token
  rotation, fresh login and app resume; sign-out/account switch drop pending work and
  re-check the account before every send. Installation UUID is a random id kept in
  SharedPreferences. `getToken`/`onTokenRefresh` are used on purpose (the backend takes
  an FCM registration token, not the newer Installation ID).
- Messages: `notification_id` (UUID-validated) is de-duplicated. Foreground shows a banner
  built from the authenticated inbox item; tapping a notification (background or cold
  start) refreshes the inbox and opens it once the app has left the splash screen. The
  text shown is never taken from the push payload.
- Tests: `push_notification_service_test.dart` (9). **Not yet tested on a real phone**:
  foreground/background/closed delivery, token rotation and account switching need a
  device and a backend with the push worker running.
- CI: Saarthi Voice Agent CI was failing on ruff (import order, SIM905) for the earlier
  Python files; fixed and `ruff check` / `ruff format --check` pass.

## Follow-up: in-app wording aligned with the catalog's own terms (Tamil / Hindi)
Preferred forms were read off the scheme catalog (the DB translations), counting how it
writes each term, and the app's ARB strings and translation dictionaries now match:
- **Tamil:** women = "மகளிர்" (catalog 178x vs "பெண்கள்" 68x): "மகளிர் தொழில்முனைவோர்"
  (women entrepreneurs), "மகளிர் தொழில்முனைவு" (the category; the dictionary had both
  forms for it); MSME stays Latin "MSME" (catalog 282x), one stray "எம்எஸ்எம்இ" fixed;
  "காதி" not "கதர்" (90x vs 0); "எரிசக்தி" for energy; "வேளாண்மை" for the agriculture
  category; "Artisan & Craftsmen" no longer repeats the same word twice; "கடன் & வரவு"
  (credit-entry sense) -> "கடன் & கடனுதவி"; transgender filter -> "மூன்றாம் பாலினத்தவர்";
  ex-servicemen -> "முன்னாள் படைவீரர்கள்" (as in the catalog's scheme names).
- **Hindi:** "औरत" -> "महिला"; "अलग रूप से सक्षम" -> "दिव्यांग" (and disability labels ->
  "दिव्यांगता/दिव्यांगजन"); "बुनियादी ढाँचा/आधारभूत संरचना" -> "अवसंरचना"; "रसद" ->
  "लॉजिस्टिक्स"; "ऋण और उधार" -> "ऋण और क्रेडिट"; ex-servicemen -> "पूर्व सैनिक";
  dictionary "business & msme" now matches the ARB category title.
- **States / union territories:** only a few had Tamil/Hindi names in the dictionaries, so
  the rest showed in English in the state lists. All 36 now have official names (24 added
  to each language); Telangana corrected to "தெலங்கானா".
- Official proper names (MSME, Udyam, Startup India, KVIC, scheme names) are kept in their
  official form rather than translated word by word.
- `official_terms_test.dart` guards these choices.
- Not changed: "ஸ்டார்ட்அப்" for startup (the catalog uses it 33x; Tamil Nadu government
  texts also use "புத்தொழில்"); worth a native-speaker decision.
