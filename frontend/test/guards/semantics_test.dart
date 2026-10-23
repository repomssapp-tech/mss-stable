// spec_design_system.md §8, semantics_test.dart. Pumps the real
// AppBottomNavBar and asserts the currently selected tab carries the
// `isSelected` semantics flag (and the others do not), so screen readers hear
// which tab is active. The bar is custom (liquid-glass droplet), so each
// AppNavBarItem sets the flag itself instead of inheriting it from Material's
// NavigationBar.
//
// `AppIconButton`'s `semanticLabel` being a required named parameter is
// enforced by the Dart compiler itself (it would fail to build this whole
// test suite otherwise), so there is nothing further to assert for that
// half of the spec's rule here.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/common/app_bottom_nav_bar.dart';

void main() {
  Widget harness(int selectedIndex, ValueChanged<int> onSelected) =>
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            labels: const ['Home', 'Search', 'Discover', 'Saved', 'Profile'],
          ),
        ),
      );

  testWidgets(
    'the selected bottom-nav tab carries the selected semantics flag',
    (tester) async {
      var selectedIndex = 0;
      await tester.pumpWidget(harness(selectedIndex, (i) => selectedIndex = i));

      final items = find.byType(AppNavBarItem);
      expect(items, findsNWidgets(5));

      // ignore: deprecated_member_use
      bool selected(int i) => tester
          .getSemantics(items.at(i))
          // ignore: deprecated_member_use
          .hasFlag(SemanticsFlag.isSelected);

      expect(selected(0), isTrue);
      expect(selected(1), isFalse);

      await tester.tap(items.at(1));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
      await tester.pumpWidget(harness(selectedIndex, (i) => selectedIndex = i));
      await tester.pumpAndSettle();

      expect(selected(1), isTrue);
      expect(selected(0), isFalse);
    },
  );
}
