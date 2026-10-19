/// The one place that maps an app language code to what voice and chat need.
///
/// Voice and chat support English, Tamil, Hindi and Marathi. Marathi is a
/// voice/chat language even though the app's interface is not offered in it.
class VoiceLanguage {
  VoiceLanguage._();

  static const Map<String, String> _speechLocales = {
    'en': 'en-IN',
    'ta': 'ta-IN',
    'hi': 'hi-IN',
    'mr': 'mr-IN',
  };

  static const List<String> supported = ['en', 'ta', 'hi', 'mr'];

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
