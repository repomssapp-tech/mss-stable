# Hindi / Marathi text inventory (2026-11-12)

Every source that holds Hindi (`hi`) or Marathi (`mr`) text, and what is broken.
Nothing was changed. Raw output in this folder.

## 1. Catalogue (scheme name, description, ministry/authority, ...)

Master: `frontend/assets/catalog/catalog_{core,central,maharashtra,tamil_nadu}.json.gz`.
Field map is `tools/translation/units.py` (only place that knows paths).

| Field | Path in scheme |
|---|---|
| name, short_name, description, benefits, eligibility | `source.<field>.{hi,mr}` |
| alt_names | `source.alt_names.<L>` / `alt_names_i18n.<L>` / `translations.<L>.alt_names` |
| steps | `source.how_to_apply.steps.<L>` |
| authority (ministry) | `source.translations.<L>.authority` (legacy `source.authority_<L>`) |
| category, status_note, mode | `source.translations.<L>.{category,status.note,how_to_apply.mode}` |
| notes, documents | `how_to_apply.notes_<L>` / `documents_<L>` / `translations.<L>.how_to_apply.*` |
| contacts office/address/hours | `source.translations.<L>.contacts.*` |
| benefit facts | `source.benefit_facts.facts[i].translations.<L>.*` (+ `content.benefitFacts` mirror) |
| required documents (detail tier) | `content.requiredDocuments[i].{name,description,issuingAuthorityText,estimatedCostText,remarks}.<L>` |
| reference sections (authorities, institutions, terms) | `<section>.localization.<L>.*` (hi only) |

Rendered via `frontend/lib/services/catalog/` (`mss_scheme_adapter.dart`, `adapter/scheme_*_resolver.dart`, `content_language_resolver.dart`, `language_pack_manager.dart`) into scheme card, scheme details (hero, benefits, eligibility, documents, services), search, saved, home.

### Gaps (`audit_hi.txt`, `audit_mr.txt`)

| Lang | Tier | Total | Missing |
|---|---|---|---|
| hi | central/detail (required docs) | 1923 | 711 (+103 held pending) |
| hi | tamil_nadu/core | 715 | 3 |
| hi | tamil_nadu/detail | 387 | 42 |
| hi | reference | 1017 | 886 |
| hi | gov names without official source | | 1325 |
| mr | maharashtra/detail | 106 | 106 (all) |
| mr | gov names without official source | | 163 |

Core text for central + maharashtra: complete for both.

### Broken (`lint_hi.jsonl`: 549 findings, `lint_mr.jsonl`: 46)

Each line: `{unit: "<scheme_id>|<field>", severity, code, detail, en, text}`.

| Lang | Blocking | Count | Fields hit |
|---|---|---|---|
| hi | number_missing / added, crore_mismatch | 32 | status_note 30, facts 16 |
| hi | wrong_script, same_as_english | 47 | alt_names 20, short_name 10, ... |
| hi | flags (term_changed 317, low_script 148, same_as_mr 5) | 470 | steps, description, authority, eligibility |
| mr | wrong_script 8, same_as_english 6, lakh/crore/number 3 | 17 | facts 17 |
| mr | flags (low_script 24, same_as_hi 5) | 29 | steps, documents, category |

## 2. Phrase dictionaries (runtime fallback translator)

- `frontend/assets/catalog/translation_dictionary_hi.json` (tagMap, phraseMap; 480 KB)
- `frontend/assets/catalog/translation_dictionary_mr.json` (100 KB)
- `frontend/assets/catalog/translation_dictionary.json` (shared)
- Backend copies: `backend/catalog/source/translation_dictionary.json`, `translation_terminology_dictionary.json`
- Used by `frontend/lib/services/catalog/centralized_translator.dart`, `widgets/common/auto_translated_text.dart` (chips, tags, catalogue text without stored translation).

Not audited for quality yet.

## 3. App UI strings

- `frontend/lib/l10n/app_hi.arb`, `app_mr.arb` (1872 keys each, none missing).
- Untranslated real text: `mr notifSeed3Title = "PM Vishwakarma Yojana"`. Others in `arb_issues.txt` are acronyms/formats (OK).
- Hardcoded non-ARB strings: guard `frontend/test/guards/i18n_literals_test.dart`, baseline `test/guards/baseline/i18n_literals.json`.
- Notifications: `services/notifications/notification_translator.dart`, `providers/controllers/notification_translation_controller.dart`.

## 4. AI / Saarthi assistant

- Voice agent language table: `saarthi-agent/src/agent_language.py` (greeting, voice, prompt language per `hi`/`mr`).
- Search vocab: `saarthi-agent/src/indic_stemmer.py`, `indic_search.py`, `search_taxonomy.py`; `backend/catalog/search_taxonomy.json` (166 Devanagari lines).
- App side: `frontend/lib/design_v2/saarthi/*` (history, kit, voice views, scheme mentions), `screens/companion_mode/saarthi_message.dart`, `widgets/chat/chat_markdown_body.dart`, `widgets/assistant/smart_assessment/*` (question flows: check for inline text), `services/search/indic_*`, `private_ai_knowledge_base.dart`, `scheme_understanding_rules.dart`.

## Fix pass (2026-11-12)

### Catalogue blocking findings: no change needed

| Finding | Why it stays |
|---|---|
| short_name / alt_names in English (WOS-C, E-SDP, PM E-DRIVE, DJAY-S, Q-Cert, Design, Incubation, Khadi, IEC in AYUSH) | Government-name fields. Pipeline rule: English stays until an official translation with `official_source` exists. |
| facts `group` = A, B, C, D, D+ (MAH2026-043/044/054, hi + mr) | Zone codes, not words. |
| MAH2026-046 "Rs 10 million" = ₹1 करोड़ / ₹1 कोटी | Correct conversion (the pipeline doc gives this exact example). |
| 30 TN status_note missing "200" | "HTTP 200" is a technical detail; translations say "page opened successfully". |
| Mixed script: SHG/SRLM, PAN/GSTIN, KMUT, ONDC/TEAM | Acronyms. |

Open (needs official source, not done): Hindi official names for the 9 government names above.

### Phrase dictionaries

Checks run on all 2394 hi and 556 mr entries: numbers, lakh/crore, script, empty, Tamil script, Hindi words inside Marathi, Marathi words inside Hindi, leftover English. Not done: a line-by-line meaning review.

Fixed in `translation_dictionary_mr.json` (English descriptions left untranslated):
- AD (Authorized Dealer) Code -> AD (अधिकृत डीलर) कोड
- Department of Industries and Commerce (MSME Department) -> उद्योग व वाणिज्य विभाग (MSME विभाग)
- Scheme of Fund for Regeneration of Traditional Industries -> पारंपरिक उद्योगांच्या पुनरुज्जीवनासाठी निधी योजना
- Registration cum Membership Certificate -> नोंदणी-सह-सदस्यत्व प्रमाणपत्र
- MSME Development Institutes -> MSME विकास संस्था
- Digital Personal Data Protection Act, 2023 -> डिजिटल वैयक्तिक माहिती संरक्षण अधिनियम, 2023

Kept by design (proper names/brands): Google, Android, StartupTN, MentorTN, TNSkill, FaMe TN, BioNEST, BioCARe, MeitY, MoFPI, MSInS, ITeS, TiE, WInER, AcE, NSE Emerge, TN e-Sevai, RXIL/M1xchange/Invoicemart, HS Code (Harmonized System Code), website addresses.

### App screen text

Fixed: `app_mr.arb` `notifSeed3Title` -> पीएम विश्वकर्मा योजना (same as Hindi).

Kept in English by design (acronyms and formats), both languages unless noted:
`treds` TReDS, `quickPillPmegpQuery` PMEGP, `quickPillAscendQuery` ASCEND, `onbChipMsme` MSME, `profileHintDdmmyyyy` DD/MM/YYYY, `onbStep` {step} / {total};
mr only: `homeTourProgress` {current} / {total}, `commEws`/`commEwsCategory` EWS, `assessWomenQ4CasteOpt2`/`assessAgriQ3CasteOpt2` OBC, `assessStateQ2Opt1` BC / SEBC / OBC, `commObcBcMbc` OBC / BC / MBC, `docEntityLlp` LLP.

## 5. Old review / worklists (reference only)

`docs/reports/hindi_names_for_review.csv`, `docs/reports/unverified_hindi.csv`, `tools/data/maharashtra_hindi_review_2026-10-23.json`, `backend/catalog/translations/ledger/{hi,mr}.jsonl`, `glossary.json`.
