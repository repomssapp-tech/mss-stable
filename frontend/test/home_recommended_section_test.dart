import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/home/home_recommended_section.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-publishable-key',
      );
    } catch (_) {}
  });

  Widget buildTestWidget(AppProvider provider, {List<Scheme>? schemes}) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ta')],
        home: Scaffold(
          body: HomeRecommendedSection(provider: provider, schemes: schemes),
        ),
      ),
    );
  }

  const dummyScheme = Scheme(
    id: 'test-scheme-1',
    name: 'Tamil Nadu MSME Growth Scheme',
    schemeCode: 'TN-MSME-01',
    category: 'MSME',
    state: 'Tamil Nadu',
    overview: 'Support scheme for micro enterprises in Tamil Nadu.',
  );

  group('HomeRecommendedSection', () {
    testWidgets(
      'shows a match badge with the real recommendation percentage, and '
      'nothing starts pre-bookmarked',
      (tester) async {
        final provider = AppProvider();
        final realResult = RecommendationResult(
          score: 0.85,
          matchingReasons: ['Matches state Tamil Nadu'],
          missingRequirements: [],
          missingDocuments: [],
        );
        provider.setRecommendedSchemesForTesting([
          MapEntry(dummyScheme, realResult),
        ]);

        await tester.pumpWidget(buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.textContaining('85%'), findsOneWidget);
        // Nothing may ever start pre-bookmarked.
        expect(find.byIcon(Icons.bookmark), findsNothing);
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      },
    );

    testWidgets(
      'never shows a match badge for an item with no real recommendation '
      'result (the widget.schemes test seam carries no score)',
      (tester) async {
        final provider = AppProvider();
        provider.setRecommendedSchemesForTesting([]);

        await tester.pumpWidget(
          buildTestWidget(provider, schemes: [dummyScheme]),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('%'), findsNothing);
        expect(find.text(dummyScheme.name), findsOneWidget);
      },
    );

    testWidgets(
      'shows the empty-state message and a profile CTA when there are no '
      'recommendations, instead of fabricated placeholder cards',
      (tester) async {
        final provider = AppProvider();
        provider.setRecommendedSchemesForTesting([]);

        await tester.pumpWidget(buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(
          find.text('Complete your profile to see recommendations'),
          findsOneWidget,
        );
        expect(find.text('Complete Profile'), findsOneWidget);
        // The old hardcoded placeholder cards must be gone.
        expect(find.textContaining('PMEGP Loan'), findsNothing);
        expect(find.textContaining('95%'), findsNothing);
      },
    );

    testWidgets(
      'tapping the bookmark icon stores scheme.id, not scheme.schemeCode '
      '(H7: the two always differ in the real catalog)',
      (tester) async {
        final provider = AppProvider();
        final realResult = RecommendationResult(
          score: 0.85,
          matchingReasons: const [],
          missingRequirements: const [],
          missingDocuments: const [],
        );
        provider.setRecommendedSchemesForTesting([
          MapEntry(dummyScheme, realResult),
        ]);

        await tester.pumpWidget(buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.bookmark_border));
        await tester.pumpAndSettle();

        expect(provider.bookmarkedIds, equals([dummyScheme.id]));
        expect(
          provider.bookmarkedIds,
          isNot(contains(dummyScheme.schemeCode)),
        );
      },
    );
  });
}
