import 'package:shared_preferences/shared_preferences.dart';
import 'voice_language.dart';

/// A voice override survives reopening. Changing the app language supersedes an
/// override made for the previous app language, keeping the latest user setting.
class VoicePreferences {
  static const _language = 'saarthi_voice_language_v1';
  static const _appLanguage = 'saarthi_voice_app_language_v1';
  Future<String> languageFor(String appLanguage) async {
    final app = VoiceLanguage.code(appLanguage);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_appLanguage) != app) return app;
    final saved = prefs.getString(_language);
    return saved == null ? app : VoiceLanguage.code(saved);
  }

  Future<void> saveLanguage(String language, String appLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_language, VoiceLanguage.code(language));
    await prefs.setString(_appLanguage, VoiceLanguage.code(appLanguage));
  }
}
