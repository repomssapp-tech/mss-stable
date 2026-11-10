import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/home/home_language_button.dart';
import 'package:frontend/screens/regular_mode/language_selection_screen.dart';
import 'package:frontend/services/account/session_cache_service.dart';
import 'package:frontend/services/catalog/catalog_packs.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';
import 'package:frontend/services/catalog/scheme_catalog_sync_service.dart';
import 'package:frontend/utils/language_names.dart';
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

/// A manifest that turns Marathi on, as the shipped catalog data does.
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

/// Scheme content in a language the catalogue carries renders with no
/// per-language code, but the app offers only English, Tamil and Hindi
/// (Marathi was removed in 2.5.0) whatever the catalogue manifest says.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  final pack = LanguagePackManager.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    bundle = await MssCatalogBundle.load();
    await CentralizedTranslator.instance.ensureLoaded();
  });

  setUp(() async {
    pack.resetForTesting();
  });

  tearDown(pack.resetForTesting);

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

  group('the app offers English, Tamil and Hindi only', () {
    test(
      'the shipped catalog: Marathi data stays, Marathi is not offered',
      () async {
        expect(await pack.offeredLanguages(), ['en', 'ta', 'hi']);
        expect(pack.isLanguageActiveInRelease('mr'), isFalse);
      },
    );

    test('a release that turns Marathi on still does not offer it', () async {
      pack.setReleaseManifest(_marathiOn);
      expect(await pack.offeredLanguages(), ['en', 'ta', 'hi']);
      expect(await pack.isLanguageSupported('mr'), isFalse);
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
      expect(await pack.offeredLanguages(), ['en', 'ta', 'hi']);
    });
  });

  group('language names', () {
    test('are written in the language itself', () {
      expect(languageEndonym('en'), 'English');
      expect(languageEndonym('ta'), 'தமிழ்');
      expect(languageEndonym('hi'), 'हिन्दी');
    });

    test('an unknown code is shown as itself, never as English', () {
      expect(languageEndonym('xx'), 'XX');
      expect(languageEndonym(''), 'English');
    });
  });

  group('switching language', () {
    test('Marathi cannot be selected', () async {
      pack.setReleaseManifest(_marathiOn);
      final sync = _NoSync();
      final provider = AppProvider(catalogSyncService: sync);
      while (sync.calls == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      await provider.changeLanguage('mr');
      expect(provider.selectedLanguage, isNot('mr'));
      await provider.changeLanguage('hi');
      expect(provider.selectedLanguage, 'hi');
    });

    test('a phone saved in Marathi starts in English', () async {
      SharedPreferences.setMockInitialValues({'language': 'mr'});
      expect(await SessionCacheService.instance.getLanguage(), 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), 'en');
      SharedPreferences.setMockInitialValues({'language': 'hi'});
      expect(await SessionCacheService.instance.getLanguage(), 'hi');
    });

    testWidgets('the picker lists English, Tamil and Hindi', (tester) async {
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
      expect(find.text('Marathi'), findsNothing);
      expect(find.text('मराठी'), findsNothing);
      expect(find.text('Hindi'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the home menu leaves Marathi out too', (tester) async {
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
      expect(find.text('मराठी'), findsNothing);
      expect(find.text('हिन्दी'), findsWidgets);
    });
  });
}
