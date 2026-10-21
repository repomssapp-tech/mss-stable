# Recorded Saarthi voice over MSS REST

The current Flutter app no longer depends on LiveKit/WebRTC or a Python cloud
worker. Authentication uses the MSS Node bearer token and the existing API
client, including its single-flight refresh logic.

1. Choose English, Tamil, Hindi or Marathi explicitly. Record at most 60 seconds
   of PCM16 mono 16 kHz in memory; recording stops when the app loses focus.
2. Stop recording, then upload to `POST /v1/voice/transcriptions`. The server starts
   a Sarvam batch job with the selected locale (no automatic language guessing).
3. Poll `POST /v1/voice/transcriptions/status` every five seconds with the returned
   handle. It is signed, bound to the authenticated account and expires in 15 minutes.
4. Review/edit the transcript before sending. Retry polling the same job after
   transient errors; changing language resubmits the retained clip. Typed input
   remains available. No recording is written to application storage.
5. Send reviewed text to `/v1/chat`. The server uses published active schemes
   visible to the signed-in user's saved profile state, through its existing
   scheme service. The model cannot create scheme card identities. Results are
   guidance, not eligibility certification.
6. Display text, then call `/v1/voice/speech` and play MP3 bytes. Speech failure
   preserves the text reply. Interrupt/close invalidate late responses and stop
   playback. Failed requests retain the reviewed text for the next microphone tap.

The regular chatbot reveals replies gradually using Unicode grapheme clusters;
reduced-motion users receive the whole reply. Long replies do not force a scroll
to the end.

## Server rollout (operator)

The server source is in the sibling `mss-backend` checkout. Its generated
`API_DOCUMENTATION.txt` is authoritative; the copy here documents the same change.
Server environment needs `SARVAM_API_KEY` (never in Flutter defines or source).
The supplied key has been configured in the private server environment. Live
Sarvam chat, MP3 synthesis and batch jobs in English, Tamil, Hindi and Marathi
passed with their selected locales; the Node routes are
not deployed yet. The server checkout has no GitHub push credentials, so backend
commit `1aae14e` remains local and in a transferred Git bundle.
No database migration or production fixture/import is required for this change.

Run Node >=24, `npm ci`, then `npm run verify`. Publish/review the backend branch
and deploy using the existing release procedure. Existing production code was
left running. This checkout alone does not make the routes live.

The reverse proxy must permit a 3 MB request body for `/v1/voice/transcriptions`
(JSON includes base64 overhead), and allow at least 90 seconds for job creation.
Use at least 70 seconds for `/v1/chat`, and 40 seconds for speech and status.
Retain HTTPS, authentication and the current trusted-proxy policy.

Before installing the release, test signed-in chat, each voice language, transcript
correction, permission denial, silence, offline retry, interruption and backgrounding.
Vendor processing can continue after the dialog closes; closing stops local polling.
Audio and text are sent to Sarvam, and are not logged by these Node routes.

Keep the legacy LiveKit worker available for older installed clients until the
mobile rollout is verified. Its workflow is already manual-only. Retire its cloud
resources separately after migration; this change does not shut down shared services.
