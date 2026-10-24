import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/common/app_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/search_results_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppProvider> openResults(WidgetTester tester) async {
    final provider = AppProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ta')],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SearchResultsScreen(
                      title: 'Cluster',
                      type: 'category',
                    ),
                  ),
                ),
                child: const Text('open results'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open results'));
    // Not pumpAndSettle: the results skeleton animates until data arrives.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return provider;
  }

  testWidgets('a pushed results page shows the bottom navigation bar', (
    tester,
  ) async {
    await openResults(tester);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
  });

  testWidgets('choosing a tab returns to the shell on that tab', (
    tester,
  ) async {
    final provider = await openResults(tester);
    await tester.tap(find.byType(AppNavBarItem).at(3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(provider.currentTabIndex, 3);
    expect(find.byType(AppBottomNavBar), findsNothing);
    expect(find.text('open results'), findsOneWidget);
  });
}
