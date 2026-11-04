import 'package:flutter/widgets.dart';

/// The language a scheme card is shown in during a voice conversation: Tamil
/// when the conversation is in Tamil, otherwise the app's language. A Tamil-app
/// user speaking English gets English.
String voiceCardLanguage(BuildContext context, bool presentInTamil) {
  if (presentInTamil) return 'ta';
  final app = Localizations.localeOf(context).languageCode;
  return app == 'ta' ? 'en' : app;
}
