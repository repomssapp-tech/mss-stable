import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
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

  testWidgets('SearchScreen removes top right filter icon and shows Discover filter strip when searching', (
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
          home: Scaffold(body: SearchScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Top Right filter icon is removed
    expect(find.byIcon(Icons.filter_alt_outlined), findsNothing);

    // 2. In Idle state, Try banner is visible
    expect(find.byType(TextField), findsOneWidget);

    // 3. Enter search query "food"
    await tester.enterText(find.byType(TextField), 'food');
    await tester.pump();

    // 4. Verify Discover Filters Strip is rendered
    expect(find.text('Filter'), findsOneWidget);
    expect(find.textContaining('Sort'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Benefit Type'), findsOneWidget);
    expect(find.textContaining('Ministry'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
  });

  testWidgets('SearchScreen filter chip popup menus do NOT contain "All"', (
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
          home: Scaffold(body: SearchScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Trigger filter strip by focusing or searching
    await tester.enterText(find.byType(TextField), 'loan');
    await tester.pump();

    // Tap "Type" chip to open menu
    await tester.tap(find.text('Type'));
    await tester.pumpAndSettle();

    // Verify popup items
    expect(find.text('Loan'), findsWidgets);
    expect(find.text('Subsidy'), findsOneWidget);
    expect(find.text('Scholarship'), findsOneWidget);
    expect(find.text('Pension'), findsOneWidget);
    expect(find.text('All'), findsNothing,
        reason: 'Filter chip popup menu must not contain "All"');

    // Select "Loan"
    await tester.tap(find.text('Loan').last);
    await tester.pumpAndSettle();

    // Never show 'No schemes found for "All"'
    expect(find.textContaining('"All"'), findsNothing);
  });
}
