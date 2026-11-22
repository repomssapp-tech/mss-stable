import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/widgets/legal/copyright_notice.dart';

Widget _host(Widget child, String lang) => MaterialApp(
  locale: Locale(lang),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('the copyright line is exactly as supplied by the rights holders', () {
    expect(
      mssCopyrightLine,
      '© 2026 Swadeshi Shodh Sansthan, Tamil Nadu Chapter & Rajalakshmi '
      'Institute of Technology, Chennai. All Rights Reserved.',
    );
  });

  for (final lang in ['en', 'ta', 'hi', 'mr']) {
    testWidgets('the full notice shows the line and the notice in $lang', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(Locale(lang));
      await tester.pumpWidget(_host(const CopyrightNotice.full(), lang));
      await tester.pumpAndSettle();
      expect(find.text(l10n.copyrightOwnership), findsOneWidget);
      expect(find.text(l10n.copyrightNoticeTitle), findsOneWidget);
      expect(find.text(l10n.copyrightNoticeBody), findsOneWidget);
    });
  }

  testWidgets('the line form shows only the copyright line', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_host(const CopyrightNotice.line(), 'en'));
    await tester.pumpAndSettle();
    expect(find.text(mssCopyrightLine), findsOneWidget);
    expect(find.text(l10n.copyrightNoticeBody), findsNothing);
  });

  test('Tamil and Hindi have their own translation of the notice', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    for (final lang in ['ta', 'hi']) {
      final l10n = await AppLocalizations.delegate.load(Locale(lang));
      expect(l10n.copyrightNoticeBody, isNot(en.copyrightNoticeBody));
      expect(l10n.copyrightNoticeTitle, isNot(en.copyrightNoticeTitle));
    }
  });
}
