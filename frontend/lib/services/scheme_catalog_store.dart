import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/catalog_manifest.dart';

enum SchemeCatalogSource { bundled, cached }

class StoredSchemeCatalog {
  const StoredSchemeCatalog({
    required this.source,
    required this.manifest,
    required this.bundlePath,
    required this.releaseJsonPath,
  });
  final SchemeCatalogSource source;
  final CatalogManifest manifest;

  /// Absolute path to the installed `catalog_bundle.json.gz`, for
  /// [MssCatalogBundle] to load in place of the shipped asset.
  final String bundlePath;

  /// Absolute path to a `release.json`-shaped file describing [bundlePath],
  /// for [MssCatalogBundle]'s existing manifest-parsing logic to reuse
  /// unchanged.
  final String releaseJsonPath;
}

/// Real on-device persistence for downloaded catalog releases, per
/// docs/handoff/architecture_docs/UPDATE_FLOW_SPECIFICATION.md:
/// download to a versioned directory, verify SHA-256, and only then flip an
/// "active" pointer file -- so a failed or partial install can never corrupt
/// or replace a working installed release. The previously active release's
/// files are left on disk (not deleted) until a new install has fully
/// succeeded, matching the spec's rollback-safety requirement.
///
/// Replaces a prior stub of the same name that always returned null --
/// see UPDATE_FLOW_SPECIFICATION.md §6 for why that made the whole sync
/// mechanism a no-op end-to-end even when its data source worked.
class SchemeCatalogStore {
  SchemeCatalogStore();
  static final SchemeCatalogStore instance = SchemeCatalogStore();
  static const int supportedSchemaVersion = 1;

  static const String _rootDirName = 'mss_catalog_cache';
  static const String _activePointerFileName = 'active_manifest.json';
  static const String _bundleFileName = 'catalog_bundle.json.gz';
  static const String _manifestFileName = 'release.json';

  Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_rootDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _releaseDirName(CatalogManifest manifest) =>
      (manifest.releaseVersion?.isNotEmpty ?? false)
      ? manifest.releaseVersion!
      : manifest.id;

  Future<CatalogManifest?> readActiveManifest() async {
    try {
      final root = await _rootDir();
      final pointerFile = File('${root.path}/$_activePointerFileName');
      if (!await pointerFile.exists()) return null;
      final json =
          jsonDecode(await pointerFile.readAsString())
              as Map<String, dynamic>;
      final releaseDir = json['releaseDir'] as String?;
      final manifestJson = json['manifest'] as Map<String, dynamic>?;
      if (releaseDir == null || manifestJson == null) return null;

      // Confirm the bundle this pointer references still exists on disk --
      // a pointer with no backing file is not a valid active release.
      final bundlePath =
          '${root.path}/$releaseDir/$_bundleFileName';
      if (!await File(bundlePath).exists()) return null;

      return CatalogManifest.fromReleaseRpc(manifestJson);
    } catch (e) {
      debugPrint('[SchemeCatalogStore] readActiveManifest error: $e');
      return null;
    }
  }

  /// Downloads/writes [payload] (the release artifact's raw bytes) to a
  /// versioned directory, verifies its SHA-256 against [manifest].sha256,
  /// and -- only on success -- atomically flips the active pointer. Never
  /// touches or deletes the previously active release's files here; that is
  /// a separate, explicit cleanup step so a failed install can never leave
  /// the app without a working catalog.
  Future<StoredSchemeCatalog?> install(
    CatalogManifest manifest,
    Uint8List payload,
  ) async {
    final actualSha256 = sha256.convert(payload).toString().toLowerCase();
    if (actualSha256 != manifest.sha256.toLowerCase()) {
      throw Exception(
        'Catalog release SHA-256 mismatch. Expected: ${manifest.sha256}, '
        'Got: $actualSha256 -- refusing to install.',
      );
    }
    if (manifest.schemaVersion > supportedSchemaVersion) {
      throw UnsupportedError(
        'Release schema version ${manifest.schemaVersion} is newer than '
        'the schema version ($supportedSchemaVersion) this app build '
        'understands. Rejecting rather than attempting to parse it.',
      );
    }

    final root = await _rootDir();
    final releaseDirName = _releaseDirName(manifest);
    final targetDir = Directory('${root.path}/$releaseDirName');
    final tempDir = Directory('${root.path}/.tmp_$releaseDirName');

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);

    final tempBundleFile = File('${tempDir.path}/$_bundleFileName');
    await tempBundleFile.writeAsBytes(payload, flush: true);

    final releaseJsonContent = jsonEncode({
      'releaseTag': manifest.releaseVersion ?? manifest.id,
      'schemaVersion': manifest.schemaVersion.toString(),
      'bundleSha256': manifest.sha256,
      'bundleBytes': manifest.byteSize,
      'entityCount': manifest.schemeCount,
    });
    final tempManifestFile = File('${tempDir.path}/$_manifestFileName');
    await tempManifestFile.writeAsString(releaseJsonContent, flush: true);

    // Atomic-ish activation: move the fully-written temp directory into
    // place (rename is atomic on the same filesystem/volume), then update
    // the pointer file last, once the payload is guaranteed present.
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await tempDir.rename(targetDir.path);

    final pointerFile = File('${root.path}/$_activePointerFileName');
    final pointerContent = jsonEncode({
      'releaseDir': releaseDirName,
      'manifest': {
        'release_version': manifest.releaseVersion,
        'package_sha256': manifest.sha256,
        'package_byte_size': manifest.byteSize,
        'schema_version': manifest.schemaVersion,
        'record_counts': {'scheme_catalog.json': manifest.schemeCount},
        'published_at': manifest.publishedAt.toUtc().toIso8601String(),
      },
    });
    // Write-then-rename for the pointer too, so a crash mid-write can never
    // leave a half-written, unparseable pointer file behind.
    final pointerTemp = File('${root.path}/.tmp_$_activePointerFileName');
    await pointerTemp.writeAsString(pointerContent, flush: true);
    await pointerTemp.rename(pointerFile.path);

    debugPrint(
      '[SchemeCatalogStore] Installed release '
      '${manifest.releaseVersion ?? manifest.id} '
      '(${manifest.schemeCount} schemes, ${manifest.byteSize} bytes) '
      'at ${targetDir.path}',
    );

    return StoredSchemeCatalog(
      source: SchemeCatalogSource.cached,
      manifest: manifest,
      bundlePath: '${targetDir.path}/$_bundleFileName',
      releaseJsonPath: '${targetDir.path}/$_manifestFileName',
    );
  }

  /// Resolves the currently active installed release's file paths, if any
  /// (used by [MssCatalogBundle] to prefer a downloaded release over the
  /// shipped asset). Returns null if nothing has ever been installed, or if
  /// the pointer is stale/missing its backing files.
  Future<StoredSchemeCatalog?> resolveActive() async {
    final manifest = await readActiveManifest();
    if (manifest == null) return null;
    final root = await _rootDir();
    final releaseDirName = _releaseDirName(manifest);
    final bundlePath = '${root.path}/$releaseDirName/$_bundleFileName';
    final releaseJsonPath = '${root.path}/$releaseDirName/$_manifestFileName';
    if (!await File(bundlePath).exists() ||
        !await File(releaseJsonPath).exists()) {
      return null;
    }
    return StoredSchemeCatalog(
      source: SchemeCatalogSource.cached,
      manifest: manifest,
      bundlePath: bundlePath,
      releaseJsonPath: releaseJsonPath,
    );
  }
}
