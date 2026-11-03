import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/eligibility_results_screen.dart';
import 'package:frontend/screens/regular_mode/search_results_screen.dart';
import 'package:frontend/services/account/session_cache_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionCacheService - Eligibility Results', () {
    test(
      'saves and retrieves saved eligibility results and timestamp',
      () async {
        final cache = SessionCacheService.instance;
        expect(await cache.getSavedEligibilityResults(), isNull);
        expect(await cache.getLastEligibilitySavedAt(), isNull);

        final testIds = ['scheme-101', 'scheme-202'];
        final testTime = DateTime(2026, 9, 8, 10, 30);
        await cache.saveSavedEligibilityResults(testIds, testTime);

        final retrievedIds = await cache.getSavedEligibilityResults();
        final retrievedTime = await cache.getLastEligibilitySavedAt();

        expect(retrievedIds, equals(testIds));
        expect(retrievedTime, equals(testTime));

        // Test clear
        await cache.clearSavedEligibilityResults();
        expect(await cache.getSavedEligibilityResults(), isNull);
        expect(await cache.getLastEligibilitySavedAt(), isNull);
      },
    );
  });

  group('AppProvider - Eligibility Persistence', () {
    test(
      'saveEligibilityResults updates in-memory state and notifies listeners',
      () async {
        final provider = AppProvider();
        expect(provider.savedEligibilitySchemeIds, isEmpty);
        expect(provider.hasSavedEligibilityResults, isFalse);

        bool notified = false;
        provider.addListener(() {
          notified = true;
        });

        final testIds = ['scheme-a', 'scheme-b'];
        await provider.saveEligibilityResults(testIds);

        expect(provider.savedEligibilitySchemeIds, equals(testIds));
        expect(provider.hasSavedEligibilityResults, isTrue);
        expect(provider.lastEligibilitySavedAt, isNotNull);
        expect(notified, isTrue);

        // Verify cached in SharedPreferences
        final cachedIds = await SessionCacheService.instance
            .getSavedEligibilityResults();
        expect(cachedIds, equals(testIds));
      },
    );
  });

  group('EligibilityResultsScreen Widget Tests', () {
    Widget buildTestWidget(AppProvider provider) {
      return ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ta')],
          home: EligibilityResultsScreen(),
        ),
      );
    }

    testWidgets('renders empty state when no eligible schemes exist', (
      tester,
    ) async {
      final provider = AppProvider();
      provider.setRecommendedSchemesForTesting([]);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Your results'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('0 government schemes'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'No matching schemes found. Adjust your profile details to expand matching rules.',
        ),
        findsOneWidget,
      );
      expect(find.text('Explore all schemes'), findsOneWidget);
      expect(find.text('View All'), findsNothing);
    });

    testWidgets(
      'renders eligible matches, saves results on button tap, and navigates via View All',
      (tester) async {
        final provider = AppProvider();
        final dummyScheme = const Scheme(
          id: 'test-scheme-1',
          name: 'Tamil Nadu MSME Growth Scheme',
          schemeCode: 'TN-MSME-01',
          category: 'MSME',
          state: 'Tamil Nadu',
          overview: 'Support scheme for micro enterprises in Tamil Nadu.',
        );
        final dummyResult = RecommendationResult(
          score: 0.85,
          matchingReasons: ['Matches state Tamil Nadu', 'Matches sector MSME'],
          missingRequirements: [],
          missingDocuments: [],
        );

        provider.setRecommendedSchemesForTesting([
          MapEntry(dummyScheme, dummyResult),
        ]);

        await tester.pumpWidget(buildTestWidget(provider));
        await tester.pumpAndSettle();

        // 1. Verify Header and Counts
        expect(find.text('Your results'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('1 government schemes'),
          ),
          findsOneWidget,
        );
        expect(find.text('Recommended schemes'), findsOneWidget);
        expect(find.text('View All'), findsOneWidget);

        // 2. Tap "Save Results"
        expect(find.text('Save results'), findsOneWidget);
        await tester.tap(find.text('Save results'));
        await tester.pump(); // Start async save

        await tester.pumpAndSettle(); // Finish save

        // 3. Verify Button updates to "Saved to Profile", is disabled, and provider has persisted ID
        expect(find.text('Saved to profile'), findsOneWidget);
        final saveBtn = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(saveBtn.onPressed, isNull);
        expect(provider.savedEligibilitySchemeIds, contains('test-scheme-1'));

        final cachedIds = await SessionCacheService.instance
            .getSavedEligibilityResults();
        expect(cachedIds, contains('test-scheme-1'));

        // 4. Tap "View All" and verify SearchResultsScreen is pushed and displays schemes
        await tester.tap(find.text('View All'));
        await tester.pumpAndSettle();

        expect(find.byType(SearchResultsScreen), findsOneWidget);
        expect(find.text('Tamil Nadu MSME Growth Scheme'), findsOneWidget);
      },
    );
  });
}
