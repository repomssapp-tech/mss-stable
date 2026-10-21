class CatalogManifest {
  const CatalogManifest({
    required this.id,
    required this.version,
    required this.schemaVersion,
    required this.sha256,
    required this.byteSize,
    required this.schemeCount,
    required this.documentCount,
    required this.serviceCount,
    required this.publishedAt,
    this.releaseVersion,
    this.bundleUrl,
  });

  final String id;
  final int version;
  final int schemaVersion;
  final String sha256;
  final int byteSize;
  final int schemeCount;
  final int documentCount;
  final int serviceCount;
  final DateTime publishedAt;

  /// Semantic release identity (e.g. "1.33.0-alpha"), distinct from [version]
  /// (a bare sequence number) -- see
  /// docs/specs/CATALOG_SPECIFICATIONS.md (Part 3).
  final String? releaseVersion;

  /// Download path relative to API origin, e.g. "/v1/catalog/releases/1.35.1-alpha/bundle".
  final String? bundleUrl;

  /// Builds from `public.mss_current_release()`'s row shape (the corrected
  /// Storage-based release architecture) or REST `/v1/catalog/releases/current`.
  /// `id`/`version` are synthesized
  /// (deterministic hash / release counter) since that RPC doesn't expose
  /// `admin.catalog_releases`'s internal uuid/bigint directly -- identity for
  /// comparison purposes is `releaseVersion` + `sha256`, not `id`/`version`.
  factory CatalogManifest.fromReleaseRpc(Map<String, dynamic> row) {
    final releaseVersion = row['release_version']?.toString() ?? '';
    final sha256 =
        row['package_sha256']?.toString() ?? row['sha256']?.toString() ?? '';
    final rawCounts = row['record_counts'];
    final recordCounts = rawCounts is Map ? rawCounts : const {};
    final schemeCount =
        (recordCounts['scheme_catalog.json'] as num?)?.toInt() ??
        (row['scheme_count'] as num?)?.toInt() ??
        0;
    final bundleUrl = row['bundle_url']?.toString();
    return CatalogManifest(
      id: sha256.isNotEmpty
          ? sha256.substring(0, 36.clamp(0, sha256.length)).padRight(36, '0')
          : '',
      version:
          (row['schema_version'] as num?)?.toInt() ??
          (row['version'] as num?)?.toInt() ??
          0,
      schemaVersion: (row['schema_version'] as num?)?.toInt() ?? 0,
      sha256: sha256,
      byteSize:
          (row['package_byte_size'] as num?)?.toInt() ??
          (row['byte_size'] as num?)?.toInt() ??
          0,
      schemeCount: schemeCount,
      documentCount: (row['document_count'] as num?)?.toInt() ?? 0,
      serviceCount: (row['service_count'] as num?)?.toInt() ?? 0,
      publishedAt:
          DateTime.tryParse(row['published_at']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      releaseVersion: releaseVersion.isEmpty ? null : releaseVersion,
      bundleUrl: bundleUrl,
    );
  }

  /// Builds from `GET /v1/catalog/releases/:tag`, which returns the original
  /// immutable `release.json` with camelCase keys (`releaseTag`,
  /// `bundleSha256`, `bundleBytes`, `recordCounts`, `schemaVersion` as a
  /// semantic string such as "1.0.0", `releasedAt`) -- not the snake_case
  /// shape of `/v1/catalog/current` that [CatalogManifest.fromReleaseRpc]
  /// reads. Its `bundleAsset` is a source path, not a download URL, so
  /// [bundleUrl] stays null and the download uses the release-tag route.
  factory CatalogManifest.fromReleaseDetails(Map<String, dynamic> json) {
    final releaseVersion = json['releaseTag']?.toString().trim() ?? '';
    final sha256 = json['bundleSha256']?.toString().toLowerCase() ?? '';
    final rawCounts = json['recordCounts'];
    final recordCounts = rawCounts is Map ? rawCounts : const {};
    final schemaMajor = _schemaMajor(json['schemaVersion']);
    return CatalogManifest(
      id: sha256.isNotEmpty
          ? sha256.substring(0, 36.clamp(0, sha256.length)).padRight(36, '0')
          : '',
      version: schemaMajor,
      schemaVersion: schemaMajor,
      sha256: sha256,
      byteSize: (json['bundleBytes'] as num?)?.toInt() ?? 0,
      schemeCount: (recordCounts['scheme_catalog.json'] as num?)?.toInt() ?? 0,
      documentCount: 0,
      serviceCount: 0,
      publishedAt:
          DateTime.tryParse(json['releasedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      releaseVersion: releaseVersion.isEmpty ? null : releaseVersion,
    );
  }

  /// Major version of a `schemaVersion` given as a number (`1`) or a semantic
  /// string (`"1.0.0"`); 0 when it is missing or unreadable.
  static int _schemaMajor(Object? raw) {
    if (raw is num) return raw.toInt();
    final major = raw?.toString().trim().split('.').first ?? '';
    return int.tryParse(major) ?? 0;
  }

  factory CatalogManifest.fromJson(Map<String, dynamic> json) =>
      CatalogManifest.fromReleaseRpc(json);

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'schema_version': schemaVersion,
    'sha256': sha256,
    'byte_size': byteSize,
    'scheme_count': schemeCount,
    'document_count': documentCount,
    'service_count': serviceCount,
    'published_at': publishedAt.toUtc().toIso8601String(),
    if (releaseVersion != null) 'release_version': releaseVersion,
    if (bundleUrl != null) 'bundle_url': bundleUrl,
  };

  bool get isStructurallyValid =>
      RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256) &&
      byteSize > 0 &&
      schemeCount > 0 &&
      (releaseVersion != null
          ? releaseVersion!.isNotEmpty
          : RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id) &&
                version > 0 &&
                schemaVersion > 0);

  /// Identity comparison for sync purposes: two manifests represent the same
  /// installed release iff their release identity and content hash match.
  /// Uses [releaseVersion] when available (the corrected architecture),
  /// falling back to [id] otherwise.
  bool sameReleaseAs(CatalogManifest? other) {
    if (other == null) return false;
    if (sha256 != other.sha256) return false;
    if (releaseVersion != null || other.releaseVersion != null) {
      return releaseVersion == other.releaseVersion;
    }
    return id == other.id;
  }
}
