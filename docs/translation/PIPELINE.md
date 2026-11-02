# Catalogue translation pipeline

One pipeline for every language. A new language is a config entry; the code does not change.

Code: `tools/translation/`. Config and ledgers: `backend/catalog/translations/`. Tests: `tools/test_translation_pipeline.py`.

## Why it exists

Translation had four separate lanes (Supabase content, central procedure steps, Maharashtra Hindi, the local AI4Bharat factory), and none of them was set up to grow:

- Each new language or state needed a new one-off script (`add_tn_hindi.py`, `merge_tamil_nadu.py`, ...). Those scripts hand-wrote the same text into many places, and they drifted: `add_tn_hindi.py` updated the pack's languages but not the registry.
- Checks hardcoded `hi` and `ta`, and the factory has no reviewed path back into the catalogue.
- Job state lived in `admin.translation_jobs`, which went away with Supabase, and the factory folder is not in git.
- Nothing decided which lane wins when two disagree. Past "fixes" silently removed 39 Hindi translations.

## Rules the code enforces

| Rule | Where |
|---|---|
| The catalogue packs are the single master | `release.py` |
| English is never changed | `gate()` refuses any change outside the target language |
| Existing text is never overwritten unless a reviewer superseded that exact text | `apply_events()`, compare by checksum |
| Translations can never be lost, in any language | `gate()` compares coverage per language |
| A release is compared to the previous release, never to itself | `release()`; an identical candidate is refused |
| Numbers, lakh/crore, links and list alignment must survive | `checks.py`, blocking |
| The engine is recorded honestly and must be registered | `ingest()` |
| The writer cannot approve its own text | `approve_batch()`, `decide()` |
| A sampled batch stays `verified: false`; only a per-unit decision can set it | `approve_batch()`, `decide()` |
| Web-found English marked `pending_translation` is held back unless asked | `export_batch()` |
| Offering a language to users is a separate, explicit step | `apply` only adds to `available` |

## Flow

```
audit -> export -> engine -> ingest (checks) -> report -> approve / decide -> apply (gate) -> candidate packs
```

Every unit has a state in an append-only ledger, one file per language (`ledger/<lang>.jsonl`):

```
baseline: text already in the catalogue when tracking began
queued -> checked | needs_review | failed -> approved | rejected -> written
```

Re-runs skip finished units, a crash loses at most the line being written, and history is never edited. An illegal transition (say, written without approval) raises.

## Modules

| File | Job |
|---|---|
| `config.py` | Loads and validates `languages.json` and `glossary.json` |
| `units.py` | Flattens the catalogue into units. The only place that knows where text is stored (`source.name.hi`, `notes_ta`, `translations.hi.category`, ...) |
| `checks.py` | Deterministic checks, driven by the language's config |
| `ledger.py` | Append-only state per language |
| `stages.py` | `audit`, `lint`, `baseline`, `export`, `ingest`, `report`, `approve`, `decide` |
| `release.py` | Writes approved text to a copy, projects `localization.<lang>`, runs the gate, publishes |
| `cli.py` | Command line |
| `run_indictrans2.py` | Local model runner, one example of an engine |

## Checks

| Check | Severity | Catches |
|---|---|---|
| Number parity, any script's digits | Block | A changed or dropped figure |
| Lakh/crore parity | Block | "5 lakh" as "5 crore", which a digit check passes |
| Links and emails unchanged | Block | Broken or invented links |
| List length matches | Block | Steps shifted against the English |
| Script below 0.25 | Block | Wrong language, or English left behind |
| Same as English | Block | Untranslated text, unless it is only acronyms |
| Script below the language's ratio | Flag | Could be many proper nouns, so a person looks |
| Same as a sibling language | Flag | Hindi copied as Marathi: they share a script, so the script check cannot tell |
| Length ratio outside 0.4x to 3x | Flag | Truncated or padded text |
| Do-not-translate term changed | Flag | PMEGP, MSME and so on, unless the form is approved in the glossary |

These prove the facts survived, not that the meaning is right. In the Gujarati pilot, "Accelerator Support" passed every check but came back with the physics sense of "accelerator". That is why the sample review gate stays.

A reviewer can override a blocking finding with `decide` by recording `override_reason`. For example, "Rs 10 million" as "₹1 crore" is correct but fails the amount check.

## Tiers and jurisdictions

- **`core`**: what a scheme page needs. A jurisdiction needs this complete before the language is offered there.
- **`detail`**: `content.requiredDocuments` fields.
- **`reference`**: authorities, institutions, common terms, finance and so on. Only for languages with `reference_sections: true`.

Each language lists its `jurisdictions`, so Marathi covers Maharashtra only and Tamil covers Central and Tamil Nadu.

## Add a language

1. Add it to `backend/catalog/translations/languages.json`:
   ```json
   "gu": {
     "name": "Gujarati",
     "script_ranges": [[2688, 2815]],
     "jurisdictions": ["maharashtra"],
     "model_codes": {"indictrans2": "guj_Gujr"},
     "magnitudes": {"lakh": ["લાખ"], "crore": ["કરોડ"]},
     "months": ["જાન્યુઆરી", "ફેબ્રુઆરી", "માર્ચ", "એપ્રિલ", "મે", "જૂન", "જુલાઈ", "ઓગસ્ટ", "સપ્ટેમ્બર", "ઓક્ટોબર", "નવેમ્બર", "ડિસેમ્બર"]
   }
   ```
   Add `ordinals` and `siblings` where they apply. A language without lakh and crore words is refused, because its amounts could not be checked.
2. Have the owner approve its forms in `glossary.json`.
3. Run a small pilot and read the output:
   ```bash
   python tools/translation/cli.py audit --lang gu
   python tools/translation/cli.py export --lang gu --batch gu-001 --tier core --limit 50 --out work/gu-001.jsonl
   C:/development/MSS_Translation/.venv-indictrans-cuda/Scripts/python.exe tools/translation/run_indictrans2.py --in work/gu-001.jsonl --out work/gu-001.out.jsonl --target guj_Gujr
   python tools/translation/cli.py ingest --lang gu --file work/gu-001.out.jsonl --engine indictrans2 --revision bb1e8f49
   python tools/translation/cli.py report --lang gu --batch gu-001 --out work/gu-001.md
   ```
4. Review the report, then approve. Handle flagged and failed units one by one with `decide`:
   ```bash
   python tools/translation/cli.py approve --lang gu --batch gu-001 --reviewer <name> --report work/gu-001.md
   ```
5. Build a candidate and check it. `apply` only publishes if the gate passes:
   ```bash
   python tools/translation/cli.py apply --lang gu --out-dir work/candidate
   python tools/translation/cli.py --packs work/candidate audit --lang gu
   ```
6. When it is right, run `apply --lang gu --in-place`, then build the release as usual with `tools/build_catalog_release.py`.
7. Check `python tools/translation/cli.py readiness --lang gu` for what the app still needs. See below.

`decide` takes JSONL lines: `{"unit": "...", "decision": "approve" | "reject", "text": "...", "supersede": true, "verified": true, "override_reason": "...", "reason": "..."}`. Only `unit` and `decision` are required.

## Other engines

Anything can translate if it reads `{unit, checksum, en}` lines and writes `{unit, checksum, translation}` lines. A list in `en` needs a list of the same length back. Register the engine's name in `languages.json` so a typo cannot mislabel where text came from.

## Maintenance

- `audit --lang X`: coverage, gaps, stale text, and where the manifest registry disagrees with the schemes.
- `lint --lang X --out file.jsonl`: runs the checks over text already in the catalogue. Old text predates these rules, so each finding is a lead, not a verdict.
- `baseline --lang X`: records the English behind existing text so later edits show as stale. Claims nothing about who translated it.
- `export --stale`: re-queues text whose English changed. Replacing the old text then needs `decide` with `supersede: true`.

## What this does not cover

- **The app.** Screens and models branch on `hi` and `ta` in about 40 Dart files, and the UI needs an ARB file per language. A language in the catalogue is not visible until that work is done, which is why Marathi is `isActive: false`.
- **UI strings and phrase dictionaries.** ARB files and `translation_dictionary*.json` remain separate.
- **The older tools.** `add_tn_hindi.py`, `add_hindi_detail_text.py` and the factory's `merge_*.py` still exist. Do not use them for new work: they bypass the gate.
- **Provenance of existing text.** `baseline` leaves it as found, and old `engine` labels are not reliable.
