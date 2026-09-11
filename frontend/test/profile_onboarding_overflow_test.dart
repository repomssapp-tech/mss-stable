// Phase 5 regression: the four-step "Complete Your Profile" flow must lay out
// without a RenderFlex overflow at the narrowest supported width (320 dp) and
// the largest text scale that ships (main.dart clamps device text scaling to
// [1.20, 1.30], so 1.30 is the worst case).
//
// Before the fix, LocationProfileScreen put the "Where Are You Located?"
// heading and the "Step 2 of 4" counter in a spaceBetween Row with neither
// child flexible, so they collided and overflowed at this size.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/about_you_profile_screen.dart';
import 'package:frontend/screens/regular_mode/basic_profile_screen.dart';
import 'package:frontend/screens/regular_mode/eligibility_profile_screen.dart';
import 'package:frontend/screens/regular_mode/location_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Size _narrowPhone = Size(320, 568);
const double _maxShippedTextScale = 1.30;

Future<void> _pumpStep(WidgetTester tester, Widget step) async {
  final provider = AppProvider();
  addTearDown(provider.dispose);

  tester.view.physicalSize = _narrowPhone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(_maxShippedTextScale)),
          child: child!,
        ),
        home: step,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final steps = <String, Widget Function()>{
    'Step 1 - Basic details': () => const BasicProfileScreen(),
    'Step 2 - Location': () => const LocationProfileScreen(),
    'Step 3 - About you': () => const AboutYouProfileScreen(),
    'Step 4 - Eligibility': () => const EligibilityProfileScreen(),
  };

  steps.forEach((name, build) {
    testWidgets(
      '$name has no RenderFlex overflow at 320dp / 1.30x text scale',
      (tester) async {
        await _pumpStep(tester, build());
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets(
    'Step 2 heading and step counter are both fully visible (no collision)',
    (tester) async {
      await _pumpStep(tester, const LocationProfileScreen());
      expect(find.text('Where Are You Located?'), findsOneWidget);
      expect(find.text('2/4 Complete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Step 1 phone field shows the +91 prefix before focus', (
    tester,
  ) async {
    await _pumpStep(tester, const BasicProfileScreen());
    // Rendered in the prefixIcon slot, so it is present without focusing.
    expect(find.text('+91 '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Step 1 age field shows the "e.g. 25" placeholder', (
    tester,
  ) async {
    await _pumpStep(tester, const BasicProfileScreen());
    expect(find.text('e.g. 25'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Step 2 Continue stays disabled until every address field is valid',
    (tester) async {
      await _pumpStep(tester, const LocationProfileScreen());

      ElevatedButton button() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      Color? bg() => button().style?.backgroundColor?.resolve(<WidgetState>{});

      // Step 2 fields, in tree order: address, city/town, district, state.
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));

      // Nothing filled in -> greyed.
      expect(bg(), Colors.grey.shade300);

      await tester.enterText(fields.at(0), 'Flat 402, Royal Enclave');
      await tester.enterText(fields.at(1), 'Anna Nagar West');
      await tester.enterText(fields.at(2), 'Chennai');
      await tester.pump();

      // State still blank -> still greyed.
      expect(bg(), Colors.grey.shade300);

      await tester.enterText(fields.at(3), 'Tamil Nadu');
      await tester.pump();

      // All four valid -> enabled.
      expect(bg(), const Color(0xFF2563EB));
      expect(tester.takeException(), isNull);
    },
  );
}
