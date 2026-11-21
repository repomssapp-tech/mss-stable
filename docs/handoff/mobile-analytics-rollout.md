# Mobile analytics rollout and QA

For the mobile release engineer, QA lead, and product or privacy owner.

## Enable staging

1. Confirm that the backend staging origin implements the [batch API](../backend/mobile-analytics-api.md). The app uses its configured `API_BASE_URL` with `/v1/analytics/events`.
2. Confirm the approved usage disclosure version against the actual packet. The bundled privacy text currently describes limited technical and usage information for operation and reliability. Configure the debug or staging build with `MSS_ANALYTICS_ENABLED=true` and `MSS_ANALYTICS_NOTICE_VERSION=analytics-v1` or the approved replacement. With either value absent, the app creates no analytics queue or upload.
3. Use synthetic guest and signed-in profiles. The client sends schema version, disclosure version, a random installation ID, and the event array. Neither mode sends account tokens, profile field values, search text, selected questionnaire answers, or transcripts.
4. Verify that a full acknowledgment accounts for every event as accepted or duplicate. A partial acknowledgment keeps the packet for retry. Use an integer number of seconds for `Retry-After`.
5. Review the report values with the existing admin-site engineer. Enable the production flag only after an actual staging packet appears in the corresponding aggregate and the disclosure version is approved.

## End-to-end checks

| Journey | Expected evidence |
| --- | --- |
| Guest opens Discover, completes Smart Assessment, opens a scheme | Guest session context, assessment start, question actions, completion, result counts, and scheme open tied by the assessment interaction ID. |
| Search while offline, open a result, reconnect | Search count and scheme-open rank survive an app restart and arrive in the same or successive packets. Their search interaction ID stays stable. |
| Repeat a packet after a response is lost | Server returns duplicate counts for the previously accepted event IDs and report totals stay unchanged. |
| Return HTTP `429` or `503` | App retains the packet, delays the retry, and keeps browsing available. |
| Join from a guest sign-in prompt | Prompt shown and selected are linked. A successful account session records `from_guest` from the app state before the transition. |
| Save a profile section and complete signed-in onboarding | A local draft and a confirmed server write have different actions. Confirmed onboarding emits `profile_completed`. Repeated confirmed onboarding writes are possible, so report distinct completions within the intended metric window. |
| Open a scheme application link | Successful external app handoff emits a scheme action. Use the admin site to report outbound interest. |
| Build with analytics disabled | App journeys still work and the batch endpoint receives no app analytics events. |
| Check a small or empty sample | Confirm that the report presents suppression, unavailable data, and measured zero as defined by the contract. |

The focused app tests exercise offline persistence, packet acknowledgment and stable IDs, rate limiting, and disabled-build behavior with a mock server. Staging verification still requires the backend and admin deployments.
