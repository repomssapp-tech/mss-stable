import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/widgets/legal_consent_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('login is Google-only with no mock phone or OTP controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('OTP'), findsNothing);
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets(
    'mandatory legal document consent flow gates Google sign-in button',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      // 1. Initial state
      expect(
        find.textContaining('I have read and agree to the'),
        findsOneWidget,
      );

      // Checkbox is unchecked
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      Checkbox checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isFalse);

      // Button is disabled initially
      final buttonFinder = find.widgetWithText(OutlinedButton, 'Continue with Google');
      expect(buttonFinder, findsOneWidget);
      OutlinedButton button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // 2. Interacting with disabled checkbox shows notice
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(
        find.text('Please review the Terms of Use and Privacy Policy before continuing.'),
        findsOneWidget,
      );
      checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isFalse);
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // 3. Open Terms of Use modal via link
      final textWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(LegalConsentSection),
          matching: find.byType(Text),
        ),
      );
      final textSpan = textWidget.textSpan! as TextSpan;
      final termsSpan = textSpan.children!.firstWhere(
        (s) => s is TextSpan && s.text == 'Terms of Use',
      ) as TextSpan;
      (termsSpan.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();

      // Modal content is visible
      expect(find.text('Rules and guidelines for using the MSS App'), findsOneWidget);
      expect(find.text('Effective Date: 1 September 2026'), findsOneWidget);
      expect(find.text('Use of the MSS App'), findsOneWidget);

      // Close Terms modal
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
      await tester.pumpAndSettle();

      // Checkbox and button still disabled (Privacy Policy not yet viewed)
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isFalse);
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // 4. Open Privacy Policy modal via link
      final privacySpan = textSpan.children!.firstWhere(
        (s) => s is TextSpan && s.text == 'Privacy Policy',
      ) as TextSpan;
      (privacySpan.recognizer as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();

      // Modal content is visible
      expect(
        find.text('How MSS collects, uses and protects your information'),
        findsOneWidget,
      );
      expect(find.text('Personal Data We Collect'), findsOneWidget);

      // Close Privacy modal
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
      await tester.pumpAndSettle();

      // Button is still disabled because checkbox is not yet checked
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // 5. Check the consent checkbox (now enabled because both are viewed)
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isTrue);

      // Button is now ENABLED
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNotNull);

      // 6. Unchecking checkbox disables button again
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isFalse);
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);
    },
  );

  const testDevices = <String, Size>{
    '320x568 (very small phone)': Size(320, 568),
    '360x640 (budget Android)': Size(360, 640),
    '390x844 (iPhone standard)': Size(390, 844),
    '412x915 (large Android)': Size(412, 915),
    '800x1280 (tablet)': Size(800, 1280),
  };

  for (final entry in testDevices.entries) {
    testWidgets('LoginScreen renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.textContaining('I have read and agree to the'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
