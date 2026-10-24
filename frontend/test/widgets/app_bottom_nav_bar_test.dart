// The bottom bar must be 64dp (scaled a little for large fonts) plus the system
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
    // The label-fit cap keeps the text scale within 11/12..1.15.
    expect(
      h,
      lessThanOrEqualTo(
        64 * 1.15 + kNavBarLift + gestureInset + kNavBarFloatGap + 1,
      ),
    );
    expect(
      h,
      greaterThanOrEqualTo(
        64 * kMinNavLabelScale +
            kNavBarLift +
            gestureInset +
            kNavBarFloatGap -
            1,
      ),
    );
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
    // Every tab is announced with its label; only the active one shows it.
    for (final l in labels) {
      expect(find.bySemanticsLabel(l), findsOneWidget);
    }
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsNothing);
    await tester.tap(find.byType(AppNavBarItem).at(2));
    expect(tapped, 2);
  });

  testWidgets('a long Tamil label on a narrow phone stays at 11sp or more', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0; // 360dp wide
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
            selectedIndex: 0,
            onSelected: (_) {},
            labels: tamil,
          ),
        ),
      ),
    );
    // The active label is never below 11sp.
    final text = find.text(tamil.first);
    expect(text, findsOneWidget);
    final scaler = MediaQuery.textScalerOf(tester.element(text));
    expect(scaler.scale(12), greaterThanOrEqualTo(11 - 0.01));
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
