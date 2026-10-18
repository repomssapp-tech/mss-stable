// Renders the main non-scheme screens in Hindi and Tamil and checks that every
// visible string containing English words is on the reviewed allowlist
// (test/fixtures/ui_audit_allowlist.json): acronyms, programme and institution
// names, and similar. A new hardcoded English string on any of these screens
// fails this test.
//
// To print a report for one language instead (and skip the allowlist check):
//   flutter test test/hindi_ui_audit_test.dart --dart-define=AUDIT_LANG=hi
// The report also goes to a JSON file when AUDIT_OUT is set.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/regular_mode/categories/document_checklist_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/dpiit_checklist_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/emi_calculator_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/gst_calculator_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/subsidy_estimator_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/udyam_classifier_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/valuation_estimator_sheet.dart';
import 'package:frontend/utils/permission_helper.dart';
import 'package:frontend/widgets/legal/data_processing_consent_modal.dart';
import 'package:frontend/widgets/legal/legal_document_modal.dart';
import 'package:frontend/widgets/scheme/filter_panel.dart';
import 'package:frontend/screens/navigation_mode_screen.dart';
import 'package:frontend/screens/companion_mode/saarthi_welcome_screen.dart';
import 'package:frontend/screens/companion_mode/saarthi_home_screen.dart';
import 'package:frontend/screens/notifications_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/regular_mode/about_you_profile_screen.dart';
import 'package:frontend/screens/regular_mode/basic_profile_screen.dart';
import 'package:frontend/screens/regular_mode/categories_screen.dart';
import 'package:frontend/screens/regular_mode/eligibility_profile_screen.dart';
import 'package:frontend/screens/regular_mode/eligibility_results_screen.dart';
import 'package:frontend/screens/regular_mode/help_support_screen.dart';
import 'package:frontend/screens/regular_mode/home_screen.dart';
import 'package:frontend/screens/regular_mode/language_selection_screen.dart';
import 'package:frontend/screens/regular_mode/legal_screens.dart';
import 'package:frontend/screens/regular_mode/location_profile_screen.dart';
import 'package:frontend/screens/regular_mode/msme_module_details_screen.dart';
import 'package:frontend/screens/regular_mode/saved_schemes_screen.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/screens/regular_mode/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _langEnv = String.fromEnvironment('AUDIT_LANG');
const _full = bool.fromEnvironment('AUDIT_FULL');
final _langs = _langEnv.isEmpty ? ['hi', 'ta'] : [_langEnv];
const _out = String.fromEnvironment('AUDIT_OUT');

// Acronyms, product and brand names that legitimately stay in Latin script.
const _allowed = <String>{
  'MSME',
  'MSMES',
  'MSMED',
  'GST',
  'CGST',
  'SGST',
  'IGST',
  'PAN',
  'SIDBI',
  'NSIC',
  'DIC',
  'KVIC',
  'DGFT',
  'TREDS',
  'IEC',
  'RCMC',
  'EMI',
  'OTP',
  'SMS',
  'MSS',
  'GOOGLE',
  'UDYAM',
  'DPIIT',
  'MRR',
  'ARR',
  'KYC',
  'CSR',
  'PMEGP',
  'CGTMSE',
  'SFURTI',
  'MSEFC',
  'NBFC',
  'RXIL',
  'PDF',
  'FAQ',
  'OBC',
  'EWS',
  'LLP',
  'OPC',
  'PIN',
  'ID',
  'EN',
  'AI',
  'APP',
  'SAARTHI',
  'CST',
};

final _latinWord = RegExp(r'[A-Za-z]{3,}');
final _urlOrEmail = RegExp(r'(https?://\S+|\S+@\S+|\S+\.(gov|org|in|com)\S*)');

bool _hasEnglish(String s) {
  final cleaned = s.replaceAll(_urlOrEmail, ' ');
  return _latinWord
      .allMatches(cleaned)
      .any((m) => !_allowed.contains(m.group(0)!.toUpperCase()));
}

void main() {
  final report = <String, List<String>>{};

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Hindi is active in the shipped release; mirror that so the language
    // picker previews Hindi like it does in the app.
    LanguagePackManager.instance.isLanguageActiveOverride = (_) => true;
    LanguagePackManager.instance.hasValidPackOverride = (_) => true;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  Future<void> audit(
    WidgetTester tester,
    String lang,
    String name,
    Widget Function() build, {
    Future<void> Function(WidgetTester)? afterBuild,
    _Variant variant = _Variant.reference,
  }) async {
    tester.view.physicalSize = variant.physicalSize;
    tester.view.devicePixelRatio = variant.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final layoutErrors = <String>{};
    try {
      final provider = AppProvider()..setLoggedInForTesting(true);
      Widget tree() => ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(variant.textScale)),
            child: child!,
          ),
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: build()),
        ),
      );
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString().replaceAll(RegExp(r'\s+'), ' ');
        if (_full) {
          // Which widget overflowed: the creator chain from the diagnostics.
          final info = details.informationCollector?.call() ?? const [];
          final chain = info
              .map((n) => n.toString())
              .join(' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          final creator = RegExp(
            r'creator: ([^)]{0,260})',
          ).firstMatch(details.toString().replaceAll(RegExp(r'\s+'), ' '));
          layoutErrors.add(
            '$msg | ${creator?.group(1) ?? chain}'.substring(
              0,
              ('$msg | ${creator?.group(1) ?? chain}').length.clamp(0, 520),
            ),
          );
          return;
        }
        layoutErrors.add(msg.length > 140 ? msg.substring(0, 140) : msg);
      };
      provider.changeLanguage(lang);
      await tester.pumpWidget(tree());
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      // A fresh provider restores its cached state asynchronously and resets
      // the language. Re-apply it, then rebuild the screen from scratch the
      // way a real language switch does (the locale change rebuilds the tree).
      provider.changeLanguage(lang);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(tree());
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      if (afterBuild != null) {
        await afterBuild(tester);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
      final seen = <String>{};
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final s = (t.data ?? t.textSpan?.toPlainText() ?? '').trim();
        if (s == 'open') continue;
        if (s.isNotEmpty && _hasEnglish(s)) seen.add(s);
      }
      for (final d in tester.widgetList<InputDecorator>(
        find.byType(InputDecorator),
      )) {
        for (final s in [
          d.decoration.hintText,
          d.decoration.labelText,
          d.decoration.helperText,
          d.decoration.errorText,
        ]) {
          if (s != null && s.trim().isNotEmpty && _hasEnglish(s)) {
            seen.add('[field] ${s.trim()}');
          }
        }
      }
      FlutterError.onError = previousOnError;
      tester.takeException();
      for (final e in layoutErrors) {
        seen.add('!! layout error: $e');
      }
      // Other phone sizes only check layout; the English audit runs once.
      final keep = variant == _Variant.reference
          ? seen
          : seen
                .where(
                  (s) =>
                      s.startsWith('!!') && !s.contains('ListTile background'),
                )
                .toSet();
      report['$lang${variant.tag}: $name'] = keep.toList()..sort();
    } catch (e, st) {
      FlutterError.onError = FlutterError.presentError;
      report['$lang${variant.tag}: $name'] = [
        for (final err in layoutErrors) '!! layout error: $err',
        '!! could not render: ${e.toString().split("\n").first}${_full ? ' @ ${st.toString().split("\n").take(5).join(" | ")}' : ''}',
      ];
    }
  }

  final screens = <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'Categories': () => const CategoriesScreen(),
    'Search': () => const SearchScreen(),
    'Saved': () => const SavedSchemesScreen(),
    'Profile': () => const ProfileScreen(),
    'Settings': () => const SettingsScreen(),
    'Notifications': () => const NotificationsScreen(),
    'HelpSupport': () => const HelpSupportScreen(),
    'AboutYou': () => const AboutYouProfileScreen(),
    'EligibilityProfile': () => const EligibilityProfileScreen(),
    'EligibilityResults': () => const EligibilityResultsScreen(),
    'LocationProfile': () => const LocationProfileScreen(),
    'LanguageSelection': () => const LanguageSelectionScreen(),
    'Login': () => const LoginScreen(),
    'NavigationMode': () => const NavigationModeScreen(),
    'PrivacyPolicy': () => const PrivacyPolicyScreen(),
    'Terms': () => const TermsConditionsScreen(),
    'Companion welcome': () => const SaarthiWelcomeScreen(),
    'Companion home': () => const SaarthiHomeScreen(),
    for (var step = 1; step <= 4; step++)
      'BasicProfile step $step': () => BasicProfileScreen(initialStep: step),
    for (final m in const [
      'schemes',
      'finance',
      'tax_gst',
      'export',
      'treds',
      'csr',
      'govt',
      'institutions',
      'udyam',
    ])
      'MSME module $m': () => MSMEModuleDetailsScreen(
        moduleId: m,
        title: m,
        description: m,
        icon: Icons.business,
        iconColor: Colors.blue,
        themeColor: Colors.blue,
      ),
  };

  final overlays = <String, void Function(BuildContext)>{
    'About dialog': showAboutAppDialog,
    'Location services dialog': showLocationServiceOffDialog,
    'Report issue sheet': showReportIssueBottomSheet,
    'Feedback sheet': showFeedbackBottomSheet,
    'All FAQs sheet': showAllFAQsBottomSheet,
    'Document checklist sheet': showDocumentChecklistSheet,
    'DPIIT sheet': showDpiitChecklistSheet,
    'EMI sheet': showEmiCalculatorSheet,
    'GST sheet': showGstCalculatorSheet,
    'Subsidy sheet': showSubsidyEstimatorSheet,
    'Udyam sheet': showUdyamClassifierSheet,
    'Valuation sheet': showValuationEstimatorSheet,
    'Terms modal': LegalDocumentModal.showTermsOfUse,
    'Privacy notice modal': LegalDocumentModal.showPrivacyNotice,
    'Privacy policy modal': LegalDocumentModal.showPrivacyPolicy,
    'Consent modal': DataProcessingConsentModal.show,
    'Filter panel': (c) => showModalBottomSheet<void>(
      context: c,
      isScrollControlled: true,
      builder: (_) => const FilterPanel(),
    ),
  };

  for (final variant in _Variant.values) {
    for (final lang in _langs) {
      for (final entry in overlays.entries) {
        testWidgets('audit overlay ${entry.key} ($lang${variant.tag})', (
          tester,
        ) async {
          await audit(
            tester,
            lang,
            'OVERLAY ${entry.key}',
            () => Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => entry.value(ctx),
                  child: const Text('open'),
                ),
              ),
            ),
            afterBuild: (t) async {
              await t.tap(find.byType(ElevatedButton));
            },
            variant: variant,
          );
        });
      }

      for (final entry in screens.entries) {
        testWidgets('audit ${entry.key} ($lang${variant.tag})', (tester) async {
          await audit(tester, lang, entry.key, entry.value, variant: variant);
        });
      }
    }
  }

  if (_langEnv.isEmpty) {
    test('no overflow or render errors on small and large phones', () {
      final problems = <String>[];
      report.forEach((key, items) {
        if (!key.contains('@')) return;
        for (final s in items) {
          problems.add('$key -> $s');
        }
      });
      expect(
        problems,
        isEmpty,
        reason:
            'Layout must adapt to the screen: no overflow at 360dp wide '
            'with 1.3x text, or on a wide display.',
      );
    });

    test('no English outside the reviewed allowlist', () {
      final allow =
          jsonDecode(
                File(
                  'test/fixtures/ui_audit_allowlist.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final problems = <String>[];
      report.forEach((key, items) {
        if (key.contains('@')) return; // other phone sizes: layout only
        final lang = key.split(':').first;
        final allowed = ((allow[lang] ?? const []) as List)
            .cast<String>()
            .toSet();
        for (final s in items) {
          if (!allowed.contains(s)) problems.add('$key -> $s');
        }
      });
      expect(
        problems,
        isEmpty,
        reason:
            'English text found that is not on the allowlist. Translate it '
            '(ARB or translation dictionary); if it is a name/acronym that '
            'should stay Latin, add it to test/fixtures/ui_audit_allowlist.json.',
      );
    });
  }

  tearDownAll(() {
    LanguagePackManager.instance.isLanguageActiveOverride = null;
    LanguagePackManager.instance.hasValidPackOverride = null;
    final b = StringBuffer(
      '\n===== ENGLISH LEFT IN ${_langs.join('+')} =====\n',
    );
    var total = 0;
    report.forEach((screen, items) {
      b.writeln('## $screen (${items.length})');
      for (final s in items) {
        b.writeln('   $s');
      }
      total += items.length;
    });
    b.writeln('TOTAL $total');
    // ignore: avoid_print
    print(b);
    if (_out.isNotEmpty) {
      File(
        _out,
      ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(report));
    }
  });
}

/// Screen sizes the layout audit renders every screen at. The reference size is
/// the one the English audit runs on; the others catch fixed widths/heights.
enum _Variant {
  reference('', Size(1080, 2400), 2.5, 1.0),
  smallLargeText('@small', Size(720, 1280), 2.0, 1.3),
  wide('@wide', Size(1600, 2560), 2.0, 1.0);

  const _Variant(
    this.tag,
    this.physicalSize,
    this.devicePixelRatio,
    this.textScale,
  );
  final String tag;
  final Size physicalSize;
  final double devicePixelRatio;
  final double textScale;
}
