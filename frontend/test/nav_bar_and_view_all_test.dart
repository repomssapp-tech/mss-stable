// The floating frosted nav bar in every supported language and several phone
// widths (no overflow, active tab in the brand primary colour), and the Home
// "View all" button opening the full inbox.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/notifications_screen.dart';
import 'package:frontend/screens/regular_mode/home/home_updates_section.dart';
import 'package:frontend/utils/app_colors.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/widgets/common/app_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) =>
    ChangeNotifierProvider.value(
      value: AppProvider(),
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

Widget _bar(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return Scaffold(
    body: const SizedBox.expand(),
    bottomNavigationBar: AppBottomNavBar(
      selectedIndex: 0,
      onSelected: (_) {},
      labels: [l.navHome, l.navSearch, l.navDiscover, l.navSaved, l.navProfile],
    ),
  );
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  for (final code in ['en', 'hi', 'ta']) {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('nav bar: $code at ${width}dp, text x$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width * 2, 1600);
          tester.view.devicePixelRatio = 2.0;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          await tester.pumpWidget(
            _app(Builder(builder: _bar), locale: Locale(code)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final bar = tester.getRect(find.byType(NavigationBar));
          expect(bar.left, greaterThanOrEqualTo(0));
          expect(bar.right, lessThanOrEqualTo(width));
          expect(find.byType(NavigationDestination), findsNWidgets(5));
        });
      }
    }
  }

  testWidgets('nav bar active icon uses the primary colour', (tester) async {
    await tester.pumpWidget(_app(Builder(builder: _bar)));
    await tester.pumpAndSettle();
    final icon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
    final ctx = tester.element(find.byIcon(Icons.home_rounded));
    expect(icon.color ?? IconTheme.of(ctx).color, AppColors.primary);
  });

  for (final code in ['en', 'hi', 'ta']) {
    testWidgets('Home View all opens the full notification list ($code)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(body: HomeLatestUpdatesCard(provider: AppProvider())),
          locale: Locale(code),
        ),
      );
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(Locale(code));
      await tester.tap(find.text(l.viewAll));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
