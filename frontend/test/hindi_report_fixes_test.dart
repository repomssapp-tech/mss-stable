import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/l10n/app_localizations_hi.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/profile/profile_banner_card.dart';
import 'package:frontend/screens/regular_mode/categories/emi_calculator_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/udyam_classifier_sheet.dart';
import 'package:frontend/screens/regular_mode/scheme_details/scheme_documents_section.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/screens/regular_mode/settings/active_sessions_dialog.dart';
import 'package:frontend/services/account/rest_auth_service.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthFixture extends RestAuthService {
  @override
  Future<bool> hasPassword() async => false;

  @override
  Future<List<UserSession>> getSessions() async => [
    UserSession(
      id: 'current',
      authenticatedAt: DateTime(2026, 10, 20),
      expiresAt: DateTime(2026, 11, 20),
      current: true,
    ),
    UserSession(
      id: 'other',
      authenticatedAt: DateTime(2026, 10, 19),
      expiresAt: DateTime(2026, 11, 19),
      current: false,
    ),
  ];
}

void main() {
  final hi = AppLocalizationsHi();
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await SchemeRepository.instance.getAllSchemes();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    RestAuthService.testInstance = _AuthFixture();
    CentralizedTranslator.instance.activeLanguage = 'hi';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/events'),
      (_) async => null,
    );
  });
  tearDown(() {
    RestAuthService.testInstance = null;
    CentralizedTranslator.instance.activeLanguage = 'en';
  });

  Widget wrap(Widget child, {AppProvider? provider}) =>
      ChangeNotifierProvider.value(
        value: provider ?? AppProvider(),
        child: MaterialApp(
          locale: const Locale('hi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  Future<void> openSheet(
    WidgetTester tester,
    void Function(BuildContext) show,
  ) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('HI-08 active device and status labels are Hindi', (t) async {
    await t.pumpWidget(wrap(const ActiveSessionsDialog()));
    await t.pumpAndSettle();
    expect(find.text(hi.activeBadge), findsOneWidget);
    expect(find.text(hi.sessionOtherDevice), findsOneWidget);
    expect(
      find.textContaining(hi.sessionSignedInAt('').trim()),
      findsNWidgets(2),
    );
    expect(find.text('Active'), findsNothing);
  });

  testWidgets('FN-04 badge uses the same completion score as Settings', (
    t,
  ) async {
    final provider = AppProvider();
    final profile = provider.profile;
    profile.name = 'Sample';
    profile.email = 'test@example.com';
    profile.mobile = '9999999999';
    profile.dob = DateTime(1990);
    profile.gender = 'Male';
    profile.house = '1';
    profile.area = 'Sample area';
    profile.city = 'Chennai';
    profile.district = 'Chennai';
    profile.state = 'Tamil Nadu';
    profile.pinCode = '600001';
    profile.employmentStatus = 'Entrepreneur';
    profile.educationLevel = 'School';
    profile.community = 'General';
    profile.disability = 'No';
    expect(profile.profileCompleted, isFalse);
    expect(provider.profileCompletionPercentage, 100);
    await t.pumpWidget(
      wrap(ProfileBannerCard(provider: provider), provider: provider),
    );
    await t.pumpAndSettle();
    expect(find.text(hi.profileVerified), findsOneWidget);
    // No address line at all (either field fills it) -> incomplete, even
    // though the flag says completed.
    profile.house = '';
    profile.area = '';
    profile.profileCompleted = true;
    await t.pumpWidget(
      wrap(ProfileBannerCard(provider: provider), provider: provider),
    );
    await t.pumpAndSettle();
    expect(find.text(hi.profileIncomplete), findsOneWidget);
  });

  testWidgets('FN-05 typing a nonmatch opens results without submitting', (
    t,
  ) async {
    await t.pumpWidget(wrap(const SearchScreen()));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await t.enterText(
        find.byType(TextField).first,
        'zzzxqvnonmatch987654321',
      );
      // Let offline asset/index futures complete on the real event loop.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('SearchResultsState')), findsOneWidget);
    expect(
      find.text(hi.noSchemesFound('zzzxqvnonmatch987654321')),
      findsOneWidget,
    );
    await t.enterText(find.byType(TextField).first, '');
    await t.pump(const Duration(milliseconds: 350));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('SearchResultsState')), findsNothing);
  });

  for (final sample in <(String, String, String)>[
    ('2', '8', 'MICRO Enterprise'),
    ('2.5', '10', 'MICRO Enterprise'),
    ('2.5', '10.01', 'SMALL Enterprise'),
    ('25', '100', 'SMALL Enterprise'),
    ('25.01', '100', 'MEDIUM Enterprise'),
    ('125', '500', 'MEDIUM Enterprise'),
    ('125', '500.01', 'Large Enterprise (Beyond MSME Limits)'),
  ]) {
    testWidgets('FN-03 Udyam ${sample.$1}/${sample.$2}', (t) async {
      await openSheet(t, showUdyamClassifierSheet);
      await t.enterText(find.byType(TextField).at(0), sample.$1);
      await t.enterText(find.byType(TextField).at(1), sample.$2);
      await t.ensureVisible(find.byType(ElevatedButton));
      CentralizedTranslator.instance.activeLanguage = 'hi';
      await t.tap(find.byType(ElevatedButton));
      await t.pumpAndSettle();
      expect(
        find.text(switch (sample.$3) {
          'MICRO Enterprise' => hi.udyamMicro,
          'SMALL Enterprise' => hi.udyamSmall,
          'MEDIUM Enterprise' => hi.udyamMedium,
          _ => hi.udyamLarge,
        }),
        findsOneWidget,
      );
      expect(
        find.text(
          hi.udyamLimitsSummary('2.5', '10', '25', '100', '125', '500'),
        ),
        findsOneWidget,
      );
    });
  }

  for (final rate in ['0', '12', '', '-1']) {
    testWidgets('OBS-01 EMI interest "$rate" and HI-05 label', (t) async {
      await openSheet(t, showEmiCalculatorSheet);
      await t.enterText(find.byType(TextField).at(0), '120000');
      await t.enterText(find.byType(TextField).at(1), rate);
      await t.enterText(find.byType(TextField).at(2), '12');
      await t.ensureVisible(find.byType(ElevatedButton));
      await t.tap(find.byType(ElevatedButton));
      await t.pumpAndSettle();
      if (rate == '0' || rate == '12') {
        expect(
          find.text(rate == '0' ? '₹ 10,000.00' : '₹ 10,661.85'),
          findsOneWidget,
        );
        expect(find.text('कुल राशि (मूलधन + ब्याज)'), findsOneWidget);
      } else {
        expect(find.text(hi.emiInvalidInputs), findsOneWidget);
      }
    });
  }

  testWidgets(
    'HI-03 PMEGP display fields translated; flags and portals retained',
    (t) async {
      final schemes = await SchemeRepository.instance.getAllSchemes();
      final raw = schemes.firstWhere((s) => s.id == 'CEN2026-085');
      final translated = LocalizedScheme.fromScheme(raw, 'hi');
      final hindi = RegExp(r'[\u0900-\u097f]');
      expect(translated.targetBeneficiary, matches(hindi));
      expect(translated.subsidyAmount, matches(hindi));
      for (var i = 0; i < raw.documents.length; i++) {
        final d = translated.documents[i];
        for (final text in [
          d.name,
          d.description,
          d.estimatedCost,
          d.issuingAuthority,
          d.remarks,
        ]) {
          if (text.isNotEmpty) expect(text, matches(hindi), reason: text);
        }
        expect(d.isMandatory, raw.documents[i].isMandatory);
        expect(d.sourceUrl, raw.documents[i].sourceUrl);
      }
      await t.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: SchemeDocumentsContent(
              scheme: translated,
              onOpenUrl: (_) {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Conditional'), findsNothing);
      expect(find.text(hi.badgeConditional), findsWidgets);
      expect(find.text(hi.getDocumentOnline), findsWidgets);
    },
  );
}
