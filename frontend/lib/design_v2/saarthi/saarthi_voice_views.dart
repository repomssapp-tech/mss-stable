// Language and error text shared by the Saarthi conversation views.
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Name of a voice language in its own script.
String voiceLanguageName(String code) => switch (code) {
  'ta' => 'தமிழ்', // i18n-ok
  'hi' => 'हिन्दी', // i18n-ok
  'mr' => 'मराठी', // i18n-ok
  _ => 'English', // i18n-ok
};

/// Localised text for a conversation error code.
String voiceErrorText(BuildContext context, String? code) {
  final l10n = context.l10n;
  return switch (code?.toUpperCase()) {
    'MIC_PERMISSION' => l10n.liveVoiceMicrophonePermission,
    'NO_SPEECH' || 'SILENCE_TIMEOUT' => l10n.liveVoiceNoSpeech,
    'UNAUTHORIZED' ||
    'AUTH_REQUIRED' ||
    'INVALID_TOKEN' ||
    '401' => l10n.saarthiCloudErrorSignIn,
    'SPEECH-UNAVAILABLE' => l10n.liveVoiceSpeechUnavailable,
    'FINAL_TIMEOUT' || 'VOICE_FINAL_TIMEOUT' => l10n.liveVoiceFinalTimeout,
    _ => l10n.liveVoiceConnectionError,
  };
}
