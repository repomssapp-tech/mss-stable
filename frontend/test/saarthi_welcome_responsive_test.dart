import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/companion_mode/saarthi_welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final viewports = <String, Size>{
    '320x568 (very small phone)': const Size(320, 568),
    '360x640 (budget Android)': const Size(360, 640),
    '390x844 (Realme P4 / iPhone standard)': const Size(390, 844),
    '412x915 (large Android)': const Size(412, 915),
    '800x1280 (tablet)': const Size(800, 1280),
  };

  for (final entry in viewports.entries) {
    testWidgets('SaarthiWelcomeScreen is overflow-free on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = AppProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SaarthiWelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no exceptions / RenderFlex overflows on Step 1 (State)
      expect(tester.takeException(), isNull);
      expect(find.text('Tamil Nadu'), findsOneWidget);
      expect(find.text('Maharashtra'), findsOneWidget);

      // Select Maharashtra and continue
      final mahaOption = find.text('Maharashtra');
      await tester.ensureVisible(mahaOption);
      await tester.tap(mahaOption);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final nextButton = find.text('Next');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Ensure no exceptions on Step 2 (Gender & Age)
      expect(tester.takeException(), isNull);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);

      // Select Female and adjust age
      final femaleOption = find.text('Female');
      await tester.ensureVisible(femaleOption);
      await tester.tap(femaleOption);
      await tester.pumpAndSettle();

      final plusButton = find.byIcon(Icons.add_rounded);
      await tester.ensureVisible(plusButton);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
