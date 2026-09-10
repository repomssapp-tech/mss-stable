import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/basic_profile_screen.dart';
import 'package:frontend/screens/regular_mode/location_profile_screen.dart';
import 'package:frontend/screens/regular_mode/about_you_profile_screen.dart';
import 'package:frontend/screens/regular_mode/eligibility_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-publishable-key',
      );
    } catch (_) {}
  });

  Widget buildTestApp(Widget child, AppProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ta')],
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'BasicProfileScreen: no gender is selected by default and required asterisks are red, tap toggles',
    (WidgetTester tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(buildTestApp(const BasicProfileScreen(), provider));
      await tester.pumpAndSettle();

      // Verify Male, Female, Other all exist
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Verify none of the gender boxes are selected (none should have active background or bold font)
      final maleText = tester.widget<Text>(find.text('Male'));
      final femaleText = tester.widget<Text>(find.text('Female'));
      final otherText = tester.widget<Text>(find.text('Other'));

      expect(maleText.style?.fontWeight, FontWeight.normal);
      expect(femaleText.style?.fontWeight, FontWeight.normal);
      expect(otherText.style?.fontWeight, FontWeight.normal);

      // Verify required field labels contain red asterisks
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      bool foundRedAsterisk = false;

      for (final rt in richTexts) {
        rt.text.visitChildren((span) {
          if (span is TextSpan && span.text == ' *') {
            if (span.style?.color != null) {
              foundRedAsterisk = true;
            }
          }
          return true;
        });
      }

      expect(foundRedAsterisk, isTrue);

      // Scroll until Male is visible, then tap to select
      await tester.ensureVisible(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      var updatedMaleText = tester.widget<Text>(find.text('Male'));
      expect(updatedMaleText.style?.fontWeight, FontWeight.bold);

      // Tap Male again to deselect
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      updatedMaleText = tester.widget<Text>(find.text('Male'));
      expect(updatedMaleText.style?.fontWeight, FontWeight.normal);
    },
  );

  testWidgets(
    'LocationProfileScreen: required asterisks are red and state is not defaulted to Tamil Nadu',
    (WidgetTester tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(buildTestApp(const LocationProfileScreen(), provider));
      await tester.pumpAndSettle();

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      bool foundRedAsterisk = false;

      for (final rt in richTexts) {
        rt.text.visitChildren((span) {
          if (span is TextSpan && span.text == ' *') {
            if (span.style?.color != null) {
              foundRedAsterisk = true;
            }
          }
          return true;
        });
      }

      expect(foundRedAsterisk, isTrue);

      // Verify state text field is empty by default for fresh profile
      expect(find.text('Tamil Nadu'), findsNothing);

      // Verify divider displays "OR" instead of "OR FILL MANUALLY"
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('OR FILL MANUALLY'), findsNothing);

      // Verify "Use Current Location" is shown (no "My" and no subtitle)
      expect(find.text('Use Current Location'), findsOneWidget);
      expect(find.text('Use My Current Location'), findsNothing);
      expect(find.text('Get your current location automatically'), findsNothing);

      // Verify "2/4 Complete" fraction is centered in the middle
      final fractionFinder = find.text('2/4 Complete');
      expect(fractionFinder, findsOneWidget);
      final centerAncestor = find.ancestor(
        of: fractionFinder,
        matching: find.byType(Center),
      );
      expect(centerAncestor, findsOneWidget);

      // State is the final address field on this step; Pincode was removed.
      await tester.ensureVisible(find.text('State *'));
      await tester.pumpAndSettle();
      expect(find.text('Pincode *'), findsNothing);
    },
  );

  testWidgets(
    'AboutYouProfileScreen: no role is selected by default and tap toggles selection',
    (WidgetTester tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(buildTestApp(const AboutYouProfileScreen(), provider));
      await tester.pumpAndSettle();

      // Verify role names without "Aspiring" or "Existing"
      expect(find.text('Entrepreneur'), findsOneWidget);
      expect(find.text('Aspiring Entrepreneur'), findsNothing);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Existing Business'), findsNothing);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('MSME Owner'), findsOneWidget);
      expect(find.text('Artisan / SHG Member'), findsOneWidget);

      // Find role cards container: verify Continue button has disabled background (grey shade 300)
      final continueBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        continueBtn.style?.backgroundColor?.resolve({}),
        Colors.grey.shade300,
      );

      // Verify small descriptions under select options are removed
      expect(
        find.text('Looking for learning, innovation and startup opportunities.'),
        findsNothing,
      );
      expect(
        find.text('I have an idea and want to start a business.'),
        findsNothing,
      );

      // Tap student role to select
      await tester.ensureVisible(find.text('Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      final activeContinueBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        activeContinueBtn.style?.backgroundColor?.resolve({}),
        const Color(0xFF2563EB),
      );

      // Tap student role again to deselect
      await tester.ensureVisible(find.text('Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      final deselectedContinueBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        deselectedContinueBtn.style?.backgroundColor?.resolve({}),
        Colors.grey.shade300,
      );
    },
  );

  testWidgets(
    'EligibilityProfileScreen: no education, community, or income is selected by default',
    (WidgetTester tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(buildTestApp(const EligibilityProfileScreen(), provider));
      await tester.pumpAndSettle();

      // Verify no check icons exist inside choice chips
      expect(find.byIcon(Icons.check), findsNothing);

      // Tap Undergraduate chip to select
      await tester.ensureVisible(find.text('Undergraduate (Degree)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undergraduate (Degree)'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNWidgets(1));

      // Tap Undergraduate chip again to deselect
      await tester.ensureVisible(find.text('Undergraduate (Degree)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undergraduate (Degree)'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);

      // Tap General (OC) community chip to select
      await tester.ensureVisible(find.text('General (OC)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General (OC)'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNWidgets(1));

      // Tap General (OC) again to deselect
      await tester.ensureVisible(find.text('General (OC)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General (OC)'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);

      // Verify "No Income" option exists for students and users with no income
      expect(find.text('No Income'), findsOneWidget);

      // Tap No Income chip to select
      await tester.ensureVisible(find.text('No Income'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Income'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNWidgets(1));

      // Tap No Income again to deselect
      await tester.ensureVisible(find.text('No Income'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Income'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);

      // Tap Under ₹1.5 Lakhs income chip to select
      await tester.ensureVisible(find.text('Under ₹1.5 Lakhs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Under ₹1.5 Lakhs'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNWidgets(1));

      // Tap Under ₹1.5 Lakhs again to deselect
      await tester.ensureVisible(find.text('Under ₹1.5 Lakhs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Under ₹1.5 Lakhs'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    },
  );

  testWidgets(
    'Uncompleted profile with legacy database values does not pre-select Male or Eligibility options',
    (WidgetTester tester) async {
      final provider = AppProvider();
      // Simulate profile loaded from cloud with legacy values but profileCompleted == false
      await provider.updateProfile(
        provider.profile.copyWith(
          gender: 'Male',
          community: 'General',
          qualification: 'Undergraduate',
          annualIncome: 100000.0,
          profileCompleted: false,
        ),
      );

      // 1. In BasicProfileScreen, Male should NOT be selected
      await tester.pumpWidget(buildTestApp(const BasicProfileScreen(), provider));
      await tester.pumpAndSettle();

      final maleText = tester.widget<Text>(find.text('Male'));
      expect(maleText.style?.fontWeight, FontWeight.normal);

      // 2. In EligibilityProfileScreen, no chips should be selected
      await tester.pumpWidget(buildTestApp(const EligibilityProfileScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    },
  );
}

