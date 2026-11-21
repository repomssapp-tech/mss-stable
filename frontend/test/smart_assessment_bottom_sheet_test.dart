import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/questionnaire_results_screen.dart';
import 'package:frontend/services/questionnaire/questionnaire_answers_store.dart';
import 'package:frontend/services/questionnaire/questionnaire_repository.dart';
import 'package:frontend/widgets/assistant/smart_assessment_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.evict(QuestionnaireRepository.assetPath);
  });

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
    testWidgets('reopened assessment shows saved selections through results', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        QuestionnaireAnswersStore.preferencesKey:
            '{"schema_version":"1.0.0","answers":{"general_state":"Andhra Pradesh",'
            '"general_gender":"woman","general_need":["start_business"]}}',
      });
      final provider = AppProvider();
      var completed = false;
      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Business & MSME',
          cardType: 'category',
          onCompleted: () => completed = true,
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      final startingBusiness = find.widgetWithText(
        FilterChip,
        'Start a new business',
      );
      expect(tester.widget<FilterChip>(startingBusiness).selected, isTrue);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

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
