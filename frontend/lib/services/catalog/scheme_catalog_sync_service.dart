import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/catalog_manifest.dart';
import '../network/api_client.dart';
import 'http_catalog_release_source.dart';
import 'language_pack_manager.dart';
import 'scheme_catalog_store.dart';

enum CatalogSyncOutcome {
  unchanged,
  updated,
  offline,
  incompatible,
  rejected,
  throttled,
}

class CatalogSyncResult {
  const CatalogSyncResult(this.outcome, {this.manifest, this.message});

  final CatalogSyncOutcome outcome;
  final CatalogManifest? manifest;
  final String? message;

  bool get changed => outcome == CatalogSyncOutcome.updated;
}

class CatalogPackFile {
  const CatalogPackFile({
    required this.fileName,
    required this.byteSize,
    required this.checksum,
    required this.storagePath,
    required this.lang,
  });

  final String fileName;
  final int byteSize;
  final String checksum;
  final String storagePath;
  final String lang;

  factory CatalogPackFile.fromMap(Map<String, dynamic> row) {
    return CatalogPackFile(
      fileName: row['file_name']?.toString() ?? '',
      byteSize: (row['byte_size'] as num?)?.toInt() ?? 0,
      checksum: row['checksum']?.toString() ?? '',
      storagePath: row['storage_path']?.toString() ?? '',
      lang: row['lang']?.toString() ?? '',
    );
  }
}

abstract class CatalogReleaseSource {
  Future<CatalogManifest?> fetchCurrentManifest();
  Future<Uint8List> fetchPayload(CatalogManifest manifest);
  Future<List<CatalogPackFile>> fetchPacks();
  Future<Uint8List> downloadStorageFile(String storagePath);
}

/// Reads release identity from `public.mss_current_release()` and
/// downloads the release artifact from the `catalogs` Storage bucket,
/// under `releases/<releaseVersion>/catalog_bundle.json.gz`.
class SupabaseCatalogReleaseSource implements CatalogReleaseSource {
  SupabaseCatalogReleaseSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'catalogs';
  static const String _bundleFileName = 'catalog_bundle.json.gz';

  @override
  Future<CatalogManifest?> fetchCurrentManifest() async {
    final response = await _client.rpc('mss_current_release');
    final rows = response as List<dynamic>?;
    if (rows == null || rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    if (row['release_version'] == null || row['package_sha256'] == null) {
      return null;
    }
    return CatalogManifest.fromReleaseRpc(row);
  }

  @override
  Future<Uint8List> fetchPayload(CatalogManifest manifest) async {
    final releaseVersion = manifest.releaseVersion;
    if (releaseVersion == null || releaseVersion.isEmpty) {
      throw StateError(
        'Cannot download a release artifact without a releaseVersion.',
      );
    }
    final objectPath = 'releases/$releaseVersion/$_bundleFileName';
    return _client.storage.from(_bucket).download(objectPath);
  }

  @override
  Future<List<CatalogPackFile>> fetchPacks() async {
    try {
      final response = await _client.rpc('mss_current_release_packs');
      final rows = response as List<dynamic>?;
      if (rows == null || rows.isEmpty) return [];
      return rows
          .map((r) => CatalogPackFile.fromMap(r as Map<String, dynamic>))
          .where((p) => p.lang.isNotEmpty && p.storagePath.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[SupabaseCatalogReleaseSource] Error fetching packs: $e');
      return [];
    }
  }

  @override
  Future<Uint8List> downloadStorageFile(String storagePath) async {
    return _client.storage.from(_bucket).download(storagePath);
  }
}

class SchemeCatalogSyncService {
  SchemeCatalogSyncService({
    CatalogReleaseSource? source,
    SchemeCatalogStore? store,
    Duration timeout = const Duration(seconds: 8),
    Duration throttle = const Duration(hours: 1),
    DateTime Function()? clock,
  }) : _source = source,
       _store = store ?? SchemeCatalogStore.instance,
       _timeout = timeout,
       _throttle = throttle,
       _clock = clock ?? DateTime.now;

  static final SchemeCatalogSyncService instance = SchemeCatalogSyncService();

  CatalogReleaseSource? _source;
  final SchemeCatalogStore _store;
  final Duration _timeout;
  final Duration _throttle;
  final DateTime Function() _clock;
  DateTime? _lastCheck;
  Future<CatalogSyncResult>? _inFlight;

  CatalogReleaseSource get _releaseSource =>
      _source ??= HttpCatalogReleaseSource(client: ApiClient.instance);

  Future<CatalogSyncResult> syncIfNeeded({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final operation = _sync(force: force);
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<CatalogSyncResult> _sync({required bool force}) async {
    final now = _clock();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!) < _throttle) {
      return CatalogSyncResult(
        CatalogSyncOutcome.throttled,
        manifest: await _store.readActiveManifest(),
      );
    }
    _lastCheck = now;

    CatalogManifest? remote;
    try {
      remote = await _releaseSource.fetchCurrentManifest().timeout(_timeout);
    } catch (error) {
      return CatalogSyncResult(
        CatalogSyncOutcome.offline,
        manifest: await _store.readActiveManifest(),
        message: error.toString(),
      );
    }
    if (remote == null) {
      return CatalogSyncResult(
        CatalogSyncOutcome.unchanged,
        manifest: await _store.readActiveManifest(),
      );
    }
    if (remote.schemaVersion > SchemeCatalogStore.supportedSchemaVersion) {
      return CatalogSyncResult(
        CatalogSyncOutcome.incompatible,
        manifest: remote,
        message: 'A newer app version is required for this catalog.',
      );
    }

    final local = await _store.readActiveManifest();
    if (local != null && local.sameReleaseAs(remote)) {
      await _syncPacks();
      return CatalogSyncResult(CatalogSyncOutcome.unchanged, manifest: local);
    }

    try {
      final payload = await _releaseSource
          .fetchPayload(remote)
          .timeout(_timeout);
      await _store.install(remote, payload);
      await _syncPacks();
      return CatalogSyncResult(CatalogSyncOutcome.updated, manifest: remote);
    } on UnsupportedError catch (error) {
      return CatalogSyncResult(
        CatalogSyncOutcome.incompatible,
        manifest: remote,
        message: error.toString(),
      );
    } catch (error) {
      return CatalogSyncResult(
        CatalogSyncOutcome.rejected,
        manifest: local,
        message: error.toString(),
      );
    }
  }

  Future<void> _syncPacks() async {
    try {
      final packs = await _releaseSource.fetchPacks().timeout(_timeout);
      for (final pack in packs) {
        try {
          final packBytes = await _releaseSource
              .downloadStorageFile(pack.storagePath)
              .timeout(_timeout);
          final ok = await LanguagePackManager.instance.installPackBytes(
            lang: pack.lang,
            compressedBytes: packBytes,
            expectedSha256: pack.checksum,
          );
          if (!ok) {
            // Fall back to asset pack on failure
            await LanguagePackManager.instance.loadPack(pack.lang);
          }
        } catch (e) {
          debugPrint('[SchemeCatalogSyncService] Error downloading pack ${pack.lang}: $e');
          // Fall back to asset pack on failure
          await LanguagePackManager.instance.loadPack(pack.lang);
        }
      }
    } catch (e) {
      debugPrint('[SchemeCatalogSyncService] Error fetching packs: $e');
    }
  }
}

