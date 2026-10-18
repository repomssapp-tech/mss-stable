import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    test('app_hi.arb contains all keys from app_en.arb (0 missing keys)', () async {
      final enFile = File('lib/l10n/app_en.arb');
      final hiFile = File('lib/l10n/app_hi.arb');

      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
      expect(hiFile.existsSync(), isTrue, reason: 'app_hi.arb must exist');

      final enData = jsonDecode(await enFile.readAsString()) as Map<String, dynamic>;
      final hiData = jsonDecode(await hiFile.readAsString()) as Map<String, dynamic>;

      final missingKeys = <String>[];
      for (final key in enData.keys) {
        if (key.startsWith('@')) continue;
        if (!hiData.containsKey(key) || (hiData[key] as String).trim().isEmpty) {
          missingKeys.add(key);
        }
      }

      expect(
        missingKeys,
        isEmpty,
        reason: 'Zero keys from app_en.arb may be missing in app_hi.arb. Missing: $missingKeys',
      );
    });
  });

  group('Phase P4: LanguagePackManager Tests', () {
    setUp(() {
      LanguagePackManager.instance.resetForTesting();
    });

    test('Loads catalog_pack_hi.json.gz from assets and indexes entries', () async {
      final packFile = File('assets/catalog/catalog_pack_hi.json.gz');
      expect(packFile.existsSync(), isTrue, reason: 'catalog_pack_hi.json.gz asset must exist');

      final bytes = await packFile.readAsBytes();
      final releaseFile = File('assets/catalog/release.json');
      final releaseJson = jsonDecode(await releaseFile.readAsString()) as Map<String, dynamic>;
      final expectedSha = releaseJson['languagePacks']['hi']['sha256'] as String;

      final installed = await LanguagePackManager.instance.installPackBytes(
        lang: 'hi',
        compressedBytes: bytes,
        expectedSha256: expectedSha,
      );

      expect(installed, isTrue);
      expect(LanguagePackManager.instance.isLanguageLoaded('hi'), isTrue);

      // Verify field lookup on an in-scope scheme (SCH000006)
      final name = LanguagePackManager.instance.getField(
        lang: 'hi',
        entityType: 'scheme',
        entityId: 'SCH000006',
        fieldName: 'name',
      );
      expect(name, isNotNull);
      expect(name!.isNotEmpty, isTrue);
    });

    test('Rejects corrupt/invalid SHA-256 and discards payload', () async {
      final corruptBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final installed = await LanguagePackManager.instance.installPackBytes(
        lang: 'hi',
        compressedBytes: corruptBytes,
        expectedSha256: 'deadbeef12345678',
      );

      expect(installed, isFalse);
      expect(LanguagePackManager.instance.isLanguageLoaded('hi'), isFalse);
    });

    test('bad sha -> rejected, old pack kept', () async {
      final packFile = File('assets/catalog/catalog_pack_hi.json.gz');
      final bytes = await packFile.readAsBytes();
      final releaseFile = File('assets/catalog/release.json');
      final releaseJson = jsonDecode(await releaseFile.readAsString()) as Map<String, dynamic>;
      final validSha = releaseJson['languagePacks']['hi']['sha256'] as String;

      // 1. Install initial valid pack
      final installedV1 = await LanguagePackManager.instance.installPackBytes(
        lang: 'hi',
        compressedBytes: bytes,
        expectedSha256: validSha,
      );
      expect(installedV1, isTrue);

      final originalName = LanguagePackManager.instance.getField(
        lang: 'hi',
        entityType: 'scheme',
        entityId: 'SCH000006',
        fieldName: 'name',
      );
      expect(originalName, isNotNull);

      // 2. Attempt to install a corrupted payload with bad sha
      final badBytes = Uint8List.fromList([9, 8, 7, 6, 5]);
      final installedV2 = await LanguagePackManager.instance.installPackBytes(
        lang: 'hi',
        compressedBytes: badBytes,
        expectedSha256: 'bad_sha_256_checksum_value',
      );

      // 3. Verify rejected
      expect(installedV2, isFalse);

      // 4. Verify old pack is KEPT and untouched
      expect(LanguagePackManager.instance.isLanguageLoaded('hi'), isTrue);
      final retainedName = LanguagePackManager.instance.getField(
        lang: 'hi',
        entityType: 'scheme',
        entityId: 'SCH000006',
        fieldName: 'name',
      );
      expect(retainedName, equals(originalName));
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
      expect(entity.getLocalizedAttribute('summary', 'en'), equals('English Summary Text'));

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

    test('Scheme.toLocalized and Scheme.getName resolve Hindi through LanguagePackManager', () async {
      await LanguagePackManager.instance.loadPack('hi');
      final bundle = await MssCatalogBundle.load();
      // Use a Central scheme (e.g. SCH000006) which has Hindi translations per Decision D6
      final scheme = bundle.schemes.firstWhere((s) => s.id == 'SCH000006');
      final domainScheme = MssSchemeAdapter.toScheme(scheme, bundle, langCode: 'hi');
      
      final localized = domainScheme.toLocalized('hi');
      expect(localized.languageCode, equals('hi'));
      expect(localized.name, isNotEmpty);
      expect(domainScheme.getName('hi'), isNotEmpty);
      // Verify Hindi characters are present in localized name if translated
      final hiName = domainScheme.getName('hi');
      final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(hiName);
      expect(hasDevanagari, isTrue, reason: 'Scheme name should contain Devanagari characters: $hiName');
    });
  });

  group('Phase P5: Hindi Search Queries', () {
    test('Devanagari queries hit expected schemes and parse without error', () async {
      await SchemeSearchTaxonomy.ensureLoaded();
      final bundle = await MssCatalogBundle.load();
      final search = await HybridSchemeSearch.build(bundle);

      // Test real queries mentioned in MASTER_PLAN P5: कारीगर, ऋण, सब्सिडी
      final queryLoan = search.search('ऋण');
      expect(queryLoan, isNotEmpty, reason: 'Search for "ऋण" must yield matches');

      final querySubsidy = search.search('सब्सिडी');
      expect(querySubsidy, isNotEmpty, reason: 'Search for "सब्सिडी" must yield matches');

      final queryArtisan = search.search('कारीगर');
      expect(queryArtisan, isNotEmpty, reason: 'Search for "कारीगर" must yield matches');
    });
  });
}
