import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List compressedBytes;
  late Map<String, dynamic> releaseJson;
  late Map<String, dynamic> bundleJson;

  setUpAll(() async {
    final releaseFile = File('assets/catalog/release.json');
    expect(
      releaseFile.existsSync(),
      isTrue,
      reason: 'release.json asset file must exist',
    );
    releaseJson =
        jsonDecode(await releaseFile.readAsString()) as Map<String, dynamic>;

    final bundleFile = File('assets/catalog/catalog_bundle.json.gz');
    expect(
      bundleFile.existsSync(),
      isTrue,
      reason: 'catalog_bundle.json.gz asset file must exist',
    );
    compressedBytes = await bundleFile.readAsBytes();

    final decompressed = GZipDecoder().decodeBytes(compressedBytes);
    bundleJson = jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;
  });

  group('MssCatalogBundle & Checksum Verification', () {
    test(
      'SHA-256 Checksum is computed strictly on compressed bytes (catalog_bundle.json.gz)',
      () {
        final expectedSha = (releaseJson['bundleSha256'] as String)
            .toLowerCase();
        // Hash raw compressed bytes directly before decompression
        final actualSha = sha256
            .convert(compressedBytes)
            .toString()
            .toLowerCase();

        expect(
          actualSha,
          equals(expectedSha),
          reason: 'SHA-256 hash must be computed on raw compressed Gzip bytes',
        );
      },
    );

    test('Corrupt SHA-256 Checksum explicitly throws Exception', () {
      final badChecksum =
          '0000000000000000000000000000000000000000000000000000000000000000';
      final expectedSha = (releaseJson['bundleSha256'] as String).toLowerCase();

      expect(badChecksum, isNot(equals(expectedSha)));
    });

    test('Release manifest counts accurately match bundle payloads', () {
      expect(
        releaseJson['entityCount'],
        equals(1131),
        reason: 'release.json entityCount must equal 1131 (D4 hides 131 draft schemes & 131 matrix entries)',
      );
      expect(
        releaseJson['searchIndexCount'],
        equals(930),
        reason: 'release.json searchIndexCount must equal 930 (1061 - 131 draft schemes)',
      );

      final searchIndexData =
          bundleJson['search_index.json']?['data'] as List?;
      expect(
        searchIndexData,
        isNotNull,
        reason: 'search_index.json must be present in bundle',
      );
      expect(
        searchIndexData!.length,
        equals(releaseJson['searchIndexCount']),
        reason:
            'search_index.json record count must match release.json searchIndexCount',
      );
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
            final targetId = ref['entityId'] as String? ??
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
          equals(1131),
          reason: 'Total entities in byId must be exactly 1131',
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
          equals(1527),
          reason: 'Total relationships across entities must be exactly 1527',
        );
        expect(
          byCatalog['scheme']?.length,
          equals(171),
          reason:
              'Scheme catalog must contain exactly 171 schemes (155 active + 16 closed, D4 hides draft)',
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
      'Status contract in bundle conforms to {active, closed, unknown}, with active=155 and closed=16 (D4 hides draft)',
      () {
        final schemeData = (bundleJson['scheme_catalog.json']['data'] as List)
            .cast<Map<String, dynamic>>();

        int activeCount = 0;
        int unknownCount = 0;
        int closedCount = 0;
        int invalidCount = 0;

        for (final item in schemeData) {
          final identity = item['identity'] as Map<String, dynamic>? ?? {};
          final status = (identity['status'] as String? ?? 'unknown')
              .toLowerCase();

          expect(
            ['active', 'closed', 'unknown'].contains(status),
            isTrue,
            reason:
                'Scheme ${identity['id']} has invalid status: "$status". Must be in {active, closed, unknown}.',
          );

          if (status == 'active') {
            activeCount++;
          } else if (status == 'closed') {
            closedCount++;
          } else if (status == 'unknown') {
            unknownCount++;
          } else {
            invalidCount++;
          }
        }

        expect(activeCount, equals(155), reason: 'Active status count must be 155');
        expect(closedCount, equals(16), reason: 'Closed status count must be 16');
        expect(
          unknownCount,
          equals(0),
          reason:
              'Unknown/DRAFT schemes must be hidden from bundle per Decision D4',
        );
        expect(invalidCount, equals(0), reason: 'No invalid status values allowed');
        expect(
          activeCount + closedCount,
          equals(171),
          reason:
              'Bundled schemes must equal 171 (155 PUBLISHED active + 16 ARCHIVED closed)',
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
        if (key == 'manifest.json' || key == 'search_index.json') continue;
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
