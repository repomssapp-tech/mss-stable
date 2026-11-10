import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase P4: ARB Completeness Check', () {
    test(
      'app_hi.arb contains all keys from app_en.arb (0 missing keys)',
      () async {
        final enFile = File('lib/l10n/app_en.arb');
        final hiFile = File('lib/l10n/app_hi.arb');

        expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
        expect(hiFile.existsSync(), isTrue, reason: 'app_hi.arb must exist');

        final enData =
            jsonDecode(await enFile.readAsString()) as Map<String, dynamic>;
        final hiData =
            jsonDecode(await hiFile.readAsString()) as Map<String, dynamic>;

        final missingKeys = <String>[];
        for (final key in enData.keys) {
          if (key.startsWith('@')) continue;
          if (!hiData.containsKey(key) ||
              (hiData[key] as String).trim().isEmpty) {
            missingKeys.add(key);
          }
        }

        expect(
          missingKeys,
          isEmpty,
          reason:
              'Zero keys from app_en.arb may be missing in app_hi.arb. Missing: $missingKeys',
        );
      },
    );
  });

  group('LanguagePackManager (backed by the unified bundle)', () {
    late MssCatalogBundle bundle;

    setUpAll(() async {
      bundle = await MssCatalogBundle.load();
    });

    setUp(() {
      LanguagePackManager.instance.resetForTesting();
    });

    test(
      'the runtime ships the core file and one pack per jurisdiction, no side files',
      () {
        final files = Directory('assets/catalog')
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .toSet();
        expect(
          files.where(
            (f) => f.startsWith('catalog_') && f.endsWith('.json.gz'),
          ),
          {
            'catalog_core.json.gz',
            'catalog_central.json.gz',
            'catalog_tamil_nadu.json.gz',
            'catalog_maharashtra.json.gz',
          },
        );
        expect(files, isNot(contains('catalog_bundle.json.gz')));
        expect(files.where((f) => f.startsWith('catalog_pack_')), isEmpty);
        expect(files, isNot(contains('release.json')));
        expect(files, isNot(contains('scheme_id_map.json')));
        expect(files, isNot(contains('scheme_supplement_legacy.json')));
      },
    );

    test('loads Hindi from the bundle and indexes entries', () async {
      expect(await LanguagePackManager.instance.loadPack('hi'), isTrue);
      expect(LanguagePackManager.instance.isLanguageLoaded('hi'), isTrue);

      final name = LanguagePackManager.instance.getField(
        lang: 'hi',
        entityType: 'scheme',
        entityId: 'CEN2026-223',
        fieldName: 'name',
      );
      expect(name, isNotNull);
      expect(RegExp(r'[ऀ-ॿ]').hasMatch(name!), isTrue);
    });

    test('authority translations come from the entity, not a pack', () async {
      await LanguagePackManager.instance.loadPack('hi');
      final authority = bundle.byCatalog['authority']!.firstWhere(
        (e) => (e.raw['localization'] as Map).containsKey('hi'),
      );
      final name = LanguagePackManager.instance.getField(
        lang: 'hi',
        entityType: 'authority',
        entityId: authority.id,
        fieldName: 'name',
      );
      expect(name, isNotNull);
      expect(
        LanguagePackManager.instance.isVerified(
          lang: 'hi',
          entityType: 'authority',
          entityId: authority.id,
        ),
        isA<bool>(),
      );
    });

    test(
      'a language the catalog has no content for is not loaded (no invention)',
      () async {
        expect(await LanguagePackManager.instance.loadPack('kn'), isFalse);
        expect(LanguagePackManager.instance.isLanguageLoaded('kn'), isFalse);
        expect(
          LanguagePackManager.instance.getField(
            lang: 'kn',
            entityType: 'scheme',
            entityId: 'CEN2026-223',
            fieldName: 'name',
          ),
          isNull,
        );
      },
    );

    test('a Tamil Nadu scheme has its Hindi name in the pack', () async {
      await LanguagePackManager.instance.loadPack('hi');
      final tn = bundle.schemes.firstWhere(
        (s) => (s.raw['provenance'] as Map)['jurisdiction'] == 'tamil_nadu',
      );
      expect(
        LanguagePackManager.instance.getField(
          lang: 'hi',
          entityType: 'scheme',
          entityId: tn.id,
          fieldName: 'name',
        ),
        tn.getLocalizedName('hi'),
      );
      expect(tn.getLocalizedName('hi'), isNot(tn.getLocalizedName('en')));
    });

    test('the manifest is the language kill switch', () async {
      LanguagePackManager.instance.setReleaseManifest(bundle.manifest);
      expect(
        LanguagePackManager.instance.isLanguageActiveInRelease('hi'),
        isTrue,
      );
      expect(
        LanguagePackManager.instance.isLanguageActiveInRelease('ta'),
        isTrue,
      );
      expect(
        LanguagePackManager.instance.isLanguageActiveInRelease('mr'),
        isFalse, // removed from the app in 2.5.0, whatever the manifest says
      );
      expect(
        await LanguagePackManager.instance.isLanguageSupported('hi'),
        isTrue,
      );
      expect(
        await LanguagePackManager.instance.isLanguageSupported('mr'),
        isFalse,
      );

      LanguagePackManager.instance.setReleaseManifest({
        'languages': [
          {'code': 'hi', 'isActive': false},
        ],
      });
      expect(
        await LanguagePackManager.instance.isLanguageSupported('hi'),
        isFalse,
      );
    });

    test('a manifest without a languages list keeps the app languages on', () {
      // Admin-published catalogs (schemes-3) carry no `languages` list.
      LanguagePackManager.instance.setReleaseManifest({
        'catalogRelease': 'schemes-3',
      });
      final m = LanguagePackManager.instance;
      expect(m.isLanguageActiveInRelease('hi'), isTrue);
      expect(m.isLanguageActiveInRelease('ta'), isTrue);
      expect(m.isLanguageActiveInRelease('mr'), isFalse);
      expect(m.isLanguageActiveInRelease('gu'), isFalse);
    });
  });

  group('Phase P4: MssEntity Content Resolver Fallback', () {
    test('Per-field fallback: pack -> legacy block -> English fallback', () {
      final entity = MssEntity.fromJson({
        'identity': {
          'id': 'TEST_SCHEME_001',
          'entityType': 'scheme',
          'code': 'TEST',
          'name': 'English Scheme Name',
        },
        'attributes': {
          'summary': 'English Summary Text',
          'eligibilityText': 'English Eligibility Text',
        },
        'localization': {
          'en': {
            'name': 'English Scheme Name',
            'summary': 'English Summary Text',
            'eligibilityText': 'English Eligibility Text',
          },
          'hi': {
            'name': 'हिंदी योजना का नाम',
            // eligibilityText is null (e.g. excluded due to number mismatch)
          },
        },
      });

      // 1. English resolution
      expect(entity.getLocalizedName('en'), equals('English Scheme Name'));
      expect(
        entity.getLocalizedAttribute('summary', 'en'),
        equals('English Summary Text'),
      );

      // 2. Hindi resolution with non-empty Hindi name
      expect(entity.getLocalizedName('hi'), equals('हिंदी योजना का नाम'));

      // 3. Fallback: Hindi field is null -> cleanly falls back to English!
      expect(
        entity.getLocalizedAttribute('eligibilityText', 'hi'),
        equals('English Eligibility Text'),
      );

      // 4. Missing language: falls back to English cleanly
      expect(entity.getLocalizedName('kn'), equals('English Scheme Name'));
      expect(
        entity.getLocalizedAttribute('summary', 'kn'),
        equals('English Summary Text'),
      );
    });

    test(
      'Scheme.toLocalized and Scheme.getName resolve Hindi through LanguagePackManager',
      () async {
        await LanguagePackManager.instance.loadPack('hi');
        final bundle = await MssCatalogBundle.load();
        // Use a Central scheme (e.g. CEN2026-223) which has Hindi translations per Decision D6
        final scheme = bundle.schemes.firstWhere((s) => s.id == 'CEN2026-223');
        final domainScheme = MssSchemeAdapter.toScheme(
          scheme,
          bundle,
          langCode: 'hi',
        );

        final localized = domainScheme.toLocalized('hi');
        expect(localized.languageCode, equals('hi'));
        expect(localized.name, isNotEmpty);
        expect(domainScheme.getName('hi'), isNotEmpty);
        // Verify Hindi characters are present in localized name if translated
        final hiName = domainScheme.getName('hi');
        final hasDevanagari = RegExp(r'[ऀ-ॿ]').hasMatch(hiName);
        expect(
          hasDevanagari,
          isTrue,
          reason: 'Scheme name should contain Devanagari characters: $hiName',
        );
      },
    );
  });

  group('Phase P5: Hindi Search Queries', () {
    test(
      'Devanagari queries hit expected schemes and parse without error',
      () async {
        await SchemeSearchTaxonomy.ensureLoaded();
        final bundle = await MssCatalogBundle.load();
        final search = await HybridSchemeSearch.build(bundle);

        // Test real queries mentioned in MASTER_PLAN P5: कारीगर, ऋण, सब्सिडी
        final queryLoan = search.search('ऋण');
        expect(
          queryLoan,
          isNotEmpty,
          reason: 'Search for "ऋण" must yield matches',
        );

        final querySubsidy = search.search('सब्सिडी');
        expect(
          querySubsidy,
          isNotEmpty,
          reason: 'Search for "सब्सिडी" must yield matches',
        );

        final queryArtisan = search.search('कारीगर');
        expect(
          queryArtisan,
          isNotEmpty,
          reason: 'Search for "कारीगर" must yield matches',
        );
      },
    );
  });
}
