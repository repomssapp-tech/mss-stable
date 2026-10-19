import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../models/catalog_manifest.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'scheme_catalog_sync_service.dart';

/// Catalog release source that queries the Node.js REST backend
/// (`/v1/catalog/releases/...`) and downloads gzip bundles with client-side
/// SHA-256 and byte-size verification.
class HttpCatalogReleaseSource implements CatalogReleaseSource {
  HttpCatalogReleaseSource({required ApiClient client}) : _client = client;

  final ApiClient _client;

  // Conditional requests: the ETag of the last answer and that answer (which
  // may be "nothing published"). Sent back as If-None-Match, so an unchanged
  // release is a bodyless 304 instead of a repeated download of the manifest.
  String? _etag;
  CatalogManifest? _cachedManifest;
  bool _hasCache = false;

  @override
  Future<CatalogManifest?> fetchCurrentManifest() async {
    try {
      // `GET /v1/catalog/current` answers 200 with one object, or 200 with
      // JSON `null` when nothing has been published (keep the shipped catalog).
      final conditional = _etag != null && _hasCache;
      final response = await _client.get(
        '/v1/catalog/current',
        requiresAuth: false,
        headers: conditional
            ? {'If-None-Match': _etag!, 'Cache-Control': 'max-age=0'}
            : null,
      );
      if (response.statusCode == 304 && conditional) return _cachedManifest;

      CatalogManifest? manifest;
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['release_version'] != null &&
          (data['package_sha256'] != null || data['sha256'] != null)) {
        manifest = CatalogManifest.fromReleaseRpc(data);
      }
      _etag = response.etag;
      _cachedManifest = manifest;
      _hasCache = true;
      return manifest;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Fetches a specific release manifest by its semantic version.
  Future<CatalogManifest?> fetchManifestByVersion(String version) async {
    try {
      final response = await _client.get(
        '/v1/catalog/releases/$version',
        requiresAuth: false,
      );
      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      }
      return CatalogManifest.fromReleaseRpc(
        response.data as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Uint8List> fetchPayload(CatalogManifest manifest) async {
    final path =
        manifest.bundleUrl ??
        (manifest.releaseVersion != null && manifest.releaseVersion!.isNotEmpty
            ? '/v1/catalog/releases/${manifest.releaseVersion}/bundle'
            : null);

    if (path == null) {
      throw StateError(
        'Cannot download release payload without a valid bundleUrl or releaseVersion.',
      );
    }
    // The server hands back an API-origin-relative path. Never follow an
    // absolute URL or anything outside the catalog routes: the download is
    // sent to this API's origin only.
    final uri = Uri.tryParse(path);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !path.startsWith('/v1/catalog/') ||
        path.contains('..')) {
      throw ApiException(
        statusCode: 400,
        errorCode: 'UNSAFE_BUNDLE_URL',
        message: 'The release bundle URL is not an API catalog path.',
      );
    }

    // Allow a small overhead limit if manifest specified byteSize
    final maxBytes = manifest.byteSize > 0
        ? (manifest.byteSize * 1.2).toInt()
        : null;

    final response = await _client.getBytes(path, maxByteSize: maxBytes);

    final bytes = response.data;

    // 1. Enforce byte size if manifest provides non-zero byteSize
    if (manifest.byteSize > 0 && bytes.length != manifest.byteSize) {
      throw ApiException(
        statusCode: 400,
        errorCode: 'BYTE_SIZE_MISMATCH',
        message:
            'Downloaded bundle size ${bytes.length} bytes does not match manifest ${manifest.byteSize} bytes',
      );
    }

    // 2. Enforce SHA-256 checksum over raw downloaded gzip bytes
    final computedSha256 = sha256.convert(bytes).toString().toLowerCase();
    if (computedSha256 != manifest.sha256.toLowerCase()) {
      throw ApiException(
        statusCode: 400,
        errorCode: 'CHECKSUM_MISMATCH',
        message:
            'Downloaded bundle SHA-256 ($computedSha256) does not match manifest (${manifest.sha256})',
      );
    }

    return bytes;
  }
}
