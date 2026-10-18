import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/companion_mode/saarthi_home/saarthi_response_helpers.dart';
import 'package:frontend/services/search/scheme_understanding_models.dart';
import 'package:frontend/services/voice/assistant_session_controller.dart';

// The Companion's follow-up questions must follow the language the user picked
// in the app, not only Tamil-vs-English.
void main() {
  const question = FollowUpQuestion(
    factKey: EligibilityFactKey.age,
    english: 'How old are you?',
    tamil: 'உங்கள் வயது என்ன?',
  );

  Future<String> ask(WidgetTester tester, String language) async {
    late String text;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            text = SaarthiResponseHelpers.questionText(
              context,
              const AssistantSessionState(),
              question,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    return text;
  }

  testWidgets('English UI keeps the English question', (tester) async {
    expect(await ask(tester, 'en'), 'How old are you?');
  });

  testWidgets('Hindi UI gets the Hindi question, not English', (tester) async {
    final text = await ask(tester, 'hi');
    expect(text, isNot('How old are you?'));
    expect(RegExp(r'[ऀ-ॿ]').hasMatch(text), isTrue);
  });

  testWidgets('Tamil UI gets the Tamil question', (tester) async {
    final text = await ask(tester, 'ta');
    expect(RegExp(r'[஀-௿]').hasMatch(text), isTrue);
  });
}
