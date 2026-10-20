# Changelog

All notable changes to the MSS app (Flutter, `frontend/`). Versions follow
`frontend/pubspec.yaml` (`versionName+versionCode`, see `docs/APP_VERSIONING.md`).
Each release is tagged `app-v<version>+<build>` and published on GitHub Releases.
Format based on [Keep a Changelog](https://keepachangelog.com/).

How to add an entry: put changes under **Unreleased** as you merge; at release time run
`dart run tool/app_version.dart bump <patch|minor|major>` from `frontend/`, move the
Unreleased items under a new heading, commit, and tag the commit.

## [Unreleased]

## [1.2.0+5] - 2026-10-20 (pre-release)

### Added
- Multilingual search with "Did you mean", Hindi/Tamil stemming, profile canonicalisation
  and voice-agent parity; English scheme text indexed so indirect queries resolve.
- Firebase Cloud Messaging push integration.
- Device audit report: `docs/audit/DEVICE_AUDIT_2026-10-20.md`.

### Changed
- App and voice agent now use the MSS REST backend and the 2026 scheme catalog.
- Default API origin is `https://mssapi.msmeschemes.org` (the Vercel host
  `api.msmeschemes.org` is paused).
- In-app Tamil/Hindi terms aligned with the catalog (MSME, women entrepreneurs, states).
- Home fallback promo carousel shows only the evergreen "For Women Entrepreneurs" card.

### Fixed
- Logout now revokes the session on the server before clearing local tokens (the request
  used to go out without a bearer and the session stayed valid).
- Users were signed out after an expired access token: the refresh lock was per-client, so
  parallel clients reused one refresh token and the server revoked the session. The lock is
  now shared (regression test added).
- "Use my profile" filter treated disability "No" as a disability and collapsed results to
  one scheme.
- Missing accessibility labels: legal-sheet close button, profile notification bell and
  avatar, onboarding step 4 switches.
- Fabricated home promo cards ("PMEGP · 2 days left", "TN Export Promotion Scheme",
  "UDYAM registration process updated") removed.

### Known issues
- Server `LEGAL_DOCUMENT_VERSIONS` is empty, so onboarding is never marked complete on the
  server and re-runs on every cold start (server configuration, not an app bug).
- Full Address is not restored after a restart.
- Default scheme lists are not scoped to the user's state (Filter → Maharashtra coverage
  works).
- Access and refresh tokens are kept in plain SharedPreferences.

Full detail: `docs/audit/DEVICE_AUDIT_2026-10-20.md`.

## [1.1.0+4] - 2026-10-19

### Changed
- Moved the app and voice agent to the MSS REST backend with the 2026 catalog (#114).
- Hindi + Tamil UI sweep, Companion localization and adaptive layouts (#112).

## [1.0.2] - 2026-09-06 (pre-release)

Scheme result engine, single shared filter, redesigned filter sheet, hardened profile
round-trip. See the `v1.0.2` GitHub release for notes.
