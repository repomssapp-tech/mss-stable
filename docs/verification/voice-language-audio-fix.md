# Selected-language and audio repair — 2026-10-21

Backend: `7078bdc44016e66c1429662246352f7dec5f466c`, deployed through the existing
immutable release command. API and DB health passed. Previous release retained.
No schema changes or production fixture writes were needed.

The explicit request language now determines reply delivery and speech locale.
The model drafts from the same verified catalog evidence in English; Indic
answers use `sarvam-translate:v1` with source `en-IN` and the exact selected target.
This costs one extra bounded translation request on Indic turns; English skips it.
Script guards fail closed to a static selected-language retry message with no
scheme cards. Hindi and Marathi share a script; their separate target locales
control delivery. This is stronger delivery enforcement, not a claim that any
model's wording is linguistically perfect.

The app validates returned locale metadata, invalidates replay on language change,
remembers the voice choice, and follows a later app-language change. An Android
spoken-feedback/touch-exploration query distinguishes readers from a generic
accessible-navigation flag. Reader exit restores the default audio preference;
explicit user choices survive changes. Playback reapplies speech/media/normal
routing after recording. Audio failures offer retry without another chat call.

## Evidence

- Full Node verification: 181 tests; 179 passed, 2 skipped, 0 failed.
- Final focused Flutter suite: 62 passed, including design spacing and accessibility.
- Flutter analysis: no issues.
- Existing unrelated account-dialog guard failures from the previous broad run
  were not changed or hidden by baseline updates.
- Live real-provider synthetic greetings with Hindi in history:

| Selected language | Reply + MP3 time (one sample) | MP3 bytes |
| --- | ---: | ---: |
| English | 1332 ms | 33792 |
| Tamil | 2054 ms | 62208 |
| Hindi | 1873 ms | 66432 |
| Marathi | 1921 ms | 59520 |

These local samples include generation, delivery translation where applicable,
and speech synthesis. They are not a device benchmark or latency guarantee.
Selected replies were native text in each target language, not fallback messages.

The connected phone's media stream was not muted. Earlier UI automation had
triggered the broad accessibility flag; previous code disabled audio on entry
without restoring it on exit. Regression tests cover that failure and the native
probe. The phone disconnected during final packaging, so installing release
1.2.3 build 2008 and checking physical playback are pending reconnection.
No physical TalkBack or controlled on-phone hearing test is claimed.

[Official Sarvam translation contract](https://docs.sarvam.ai/api-reference/text/translate-text)
[AudioContextAndroid contract](https://pub.dev/documentation/audioplayers/latest/audioplayers/AudioContextAndroid-class.html)

## Reconnected phone and deployment conflict

Android 1.2.3 build 2008 was installed successfully with `adb install -r`; package
metadata and the running app confirmed the version. The accessibility automation
no longer exposed an unexpected audio-off/reader state. Functional voice failed
because a separate deployment had replaced the server with release `4f622df`,
which has no voice source/routes. While integrating its legal/profile changes,
another release `9ab487b` (v0.2.3 metadata) appeared. The expected-release guard
stopped activation, avoiding an overwrite of concurrent work.

Prepared integration `6107ebcec22fcd8922481427ee173a65222e8702` retains that latest
source and adds the voice fixes. Its full verification passed 189 tests with
2 skipped. Migration/grant files match the latest release; no database operation
is proposed. The patch can be applied to source at `9ab487b`:
`MSS-Backend-Voice-v0.2.3.patch`, with a full local Git bundle also supplied in
the workspace deliverables folder. Git CLI and the connected GitHub app both
return 404 for `mssschemes/backend`, so publishing to its deploying branch needs
repository access. The phone journey stopped on the route failure and remaining
audio/language assertions were skipped. End was used afterward; microphone off.
