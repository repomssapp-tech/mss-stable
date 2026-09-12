import '../../models/scheme_model.dart';
import 'private_ai_knowledge_base.dart';

enum EligibilityFactKey {
  age,
  state,
  district,
  annualIncome,
  gender,
  community,
  occupation,
  education,
  disability,
  maritalStatus,
  studentStatus,
  businessStage,
  businessSector,
  fundingNeed,
  landholding,
}

enum EligibilityFactSource { statement, profile, followUp, edited }

enum SchemeMatchState {
  strongMatch,
  likelyMatch,
  needsInformation,
  notSuitable,
  noConfidentMatch,
}

class EligibilityFact {
  const EligibilityFact({
    required this.key,
    required this.value,
    required this.confidence,
    required this.source,
    this.confirmed = false,
    this.conflictingValue,
  });

  final EligibilityFactKey key;
  final String value;
  final double confidence;
  final EligibilityFactSource source;
  final bool confirmed;
  final String? conflictingValue;

  bool get hasConflict => conflictingValue != null;

  EligibilityFact copyWith({
    String? value,
    double? confidence,
    EligibilityFactSource? source,
    bool? confirmed,
    String? conflictingValue,
    bool clearConflict = false,
  }) {
    return EligibilityFact(
      key: key,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      confirmed: confirmed ?? this.confirmed,
      conflictingValue: clearConflict
          ? null
          : conflictingValue ?? this.conflictingValue,
    );
  }
}

class FollowUpQuestion {
  const FollowUpQuestion({
    required this.factKey,
    required this.english,
    required this.tamil,
    this.options = const [],
  });

  final EligibilityFactKey factKey;
  final String english;
  final String tamil;
  final List<String> options;

  String text({required bool tamilLanguage}) => tamilLanguage ? tamil : english;
}

class SchemeRecommendation {
  const SchemeRecommendation({
    required this.scheme,
    required this.score,
    required this.state,
    required this.reasons,
    required this.unknownRequirements,
    required this.disqualifiers,
    required this.isTrusted,
  });

  final Scheme scheme;
  final double score;
  final SchemeMatchState state;
  final List<String> reasons;
  final List<String> unknownRequirements;
  final List<String> disqualifiers;
  final bool isTrusted;
}

class SchemeUnderstandingRequest {
  const SchemeUnderstandingRequest({
    required this.statement,
    required this.schemes,
    required this.knownFacts,
    required this.questionsAsked,
    this.latestAnswer,
    this.requestedFact,
    this.includeUncertain = false,
  });

  final String statement;
  final List<Scheme> schemes;
  final Map<EligibilityFactKey, EligibilityFact> knownFacts;
  final int questionsAsked;
  final String? latestAnswer;
  final EligibilityFactKey? requestedFact;
  final bool includeUncertain;
}

class SchemeUnderstandingResult {
  const SchemeUnderstandingResult({
    required this.isTamil,
    required this.concepts,
    required this.facts,
    required this.recommendations,
    required this.excludedUncertainCount,
    required this.elapsed,
    this.reply,
    this.followUpQuestion,
    this.noConfidentMatch = false,
  });

  final bool isTamil;
  final Set<String> concepts;
  final Map<EligibilityFactKey, EligibilityFact> facts;
  final List<SchemeRecommendation> recommendations;
  final int excludedUncertainCount;
  final Duration elapsed;
  final GroundedAssistantReply? reply;
  final FollowUpQuestion? followUpQuestion;
  final bool noConfidentMatch;
}

abstract interface class SchemeUnderstandingEngine {
  Future<SchemeUnderstandingResult> understand(
    SchemeUnderstandingRequest request,
  );
}

abstract interface class ClosableSchemeUnderstandingEngine {
  Future<void> close();
}
