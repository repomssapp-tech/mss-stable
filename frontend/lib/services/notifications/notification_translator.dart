import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Translates one piece of text. Returns null when it cannot (language not
/// supported, model not available, no network for the first model download).
abstract class TextTranslationBackend {
  Future<String?> translate(String text, {required String target});
}

/// Google ML Kit on-device translation. The language of the text is detected
/// first, and the translation model for the pair is downloaded the first time
/// it is needed (about 30 MB per language, over any network, kept on the
/// phone), after which translating works offline.
class MlKitTranslationBackend implements TextTranslationBackend {
  MlKitTranslationBackend();

  static const Map<String, TranslateLanguage> _languages = {
    'en': TranslateLanguage.english,
    'hi': TranslateLanguage.hindi,
    'ta': TranslateLanguage.tamil,
    'mr': TranslateLanguage.marathi,
  };

  final OnDeviceTranslatorModelManager _models =
      OnDeviceTranslatorModelManager();
  final LanguageIdentifier _identifier = LanguageIdentifier(
    confidenceThreshold: 0.5,
  );

  @override
  Future<String?> translate(String text, {required String target}) async {
    final to = _languages[target];
    if (to == null) return null;
    var detected = await _identifier.identifyLanguage(text);
    // Short titles are often "undetermined". The admin's broadcasts and the
    // catalog's fallback names are written in English, so assume that.
    if (detected == 'und') detected = 'en';
    final from = _languages[detected];
    if (from == null || from == to) return null;
    for (final language in [from, to]) {
      if (!await _models.isModelDownloaded(language.bcpCode)) {
        final ok = await _models.downloadModel(
          language.bcpCode,
          isWifiRequired: false,
        );
        if (!ok) return null;
      }
    }
    final translator = OnDeviceTranslator(
      sourceLanguage: from,
      targetLanguage: to,
    );
    try {
      return await translator.translateText(text);
    } finally {
      unawaited(translator.close());
    }
  }
}

/// Translates notification text to the user's language, remembering results so
/// each message is translated once per language.
class NotificationTranslator {
  NotificationTranslator({TextTranslationBackend? backend})
    : _backend = backend ?? MlKitTranslationBackend();

  static final NotificationTranslator instance = NotificationTranslator();

  final TextTranslationBackend _backend;
  final Map<String, String> _cache = {};
  final Map<String, Future<String>> _inFlight = {};

  static String _key(String text, String target) => '$target\u0000$text';

  /// The translation of [text] already known, or null. Never starts work.
  String? cached(String text, String target) => _cache[_key(text, target)];

  /// [text] in [target] ('en', 'hi', 'ta'), or [text] itself when it is empty,
  /// already in that language, or cannot be translated. Never throws.
  Future<String> translate(String text, String target) {
    if (text.trim().isEmpty) return Future.value(text);
    final key = _key(text, target);
    final hit = _cache[key];
    if (hit != null) return Future.value(hit);
    return _inFlight[key] ??= _run(text, target, key);
  }

  Future<String> _run(String text, String target, String key) async {
    try {
      final out = await _backend
          .translate(text, target: target)
          .timeout(const Duration(seconds: 25));
      if (out == null || out.trim().isEmpty) return text;
      // Only real results are remembered, so a failed attempt (e.g. offline
      // before the first model download) is tried again next time.
      _cache[key] = out;
      return out;
    } catch (e) {
      debugPrint('[NotificationTranslator] translate failed: $e');
      return text;
    } finally {
      _inFlight.remove(key);
    }
  }
}
