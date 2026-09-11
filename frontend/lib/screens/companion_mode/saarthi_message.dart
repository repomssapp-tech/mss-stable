import '../../models/scheme_model.dart';
import '../../services/voice/livekit_voice_agent_controller.dart';

/// The Saarthi (companion-mode voice assistant) conversation states.
enum SaarthiVoiceState { idle, listening, processing, speaking, ended }

/// One turn in the Saarthi conversation transcript.
///
/// Extracted verbatim from `saarthi_home_screen.dart` (frontend refactor C5,
/// safe slice) — a plain data class + its 3 `@visibleForTesting` pure
/// helpers below, all with zero coupling to `_SaarthiHomeScreenState`.
class SaarthiMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final String? status; // 'transcribing' | null
  final List<Scheme>? schemeResults;
  final List<CloudSchemeResult>? cloudSchemeResults;
  final String? speakingState; // 'speaking' | null

  SaarthiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.status,
    this.schemeResults,
    this.cloudSchemeResults,
    this.speakingState,
  });

  SaarthiMessage copyWith({
    String? text,
    String? status,
    bool clearStatus = false,
    List<Scheme>? schemeResults,
    List<CloudSchemeResult>? cloudSchemeResults,
    String? speakingState,
    bool clearSpeakingState = false,
  }) {
    return SaarthiMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp,
      status: clearStatus ? null : status ?? this.status,
      schemeResults: schemeResults ?? this.schemeResults,
      cloudSchemeResults: cloudSchemeResults ?? this.cloudSchemeResults,
      speakingState: clearSpeakingState
          ? null
          : speakingState ?? this.speakingState,
    );
  }
}

// Note: these 4 helpers are NOT test-only despite their original
// @visibleForTesting annotation in the pre-split file -- _SaarthiHomeScreenState
// calls all of them in production (saarthi_home_screen.dart), and
// saarthi_transcript_test.dart exercises them directly. The annotation was
// dropped on the move: it now under-restricts (any importer can call them),
// but it cannot over-restrict a real production caller in a sibling file.
int cloudAssistantMessageTargetIndex(List<SaarthiMessage> messages) =>
    messages.isNotEmpty && messages.last.role == 'assistant'
    ? messages.length - 1
    : -1;

int cloudSchemeResultTargetIndex(List<SaarthiMessage> messages) =>
    messages.isNotEmpty && messages.last.role == 'assistant'
    ? messages.length - 1
    : -1;

bool isTransientCloudConnectionFailure(Object? error) {
  final detail = error?.toString().toLowerCase() ?? '';
  return detail.contains('network') ||
      detail.contains('socket') ||
      detail.contains('timeout') ||
      detail.contains('timed out') ||
      detail.contains('disconnected') ||
      detail.contains('host lookup') ||
      detail.contains('connection reset');
}

bool shouldApplyCloudOutput({
  required String output,
  required String previousOutput,
}) => output.trim().isNotEmpty && output.trim() != previousOutput;
