# Saarthi conversational voice

Current rollout: Android **1.2.3 build 2008 is installed**, with data preserved.
A separate backend deployment subsequently replaced the tested voice-enabled
release; the latest observed server release is `9ab487b` and omits the voice
routes. Full phone audio verification is blocked by those 404 responses.
An integration preserving the newer v0.2.3 legal/profile changes is prepared at
`6107ebcec22fcd8922481427ee173a65222e8702` (189 passed, 2 skipped). Activation
stopped when the expected running release changed again. Pause concurrent API
deployments and include the voice patch upstream before continuing activation.

Saarthi AI mode uses the MSS Node API and Sarvam directly through a protected
WebSocket relay. The mobile app has no LiveKit/WebRTC dependency or Supabase
runtime dependency. Keys stay in the server environment.

Tap once to start. Partial words appear while speaking; Sarvam detects the end
of the turn and returns a final transcript. Only that final text is submitted to
chat. Input stops completely before inference and speech playback. After playback
and a 900 ms echo guard, listening resumes. Pause, End and backgrounding stop the
microphone and invalidate pending callbacks. Backgrounding never auto-resumes.

Choose English, Tamil, Hindi or Marathi explicitly in voice options; the selected
locale is sent to recognition, chat and speech. The voice choice is remembered
when Saarthi is reopened; a later change to the app language supersedes an older
voice override. Chat drafts grounded guidance in English, then a dedicated
translator renders Tamil/Hindi/Marathi using the explicit selected target.
Wrong-script output or translation failure returns a localized retry message
instead of exposing the English draft. Responses echo the selected language,
and the client rejects mismatching metadata. Changing language clears cached
replies so Repeat cannot play the previous language. Longer pauses change endpointing
from 1200 to 1800 ms. Finish speaking manually is also available. Correct and Type
pause input and open an inline editor. Review before sending is optional. Correcting
the latest completed request removes that mistaken exchange from model history.

Android checks enabled spoken-feedback/touch-exploration services; a generic
accessible-navigation flag alone cannot disable reply audio. Explicit audio
choices are preserved and the default is restored when a reader leaves.
Screen reader mode defaults to text replies and explicit Resume, preventing a
reader's speech from becoming a new request. Status is one live region; partial
words are readable without repeated announcements. Controls have labels, the view
supports large text and keyboard access, and Latest reveals the start of a reply
without forcing the user's scroll position. Read aloud and cached Repeat are
available. Audio-off exposes a Read aloud action. Speech failure preserves the
written reply and offers a specific retry message; Repeat retries speech without
resubmitting chat. Each playback reapplies normal Android media routing with
speech content and transient audio focus, respecting connected headphones and
system media volume.

The regular chatbot still offers recorded audio: up to 60 seconds in memory,
explicit-language Sarvam batch job, five-second status polling and editable review.
This asynchronous flow is useful for dictation; conversational endpointing is used
in Saarthi mode to avoid waiting for a batch job every turn.

## Transport and efficiency

`wss://mssapi.msmeschemes.org/v1/voice/stream` authenticates with the existing MSS
bearer token in its first frame, never a URL. It relays PCM16 mono 16 kHz. Sessions
are bounded and rate limited. The existing token refresh is shared across calls.
There is no per-turn account lookup from the client. Partial UI rebuilds are capped
at one per 120 ms. Audio remains in memory; Repeat reuses the last MP3. Model
history is bounded. Chat uses published schemes scoped by the existing server
scheme service; model output cannot invent card identities. Offline scheme browsing
retains the bundled catalog path.

## Deployment and validation

Backend commit `bb7ec782f3f545842c13e5a16a1fc2d7451c5820` was deployed through the
existing immutable release procedure on 2026-10-21 after user approval. Nginx HTTPS
WebSocket upgrade and route timeouts were validated and reloaded; only the API was
restarted. Health/database checks and public unauthorized-route tests passed. The
previous release and Nginx backup remain available for rollback. No schema changes
or production test accounts were created. The backend commit is local/deployed;
GitHub push credentials were unavailable.

Backend verification: 171 tests, 169 passed and 2 skipped. A synthetic English clip
through the real Sarvam realtime provider produced partial text about 615 ms after
streaming began and a final about 1.9 seconds after the clip ended. This is one
local relay measurement, not an on-device latency guarantee. Batch jobs and speech
in all four selected languages were checked separately.

Final focused Flutter checks: 50 passed, including layout at 320dp/200% text in
en/ta/hi, keyboard editing, labels/contrast/tap targets, token refresh, correction,
manual finish, late events, stopping input before replies and screen reader mode.
Analysis reports no issues. The broad run passed 1233 tests with 3 skipped; its
six failures included five existing design guard failures in untouched account
dialogs and one new spacing issue. The new issue and added button overrides were
fixed; final spacing/focused checks pass and the remaining five guard failures
reference only the same three untouched account dialogs. Baselines were unchanged.
Physical TalkBack and a spoken conversation still require a human check; automated
semantics checks do not establish recognition accuracy on the phone.

The generated backend API reference is copied under `backend/New API Ref/`.
Keep legacy LiveKit resources available for older installed clients until their
rollout is complete; this update does not shut down shared legacy infrastructure.

## Installed Android release

Version 1.2.2 build 2007 was installed successfully with `adb install -r`, using
the same signing certificate and retaining existing data. On the connected phone,
Start reached Listening with the deployed relay, Pause exposed Resume, and End
returned to the initial screen. The app moved to the background during the inline
editor assertion, so that device journey stopped there. No physical TalkBack
service was enabled. See `verification/saarthi-android-results.json` for the exact
checks and limits. The signed APK is in
`frontend/build/app/outputs/flutter-apk/app-release.apk`.

## Selected-language and audio fix (2026-10-21)

Backend `7078bdc44016e66c1429662246352f7dec5f466c` was deployed and verified healthy,
then was superseded by the separate releases described above.
Its full verification passed 179 tests with 2 skipped. Live synthetic requests
returned selected-language replies and nonempty MP3s in en/ta/hi/mr despite a
different language in history. Final app checks passed 62 focused tests and clean
analysis. This includes actual playback adapter configuration, audio preference
restoration, native accessibility probing, wrong-locale rejection, retry without
repeating chat, language cache invalidation and persistence.

Release 1.2.3 build 2008 was installed after USB reconnection; version and
package checks passed. End was used after the failed route check to leave the
microphone off. Integration and upstream publication are still pending deployment
coordination. Provider audio
generation and automated playback checks do not establish that sound was heard
on the physical phone. See `verification/voice-language-audio-fix.md`.
