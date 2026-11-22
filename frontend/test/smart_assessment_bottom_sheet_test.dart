import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/categories/categories_data.dart';
import 'package:frontend/screens/regular_mode/search_results_screen.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/services/questionnaire/assessment_fields.dart';
import 'package:frontend/services/questionnaire/questionnaire_answers_store.dart';
import 'package:frontend/services/questionnaire/questionnaire_repository.dart';
import 'package:frontend/widgets/assistant/smart_assessment_bottom_sheet.dart';

import 'questionnaire_widget_test_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget hostSheet({
    required AppProvider provider,
    required String cardTitle,
    required String cardType,
    required VoidCallback onCompleted,
    ValueChanged<Map<String, Object?>>? onAnswersCompleted,
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
            onAnswersCompleted: onAnswersCompleted,
          ),
        ),
      ),
    );
  }

  test(
    'every Discover card has localized questions and no location entry',
    () async {
      final definition = await QuestionnaireRepository().load();
      final cards = [
        for (final category in allCategoriesList) ('category', category.title),
        for (final ministry in allMinistriesList) ('ministry', ministry),
        for (final state in allStatesList) ('state', state),
      ];
      final covered = <String>{};
      for (final (type, title) in cards) {
        final fields = assessmentFields(
          definition,
          title: title,
          cardType: type,
        );
        expect(fields.length, inInclusiveRange(3, 5), reason: title);
        for (final field in fields) {
          covered.add(field.id);
          expect(
            field.type,
            isNot(isIn(['location', 'state', 'boolean_with_district'])),
          );
          expect(field.question['ta'], isNotEmpty, reason: field.id);
          expect(
            field.options.every(
              (option) => option.labels['ta']?.isNotEmpty ?? false,
            ),
            isTrue,
          );
        }
      }
      expect(
        covered,
        containsAll([
          'general_gender',
          'social_category',
          'business_nature',
          'scheme_goal',
          'business_age',
          'org_structure',
          'special_focus_zone',
          'assistance_needed',
          'digital_literacy_level',
          'has_gi_tag',
          'cluster_membership',
          'export_status',
          'tax_compliance_comfort',
        ]),
      );
    },
  );

  group('SmartAssessmentBottomSheet', () {
    useQuestionnaireWidgetAssets();

    testWidgets('uses saved profile values without asking for them', (
      tester,
    ) async {
      final provider = AppProvider();
      provider.setProfileForTesting(
        provider.profile.copyWith(
          state: 'Tamil Nadu',
          gender: 'Female',
          area: 'Rural',
          businessIndustry: 'Manufacturing',
        ),
      );
      Map<String, Object?>? submitted;
      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Business & MSME',
          cardType: 'category',
          onCompleted: () {},
          onAnswersCompleted: (answers) => submitted = answers,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Where do you live or run your business?'),
        findsNothing,
      );
      expect(find.text('What is your gender?'), findsNothing);
      expect(find.text('What does your business do?'), findsNothing);
      expect(find.text('What would you like to do?'), findsOneWidget);
      await tester.tap(find.text('Skip to Results'));
      await tester.pumpAndSettle();
      expect(submitted?['general_state'], 'Tamil Nadu');
      expect(submitted?['general_gender'], 'woman');
      expect(submitted?['business_location'], {'area': 'village_rural'});
    });

    testWidgets(
      'inline answer rows and the sheet stay in place on a narrow phone',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final provider = AppProvider();
        Map<String, Object?>? answers;
        await tester.pumpWidget(
          hostSheet(
            provider: provider,
            cardTitle: 'Business & MSME',
            cardType: 'category',
            onCompleted: () {},
            onAnswersCompleted: (value) => answers = value,
          ),
        );
        await tester.pumpAndSettle();

        final manufacturing = find.widgetWithText(
          RadioListTile<String>,
          'Manufacturing',
        );
        final services = find.widgetWithText(RadioListTile<String>, 'Services');
        final close = find.byTooltip('Close');
        final closePosition = tester.getTopLeft(close);
        final first = tester.getRect(manufacturing);
        final second = tester.getRect(services);
        expect(first.width, greaterThan(250));
        expect(second.left, first.left);
        expect(second.width, first.width);
        expect(second.top, greaterThan(first.bottom));

        await tester.tap(manufacturing);
        await tester.pumpAndSettle();
        expect(tester.getRect(manufacturing), first);
        expect(tester.getRect(services), second);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('What is your gender?'), findsOneWidget);
        expect(tester.getTopLeft(close), closePosition);
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();
        await tester.tap(services);
        await tester.pumpAndSettle();
        final skip = find.text('Skip to Results');
        await tester.ensureVisible(skip);
        await tester.tap(skip);
        await tester.pumpAndSettle();
        expect(answers?['business_nature'], 'services');
      },
    );

    testWidgets('reopened assessment shows saved selections through results', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        QuestionnaireAnswersStore.preferencesKey:
            '{"schema_version":"1.0.0","answers":{"general_state":"Andhra Pradesh",'
            '"general_gender":"woman","scheme_goal":["start_a_new_business"]}}',
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
      for (final question in [
        'What does your business do?',
        'What is your gender?',
      ]) {
        expect(find.text(question), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      final startingBusiness = find.widgetWithText(
        CheckboxListTile,
        'Start a new business',
      );
      expect(tester.widget<CheckboxListTile>(startingBusiness).value, isTrue);
      await tester.tap(find.text('Skip to Results'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets(
      'guest assessment skips location and leaves profile unchanged',
      (tester) async {
        final provider = AppProvider();
        var completed = false;
        await tester.pumpWidget(
          hostSheet(
            provider: provider,
            cardTitle: 'Education & Fellowship',
            cardType: 'category',
            onCompleted: () => completed = true,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Where do you live or run your business?'),
          findsNothing,
        );
        expect(
          find.text('What is your highest level of education?'),
          findsOneWidget,
        );
        expect(find.text('Skip to Results'), findsOneWidget);
        await tester.tap(find.text('Skip to Results'));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
        expect(provider.profile.gender, isEmpty);
        expect(provider.profile.community, isEmpty);
      },
    );

    testWidgets('browsing a state does not assert residency', (tester) async {
      final provider = AppProvider();
      Map<String, Object?>? submitted;
      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Tamil Nadu',
          cardType: 'state',
          onCompleted: () {},
          onAnswersCompleted: (answers) => submitted = answers,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip to Results'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted, isNot(contains('general_state')));
    });

    testWidgets(
      'export asks trade questions and skips GI for aspiring businesses',
      (tester) async {
        final provider = AppProvider();
        await tester.pumpWidget(
          hostSheet(
            provider: provider,
            cardTitle: 'Export & Trade Promotion',
            cardType: 'category',
            onCompleted: () {},
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Do you sell or plan to sell outside India?'),
          findsOneWidget,
        );
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Not started yet (Aspiring)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('What kind of support do you need?'), findsOneWidget);
        expect(find.textContaining('Geographical Indication'), findsNothing);
      },
    );
  });

  testWidgets(
    'results keep the selected card when all its schemes have a known conflict',
    (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => SearchResultsScreen.openAssessment(
                    context,
                    title: 'Test card',
                    schemes: [
                      for (var i = 0; i < 5; i++)
                        Scheme(
                          id: 'card-$i',
                          name: 'Card scheme $i',
                          eligibilityMaxAge: 45,
                        ),
                    ],
                    answers: const {'owner_age': 46},
                  ),
                  child: const Text('Open assessment results'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open assessment results'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Card scheme 0'), findsOneWidget);
      expect(find.text('Not for you now'), findsWidgets);
      expect(find.text('Good fit'), findsNothing);
    },
  );
}
