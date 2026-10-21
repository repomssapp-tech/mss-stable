import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Accessible navigation can also be set by UI automation and non-reader
/// services. On Android check spoken-feedback/touch-exploration services before
/// handing reply audio over to a reader. Other platforms retain Flutter's hint.
class VoiceAccessibility {
  static const _channel = MethodChannel(
    'com.inschemes.app/voice_accessibility',
  );
  static Future<bool> screenReaderEnabled({required bool platformHint}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return platformHint;
    }
    try {
      return await _channel.invokeMethod<bool>('screenReaderEnabled') ??
          platformHint;
    } on MissingPluginException {
      return platformHint;
    } on PlatformException {
      return platformHint;
    }
  }
}
