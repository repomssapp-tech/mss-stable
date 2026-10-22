import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/saved_schemes_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget(AppProvider provider) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ta')],
        home: SavedSchemesScreen(),
      ),
    );
  }

  const viewedOnlyScheme = Scheme(
    id: 'viewed-only-1',
    name: 'Viewed Only Scheme',
    schemeCode: 'VIEWED-01',
    category: 'MSME',
    state: 'Tamil Nadu',
    overview: 'A scheme that was only viewed, never bookmarked.',
  );

  const secondSavedScheme = Scheme(
    id: 'saved-2',
    name: 'Second Saved Scheme',
    schemeCode: 'SAVED-02',
    category: 'MSME',
    state: 'Tamil Nadu',
    overview: 'A second scheme bookmarked for the count=2 plural case.',
  );

  group('SavedSchemesScreen - Recently viewed tab', () {
    testWidgets('tab is labelled "Recently viewed"', (tester) async {
      final provider = AppProvider();
      provider.setAllSchemesForTesting([viewedOnlyScheme]);
      provider.addToRecentlyViewed(viewedOnlyScheme.id);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Recently viewed'), findsOneWidget);
      expect(find.text('Recently Added'), findsNothing);
    });

    testWidgets('the card menu removes the item from Recently viewed and '
        'never touches bookmarks (issue #144)', (tester) async {
      final provider = AppProvider();
      provider.setAllSchemesForTesting([viewedOnlyScheme]);
      provider.addToRecentlyViewed(viewedOnlyScheme.id);
      expect(provider.bookmarkedIds, isEmpty);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Switch to the Recently viewed tab.
      await tester.tap(find.text('Recently viewed'));
      await tester.pumpAndSettle();
      expect(find.text(viewedOnlyScheme.name), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from recently viewed'));
      await tester.pumpAndSettle();

      expect(provider.recentlyViewedIds, isEmpty);
      expect(find.text(viewedOnlyScheme.name), findsNothing);
      // Removing from this tab must not create (or remove) a bookmark.
      expect(provider.bookmarkedIds, isEmpty);
    });

    testWidgets('shows its own empty-state body copy for this tab', (
      tester,
    ) async {
      final provider = AppProvider();
      provider.setAllSchemesForTesting(const []);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recently viewed'));
      await tester.pumpAndSettle();

      // This is the tab's dedicated empty-state body text (distinct from
      // the bookmark-tab wording "Bookmark schemes while browsing...").
      expect(find.text('Schemes you open appear here'), findsOneWidget);
      expect(find.text('No Schemes Viewed Yet'), findsOneWidget);
    });
  });

  group('SavedSchemesScreen - page subtitle (V1)', () {
    testWidgets('shows the empty-state copy as the subtitle when there are no '
        'bookmarks', (tester) async {
      final provider = AppProvider();
      provider.setAllSchemesForTesting(const []);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Shown twice when empty: once as the page subtitle, once as the
      // empty-state body below it -- both legitimately use this copy.
      expect(
        find.text(
          'Bookmark schemes while browsing to view them offline anytime.',
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets(
      'shows a "{n} schemes saved" count once there are bookmarks, not the '
      'empty-state copy',
      (tester) async {
        final provider = AppProvider();
        provider.setAllSchemesForTesting([viewedOnlyScheme]);
        provider.toggleBookmark(viewedOnlyScheme.id);

        await tester.pumpWidget(buildTestWidget(provider));
        await tester.pumpAndSettle();

        // savedSubtitleCountFormat is now an ICU plural (Phase 3 §Z2): count=1
        // renders the singular form, not "1 schemes saved".
        expect(find.text('1 scheme saved'), findsOneWidget);
        expect(
          find.text(
            'Bookmark schemes while browsing to view them offline anytime.',
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows "{n} schemes saved" (other branch) once there are two or more bookmarks',
      (tester) async {
        final provider = AppProvider();
        provider.setAllSchemesForTesting([viewedOnlyScheme, secondSavedScheme]);
        provider.toggleBookmark(viewedOnlyScheme.id);
        provider.toggleBookmark(secondSavedScheme.id);

        await tester.pumpWidget(buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('2 schemes saved'), findsOneWidget);
      },
    );
  });

  group(
    'SavedSchemesScreen - Recently viewed order and manage mode (#149)',
    () {
      test(
        'recently viewed lists the newest view first, not catalog order',
        () {
          final provider = AppProvider();
          provider.setAllSchemesForTesting([
            viewedOnlyScheme,
            secondSavedScheme,
          ]);
          provider.addToRecentlyViewed(viewedOnlyScheme.id);
          provider.addToRecentlyViewed(secondSavedScheme.id);

          expect(provider.recentlyViewedSchemes.map((s) => s.id), [
            secondSavedScheme.id,
            viewedOnlyScheme.id,
          ]);
        },
      );

      testWidgets('manage mode does not carry over to the other tab', (
        tester,
      ) async {
        final provider = AppProvider();
        provider.setAllSchemesForTesting([viewedOnlyScheme]);
        provider.addToRecentlyViewed(viewedOnlyScheme.id);

        await tester.pumpWidget(buildTestWidget(provider));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Recently viewed'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Manage'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Manage'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);

        await tester.tap(find.textContaining('All Saved'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Recently viewed'));
        await tester.pumpAndSettle();
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });
    },
  );
}
