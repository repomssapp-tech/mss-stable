# Saarthi native conversation — 2026-10-21

MSS 1.2.6+2011 uses the authenticated MSS WebSocket at `/v1/voice/agent` for
Android conversation mode. Sarvam produces conversational speech directly;
the selected session language remains fixed. Reviewed speech and longer-pause
settings retain the editable one-turn path. Provider credentials stay on the
server, and signed provider URLs never reach the app.

The committed voice agent is `Saarthi-Sch-91830352-d966` version 9. The reviewed
chat twin is `Saarthi-Sch-f1200b0a-9d34` version 2. The backend release is
`801b49af519785166850789e51d4eabce209a4b7` (API 0.2.3).
Tamil uses Vijay Narrator, English/Hindi use Shubh AI Companion, and Marathi
uses Nilesh Conversational Voice. Reviewed playback uses matching Bulbul v4
Flash personas, and selected-language Mayura classic-colloquial translation.

## Lookup configuration

The HTTP tool POSTs generated English keywords to `/v1/voice/agent/lookup`.
Authorization must use **Agent variable** `mss_lookup_token` directly; the
runtime supplies the complete Bearer value. A model-generated field containing
`Bearer {{mss_lookup_token}}` does not interpolate this context-disabled variable
and caused HTTP 401. Content-Type is a fixed `application/json` value. The query
body remains a required model-generated argument.

Each lookup capability is random, expires with one live call, is excluded from
model context, and is revoked when the call closes. The backend revalidates the
owner and reads published, state-scoped catalog records. The agent cannot write
catalog data or decide eligibility. Only server-selected records become cards.

## Audio and accessibility

Input is mono PCM16 at 16 kHz. Partial transcripts accumulate until the agent
begins its answer; partial text never stops capture. The Android AudioTrack
bridge buffers 300 ms, respects audio routing, and waits for the actual playback
head to drain before capture resumes. Pause, End, language change and background
close the call; resume skips a repeated greeting. Captions, correction, repeat,
and editable reviewed speech remain available. Screen-reader mode requires
explicit Resume after a reply. This is functional accessibility validation,
not a formal compliance certification.

## Verification and device incident

Backend verification: 203 passed, 2 skipped, no failures. Flutter analysis: no
issues. Focused Flutter voice and spacing tests: 17 passed. Release APK build passed and
retains the existing signing certificate. Real provider probes confirmed audible
PCM and replies in all four configured languages. The user confirmed the phone
voice and audio were working well, then reported the lookup authentication
failure. Version 8 and its matching backend were deployed to address that failure;
subsequent successful HTTP calls still returned empty arrays because the imported
catalog was entirely draft. The user explicitly approved publication of all 406
records and unreviewed translations on 21 October 2026. Catalog release 2 now
contains these records, retaining geographic restrictions, unknown application
statuses and translation review labels. Fresh phone lookup acceptance is pending.

An attempted Flutter integration test failed during its debug build, and the
runner's cleanup uninstalled the target package, removing local login/data. No
local-data backup was found. The release was reinstalled and the user signed in
again. Do not run Flutter integration tests against the user's installed package;
use an isolated application ID and synthetic account. Actual-phone updates must
verify the signer and use `adb install -r`, without uninstalling or clearing data.

## References

- https://docs.sarvam.ai/voice-agents/deploy/sdks/web
- https://docs.sarvam.ai/voice-agents/build/tools/https-tool
- https://docs.sarvam.ai/api-reference/text-to-speech/convert
- https://docs.sarvam.ai/api-reference/text/translate-text

## Longer listening update

Agent version 9 uses the maximum Patient turn-taking setting. MSS 1.2.6+2011
increases native capture's maximum per turn from 30 to 60 seconds. This is a
maximum capture window: Sarvam can reply earlier when it detects a completed
utterance. Pause, End and background closure remain immediate. Tamil uses the
gentler Vijay persona (`vijay_ta_narration`) for both native and reviewed speech.

The 406-record catalog publication used the exact imported source fingerprint
`0f294200a75cf910d4ec4e3ad18268e272adbe023a47814bd230234936213ef3`.
274 records are central, 53 Tamil Nadu and 79 Maharashtra. Publication changes
only visibility and its audit link; it does not mark applications open or
eligibility verified. A protected catalog-table backup was made before the
atomic publication. Existing RLS and runtime state scoping remain in force.

## Named scheme search

After catalog publication, the live call returned records but a PMEGP request
still missed its named scheme. Voice lookup had reused the feed's ID ordering,
which could select three generic matches before the named record. Native and
reviewed voice now use an internal search ordered by short-name/acronym rank,
then title rank, then body rank. Generic words such as scheme/details are
removed, and PMEPG is normalized to PMEGP. Public feed cursor ordering is
unchanged. The same owner/profile, published visibility, active status and RLS
constraints still apply. A read-only catalog query returned CEN2026-085 first
for PMEGP OR loan. The user's follow-up spoken PMEGP test remains pending; the
phone was in a normal telephone call when the final UI check was attempted.
