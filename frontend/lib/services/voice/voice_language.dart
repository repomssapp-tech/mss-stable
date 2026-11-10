/// The one place that maps an app language code to what voice and chat need.
///
/// Voice and chat support the app's languages: English, Tamil and Hindi.
class VoiceLanguage {
  VoiceLanguage._();

  static const Map<String, String> _speechLocales = {
    'en': 'en-IN',
    'ta': 'ta-IN',
    'hi': 'hi-IN',
  };

  static const List<String> supported = ['en', 'ta', 'hi'];

  /// A final guard for main-script drift, while allowing familiar borrowed
  /// terms.
  static bool hasMainScript(String text, String language) {
    final tamil = RegExp(r'[\u0B80-\u0BFF]').allMatches(text).length;
    final devanagari = RegExp(r'[\u0900-\u097F]').allMatches(text).length;
    final latin = RegExp(r'[A-Za-z]+').allMatches(text).length;
    if (language == 'en') return latin > 0 && tamil == 0 && devanagari == 0;
    final native = RegExp(
      language == 'ta' ? r'[\u0B80-\u0BFF]+' : r'[\u0900-\u097F]+',
    ).allMatches(text).length;
    final other = language == 'ta' ? devanagari : tamil;
    return native > 0 && other == 0 && native >= latin;
  }

  /// `ta`, `ta-IN`, `TA_in` -> `ta`; unknown or blank -> `en`.
  static String code(String? tagOrCode) {
    final c = (tagOrCode ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('_', '-')
        .split('-')
        .first;
    return _speechLocales.containsKey(c) ? c : 'en';
  }

  /// Speech recogniser / synthesiser locale for an app language or tag.
  static String speechLocale(String? tagOrCode) =>
      _speechLocales[code(tagOrCode)]!;

  /// Language code sent to the chat function.
  static String chatCode(String? tagOrCode) => code(tagOrCode);
}
