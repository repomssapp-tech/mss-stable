# Backend routes the app expects but `backend/New API Ref` does not define

The app now talks only to the MSS REST backend (`https://api.msmeschemes.org`,
override with `--dart-define=API_BASE_URL=...`). `backend/New API Ref/` documents
48 operations (`API_DOCUMENTATION.txt` is the central reference). The app uses
auth, profile and onboarding, account deletion, notifications, promotions, the
catalog update, support tickets, favorites and eligibility results exactly as
written there. It deliberately does not use the scheme list/search/sync routes
(see `LOCAL_DATA_AND_SYNC.md`), the notification SSE stream or push devices.

Everything below replaced a table, RPC or function of the old hosted backend and
is **not among those 48 operations**. `API_DOCUMENTATION.txt` says the old
voice-agent services are separate systems and "not advertised as Node APIs", so
these four stay assumptions, kept in one place
(`frontend/lib/services/backend/pending_endpoints.dart`) so they can be changed
the day the real contract exists. Until a route exists the server answers
404/501 and the feature degrades as described.

All routes are under `/v1`, authenticated with the Node bearer token unless
noted, and take the account from the token (never from the body).

| Route | Was | Request | Response | Behaviour while missing |
|---|---|---|---|---|
| `POST /v1/beta-gate/verify` | table `beta_gate_config` | `{password}` (public) | `{unlocked: bool}` | Gate is off by default (`isBetaModeEnabled = false`); a device that unlocked earlier stays unlocked |
| `POST /v1/me/chat-sessions` | table `voice_chat_sessions` | one session: `{session_id, status, transcript[], session_metrics, created_at, ended_at}` | 2xx; `409` if already stored | Sessions stay queued on the device and retry on the next launch |
| `POST /v1/chat` | edge function `sarvam-chat` | `{language: en\|ta\|hi\|mr, messages: [{role, content}]}` | `{reply, usage?}` | Text assistant shows a connection error |
| `POST /v1/voice/token` | edge function `livekit-token` | LiveKit token-source body plus `{language}` | `{server_url, participant_token, participant_name, room_name}` | Voice falls back to the on-device assistant |

Not replaced (no endpoint in the reference):

- **Draft questionnaire cards** on the home carousel (table `questionnaire_sessions`): no cards are shown.
- **Realtime / push**: the notification inbox is polled (see `LOCAL_DATA_AND_SYNC.md`). The reference offers an SSE stream (`/me/notifications/events`) and FCM push devices (`/me/push-devices`); they need Firebase setup and a long-lived connection, so they are not used yet.

## Legal consent for onboarding (decided)

`PUT /v1/me/onboarding` completes a profile only with `legal_acceptances` for the
four current server documents (terms, privacy_policy, privacy_notice, consent).
The user sees **three** documents and nothing is split further:

| What the user sees | When it is accepted | Server types recorded |
|---|---|---|
| Terms of Use | Sign-in screen: opened, scrolled to the end, Accept | `terms` |
| Privacy Policy | Sign-in screen: opened, scrolled to the end, Accept | `privacy_policy` |
| Privacy & data use (what the data is used for, privacy notice and consent together) | Automatically when the profile is completed. The profile page shows a notice and a "Read how your data is used" link; there is no checkbox | `privacy_notice` + `consent` |

There is no consent checkbox on the sign-in screen: Sign in unlocks once both
documents were accepted. After sign-in the app reads `GET /v1/me/legal-documents`
and records the current `terms` and `privacy_policy` versions; when the profile
is complete it records `privacy_notice` and `consent`; only then is the final
onboarding call sent with all four. Until all four are recorded, or while the
server's documents are not configured, the profile is saved through
`PATCH /v1/me/profile` only. The onboarding body is never sent with an empty
required field.

## Language

`language` in the profile payload carries every interface language the app
offers (`en`, `ta`, `hi`, `mr`). **The server must accept `hi` and `mr`**, the
API reference lists only `en|ta`; until it does, a patch with `hi`/`mr` is
rejected.

## Voice language contract (`POST /v1/voice/token` → saarthi-agent)

The user's interface language must reach the voice agent, which then speaks it.

1. The app sends `language` in the token request body (`en`, `ta`, `hi` or `mr`).
2. The server normalises it (`hi-IN`, `HI_in` → `hi`), **ignores anything not in
   that list**, and puts it in the agent dispatch metadata next to the profile:

   ```json
   {"schema": "in-schemes-profile-v1", "profile": { }, "language": "hi"}
   ```

   Room, identity and dispatch values stay server-controlled; `language` is the
   only client-supplied value used.
3. `saarthi-agent/src/agent_language.py` maps it to the prompt language,
   greeting, TTS locale and voice. A session without `language` (older app) uses
   the environment defaults (Tamil).

`POST /v1/chat` takes the same four language codes.

## Needs your review (2026-10-19)

1. **Assumed routes with no contract**: `/beta-gate/verify`, `/me/chat-sessions`, `/chat`, `/voice/token` (see `pending_endpoints.dart`).
2. **Onboarding body** (`profile_cloud_sync.dart`): now sends the full writable profile (no `email`; `phone` = 10 digits, `pincode` = 6 digits). If any required field is empty the onboarding call is skipped and only PATCH drafts are sent. `applicant_type` is sent from the app's employment status (e.g. `Student`); the API sample uses `Individual`. Please confirm the accepted values. A student venture with no registration/funding is sent as `business: null` (STUDENT_WITHOUT_VENTURE).
3. **Consent**: three documents for the user, four server types (see above). Confirm `privacy_notice` and `consent` may be accepted together with the data-use page.
4. **OTA catalog** (resolved): the admin site changes schemes, the server builds ONE gzip of all schemes, the app downloads it, decompresses it and wires schemes to states from each scheme's own jurisdiction. The app no longer requires packs or bundleFormat 3 for a downloaded release; only an empty schemes section is refused.
5. **Hindi/Tamil strings I wrote** (consent scroll alert, scheme section labels) need a human reviewer.
6. **Untested against the real server**: Google sign-in and every call above.
- Server-side findings: see [SERVER_SIDE_ISSUES.md](SERVER_SIDE_ISSUES.md).

## Status of the overnight brief (2026-10-19, updated)

| Item | Status |
|---|---|
| Onboarding body sends every required value | Done, covered by `test/profile/profile_and_onboarding_test.dart` |
| "Needs your review" list | Above |
| Stress / exceptional-case testing | To be tested later |
| Emulator visual check + real Google sign-in | **On hold**; only the required API list is written (sections above) |
| Push, PR | To be verified later (branch `feat/rest-backend-migration`) |
| `color_tokens` / `type_scale` guard tests | Passing on this branch |
| Data-usage consent | Accepted automatically when the profile is completed; the profile page only offers a link to read it. No consent checkbox on the sign-in or profile pages. |
