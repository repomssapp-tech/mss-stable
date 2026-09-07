# MSS App — Flutter frontend

## First-time setup

1. `flutter pub get`
2. Create `dart_defines.json` from the template and fill in the real values:
   ```
   cp dart_defines.example.json dart_defines.json
   ```
   | Key | Value |
   |---|---|
   | `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
   | `SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_...` (anon key — safe in the client, RLS-protected) |
   | `MSS_API_BASE_URL` | `https://<project-ref>.supabase.co/functions/v1` |

   `dart_defines.json` is git-ignored. Ask a teammate for the values, or read
   them from the Supabase dashboard → Project Settings → API.

## Running the app

Connection config is injected at build time — it is **not** hard-coded in
source. If you launch without it you get an "App configuration error" screen
instead of the app. Use one of these so you never have to remember the flag:

| How | Command |
|---|---|
| Terminal (Windows) | `./run.ps1` &nbsp;·&nbsp; `./run.ps1 apk-release` |
| Terminal (macOS/Linux/Git Bash) | `./run.sh` &nbsp;·&nbsp; `./run.sh apk-release` |
| VS Code | Run panel → **"MSS App (debug)"** |
| Android Studio | Run → Edit Configurations → *Additional run args*: `--dart-define-from-file=dart_defines.json` |
| Raw Flutter | `flutter run --dart-define-from-file=dart_defines.json` |

`run.ps1` / `run.sh` accept: `run` (default), `run-release`, `apk`,
`apk-release`, `appbundle`, `web`, `analyze`, `test`. They auto-create
`dart_defines.json` from the example on first use and tell you to fill it in.

## CI

`.github/workflows/build-app.yml` writes `dart_defines.json` from the repo
secrets `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`, then passes
`--dart-define-from-file` to the build steps. Without those secrets the
workflow runs `analyze` + `test` only.

## Flutter resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Flutter documentation](https://docs.flutter.dev/) — tutorials, samples, API reference
