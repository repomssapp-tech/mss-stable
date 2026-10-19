import 'package:flutter/foundation.dart';
import '../../../services/search/intelligent_scheme_search.dart';

enum VoiceAssistantPhase { starting, listening, processing, ready, unavailable }

enum VoiceInputLanguage { english, tamil }

enum OnlineGroundingPhase { idle, checking, found, unavailable, noSources }

enum VoiceTranscriptSpeaker { user, assistant }

@immutable
class VoiceTranscriptTurn {
  const VoiceTranscriptTurn({
    required this.id,
    required this.speaker,
    required this.text,
    this.schemeMatches = const [],
  });

  final String id;
  final VoiceTranscriptSpeaker speaker;
  final String text;
  final List<SchemeSearchMatch> schemeMatches;

  VoiceTranscriptTurn copyWith({
    String? text,
    List<SchemeSearchMatch>? schemeMatches,
  }) => VoiceTranscriptTurn(
    id: id,
    speaker: speaker,
    text: text ?? this.text,
    schemeMatches: schemeMatches ?? this.schemeMatches,
  );
}

@immutable
class GroundedOnlineSource {
  final String url;
  final String label;

  const GroundedOnlineSource({required this.url, required this.label});
}
