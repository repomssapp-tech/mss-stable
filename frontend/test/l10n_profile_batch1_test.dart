// Batch 1 of the custom profile string-map -> gen-l10n ARB migration.
//
// These are execution tests (not just `flutter analyze`): each screen is
// pumped under a real `MaterialApp` locale and we assert, via `find.text`,
// that the exact Tamil / English strings that used to live in the old
// custom onboarding string map now render from `AppLocalizations`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/regular_mode/language_selection_screen.dart';

// Exact values copied from the old custom `_en` / `_ta` onboarding maps.
const _welcomeEn = 'Welcome!';
const _welcomeTa = 'வரவேற்கிறோம்!';
const _chooseLangEn = 'Choose Your Language';
const _chooseLangTa = 'உங்கள் மொழியை தேர்ந்தெடுக்கவும்';

Widget _host(Locale locale, Widget screen) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider(),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('LoginScreen renders ARB strings for the active locale', () {
    testWidgets('Tamil locale shows the Tamil welcome string', (tester) async {
      await tester.pumpWidget(_host(const Locale('ta'), const LoginScreen()));
      await tester.pump();

      expect(find.text(_welcomeTa), findsOneWidget);
      expect(find.text(_welcomeEn), findsNothing);
    });

    testWidgets('English locale shows the English welcome string', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Locale('en'), const LoginScreen()));
      await tester.pump();

      expect(find.text(_welcomeEn), findsOneWidget);
      expect(find.text(_welcomeTa), findsNothing);
    });
  });

  group('LanguageSelectionScreen renders ARB strings for the active locale', () {
    testWidgets('Tamil locale shows the Tamil title', (tester) async {
      await tester.pumpWidget(
        _host(const Locale('ta'), const LanguageSelectionScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(_chooseLangTa), findsOneWidget);
      expect(find.text(_chooseLangEn), findsNothing);
    });

    testWidgets('English locale shows the English title', (tester) async {
      await tester.pumpWidget(
        _host(const Locale('en'), const LanguageSelectionScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(_chooseLangEn), findsOneWidget);
      expect(find.text(_chooseLangTa), findsNothing);
    });

    testWidgets(
      'tapping the Tamil card live-previews Tamil without pressing Continue',
      (tester) async {
        await tester.pumpWidget(
          _host(const Locale('en'), const LanguageSelectionScreen()),
        );
        await tester.pumpAndSettle();

        // Starts in the ambient (English) locale.
        expect(find.text(_chooseLangEn), findsOneWidget);
        expect(find.text(_chooseLangTa), findsNothing);

        // Tap the Tamil option card (its English sub-title is "Tamil").
        await tester.tap(find.text('Tamil'));
        await tester.pumpAndSettle();

        // Preview flips to Tamil immediately; Continue was never pressed.
        expect(find.text(_chooseLangTa), findsOneWidget);
        expect(find.text(_chooseLangEn), findsNothing);
      },
    );
  });
}
