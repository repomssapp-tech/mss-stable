import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/widgets/legal/legal_consent_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login is Google-only with no mock phone or OTP controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('OTP'), findsNothing);
    expect(find.text('Apple'), findsNothing);
  });

  Future<void> scrollToEnd(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -600),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('mandatory legal document consent flow gates Google sign-in button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    // 1. Initial state
    expect(find.textContaining('I have read and agree to the'), findsOneWidget);

    // The data-usage consent is collected on the profile page: no checkbox here.
    expect(find.byType(Checkbox), findsNothing);

    // Button is disabled initially
    final buttonFinder = find.widgetWithText(
      OutlinedButton,
      'Continue with Google',
    );
    expect(buttonFinder, findsOneWidget);
    OutlinedButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);

    // 3. Open Terms of Use modal via link
    // The consent sentence is the first Text; the document buttons follow.
    final textWidget = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(LegalConsentSection),
            matching: find.byType(Text),
          )
          .first,
    );
    final textSpan = textWidget.textSpan! as TextSpan;
    final termsSpan =
        textSpan.children!.firstWhere(
              (s) => s is TextSpan && s.text == 'Terms of Use',
            )
            as TextSpan;
    (termsSpan.recognizer as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    // Modal content is visible
    expect(
      find.text('Rules and guidelines for using the MSS App'),
      findsOneWidget,
    );
    expect(find.text('Effective Date: 1 September 2026'), findsOneWidget);
    expect(find.text('Use of the MSS App'), findsOneWidget);

    // Accepting before reading to the end is refused with an alert...
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accept'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'You must scroll to the end of this document before you can accept it.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // ...and the sheet is still open: nothing was accepted.
    expect(find.text('Use of the MSS App'), findsOneWidget);

    // Accept Terms modal after scrolling to the end
    await scrollToEnd(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accept'));
    await tester.pumpAndSettle();

    // Button still disabled (Privacy Policy not yet accepted)
    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);

    // 4. Open Privacy Policy modal via link
    final privacySpan =
        textSpan.children!.firstWhere(
              (s) => s is TextSpan && s.text == 'Privacy Policy',
            )
            as TextSpan;
    (privacySpan.recognizer as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    // Modal content is visible
    expect(
      find.text('How MSS collects, uses and protects your information'),
      findsOneWidget,
    );
    expect(find.text('Personal Data We Collect'), findsOneWidget);

    // Accept Privacy modal (after scrolling to the end)
    await scrollToEnd(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accept'));
    await tester.pumpAndSettle();

    // 5. Accepting BOTH legal documents enables login
    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull);
  });

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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
          ),
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
