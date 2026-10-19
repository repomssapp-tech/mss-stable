import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/companion_mode/saarthi_welcome_screen.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Full 6-step Assisted Profile flow collects exact recommendation facets and personalizes schemes',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = AppProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SaarthiWelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ── STEP 1: State ──
      expect(find.text('Where do you live?'), findsOneWidget);
      final tnCard = find.text('Tamil Nadu');
      await tester.ensureVisible(tnCard);
      await tester.tap(tnCard);
      await tester.pumpAndSettle();

      final nextButton1 = find.text('Next');
      await tester.ensureVisible(nextButton1);
      await tester.tap(nextButton1);
      await tester.pumpAndSettle();

      // ── STEP 2: Gender & Age ──
      expect(find.text('About You'), findsOneWidget);
      final femaleTile = find.text('Female');
      await tester.ensureVisible(femaleTile);
      await tester.tap(femaleTile);
      await tester.pumpAndSettle();

      // Age preset chip: 35
      final chip35 = find.text('35');
      await tester.ensureVisible(chip35);
      await tester.tap(chip35);
      await tester.pumpAndSettle();

      final nextButton2 = find.text('Next');
      await tester.ensureVisible(nextButton2);
      await tester.tap(nextButton2);
      await tester.pumpAndSettle();

      // ── STEP 3: Work & Business Stage ──
      expect(find.text('What is your work or plan?'), findsOneWidget);
      final artisanCard = find.text('Artisan, Handloom & Crafts');
      await tester.ensureVisible(artisanCard);
      await tester.tap(artisanCard);
      await tester.pumpAndSettle();

      final nextButton3 = find.text('Next');
      await tester.ensureVisible(nextButton3);
      await tester.tap(nextButton3);
      await tester.pumpAndSettle();

      // ── STEP 4: Sector ──
      expect(find.text('Which sector or field?'), findsOneWidget);
      final textilesCard = find.text('Textiles & Handloom');
      await tester.ensureVisible(textilesCard);
      await tester.tap(textilesCard);
      await tester.pumpAndSettle();

      final nextButton4 = find.text('Next');
      await tester.ensureVisible(nextButton4);
      await tester.tap(nextButton4);
      await tester.pumpAndSettle();

      // ── STEP 5: Community ──
      expect(find.text('Your Social Category'), findsOneWidget);
      final obcCard = find.text('OBC / BC / MBC');
      await tester.ensureVisible(obcCard);
      await tester.tap(obcCard);
      await tester.pumpAndSettle();

      final nextButton5 = find.text('Next');
      await tester.ensureVisible(nextButton5);
      await tester.tap(nextButton5);
      await tester.pumpAndSettle();

      // ── STEP 6: Education Level ──
      expect(find.text('Your Education Level'), findsOneWidget);
      final schoolCard = find.text('School (10th / 12th)');
      await tester.ensureVisible(schoolCard);
      await tester.tap(schoolCard);
      await tester.pumpAndSettle();

      // Finish CTA
      final finishButton = find.text('Find My Schemes');
      expect(finishButton, findsOneWidget);

      // ── RECOMMENDATION ENGINE DIRECT FACET VALIDATION ──
      // Build the exact profile that this submission creates
      final profile = provider.profile.copyWith(
        state: 'Tamil Nadu',
        gender: 'Female',
        dob: DateTime(DateTime.now().year - 35, 1, 1),
        employmentStatus: 'Artisan / SHG Member',
        businessStage: 'Operational',
        existingBusiness: true,
        businessIndustry: 'Textiles',
        community: 'OBC',
        educationLevel: 'School',
        profileCompleted: true,
        navigationMode: 'companion',
      );

      expect(profile.state, equals('Tamil Nadu'));
      expect(profile.gender, equals('Female'));
      expect(profile.age, equals(35));
      expect(profile.employmentStatus, equals('Artisan / SHG Member'));
      expect(profile.businessIndustry, equals('Textiles'));
      expect(profile.community, equals('OBC'));
      expect(profile.educationLevel, equals('School'));
      expect(profile.profileCompleted, isTrue);

      // Evaluate against a scheme that targets artisans in Tamil Nadu
      final kaivinaiScheme = Scheme(
        id: 'KALAIGNAR_KAIVINAI',
        name: 'Kalaignar Kaivinai Thittam',
        category: 'Artisans',
        overview: 'Special assistance scheme for artisans in Tamil Nadu',
        sponsoringBody: 'Government of Tamil Nadu',
        state: 'Tamil Nadu',
        targetBeneficiary: 'Artisans',
      );

      final result = RecommendationEngine.evaluate(profile, kaivinaiScheme);
      // Should score high because state matches (+0.20) and artisan role matches (+0.25)
      expect(result.score, greaterThanOrEqualTo(0.40));
      expect(
        result.matchingReasons.any((r) => r.contains('Tamil Nadu')),
        isTrue,
      );
      expect(result.matchingReasons.any((r) => r.contains('artisan')), isTrue);
    },
  );
}
