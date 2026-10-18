/// Name of a language written in its own script, whatever the active UI
/// language is. Used wherever the current language is shown as a value
/// (Settings, Profile), so a Hindi user never sees "English" for Hindi.
String languageEndonym(String code) {
  switch (code) {
    case 'ta':
      return 'தமிழ்'; // i18n-ok
    case 'hi':
      return 'हिन्दी'; // i18n-ok
    default:
      return 'English'; // i18n-ok
  }
}
