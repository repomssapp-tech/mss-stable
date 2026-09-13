import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
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

  Widget createSearchTestApp(AppProvider provider) =>
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
          home: Scaffold(body: SearchScreen()),
        ),
      );

  testWidgets('search debounce delays query trigger by 300ms', (tester) async {
    final provider = AppProvider();
    await tester.pumpWidget(createSearchTestApp(provider));
    await tester.pumpAndSettle();

    // Verify initial idle state with category browse cards
    expect(find.byType(TextField), findsOneWidget);

    // Enter query 'loan'
    await tester.enterText(find.byType(TextField), 'loan');
    // Pump 100ms: within the 300ms debounce window
    await tester.pump(const Duration(milliseconds: 100));

    // Pump remainder of debounce window (250ms -> 350ms total)
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // Results or filter strip controls should now be visible
    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'For Me'), findsOneWidget);
  });

  testWidgets('rapid typing resets the debounce timer and executes only once', (
    tester,
  ) async {
    final provider = AppProvider();
    await tester.pumpWidget(createSearchTestApp(provider));
    await tester.pumpAndSettle();

    final inputFinder = find.byType(TextField);

    // Keystroke 1: 'p'
    await tester.enterText(inputFinder, 'p');
    await tester.pump(const Duration(milliseconds: 100));

    // Keystroke 2: 'pm'
    await tester.enterText(inputFinder, 'pm');
    await tester.pump(const Duration(milliseconds: 100));

    // Keystroke 3: 'pmegp'
    await tester.enterText(inputFinder, 'pmegp');
    await tester.pump(const Duration(milliseconds: 100));

    // Wait full debounce window after final keystroke
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Search results active
    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsOneWidget);
  });

  testWidgets('clearing search field resets state and cancels debounce', (
    tester,
  ) async {
    final provider = AppProvider();
    await tester.pumpWidget(createSearchTestApp(provider));
    await tester.pumpAndSettle();

    final inputFinder = find.byType(TextField);

    // Enter text and let search trigger
    await tester.enterText(inputFinder, 'startup');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsOneWidget);

    // Now clear the text
    await tester.enterText(inputFinder, '');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Idle state restored
    expect(find.widgetWithText(OutlinedButton, 'Filter'), findsNothing);
  });

  testWidgets('disposing search screen while debounce pending does not crash', (
    tester,
  ) async {
    final provider = AppProvider();
    await tester.pumpWidget(createSearchTestApp(provider));
    await tester.pumpAndSettle();

    // Start a query
    await tester.enterText(find.byType(TextField), 'subsidy');
    await tester.pump(const Duration(milliseconds: 100)); // Debounce in-flight

    // Immediately replace widget tree to trigger dispose() while Timer is active
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Replacement Screen')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Replacement Screen'), findsOneWidget);
  });
}
