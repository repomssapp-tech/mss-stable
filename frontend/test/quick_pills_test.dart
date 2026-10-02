import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/widgets/common/quick_pills.dart';

void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('renders all five pills with a 48dp hit area each', (tester) async {
    await tester.pumpWidget(wrap(QuickPills(onSelected: (_) {})));

    expect(find.text('Search PMEGP'), findsOneWidget);
    expect(find.text('Search Startup India'), findsOneWidget);
    expect(find.text('Search MSME Loans'), findsOneWidget);
    expect(find.text('Search Women Entrepreneur Schemes'), findsOneWidget);
    expect(find.text('Search ASCEND Workshops'), findsOneWidget);

    final size = tester.getSize(find.byType(QuickPills));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('tapping a pill passes the query, not the label', (tester) async {
    String? selectedQuery;
    await tester.pumpWidget(wrap(QuickPills(onSelected: (q) => selectedQuery = q)));

    await tester.tap(find.text('Search Startup India'));
    await tester.pump();

    expect(selectedQuery, 'Startup');
  });

  testWidgets('renders Tamil pill labels', (tester) async {
    await tester.pumpWidget(wrap(QuickPills(onSelected: (_) {}), locale: const Locale('ta')));

    expect(find.text('ஸ்டார்ட்அப் இந்தியா தேடுக'), findsOneWidget);
  });

  testWidgets('tapping a Tamil pill passes the Tamil query', (tester) async {
    String? selectedQuery;
    await tester.pumpWidget(
      wrap(QuickPills(onSelected: (q) => selectedQuery = q), locale: const Locale('ta')),
    );

    await tester.tap(find.text('ஸ்டார்ட்அப் இந்தியா தேடுக'));
    await tester.pump();

    expect(selectedQuery, 'தொடக்க நிறுவனம்');
  });
}
