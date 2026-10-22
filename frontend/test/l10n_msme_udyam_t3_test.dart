// T3 of the MSME module-details localization migration.
//
// Execution tests: the `udyam` module-details screen is pumped under a real
// `MaterialApp` locale and we assert, via `find.text`, that the Udyam
// interactive panel strings that used to be hardcoded English literals
// (panel title, "Go to Official Udyam Portal" button, step 1 title) now
// render from `AppLocalizations` for the active locale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/msme_module_details_screen.dart';

// Exact ARB values (en / ta) for the migrated Udyam panel strings.
const _flowTitleEn = 'Udyam Registration Flow';
const _flowTitleTa = 'உத்யம் (Udyam) பதிவு வழிமுறை';
const _portalBtnEn = 'Go to Official Udyam Portal';
const _portalBtnTa = 'அதிகாரப்பூர்வ உத்யம் (Udyam) போர்ட்டலுக்குச் செல்லவும்';
const _step1TitleEn = '1. Aadhaar & PAN Validation';
const _step1TitleTa = '1. ஆதார் & PAN (நிரந்தரக் கணக்கு எண்) சரிபார்ப்பு';

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

MSMEModuleDetailsScreen _udyamModule() => const MSMEModuleDetailsScreen(
  moduleId: 'udyam',
  title: 'Register UDYAM',
  description: 'Free official MSME Udyam registration',
  icon: Icons.app_registration,
  iconColor: Color(0xFF2563EB),
  themeColor: Color(0xFF2563EB),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group(
    'MSMEModuleDetailsScreen (udyam) renders migrated Udyam panel strings',
    () {
      testWidgets('Tamil locale: flow title + portal button + step 1 title', (
        tester,
      ) async {
        await tester.pumpWidget(_host(const Locale('ta'), _udyamModule()));
        await tester.pumpAndSettle();

        expect(find.text(_flowTitleTa), findsOneWidget);
        expect(find.text(_portalBtnTa), findsOneWidget);
        expect(find.text(_step1TitleTa), findsOneWidget);

        expect(find.text(_flowTitleEn), findsNothing);
        expect(find.text(_portalBtnEn), findsNothing);
        expect(find.text(_step1TitleEn), findsNothing);
      });

      testWidgets('English locale: flow title + portal button + step 1 title', (
        tester,
      ) async {
        await tester.pumpWidget(_host(const Locale('en'), _udyamModule()));
        await tester.pumpAndSettle();

        expect(find.text(_flowTitleEn), findsOneWidget);
        expect(find.text(_portalBtnEn), findsOneWidget);
        expect(find.text(_step1TitleEn), findsOneWidget);

        expect(find.text(_flowTitleTa), findsNothing);
        expect(find.text(_portalBtnTa), findsNothing);
        expect(find.text(_step1TitleTa), findsNothing);
      });
    },
  );

  group('Udyam ARB getters resolve for both locales', () {
    testWidgets('en getters', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        _host(
          const Locale('en'),
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(l10n.msmeUdyamFlowTitle, _flowTitleEn);
      expect(l10n.msmeUdyamGoToPortal, _portalBtnEn);
      expect(l10n.msmeUdyamStep1Title, _step1TitleEn);
      expect(l10n.msmeRatePerAnnum('20.25'), '20.25% p.a.');
    });

    testWidgets('ta getters', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        _host(
          const Locale('ta'),
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(l10n.msmeUdyamFlowTitle, _flowTitleTa);
      expect(l10n.msmeUdyamGoToPortal, _portalBtnTa);
      expect(l10n.msmeUdyamStep1Title, _step1TitleTa);
      expect(l10n.msmeRatePerAnnum('20.25'), '20.25% ஆண்டுக்கு');
    });
  });
}
