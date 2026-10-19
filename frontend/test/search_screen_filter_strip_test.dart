import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Discover filter strip is just three controls now: Filter, For Me, Sort.
/// The old Type / Benefit Type / Ministry dropdown chips are gone.
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

  testWidgets('strip shows only Filter / For Me / Sort while searching', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(AppProvider()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'loan');
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'For Me'), findsOneWidget);
    expect(find.textContaining('Sort'), findsOneWidget);

    // The retired dropdown chips must be gone.
    expect(find.text('Type'), findsNothing);
    expect(find.text('Benefit Type'), findsNothing);
    expect(find.text('Ministry'), findsNothing);
    expect(find.text('Clear All'), findsNothing);
  });

  testWidgets('Sort menu offers exactly Relevance / Best match / A-Z', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(AppProvider()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'loan');
    await tester.pump();

    await tester.tap(find.textContaining('Sort'));
    await tester.pumpAndSettle();

    expect(find.text('Relevance'), findsWidgets);
    expect(find.text('Best match for me'), findsOneWidget);
    expect(find.text('Scheme name (A-Z)'), findsOneWidget);
    expect(find.text('Benefits: High to Low'), findsNothing);
    expect(find.textContaining('Z-A'), findsNothing);
  });
}
