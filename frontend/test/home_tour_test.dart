// The first-time home tour: it finds the real widgets (search bar, Saarthi
// button, Discover and Profile tabs), follows them, advances, records Finish
// and Skip per account, and holds up across languages, screen sizes and text
// scales. Uses a small stand-in page with the real bottom bar and the real
// target keys.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/onboarding/home_tour_store.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/widgets/common/app_bottom_nav_bar.dart';
import 'package:frontend/widgets/onboarding/home_tour.dart';
import 'package:frontend/widgets/onboarding/home_tour_targets.dart';
import 'package:frontend/widgets/onboarding/spotlight_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _locale = ValueNotifier<Locale>(const Locale('en'));

Widget _page() => ValueListenableBuilder<Locale>(
  valueListenable: _locale,
  builder: (context, locale, _) => MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                top: 90,
                child: Container(
                  key: HomeTourTargets.search,
                  height: 52,
                  color: Colors.white,
                  child: const Text('search'),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 120,
                child: Container(
                  key: HomeTourTargets.askSaarthi,
                  width: 150,
                  height: 56,
                  color: Colors.blue,
                  child: const Text('ask'),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            selectedIndex: 0,
            onSelected: (_) {},
            itemKeys: {2: HomeTourTargets.discover, 4: HomeTourTargets.profile},
            labels: [
              l.navHome,
              l.navSearch,
              l.navDiscover,
              l.navSaved,
              l.navProfile,
            ],
          ),
        );
      },
    ),
  ),
);

/// The rectangle the scrim leaves lit (null when nothing is highlighted).
Rect? _lit(WidgetTester tester) {
  for (final paint in tester.widgetList<CustomPaint>(
    find.descendant(
      of: find.byType(SpotlightTour),
      matching: find.byType(CustomPaint),
    ),
  )) {
    final painter = paint.painter;
    if (painter.runtimeType.toString() == '_ScrimPainter') {
      return (painter as dynamic).target as Rect?;
    }
  }
  return null;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<HomeTourStart> _start(WidgetTester tester, {String user = 'u1'}) async {
  final result = await HomeTour.maybeStart(
    tester.element(find.byType(Scaffold).first),
    userId: user,
  );
  await _settle(tester);
  return result;
}

AppLocalizations _l(String code) => lookupAppLocalizations(Locale(code));

TourLabels _plainLabels() => TourLabels(
  skip: 'Skip',
  next: 'Next',
  finish: 'Finish',
  progress: (a, b) => '$a/$b',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _locale.value = const Locale('en');
  });
  tearDown(HomeTour.dismiss);

  testWidgets('a new user sees the tour, starting on the search bar', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    expect(await _start(tester), HomeTourStart.started);
    expect(find.byType(SpotlightTour), findsOneWidget);
    expect(find.text('1 of 4'), findsOneWidget);
    expect(find.text('Find a Scheme'), findsOneWidget);
    // The lit hole is the real search bar's rectangle.
    expect(_lit(tester), tester.getRect(find.byKey(HomeTourTargets.search)));
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Next walks search -> Saarthi -> Discover -> Profile, each lit '
      'on its real widget', (tester) async {
    await tester.pumpWidget(_page());
    await _start(tester);

    Future<void> next() async {
      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
    }

    await next();
    expect(find.text('2 of 4'), findsOneWidget);
    expect(find.text('Ask Saarthi'), findsOneWidget);
    expect(
      _lit(tester),
      tester.getRect(find.byKey(HomeTourTargets.askSaarthi)),
    );

    await next();
    expect(find.text('3 of 4'), findsOneWidget);
    expect(_lit(tester), tester.getRect(find.byKey(HomeTourTargets.discover)));
    // The Discover target is the bottom bar's third item, label included.
    expect(
      find.descendant(
        of: find.byKey(HomeTourTargets.discover),
        matching: find.text('Discover'),
      ),
      findsOneWidget,
    );

    await next();
    expect(find.text('4 of 4'), findsOneWidget);
    expect(find.text('Edit Your Profile'), findsOneWidget);
    expect(_lit(tester), tester.getRect(find.byKey(HomeTourTargets.profile)));
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('the card sits above the bottom bar for the tab steps', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    await _start(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
    }
    final card = tester.getRect(
      find
          .ancestor(of: find.text('3 of 4'), matching: find.byType(Material))
          .first,
    );
    final tab = tester.getRect(find.byKey(HomeTourTargets.discover));
    expect(card.bottom, lessThanOrEqualTo(tab.top));
  });

  testWidgets('Finish closes the tour and records completion', (tester) async {
    await tester.pumpWidget(_page());
    await _start(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
    }
    await tester.tap(find.text('Finish'));
    await _settle(tester);
    expect(find.byType(SpotlightTour), findsNothing);
    expect(HomeTour.isShowing, isFalse);
    expect(
      await const HomeTourStore().outcome('u1'),
      HomeTourOutcome.completed,
    );
  });

  testWidgets('Skip closes the tour and records the dismissal', (tester) async {
    await tester.pumpWidget(_page());
    await _start(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(find.byType(SpotlightTour), findsNothing);
    expect(await const HomeTourStore().outcome('u1'), HomeTourOutcome.skipped);
  });

  testWidgets('it is not shown again to an account that has seen it, even '
      'after logging out and in or restarting', (tester) async {
    await tester.pumpWidget(_page());
    await _start(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    // "Logout, login" and "restart": the same account asks again.
    expect(await _start(tester), HomeTourStart.alreadyDone);
    expect(find.byType(SpotlightTour), findsNothing);
    // Another account on the same phone is a new user.
    expect(await _start(tester, user: 'u2'), HomeTourStart.started);
  });

  testWidgets('never two overlays at once', (tester) async {
    await tester.pumpWidget(_page());
    expect(await _start(tester), HomeTourStart.started);
    expect(await _start(tester), HomeTourStart.notApplicable);
    expect(find.byType(SpotlightTour), findsOneWidget);
  });

  testWidgets('nothing is shown without a signed-in account or before the '
      'targets are on screen', (tester) async {
    await tester.pumpWidget(_page());
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(
      await HomeTour.maybeStart(ctx, userId: ''),
      HomeTourStart.notApplicable,
    );
    // Targets missing: replace the page with an empty one.
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(
      await HomeTour.maybeStart(
        tester.element(find.byType(Scaffold)),
        userId: 'u3',
      ),
      HomeTourStart.notReady,
    );
  });

  testWidgets('the page underneath cannot be tapped while the tour is open', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              key: HomeTourTargets.search,
              onPressed: () => tapped++,
              child: const Text('under'),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(Scaffold));
    final entry = OverlayEntry(
      builder: (_) => SpotlightTour(
        stepsBuilder: (_) => [
          TourStep(
            target: HomeTourTargets.search,
            icon: Icons.search,
            title: 't',
            body: 'b',
          ),
        ],
        labelsBuilder: (_) => _plainLabels(),
        onFinish: () {},
        onSkip: () {},
      ),
    );
    Overlay.of(ctx).insert(entry);
    await _settle(tester);
    await tester.tapAt(tester.getCenter(find.text('under')));
    await tester.pump();
    expect(tapped, 0);
    entry.remove();
  });

  testWidgets('a step whose target never appears is skipped', (tester) async {
    await tester.pumpWidget(_page());
    var finished = 0;
    final entry = OverlayEntry(
      builder: (_) => SpotlightTour(
        stepsBuilder: (_) => [
          TourStep(
            target: GlobalKey(),
            icon: Icons.search,
            title: 'ghost',
            body: 'b',
          ),
        ],
        labelsBuilder: (_) => _plainLabels(),
        onFinish: () => finished++,
        onSkip: () {},
      ),
    );
    Overlay.of(tester.element(find.byType(Scaffold).first)).insert(entry);
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(finished, 1);
    entry.remove();
  });

  for (final code in ['en', 'hi', 'ta']) {
    testWidgets('text comes from the language files ($code), all four steps', (
      tester,
    ) async {
      _locale.value = Locale(code);
      await tester.pumpWidget(_page());
      await _start(tester);
      final l = _l(code);
      final titles = [
        l.homeTourFindTitle,
        l.homeTourAskTitle,
        l.homeTourDiscoverTitle,
        l.homeTourProfileTitle,
      ];
      final bodies = [
        l.homeTourFindBody,
        l.homeTourAskBody,
        l.homeTourDiscoverBody,
        l.homeTourProfileBody,
      ];
      for (var i = 0; i < 4; i++) {
        expect(find.text(l.homeTourProgress(i + 1, 4)), findsOneWidget);
        expect(find.text(titles[i]), findsWidgets);
        expect(find.text(bodies[i]), findsOneWidget);
        expect(
          find.text(i == 3 ? l.homeTourFinish : l.homeTourNext),
          findsOneWidget,
        );
        expect(find.text(l.homeTourSkip), findsOneWidget);
        if (i < 3) {
          await tester.tap(find.byType(ElevatedButton));
          await _settle(tester);
        }
      }
    });
  }

  testWidgets('changing the app language while the tour is open updates the '
      'text and keeps the step', (tester) async {
    await tester.pumpWidget(_page());
    await _start(tester);
    await tester.tap(find.byType(ElevatedButton));
    await _settle(tester);
    expect(find.text('2 of 4'), findsOneWidget);

    _locale.value = const Locale('ta');
    await tester.pump();
    await _settle(tester);
    final ta = _l('ta');
    expect(find.text(ta.homeTourProgress(2, 4)), findsOneWidget);
    expect(find.text(ta.homeTourAskTitle), findsOneWidget);
    expect(
      _lit(tester),
      tester.getRect(find.byKey(HomeTourTargets.askSaarthi)),
    );
  });

  for (final code in ['en', 'hi', 'ta']) {
    for (final size in [const Size(320, 568), const Size(412, 915)]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('no overflow, card on screen ($code, ${size.width.toInt()}'
            'x${size.height.toInt()}, text x$scale)', (tester) async {
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          _locale.value = Locale(code);
          await tester.pumpWidget(_page());
          await _start(tester);
          for (var step = 0; step < 4; step++) {
            await _settle(tester);
            final card = tester.getRect(
              find
                  .ancestor(
                    of: find.byType(ElevatedButton),
                    matching: find.byType(Material),
                  )
                  .first,
            );
            expect(card.left, greaterThanOrEqualTo(0));
            expect(card.right, lessThanOrEqualTo(size.width));
            expect(card.top, greaterThanOrEqualTo(0));
            expect(card.bottom, lessThanOrEqualTo(size.height));
            expect(tester.takeException(), isNull);
            if (step < 3) {
              await tester.tap(find.byType(ElevatedButton));
            }
          }
        });
      }
    }
  }
}
