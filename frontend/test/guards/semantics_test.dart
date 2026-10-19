// spec_design_system.md §8, semantics_test.dart. Builds the same five
// NavigationDestinations lib/main.dart's MainTabsContainer passes to
// NavigationBar and asserts the currently selected one carries the
// `isSelected` semantics flag -- Material 3's NavigationBar/
// NavigationDestination provide this for free (spec §1 note: "Semantics
// (selected, 'tab n of 5') come with NavigationBar"), unlike the old
// GestureDetector-based bar this replaced in Phase 3 group 1, which had no
// selection semantics at all.
//
// This pumps a standalone NavigationBar rather than the real
// MainTabsContainer: that widget's IndexedStack mounts all five tab screens
// at once, and one of them (profile/saved) redirects to LoginScreen via
// Navigator as soon as it mounts when there is no signed-in session in the
// test harness -- an unrelated auth-gating side effect that has nothing to
// do with the nav bar's semantics and would make this test fragile against
// changes in screens group 0 has no business depending on. Not ratcheted:
// this is a widget test with a single pass/fail state, not a per-file
// violation count.
//
// `AppIconButton`'s `semanticLabel` being a required named parameter is
// enforced by the Dart compiler itself (it would fail to build this whole
// test suite otherwise), so there is nothing further to assert for that
// half of the spec's rule here.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(int selectedIndex, ValueChanged<int> onSelected) =>
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );

  testWidgets(
    'the selected bottom-nav destination carries the selected semantics flag',
    (tester) async {
      var selectedIndex = 0;
      await tester.pumpWidget(harness(selectedIndex, (i) => selectedIndex = i));

      final destinations = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(NavigationDestination),
      );
      expect(destinations, findsNWidgets(5));

      final homeSemantics = tester.getSemantics(destinations.at(0));
      // ignore: deprecated_member_use
      expect(homeSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);

      final searchSemantics = tester.getSemantics(destinations.at(1));
      // ignore: deprecated_member_use
      expect(searchSemantics.hasFlag(SemanticsFlag.isSelected), isFalse);

      await tester.tap(destinations.at(1));
      await tester.pump();
      await tester.pumpWidget(harness(selectedIndex, (i) => selectedIndex = i));

      final searchSelectedNow = tester.getSemantics(destinations.at(1));
      // ignore: deprecated_member_use
      expect(searchSelectedNow.hasFlag(SemanticsFlag.isSelected), isTrue);
    },
  );
}
