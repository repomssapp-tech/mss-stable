import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/splash_screen.dart';
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

  const testDevices = <String, Size>{
    '320x568 (very small phone)': Size(320, 568),
    '360x640 (budget Android)': Size(360, 640),
    '390x844 (iPhone standard)': Size(390, 844),
    '412x915 (large Android)': Size(412, 915),
    '800x1280 (tablet)': Size(800, 1280),
  };

  for (final entry in testDevices.entries) {
    testWidgets('SplashScreen renders without overflow on ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(
        find.text('Please wait while we prepare\nsomething amazing for you'),
        findsOneWidget,
      );
      expect(find.text('App developed by'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
