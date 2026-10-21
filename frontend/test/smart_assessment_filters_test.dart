// The Discover-page adaptive questionnaire must (1) turn the "what do you
// need" answers into real result filters, and (2) not re-ask what the
// onboarding profile already knows -- it pre-selects those answers instead.
//
// Before this change `_submitAnswers` folded every answer into the profile
// and set only a single category/state/ministry filter, so the list the
// user landed on was identical no matter what they picked.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/widgets/assistant/smart_assessment_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget host(AppProvider provider, String title, String type) =>
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          // smart_assessment_bottom_sheet.dart now resolves its strings via
          // AppLocalizations (context.l10n); a bare MaterialApp returns null
          // and build() throws. Delegates added, no explicit locale -> en.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: SmartAssessmentBottomSheet(
                      cardTitle: title,
                      cardType: type,
                      onCompleted: () {},
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapOption(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'need-type answers become a schemeTypes filter; male keeps no beneficiary',
    (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(
        host(provider, 'Business Loans & Credit', 'category'),
      );
      await open(tester);

      // biz_q1 -> biz_q2_artisan -> biz_q3_artisan_need -> biz_q4 -> biz_q5
      await tapOption(tester, 'No, operating as individual trader/artisan');
      await tapOption(tester, 'No, not registered');
      await tapOption(tester, 'Individual craft micro-loan');
      await tapOption(tester, 'General category Male');
      await tapOption(tester, 'Under ₹10 Lakhs');

      final f = provider.filters;
      expect(
        f['category'],
        isNull,
        reason: 'the card is the browse page base set, not a second facet',
      );
      expect(
        (f['schemeTypes'] as List).cast<String>(),
        contains('loans'),
        reason: 'the "micro-loan" answer must narrow the result list',
      );
      expect(
        f.containsKey('beneficiaries'),
        isFalse,
        reason: 'a General-category male picked no beneficiary group',
      );
    },
  );

  testWidgets(
    'a gender question is pre-filled from the profile (no tap needed)',
    (tester) async {
      final provider = AppProvider();
      provider.updateProfile(
        UserProfile(
          gender: 'Female',
          community: 'SC',
          dob: DateTime(2000, 1, 1),
          profileCompleted: true,
        ),
      );

      // "Housing" matches no keyword -> the default category flow, whose
      // cat_q3 asks gender and cat_q4 asks caste.
      await tester.pumpWidget(host(provider, 'Housing', 'category'));
      await open(tester);

      await tapOption(tester, 'Student'); // cat_q1
      await tapOption(tester, 'Subsidies & welfare grants'); // cat_q2
      // Now on cat_q3 (gender). Do NOT answer it -- skip straight to results.
      await tapOption(tester, 'Skip to Results');

      expect(
        (provider.filters['beneficiaries'] as List).cast<String>(),
        contains('women'),
        reason:
            'gender was auto-seeded to Female from the profile, so the '
            'beneficiary facet is applied without the user re-picking it',
      );
    },
  );
}
