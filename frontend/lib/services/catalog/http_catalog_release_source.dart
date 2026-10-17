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

  @override
  Future<CatalogManifest?> fetchCurrentManifest() async {
    try {
      final response = await _client.get(
        '/v1/catalog/releases/current',
        requiresAuth: false,
      );
      if (response.data == null || response.data is! Map<String, dynamic>) {
        return null;
      }
      final json = response.data as Map<String, dynamic>;
      if (json['release_version'] == null ||
          (json['package_sha256'] == null && json['sha256'] == null)) {
        return null;
      }
      return CatalogManifest.fromReleaseRpc(json);
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
      return CatalogManifest.fromReleaseRpc(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Uint8List> fetchPayload(CatalogManifest manifest) async {
    final path = manifest.bundleUrl ??
        (manifest.releaseVersion != null && manifest.releaseVersion!.isNotEmpty
            ? '/v1/catalog/releases/${manifest.releaseVersion}/bundle'
            : null);

    if (path == null) {
      throw StateError(
        'Cannot download release payload without a valid bundleUrl or releaseVersion.',
      );
    }

    // Allow a small overhead limit if manifest specified byteSize
    final maxBytes = manifest.byteSize > 0 ? (manifest.byteSize * 1.2).toInt() : null;

    final response = await _client.getBytes(
      path,
      maxByteSize: maxBytes,
    );

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
