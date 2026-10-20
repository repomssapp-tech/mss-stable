// The bottom bar must be 64dp (scaled a little for large fonts) plus the system
// gesture inset -- never also the status-bar height. A MediaQuery rebuilt from
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
    // The label-fit cap keeps the text scale within 0.75..1.15.
    expect(h, lessThanOrEqualTo(64 * 1.15 + gestureInset + 1));
    expect(h, greaterThanOrEqualTo(64 * 0.75 + gestureInset - 1));
  });

  testWidgets('height does not depend on the status-bar height', (
    tester,
  ) async {
    final tall = await barHeight(tester, topInset: 136);
    final none = await barHeight(tester, topInset: 0);
    expect(tall, none);
  });

  testWidgets('shows all five labels and reports taps', (tester) async {
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
    for (final l in labels) {
      expect(find.text(l), findsOneWidget);
    }
    await tester.tap(find.text('Discover'));
    expect(tapped, 2);
  });
}
