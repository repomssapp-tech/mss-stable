import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/questionnaire_results_screen.dart';
import 'package:frontend/widgets/assistant/smart_assessment_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget hostSheet({
    required AppProvider provider,
    required String cardTitle,
    required String cardType,
    required VoidCallback onCompleted,
    Locale locale = const Locale('en'),
  }) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SmartAssessmentBottomSheet(
            cardTitle: cardTitle,
            cardType: cardType,
            onCompleted: onCompleted,
          ),
        ),
      ),
    );
  }

  group('SmartAssessmentBottomSheet', () {
    testWidgets('uses general questions and leaves profile unchanged', (
      tester,
    ) async {
      final provider = AppProvider();
      var completed = false;
      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Education',
          cardType: 'category',
          onCompleted: () => completed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Where do you live or run your business?'),
        findsOneWidget,
      );
      expect(find.text('Skip to Results'), findsOneWidget);
      await tester.tap(find.text('Skip to Results'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(provider.profile.gender, isEmpty);
      expect(provider.profile.community, isEmpty);
    });
  });

  testWidgets('results fill a card with five ineligible schemes from catalog', (
    tester,
  ) async {
    final provider = AppProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuestionnaireResultsScreen(
            title: 'Test card',
            cardType: 'category',
            schemes: [
              for (var i = 0; i < 5; i++)
                Scheme(
                  id: 'card-$i',
                  name: 'Card scheme $i',
                  eligibilityMaxAge: 45,
                ),
            ],
            catalogSchemes: const [
              Scheme(id: 'national', name: 'National scheme'),
            ],
            answers: const {'owner_age': 46},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('National scheme'), findsOneWidget);
    expect(find.text('Might fit'), findsOneWidget);
  });
}
