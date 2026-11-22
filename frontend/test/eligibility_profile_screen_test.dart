import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/regular_mode/basic_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'EligibilityProfileScreen renders the final step and options, no Skip',
    (WidgetTester tester) async {
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
            home: Scaffold(body: BasicProfileScreen(initialStep: 4)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Step 4 of 4'), findsOneWidget);

      // 2. Step 4 is now mandatory -- the Skip shortcut has been removed.
      expect(find.text('Skip'), findsNothing);

      // 3. Verify Education options
      expect(find.textContaining('Undergraduate'), findsOneWidget);
      expect(find.textContaining('Diploma'), findsOneWidget);

      // 4. Verify Community options
      expect(find.textContaining('OBC'), findsOneWidget);
      expect(find.textContaining('SC'), findsOneWidget);

      // 5. Verify Complete Profile button
      expect(find.text('Complete Profile'), findsOneWidget);
    },
  );
}
