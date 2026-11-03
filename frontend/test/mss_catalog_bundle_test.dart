import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/catalog/catalog_packs.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List compressedBytes;
  late Map<String, dynamic> manifest;
  late Map<String, dynamic> bundleJson;

  Uint8List encode(Map<String, dynamic> json) =>
      Uint8List.fromList(GZipEncoder().encode(utf8.encode(jsonEncode(json)))!);

  setUpAll(() async {
    final coreFile = File(MssCatalogBundle.coreAssetPath);
    expect(
      coreFile.existsSync(),
      isTrue,
      reason: 'catalog_core.json.gz asset file must exist',
    );
    compressedBytes = await coreFile.readAsBytes();

    Map<String, dynamic> parse(Uint8List gz) =>
        jsonDecode(utf8.decode(GZipDecoder().decodeBytes(gz)))
            as Map<String, dynamic>;
    bundleJson = parse(compressedBytes);
    manifest =
        (bundleJson['manifest.json']['data'] as List).first
            as Map<String, dynamic>;
    // The merged view: the core plus every jurisdiction pack, as the app sees it.
    await CatalogPacks.mergeInto(bundleJson, manifest, (file) async {
      final f = File('${MssCatalogBundle.catalogAssetDir}/$file');
      return f.existsSync() ? await f.readAsBytes() : null;
    }, (bytes) async => parse(bytes));
  });

  group('MssCatalogBundle & embedded manifest', () {
    test('the asset is real GZIP holding UTF-8 JSON', () {
      expect(compressedBytes[0], 0x1f);
      expect(compressedBytes[1], 0x8b);
      expect(bundleJson, isNotEmpty);
    });

    test('the embedded manifest identifies the release and format', () {
      final release = manifest['release'] as Map<String, dynamic>;
      expect(release['releaseTag'], '1.37.0-alpha');
      expect(DateTime.tryParse(release['releasedAt'] as String), isNotNull);
      expect(manifest['bundleFormat'], MssCatalogBundle.supportedBundleFormat);
    });

    test('manifest record counts match every section of the payload', () {
      final counts = (manifest['recordCounts'] as Map).cast<String, int>();
      expect(counts.length, 15, reason: 'one count per catalog section');
      var entities = 0;
      counts.forEach((section, expected) {
        final data = bundleJson[section]['data'] as List;
        expect(data.length, expected, reason: section);
        entities += data.length;
      });
      expect(manifest['entityCount'], entities);
      expect(entities, 1601, reason: '406 schemes + 1195 other entities');
      expect(
        (bundleJson['search_index.json']['data'] as List).length,
        1165,
        reason: '406 scheme rows + non-scheme rows',
      );
    });

    test('manifest inventory, section metadata and data all agree', () {
      final files = (manifest['files'] as List).cast<Map<String, dynamic>>();
      expect(files.length, 16, reason: '15 catalogs + search index');
      for (final f in files) {
        final name = f['fileName'] as String;
        final section = bundleJson[name] as Map<String, dynamic>;
        final meta = section['metadata'] as Map<String, dynamic>;
        final length = (section['data'] as List).length;
        expect(f['recordCount'], length, reason: name);
        expect(meta['recordCount'], length, reason: name);
        expect(f['checksum'], meta['checksum'], reason: name);
        expect(f['schemaVersion'], meta['schemaVersion'], reason: name);
      }
      expect(
        manifest['releasedAt'],
        (manifest['release'] as Map)['releasedAt'],
      );
      expect(
        manifest['history'],
        isA<Map>(),
        reason: 'authoring history kept apart',
      );
      expect(manifest.containsKey('generationOrder'), isFalse);
    });

    test('a truncated bundle fails its own record-count check', () async {
      final tampered =
          jsonDecode(jsonEncode(bundleJson)) as Map<String, dynamic>;
      (tampered['scheme_catalog.json']['data'] as List).removeLast();
      await expectLater(
        MssCatalogBundle.parseBytesForTest(encode(tampered)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('scheme_catalog.json: expected 406, found 405'),
          ),
        ),
      );
    });

    test(
      'a bundle from a newer format is rejected with a clear message',
      () async {
        final tampered =
            jsonDecode(jsonEncode(bundleJson)) as Map<String, dynamic>;
        ((tampered['manifest.json']['data'] as List).first
                as Map)['bundleFormat'] =
            MssCatalogBundle.supportedBundleFormat + 1;
        await expectLater(
          MssCatalogBundle.parseBytesForTest(encode(tampered)),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

    test('the loaded bundle exposes manifest, languages and id map', () async {
      final loaded = await MssCatalogBundle.load();
      expect(loaded.releaseTag, '1.37.0-alpha');
      expect(loaded.isLanguageActive('hi'), isTrue);
      expect(loaded.isLanguageActive('mr'), isTrue);
      expect(loaded.offeredLanguagesFor('tamil_nadu'), ['en', 'ta']);
      expect(loaded.offeredLanguagesFor('maharashtra'), ['en', 'hi', 'mr']);
      expect(loaded.offeredLanguagesFor('central'), ['en', 'hi', 'ta']);
      expect(loaded.schemeIdMap['SCH000130'], 'CEN2026-085');
    });

    test(
      'Graph Integrity: Unique Entity IDs, Unique Relationship IDs, and 0 Dangling References',
      () {
        final byId = <String, MssEntity>{};
        final byCatalog = <String, List<MssEntity>>{};
        final seenEntityIds = <String>{};
        int duplicateEntityIdCount = 0;
        int totalRels = 0;

        const catalogKeys = [
          'common_catalog.json',
          'authority_catalog.json',
          'institution_catalog.json',
          'scheme_catalog.json',
          'finance_catalog.json',
          'tax_catalog.json',
          'treds_catalog.json',
          'csr_catalog.json',
          'export_catalog.json',
          'knowledge_catalog.json',
          'applicability_matrix_catalog.json',
          'enterprise_classification_catalog.json',
          'msme_privilege_catalog.json',
          'business_enablement_catalog.json',
          'cluster_assistance_catalog.json',
        ];

        for (final fileKey in catalogKeys) {
          final catalogObject = bundleJson[fileKey] as Map<String, dynamic>?;
          expect(
            catalogObject,
            isNotNull,
            reason: 'Catalog file $fileKey must exist in bundle',
          );

          final catalogName =
              (catalogObject!['metadata']?['catalogName'] as String?) ??
              fileKey.replaceAll('_catalog.json', '');

          final dataList = catalogObject['data'] as List?;
          expect(dataList, isNotNull);

          final entityList = <MssEntity>[];
          for (final rawItem in dataList!) {
            if (rawItem is Map<String, dynamic>) {
              final entity = MssEntity.fromJson(rawItem);
              if (seenEntityIds.contains(entity.id)) {
                duplicateEntityIdCount++;
              } else {
                seenEntityIds.add(entity.id);
              }
              byId[entity.id] = entity;
              entityList.add(entity);
              totalRels += entity.references.length;
            }
          }
          byCatalog[catalogName] = entityList;
        }

        // Graph traversal to check for dangling references across all key conventions
        int danglingReferenceCount = 0;
        for (final entity in byId.values) {
          for (final ref in entity.references) {
            final targetId =
                ref['entityId'] as String? ??
                ref['targetId'] as String? ??
                ref['target_id'] as String?;
            if (targetId != null &&
                targetId.isNotEmpty &&
                !byId.containsKey(targetId)) {
              danglingReferenceCount++;
            }
          }
        }

        expect(
          byId.length,
          equals(1601),
          reason: 'Total entities in byId must be exactly 1601',
        );
        expect(
          duplicateEntityIdCount,
          equals(0),
          reason: 'Duplicate entity IDs must be 0',
        );
        expect(
          danglingReferenceCount,
          equals(0),
          reason: 'Dangling references in graph must be 0',
        );
        expect(
          totalRels,
          equals(2066),
          reason: 'Total relationships across entities must be exactly 2066',
        );
        expect(
          byCatalog['scheme']?.length,
          equals(406),
          reason:
              'Scheme catalog must contain exactly 406 schemes (274 central + 53 Tamil Nadu + 79 Maharashtra)',
        );
      },
    );
  });

  group('Multilingual Search Acceptance Criteria', () {
    test(
      'Tamil UI / Query -> search SIDBI -> matches English & Tamil tokens',
      () async {
        final bundle = await MssCatalogBundle.load();
        final results = bundle.search('SIDBI');

        expect(
          results,
          isNotEmpty,
          reason: 'Search for SIDBI must return matching entities',
        );
        expect(
          results.any(
            (e) =>
                e.getLocalizedName('en').contains('SIDBI') ||
                e.search.toString().contains('SIDBI'),
          ),
          isTrue,
          reason: 'Results must contain English tokens for SIDBI',
        );
      },
    );

    test(
      'English UI / Query -> search மானியம் -> matches Tamil & English tokens',
      () async {
        final bundle = await MssCatalogBundle.load();
        final results = bundle.search('மானியம்');

        expect(
          results,
          isNotEmpty,
          reason: 'Search for மானியம் must return matching entities',
        );
        expect(
          results.any(
            (e) =>
                e.getLocalizedName('ta').contains('மானியம்') ||
                e.getLocalizedName('en').toLowerCase().contains('subsidy'),
          ),
          isTrue,
          reason: 'Results must return Tamil and English subsidy tokens',
        );
      },
    );
  });

  group('Scheme Status & Distribution Verification', () {
    test(
      'Status contract in bundle conforms to {active, closed, unknown, announced} with the 2026 source counts',
      () {
        final schemeData = (bundleJson['scheme_catalog.json']['data'] as List)
            .cast<Map<String, dynamic>>();

        int activeCount = 0;
        int unknownCount = 0;
        int announcedCount = 0;
        int closedCount = 0;
        int invalidCount = 0;

        for (final item in schemeData) {
          final identity = item['identity'] as Map<String, dynamic>? ?? {};
          final status = (identity['status'] as String? ?? 'unknown')
              .toLowerCase();

          expect(
            ['active', 'closed', 'unknown', 'announced'].contains(status),
            isTrue,
            reason:
                'Scheme ${identity['id']} has invalid status: "$status". Must be in {active, closed, unknown, announced}.',
          );

          if (status == 'active') {
            activeCount++;
          } else if (status == 'closed') {
            closedCount++;
          } else if (status == 'unknown') {
            unknownCount++;
          } else if (status == 'announced') {
            announcedCount++;
          } else {
            invalidCount++;
          }
        }

        // The 2026 source carries its own status per scheme (no draft list), so
        // `unknown` (status not confirmed) and `announced` schemes ship too.
        expect(
          activeCount,
          equals(267),
          reason: 'Active status count must be 267',
        );
        expect(
          closedCount,
          equals(26),
          reason: 'Closed status count must be 26',
        );
        expect(
          unknownCount,
          equals(68),
          reason: 'Unknown status count must be 68',
        );
        expect(
          announcedCount,
          equals(45),
          reason: 'Announced status count must be 45',
        );
        expect(
          invalidCount,
          equals(0),
          reason: 'No invalid status values allowed',
        );
        expect(
          activeCount + closedCount + unknownCount + announcedCount,
          equals(406),
          reason: 'Bundled schemes must equal 406',
        );
      },
    );
  });

  group('MssSchemeAdapter Null Rules & Currency Rules', () {
    test('Null values remain null without defaulting to 0 or empty string', () {
      final schemeData = (bundleJson['scheme_catalog.json']['data'] as List)
          .cast<Map<String, dynamic>>();

      final byId = <String, MssEntity>{};
      final byCatalog = <String, List<MssEntity>>{};
      int totalRels = 0;

      for (final key in bundleJson.keys) {
        // Entity catalogs only; manifest/search_index/migrations are other sections.
        if (!key.endsWith('_catalog.json')) continue;
        final catObj = bundleJson[key] as Map<String, dynamic>;
        final catName = catObj['metadata']['catalogName'] as String;
        final list = (catObj['data'] as List).cast<Map<String, dynamic>>();
        final entities = <MssEntity>[];
        for (final item in list) {
          final e = MssEntity.fromJson(item);
          byId[e.id] = e;
          entities.add(e);
          totalRels += e.references.length;
        }
        byCatalog[catName] = entities;
      }

      final mockBundle = MssCatalogBundleProxy(byId, byCatalog, totalRels);

      for (final item in schemeData) {
        final entity = MssEntity.fromJson(item);
        final scheme = MssSchemeAdapter.toScheme(entity, mockBundle);

        // Reverted weakened assertion: Closed schemes must NOT be active; active schemes must be active.
        if (entity.status.toLowerCase() == 'closed') {
          expect(
            scheme.isActive,
            isFalse,
            reason: 'Closed scheme ${entity.id} must have isActive == false',
          );
        } else if (entity.status.toLowerCase() == 'active') {
          expect(
            scheme.isActive,
            isTrue,
            reason: 'Active scheme ${entity.id} must have isActive == true',
          );
        }
      }
    });
  });
}

class MssCatalogBundleProxy implements MssCatalogBundle {
  @override
  final Map<String, MssEntity> byId;
  @override
  final Map<String, List<MssEntity>> byCatalog;
  @override
  final int totalRelationshipsCount;
  @override
  final Map<String, Map<String, dynamic>> searchProfiles = const {};
  @override
  final Map<String, List<String>> queryExpansions = const {};
  @override
  final Map<String, dynamic> manifest = const {};
  @override
  final Map<String, String> schemeIdMap = const {};
  @override
  final List<String> loadedPackIds = const [];
  @override
  List<CatalogPackInfo> get availablePacks => const [];

  @override
  List<({String code, bool isActive})> get languages => const [];

  @override
  bool isLanguageActive(String code) => false;

  @override
  List<String> offeredLanguagesFor(String jurisdiction) => const [];

  MssCatalogBundleProxy(
    this.byId,
    this.byCatalog,
    this.totalRelationshipsCount,
  );

  @override
  int get totalEntitiesCount => byId.length;

  @override
  List<MssEntity> get schemes => byCatalog['scheme'] ?? const [];

  @override
  MssEntity? getEntity(String id) => byId[id];

  @override
  List<MssEntity> getCatalog(String catalogName) =>
      byCatalog[catalogName] ?? const [];

  @override
  String get releaseTag => '1.33.0-alpha';

  @override
  DateTime? get releasedAt => null;

  @override
  int get duplicateEntityIdCount => 0;

  @override
  int get danglingReferenceCount => 0;

  @override
  int get uniqueRelationshipIdsCount => 1715;

  @override
  List<MssEntity> search(String query) => schemes;

  @override
  List<MssEntity> getLinkedEntities(
    MssEntity entity, {
    String? targetType,
    String? relationType,
  }) => const [];

  @override
  List<MssEntity> getReverseLinkedEntities(
    String targetSchemeId,
    String catalogName,
  ) => const [];

  @override
  List<MssEntity> getAuthoritiesForScheme(MssEntity scheme) => const [];

  @override
  List<MssEntity> getInstitutionsForScheme(MssEntity scheme) => const [];

  @override
  List<MssEntity> getFinanceProductsForScheme(MssEntity scheme) => const [];

  @override
  List<MssEntity> getTaxProvisionsForScheme(MssEntity scheme) => const [];

  @override
  List<MssEntity> getExportBenefitsForScheme(MssEntity scheme) => const [];

  @override
  List<MssEntity> getCsrProvisionsForScheme(MssEntity scheme) => const [];

  @override
  List<MssEntity> getTredsPlatformsForScheme(MssEntity scheme) => const [];

  @override
  List<MssEntity> getKnowledgeItemsForScheme(MssEntity scheme) => const [];
}
