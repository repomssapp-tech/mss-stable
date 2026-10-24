// The bottom bar must be 64dp plus the system
// gesture inset and the small float gap below the pill -- never also the status-bar height. A MediaQuery rebuilt from
// a context ABOVE the Scaffold puts the status-bar padding back, and the bar's
// SafeArea then adds it on top (it showed as ~50dp of empty white above the icons).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/widgets/common/app_bottom_nav_bar.dart';

void main() {
  const labels = ['Home', 'Search', 'Discover', 'Saved', 'Profile'];

  Future<double> barHeight(
    WidgetTester tester, {
    double topInset = 136,
    double bottomInset = 63,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = FakeViewPadding(top: topInset, bottom: bottomInset);
    tester.view.viewPadding = FakeViewPadding(
      top: topInset,
      bottom: bottomInset,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppBottomNavBar(
            selectedIndex: 0,
            onSelected: (_) {},
            labels: labels,
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(AppBottomNavBar)).height;
  }

  testWidgets('is not inflated by the status-bar padding', (tester) async {
    final h = await barHeight(tester);
    const gestureInset = 63 / 2.625;
    expect(h, closeTo(kNavBarHeight + gestureInset + kNavBarFloatGap, 1));
  });

  testWidgets('keeps its height with large text (icons only)', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final big = await barHeight(tester);
    tester.platformDispatcher.clearAllTestValues();
    final normal = await barHeight(tester);
    expect(big, normal);
  });

  testWidgets('height does not depend on the status-bar height', (
    tester,
  ) async {
    final tall = await barHeight(tester, topInset: 136);
    final none = await barHeight(tester, topInset: 0);
    expect(tall, none);
  });

  testWidgets('announces all five tabs and reports taps', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppBottomNavBar(
            selectedIndex: 0,
            onSelected: (i) => tapped = i,
            labels: labels,
          ),
        ),
      ),
    );
    // Every tab is announced with its label; the bar itself shows icons only.
    for (final l in labels) {
      expect(find.bySemanticsLabel(l), findsOneWidget);
      expect(find.text(l), findsNothing);
    }
    await tester.tap(find.byType(AppNavBarItem).at(2));
    expect(tapped, 2);
  });

  testWidgets('fits a narrow phone with Tamil labels', (tester) async {
    tester.view.physicalSize = const Size(640, 1600);
    tester.view.devicePixelRatio = 2.0; // 320dp wide
    addTearDown(tester.view.reset);
    const tamil = [
      'முகப்பு',
      'தேடல்',
      'கண்டறியுங்கள்',
      'சேமித்தவை',
      'சுயவிவரம்',
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppBottomNavBar(
            selectedIndex: 4,
            onSelected: (_) {},
            labels: tamil,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(tamil[2]), findsOneWidget);
    final bar = tester.getRect(find.byType(AppBottomNavBar));
    expect(bar.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliding a finger along the bar switches tabs on the way', (
    tester,
  ) async {
    final picked = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppBottomNavBar(
            selectedIndex: 0,
            onSelected: picked.add,
            labels: labels,
          ),
        ),
      ),
    );
    final home = tester.getCenter(find.byType(AppNavBarItem).at(0));
    final profile = tester.getCenter(find.byType(AppNavBarItem).at(4));
    final gesture = await tester.startGesture(home);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(home, profile, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    // Each tab passed under the finger is selected in order, ending on Profile.
    expect(picked, [1, 2, 3, 4]);
    expect(tester.takeException(), isNull);
  });
}
