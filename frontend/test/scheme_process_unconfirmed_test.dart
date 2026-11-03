import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/regular_mode/scheme_details/scheme_process_section.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> pump(
    WidgetTester tester, {
    bool notice = true,
    String url = '',
    ValueChanged<String>? onOpen,
    Locale locale = const Locale('en'),
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SchemeProcessContent(
            steps: const ['Step 1: Apply'],
            showUnconfirmedNotice: notice,
            officialUrl: url,
            onOpenUrl: onOpen,
          ),
        ),
      ),
    ),
  );

  testWidgets('the notice is the last item and opens the official page', (
    tester,
  ) async {
    String? opened;
    await pump(tester, url: 'https://x.gov.in', onOpen: (u) => opened = u);
    final step = tester.getTopLeft(find.text('Step 1: Apply')).dy;
    final link = find.text(en.processUnconfirmedLink);
    expect(tester.getTopLeft(link).dy, greaterThan(step));
    await tester.tap(link);
    expect(opened, 'https://x.gov.in');
  });

  testWidgets('with no link to trust it is plain text', (tester) async {
    await pump(tester, onOpen: (_) {});
    expect(find.text(en.processUnconfirmedNoLink), findsOneWidget);
    expect(find.text(en.processUnconfirmedLink), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('schemes with confirmed details show nothing', (tester) async {
    await pump(tester, notice: false, url: 'https://x.gov.in', onOpen: (_) {});
    expect(find.text(en.processUnconfirmedLink), findsNothing);
    expect(find.text(en.processUnconfirmedNoLink), findsNothing);
  });

  testWidgets('it is in the reader language', (tester) async {
    await pump(
      tester,
      url: 'https://x.gov.in',
      onOpen: (_) {},
      locale: const Locale('ta'),
    );
    final ta = lookupAppLocalizations(const Locale('ta'));
    expect(find.text(ta.processUnconfirmedLink), findsOneWidget);
  });

  test('the catalogue flags the schemes its notes warn about', () async {
    final bundle = await MssCatalogBundle.load();
    final flagged = <String>{};
    final wrongLink = <String>{};
    for (final e in bundle.schemes) {
      final extras = MssSchemeAdapter.toScheme(e, bundle).extras;
      if (extras.hasUnconfirmedDetails) flagged.add(e.id);
      if (extras.hasWrongLink) wrongLink.add(e.id);
    }
    expect(flagged, contains('TN2026-021'));
    expect(flagged, contains('TN2026-027'));
    expect(flagged, isNot(contains('CEN2026-001')));
    expect(flagged.length, greaterThan(40));
    expect(flagged.length, lessThan(70));
    expect(wrongLink, containsAll(['TN2026-050', 'TN2026-053']));
    expect(wrongLink, isNot(contains('TN2026-021')));
  });
}
