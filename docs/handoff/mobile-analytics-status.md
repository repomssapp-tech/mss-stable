# Mobile analytics implementation and handoff

Updated 21 November 2026.

**The mobile analytics backbone is implemented in the app and disabled by default.** The separate backend must deploy the proposed batch ingest and report endpoints before the rollout owner enables uploads. The existing admin site will display the reports.

## App implementation

- Analytics records approved actions for guest and signed-in sessions and attaches the app context available at the time. The app stores events locally, up to 2,000 pending events and 30 days, then uploads packets of up to 100 events. Browse and Search continue while uploads run in the background.
- One packet can contain a session start, a search, a scheme open, a save or outbound link launch, and other eligible actions. A failed upload keeps the same event IDs, so the server can accept a retry without counting the same action twice.
- Item 2 in the earlier report means using random identifiers to connect related actions. An installation ID groups activity on one app installation. A session ID groups a period of activity. An interaction ID pairs a search with its result open or an assessment with its questions, results, and scheme opens. These IDs carry no account ID, raw search text, or questionnaire answers.
- Event hooks cover sessions, tab and Settings entries, Search and filter use, scheme details, saves and outbound launches, Smart Assessment steps and results, sign-in prompts and completion, and profile steps. Profile draft saving is tracked separately from cloud acknowledgments. An outbound link launch records interest and leaves external application outcomes unknown.
- The build has no in-app analytics switch. The release owner supplies the approved disclosure version and enables the build flag after the backend handshake. The old Smart Assessment debug log remains available for local QA.

## Send these files

| Recipient | Document | Action |
| --- | --- | --- |
| **Backend/API engineer** | [Mobile analytics API contract](../backend/mobile-analytics-api.md) | Implement batch ingest, validation, retry deduplication, retention, and the aggregate report API. Share the staging endpoint and fixture acknowledgments with mobile QA. |
| **Engineer who owns the existing admin site** | [Existing admin integration](analytics-admin-integration.md) | Add Reach, Search, Schemes, Assessment, and Profile reports to the existing site once the report API is ready. Use the same aggregate query and privacy thresholds for any exports. |
| **Mobile release engineer and QA lead** | [Mobile analytics rollout and QA](mobile-analytics-rollout.md) | Validate synthetic guest and signed-in journeys through the staging endpoint and admin reports before enabling the production build. |
| **Product or privacy owner** | [Mobile analytics rollout and QA](mobile-analytics-rollout.md) | Confirm that the published disclosure describes the production usage metrics and identify the notice version for the release engineer. |

Backend and admin deployment were outside the mobile repository audit. The app supports measurement after a successful staging handoff. Historical offline searches and other actions before instrumentation have no events to backfill.
