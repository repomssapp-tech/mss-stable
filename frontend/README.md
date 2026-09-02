# frontend

A new Flutter project.

## Configuration

Supabase connection settings are passed at build/run time via a dart-define
file, not hardcoded. Copy the example and fill in the publishable key:

```console
cp dart_defines.example.json dart_defines.json
```

`dart_defines.json` is gitignored. Then run/build with:

```console
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

`SUPABASE_PUBLISHABLE_KEY` is the new-format publishable key (`sb_publishable_...`).
`SUPABASE_URL` and `MSS_API_BASE_URL` fall back to the production project when
omitted.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
