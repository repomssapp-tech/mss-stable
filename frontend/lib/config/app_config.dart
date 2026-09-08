/// Build-time application configuration.
///
/// Connection values are injected at compile time and are **never** hard-coded
/// in source. Pass them with:
///
///   flutter run  --dart-define-from-file=dart_defines.json
///   flutter build ... --dart-define-from-file=dart_defines.json
///
/// `dart_defines.json` is git-ignored; `dart_defines.example.json` documents the
/// required keys. In CI the file is materialised from repository secrets.
library;

class AppConfig {
  AppConfig._();

  /// Supabase project URL, e.g. `https://<ref>.supabase.co`.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase publishable (anon) key. Safe to ship in the client — it only
  /// grants what Row Level Security allows — but it is still supplied at build
  /// time so the project a build points at is never baked into source control.
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Human-readable reason the current build-time configuration is unusable,
  /// or `null` when everything required is present and well-formed.
  static String? get validationError {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    ];
    if (missing.isNotEmpty) {
      return 'Missing build-time configuration: ${missing.join(', ')}.';
    }
    if (Uri.tryParse(supabaseUrl)?.hasScheme != true) {
      return 'SUPABASE_URL is not a valid absolute URL: "$supabaseUrl".';
    }
    return null;
  }

  static bool get isValid => validationError == null;

  /// The guidance appended to any configuration error shown to a developer.
  static const String setupHint =
      'Run with --dart-define-from-file=dart_defines.json '
      '(copy dart_defines.example.json to dart_defines.json and fill it in).';

  /// Throws a [StateError] when required build-time configuration is missing.
  /// Prefer [isValid] / [validationError] in `main()` so the app can render a
  /// visible error instead of failing before `runApp`.
  static void ensureValid() {
    final error = validationError;
    if (error != null) throw StateError('$error\n$setupHint');
  }
}
