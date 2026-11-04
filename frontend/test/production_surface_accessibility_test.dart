import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/navigation_mode_screen.dart' as app_navigation;
import 'package:frontend/screens/regular_mode/about_you_profile_screen.dart';
import 'package:frontend/screens/regular_mode/basic_profile/state_picker_field.dart';
import 'package:frontend/screens/regular_mode/basic_profile_screen.dart';
import 'package:frontend/screens/regular_mode/language_selection_screen.dart';
import 'package:frontend/screens/regular_mode/location_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phoneViewport = Size(320, 568);
const _tabletViewport = Size(800, 1000);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final viewport in <String, Size>{
    'narrow phone': _phoneViewport,
    'wide tablet': _tabletViewport,
  }.entries) {
    testWidgets(
      'Google-only login is accessible and overflow-free on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);

          await _pumpSurface(tester, provider, const LoginScreen());

          final googleButton = find.widgetWithText(
            OutlinedButton,
            'Continue with Google',
          );
          expect(googleButton, findsOneWidget);
          expect(find.byType(TextFormField), findsNothing);
          expect(find.textContaining('OTP'), findsNothing);
          expect(find.textContaining('Mobile number'), findsNothing);
          // Google sign-in is gated behind reading and accepting the legal
          // documents, so it starts disabled.
          expect(tester.widget<OutlinedButton>(googleButton).onPressed, isNull);
          expect(find.byType(Checkbox), findsNothing);
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'navigation mode controls select and continue on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);
          app_navigation.NavigationMode? submittedMode;

          await _pumpSurface(
            tester,
            provider,
            app_navigation.NavigationModeScreen(
              onContinue: (mode) => submittedMode = mode,
            ),
          );

          expect(find.text('Regular Navigation'), findsOneWidget);
          expect(find.text('AI Companion'), findsOneWidget);
          expect(
            find.byType(app_navigation.NavigationOptionCard),
            findsNWidgets(2),
          );

          await tester.ensureVisible(find.text('AI Companion'));
          await tester.tap(find.text('AI Companion'));
          await tester.pump(const Duration(milliseconds: 350));

          final continueButton = find.widgetWithText(
            ElevatedButton,
            'Continue',
          );
          await tester.ensureVisible(continueButton);
          expect(
            tester.widget<ElevatedButton>(continueButton).onPressed,
            isNotNull,
          );
          _expectTappableSemantics(tester, continueButton, 'Continue');
          await tester.tap(continueButton);
          await tester.pump();

          expect(submittedMode, app_navigation.NavigationMode.companion);
          expect(provider.navigationMode, 'companion');
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'language selection is operable and persists Tamil on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);

          await _pumpSurface(tester, provider, const LanguageSelectionScreen());

          expect(find.text('Choose your language'), findsOneWidget);
          expect(find.text('English'), findsNWidgets(2));
          expect(find.text('Tamil'), findsOneWidget);
          expect(find.byType(InkWell), findsAtLeastNWidgets(2));

          final continueButton = find.byType(ElevatedButton);
          await tester.ensureVisible(continueButton);
          _expectTappableSemantics(tester, continueButton, 'Continue');

          await tester.ensureVisible(find.text('Tamil'));
          await tester.tap(find.text('Tamil'));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.ensureVisible(continueButton);
          await tester.tap(continueButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(provider.selectedLanguage, 'ta');
          expect(find.byType(LoginScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'profile onboarding controls validate safely on ${viewport.key}',
      (tester) async {
        await _withSemantics(tester, () async {
          final provider = AppProvider();
          addTearDown(provider.dispose);
          _setViewport(tester, viewport.value);

          await _pumpSurface(tester, provider, const BasicProfileScreen());
          expect(find.text('Complete your profile'), findsOneWidget);
          expect(find.textContaining('Full Name'), findsOneWidget);
          expect(find.textContaining('Email Address'), findsOneWidget);
          expect(find.textContaining('Gender'), findsOneWidget);
          // Step 1 collects age (DOB is derived from it), not a DOB field.
          expect(find.text('Age *'), findsOneWidget);
          expect(find.byType(TextFormField), findsAtLeastNWidgets(3));

          var continueButton = find.widgetWithText(ElevatedButton, 'Continue');
          await tester.ensureVisible(continueButton);
          _expectTappableSemantics(tester, continueButton, 'Continue');
          await tester.tap(continueButton);
          await tester.pump();
          expect(find.text('Please enter your full name'), findsOneWidget);
          expect(find.byType(LocationProfileScreen), findsNothing);
          expect(tester.takeException(), isNull);

          await _pumpSurface(tester, provider, const LocationProfileScreen());
          await tester.pump();
          expect(find.text('Where are you located?'), findsOneWidget);
          expect(find.text('Use current location'), findsOneWidget);
          // Address, city/town and pincode are typed; the state and the
          // district are picked from lists.
          expect(find.byType(TextFormField), findsNWidgets(3));
          expect(find.byType(StatePickerField), findsOneWidget);
          continueButton = find.widgetWithText(ElevatedButton, 'Continue');
          await tester.ensureVisible(continueButton);
          _expectTappableSemantics(tester, continueButton, 'Continue');
          await tester.tap(continueButton);
          await tester.pump();
          expect(
            find.text('Please enter your house/street address'),
            findsOneWidget,
          );
          expect(find.byType(AboutYouProfileScreen), findsNothing);
          expect(tester.takeException(), isNull);

          await _pumpSurface(tester, provider, const AboutYouProfileScreen());
          expect(find.text('Tell us about you'), findsOneWidget);
          expect(find.text('Student'), findsOneWidget);
          expect(find.text('Farmer'), findsOneWidget);
          continueButton = find.widgetWithText(ElevatedButton, 'Continue');
          await tester.ensureVisible(continueButton);
          await tester.tap(continueButton);
          await tester.pump();
          expect(provider.profile.profileCompleted, isFalse);
          expect(tester.takeException(), isNull);
        });
      },
    );
  }
}

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpSurface(
  WidgetTester tester,
  AppProvider provider,
  Widget home,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
}

void _expectTappableSemantics(
  WidgetTester tester,
  Finder finder,
  String expectedLabel,
) {
  expect(finder, findsOneWidget);
  final semanticsFinder = find.bySemanticsLabel(expectedLabel);
  expect(semanticsFinder, findsOneWidget);
  final data = tester.getSemantics(semanticsFinder).getSemanticsData();
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}
