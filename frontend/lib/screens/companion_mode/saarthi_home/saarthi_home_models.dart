import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../saarthi_message.dart';

/// Helper methods for Saarthi companion UI states, colors, and timestamps.
class SaarthiHomeHelpers {
  SaarthiHomeHelpers._();

  /// Resolves the theme color corresponding to the current companion voice state.
  static Color statusColor(
    SaarthiVoiceState voiceState, {
    String? cloudConnectionError,
  }) {
    if (cloudConnectionError != null) return const Color(0xFFDC2626);
    switch (voiceState) {
      case SaarthiVoiceState.listening:
        return const Color(0xFF2563EB);
      case SaarthiVoiceState.processing:
        return const Color(0xFFB45309);
      case SaarthiVoiceState.speaking:
        return const Color(0xFF047857);
      default:
        return const Color(0xFF475569);
    }
  }

  /// Resolves the localized status badge label shown in the compact header.
  static String statusLabel(
    BuildContext context,
    SaarthiVoiceState voiceState, {
    String? cloudConnectionError,
    bool cloudRetrying = false,
  }) {
    final l10n = context.l10n;
    if (cloudConnectionError != null) {
      return l10n.saarthiStatusConnectionAttention;
    }
    if (cloudRetrying) return l10n.companionConnectingShort;
    switch (voiceState) {
      case SaarthiVoiceState.listening:
        return l10n.companionListeningToYou;
      case SaarthiVoiceState.processing:
        return l10n.companionCheckingYourDetails;
      case SaarthiVoiceState.speaking:
        return l10n.companionSpeakingNow;
      default:
        return l10n.companionReadyToHelp;
    }
  }

  /// Resolves the localized status banner text shown in the bottom panel.
  static String voiceStatusText(
    BuildContext context,
    SaarthiVoiceState voiceState, {
    String? cloudConnectionError,
    bool cloudRetrying = false,
  }) {
    final l10n = context.l10n;
    if (cloudConnectionError != null) return l10n.companionVoiceNotConnected;
    if (cloudRetrying) return l10n.companionConnectingSecurely;
    switch (voiceState) {
      case SaarthiVoiceState.listening:
        return l10n.companionListeningToYou;
      case SaarthiVoiceState.processing:
        return l10n.companionFindingBestMatch;
      case SaarthiVoiceState.speaking:
        return l10n.companionSaarthiIsSpeaking;
      default:
        return l10n.companionReadyShort;
    }
  }

  /// Formats a timestamp as HH:mm.
  static String formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
