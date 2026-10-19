import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/scheme_details_screen.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Scheme> allSchemes;
  late Map<String, Scheme> schemesById;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    allSchemes = await SchemeRepository.instance.getAllSchemes();
    schemesById = {for (final s in allSchemes) s.id: s};
  });

  Widget wrapScreen(Scheme scheme, {Locale locale = const Locale('en')}) {
    return ChangeNotifierProvider.value(
      value: AppProvider(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ta')],
        home: SchemeDetailsScreen(scheme: scheme),
      ),
    );
  }

  group('Catalog v3.1 Screen Integration & Recommendation Tests', () {
    testWidgets(
      'CEN2026-174 (MCGS) renders in English with header, ministry, and tabs',
      (tester) async {
        final s255 = schemesById['CEN2026-174'];
        expect(s255, isNotNull, reason: 'CEN2026-174 must exist in catalog');

        await tester.pumpWidget(wrapScreen(s255!));
        await tester.pumpAndSettle();

        // Verify screen renders
        expect(find.byType(SchemeDetailsScreen), findsOneWidget);

        // Verify ministry or department is non-empty
        expect(
          s255.ministry.isNotEmpty || s255.sponsoringBody.isNotEmpty,
          isTrue,
        );

        // Verify overview tab is present and selected
        expect(find.text('Overview'), findsWidgets);
      },
    );

    testWidgets('CEN2026-174 (MCGS) renders in Tamil without crash', (
      tester,
    ) async {
      final s255 = schemesById['CEN2026-174'];
      expect(s255, isNotNull);

      await tester.pumpWidget(wrapScreen(s255!, locale: const Locale('ta')));
      await tester.pumpAndSettle();

      expect(find.byType(SchemeDetailsScreen), findsOneWidget);
    });

    testWidgets('CEN2026-208 (PM Surya Ghar) renders in English and Tamil', (
      tester,
    ) async {
      final s289 = schemesById['CEN2026-208'];
      expect(s289, isNotNull, reason: 'CEN2026-208 must exist in catalog');

      await tester.pumpWidget(wrapScreen(s289!));
      await tester.pumpAndSettle();
      expect(find.byType(SchemeDetailsScreen), findsOneWidget);

      await tester.pumpWidget(wrapScreen(s289, locale: const Locale('ta')));
      await tester.pumpAndSettle();
      expect(find.byType(SchemeDetailsScreen), findsOneWidget);
    });

    testWidgets('CEN2026-079 renders in English and Tamil', (tester) async {
      final s124 = schemesById['CEN2026-079'];
      expect(s124, isNotNull, reason: 'CEN2026-079 must exist in catalog');

      await tester.pumpWidget(wrapScreen(s124!));
      await tester.pumpAndSettle();
      expect(find.byType(SchemeDetailsScreen), findsOneWidget);

      await tester.pumpWidget(wrapScreen(s124, locale: const Locale('ta')));
      await tester.pumpAndSettle();
      expect(find.byType(SchemeDetailsScreen), findsOneWidget);
    });

    test('PMEGP CEN2026-085 carries second loan details in benefits', () {
      final s130 = schemesById['CEN2026-085'];
      expect(s130, isNotNull, reason: 'CEN2026-085 must exist in catalog');

      final benefitsLower = s130!.benefits.toLowerCase();
      final hasSecondLoan =
          benefitsLower.contains('second') ||
          benefitsLower.contains('upgrading') ||
          benefitsLower.contains('1 crore');
      expect(
        hasSecondLoan,
        isTrue,
        reason: 'PMEGP benefits must contain second loan / upgrade details',
      );
    });

    test(
      'For Me Evaluation: 30yo woman, TN, micro manufacturing includes CEN2026-174 and excludes CEN2026-198',
      () {
        final womanProfile = UserProfile(
          gender: 'Female',
          state: 'Tamil Nadu',
          dob: DateTime(1996, 1, 1), // 30yo
          employmentStatus: 'Business Owner',
          existingBusiness: true,
          businessStage: 'Operational',
          businessIndustry: 'Manufacturing',
        );

        final s255 = schemesById['CEN2026-174'];
        final s279 = schemesById['CEN2026-198'];
        expect(s255, isNotNull);
        expect(s279, isNotNull);

        final res255 = RecommendationEngine.evaluate(womanProfile, s255!);
        final res279 = RecommendationEngine.evaluate(womanProfile, s279!);

        // CEN2026-174: Eligible for 30yo micro manufacturing entrepreneur (score 0.35)
        expect(
          res255.score,
          greaterThan(0.3),
          reason:
              'CEN2026-174 must have substantive match (sector + national coverage)',
        );

        // CEN2026-198: PMIS youth scheme (age 21-24) -> 30yo user is age-gated out
        expect(
          res255.score,
          greaterThan(res279.score),
          reason:
              'CEN2026-174 must score higher than age-restricted CEN2026-198',
        );
        expect(
          res279.missingRequirements.any(
            (m) => m.toLowerCase().contains('age'),
          ),
          isTrue,
          reason:
              'Missing requirements for CEN2026-198 must explicitly report age disqualification',
        );
      },
    );
  });
}
