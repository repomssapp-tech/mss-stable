# Selected-language and audio repair — 2026-10-21

Final backend: `4fc12cb17f5977b066bad2664abf455cd6169427`, deployed and healthy
on v0.2.3. Android 1.2.3 build 2008 is installed with data preserved.

The explicit request language determines reply delivery and synthesis locale.
Grounded English drafts use sarvam-translate:v1 with exact ta-IN, hi-IN or mr-IN
targets. English skips translation. Script guards fail closed to a localized retry
message without scheme cards. Metadata validation and replay invalidation prevent
old-locale audio. Voice preference persists across restart and follows a later
app-language change. This does not claim linguistically perfect model wording.

A generic accessibility flag previously disabled audio without restoring it.
Android now checks actual spoken-feedback/touch-exploration services, restores
default audio when the reader leaves, and preserves explicit user choices.
Playback reapplies speech/media/normal context after recording. Failures preserve
text and retry speech without repeating the chat request.

## Evidence

- Final full Node verification: 189 passed, 2 skipped, 0 failed.
- Focused Flutter suite: 62 passed; analysis clean; signed release build passed.
- Existing unrelated account-dialog guard failures remain unchanged.
- API/DB healthy; chat/speech reject missing auth with 401; public WSS upgrades
  and rejects an invalid token.
- Phone selected Tamil, sent English Hello and displayed:
  “வணக்கம்! இன்று நான் உங்களுக்கு எப்படி உதவ முடியும்?”.
- Human user explicitly confirmed the Tamil replay was audible.
- Runtime observed app transient audio focus with media/speech attributes and
  24 kHz preparation; playback completed back to paused without audio failure.
- Tamil remained selected after full process restart. Read aloud restored on;
  End used at completion; microphone off.
- Full physical TalkBack and controlled recognition-in-noise testing were not done.

Real-provider synthetic greetings, with Hindi in history, returned each selected
language and nonempty MP3s. One local sample per language, not a device benchmark:

| Target | Reply + MP3 time | MP3 bytes |
| --- | ---: | ---: |
| English | 1332 ms | 33792 |
| Tamil | 2054 ms | 62208 |
| Hindi | 1873 ms | 66432 |
| Marathi | 1921 ms | 59520 |

## Deployment continuity

Independent releases 4f622df, 9ab487b and 3b6a1e1 omitted voice routes. Expected-
release checks prevented overwriting those changes during integration. After the
user paused other deployments, the final source preserved their legal/profile/
logging updates and version. Migration/grant files match the final base; no
production migrations or fixtures were run. Prior releases remain for rollback.

Git CLI and GitHub connector return 404 for mssschemes/backend. Before resuming
its deployments, apply `MSS-Backend-Voice-current.patch` to the deploying branch
(source base 3b6a1e1); a full current Git bundle is also in workspace deliverables.

[Official Sarvam translation contract](https://docs.sarvam.ai/api-reference/text/translate-text)
[AudioContextAndroid contract](https://pub.dev/documentation/audioplayers/latest/audioplayers/AudioContextAndroid-class.html)
