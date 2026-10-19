import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';

/// The catalog ships as a core file plus one pack per jurisdiction. These tests
/// load the real shipped files.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dir = MssCatalogBundle.catalogAssetDir;
  late Uint8List core;

  Future<Uint8List?> shipped(String file, {Set<String> drop = const {}}) async {
    if (drop.contains(file)) return null;
    final f = File('$dir/$file');
    return f.existsSync() ? await f.readAsBytes() : null;
  }

  setUpAll(() async {
    core = await File(MssCatalogBundle.coreAssetPath).readAsBytes();
  });

  test(
    'every jurisdiction pack loads and holds only its own schemes',
    () async {
      final bundle = await MssCatalogBundle.parseBytesForTest(
        core,
        packReader: shipped,
      );
      expect(bundle.loadedPackIds, ['central', 'maharashtra', 'tamil_nadu']);
      expect(bundle.availablePacks.map((p) => p.tenantId), [
        'central',
        'maharashtra',
        'tamil_nadu',
      ]);
      expect(bundle.schemes.length, 406);
      final byJurisdiction = <String, int>{};
      for (final s in bundle.schemes) {
        final j = (s.raw['provenance'] as Map)['jurisdiction'] as String;
        byJurisdiction[j] = (byJurisdiction[j] ?? 0) + 1;
      }
      for (final pack in bundle.availablePacks) {
        expect(
          byJurisdiction[pack.jurisdiction],
          pack.recordCounts['scheme_catalog.json'],
          reason: pack.id,
        );
      }
      expect(bundle.availablePacks.where((p) => p.required).map((p) => p.id), [
        'central',
      ]);
    },
  );

  test('a state pack that is not installed is left out cleanly', () async {
    final bundle = await MssCatalogBundle.parseBytesForTest(
      core,
      packReader: (f) => shipped(f, drop: {'catalog_tamil_nadu.json.gz'}),
    );
    expect(bundle.loadedPackIds, ['central', 'maharashtra']);
    expect(
      bundle.availablePacks.length,
      3,
      reason: 'still listed, to re-download',
    );
    expect(bundle.schemes.length, 406 - 53);
    expect(
      bundle.schemes.any(
        (s) => (s.raw['provenance'] as Map)['jurisdiction'] == 'tamil_nadu',
      ),
      isFalse,
    );
    expect(
      bundle.searchProfiles.keys.any((id) => id.startsWith('TN2026')),
      isFalse,
    );
    expect(bundle.getEntity('TN2026-001'), isNull);
    // Shared catalogs stay whole.
    expect(bundle.getCatalog('authority'), isNotEmpty);
  });

  test('a tampered pack is rejected', () async {
    final bytes = Uint8List.fromList(
      await File('$dir/catalog_maharashtra.json.gz').readAsBytes(),
    );
    bytes[bytes.length ~/ 2] ^= 0xff;
    expect(
      MssCatalogBundle.parseBytesForTest(
        core,
        packReader: (f) async =>
            f == 'catalog_maharashtra.json.gz' ? bytes : shipped(f),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('SHA-256'),
        ),
      ),
    );
  });

  test('a missing required pack is an error, not an empty catalog', () async {
    expect(
      MssCatalogBundle.parseBytesForTest(
        core,
        packReader: (f) => shipped(f, drop: {'catalog_central.json.gz'}),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('missing'),
        ),
      ),
    );
  });

  test('pack order does not change what the app sees', () async {
    final all = await MssCatalogBundle.parseBytesForTest(
      core,
      packReader: shipped,
    );
    final ids = all.schemes.map((s) => s.id).toList();
    expect(ids.take(3), ['CEN2026-001', 'CEN2026-002', 'CEN2026-003']);
    expect(ids.toSet().length, ids.length);
  });
}
