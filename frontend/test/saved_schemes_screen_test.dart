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

    testWidgets('has no card menu at all for an unbookmarked item, so it is '
        'structurally impossible to call toggleBookmark from this tab', (
      tester,
    ) async {
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
      // The card's overflow menu (PopupMenuButton, the only card-level
      // control whose onSelected calls toggleBookmark) is not rendered at
      // all for this tab, so there is no UI path that can call
      // provider.toggleBookmark() and accidentally create a bookmark.
      // (Icons.more_vert_rounded / delete_outline_rounded alone aren't
      // checked here -- the "Manage" banner below the list legitimately
      // reuses delete_outline_rounded for an unrelated, list-wide toggle.)
      expect(find.byType(PopupMenuButton<String>), findsNothing);

      // Confirm the bookmark set is still untouched after rendering.
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
}
