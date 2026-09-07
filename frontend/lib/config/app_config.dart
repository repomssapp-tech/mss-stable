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

  static bool get _isBlank =>
      supabaseUrl.isEmpty || supabasePublishableKey.isEmpty;

  /// Throws a [StateError] with actionable guidance when required build-time
  /// configuration is missing. Call once at the very start of `main()`.
  static void ensureValid() {
    if (!_isBlank && Uri.tryParse(supabaseUrl)?.hasScheme == true) return;

    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
      if (supabaseUrl.isNotEmpty && Uri.tryParse(supabaseUrl)?.hasScheme != true)
        'SUPABASE_URL (not a valid absolute URL)',
    ];

    throw StateError(
      'Missing build-time configuration: ${missing.join(', ')}.\n'
      'Run with:  --dart-define-from-file=dart_defines.json\n'
      '(copy dart_defines.example.json to dart_defines.json and fill it in).',
    );
  }
}
