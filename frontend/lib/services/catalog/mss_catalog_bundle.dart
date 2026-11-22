import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/mss_entity.dart';
import 'catalog_language_fill.dart';
import 'catalog_packs.dart';
import 'scheme_catalog_store.dart';

/// Top-level isolate function for async gzip decompression and JSON decoding.
/// Executed off the UI main thread via [compute] to prevent startup jank.
Map<String, dynamic> _decompressAndParseJson(Uint8List bytes) {
  final decompressedBytes = GZipDecoder().decodeBytes(bytes);
  if (decompressedBytes.length > MssCatalogBundle.maxDownloadedBytes) {
    throw StateError('Catalog bundle expands beyond the allowed size.');
  }
  final utf8String = utf8.decode(decompressedBytes);
  return jsonDecode(utf8String) as Map<String, dynamic>;
}

/// MssCatalogBundle
/// ─────────────────
/// Lazy Singleton loader and in-memory index for the offline catalog bundle.
/// Loads catalog_bundle.json.gz exactly once per app lifespan, verifies SHA-256 checksum,
/// and builds O(1) dual indexes (`byId` and `byCatalog`) along with a combined multilingual search index.
class MssCatalogBundle {
  MssCatalogBundle._({
    required Map<String, MssEntity> byId,
    required Map<String, List<MssEntity>> byCatalog,
    required Map<String, Set<String>> searchTokenMap,
    required Map<String, Map<String, dynamic>> searchProfiles,
    required this.releaseTag,
    this.releasedAt,
    required this.manifest,
    required Map<String, String> schemeIdMap,
    required this.totalRelationshipsCount,
    required Map<String, List<String>> queryExpansions,
    this.duplicateEntityIdCount = 0,
    this.danglingReferenceCount = 0,
    this.uniqueRelationshipIdsCount = 0,
    this.loadedPackIds = const [],
  }) : byId = UnmodifiableMapView(byId),
       byCatalog = UnmodifiableMapView(
         byCatalog.map((k, v) => MapEntry(k, UnmodifiableListView(v))),
       ),
       searchProfiles = UnmodifiableMapView(searchProfiles),
       queryExpansions = UnmodifiableMapView(queryExpansions),
       schemeIdMap = UnmodifiableMapView(schemeIdMap),
       _searchTokenMap = searchTokenMap;

  static MssCatalogBundle? _instance;
  static String? get loadedReleaseTag => _instance?.releaseTag;
  static Future<MssCatalogBundle>? _loadFuture;

  /// Highest `manifest.bundleFormat` this build understands. A bundle with a
  /// newer format is rejected with a clear message instead of being misread.
  static const int supportedBundleFormat = 3;

  /// The core catalog file; its manifest lists the jurisdiction packs that sit
  /// beside it in [catalogAssetDir].
  static const String catalogAssetDir = 'assets/catalog';
  static const String coreAssetPath = '$catalogAssetDir/catalog_core.json.gz';
  static const String queryExpansionAssetPath =
      'assets/search/query_expansion.json';

  final Map<String, MssEntity> byId;
  final Map<String, List<MssEntity>> byCatalog;
  final Map<String, Set<String>> _searchTokenMap;

  /// Raw search_index.json entries for `entityType == 'scheme'`, keyed by
  /// entityId. Carries `tokens.{en,ta}` and `schemeSearchProfile` -- the
  /// exact fields the ranking algorithm in [HybridSchemeSearch] consumes,
  /// mirroring what `catalog/hybrid_search.py` reads from the same file.
  final Map<String, Map<String, dynamic>> searchProfiles;

  /// Query expansion dictionary loaded from `assets/search/query_expansion.json`.
  /// Maps query tokens/phrases to lists of catalog-vocabulary-verified
  /// expansion terms. Used by [HybridSchemeSearch] to expand queries at
  /// search time without an async gap.
  final Map<String, List<String>> queryExpansions;

  final String releaseTag;

  /// When this catalog release was published (`manifest.release.releasedAt`).
  /// Null only if the field is absent/unparsable.
  final DateTime? releasedAt;

  /// The bundle's embedded manifest (`manifest.json` section): release
  /// identity, language list/registry and per-section record counts.
  final Map<String, dynamic> manifest;

  /// Pre-2026 scheme id (or legacy code) -> current id, from the embedded
  /// `migrations.json` section. Used to carry saved items across releases.
  final Map<String, String> schemeIdMap;

  /// Languages present in the catalog data, with whether the release has them
  /// switched on (`manifest.languages`: `[{code, isActive}]`). This is the
  /// kill switch for offering a language.
  List<({String code, bool isActive})> get languages {
    final raw = manifest['languages'];
    if (raw is List) {
      return [
        for (final item in raw)
          if (item is Map && item['code'] is String)
            (code: item['code'] as String, isActive: item['isActive'] == true),
      ];
    }
    return const [];
  }

  /// Whether the release lists [code] as active.
  bool isLanguageActive(String code) =>
      languages.any((l) => l.code == code && l.isActive);

  /// Scheme-content languages offered for a jurisdiction (`central`,
  /// `tamil_nadu`, `maharashtra`, ...), from `manifest.languageRegistry`.
  /// Languages present in the data but not offered (e.g. Marathi) are omitted.
  List<String> offeredLanguagesFor(String jurisdiction) {
    final reg = manifest['languageRegistry'];
    final jurisdictions = reg is Map ? reg['jurisdictions'] : null;
    final entry = jurisdictions is Map ? jurisdictions[jurisdiction] : null;
    final offered = entry is Map ? entry['offeredLanguages'] : null;
    return offered is List ? offered.whereType<String>().toList() : const [];
  }

  /// Jurisdiction packs merged into this catalog (`central`, `tamil_nadu`...).
  /// A pack listed in the manifest but not installed on the device is absent.
  final List<String> loadedPackIds;

  /// Every jurisdiction pack the release lists, installed or not.
  List<CatalogPackInfo> get availablePacks => CatalogPacks.listed(manifest);

  final int totalRelationshipsCount;
  final int duplicateEntityIdCount;
  final int danglingReferenceCount;
  final int uniqueRelationshipIdsCount;

  /// Total count of catalog entities across all catalogs.
  int get totalEntitiesCount => byId.length;

  /// Helper to get all scheme entities.
  List<MssEntity> get schemes => byCatalog['scheme'] ?? const [];

  /// Get a single entity by ID in O(1) time.
  MssEntity? getEntity(String id) => byId[id];

  /// Get all entities for a catalog type (e.g. 'scheme', 'authority', 'finance').
  List<MssEntity> getCatalog(String catalogName) =>
      byCatalog[catalogName] ?? const [];

  /// Asynchronous lazy singleton loader.
  /// Guarantees catalog_bundle.json.gz is loaded, verified, and decompressed ONCE.
  static Future<MssCatalogBundle> load({bool overrideChecksumForTest = false}) {
    if (_instance != null) return Future.value(_instance!);
    return _loadFuture ??= _loadInternal(
      overrideChecksumForTest: overrideChecksumForTest,
    );
  }

  /// Drops the cached bundle so the next [load] call re-reads from disk
  /// instead of returning the in-memory singleton. Without this, a
  /// successful background catalog sync (SchemeCatalogSyncService installing
  /// a new release) would never actually become visible in a running app
  /// session -- [load] would keep returning the bundle built from whatever
  /// was on disk at first load, until the process fully restarts. Called
  /// from [SchemeRepository.clearCache] after a confirmed sync.
  static void invalidate() {
    _instance = null;
    _loadFuture = null;
  }

  /// Reset instance (for testing checksum exceptions).
  @visibleForTesting
  static void resetForTesting() => invalidate();

  /// Loads the query expansion dictionary from the bundled JSON asset.
  /// Returns an empty map on any failure so the search engine degrades
  /// gracefully (no expansion) instead of crashing.
  static Future<Map<String, List<String>>> _loadQueryExpansions() async {
    try {
      final jsonStr = await rootBundle.loadString(queryExpansionAssetPath);
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      return raw.map(
        (k, v) => MapEntry(k.toLowerCase(), (v as List).cast<String>()),
      );
    } catch (_) {
      // Fallback for flutter test / missing asset — try direct file read.
      try {
        final file = File(queryExpansionAssetPath);
        if (await file.exists()) {
          final raw =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          return raw.map(
            (k, v) => MapEntry(k.toLowerCase(), (v as List).cast<String>()),
          );
        }
      } catch (_) {
        // Intentionally empty — fall through to empty map.
      }
    }
    return const <String, List<String>>{};
  }

  static Future<MssCatalogBundle> _loadInternal({
    bool overrideChecksumForTest = false,
  }) async {
    String? releaseJsonStr;
    Uint8List compressedBytes;

    // Load the query expansion dictionary in parallel with the catalog
    // bundle. This is a tiny JSON file (~2 KB) so load time is negligible.
    final expansionsFuture = _loadQueryExpansions();

    // Prefer a downloaded, hash-verified release over the shipped asset, if
    // one has been installed by SchemeCatalogSyncService -- see
    // docs/specs/CATALOG_SPECIFICATIONS.md (Part 5).
    // The installed release's own SHA-256 was already verified at install
    // time (SchemeCatalogStore.install); re-verifying here too costs little
    // and guards against on-disk corruption between install and load.
    //
    // Skipped entirely under `flutter test`: path_provider has no platform
    // channel implementation there, so this would otherwise throw
    // MissingPluginException on every load -- caught further down, but the
    // exception itself is expensive enough to blow performance-sensitive
    // test budgets for no benefit (tests never have an installed release).
    final isTestEnvironment = Platform.environment['FLUTTER_TEST'] == 'true';
    final installed = isTestEnvironment
        ? null
        : await SchemeCatalogStore.instance.resolveActive();
    if (installed != null) {
      try {
        final releaseFile = File(installed.releaseJsonPath);
        final bundleFile = File(installed.bundlePath);
        releaseJsonStr = await releaseFile.readAsString();
        compressedBytes = await bundleFile.readAsBytes();
        final expected = installed.manifest.sha256.toLowerCase();
        final actual = sha256.convert(compressedBytes).toString().toLowerCase();
        if (actual != expected) {
          throw Exception(
            'Installed catalog release failed re-verification '
            '(expected $expected, got $actual) -- falling back to the '
            'shipped asset.',
          );
        }
        debugPrint(
          '[MssCatalogBundle] Loaded installed release '
          '${installed.manifest.releaseVersion ?? installed.manifest.id} '
          'from ${installed.bundlePath}',
        );
        return await _finishLoading(
          releaseJsonStr,
          compressedBytes,
          queryExpansions: await expansionsFuture,
          overrideChecksumForTest: overrideChecksumForTest,
          requireEmbeddedManifest: true,
          shippedPackReader: _assetPackReader,
        );
      } catch (e) {
        // Never let a corrupted/unreadable installed release block startup
        // -- fall through to the bundled asset, which is always known-good.
        debugPrint(
          '[MssCatalogBundle] Installed release unusable ($e); '
          'falling back to the shipped asset.',
        );
      }
    }

    // The shipped asset is a single self-describing file: its release
    // identity, record counts and language list are in the embedded manifest.
    try {
      final ByteData bundleByteData = await rootBundle.load(coreAssetPath);
      compressedBytes = bundleByteData.buffer.asUint8List(
        bundleByteData.offsetInBytes,
        bundleByteData.lengthInBytes,
      );
    } catch (_) {
      // Fallback for Flutter unit test environment where rootBundle asset bundle is uninitialized
      final bundleFile = File(coreAssetPath);
      compressedBytes = await bundleFile.readAsBytes();
    }
    releaseJsonStr = null;

    return _finishLoading(
      releaseJsonStr,
      compressedBytes,
      queryExpansions: await expansionsFuture,
      overrideChecksumForTest: overrideChecksumForTest,
      packReader: _assetPackReader,
    );
  }

  static const List<String> _shippedPackFiles = [
    'catalog_central.json.gz',
    'catalog_maharashtra.json.gz',
    'catalog_tamil_nadu.json.gz',
  ];

  /// Gives a server release the languages only the shipped packs have, see
  /// `catalog_language_fill.dart`. A failure leaves the release as published.
  static Future<void> _fillAbsentLanguages(
    Map<String, dynamic> bundleJson,
    CatalogPackReader reader,
  ) async {
    try {
      final absent = languagesAbsentFrom(bundleJson, [
        for (final locale in AppLocalizations.supportedLocales)
          locale.languageCode,
      ]);
      for (final file in _shippedPackFiles) {
        final bytes = await reader(file);
        if (bytes == null) continue;
        final pack = await compute(_decompressAndParseJson, bytes);
        fillLanguagesFromPack(bundleJson, pack, absent);
        fillDocumentsFromPack(bundleJson, pack);
      }
    } catch (e) {
      debugPrint('[MssCatalogBundle] Language fill skipped: $e');
    }
  }

  /// Reads a pack shipped beside the core file; null when it was dropped.
  static Future<Uint8List?> _assetPackReader(String file) async {
    final path = '$catalogAssetDir/$file';
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      // Flutter unit tests have no asset bundle: read the file directly.
      final f = File(path);
      return await f.exists() ? await f.readAsBytes() : null;
    }
  }

  /// [releaseJsonStr] is only supplied for a downloaded release, whose
  /// `release.json` (written at install time) carries the SHA-256 the server
  /// published. The shipped asset is checked against its own embedded manifest.
  static Future<MssCatalogBundle> _finishLoading(
    String? releaseJsonStr,
    Uint8List compressedBytes, {
    Map<String, List<String>> queryExpansions = const <String, List<String>>{},
    bool overrideChecksumForTest = false,
    bool registerAsSingleton = true,
    bool requireEmbeddedManifest = false,
    CatalogPackReader? packReader,
    CatalogPackReader? shippedPackReader,
  }) async {
    final releaseJson = releaseJsonStr == null
        ? const <String, dynamic>{}
        : jsonDecode(releaseJsonStr) as Map<String, dynamic>;

    if (releaseJsonStr != null) {
      final expectedChecksum =
          (releaseJson['bundleSha256'] as String?)?.toLowerCase() ?? '';
      final actualChecksum = sha256
          .convert(compressedBytes)
          .toString()
          .toLowerCase();
      if (!overrideChecksumForTest && actualChecksum != expectedChecksum) {
        throw Exception(
          'Catalog bundle SHA-256 checksum mismatch. Expected: $expectedChecksum, Got: $actualChecksum',
        );
      }
    }

    // Offload gzip decompression & JSON decode to isolate via compute()
    final Map<String, dynamic> bundleJson = await compute(
      _decompressAndParseJson,
      compressedBytes,
    );

    final manifest = _embeddedManifest(bundleJson);
    _checkCompatibility(manifest);
    if (requireEmbeddedManifest) {
      // The server publishes ONE gzip holding every scheme (the admin site
      // regenerates it on each change). It carries no packs and may predate the
      // pack layout: schemes name their own jurisdiction, so the app wires them
      // by state after loading. Only an empty schemes section is refused.
      final schemes = bundleJson['scheme_catalog.json'];
      final rows = schemes is Map ? schemes['data'] : null;
      if (rows is! List || rows.isEmpty) {
        throw StateError('Installed release has no schemes.');
      }
    }
    if (shippedPackReader != null) {
      await _fillAbsentLanguages(bundleJson, shippedPackReader);
    }
    var loadedPackIds = const <String>[];
    if (packReader != null) {
      loadedPackIds = (await CatalogPacks.mergeInto(
        bundleJson,
        manifest,
        packReader,
        (bytes) => compute(_decompressAndParseJson, bytes),
      )).loaded;
    }
    final releaseInfo = manifest['release'] is Map
        ? (manifest['release'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final releaseTag =
        (releaseInfo['releaseTag'] as String?) ??
        (releaseJson['releaseTag'] as String?) ??
        (manifest['catalogRelease'] as String?) ??
        'unknown';
    final releasedAt = DateTime.tryParse(
      (releaseInfo['releasedAt'] as String?) ??
          (releaseJson['releasedAt'] as String?) ??
          '',
    );

    final byId = <String, MssEntity>{};
    final byCatalog = <String, List<MssEntity>>{};
    final searchTokenMap = <String, Set<String>>{};
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
      if (catalogObject == null) continue;

      final catalogName =
          (catalogObject['metadata']?['catalogName'] as String?) ??
          fileKey.replaceAll('_catalog.json', '');

      final dataList = catalogObject['data'] as List?;
      if (dataList == null) continue;

      final entityList = <MssEntity>[];

      for (final rawItem in dataList) {
        if (rawItem is! Map<String, dynamic>) continue;
        final entity = MssEntity.fromJson(rawItem);
        if (entity.id.isEmpty) continue;

        if (seenEntityIds.contains(entity.id)) {
          duplicateEntityIdCount++;
        } else {
          seenEntityIds.add(entity.id);
        }

        byId[entity.id] = entity;
        entityList.add(entity);

        // Count relationships
        totalRels += entity.references.length;

        // Index multilingual search tokens
        _indexSearchTokens(entity, searchTokenMap);
      }

      byCatalog[catalogName] = entityList;
    }

    // search_index.json carries tokens.{en,ta} + schemeSearchProfile per
    // scheme -- not indexed into byId/byCatalog (it's a flat search-only
    // projection, not a full entity), but kept for HybridSchemeSearch.
    final searchProfiles = <String, Map<String, dynamic>>{};
    final searchIndexObject =
        bundleJson['search_index.json'] as Map<String, dynamic>?;
    final searchIndexData = searchIndexObject?['data'] as List?;
    if (searchIndexData != null) {
      for (final rawItem in searchIndexData) {
        if (rawItem is! Map<String, dynamic>) continue;
        if (rawItem['entityType'] != 'scheme') continue;
        final entityId = rawItem['entityId'] as String?;
        if (entityId == null || entityId.isEmpty) continue;
        searchProfiles[entityId] = rawItem;
      }
    }

    // Graph integrity verification pass: check dangling references
    int danglingReferenceCount = 0;
    final seenRelIds = <String>{};
    for (final entity in byId.values) {
      for (final ref in entity.references) {
        final relId = ref['relationshipId'] as String? ?? ref['id'] as String?;
        if (relId != null && relId.isNotEmpty) {
          seenRelIds.add(relId);
        }
        final targetId =
            ref['targetId'] as String? ?? ref['target_id'] as String?;
        if (targetId != null &&
            targetId.isNotEmpty &&
            !byId.containsKey(targetId)) {
          danglingReferenceCount++;
        }
      }
    }

    _checkRecordCounts(manifest, bundleJson);

    final built = MssCatalogBundle._(
      byId: byId,
      byCatalog: byCatalog,
      searchTokenMap: searchTokenMap,
      searchProfiles: searchProfiles,
      queryExpansions: queryExpansions,
      releaseTag: releaseTag,
      releasedAt: releasedAt,
      manifest: manifest,
      schemeIdMap: _schemeIdMap(bundleJson),
      totalRelationshipsCount: totalRels,
      duplicateEntityIdCount: duplicateEntityIdCount,
      danglingReferenceCount: danglingReferenceCount,
      uniqueRelationshipIdsCount: seenRelIds.length,
      loadedPackIds: loadedPackIds,
    );
    if (registerAsSingleton) _instance = built;
    return built;
  }

  /// Largest uncompressed catalog a download may expand to.
  static const int maxDownloadedBytes = 256 * 1024 * 1024;

  /// Checks a downloaded single-file release BEFORE it is installed: it must
  /// decompress within [maxDownloadedBytes], parse, be a format this app reads,
  /// pass its own record counts and hold at least one scheme. Throws otherwise,
  /// so a bad release never replaces the working catalog.
  static Future<void> validateDownload(Uint8List gzipBytes) async {
    final parsed = await compute(_decompressAndParseJson, gzipBytes);
    final manifest = _embeddedManifest(parsed);
    _checkCompatibility(manifest);
    final schemes = parsed['scheme_catalog.json'];
    final rows = schemes is Map ? schemes['data'] : null;
    if (rows is! List || rows.isEmpty) {
      throw StateError('Downloaded release has no schemes.');
    }
    _checkRecordCounts(manifest, parsed);
  }

  /// Parses [gzipBytes] exactly as the loader does (decompress, decode,
  /// compatibility and record-count checks) without touching the loaded
  /// singleton. For tests of the failure paths.
  @visibleForTesting
  static Future<MssCatalogBundle> parseBytesForTest(
    Uint8List gzipBytes, {
    CatalogPackReader? packReader,
  }) => _finishLoading(
    null,
    gzipBytes,
    registerAsSingleton: false,
    packReader: packReader,
  );

  /// The `manifest.json` section's single record, or `{}` for a bundle that
  /// predates the embedded manifest.
  static Map<String, dynamic> _embeddedManifest(Map<String, dynamic> bundle) {
    final section = bundle['manifest.json'];
    final data = section is Map ? section['data'] : null;
    if (data is List && data.isNotEmpty && data.first is Map) {
      return (data.first as Map).cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }

  /// Rejects a bundle written by a newer build than this app understands, with
  /// a message that says why, instead of silently misreading it.
  static void _checkCompatibility(Map<String, dynamic> manifest) {
    final format = manifest['bundleFormat'];
    if (format is int && format > supportedBundleFormat) {
      throw UnsupportedError(
        'Catalog bundle format $format is newer than this app supports '
        '($supportedBundleFormat). Update the app to use this catalog release.',
      );
    }
  }

  /// Every section the manifest counts must have exactly that many records, so
  /// a truncated or partially written bundle is an error, never an empty catalog.
  static void _checkRecordCounts(
    Map<String, dynamic> manifest,
    Map<String, dynamic> bundle,
  ) {
    final counts = manifest['recordCounts'];
    if (counts is! Map) return;
    final mismatches = <String>[];
    counts.forEach((section, expected) {
      final body = bundle[section];
      final data = body is Map ? body['data'] : null;
      final actual = data is List ? data.length : -1;
      if (expected is int && actual != expected) {
        mismatches.add('$section: expected $expected, found $actual');
      }
      // The section's own metadata must agree with its data too.
      final declared = body is Map && body['metadata'] is Map
          ? (body['metadata'] as Map)['recordCount']
          : null;
      if (declared is int && declared != actual) {
        mismatches.add(
          '$section: metadata.recordCount $declared, found $actual',
        );
      }
    });
    if (mismatches.isNotEmpty) {
      throw StateError(
        'Catalog bundle failed its own record-count check: '
        '${mismatches.join('; ')}',
      );
    }
  }

  static Map<String, String> _schemeIdMap(Map<String, dynamic> bundle) {
    final section = bundle['migrations.json'];
    final raw = section is Map ? section['schemeIdMap'] : null;
    if (raw is! Map) return const <String, String>{};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  }

  static void _indexSearchTokens(
    MssEntity entity,
    Map<String, Set<String>> tokenMap,
  ) {
    final searchObj = entity.raw['search'] as Map<String, dynamic>?;
    final tokensObj = searchObj?['tokens'] as Map<String, dynamic>?;
    final keywordsObj = searchObj?['keywords'] as Map<String, dynamic>?;

    final tokenSet = <String>{};

    void addTokens(dynamic list) {
      if (list is List) {
        for (final item in list) {
          if (item is String && item.trim().isNotEmpty) {
            tokenSet.add(item.toLowerCase().trim());
          }
        }
      }
    }

    if (tokensObj != null) {
      addTokens(tokensObj['en']);
      addTokens(tokensObj['ta']);
    }
    if (keywordsObj != null) {
      addTokens(keywordsObj['en']);
      addTokens(keywordsObj['ta']);
    }

    // Add name tokens as fallback
    final nameEn = entity.getLocalizedName('en');
    final nameTa = entity.getLocalizedName('ta');
    for (final word in nameEn.split(RegExp(r'\s+'))) {
      if (word.trim().isNotEmpty) tokenSet.add(word.toLowerCase().trim());
    }
    for (final word in nameTa.split(RegExp(r'\s+'))) {
      if (word.trim().isNotEmpty) tokenSet.add(word.toLowerCase().trim());
    }

    for (final token in tokenSet) {
      tokenMap.putIfAbsent(token, () => <String>{}).add(entity.id);
    }
  }

  /// O(token lookup) Multilingual search across English and Tamil tokens.
  /// UI language controls display only, never matching.
  List<MssEntity> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return schemes;

    final matchingIds = <String>{};
    final queryTokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);

    for (final token in queryTokens) {
      for (final entry in _searchTokenMap.entries) {
        if (entry.key.contains(token)) {
          matchingIds.addAll(entry.value);
        }
      }
    }

    final results = <MssEntity>[];
    for (final id in matchingIds) {
      final entity = byId[id];
      if (entity != null && entity.entityType == 'scheme') {
        results.add(entity);
      }
    }

    return results;
  }

  // ── Graph Relationship Resolution Extensions ───────────────────────

  /// Resolves all forward linked entities declared in [entity.references]
  /// with optional filtering by [targetType] and [relationType].
  List<MssEntity> getLinkedEntities(
    MssEntity entity, {
    String? targetType,
    String? relationType,
  }) {
    final results = <MssEntity>[];
    final seenIds = <String>{};

    for (final ref in entity.references) {
      final tId =
          (ref['entityId'] ?? ref['targetId'] ?? ref['target_id'] ?? ref['id'])
              ?.toString();
      if (tId == null || tId.isEmpty || seenIds.contains(tId)) continue;

      final relType = (ref['relationType'] ?? ref['type'] ?? '')
          .toString()
          .toLowerCase();
      final refType = (ref['entityType'] ?? ref['targetType'] ?? '')
          .toString()
          .toLowerCase();

      if (relationType != null && relationType.isNotEmpty) {
        if (!relType.contains(relationType.toLowerCase())) continue;
      }

      final target = getEntity(tId);
      if (target == null) continue;

      final actualType = target.entityType.toLowerCase();
      if (targetType != null && targetType.isNotEmpty) {
        final expectedType = targetType.toLowerCase();
        if (actualType != expectedType && refType != expectedType) continue;
      }

      seenIds.add(tId);
      results.add(target);
    }

    return results;
  }

  /// Resolves reverse linked entities in [catalogName] pointing to [targetSchemeId].
  List<MssEntity> getReverseLinkedEntities(
    String targetSchemeId,
    String catalogName,
  ) {
    final results = <MssEntity>[];
    final entities = getCatalog(catalogName);

    for (final e in entities) {
      bool matches = false;
      final content = e.content;
      if (content['schemeId']?.toString() == targetSchemeId) {
        matches = true;
      }
      if (!matches && content['evidencedInSchemes'] is List) {
        final list = (content['evidencedInSchemes'] as List).map(
          (x) => x.toString(),
        );
        if (list.contains(targetSchemeId)) matches = true;
      }
      if (!matches) {
        for (final ref in e.references) {
          final tId =
              (ref['entityId'] ??
                      ref['targetId'] ??
                      ref['target_id'] ??
                      ref['id'])
                  ?.toString();
          if (tId == targetSchemeId) {
            matches = true;
            break;
          }
        }
      }
      if (matches) results.add(e);
    }
    return results;
  }

  /// Resolve authorities administering or linked to a scheme entity.
  List<MssEntity> getAuthoritiesForScheme(MssEntity scheme) {
    return getLinkedEntities(scheme, targetType: 'authority');
  }

  /// Resolve institutions implementing or linked to a scheme entity.
  List<MssEntity> getInstitutionsForScheme(MssEntity scheme) {
    return getLinkedEntities(scheme, targetType: 'institution');
  }

  /// Resolve finance products linked forward or reverse to a scheme entity.
  List<MssEntity> getFinanceProductsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'finance_product');
    final reverse = getReverseLinkedEntities(scheme.id, 'finance');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve tax provisions linked forward or reverse to a scheme entity.
  List<MssEntity> getTaxProvisionsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'tax_provision');
    final reverse = getReverseLinkedEntities(scheme.id, 'tax');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve export benefits linked forward or reverse to a scheme entity.
  List<MssEntity> getExportBenefitsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'export_benefit');
    final reverse = getReverseLinkedEntities(scheme.id, 'export');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve CSR provisions linked forward or reverse to a scheme entity.
  List<MssEntity> getCsrProvisionsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'csr_provision');
    final reverse = getReverseLinkedEntities(scheme.id, 'csr');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve TReDS platforms linked forward or reverse to a scheme entity.
  List<MssEntity> getTredsPlatformsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'treds_platform');
    final reverse = getReverseLinkedEntities(scheme.id, 'treds');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  /// Resolve knowledge items linked forward or reverse to a scheme entity.
  List<MssEntity> getKnowledgeItemsForScheme(MssEntity scheme) {
    final forward = getLinkedEntities(scheme, targetType: 'knowledge_item');
    final reverse = getReverseLinkedEntities(scheme.id, 'knowledge');
    final map = <String, MssEntity>{};
    for (final e in [...forward, ...reverse]) {
      map[e.id] = e;
    }
    return map.values.toList();
  }
}
