# App versioning: updating installed phones without a fresh install

A phone replaces an installed app in place only when the new build

1. has the **same application id** (`com.inschemes.app`, set in
   `frontend/android/app/build.gradle.kts`),
2. is signed with the **same key**, and
3. has a **higher `versionCode`**.

Miss any one and Android refuses with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (key
or id) or `INSTALL_FAILED_VERSION_DOWNGRADE` (code), and the only way out is
uninstalling the app, which also deletes the user's saved schemes and profile.

## One source of truth

`frontend/pubspec.yaml`:

```yaml
version: 1.1.0+4     # versionName 1.1.0, versionCode 4
```

`versionName` is what users see; the number after `+` is the Android
`versionCode`. Gradle reads both from here (`flutter.versionName`,
`flutter.versionCode`); do not set them anywhere else. The About dialog shows
the installed values (read from the device by `AppInfoService`).

## Releasing a new build

From `frontend/`:

```bash
dart run tool/app_version.dart show                  # what is it now?
dart run tool/app_version.dart bump patch            # 1.1.0+4 -> 1.1.1+5   (fix)
dart run tool/app_version.dart bump minor            # 1.1.1+5 -> 1.2.0+6   (feature)
dart run tool/app_version.dart bump major            # -> 2.0.0+7           (breaking)
dart run tool/app_version.dart bump build            # 1.2.0+6 -> 1.2.0+7   (rebuild only)
dart run tool/app_version.dart check --against origin/main
```

Every bump raises the build number by exactly one, which is what makes the new
build installable over the old one. Commit the `pubspec.yaml` change with the
release, and tag the release commit `app-v<version>+<build>` (for example
`app-v1.1.0+4`); the CI release check compares against the newest such tag.

Release checklist: bump the version, move the **Unreleased** items in
`CHANGELOG.md` under the new version heading, commit both together, push, then
`git tag -a app-v<version>+<build> -m "<version>"`, `git push origin <tag>` and
`gh release create <tag> --notes-file <notes>` (add `--prerelease` until the
commit is on `main` and a signed build exists). Choose the bump from the changes:
fixes only -> `patch`, new user-visible behaviour -> `minor`, breaking -> `major`.

`check` fails when the build number is malformed (must be 1..2,100,000,000) or
lower than the compared build. With `--require-increase` it also fails when it
is equal, which is what a promotable release uses.

## Signing

Release builds are signed with the upload keystore configured in
`frontend/android/key.properties` (copy `key.properties.example`; the file and
the keystore are git-ignored). **Back the keystore up and never regenerate it**:
a new key makes every installed phone refuse the update.

Practical consequences:

- A debug build (`flutter run`, or CI with no signing secrets) is signed with the
  debug key. It will **not** update a release build, or the reverse, and two
  machines with different debug keys cannot update each other's debug builds.
  Uninstall once when switching between kinds.
- CI marks an APK promotable only when it is built with the signing secrets
  and `dry_run=false`.
- The catalog inside the app updates separately (over the air, verified against
  the server's SHA-256); bumping the app version is only needed when app code
  changes or the catalog format (`bundleFormat`) is newer than the installed app
  understands.

## Checking an install

With a device or emulator connected:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk   # -r keeps app data
adb shell dumpsys package com.inschemes.app | grep -E "versionCode|versionName"
```

## What CI checks

`.github/workflows/build-app.yml` runs `tool/app_version.dart check` before the
build: never lower than `origin/main`; for a promotable release, strictly higher
than the latest `app-v*` tag. The artifact name carries the version
(`app-apk-1.1.0+4-<sha>`).
