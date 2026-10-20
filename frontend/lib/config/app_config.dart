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

  /// REST API Base URL origin, e.g. `https://mssapi.msmeschemes.org` or `http://10.0.2.2:5000`.
  /// Defaults to `https://mssapi.msmeschemes.org` if not explicitly supplied
  /// (`--dart-define=API_BASE_URL=...`). No other connection value is needed.
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl
          .replaceAll(RegExp(r'/v1/?$'), '')
          .replaceAll(RegExp(r'/$'), '');
    }
    return 'https://mssapi.msmeschemes.org';
  }

  /// REST API /v1 prefix, e.g. `https://mssapi.msmeschemes.org/v1`.
  static String get apiV1Url => '$apiBaseUrl/v1';

  /// Human-readable reason the current build-time configuration is unusable,
  /// or `null` when everything required is present and well-formed.
  static String? get validationError {
    final base = Uri.tryParse(apiBaseUrl);
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      return 'API_BASE_URL is not a valid absolute URL: "$apiBaseUrl".';
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
