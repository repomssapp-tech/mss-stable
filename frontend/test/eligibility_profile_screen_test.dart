import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/regular_mode/eligibility_profile_screen.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  testWidgets('EligibilityProfileScreen renders 4/4 stepper, options and Skip button', (
    WidgetTester tester,
  ) async {
    final provider = AppProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ta')],
          home: Scaffold(body: EligibilityProfileScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Stepper 4/4 text
    expect(find.text('4/4 Complete'), findsOneWidget);

    // 2. Verify Skip button is present
    expect(find.text('Skip'), findsOneWidget);

    // 3. Verify Education options
    expect(find.textContaining('Undergraduate'), findsOneWidget);
    expect(find.textContaining('Diploma'), findsOneWidget);

    // 4. Verify Community options
    expect(find.textContaining('OBC'), findsOneWidget);
    expect(find.textContaining('SC'), findsOneWidget);

    // 5. Verify Complete Profile button
    expect(find.text('Complete Profile'), findsOneWidget);
  });
}
