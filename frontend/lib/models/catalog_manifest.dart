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
  /// MSS_ANTIGRAVITY_HANDOFF/architecture_docs/RELEASE_MANIFEST_SPECIFICATION.md.
  /// Null for manifests sourced from the legacy `public.catalog_releases`
  /// shape (kept for backward compatibility with [fromSupabase]).
  final String? releaseVersion;

  factory CatalogManifest.fromSupabase(Map<String, dynamic> row) {
    return CatalogManifest(
      id: row['id']?.toString() ?? '',
      version: (row['version'] as num?)?.toInt() ?? 0,
      schemaVersion: (row['schema_version'] as num?)?.toInt() ?? 0,
      sha256: row['sha256']?.toString() ?? '',
      byteSize: (row['byte_size'] as num?)?.toInt() ?? 0,
      schemeCount: (row['scheme_count'] as num?)?.toInt() ?? 0,
      documentCount: (row['document_count'] as num?)?.toInt() ?? 0,
      serviceCount: (row['service_count'] as num?)?.toInt() ?? 0,
      publishedAt:
          DateTime.tryParse(row['published_at']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// Builds from `public.mss_current_release()`'s row shape (the corrected
  /// Storage-based release architecture). `id`/`version` are synthesized
  /// (deterministic hash / release counter) since that RPC doesn't expose
  /// `admin.catalog_releases`'s internal uuid/bigint directly -- identity for
  /// comparison purposes is `releaseVersion` + `sha256`, not `id`/`version`.
  factory CatalogManifest.fromReleaseRpc(Map<String, dynamic> row) {
    final releaseVersion = row['release_version']?.toString() ?? '';
    final sha256 = row['package_sha256']?.toString() ?? '';
    final recordCounts = row['record_counts'] as Map<String, dynamic>? ?? {};
    final schemeCount =
        (recordCounts['scheme_catalog.json'] as num?)?.toInt() ?? 0;
    return CatalogManifest(
      id: sha256.isNotEmpty
          ? sha256.substring(0, 36.clamp(0, sha256.length)).padRight(36, '0')
          : '',
      version: (row['schema_version'] as num?)?.toInt() ?? 0,
      schemaVersion: (row['schema_version'] as num?)?.toInt() ?? 0,
      sha256: sha256,
      byteSize: (row['package_byte_size'] as num?)?.toInt() ?? 0,
      schemeCount: schemeCount,
      documentCount: 0,
      serviceCount: 0,
      publishedAt:
          DateTime.tryParse(row['published_at']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      releaseVersion: releaseVersion.isEmpty ? null : releaseVersion,
    );
  }

  factory CatalogManifest.fromJson(Map<String, dynamic> json) =>
      CatalogManifest.fromSupabase(json);

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
  /// falling back to [id] for manifests built via [fromSupabase] (legacy).
  bool sameReleaseAs(CatalogManifest? other) {
    if (other == null) return false;
    if (sha256 != other.sha256) return false;
    if (releaseVersion != null || other.releaseVersion != null) {
      return releaseVersion == other.releaseVersion;
    }
    return id == other.id;
  }
}
