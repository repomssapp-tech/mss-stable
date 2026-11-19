/// The languages this app is offered in: English, Tamil, Hindi and Marathi,
/// in that order. Marathi was removed in 2.5.0 and brought back in 2.5.2.
/// Every language picker, the profile sync and voice/chat take their list
/// from here, so a catalogue release or a server profile carrying another
/// language can never switch the app to it.
const List<String> appLanguages = ['en', 'ta', 'hi', 'mr'];

/// [code] when the app is offered in it, otherwise English.
String appLanguageOrEnglish(String? code) {
  final c = (code ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('_', '-')
      .split('-')
      .first;
  return appLanguages.contains(c) ? c : 'en';
}
