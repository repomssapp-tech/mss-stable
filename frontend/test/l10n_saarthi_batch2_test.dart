// Batch 2 of the hardcoded-bilingual-string -> gen-l10n ARB migration:
// the Saarthi / AI / voice screens.
//
// Execution tests (not just `flutter analyze`): each screen is pumped under a
// real `MaterialApp` locale (or, for the welcome screen, its in-screen language
// selection) and we assert via `find.text` that the exact Tamil / English
// strings that used to be `isTamil ? '…' : '…'` literals now render from
// `AppLocalizations`.


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/companion_mode/saarthi_welcome_screen.dart';

Widget _welcomeHost([Locale locale = const Locale('en')]) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider(),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SaarthiWelcomeScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SaarthiWelcomeScreen renders ARB strings for the active locale', () {
    testWidgets('default (English) selection shows English step 1 labels', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_welcomeHost(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Where do you live?'), findsOneWidget);
      expect(find.text('Tamil Nadu'), findsOneWidget);
      expect(find.text('South India'), findsWidgets);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('தமிழ்நாடு'), findsNothing);
    });

    testWidgets('Tamil locale renders Tamil ARB strings', (tester) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_welcomeHost(const Locale('ta')));
      await tester.pumpAndSettle();

      expect(find.text('நீங்கள் எங்கு வசிக்கிறீர்கள்?'), findsOneWidget);
      expect(find.text('தமிழ்நாடு'), findsOneWidget);
      expect(find.text('தென் இந்தியா'), findsWidgets);
      expect(find.text('அடுத்து'), findsOneWidget);
      expect(find.text('Tamil Nadu'), findsNothing);
      expect(find.text('South India'), findsNothing);
    });
  });
}
