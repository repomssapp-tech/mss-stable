# Saarthi conversational voice

Android **1.2.3 build 2008 is installed**, with existing data preserved. Backend
`4fc12cb17f5977b066bad2664abf455cd6169427` is deployed and healthy on v0.2.3.
It preserves the latest legal/profile/logging source at `3b6a1e1` and includes
the voice routes and selected-language fixes.

## Conversation and language

Saarthi AI mode uses the MSS Node API and Sarvam through an authenticated
WebSocket relay. The mobile app has no LiveKit/WebRTC or Supabase runtime
dependency. Provider keys stay on the server.

Tap once to start. Partial words appear while speaking; the server detects the
end of the turn and returns a final transcript. Only final or explicitly corrected
text is submitted to chat. Capture stops before inference and speech. After audio
and a 900 ms echo guard, listening resumes. Pause, End and backgrounding stop input
and invalidate pending callbacks. Backgrounding does not automatically resume.

English, Tamil, Hindi and Marathi are explicit choices. The voice choice survives
reopening; a later app-language change supersedes an earlier voice override. The
same selected locale controls recognition, reply delivery and speech. Chat drafts
from verified catalog evidence in English, then sarvam-translate:v1 renders Indic
replies using source en-IN and the exact target locale. Wrong-script output or
translation failure produces a selected-language retry message with no scheme
cards, rather than exposing the English draft. The app validates response locale
metadata and invalidates cached replay when language changes. Dedicated target
translation is stronger than following conversation language; it is not a claim
that every model wording is linguistically perfect.

Correct and Type pause input and use an inline editor. Review before sending is
optional. Longer pauses change endpointing from 1200 to 1800 ms; manual Finish is
also available. Corrections remove the mistaken latest exchange from model
history. The regular chatbot retains optional asynchronous recorded dictation
with explicit language, batch status polling and editable review.

## Audio and accessibility

Android checks spoken-feedback/touch-exploration services; a generic accessible-
navigation flag does not silence replies. Reader entry defaults to text and
explicit Resume, while reader exit restores default audio. Explicit audio choices
are preserved. Audio-off exposes Read aloud; speech failure preserves text and
provides retry without another chat request. Repeat reuses cached MP3 when present.
Each playback reapplies normal media routing with speech content and transient
focus, respecting headphones and system media volume.

Status has one live region; partials do not repeatedly announce themselves. The
view supports labeled controls, large text, keyboard editing and an explicit
Latest action without forced scrolling. Reader mode uses explicit Resume after
replies to avoid recording the reader's speech.

## Efficiency and verification

Tokens use the existing shared refresh mutex, never a URL. PCM16 mono 16 kHz is
streamed in bounded chunks. Partial UI rebuilds are capped at 120 ms; audio stays
in memory; model history is bounded. English delivery needs no translation call;
Indic turns add one translation bounded to 10 seconds. Scheme cards come from
published records scoped through the existing server service. Offline browsing
keeps the bundled catalog path.

Final Node verification: 189 passed, 2 skipped. Focused Flutter checks: 62 passed.
Flutter analysis is clean and the signed release build passed. Existing unrelated
account-dialog guard failures from the earlier broad run were not hidden by
baseline updates. API/database health, HTTP authorization and public WebSocket
upgrade/auth checks passed after activation.

On the connected phone, English Hello received the written Tamil reply
“வணக்கம்! இன்று நான் உங்களுக்கு எப்படி உதவ முடியும்?”. Tamil remained selected
after a full process restart. The user confirmed a Tamil replay was audible;
runtime showed app media/speech audio preparation at 24 kHz and playback completed
back to paused without an error. Read aloud was restored on and End used, leaving
the microphone off. Full physical TalkBack and recognition-in-noise testing remain
outside these checks. See `verification/saarthi-language-audio-results.json`.

## Deployment continuity

Separate deployments previously replaced the voice-enabled server with sources
that omitted the routes, causing 404 responses. After the user paused those
updates, the final integration preserved their legal/profile/logging changes and
version metadata. No migration/grant files changed relative to that deployed
source; no database rollout was performed. Previous releases remain for rollback.

Git CLI and the connected GitHub app cannot access mssschemes/backend (404).
Before resuming deployments, include `MSS-Backend-Voice-current.patch` in the
actual deploying branch. Workspace deliverables also contain a full current Git
bundle. The patch applies relative to source at `3b6a1e1`. The generated API
reference is copied under `backend/New API Ref/`. Keep legacy LiveKit resources
for older clients until their rollout is complete; shared resources were not shut
down. The signed APK is `../deliverables/MSS-Saarthi-1.2.3-2008.apk`.
