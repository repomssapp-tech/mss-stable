# Sarvam managed voice-agent pilot — 2026-10-21

Status: managed Tamil pilot created in Sarvam and committed through v2. It is
not enabled in the mobile app. The tested 1.2.3 app and current Node voice flow
remain live. A separately approved Voice Agents credential is stored only in
the server's private environment; credential values are not recorded here.

## Created pilot

- Agent: Saarthi Scheme Assistant (`Saarthi-Sch-91830352-d966`).
- Organisation: `019fce01-6f3b-7533-bb39-fa646862c464`.
- Workspace: `019fce01-6f42-797f-b7ab-07ffba1fa3a3`.
- Tamil is the sole allowed/starting language. Both smart and automatically
  detected language switching were explicitly disabled.
- Speaking speed 1.0, full output volume, Patient turn taking, normal sound
  threshold, no artificial background sound, no silence nudges or voicemail.
- Greeting and both gender-specific greeting translations identify Saarthi
  in Tamil. The template's original name was removed.
- v2 uses Tamil instructions to reduce mixed English phrases seen in a v1
  dashboard reply. Scheme facts remain restricted until the verified lookup
  is implemented and connected. This is intentionally a pilot, not a complete
  scheme-advice deployment.

The authenticated runtime signed-URL request succeeded with HTTP 200. Synthetic
speech testing of v2 produced an actual Tamil reply with nonzero audio samples
after an English request to answer in English. Captured output: 435200 PCM bytes,
16000 Hz mono, peak 25641, 147114 nonzero samples; the recording includes greeting
and silence as well as the reply. Reply: "என் பெயர் சாரதி. அரசுத் திட்டங்கள்
பற்றி உங்களுக்கு என்ன உதவி தேவை என்று சொல்லுங்க."
This is a server-side protocol test, not a phone speaker or TalkBack test.

**Strict-language gate is not passed.** The dashboard test against the equivalent
v3 working draft (unchanged from committed v2) refused to invent a housing benefit
or application link, but still inserted the English words "application link" in
its Tamil response. Disabling language switching and adding Tamil instructions
does not by itself prove zero code-switching. A reviewed output-language check
and fallback are required before production rollout; do not label the managed
agent as guaranteeing the user's selected delivery language.

## Verified platform fit

Official documentation supports Flutter voice sessions, initial language,
streaming transcript/audio callbacks, custom audio I/O and a backend proxy.
Conversation settings expose allowed languages and separate smart/automatic
language switching controls. HTTP tools can call the existing scheme backend.

Published package checked directly from pub.dev: sarvamconv_ai_sdk 1.0.2.
Source confirms sendText, typed session events, pinned committed versions,
optional apiKey, backend baseUrl and app-auth headers. Existing record/http/socket
constraints overlap the package requirements; a full app dependency/build check
is still required once adding it. No dependency was added for this assessment.

## Android audio integration finding

The published default audio adapter invokes com.sarvam.audio/playback (init,
play, stop, dispose). The 1.0.2 archive has no registered Flutter plugin or native
implementation for that channel; initialization errors are caught and printed.
The MSS app does not currently implement that channel. Installing the SDK alone
would therefore not establish Android playback. Use a reviewed native PCM audio
adapter and test on the actual phone. Do not infer successful audio from an open
socket or transcript alone.

Use custom I/O to retain ownership of mic start/stop, queued playback, pause,
background cleanup, errors and reader-safe explicit resume. The SDK has start,
stop and sendText, but no public pause/resume method. Pausing a connection cannot
be assumed to freeze server turns or billing. Test interruption, context recovery
and reconnection explicitly; signed URLs are single-use.

## Proposed application integration

1. Keep the existing accessible Saarthi screen, language preference and text
   fallback. Add a managed-agent controller behind an explicit feature flag.
2. The authenticated Node backend selects an allowlisted agent/version and
   requests a signed session; store the Voice Agents key only on the server.
   Never trust client-supplied organisation, workspace, user identity or URLs.
3. Match initial language to the selected preference; disable smart and detected
   language switching. Test all four targets, including mixed-language input and
   requests to switch. If a shared agent cannot enforce this adequately, use
   separately configured agents restricted to each delivery language.
4. Expose a narrowly scoped scheme lookup tool backed by the existing published,
   owner/state-scoped scheme service. Bind tool calls to a short-lived, opaque
   server-issued session capability; never expose the general MSS bearer token
   in prompts or treat a caller-provided user identifier as authorisation.
5. Preserve trusted result IDs for cards independently of model prose. Keep
   correction/typed input, long-pause settings and reader-friendly controls.
6. Pilot with synthetic requests first. Compare speech-end-to-first-audio,
   wrong-language rate, silence handling, interruptions, background cleanup,
   reconnection, TalkBack, speech failures and per-minute cost against the working
   baseline before replacing the active flow.

## Agent instruction draft

You are Saarthi, an assistant for verified Indian government schemes. Speak in
the delivery language selected in this agent's configuration for the entire
session. Do not infer the delivery language from the user's accent, transcription,
previous messages or instructions to switch languages. A language change must
come from the application's explicit language control. Use native script for
written replies and keep official scheme names and identifiers accurate.

Give one to three short, clear sentences and ask at most one useful follow-up
question. Before stating current scheme benefits, amounts, eligibility, deadlines
or application links, use the configured verified-scheme lookup tool. Use only
facts it returns. If the tool has no matching evidence or fails, explain that in
the selected language and ask for the missing detail. Never invent scheme cards,
links or final eligibility/approval. Never ask for Aadhaar, OTPs, passwords or bank
account credentials. Accept corrections and use the corrected details for future
answers. The app's Pause, End and Type controls manage the interaction.

This generic instruction draft describes the eventual grounded integration.
The created Tamil pilot uses a stricter Tamil instruction set which explicitly
states that verified lookup is not yet connected.

## Runtime findings from the synthetic pilot

- A socket can emit continuous silent PCM before the interaction is ready.
  Initial silent input frames were required in the tested runtime before the
  connected event/greeting. Send bounded synthetic silence for bootstrap;
  do not open the real microphone merely because the socket is open.
- Current TypeScript SDK 0.0.42 uses `input_sample_rate` and
  `output_sample_rate` URL parameters; Flutter 1.0.2 still uses `sample_rate`.
  Use the current verified runtime contract for a reviewed custom adapter.
- Transcripts arrive as `server.event.transcription` with `role` and `content`.
  Flutter 1.0.2's parser does not support that current event. Its text callback
  alone cannot be relied upon to populate accessible live captions.
- TypeScript 0.0.42 restricts `sendText` to chat interactions. A direct typed
  message during the voice pilot did not produce another reply. Typed correction
  and session context therefore need a deliberate integration, not an assumed
  capability of the old Flutter SDK.
- An interruption can generate an empty completed-audio event. Only count a
  reply after input finishes and actual nonzero output is received; this was
  caught while improving the smoke test.

The local deliverables/sarvam-agent directory contains synthetic smoke evidence
and screenshots. No production personal speech or credentials are included.

## Needed to run the pilot

- A reviewed Android PCM adapter and accessible transcript/event integration.
- A backend session proxy and a published, owner/state-scoped lookup tool,
  bound to the authenticated MSS user with short-lived opaque capabilities.
- Verified typed correction, explicit pause/resume and session-context behavior.
- Separately restricted delivery-language configurations for en/hi/mr, or proof
  that one runtime configuration enforces each explicit language selection.
- Real-device audio, pause/background cleanup and TalkBack verification before
  the managed controller replaces the working production flow.
- The actual deployment branch must include the Node integration before rollout;
  current private backend GitHub access still returns 404.

Sources checked on 2026-10-21:
- https://docs.sarvam.ai/voice-agents/deploy/sdks/flutter
- https://docs.sarvam.ai/voice-agents/build/conversation-settings
- https://docs.sarvam.ai/voice-agents/build/tools/https-tool
- https://docs.sarvam.ai/voice-agents/deploy/deploy-with-code
- https://docs.sarvam.ai/voice-agents/mcp
- https://pub.dev/packages/sarvamconv_ai_sdk/versions/1.0.2
