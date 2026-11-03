import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/l10n/l10n.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/home/home_language_button.dart';
import 'package:frontend/screens/regular_mode/language_selection_screen.dart';
import 'package:frontend/services/catalog/catalog_packs.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';
import 'package:frontend/services/catalog/scheme_catalog_sync_service.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
import 'package:frontend/utils/language_names.dart';
import 'package:frontend/widgets/scheme/scheme_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoSync extends SchemeCatalogSyncService {
  int calls = 0;

  @override
  Future<CatalogSyncResult> syncIfNeeded({bool force = false}) async {
    calls++;
    return const CatalogSyncResult(CatalogSyncOutcome.unchanged);
  }
}

/// A manifest that offers Marathi, as the shipped catalog does.
const _marathiOn = <String, dynamic>{
  'languages': [
    {'code': 'en', 'isActive': true},
    {'code': 'hi', 'isActive': true},
    {'code': 'mr', 'isActive': true},
    {'code': 'ta', 'isActive': true},
  ],
  'languageRegistry': {
    'jurisdictions': {
      'central': {
        'offeredLanguages': ['en', 'hi', 'ta'],
      },
      'maharashtra': {
        'offeredLanguages': ['en', 'hi', 'mr'],
      },
    },
  },
};

/// A language added to the catalogue is shown with no per-language code:
/// Marathi from the data the catalogue already ships, and a made-up language
/// that no Dart file can have special-cased.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  final pack = LanguagePackManager.instance;

  String? stored(MssEntity e, String lang, String key) {
    final loc = e.raw['localization'];
    final block = loc is Map ? loc[lang] : null;
    final v = block is Map ? block[key] : null;
    return v is String && v.trim().isNotEmpty ? v : null;
  }

  bool inMaharashtra(MssEntity e) =>
      (e.raw['provenance'] as Map)['jurisdiction'] == 'maharashtra';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    bundle = await MssCatalogBundle.load();
    await CentralizedTranslator.instance.ensureLoaded();
  });

  setUp(() async {
    pack.resetForTesting();
    await pack.loadPack('mr');
  });

  tearDown(pack.resetForTesting);

  group('Marathi scheme content', () {
    test('all 79 Maharashtra schemes show their stored Marathi', () {
      final schemes = bundle.schemes.where(inMaharashtra).toList();
      expect(schemes, hasLength(79));
      for (final e in schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'mr');
        final shown = LocalizedScheme.fromScheme(s, 'mr');
        expect(shown.languageCode, 'mr');
        expect(shown.name, stored(e, 'mr', 'name'), reason: e.id);
        expect(shown.fullSchemeName, shown.name, reason: e.id);
        expect(shown.overview, stored(e, 'mr', 'summary'), reason: e.id);
        expect(shown.benefits, stored(e, 'mr', 'benefitsText'), reason: e.id);
        expect(shown.rawBenefitsDisplayText, shown.benefits, reason: e.id);
        expect(shown.department, stored(e, 'mr', 'authority'), reason: e.id);
        expect(
          shown.eligibilityCriteria,
          s.extras.storedEligibility('mr'),
          reason: e.id,
        );
        expect(shown.eligibilityCriteria, isNotEmpty, reason: e.id);
        expect(shown.applicationProcess, isNotEmpty, reason: e.id);
        expect(s.getName('mr'), shown.name, reason: e.id);
        expect(s.getBenefits('mr'), shown.benefits, reason: e.id);
        expect(s.getOverview('mr'), shown.overview, reason: e.id);
      }
    });

    test('numbered steps carry the Marathi text and a Marathi label', () {
      var checked = 0;
      for (final e in bundle.schemes.where(inMaharashtra)) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'mr');
        final steps = s.extras.storedSteps('mr');
        if (steps.length != s.applicationProcess.length ||
            !s.applicationProcess.every((l) => l.startsWith('Step '))) {
          continue;
        }
        final shown = LocalizedScheme.fromScheme(s, 'mr').applicationProcess;
        for (var i = 0; i < steps.length; i++) {
          expect(shown[i], 'पायरी ${i + 1}: ${steps[i]}', reason: e.id);
        }
        checked++;
      }
      expect(checked, greaterThan(20));
    });

    test('a scheme with no Marathi falls back to English, field by field', () {
      final central = bundle.schemes.firstWhere((e) => !inMaharashtra(e));
      expect(stored(central, 'mr', 'name'), isNull);
      final s = MssSchemeAdapter.toScheme(central, bundle, langCode: 'mr');
      final shown = LocalizedScheme.fromScheme(s, 'mr');
      expect(shown.name, s.name);
      expect(shown.overview, s.overview);
      expect(shown.benefits, s.benefits);
      expect(shown.eligibilityCriteria, s.eligibilityCriteria);
      expect(shown.applicationProcess, s.applicationProcess);
    });

    test('metadata comes from the Marathi dictionary, never Tamil or Hindi', () {
      final e = bundle.schemes.firstWhere(inMaharashtra);
      final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'mr');
      final shown = LocalizedScheme.fromScheme(s, 'mr');
      expect(shown.governmentLevel, 'राज्य');
      expect(shown.category, stored(e, 'mr', 'category'));
    });
  });

  group('a language no code has heard of', () {
    late MssCatalogBundle withGujarati;
    late String id;

    setUpAll(() async {
      Map<String, dynamic> parse(Uint8List gz) =>
          jsonDecode(utf8.decode(GZipDecoder().decodeBytes(gz)))
              as Map<String, dynamic>;
      final core = parse(
        await File(MssCatalogBundle.coreAssetPath).readAsBytes(),
      );
      final manifest =
          ((core['manifest.json'] as Map)['data'] as List).first as Map;
      await CatalogPacks.mergeInto(core, manifest.cast<String, dynamic>(), (
        file,
      ) async {
        final f = File('${MssCatalogBundle.catalogAssetDir}/$file');
        return f.existsSync() ? await f.readAsBytes() : null;
      }, (b) async => parse(b));
      manifest.remove('packs');
      manifest.remove('bundleFormat');
      final schemes = (core['scheme_catalog.json'] as Map)['data'] as List;
      final record = schemes.first as Map;
      id = (record['identity'] as Map)['id'] as String;
      (record['localization'] as Map)['gu'] = {
        'name': 'ગુજરાતી નામ',
        'summary': 'ગુજરાતી સારાંશ',
        'benefitsText': 'ગુજરાતી લાભ',
        'authority': 'ગુજરાતી વિભાગ',
      };
      final source = record['source'] as Map;
      (source['eligibility'] as Map)['gu'] = ['ગુજરાતી પાત્રતા'];
      withGujarati = await MssCatalogBundle.parseBytesForTest(
        Uint8List.fromList(
          GZipEncoder().encode(utf8.encode(jsonEncode(core)))!,
        ),
      );
    });

    test('its content is shown as soon as the catalogue carries it', () {
      expect(pack.indexBundle('gu', withGujarati), isTrue);
      final e = withGujarati.byId[id]!;
      final s = MssSchemeAdapter.toScheme(e, withGujarati, langCode: 'gu');
      final shown = LocalizedScheme.fromScheme(s, 'gu');
      expect(shown.name, 'ગુજરાતી નામ');
      expect(shown.overview, 'ગુજરાતી સારાંશ');
      expect(shown.benefits, 'ગુજરાતી લાભ');
      expect(shown.department, 'ગુજરાતી વિભાગ');
      expect(shown.eligibilityCriteria, ['ગુજરાતી પાત્રતા']);
    });

    test('with no stored content everything stays English', () {
      final e = bundle.schemes.first;
      final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'xx');
      final shown = LocalizedScheme.fromScheme(s, 'xx');
      expect(shown.name, s.name);
      expect(shown.overview, s.overview);
      expect(shown.benefits, s.benefits);
      expect(shown.category, s.category);
    });
  });

  group('the language list comes from the catalogue manifest', () {
    test('the shipped catalog offers Marathi for Maharashtra', () async {
      expect(await pack.offeredLanguages(), ['en', 'ta', 'hi', 'mr']);
      expect(bundle.isLanguageActive('mr'), isTrue);
      expect(bundle.offeredLanguagesFor('central'), isNot(contains('mr')));
      expect(bundle.offeredLanguagesFor('tamil_nadu'), isNot(contains('mr')));
    });

    test('a release that turns Marathi on offers it', () async {
      pack.setReleaseManifest(_marathiOn);
      expect(await pack.offeredLanguages(), ['en', 'ta', 'hi', 'mr']);
    });

    test('isActive alone is not enough: the registry must offer it', () async {
      pack.setReleaseManifest({
        'languages': _marathiOn['languages'],
        'languageRegistry': {
          'jurisdictions': {
            'maharashtra': {
              'offeredLanguages': ['en', 'hi'],
            },
          },
        },
      });
      expect(await pack.offeredLanguages(), isNot(contains('mr')));
    });

    test('a language with no content is not offered', () async {
      pack.setReleaseManifest({
        'languages': [
          {'code': 'gu', 'isActive': true},
        ],
      });
      expect(await pack.offeredLanguages(), isNot(contains('gu')));
    });

    test('a manifest with no list falls back to the UI languages', () async {
      pack.setReleaseManifest({'catalogRelease': 'schemes-3'});
      expect(await pack.offeredLanguages(), ['en', 'ta', 'hi', 'mr']);
    });
  });

  group('language names', () {
    test('are written in the language itself', () {
      expect(languageEndonym('en'), 'English');
      expect(languageEndonym('ta'), 'தமிழ்');
      expect(languageEndonym('hi'), 'हिन्दी');
      expect(languageEndonym('mr'), 'मराठी');
      expect(languageEnglishName('mr'), 'Marathi');
    });

    test('an unknown code is shown as itself, never as English', () {
      expect(languageEndonym('xx'), 'XX');
      expect(languageEndonym(''), 'English');
    });
  });

  group('switching language', () {
    test('Marathi can be selected', () async {
      final sync = _NoSync();
      final provider = AppProvider(catalogSyncService: sync);
      while (sync.calls == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      await provider.changeLanguage('mr');
      expect(provider.selectedLanguage, 'mr');
    });

    testWidgets('Marathi content renders with Marathi UI strings', (
      tester,
    ) async {
      pack.setReleaseManifest(_marathiOn);
      final sync = _NoSync();
      final provider = AppProvider(catalogSyncService: sync);
      await tester.runAsync(() async {
        while (sync.calls == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
        await provider.changeLanguage('mr');
      });
      expect(provider.selectedLanguage, 'mr');

      final e = bundle.schemes.firstWhere(inMaharashtra);
      final scheme = MssSchemeAdapter.toScheme(e, bundle, langCode: 'mr');
      late BuildContext inside;
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            locale: Locale(provider.selectedLanguage),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Builder(
                  builder: (context) {
                    inside = context;
                    return SchemeCard(
                      scheme: scheme,
                      result: RecommendationResult(
                        score: 1,
                        matchingReasons: const [],
                        missingRequirements: const [],
                        missingDocuments: const [],
                      ),
                      isBookmarked: false,
                      onBookmarkToggle: () {},
                      onTap: () {},
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(stored(e, 'mr', 'name')!), findsOneWidget);
      expect(Localizations.localeOf(inside).languageCode, 'mr');
      expect(
        inside.l10n.chooseYourLanguage,
        lookupAppLocalizations(const Locale('mr')).chooseYourLanguage,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the picker offers a language the catalogue turned on', (
      tester,
    ) async {
      pack.setReleaseManifest(_marathiOn);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(catalogSyncService: _NoSync()),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LanguageSelectionScreen(isOnboarding: false),
          ),
        ),
      );
      await tester.runAsync(() => pack.offeredLanguages());
      await tester.pumpAndSettle();
      expect(find.text('Marathi'), findsOneWidget);
      expect(find.text('मराठी'), findsWidgets);

      // Previewing it shows the interface in that language.
      await tester.tap(find.text('Marathi'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          lookupAppLocalizations(const Locale('mr')).chooseYourLanguage,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the home menu lists it too', (tester) async {
      pack.setReleaseManifest(_marathiOn);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: HomeLanguageButton(
                provider: AppProvider(catalogSyncService: _NoSync()),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => pack.offeredLanguages());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(HomeLanguageButton));
      await tester.pumpAndSettle();
      expect(find.text('मराठी'), findsOneWidget);
    });
  });
}
