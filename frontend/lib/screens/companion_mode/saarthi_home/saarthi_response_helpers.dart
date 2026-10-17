import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/scheme_model.dart';
import '../../../services/search/intelligent_scheme_search.dart';
import '../../../services/search/scheme_understanding_engine.dart';
import '../../../services/voice/assistant_session_controller.dart';
import '../../../services/voice/livekit_voice_agent_controller.dart';

/// Pure helpers for turning session/voice-agent state into user-facing text
/// and scheme rankings, extracted from `SaarthiHomeScreen` orchestration code.
class SaarthiResponseHelpers {
  SaarthiResponseHelpers._();

  /// Resolves the localized follow-up question text for the assistant session.
  static String questionText(
    BuildContext context,
    AssistantSessionState state,
    FollowUpQuestion question,
  ) {
    if (RegExp(r'[஀-௿]').hasMatch(state.statement)) {
      return question.tamil;
    }
    if (!state.isTamil) return question.english;
    final l10n = context.l10n;
    // Spoken Tamil register: uses polite spoken register for voice prompts.
    return switch (question.factKey) {
      EligibilityFactKey.age => l10n.saarthiQAge,
      EligibilityFactKey.state => l10n.saarthiQState,
      EligibilityFactKey.district => l10n.saarthiQDistrict,
      EligibilityFactKey.annualIncome => l10n.saarthiQIncome,
      EligibilityFactKey.gender => l10n.saarthiQGender,
      EligibilityFactKey.community => l10n.saarthiQCommunity,
      EligibilityFactKey.occupation => l10n.saarthiQOccupation,
      EligibilityFactKey.education => l10n.saarthiQEducation,
      EligibilityFactKey.disability => l10n.saarthiQDisability,
      EligibilityFactKey.maritalStatus => l10n.saarthiQMaritalStatus,
      EligibilityFactKey.studentStatus => l10n.saarthiQIsStudent,
      EligibilityFactKey.businessStage => l10n.saarthiQBusinessStage,
      EligibilityFactKey.businessSector => l10n.saarthiQBusinessSector,
      EligibilityFactKey.fundingNeed => l10n.saarthiQFundingNeed,
      EligibilityFactKey.landholding => l10n.saarthiQLandholding,
    };
  }

  /// Resolves the localized error message shown for a failed cloud-voice
  /// connection attempt, based on a heuristic match against the error text.
  static String cloudErrorMessage(BuildContext context, Object? error) {
    final l10n = context.l10n;
    final detail = error?.toString().toLowerCase() ?? '';
    if (detail.contains('sign in') ||
        detail.contains('401') ||
        detail.contains('session')) {
      return l10n.saarthiCloudErrorSignIn;
    }
    if (detail.contains('network') ||
        detail.contains('socket') ||
        detail.contains('host lookup')) {
      return l10n.saarthiCloudErrorNetwork;
    }
    return l10n.saarthiCloudErrorGeneric;
  }

  /// Ranks cloud scheme results against the recent user turns to produce the
  /// short list attached to the corresponding assistant message.
  static List<Scheme> rankCloudSchemeResults({
    required List<CloudSchemeResult> results,
    required List<Scheme> catalogMatches,
    required List<String> recentUserTurns,
    int limit = 3,
  }) {
    final recentQuery = recentUserTurns.join(' ');
    return IntelligentSchemeSearch.rank(
      recentQuery,
      catalogMatches,
      limit: limit,
    ).map((match) => match.scheme).toList(growable: false);
  }
}
