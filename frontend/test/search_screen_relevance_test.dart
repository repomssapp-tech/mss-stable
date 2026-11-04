import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen-level checks that "For Me" is an opt-in filter chip in the results
/// strip, not an automatic behaviour. The ranking / lookup / no-result
/// behaviour of regular search itself is covered at the engine level by
/// search_result_engine_test.dart.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(AppProvider provider) => ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('ta')],
      home: Scaffold(body: SearchScreen()),
    ),
  );

  testWidgets('the results filter strip carries an opt-in "For Me" chip', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(AppProvider()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'loan');
    await tester.pump();

    // The chip is an OutlinedButton in the Discover filter strip (distinct
    // from the idle-screen "For Me" highlight card, a GestureDetector).
    final chip = find.widgetWithText(OutlinedButton, 'For me');
    expect(chip, findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsOneWidget);

    // It is inert until tapped -- regular search is not profile-filtered,
    // so the results header must not be the "Eligible Schemes For You" one.
    expect(find.textContaining('Eligible Schemes For You'), findsNothing);

    // Tapping it is a plain toggle (no crash, chip stays put).
    await tester.tap(chip);
    await tester.pump();
    expect(find.widgetWithText(OutlinedButton, 'For me'), findsOneWidget);
  });
}
