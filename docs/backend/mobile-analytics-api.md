# Mobile analytics API contract

Proposed routes for the MSS REST backend. These paths are not in the published API reference. Use the existing admin site and its roles for reports. Confirm the contract and rollout dates with the mobile engineer before enabling an app client.

## POST `/v1/analytics/events`

Accept JSON and gzip-compressed JSON. The proposed app client batches up to 100 events and queues only after an explicit, versioned analytics opt-in. This initial contract treats both modes as pseudonymous and excludes account tokens, account IDs and profile snapshots. Guest/signed-in mode describes where the event occurred and confers no permissions. If account-linked cohorts are approved later, design and review a separate authenticated version and its deletion rules.

```json
{
  "schema_version": 1,
  "consent_version": "analytics-v1",
  "install_id": "a6e90b43-7a05-47cf-a046-cf868dbe8c79",
  "events": [
    {
      "event_id": "16061c45-1125-40f6-986b-605cb9e41013",
      "session_id": "aa00cf99-0ae2-43c2-be70-cde301c93667",
      "interaction_id": "b5164fc3-a825-4d92-a498-13c399b1912e",
      "name": "questionnaire_results",
      "occurred_at": "2026-11-21T08:00:00Z",
      "context": {
        "user_kind": "guest",
        "language": "en",
        "mode": "regular",
        "platform": "android",
        "app_version": "2.5.1",
        "catalog_release": "schemes-8"
      },
      "props": {"good": 3, "possible": 5, "not_now": 2}
    }
  ]
}
```

- Use randomly generated IDs. Keep an event ID across retries, rotate session ID after 30 minutes of inactivity or a cold start, and start a new session when changing account or mode between guest and signed-in. Use an interaction ID to link events in one search, assessment or profile flow. Each event carries its own context at the time it occurred.
- Validate and accept a batch atomically. A repeat of an already stored event with the same payload succeeds with deduplication. Reject changed payloads under the same event ID with `409`. Return `200 {"accepted": 1, "duplicates": 0}` for the example. Return `400` for invalid shape, unknown properties or unsupported schema, `413` for size limits, and `429` with `Retry-After` for rate limits. Limit compressed and decoded sizes. Reject unreasonable timestamps, including future clock drift above an agreed tolerance. Proposed maximum age is 30 days, with configurable drift.
- Keep installation and IP rate limits. Use IP transiently for enforcement. Do not store IP, user agent, authorization headers or event bodies in request logs. Use request IDs and error codes in logs. Retain raw accepted records for a proposed 90 days and document deletion and retention for records, backups and exports.
- Client retries transport errors, `429` and `5xx` with bounded backoff. It removes accepted and explicitly rejected batches. Run uploads off the browse/search path. Consent off clears queued data immediately, cancels future sends and rotates the identifier before a later opt-in. Any server-side withdrawal or deletion interface needs a separately reviewed proof-of-control design. A client-generated install ID alone never authorizes reading or deleting server data.

### Initial event allow-list

The following are proposed production events. The local QA log is a separate format.

| Event | Properties |
|---|---|
| `session_start` | `launch_kind`: cold, resumed |
| `feature_opened` | `feature`: home, discover, search, saved, settings, profile, saarthi |
| `search_submitted` | `source`: typed, quick_pill, voice, category. `result_count`: integer ≥0. Optional `topic_key` from a versioned app catalog allow-list. |
| `filter_changed` | `filter_key` from an allow-list, `enabled`: boolean |
| `scheme_opened` | `scheme_id` from the catalogue, `entry_point`: search, discovery, home, saved, recommendation, assessment, saarthi, deeplink. Optional `rank`: integer ≥1. Optional `fit`: good, possible, not_now for assessment. |
| `scheme_action` | `scheme_id`, `action`: apply_link_opened, info_link_opened, saved, unsaved |
| `questionnaire_started` | `source`: category, ministry, state, home, edit_results |
| `questionnaire_progress` | `field_id` from the shipped questionnaire, `action`: shown, answered, skipped. No selected answer. |
| `questionnaire_closed` | `outcome`: completed, abandoned |
| `questionnaire_results` | `good`, `possible`, `not_now`: nonnegative displayed counts |
| `sign_in_prompt` | `feature`: save, alerts, saarthi, for_me, profile, general. `action`: shown, selected, dismissed. |
| `sign_in_completed` | `from_guest`: boolean captured by the client before the transition |
| `profile_progress` | `section`: basic_details, location, about_you, eligibility. `action`: shown, draft_saved, cloud_saved, sync_failed. |
| `profile_completed` | Empty props. Emit on confirmed cloud completion. |

Reject additional properties and raw input. Maintain compatibility for every accepted schema version. Keep prospective event categories in the [admin handoff](../handoff/analytics-admin-integration.md) until the app has the source and a reviewed schema.

## GET `/v1/admin/analytics/reports/{report}`

Use the existing admin authorization policy. Required query parameters are inclusive dates `from` and `to` in `YYYY-MM-DD`. Support allow-listed filters `platform`, `language`, `mode`, `user_kind` and `app_version`; report-specific dimensions and bounded page sizes are server controlled. Initial report IDs are `reach`, `search`, `schemes`, `assessment` and `profile`. The admin frontend should render tables from these aggregates rather than compute totals from raw events.

```json
{
  "report": "assessment",
  "from": "2026-11-21",
  "to": "2026-11-21",
  "timezone": "Asia/Kolkata",
  "data_through": "2026-11-21T12:00:00Z",
  "schema_version": 1,
  "rows": [
    {
      "dimensions": {"user_kind": "guest"},
      "metric": "completion_rate",
      "status": "available",
      "value": 0.6,
      "numerator": 60,
      "denominator": 100
    }
  ],
  "next_cursor": null
}
```

Use `suppressed` and `unavailable` as distinct statuses with null value and no numerator/denominator. Return true zeros only when the underlying instrumentation and denominator make zero meaningful. Apply threshold and complementary suppression before pagination, totals and export. A CSV export, if implemented by the existing admin site, must use the same authorized aggregate query and suppression logic. No raw-event endpoint is needed.

## Integration boundaries

Existing account, legal, profile and catalogue APIs retain their published contracts. Account sign-in and profile sync use those routes. Guest assessment, browse and search work from the device catalog. Optional cross-account transfer of questionnaire answers and official eligibility checks remain separate integrations under the existing [backend handoff](../handoff/2026-11-20-dev1-backend-tasks-1.2-1.4.md).

Before enabling uploads: agree on consent version and UI, allowed fields and guests, retention, suppression and admin roles. Verify retry deduplication, bounded payloads, offline reconnection, consent withdrawal, and guest/signed-in parity against synthetic data.
