import 'package:flutter/foundation.dart';

import '../../models/catalog_manifest.dart';
import '../network/api_client.dart';
import 'http_catalog_release_source.dart';
import 'mss_catalog_bundle.dart';
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

class SchemeCatalogSyncService {
  SchemeCatalogSyncService({
    CatalogReleaseSource? source,
    SchemeCatalogStore? store,
    Duration timeout = const Duration(seconds: 8),
    Duration throttle = const Duration(hours: 1),
    DateTime Function()? clock,
    Future<void> Function(Uint8List bytes)? validator,
  }) : _validator = validator ?? MssCatalogBundle.validateDownload,
       _source = source,
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
  final Future<void> Function(Uint8List bytes) _validator;
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
      return CatalogSyncResult(CatalogSyncOutcome.unchanged, manifest: local);
    }

    try {
      final payload = await _releaseSource
          .fetchPayload(remote)
          .timeout(_timeout);
      await _validator(payload);
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
