# Server-side issues found while testing the app (2026-10-19)

Found by running the debug build on the Pixel_7 emulator against
`https://api.msmeschemes.org`, and by auditing the app against
`backend/New API Ref/API_DOCUMENTATION.txt`. Items marked **Confirmed** were seen
on the device; **Unverified** need a check on the server.

## 1. Legal documents never reached the app (Confirmed symptom, cause unverified)

After a real Google sign-in the app still held its "agreement given on the
sign-in screen" flag (`legal_login_agreement_v1`) and had no recorded consent, so
`PUT /v1/me/onboarding` was never sent.

The app clears that flag only when `GET /v1/me/legal-documents` answers
`configured: true` with at least one item. Please check, for the account used:

- Does `GET /v1/me/legal-documents` return `configured: true` and the four
  types `terms`, `privacy_policy`, `privacy_notice`, `consent`?
- If it returns `configured: false`, onboarding stays blocked
  (`LEGAL_DOCUMENTS_NOT_CONFIGURED`).
- Any 4xx/5xx on this route has the same effect.

The app now retries this call just before sending onboarding.

## 2. New-account profile language defaults to `en` (Confirmed)

A fresh profile reports `language: "en"`, which the app used to treat as the
user's choice and so overwrote the language picked before sign-in. The app now
keeps the local choice while the profile is incomplete. No server change needed,
but note the server only stores `en` and `ta`; Hindi (and Marathi) stay on the
device only.

## 3. Catalog publishing (needs confirmation)

The app now installs ONE gzip containing every scheme and assigns schemes to
states from each scheme's own jurisdiction. Please confirm:

- The gzip is one JSON object keyed by section file name
  (`scheme_catalog.json`, `manifest.json`, ...), each section `{metadata, data}`.
- `GET /v1/catalog/current` returns `package_sha256`, `package_byte_size`,
  `release_version`, `bundle_url` and `record_counts` (the app tolerates any of
  these being absent, but then skips the matching check).
- If the embedded `manifest.json` lists `recordCounts`, they must equal the real
  row counts; otherwise the app rejects the download and keeps the old catalog.
- Uncompressed size stays under 256 MB (the app refuses larger files).
- Release tags are plain (`1.37.0`); the app sanitises anything else.

## 4. Allowed values are not documented (Unverified)

The app sends the following; please confirm the server accepts them, or publish
the allowed lists for `PUT /v1/me/onboarding` and `PATCH /v1/me/profile`:

| Field | App sends | API sample shows |
| --- | --- | --- |
| `applicant_type` | `Student`, `Entrepreneur`, `Business`, `MSME Owner`, `Farmer`, `Artisan / SHG Member` | `Individual` |
| `education_level` | `School`, `Diploma`, `Undergraduate`, `Postgraduate`, `Ph.D.` | `Graduate` |
| `community` | `General`, `OBC`, `SC`, `ST`, `EWS`, `Minority` | `General` |
| `annual_income` | one number per income band (e.g. `450000` for the 3-6 lakh band) | `300000` |
| `gender` | `Male`, `Female`, `Other` | `Female` |

The business `STUDENT_WITHOUT_VENTURE` rule is applied by the app: a student with
no registration, funding or registration numbers is sent `business: null`.

## 5. Routes the app calls that are not in API_DOCUMENTATION.txt (Unverified)

Kept as assumed routes in `lib/services/backend/pending_endpoints.dart`:
`/beta-gate/verify`, `/me/chat-sessions`, `/chat`, `/voice/token`. Please
publish the contracts or tell us they are not coming.

## 6. Not yet exercised against the real server

Notifications, promotions, favorites sync, eligibility-results sync, support
tickets and account deletion were not exercised in this run.

## 7. Profile fields came back empty after an app restart (Confirmed symptom, cause unverified)

On the emulator all four profile steps were completed (name, phone, gender, age,
address, role, education, community, income). Onboarding was not sent (item 1),
only draft `PATCH /v1/me/profile` calls. After reinstalling and reopening the app,
the profile showed phone, gender and age empty again. Please check whether
`GET /v1/me/profile` returns fields saved only through drafts, and whether the
response carries an `updated_at` newer than the app's local copy (the app prefers
the newer one).
