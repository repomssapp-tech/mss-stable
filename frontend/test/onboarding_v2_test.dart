// First-launch onboarding (v2 design): four pages in every language and
// common phone widths without overflow; Skip jumps to the last page; Get
// Started finishes; the [bracketed] title word is the highlighted run.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/design_v2/highlight_text.dart';
import 'package:frontend/design_v2/onboarding/onboarding_screen.dart';
import 'package:frontend/l10n/app_localizations.dart';

Widget _app(Widget home, Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  test('bracketed words are the highlighted runs', () {
    expect(HighlightText.runs('Made [Simple]'), [
      ('Made ', false),
      ('Simple', true),
    ]);
    expect(HighlightText.runs('[சாரதியிடம்] கேளுங்கள்'), [
      ('சாரதியிடம்', true),
      (' கேளுங்கள்', false),
    ]);
    expect(HighlightText.runs('plain'), [('plain', false)]);
  });

  for (final code in ['en', 'ta', 'hi']) {
    for (final width in [360.0, 412.0]) {
      testWidgets('onboarding $code at ${width}dp: 4 pages, no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width * 2, width * 2 * 2.1);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        var done = 0;
        await tester.pumpWidget(
          _app(OnboardingScreen(onDone: () => done++), Locale(code)),
        );
        await tester.pump();
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        final pages = tester.widget<PageView>(find.byType(PageView));
        for (var i = 0; i < 4; i++) {
          pages.controller!.jumpToPage(i);
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'page $i');
        }
        expect(find.text(l10n.onbGetStarted), findsOneWidget);
        await tester.tap(find.text(l10n.onbGetStarted));
        expect(done, 1);
      });
    }
  }

  testWidgets('Skip goes to the last page', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(OnboardingScreen(onDone: () {}), const Locale('en')),
    );
    await tester.pump();
    await tester.tap(find.text('Skip').first);
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
  });
}
