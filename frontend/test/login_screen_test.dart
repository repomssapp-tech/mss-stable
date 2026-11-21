import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/navigation_mode_screen.dart';
import 'package:frontend/screens/permissions/app_permissions_screen.dart';
import 'package:frontend/screens/regular_mode/basic_profile_screen.dart';
import 'package:frontend/services/account/onboarding_api_service.dart';
import 'package:frontend/services/account/session_cache_service.dart';
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

  testWidgets('no password sign-in; the checklist rows open the documents', (
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

    expect(find.text('Sign in with password'), findsNothing);

    // One consent sentence, then the two "Read the ..." rows: the document
    // names are not repeated as separate buttons. The only text button is
    // "Continue as guest" is now an equal outlined button, not a text link.
    expect(find.byType(TextButton), findsNothing);
    expect(
      find.byKey(const ValueKey('login-continue-as-guest')),
      findsOneWidget,
    );
    final rows = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.textSpan != null &&
          w.textSpan!.toPlainText().startsWith('Read the '),
    );
    expect(rows, findsNWidgets(2));
    expect(
      tester.widget<Text>(rows.at(0)).textSpan!.toPlainText(),
      'Read the Terms of Use',
    );
    expect(
      tester.widget<Text>(rows.at(1)).textSpan!.toPlainText(),
      'Read the Privacy Policy',
    );

    await tester.ensureVisible(rows.at(0));
    await tester.tap(rows.at(0));
    await tester.pumpAndSettle();
    expect(find.text('Use of the MSS App'), findsOneWidget);
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

  testWidgets(
    'guest entry requires both legal documents and persists the session',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AppPermissionsStore.askedKey: true,
      });
      final provider = AppProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      // 1. Initial state: the two "Read the ..." rows are the consent text.
      expect(find.textContaining('I have read and agree to the'), findsNothing);
      expect(find.textContaining('Read the '), findsNWidgets(2));

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

      // 3. Open the Terms of Use from its checklist row.
      final termsRow = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.textSpan != null &&
            w.textSpan!.toPlainText() == 'Read the Terms of Use',
      );
      await tester.ensureVisible(termsRow);
      await tester.tap(termsRow);
      await tester.pumpAndSettle();

      // Modal content is visible
      expect(
        find.text('Rules and guidelines for using the MSS App'),
        findsOneWidget,
      );
      expect(find.text('Effective Date: 1 September 2026'), findsOneWidget);
      expect(find.text('Use of the MSS App'), findsOneWidget);

      // Before the end, Accept stays disabled and the sheet stays open.
      final accept = find.widgetWithText(ElevatedButton, 'Accept');
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNull);
      expect(find.text('Scroll to the end to enable Accept'), findsOneWidget);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(find.text('Use of the MSS App'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      final guest = find.byKey(const ValueKey('login-continue-as-guest'));
      expect(tester.widget<OutlinedButton>(guest).onPressed, isNull);
      await tester.tap(termsRow);
      await tester.pumpAndSettle();

      // Accept Terms modal after scrolling to the end
      await scrollToEnd(tester);
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNotNull);
      await tester.tap(accept);
      await tester.pumpAndSettle();

      // Button still disabled (Privacy Policy not yet accepted)
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // 4. Open the Privacy Policy from its checklist row.
      final privacyRow = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.textSpan != null &&
            w.textSpan!.toPlainText() == 'Read the Privacy Policy',
      );
      await tester.ensureVisible(privacyRow);
      await tester.tap(privacyRow);
      await tester.pumpAndSettle();

      // Modal content is visible
      expect(
        find.text('How MSS collects, uses and protects your information'),
        findsOneWidget,
      );
      expect(find.text('Personal Data We Collect'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNull);

      // Accept Privacy modal (after scrolling to the end)
      await scrollToEnd(tester);
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNotNull);
      await tester.tap(accept);
      await tester.pumpAndSettle();

      // 5. Accepting BOTH legal documents enables login
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNotNull);

      // The two rows stay on screen, both ticked.
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);

      await tester.ensureVisible(guest);
      await tester.tap(guest);
      await tester.tap(guest);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationModeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(provider.isGuest, isTrue);
      expect(await SessionCacheService.instance.getIsGuest(), isTrue);
      expect(await LegalConsentStore.hasLoginAgreement(), isTrue);

      final continueButton = find.byType(PrimaryButton);
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(MainTabsContainer), findsOneWidget);
      expect(find.byType(BasicProfileScreen), findsNothing);
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Read the '), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
