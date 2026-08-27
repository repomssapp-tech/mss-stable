import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_manifest.dart';
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

abstract class CatalogReleaseSource {
  Future<CatalogManifest?> fetchCurrentManifest();
  Future<Uint8List> fetchPayload(CatalogManifest manifest);
}

/// Reads release identity from `public.mss_current_release()` (the
/// corrected, Storage-backed architecture -- see
/// MSS_ANTIGRAVITY_HANDOFF/architecture_docs/OFFLINE_CLOUD_SYNC_ARCHITECTURE.md)
/// and downloads the actual release artifact from the `catalogs` Storage
/// bucket, under `releases/<releaseVersion>/catalog_bundle.json.gz`.
///
/// Replaces a prior implementation that queried a `public.catalog_releases`
/// table from an earlier, superseded schema
/// (`20260730090000_catalog_releases.sql`, tied to a `public.schemes`
/// four-section-JSON format) that no longer exists in the live database --
/// see UPDATE_FLOW_SPECIFICATION.md §6 for the full history. That table is
/// not referenced here at all.
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
      _source ??= SupabaseCatalogReleaseSource(Supabase.instance.client);

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
      return CatalogSyncResult(CatalogSyncOutcome.unchanged, manifest: local);
    }

    try {
      final payload = await _releaseSource
          .fetchPayload(remote)
          .timeout(_timeout);
      await _store.install(remote, payload);
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
}
