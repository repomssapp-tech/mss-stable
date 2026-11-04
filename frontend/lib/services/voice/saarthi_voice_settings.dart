import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saarthi's voice switches, shown on the Voice settings page (reached from
/// Settings and from the conversation room) and applied to every voice
/// conversation. Saarthi's language is kept by VoicePreferences.
class SaarthiVoiceSettings extends ChangeNotifier {
  SaarthiVoiceSettings._();

  static final SaarthiVoiceSettings instance = SaarthiVoiceSettings._();

  static const String _autoplayKey = 'saarthi_v2_autoplay';

  /// Saarthi reads every answer aloud.
  bool autoplay = true;

  bool _loaded = false;

  /// Set when the user picks Saarthi's language on the settings page, so an
  /// open conversation switches to it; the choice itself is saved by
  /// VoicePreferences.
  String? languageChange;

  void changeLanguage(String code) {
    languageChange = code;
    notifyListeners();
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      autoplay = p.getBool(_autoplayKey) ?? autoplay;
    } catch (e) {
      debugPrint('[SaarthiVoiceSettings] load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update({bool? autoplay}) async {
    if (autoplay != null) this.autoplay = autoplay;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_autoplayKey, this.autoplay);
    } catch (e) {
      debugPrint('[SaarthiVoiceSettings] save failed: $e');
    }
  }

  @visibleForTesting
  void resetForTesting() {
    autoplay = true;
    languageChange = null;
    _loaded = false;
  }
}
