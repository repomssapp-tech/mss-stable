import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/msme_module_details_screen.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/utils/app_size.dart';

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

  for (final lang in ['en', 'ta', 'hi']) {
    for (final (id, title) in cases) {
      testWidgets('$id [$lang] route is named, back kept, title not doubled', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(Locale(lang), id, title));
        await tester.pumpAndSettle();

        final localized = CentralizedTranslator.instance.localizeFor(
          lang,
          title,
        );
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

        final titleText = find.text(localized);
        expect(titleText, findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: titleText),
          findsOneWidget,
        );
        final icon = find.byIcon(Icons.business);
        expect(icon, findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: icon),
          findsOneWidget,
        );
        final backButton = find.byTooltip(back);
        expect(
          tester.getSize(backButton).width,
          greaterThanOrEqualTo(AppSize.tapTarget),
        );
        expect(
          tester.getCenter(icon).dy,
          closeTo(tester.getCenter(backButton).dy, 1),
        );
        final subtitle = find.text(
          CentralizedTranslator.instance.localizeFor(
            lang,
            'Free official MSME Udyam registration',
          ),
        );
        expect(subtitle, findsOneWidget);
        expect(
          tester.getTopLeft(subtitle).dy,
          greaterThan(tester.getBottomLeft(find.byType(AppBar)).dy),
        );
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }
  }
}
