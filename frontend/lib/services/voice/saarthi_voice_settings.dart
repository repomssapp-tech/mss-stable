import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saarthi's voice switches, shown on the Voice settings page (reached from
/// Settings and from the conversation room) and applied to every voice
/// conversation. Saarthi's language is kept by VoicePreferences.
class SaarthiVoiceSettings extends ChangeNotifier {
  SaarthiVoiceSettings._();

  static final SaarthiVoiceSettings instance = SaarthiVoiceSettings._();

  static const String _autoplayKey = 'saarthi_v2_autoplay';
  static const String _handsFreeKey = 'saarthi_v2_hands_free';
  static const String _confirmKey = 'saarthi_v2_confirm_before_send';

  /// Saarthi reads every answer aloud.
  bool autoplay = true;

  /// Keep listening after each reply (otherwise wait for "Tap to speak").
  bool handsFree = false;

  /// Show what Saarthi heard, with tick / cross, before it is sent.
  bool confirmBeforeSend = true;

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
      handsFree = p.getBool(_handsFreeKey) ?? handsFree;
      confirmBeforeSend = p.getBool(_confirmKey) ?? confirmBeforeSend;
    } catch (e) {
      debugPrint('[SaarthiVoiceSettings] load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update({
    bool? autoplay,
    bool? handsFree,
    bool? confirmBeforeSend,
  }) async {
    if (autoplay != null) this.autoplay = autoplay;
    if (handsFree != null) this.handsFree = handsFree;
    if (confirmBeforeSend != null) this.confirmBeforeSend = confirmBeforeSend;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_autoplayKey, this.autoplay);
      await p.setBool(_handsFreeKey, this.handsFree);
      await p.setBool(_confirmKey, this.confirmBeforeSend);
    } catch (e) {
      debugPrint('[SaarthiVoiceSettings] save failed: $e');
    }
  }

  @visibleForTesting
  void resetForTesting() {
    autoplay = true;
    handsFree = false;
    confirmBeforeSend = true;
    languageChange = null;
    _loaded = false;
  }
}
