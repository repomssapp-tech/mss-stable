// T2 of the categories_screen.dart string-map -> gen-l10n ARB migration.
//
// Covers the "Business Utilities & Tools" bottom-sheet calculators
// (EMI / DPIIT / Valuation / Doc Checklist / Subsidy) that previously had
// zero localization. We assert the new `AppLocalizations` getters resolve to
// the correct English / Tamil values, and that `CategoriesScreen` still
// builds under both locales after the migration.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/l10n/app_localizations_en.dart';
import 'package:frontend/l10n/app_localizations_ta.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/categories_screen.dart';

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

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  final en = AppLocalizationsEn();
  final ta = AppLocalizationsTa();

  group('Calculator ARB getters resolve for en/ta', () {
    test('EMI calculator', () {
      expect(en.emiCalcTitle, 'Business Loan EMI Calculator');
      expect(ta.emiCalcTitle, 'தொழில் கடன் இஎம்ஐ கால்குலேட்டர்');
      expect(en.emiCalculate, 'Calculate EMI');
      expect(ta.emiCalculate, 'இஎம்ஐ கணக்கிடுங்கள்');
      expect(en.emiTenureSuffixMo, 'Mo');
      expect(ta.emiTenureSuffixMo, 'மா');
      expect(en.emiInvalidInputs, 'Please enter valid inputs');
    });

    test('DPIIT checklist', () {
      expect(en.dpiitTitle, 'DPIIT Recognition Checklist');
      expect(ta.dpiitTitle, 'டிபிஐஐடி அங்கீகார சரிபார்ப்புப் பட்டியல்');
      expect(en.dpiitCheckEligibility, 'Check Eligibility');
      expect(ta.dpiitCheckEligibility, 'தகுதியைச் சரிபார்க்கவும்');
    });

    test('Valuation estimator', () {
      expect(en.valuationTitle, 'Startup Valuation Estimator');
      expect(ta.valuationTitle, 'ஸ்டார்ட்அப் மதிப்பீட்டு கணிப்பான்');
      expect(en.valuationCroreFmt('1.50'), '₹ 1.50 Crores');
      expect(ta.valuationCroreFmt('1.50'), '₹ 1.50 கோடி');
      expect(en.valuationLakhFmt('9.0'), '₹ 9.0 Lakhs');
      expect(ta.valuationLakhFmt('9.0'), '₹ 9.0 லட்சம்');
    });

    test('Document checklist', () {
      expect(en.docChecklistTitle, 'Setup Document Checklist');
      expect(ta.docChecklistTitle, 'அமைப்பு ஆவணப் பட்டியல்');
      expect(en.docItemDsc, 'Digital Signature Certificate (DSC)');
      expect(ta.docItemDsc, 'மின்னணு கையொப்பச் சான்றிதழ் (டிஎஸ்சி)');
      expect(en.docCloseChecklist, 'Close Checklist');
    });

    test('Subsidy estimator', () {
      expect(en.subsidyTitle, 'Business Subsidy Estimator');
      expect(ta.subsidyTitle, 'தொழில் மானிய கணிப்பான்');
      expect(en.subsidyExpectedLabel('15.0'), 'Expected Subsidy (15.0%)');
      expect(
        ta.subsidyExpectedLabel('15.0'),
        'எதிர்பார்க்கப்படும் மானியம் (15.0%)',
      );
      expect(en.subsidyLakhFmt('25.00'), '₹ 25.00 Lakhs');
      expect(ta.subsidyLakhFmt('25.00'), '₹ 25.00 லட்சம்');
    });

    test('Close tooltip reuses existing key', () {
      expect(en.close, 'Close');
      expect(ta.close, 'மூடு');
    });
  });

  group('CategoriesScreen still builds after calculator migration', () {
    testWidgets('Tamil locale builds without exceptions', (tester) async {
      await tester.pumpWidget(
        _host(const Locale('ta'), const CategoriesScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('English locale builds without exceptions', (tester) async {
      await tester.pumpWidget(
        _host(const Locale('en'), const CategoriesScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
