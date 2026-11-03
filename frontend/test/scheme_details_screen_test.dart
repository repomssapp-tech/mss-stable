import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/regular_mode/scheme_details_screen.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Scheme Details screen has six hand-rolled tabs (no TabController).
/// The bug: the tab tap called ExpansionTileController.expand() inside the
/// setState closure, so when the target tile was not mounted (during the
/// details-load window, or after it scrolled out of the list) the throw
/// aborted setState and the tab never visibly moved. These tests lock the
/// fix: every tab responds, always, including during loading.
void main() {
  const tabs = [
    'Overview',
    'Benefits',
    'Eligibility',
    'Documents',
    'Services',
    'Process',
  ];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SchemeRepository.instance.getAllSchemes();
  });

  Widget wrap(Scheme scheme) => ChangeNotifierProvider.value(
    value: AppProvider(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ta')],
      home: SchemeDetailsScreen(scheme: scheme),
    ),
  );

  /// The tab strip renders the selected label bold and every other w500.
  void expectSelected(WidgetTester tester, String label) {
    for (final t in tabs) {
      final text = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(SchemeDetailsScreen),
              matching: find.text(t),
            )
            .first,
      );
      final weight = text.style?.fontWeight;
      if (t == label) {
        expect(weight, FontWeight.bold, reason: '"$t" tab should be selected');
      } else {
        expect(
          weight,
          isNot(FontWeight.bold),
          reason: '"$t" tab should not be selected',
        );
      }
    }
  }

  /// Invoke the tab's own onTap. The tab strip is a horizontally-scrolling
  /// Row, so later tabs sit off the visible edge -- calling the handler
  /// directly proves the state path (the bug was _activeTabIndex never
  /// updating because .expand() threw inside setState) without fighting
  /// hit-test geometry.
  Future<void> tapTab(WidgetTester tester, String label) async {
    final gd = find
        .ancestor(
          of: find.descendant(
            of: find.byType(SchemeDetailsScreen),
            matching: find.text(label),
          ),
          matching: find.byType(GestureDetector),
        )
        .first;
    tester.widget<GestureDetector>(gd).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  const richScheme = Scheme(
    id: 'TESTRICH',
    name: 'Test Rich Scheme',
    overview: 'An overview paragraph for the test scheme.',
    benefits: 'A cash subsidy of up to a lot.',
  );

  const sparseScheme = Scheme(id: 'TESTSPARSE', name: 'Sparse Scheme');

  testWidgets('every tab responds, forwards then backwards', (tester) async {
    await tester.pumpWidget(wrap(richScheme));
    await tester.pump(const Duration(seconds: 1));

    expectSelected(tester, 'Overview'); // initial

    for (final label in tabs) {
      await tapTab(tester, label);
      expectSelected(tester, label);
    }
    for (final label in tabs.reversed) {
      await tapTab(tester, label);
      expectSelected(tester, label);
    }
  });

  testWidgets('FN-01 distant section tabs scroll to their mounted targets', (
    tester,
  ) async {
    final longScheme = Scheme(
      id: 'TESTLONG',
      name: 'Long scheme',
      overview: List.filled(80, 'A long overview paragraph.').join('\n'),
      benefits: 'Benefits text',
    );
    await tester.pumpWidget(wrap(longScheme));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    final processSection = find.byWidgetPredicate(
      (widget) =>
          widget is SchemeExpandableSection &&
          widget.title == 'How to apply',
    );
    expect(processSection, findsOneWidget);
    expect(tester.getTopLeft(processSection).dy, greaterThan(600));
    await tapTab(tester, 'Process');
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(processSection).dy, inInclusiveRange(0, 500));
    await tapTab(tester, 'Overview');
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getTopLeft(find.text(longScheme.overview)).dy,
      inInclusiveRange(0, 500),
    );
  });

  testWidgets('FN-02 opening details records the scheme in viewing history', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(richScheme));
    await tester.pump(const Duration(seconds: 1));
    final provider = Provider.of<AppProvider>(
      tester.element(find.byType(SchemeDetailsScreen)),
      listen: false,
    );
    expect(provider.recentlyViewedIds, contains(richScheme.id));
  });

  testWidgets('repeated taps on one tab keep it selected', (tester) async {
    await tester.pumpWidget(wrap(richScheme));
    await tester.pump(const Duration(seconds: 1));

    for (var i = 0; i < 3; i++) {
      await tapTab(tester, 'Process');
      expectSelected(tester, 'Process');
    }
  });

  testWidgets('tabs respond during the details-loading window', (tester) async {
    await tester.pumpWidget(wrap(richScheme));
    // Do NOT wait for _loadDetails to resolve -- tap straight away.
    await tapTab(tester, 'Eligibility');
    expectSelected(tester, 'Eligibility');
    await tapTab(tester, 'Services');
    expectSelected(tester, 'Services');
  });

  testWidgets('a data-sparse scheme still lets every tab respond', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(sparseScheme));
    await tester.pump(const Duration(seconds: 1));

    for (final label in ['Documents', 'Services', 'Process', 'Overview']) {
      await tapTab(tester, label);
      expectSelected(tester, label);
    }
  });
}
