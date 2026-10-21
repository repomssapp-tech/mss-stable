# Sarvam managed voice-agent pilot — 2026-10-21

Status: feasible candidate; not enabled or deployed. The tested 1.2.3 app and
current Node voice flow remain live. Agent/workspace access is still needed.

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

This is an instruction draft, not an uploaded or committed Sarvam agent.

## Needed to run the pilot

- A Sarvam Voice Agents workspace with a created agent and committed version.
- Organisation ID, workspace ID and agent/app ID (not secret keys in chat).
- Voice Agents API credentials configured in the private server environment, or
  an authenticated Sarvam MCP connection for account-side authoring.
- The actual deployment branch must include the Node integration before rollout;
  current private backend GitHub access still returns 404.

Sources checked on 2026-10-21:
- https://docs.sarvam.ai/voice-agents/deploy/sdks/flutter
- https://docs.sarvam.ai/voice-agents/build/conversation-settings
- https://docs.sarvam.ai/voice-agents/build/tools/https-tool
- https://docs.sarvam.ai/voice-agents/deploy/deploy-with-code
- https://docs.sarvam.ai/voice-agents/mcp
- https://pub.dev/packages/sarvamconv_ai_sdk/versions/1.0.2
