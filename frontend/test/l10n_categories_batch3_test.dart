// Batch 3 of the custom string-map -> gen-l10n ARB migration.
//
// Execution tests: each screen is pumped under a real `MaterialApp` locale
// and we assert, via `find.text`, that the exact Tamil / English strings that
// used to live in the top-of-file `_getLocalizedCategoryOrMinistry` map and in
// inline `isTa ? ... : ...` literals now render from `AppLocalizations`
// (categories_screen.dart) / `CentralizedTranslator` (ministry & state names).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/categories_screen.dart';
import 'package:frontend/screens/regular_mode/msme_module_details_screen.dart';

// Exact values that used to be hardcoded in the two in-scope files.
const _businessMsmeEn = 'Business & MSME';
const _businessMsmeTa = 'தொழில் & MSME'; // catBusinessMsme (ARB)
const _viewAllEn = 'View All';
const _viewAllTa = 'அனைத்தையும் காண்க'; // reused viewAll key

const _mainFeaturesEn = 'Main Features Inside';
const _mainFeaturesTa = 'முதன்மை அம்சங்கள்'; // msmeMainFeaturesInside (ARB)
const _delayedCalcEn = 'Delayed Payment Interest Calculator';
const _delayedCalcTa = 'தாமதமான செலுத்துகை வட்டி கால்குலேட்டர்';

Widget _host(Locale locale, Widget screen) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: screen),
    ),
  );
}

MSMEModuleDetailsScreen _taxGstModule() => const MSMEModuleDetailsScreen(
  moduleId: 'tax_gst',
  title: 'Tax & GST',
  description: 'Tax benefits, GST support & compliance',
  icon: Icons.receipt_long,
  iconColor: Color(0xFF2563EB),
  themeColor: Color(0xFF2563EB),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('CategoriesScreen renders migrated strings for the active locale', () {
    testWidgets('Tamil locale: category label + View All from ARB', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Locale('ta'), const CategoriesScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(_businessMsmeTa), findsWidgets);
      expect(find.text(_viewAllTa), findsWidgets);
      expect(find.text(_businessMsmeEn), findsNothing);
      expect(find.text(_viewAllEn), findsNothing);
    });

    testWidgets('English locale: category label + View All from ARB', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Locale('en'), const CategoriesScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(_businessMsmeEn), findsWidgets);
      expect(find.text(_viewAllEn), findsWidgets);
      expect(find.text(_businessMsmeTa), findsNothing);
      expect(find.text(_viewAllTa), findsNothing);
    });
  });

  group('MSMEModuleDetailsScreen renders migrated strings for the locale', () {
    testWidgets('Tamil locale: headings + calculator title from ARB', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Locale('ta'), _taxGstModule()));
      await tester.pumpAndSettle();

      expect(find.text(_mainFeaturesTa), findsOneWidget);
      expect(find.text(_delayedCalcTa), findsOneWidget);
      expect(find.text(_mainFeaturesEn), findsNothing);
      expect(find.text(_delayedCalcEn), findsNothing);
    });

    testWidgets('English locale: headings + calculator title from ARB', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Locale('en'), _taxGstModule()));
      await tester.pumpAndSettle();

      expect(find.text(_mainFeaturesEn), findsOneWidget);
      expect(find.text(_delayedCalcEn), findsOneWidget);
      expect(find.text(_mainFeaturesTa), findsNothing);
      expect(find.text(_delayedCalcTa), findsNothing);
    });
  });
}
