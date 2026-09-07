// T5 of the custom string-map -> gen-l10n ARB migration.
//
// Covers the "remaining hardcoded English" sweep across:
//   - basic_profile_screen.dart  (profileErr* / profileHint* validation + hints)
//   - settings_screen.dart       (nav-mode dialog body, mode-switch toasts,
//                                 app-version label)
//   - beta_gate_screen.dart      (betaGate* -- previously zero localization)
//   - login_screen.dart          (loginGoogleSignInFailed)
//   - custom_confirm_dialog.dart (dialogConfirm default)
//   - catalog_freshness_footer.dart (monthAbbrList)
//   - floating_logo.dart / anti_gravity_hero_section.dart (discoverEveryScheme)
//
// (i)  getter-level assertions: each representative new key is non-empty and
//      ta != en, loaded straight from the generated delegate.
// (ii) BetaGateScreen pumped under a real MaterialApp locale (en / ta) inside
//      a ChangeNotifierProvider<AppProvider>; assert the localized title and
//      CTA render per locale. Pattern mirrors test/l10n_categories_batch3_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/features/beta_gate/beta_gate_screen.dart';
import 'package:frontend/features/beta_gate/beta_gate_service.dart';

class _FakeBetaGateService extends BetaGateService {
  @override
  Future<bool> verifyPassword(String userInput) async => false;
}

Widget _host(Locale locale, Widget screen) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-publishable-key',
      );
    } catch (_) {}
  });

  group('T5 new keys: non-empty and ta != en', () {
    late AppLocalizations en;
    late AppLocalizations ta;

    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      ta = await AppLocalizations.delegate.load(const Locale('ta'));
    });

    test('representative keys across every T5 namespace differ by locale', () {
      final pairs = <String, List<String>>{
        // basic_profile_screen.dart
        'profileHintSelectDob': [en.profileHintSelectDob, ta.profileHintSelectDob],
        'profileErrEnterPhone': [en.profileErrEnterPhone, ta.profileErrEnterPhone],
        'profileErrCompleteFieldsCorrectly': [
          en.profileErrCompleteFieldsCorrectly,
          ta.profileErrCompleteFieldsCorrectly,
        ],
        'profileErrSelectIncome': [
          en.profileErrSelectIncome,
          ta.profileErrSelectIncome,
        ],
        'profileHintCityExample': [
          en.profileHintCityExample,
          ta.profileHintCityExample,
        ],
        // settings_screen.dart
        'settingsNavModeDialogBody': [
          en.settingsNavModeDialogBody,
          ta.settingsNavModeDialogBody,
        ],
        'settingsSwitchedToRegular': [
          en.settingsSwitchedToRegular,
          ta.settingsSwitchedToRegular,
        ],
        // beta_gate_screen.dart
        'betaGateAccess': [en.betaGateAccess, ta.betaGateAccess],
        'betaGateVerifyAndEnter': [
          en.betaGateVerifyAndEnter,
          ta.betaGateVerifyAndEnter,
        ],
        'betaGateEnterPassword': [
          en.betaGateEnterPassword,
          ta.betaGateEnterPassword,
        ],
        // login_screen.dart
        'loginGoogleSignInFailed': [
          en.loginGoogleSignInFailed,
          ta.loginGoogleSignInFailed,
        ],
        // custom_confirm_dialog.dart
        'dialogConfirm': [en.dialogConfirm, ta.dialogConfirm],
        // catalog_freshness_footer.dart
        'monthAbbrList': [en.monthAbbrList, ta.monthAbbrList],
        // floating_logo.dart / anti_gravity_hero_section.dart
        'discoverEveryScheme': [
          en.discoverEveryScheme,
          ta.discoverEveryScheme,
        ],
      };

      pairs.forEach((key, values) {
        final enVal = values[0];
        final taVal = values[1];
        expect(enVal.trim(), isNotEmpty, reason: '$key (en) must be non-empty');
        expect(taVal.trim(), isNotEmpty, reason: '$key (ta) must be non-empty');
        expect(taVal, isNot(equals(enVal)),
            reason: '$key ta must be a real translation, not the en string');
      });
    });

    test('settingsAppVersion interpolates the version placeholder', () {
      expect(en.settingsAppVersion('1.2.0'), contains('1.2.0'));
      expect(ta.settingsAppVersion('1.2.0'), contains('1.2.0'));
      expect(ta.settingsAppVersion('1.2.0'),
          isNot(equals(en.settingsAppVersion('1.2.0'))));
    });

    test('monthAbbrList has exactly 12 entries in both locales', () {
      expect(en.monthAbbrList.split(','), hasLength(12));
      expect(ta.monthAbbrList.split(','), hasLength(12));
    });
  });

  group('BetaGateScreen renders localized strings for the active locale', () {
    testWidgets('English locale shows the English title + CTA', (tester) async {
      await tester.pumpWidget(
        _host(const Locale('en'), BetaGateScreen(service: _FakeBetaGateService())),
      );
      await tester.pump();

      expect(find.text('Beta Access'), findsOneWidget);
      expect(find.text('Verify & Enter'), findsOneWidget);
    });

    testWidgets('Tamil locale shows the Tamil title + CTA', (tester) async {
      final ta = await AppLocalizations.delegate.load(const Locale('ta'));

      await tester.pumpWidget(
        _host(const Locale('ta'), BetaGateScreen(service: _FakeBetaGateService())),
      );
      await tester.pump();

      expect(find.text(ta.betaGateAccess), findsOneWidget);
      expect(find.text(ta.betaGateVerifyAndEnter), findsOneWidget);
      expect(find.text('Beta Access'), findsNothing);
      expect(find.text('Verify & Enter'), findsNothing);
    });
  });
}
