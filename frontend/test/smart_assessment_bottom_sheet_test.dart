import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/widgets/assistant/smart_assessment_bottom_sheet.dart';

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

  Future<void> tapOption(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('SmartAssessmentBottomSheet Tests', () {
    testWidgets('renders category flow correctly (Education)', (tester) async {
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

      expect(find.text('Education'), findsOneWidget);
      expect(
        find.text('What is your current level of education?'),
        findsOneWidget,
      );
      expect(find.text('Schooling (Up to 12th)'), findsOneWidget);
      expect(find.text('Undergraduate'), findsOneWidget);
      expect(find.text('Skip to Results'), findsOneWidget);
      // On first question, back button should not be visible
      expect(find.text('Back'), findsNothing);

      // Advance by tapping Schooling
      await tapOption(tester, 'Schooling (Up to 12th)');
      expect(
        find.text('What class/grade are you currently enrolled in?'),
        findsOneWidget,
      );
      // Now back button should be visible
      expect(find.text('Back'), findsOneWidget);

      // Go back
      await tapOption(tester, 'Back');
      expect(
        find.text('What is your current level of education?'),
        findsOneWidget,
      );

      // Skip to results completes the questionnaire
      await tapOption(tester, 'Skip to Results');
      expect(completed, isTrue);
    });

    testWidgets('renders state flow correctly (Tamil Nadu)', (tester) async {
      final provider = AppProvider();
      var completed = false;

      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Tamil Nadu',
          cardType: 'state',
          onCompleted: () => completed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tamil Nadu'), findsOneWidget);
      expect(
        find.text('Are you a permanent resident/domicile of Tamil Nadu?'),
        findsOneWidget,
      );
      expect(
        find.text('Yes, I hold a domicile certificate'),
        findsOneWidget,
      );

      await tapOption(tester, 'Yes, I hold a domicile certificate');
      expect(
        find.text(
          'What is your category in the Tamil Nadu state reservation list?',
        ),
        findsOneWidget,
      );

      // Skip to results
      await tapOption(tester, 'Skip to Results');
      expect(completed, isTrue);
      expect(provider.filters['state'], 'Tamil Nadu');
    });

    testWidgets('renders ministry flow correctly', (tester) async {
      final provider = AppProvider();
      var completed = false;

      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Ministry of Agriculture',
          cardType: 'ministry',
          onCompleted: () => completed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ministry of Agriculture'), findsOneWidget);
      expect(
        find.text("What is your primary objective within this ministry's portal?"),
        findsOneWidget,
      );
      expect(
        find.text('Applying for business subsidy / credit'),
        findsOneWidget,
      );

      await tapOption(tester, 'Skip to Results');
      expect(completed, isTrue);
      expect(provider.filters['ministry'], 'Ministry of Agriculture');
    });

    testWidgets('seeds answer from user profile and sets filters',
        (tester) async {
      final provider = AppProvider();
      provider.updateProfile(
        UserProfile(
          gender: 'Female',
          community: 'OBC',
          state: 'Tamil Nadu',
          annualIncome: 150000,
          profileCompleted: true,
        ),
      );

      var completed = false;
      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Tamil Nadu',
          cardType: 'state',
          onCompleted: () => completed = true,
        ),
      );
      await tester.pumpAndSettle();

      // State is Tamil Nadu and profile state is Tamil Nadu -> pre-fills yes
      // Skip directly to results
      await tapOption(tester, 'Skip to Results');
      expect(completed, isTrue);
      expect(provider.filters['state'], 'Tamil Nadu');
    });

    testWidgets('close icon button dismisses sheet without completion',
        (tester) async {
      final provider = AppProvider();
      var completed = false;

      // In this test, use showModalBottomSheet so Navigator.pop closes the modal
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (_) => ChangeNotifierProvider<AppProvider>.value(
                      value: provider,
                      child: SmartAssessmentBottomSheet(
                        cardTitle: 'Education',
                        cardType: 'category',
                        onCompleted: () => completed = true,
                      ),
                    ),
                  ),
                  child: const Text('open_sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open_sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(
        find.text('What is your current level of education?'),
        findsNothing,
      );
      expect(completed, isFalse);
    });

    testWidgets('renders properly in Tamil locale', (tester) async {
      SharedPreferences.setMockInitialValues({'language': 'ta'});
      final provider = AppProvider()..changeLanguage('ta');

      await tester.pumpWidget(
        hostSheet(
          provider: provider,
          cardTitle: 'Education',
          cardType: 'category',
          onCompleted: () {},
          locale: const Locale('ta'),
        ),
      );
      await tester.pumpAndSettle();

      // Tamil strings
      expect(find.text('உங்கள் தற்போதைய கல்வித் தகுதி என்ன?'), findsOneWidget);
      expect(find.text('முடிவுகளுக்குச் செல்'), findsOneWidget);
    });
  });
}
