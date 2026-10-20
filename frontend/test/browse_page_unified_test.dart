// A browse page (Discover category / ministry / state, a home tile) is the
// Search screen itself, opened on a base set -- one interface, not two.
// And the Home search bar starts a fresh search instead of reopening the last
// results: results appear only once a query is actually run.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/search_results_screen.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/widgets/common/standard_page_header.dart';
import 'package:frontend/widgets/scheme/scheme_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Scheme _scheme(String id, String name, {String state = 'All India'}) =>
    Scheme(id: id, name: name, state: state, category: 'General');

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  final national = _scheme('N1', 'National Growth Scheme');
  final kerala = _scheme('K1', 'Kerala Local Scheme', state: 'Kerala');
  final schemes = [national, kerala];

  Widget host(AppProvider provider, Widget home, {Locale? locale}) =>
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ta'), Locale('hi')],
          home: home,
        ),
      );

  Widget browse({bool keepFilters = false, List<Scheme>? list}) =>
      SearchResultsScreen(
        title: 'Business & MSME',
        type: 'category',
        initialSchemes: list ?? schemes,
        keepFilters: keepFilters,
      );

  group('browse page is the Search interface', () {
    testWidgets('same controls, a back button and the page title', (
      tester,
    ) async {
      await tester.pumpWidget(host(AppProvider(), browse()));
      await tester.pumpAndSettle();

      // The very same strip as the Search tab: Filter / For Me / Sort.
      expect(find.byType(SearchFilterStrip), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Filter'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'For Me'), findsOneWidget);
      expect(find.textContaining('Sort'), findsOneWidget);
      // A pushed page: its own title and a back button, not the tab header.
      expect(find.byType(StandardPageHeader), findsOneWidget);
      expect(find.text('Business & MSME'), findsOneWidget);
      expect(find.byType(SearchHeaderBar), findsNothing);
      expect(find.byTooltip('Back'), findsOneWidget);
      // The list is the base set it was opened with, nothing more or less.
      expect(find.byType(SchemeCard), findsNWidgets(2));
      expect(find.text('National Growth Scheme'), findsOneWidget);
      expect(find.text('Kerala Local Scheme'), findsOneWidget);
      expect(find.text('2 schemes available'), findsOneWidget);
    });

    testWidgets('the Search tab keeps its own header and no back button', (
      tester,
    ) async {
      await tester.pumpWidget(host(AppProvider(), const SearchScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(SearchHeaderBar), findsOneWidget);
      expect(find.byType(StandardPageHeader), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('a filter the caller just set narrows the page', (
      tester,
    ) async {
      final provider = AppProvider()..updateFilter('coverage', 'nationwide');
      await tester.pumpWidget(host(provider, browse(keepFilters: true)));
      await tester.pumpAndSettle();
      expect(find.text('National Growth Scheme'), findsOneWidget);
      expect(find.text('Kerala Local Scheme'), findsNothing);
    });

    testWidgets('a filter left over from another screen is cleared', (
      tester,
    ) async {
      final provider = AppProvider()..updateFilter('coverage', 'nationwide');
      await tester.pumpWidget(host(provider, browse()));
      await tester.pumpAndSettle();
      expect(find.text('National Growth Scheme'), findsOneWidget);
      expect(find.text('Kerala Local Scheme'), findsOneWidget);
    });

    testWidgets('an empty browse page stays empty and offers a way out', (
      tester,
    ) async {
      await tester.pumpWidget(host(AppProvider(), browse(list: const [])));
      await tester.pumpAndSettle();
      // Never falls back to the whole catalog.
      expect(find.byType(SchemeCard), findsNothing);
      expect(find.text('Clear Filters & Explore Schemes'), findsOneWidget);
    });

    for (final lang in ['ta', 'hi']) {
      testWidgets('the page renders in $lang with no English chrome', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(AppProvider(), browse(), locale: Locale(lang)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SearchFilterStrip), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, 'Filter'), findsNothing);
        expect(find.widgetWithText(OutlinedButton, 'For Me'), findsNothing);
        expect(find.textContaining('Sort'), findsNothing);
        expect(find.text('2 schemes available'), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);
      });
    }
  });

  group('Home search bar', () {
    testWidgets('starts fresh: old results and filters are gone', (
      tester,
    ) async {
      final provider = AppProvider();
      final key = GlobalKey<SearchScreenState>();
      await tester.pumpWidget(host(provider, SearchScreen(key: key)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'loan');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 500));
      expect(key.currentState!.isSearching, isTrue);
      provider.updateFilter('coverage', 'nationwide');

      key.currentState!.focusFreshSearch();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SearchFilterStrip), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(provider.filters['coverage'] ?? '', isEmpty);
      expect(key.currentState!.isSearching, isFalse);
    });
  });
}
