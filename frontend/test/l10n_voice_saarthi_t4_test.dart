import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';

/// T4 — localisation of the last hardcoded English in
/// `lib/widgets/voice_assistant_overlay.dart` and
/// `lib/screens/companion_mode/saarthi_home_screen.dart`.
///
/// Both screens resolve strings through an explicit `lookupAppLocalizations`
/// (the voice overlay follows the per-utterance speech language, and the
/// Saarthi home screen has a hard live-voice/session dependency), so these are
/// getter-level assertions against both shipped locales rather than a widget
/// pump.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ta = lookupAppLocalizations(const Locale('ta'));

  void expectLocalised(String label, String enValue, String taValue) {
    expect(enValue.trim(), isNotEmpty, reason: '$label (en) must not be empty');
    expect(taValue.trim(), isNotEmpty, reason: '$label (ta) must not be empty');
    expect(
      taValue,
      isNot(equals(enValue)),
      reason: '$label must be genuinely translated, not copied English',
    );
  }

  group('voice_assistant_overlay migrated keys', () {
    test('plain strings differ per locale and are non-empty', () {
      expectLocalised(
        'voiceConversationTranscript',
        en.voiceConversationTranscript,
        ta.voiceConversationTranscript,
      );
      expectLocalised(
        'voiceReviewDetails',
        en.voiceReviewDetails,
        ta.voiceReviewDetails,
      );
      expectLocalised('voiceShowTop3', en.voiceShowTop3, ta.voiceShowTop3);
      expectLocalised(
        'voiceConfirmEligibility',
        en.voiceConfirmEligibility,
        ta.voiceConfirmEligibility,
      );
      expectLocalised(
        'voiceTapToInterrupt',
        en.voiceTapToInterrupt,
        ta.voiceTapToInterrupt,
      );
      expectLocalised(
        'voiceSemInterrupt',
        en.voiceSemInterrupt,
        ta.voiceSemInterrupt,
      );
      expectLocalised(
        'voiceSemMicHint',
        en.voiceSemMicHint,
        ta.voiceSemMicHint,
      );
      expectLocalised('voiceAiReady', en.voiceAiReady, ta.voiceAiReady);
      expectLocalised(
        'voiceAiAssistant',
        en.voiceAiAssistant,
        ta.voiceAiAssistant,
      );
      expectLocalised(
        'voiceNoiseControlSecure',
        en.voiceNoiseControlSecure,
        ta.voiceNoiseControlSecure,
      );
      expectLocalised(
        'voiceSemNoiseControlOn',
        en.voiceSemNoiseControlOn,
        ta.voiceSemNoiseControlOn,
      );
      expectLocalised(
        'voiceTapWhenFinished',
        en.voiceTapWhenFinished,
        ta.voiceTapWhenFinished,
      );
      expectLocalised(
        'voiceTypeInstead',
        en.voiceTypeInstead,
        ta.voiceTypeInstead,
      );
    });

    test('the "IN" branding is dropped from the AI voice strings', () {
      for (final value in [
        en.voiceAiReady,
        ta.voiceAiReady,
        en.voiceAiAssistant,
        ta.voiceAiAssistant,
      ]) {
        expect(value, isNot(startsWith('IN ')));
        expect(value, isNot(contains('IN AI')));
      }
    });

    test('placeholder keys interpolate their argument in both locales', () {
      expect(en.voiceFoundCount(5), contains('5'));
      expect(ta.voiceFoundCount(5), contains('5'));
      expect(en.voiceFoundCount(5), isNot(equals(ta.voiceFoundCount(5))));

      expect(en.voiceRelevanceMatch(87), contains('87'));
      expect(ta.voiceRelevanceMatch(87), contains('87'));

      expect(en.voiceShowAllMatches(9), contains('9'));
      expect(ta.voiceShowAllMatches(9), contains('9'));

      expect(en.voiceSeeUncertainSchemes(3), contains('3'));
      expect(ta.voiceSeeUncertainSchemes(3), contains('3'));

      expect(en.voiceEditFact('State'), contains('State'));
      expect(ta.voiceEditFact('மாநிலம்'), contains('மாநிலம்'));

      expect(en.voiceGroundingFoundSources(2), contains('2'));
      expect(ta.voiceGroundingFoundSources(2), contains('2'));
      expect(
        ta.voiceGroundingFoundSources(2),
        isNot(equals(en.voiceGroundingFoundSources(2))),
      );

      expect(en.voiceFactCrore('1.5'), contains('1.5'));
      expect(en.voiceFactCrore('1.5'), contains('₹'));
      expect(en.voiceFactLakh('2.0'), contains('2.0'));
      expect(ta.voiceFactCrore('1.5'), contains('1.5'));

      expect(
        en.voiceFactConflictFormat('B', 'A'),
        equals('A (profile: B)'),
      );
      expect(ta.voiceFactConflictFormat('B', 'A'), contains('A'));
      expect(ta.voiceFactConflictFormat('B', 'A'), contains('B'));
    });

    test('reused fact-label keys resolve for both locales', () {
      for (final pair in [
        [en.voiceFactLabelState, ta.voiceFactLabelState],
        [en.voiceFactLabelSituation, ta.voiceFactLabelSituation],
        [en.voiceFactLabelMaritalStatus, ta.voiceFactLabelMaritalStatus],
        [en.voiceFactLabelSector, ta.voiceFactLabelSector],
        [en.voiceFactLabelFundingNeed, ta.voiceFactLabelFundingNeed],
        [en.voiceFactLabelLandholding, ta.voiceFactLabelLandholding],
      ]) {
        expect(pair[0].trim(), isNotEmpty);
        expect(pair[1].trim(), isNotEmpty);
        expect(pair[1], isNot(equals(pair[0])));
      }
    });
  });

  group('saarthi_home_screen migrated keys', () {
    test('all 15 voice-agent questions are translated Tamil script', () {
      final questions = <String, List<String>>{
        'saarthiQAge': [en.saarthiQAge, ta.saarthiQAge],
        'saarthiQState': [en.saarthiQState, ta.saarthiQState],
        'saarthiQDistrict': [en.saarthiQDistrict, ta.saarthiQDistrict],
        'saarthiQIncome': [en.saarthiQIncome, ta.saarthiQIncome],
        'saarthiQGender': [en.saarthiQGender, ta.saarthiQGender],
        'saarthiQCommunity': [en.saarthiQCommunity, ta.saarthiQCommunity],
        'saarthiQOccupation': [en.saarthiQOccupation, ta.saarthiQOccupation],
        'saarthiQEducation': [en.saarthiQEducation, ta.saarthiQEducation],
        'saarthiQDisability': [en.saarthiQDisability, ta.saarthiQDisability],
        'saarthiQMaritalStatus': [
          en.saarthiQMaritalStatus,
          ta.saarthiQMaritalStatus,
        ],
        'saarthiQIsStudent': [en.saarthiQIsStudent, ta.saarthiQIsStudent],
        'saarthiQBusinessStage': [
          en.saarthiQBusinessStage,
          ta.saarthiQBusinessStage,
        ],
        'saarthiQBusinessSector': [
          en.saarthiQBusinessSector,
          ta.saarthiQBusinessSector,
        ],
        'saarthiQFundingNeed': [en.saarthiQFundingNeed, ta.saarthiQFundingNeed],
        'saarthiQLandholding': [en.saarthiQLandholding, ta.saarthiQLandholding],
      };
      final tamilScript = RegExp(r'[஀-௿]');
      final romanised = RegExp(r'\b(enna|evlo|unga|neenga|irukk)\b');
      questions.forEach((key, pair) {
        expect(pair[0].trim(), isNotEmpty, reason: '$key (en)');
        expect(pair[1].trim(), isNotEmpty, reason: '$key (ta)');
        expect(pair[0], isNot(equals(pair[1])), reason: '$key not translated');
        expect(
          tamilScript.hasMatch(pair[1]),
          isTrue,
          reason: '$key (ta) must be written in Tamil script',
        );
        expect(
          romanised.hasMatch(pair[1].toLowerCase()),
          isFalse,
          reason: '$key (ta) still contains romanised Tanglish',
        );
      });
    });

    test('status-label + voice-status keys differ per locale', () {
      final keys = <List<String>>[
        [en.saarthiStatusConnectionAttention, ta.saarthiStatusConnectionAttention],
        [en.companionConnectingShort, ta.companionConnectingShort],
        [en.companionListeningToYou, ta.companionListeningToYou],
        [en.companionCheckingYourDetails, ta.companionCheckingYourDetails],
        [en.companionSpeakingNow, ta.companionSpeakingNow],
        [en.companionReadyToHelp, ta.companionReadyToHelp],
        [en.companionVoiceNotConnected, ta.companionVoiceNotConnected],
        [en.companionConnectingSecurely, ta.companionConnectingSecurely],
        [en.companionFindingBestMatch, ta.companionFindingBestMatch],
        [en.companionSaarthiIsSpeaking, ta.companionSaarthiIsSpeaking],
        [en.companionReadyShort, ta.companionReadyShort],
      ];
      for (final pair in keys) {
        expect(pair[0].trim(), isNotEmpty);
        expect(pair[1].trim(), isNotEmpty);
        expect(pair[1], isNot(equals(pair[0])));
      }
    });

    test('cloud-error + greeting-fallback keys are localised', () {
      expectLocalised(
        'saarthiGreetingFriend',
        en.saarthiGreetingFriend,
        ta.saarthiGreetingFriend,
      );
      expect(en.saarthiGreetingFriend, isNot(equals('Praveen')));
      expectLocalised(
        'saarthiVoiceServiceUnavailable',
        en.saarthiVoiceServiceUnavailable,
        ta.saarthiVoiceServiceUnavailable,
      );
      expectLocalised(
        'saarthiCloudErrorSignIn',
        en.saarthiCloudErrorSignIn,
        ta.saarthiCloudErrorSignIn,
      );
      expectLocalised(
        'saarthiCloudErrorNetwork',
        en.saarthiCloudErrorNetwork,
        ta.saarthiCloudErrorNetwork,
      );
      expectLocalised(
        'saarthiCloudErrorGeneric',
        en.saarthiCloudErrorGeneric,
        ta.saarthiCloudErrorGeneric,
      );
      expectLocalised(
        'saarthiGenericError',
        en.saarthiGenericError,
        ta.saarthiGenericError,
      );
      expect(en.saarthiVoiceControlLabel('Speak'), contains('Speak'));
      expect(ta.saarthiVoiceControlLabel('பேசு'), contains('பேசு'));
      expect(
        en.saarthiVoiceControlLabel('Speak'),
        isNot(equals(ta.saarthiVoiceControlLabel('Speak'))),
      );
    });
  });
}
