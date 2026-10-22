// #149 s1: the MSME module page has an empty app bar title, so the route must
// be named for assistive technology via a scopesRoute/namesRoute Semantics.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/msme_module_details_screen.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';

Widget _host(Locale locale, String id, String title) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MSMEModuleDetailsScreen(
        moduleId: id,
        title: title,
        description: 'Free official MSME Udyam registration',
        icon: Icons.business,
        iconColor: Colors.blue,
        themeColor: Colors.blue,
      ),
    ),
  );
}

void _collect(SemanticsNode n, List<SemanticsNode> out) {
  out.add(n);
  n.visitChildren((c) {
    _collect(c, out);
    return true;
  });
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  const cases = <(String, String)>[
    ('udyam', 'Register UDYAM'),
    ('schemes', 'Government Schemes'),
  ];

  for (final lang in ['en', 'ta']) {
    for (final (id, title) in cases) {
      testWidgets('$id [$lang] route is named, back kept, title not doubled', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(Locale(lang), id, title));
        await tester.pumpAndSettle();

        final localized = CentralizedTranslator.instance.localize(title);
        final back = AppLocalizations.of(
          tester.element(find.byType(MSMEModuleDetailsScreen)),
        )!.back;

        final nodes = <SemanticsNode>[];
        _collect(
          // ignore: deprecated_member_use
          tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!,
          nodes,
        );

        // (a) a route-naming scope carries the localized title.
        final routeNodes = nodes.where((n) {
          final d = n.getSemanticsData();
          return d.flagsCollection.namesRoute && d.label == localized;
        });
        expect(routeNodes, isNotEmpty);

        // (b) back button keeps its label.
        expect(find.bySemanticsLabel(back), findsWidgets);

        // (c) the title is exposed once as a header, and no app-bar node
        // repeats it as a separate label.
        final headers = nodes.where((n) {
          final d = n.getSemanticsData();
          return d.flagsCollection.isHeader && d.label.contains(localized);
        });
        expect(headers.length, 1);
        // The app bar region is the subtree holding the back button.
        final barNode = tester
            .getSemantics(find.bySemanticsLabel(back).first)
            .parent!;
        final barNodes = <SemanticsNode>[];
        _collect(barNode, barNodes);
        final inBar = barNodes.where(
          (n) => n.getSemanticsData().label.contains(localized),
        );
        expect(inBar, isEmpty);
        handle.dispose();
      });
    }
  }
}
