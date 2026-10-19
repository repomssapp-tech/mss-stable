// Batch 7 (T1) of the custom string-map -> gen-l10n ARB migration.
//
// help_support_screen.dart was never migrated: its whole FAQ dataset and all
// UI chrome were hardcoded English. This test pumps `HelpSupportScreen` under a
// real `MaterialApp` locale and asserts, via `find.text`, that a known FAQ
// question, the header title and a button now render from `AppLocalizations`
// in the active locale (Tamil under `ta`, English under `en`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/help_support_screen.dart';

// Exact ARB values for the strings this screen now pulls from AppLocalizations.
const _faqEligibilityEn = 'How do I check my eligibility for a scheme?';
const _faqEligibilityTa =
    'ஒரு திட்டத்திற்கான எனது தகுதியை எப்படிச் சரிபார்ப்பது?';
const _headerSupportEn = 'Help & Support';
const _headerSupportTa = 'உதவி & ஆதரவு';
const _viewAllFaqsEn = 'View all FAQs';
const _viewAllFaqsTa = 'அனைத்து FAQ-களையும் காண்க';

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

  group('HelpSupportScreen renders migrated strings for the active locale', () {
    testWidgets('Tamil locale: FAQ question + header + button from ARB', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Locale('ta'), const HelpSupportScreen(initialMode: 'both')),
      );
      await tester.pumpAndSettle();

      expect(find.text(_faqEligibilityTa), findsWidgets);
      expect(find.text(_headerSupportTa), findsOneWidget);
      expect(find.text(_viewAllFaqsTa), findsOneWidget);

      expect(find.text(_faqEligibilityEn), findsNothing);
      expect(find.text(_headerSupportEn), findsNothing);
      expect(find.text(_viewAllFaqsEn), findsNothing);
    });

    testWidgets('English locale: FAQ question + header + button from ARB', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Locale('en'), const HelpSupportScreen(initialMode: 'both')),
      );
      await tester.pumpAndSettle();

      expect(find.text(_faqEligibilityEn), findsWidgets);
      expect(find.text(_headerSupportEn), findsOneWidget);
      expect(find.text(_viewAllFaqsEn), findsOneWidget);

      expect(find.text(_faqEligibilityTa), findsNothing);
      expect(find.text(_headerSupportTa), findsNothing);
      expect(find.text(_viewAllFaqsTa), findsNothing);
    });
  });
}
