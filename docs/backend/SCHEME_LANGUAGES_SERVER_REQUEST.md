# Request: carry every scheme language and document detail in the server release

For: backend developer (scheme admin, `mssadmin.tech`, catalogue release generator)
From: app team, 3 November 2026
Status: the app works around these gaps today; the server should own this data.

## Why

Phones download the catalogue release from the server
(`GET /v1/catalog/current` then `/v1/catalog/releases/<tag>/bundle`) and use it
in place of the catalogue shipped inside the app. All scheme data should
therefore come from the server. Today three kinds of data cannot get there, so
app 2.3.0 fills them in from its shipped copy:

1. **Marathi** for the 79 Maharashtra schemes. The app now offers Marathi.
2. **Translated document names and the "required" marking** for every scheme.
3. **Other per-language detail fields** listed in the table below.

The app's fill only uses its own copy where the server has nothing, so once
the server carries these the app's copy is ignored automatically. No app change
is needed. The fill is in `frontend/lib/services/catalog/catalog_language_fill.dart`.

## 1. Accept Marathi (`mr`) in scheme uploads

**Now:** `POST /v1/admin/schemes/uploads` returns `INVALID_SCHEME_SOURCE` for any
record with an `mr` value. API_DOCUMENTATION.txt (line 796) allows only
`translations.en|ta|hi`, and "Unsupported languages ... fail validation".

**Tested through Preview on the admin site (nothing saved):**

| Upload | Result |
|---|---|
| A valid central or Tamil Nadu record, unchanged | valid (CHANGED) |
| The same record plus `name.mr` only | INVALID_SCHEME_SOURCE |
| The same record plus `translations.mr` only | INVALID_SCHEME_SOURCE |
| `f3_maharashtra/maharashtra_schemes_app_2026.json`, as is (79 records) | all 79 invalid |
| The same Maharashtra record with every `mr` value removed | still invalid |

API_DOCUMENTATION.txt (line 784) says the Maharashtra file fits the upload as is,
but it does not. The error does not say which field failed, so I could not tell
what else is wrong. Two small asks: return the failing field path with
`INVALID_SCHEME_SOURCE`, and make the Maharashtra file upload.

**Needed:**
- Allow `mr` wherever `hi` is allowed: `name`, `description`, `benefits`,
  `eligibility`, `how_to_apply.steps`, `name_source`, `translations.mr.*`
  (`authority`, `category`, `status.note`, `how_to_apply.mode`,
  `how_to_apply.notes`, `how_to_apply.documents`, `contacts`, `alt_names`) and
  `benefit_facts.facts[].translations.mr`.
- Store it: check any `CHECK` or enum constraints on the scheme localization
  tables, in the same way migration016 widened profile languages to `en|ta|hi|mr`.
- Emit it in the release: `localization.mr` on each Maharashtra scheme,
  `search.aliases.mr` and `search.keywords.mr`.
- Marathi is offered for **Maharashtra schemes only**; central and Tamil Nadu
  schemes have no Marathi and need none.

Source data: `maharashtra_schemes_app_2026.json` has `mr` for all 79 schemes.
The same text is in the app's shipped `frontend/assets/catalog/catalog_maharashtra.json.gz`.

## 2. Publish documents with their translations and required marking

**Now:** each release document is only
`{"name": "<English text>", "mandatory": "unknown"}` (774 documents in `schemes-6`).

**The app's shipped copy has, per document:**

```json
{
  "documentId": "TN2026-001-DOC001",
  "name": {"en": "Udyam / Entrepreneur Memorandum registration record", "hi": "..."},
  "mandatory": "required",
  "description": {"en": "...", "hi": "..."},
  "issuingAuthorityText": {"en": "...", "hi": "..."}
}
```

The Tamil names are in a separate list, in the same order as the English names:

```json
"localization": {
  "en": {"documents": ["Udyam / Entrepreneur Memorandum registration record", "..."]},
  "ta": {"documents": ["உத்யம் / தொழில்முனைவோர் குறிப்பாணை பதிவுச் சான்று", "..."]}
}
```

Uploaded master files already carry the Tamil names as
`translations.ta.how_to_apply.documents` (and `how_to_apply.documents_ta`), and
uploads that include them are accepted. **The release generator drops them.**
Please emit `localization.<lang>.documents` for every language you hold.

The `mandatory` value (`required` / `optional` / `unknown`) and the other
document fields come from the older catalogue. Most do not exist in the upload
format, where `how_to_apply.documents` is plain text. Please decide where
the server should keep them: either accept document objects in the upload, or
import them once from the app's shipped packs.

## 3. Other fields the release leaves out

Counted across all 406 schemes, comparing `schemes-6` with the app's shipped catalogue:

| Field | Shipped | Missing from `schemes-6` |
|---|---|---|
| `localization.<en,hi,ta>.mode` | 406 en, 406 hi, 327 ta | all |
| `localization.<en,hi,ta>.documents` | 188 en, 188 hi, 179 ta | all |
| `localization.<en,hi,ta>.notes` | 210 en, 210 hi, 136 ta | all |
| `localization.<en,hi,ta>.shortName` | 177 each | all |
| `localization.<en,hi,ta>.altNames` | 230 en, 58 hi, 53 ta | all |
| `localization.<en,hi,ta>.contacts` | 54 en, 42 hi, 5 ta | all |
| `localization.hi.*` on Tamil Nadu schemes | 53 | all. Intended: Tamil Nadu offers en and ta only. |
| `content.applicationTimeline`, `targetBeneficiaries`, `appRelevance` | 406 | all |
| `content.portalInfo` | 45 | all |
| `content.requiredDocuments` | 185 schemes | 50 schemes have none |

## 4. Tamil corrections the upload cannot carry

The audit corrected Tamil scheme text. Uploading it through the admin site
published corrections for 121 schemes (`schemes-6` and the release after it).
These still need a decision on the server side:

- **Seven corrections where the master text differs from both versions:**
  CEN2026-106 (benefits), CEN2026-180 and CEN2026-183 (eligibility),
  CEN2026-226 and CEN2026-227 (authority), and CEN2026-227 (description and
  summary). The server's text for these is neither the old nor the corrected
  wording, so someone should read them in the admin editor.
- **Six schemes with newer admin edits than the master files:**
  CEN2026-001, 019, 021, 051, 080 and 090. I left them out so the upload would
  not overwrite those edits. Their Tamil should be reviewed in the admin editor.
- **Summaries:** the release builds `summary` from the description. The app's
  shipped summaries are separate, edited text, so a summary correction only
  reaches phones through a description change.

## 5. Smaller items found while publishing

- Approving 112 drafts at once hit `SCHEME_ADMIN_RATE_LIMITED (HTTP 429)`. Batches
  of 10 worked.
- **Notify users** is ticked by default on the Releases page. Easy to send a
  notification to everyone by mistake.
- Publishing the master files changed more than Tamil: 13 guideline links,
  4 prerequisites and new Hindi search aliases came from the files. These were
  already in the files, not new edits.
- `TN2026-999 TEST – MSS Notification Check Scheme` is still live on phones; its
  withdrawal draft is waiting for approval.
- 40 drafts I staged change only Tamil document names, which the release drops.
  Approve them once section 2 is done, or discard them.
- API_DOCUMENTATION.txt (lines 183-188) says scheme-admin publication does not
  move the legacy catalogue pointer, but `/v1/catalog/current` now serves
  `schemes-N` releases from the admin site.

## How to check

```bash
curl -s https://mssapi.msmeschemes.org/v1/catalog/current
curl -s https://mssapi.msmeschemes.org/v1/catalog/releases/<tag>/bundle -o bundle.json.gz
python - <<'EOF'
import gzip, json
b = json.load(gzip.open('bundle.json.gz', 'rt', encoding='utf-8'))
s = b['scheme_catalog.json']['data']
mr = sum('mr' in x['localization'] for x in s)
ta_docs = sum(bool((x['localization'].get('ta') or {}).get('documents')) for x in s)
req = sum(d.get('mandatory') == 'required' for x in s for d in x['content'].get('requiredDocuments') or [])
print('schemes with Marathi', mr, '(expect 79)')
print('schemes with Tamil document names', ta_docs, '(expect 179)')
print('documents marked required', req, '(expect > 0)')
EOF
```
