import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/companion_mode/saarthi_welcome_screen.dart';
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
    testWidgets('SaarthiWelcomeScreen is overflow-free on ${entry.key}',
        (tester) async {
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

      // Ensure no exceptions / RenderFlex overflows
      expect(tester.takeException(), isNull);

      // Verify voice options exist and are selectable
      final clearOption = find.text('Clear');
      await tester.ensureVisible(clearOption);
      await tester.tap(clearOption);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Tamil
      final tamilCard = find.text('தமிழ்');
      await tester.ensureVisible(tamilCard);
      await tester.tap(tamilCard);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify Tamil voice options
      expect(find.text('குரல்'), findsOneWidget);
      expect(find.text('இயற்கையான ஒலி'), findsOneWidget);
      expect(find.text('தெளிவான ஒலி'), findsOneWidget);

      // Tap Natural voice in Tamil
      final naturalOption = find.text('இயற்கையான ஒலி');
      await tester.ensureVisible(naturalOption);
      await tester.tap(naturalOption);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
