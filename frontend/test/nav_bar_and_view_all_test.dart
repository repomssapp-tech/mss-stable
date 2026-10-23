// The floating frosted nav bar in every supported language and several phone
// widths (no overflow, active tab in the brand primary colour), and the Home
// "View all" button opening the full inbox.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/notifications_screen.dart';
import 'package:frontend/services/account/sign_in_progress.dart';
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
          final bar = tester.getRect(find.byType(AppBottomNavBar));
          expect(bar.left, greaterThanOrEqualTo(0));
          expect(bar.right, lessThanOrEqualTo(width));
          expect(find.byType(AppNavBarItem), findsNWidgets(5));
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

  for (final reduced in [false, true]) {
    testWidgets('nav bar droplet slides between tabs (system animations '
        '${reduced ? 'off' : 'on'})', (tester) async {
      final idx = ValueNotifier<int>(0);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: ValueListenableBuilder<int>(
              valueListenable: idx,
              builder: (_, i, __) => AppBottomNavBar(
                selectedIndex: i,
                onSelected: (v) => idx.value = v,
                labels: const ['a', 'b', 'c', 'd', 'e'],
              ),
            ),
          ),
        ),
      );
      double dropletX() => tester
          .getTopLeft(
            find
                .ancestor(
                  of: find.descendant(
                    of: find.byType(AppBottomNavBar),
                    matching: find.byType(IgnorePointer),
                  ),
                  matching: find.byType(Positioned),
                )
                .first,
          )
          .dx;
      final start = dropletX();
      idx.value = 3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = dropletX();
      await tester.pumpAndSettle();
      final end = dropletX();
      expect(mid, greaterThan(start));
      expect(mid, lessThan(end));
    });
  }

  for (final code in ['en', 'hi', 'ta']) {
    testWidgets('login shows a loading overlay while the sign-in finishes '
        '($code)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      addTearDown(SignInProgress.instance.resetForTest);
      await tester.pumpWidget(_app(const LoginScreen(), locale: Locale(code)));
      await tester.pump(const Duration(milliseconds: 300));
      final l = await AppLocalizations.delegate.load(Locale(code));
      expect(find.text(l.loginCompletingSignIn), findsNothing);

      SignInProgress.instance.completing();
      await tester.pump();
      expect(find.text(l.loginCompletingSignIn), findsOneWidget);
      // The Google button underneath is in its loading state, not tappable.
      expect(find.text(l.loginOpeningGoogle), findsOneWidget);

      SignInProgress.instance.finish();
      await tester.pump();
      expect(find.text(l.loginCompletingSignIn), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
