import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/catalog_manifest.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/catalog/http_catalog_release_source.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage tokenStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tokenStorage = TokenStorage(prefs);
  });

  group('HttpCatalogReleaseSource', () {
    test(
      'fetchCurrentManifest returns CatalogManifest when release is published',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/v1/catalog/current');
          return http.Response(
            jsonEncode({
              'release_version': '1.35.1-alpha',
              'schema_version': 1,
              'package_sha256':
                  'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
              'package_byte_size': 182743,
              'bundle_url': '/v1/catalog/releases/1.35.1-alpha/bundle',
              'published_at': '2026-10-15T12:00:00.000Z',
              'record_counts': {'scheme_catalog.json': 312},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org',
          httpClient: mockClient,
          tokenStorage: tokenStorage,
        );

        final source = HttpCatalogReleaseSource(client: apiClient);
        final manifest = await source.fetchCurrentManifest();

        expect(manifest, isNotNull);
        expect(manifest!.releaseVersion, '1.35.1-alpha');
        expect(manifest.schemaVersion, 1);
        expect(
          manifest.sha256,
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        );
        expect(manifest.byteSize, 182743);
        expect(manifest.schemeCount, 312);
        expect(manifest.bundleUrl, '/v1/catalog/releases/1.35.1-alpha/bundle');
      },
    );

    test(
      'fetchCurrentManifest returns null when nothing is published',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/v1/catalog/current');
          return http.Response(
            'null',
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final apiClient = ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org',
          httpClient: mockClient,
          tokenStorage: tokenStorage,
        );

        final manifest = await HttpCatalogReleaseSource(
          client: apiClient,
        ).fetchCurrentManifest();

        expect(manifest, isNull);
      },
    );

    for (final unsafe in [
      'https://evil.example/v1/catalog/releases/1.0.0/bundle',
      '//evil.example/v1/catalog/releases/1.0.0/bundle',
      '/v1/other/bundle',
      '/v1/catalog/../me/profile',
    ]) {
      test(
        'fetchPayload refuses a bundle URL outside the catalog API: $unsafe',
        () async {
          var requested = false;
          final apiClient = ApiClient(
            baseUrl: 'https://mssapi.msmeschemes.org',
            httpClient: MockClient((request) async {
              requested = true;
              return http.Response.bytes(Uint8List(0), 200);
            }),
            tokenStorage: tokenStorage,
          );
          final manifest = CatalogManifest(
            id: 'test-id',
            version: 1,
            schemaVersion: 1,
            sha256: 'a' * 64,
            byteSize: 10,
            schemeCount: 1,
            documentCount: 0,
            serviceCount: 0,
            publishedAt: DateTime.now().toUtc(),
            releaseVersion: '1.0.0',
            bundleUrl: unsafe,
          );

          await expectLater(
            HttpCatalogReleaseSource(client: apiClient).fetchPayload(manifest),
            throwsA(
              isA<ApiException>().having(
                (e) => e.errorCode,
                'errorCode',
                'UNSAFE_BUNDLE_URL',
              ),
            ),
          );
          expect(requested, isFalse);
        },
      );
    }

    test('fetchCurrentManifest returns null on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'NOT_FOUND', 'message': 'No releases available'},
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final source = HttpCatalogReleaseSource(client: apiClient);
      final manifest = await source.fetchCurrentManifest();

      expect(manifest, isNull);
    });

    test(
      'fetchPayload downloads, checks size and verifies SHA-256 successfully',
      () async {
        final sampleBytes = Uint8List.fromList(
          utf8.encode('test gzip bundle content'),
        );
        final expectedSha256 = sha256.convert(sampleBytes).toString();

        final manifest = CatalogManifest(
          id: 'test-id',
          version: 1,
          schemaVersion: 1,
          sha256: expectedSha256,
          byteSize: sampleBytes.length,
          schemeCount: 10,
          documentCount: 0,
          serviceCount: 0,
          publishedAt: DateTime.now().toUtc(),
          releaseVersion: '1.0.0',
          bundleUrl: '/v1/catalog/releases/1.0.0/bundle',
        );

        final mockClient = MockClient((request) async {
          expect(request.url.path, '/v1/catalog/releases/1.0.0/bundle');
          return http.Response.bytes(
            sampleBytes,
            200,
            headers: {'content-type': 'application/gzip'},
          );
        });

        final apiClient = ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org',
          httpClient: mockClient,
          tokenStorage: tokenStorage,
        );

        final source = HttpCatalogReleaseSource(client: apiClient);
        final payload = await source.fetchPayload(manifest);

        expect(payload, equals(sampleBytes));
      },
    );

    test('fetchPayload throws on byte size mismatch', () async {
      final sampleBytes = Uint8List.fromList(utf8.encode('short'));
      final manifest = CatalogManifest(
        id: 'test-id',
        version: 1,
        schemaVersion: 1,
        sha256: 'some-hash',
        byteSize: 9999, // Expecting 9999 bytes but received 5
        schemeCount: 10,
        documentCount: 0,
        serviceCount: 0,
        publishedAt: DateTime.now().toUtc(),
        releaseVersion: '1.0.0',
      );

      final mockClient = MockClient((request) async {
        return http.Response.bytes(sampleBytes, 200);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final source = HttpCatalogReleaseSource(client: apiClient);
      expect(
        () => source.fetchPayload(manifest),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'BYTE_SIZE_MISMATCH',
          ),
        ),
      );
    });

    test('fetchPayload throws on SHA-256 checksum mismatch', () async {
      final sampleBytes = Uint8List.fromList(utf8.encode('tampered data'));
      final manifest = CatalogManifest(
        id: 'test-id',
        version: 1,
        schemaVersion: 1,
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
        byteSize: sampleBytes.length,
        schemeCount: 10,
        documentCount: 0,
        serviceCount: 0,
        publishedAt: DateTime.now().toUtc(),
        releaseVersion: '1.0.0',
      );

      final mockClient = MockClient((request) async {
        return http.Response.bytes(sampleBytes, 200);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://mssapi.msmeschemes.org',
        httpClient: mockClient,
        tokenStorage: tokenStorage,
      );

      final source = HttpCatalogReleaseSource(client: apiClient);
      expect(
        () => source.fetchPayload(manifest),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'CHECKSUM_MISMATCH',
          ),
        ),
      );
    });
  });

  // Issue #143: `/v1/catalog/releases/:tag` returns the original camelCase
  // release.json, not the snake_case shape of `/v1/catalog/current`.
  group('fetchManifestByVersion', () {
    final bundle = Uint8List.fromList(utf8.encode('release bundle bytes'));
    final bundleSha = sha256.convert(bundle).toString();

    Map<String, dynamic> releaseJson({String? sha, int? bytes}) => {
      'releaseId': 'f85f512e-dbe5-4d8e-beb0-f64f94ef9fa9',
      'releaseTag': '1.35.1-alpha',
      'schemaVersion': '1.0.0',
      'releasedAt': '2026-10-05T00:23:52Z',
      'bundleAsset': 'assets/catalog/catalog_bundle.json.gz',
      'bundleBytes': bytes ?? bundle.length,
      'bundleSha256': sha ?? bundleSha,
      'uncompressedBytes': 9263455,
      'entityCount': 1131,
      'recordCounts': {'common_catalog.json': 344, 'scheme_catalog.json': 171},
    };

    HttpCatalogReleaseSource sourceFor(
      Object? Function(http.Request request) answer,
    ) {
      final mockClient = MockClient((request) async {
        final body = answer(request);
        if (body is Uint8List) return http.Response.bytes(body, 200);
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      return HttpCatalogReleaseSource(
        client: ApiClient(
          baseUrl: 'https://mssapi.msmeschemes.org',
          httpClient: mockClient,
          tokenStorage: tokenStorage,
        ),
      );
    }

    test('maps the camelCase release details', () async {
      final source = sourceFor((request) {
        expect(request.url.path, '/v1/catalog/releases/1.35.1-alpha');
        return releaseJson();
      });
      final manifest = await source.fetchManifestByVersion('1.35.1-alpha');

      expect(manifest, isNotNull);
      expect(manifest!.releaseVersion, '1.35.1-alpha');
      expect(manifest.sha256, bundleSha);
      expect(manifest.byteSize, bundle.length);
      expect(manifest.schemeCount, 171);
      expect(manifest.schemaVersion, 1); // "1.0.0" -> major 1
      expect(manifest.publishedAt, DateTime.utc(2026, 10, 5, 0, 23, 52));
      // bundleAsset is a source path, never a download URL.
      expect(manifest.bundleUrl, isNull);
      expect(manifest.isStructurallyValid, isTrue);
    });

    test('still accepts the snake_case shape', () async {
      final source = sourceFor(
        (_) => {
          'release_version': '1.35.1-alpha',
          'schema_version': 1,
          'package_sha256': bundleSha,
          'package_byte_size': bundle.length,
          'record_counts': {'scheme_catalog.json': 171},
          'bundle_url': '/v1/catalog/releases/1.35.1-alpha/bundle',
        },
      );
      final manifest = await source.fetchManifestByVersion('1.35.1-alpha');
      expect(manifest!.sha256, bundleSha);
      expect(manifest.byteSize, bundle.length);
      expect(manifest.schemeCount, 171);
    });

    test('rejects details without a checksum or size', () async {
      expect(
        await sourceFor(
          (_) => releaseJson(sha: ''),
        ).fetchManifestByVersion('1.35.1-alpha'),
        isNull,
      );
      expect(
        await sourceFor(
          (_) => releaseJson(bytes: 0),
        ).fetchManifestByVersion('1.35.1-alpha'),
        isNull,
      );
      expect(
        await sourceFor(
          (_) => {'unexpected': true},
        ).fetchManifestByVersion('1.35.1-alpha'),
        isNull,
      );
    });

    test('the parsed manifest downloads and verifies the bundle', () async {
      final source = sourceFor((request) {
        if (request.url.path.endsWith('/bundle')) {
          expect(request.url.path, '/v1/catalog/releases/1.35.1-alpha/bundle');
          return bundle;
        }
        return releaseJson();
      });
      final manifest = await source.fetchManifestByVersion('1.35.1-alpha');
      expect(await source.fetchPayload(manifest!), equals(bundle));
    });

    test('corrupted bytes are rejected', () async {
      final corrupted = Uint8List.fromList(bundle.reversed.toList());
      final source = sourceFor(
        (request) =>
            request.url.path.endsWith('/bundle') ? corrupted : releaseJson(),
      );
      final manifest = await source.fetchManifestByVersion('1.35.1-alpha');
      expect(
        () => source.fetchPayload(manifest!),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'CHECKSUM_MISMATCH',
          ),
        ),
      );
    });
  });
}
