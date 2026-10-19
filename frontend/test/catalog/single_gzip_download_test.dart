import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/catalog_manifest.dart';
import 'package:frontend/services/catalog/catalog_packs.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/scheme_catalog_store.dart';
import 'package:frontend/services/catalog/scheme_catalog_sync_service.dart';

/// The server publishes ONE gzip with every scheme in it. These tests build
/// that file from the shipped catalog (packs folded in, pack list removed) and
/// push it through download -> validate -> install, plus the bad-input cases.
class _FakeSource implements CatalogReleaseSource {
  _FakeSource(this.manifest, this.payload);
  CatalogManifest? manifest;
  Uint8List payload;
  int downloads = 0;

  @override
  Future<CatalogManifest?> fetchCurrentManifest() async => manifest;

  @override
  Future<Uint8List> fetchPayload(CatalogManifest m) async {
    downloads++;
    return payload;
  }
}

Uint8List _gz(Map<String, dynamic> json) =>
    Uint8List.fromList(GZipEncoder().encode(utf8.encode(jsonEncode(json)))!);

Map<String, dynamic> _clone(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

CatalogManifest _manifestFor(Uint8List gz, {String tag = '9.9.9', int? size}) =>
    CatalogManifest.fromReleaseRpc({
      'release_version': tag,
      'schema_version': 1,
      'package_sha256': sha256.convert(gz).toString(),
      'package_byte_size': size ?? gz.length,
      'record_counts': {'scheme_catalog.json': 406},
      'published_at': '2026-10-19T00:00:00Z',
      'bundle_url': '/v1/catalog/releases/$tag/bundle',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> single;
  late Directory root;
  late SchemeCatalogStore store;

  Map<String, dynamic> parse(Uint8List gz) =>
      jsonDecode(utf8.decode(GZipDecoder().decodeBytes(gz)))
          as Map<String, dynamic>;

  setUpAll(() async {
    final core = parse(
      await File(MssCatalogBundle.coreAssetPath).readAsBytes(),
    );
    final manifest =
        ((core['manifest.json'] as Map)['data'] as List).first as Map;
    await CatalogPacks.mergeInto(core, manifest.cast<String, dynamic>(), (
      file,
    ) async {
      final f = File('${MssCatalogBundle.catalogAssetDir}/$file');
      return f.existsSync() ? await f.readAsBytes() : null;
    }, (b) async => parse(b));
    // What the server's file looks like: no pack list, no bundleFormat.
    manifest.remove('packs');
    manifest.remove('bundleFormat');
    single = core;
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('mss_catalog_dl');
    store = SchemeCatalogStore(rootOverride: root);
  });
  tearDown(() => root.deleteSync(recursive: true));

  SchemeCatalogSyncService service(_FakeSource source) =>
      SchemeCatalogSyncService(
        source: source,
        store: store,
        throttle: Duration.zero,
      );

  Future<CatalogSyncResult> sync(Map<String, dynamic> bundle, {String? tag}) {
    final gz = _gz(bundle);
    return service(
      _FakeSource(_manifestFor(gz, tag: tag ?? '9.9.9'), gz),
    ).syncIfNeeded(force: true);
  }

  test('a single all-schemes gzip loads without packs', () async {
    final bundle = await MssCatalogBundle.parseBytesForTest(_gz(single));
    final schemes = (single['scheme_catalog.json'] as Map)['data'] as List;
    expect(bundle.byCatalog.values.expand((e) => e).length, greaterThan(0));
    expect(schemes, isNotEmpty);
  });

  test('download installs, then the same release is unchanged', () async {
    final gz = _gz(single);
    final source = _FakeSource(_manifestFor(gz), gz);
    final svc = service(source);

    final first = await svc.syncIfNeeded(force: true);
    expect(first.outcome, CatalogSyncOutcome.updated);
    expect((await store.readActiveManifest())?.releaseVersion, '9.9.9');
    final active = await store.resolveActive();
    expect(
      sha256.convert(await File(active!.bundlePath).readAsBytes()).toString(),
      sha256.convert(gz).toString(),
    );

    final second = await svc.syncIfNeeded(force: true);
    expect(second.outcome, CatalogSyncOutcome.unchanged);
    expect(source.downloads, 1);
  });

  test('corrupt gzip with a matching hash is rejected, old kept', () async {
    await sync(single);
    final junk = Uint8List.fromList(utf8.encode('not gzip at all'));
    final r = await service(
      _FakeSource(_manifestFor(junk, tag: '10.0.0'), junk),
    ).syncIfNeeded(force: true);

    expect(r.outcome, CatalogSyncOutcome.rejected);
    expect((await store.readActiveManifest())?.releaseVersion, '9.9.9');
  });

  test('a release with no schemes is rejected', () async {
    final empty = _clone(single);
    (empty['scheme_catalog.json'] as Map)['data'] = [];
    expect((await sync(empty)).outcome, CatalogSyncOutcome.rejected);
    expect(await store.readActiveManifest(), isNull);
  });

  test('a missing schemes section is rejected', () async {
    final none = _clone(single)..remove('scheme_catalog.json');
    expect((await sync(none)).outcome, CatalogSyncOutcome.rejected);
  });

  test('a truncated section fails its own record count', () async {
    final cut = _clone(single);
    ((cut['scheme_catalog.json'] as Map)['data'] as List).removeLast();
    expect((await sync(cut)).outcome, CatalogSyncOutcome.rejected);
    expect(await store.readActiveManifest(), isNull);
  });

  test('a bundle from a newer format is not installed', () async {
    final newer = _clone(single);
    (((newer['manifest.json'] as Map)['data'] as List).first
            as Map)['bundleFormat'] =
        MssCatalogBundle.supportedBundleFormat + 1;
    expect((await sync(newer)).outcome, CatalogSyncOutcome.incompatible);
    expect(await store.readActiveManifest(), isNull);
  });

  test('a hostile release tag cannot escape the cache folder', () async {
    final r = await sync(single, tag: '../../evil');
    expect(r.outcome, CatalogSyncOutcome.updated);
    expect(
      root.parent.listSync().any((e) => e.path.endsWith('evil')),
      isFalse,
    );
  });

  test('missing or malformed manifest values do not crash', () {
    final m = CatalogManifest.fromReleaseRpc({
      'release_version': '1.0.0',
      'package_sha256': 'a' * 64,
      'record_counts': 'oops',
      'published_at': null,
    });
    expect(m.byteSize, 0);
    expect(m.schemeCount, 0);
    expect(m.bundleUrl, isNull);
    expect(m.publishedAt.millisecondsSinceEpoch, 0);
    expect(m.isStructurallyValid, isFalse);
  });

  test('a manifest without byte size still installs', () async {
    final gz = _gz(single);
    final r = await service(
      _FakeSource(_manifestFor(gz, size: 0), gz),
    ).syncIfNeeded(force: true);
    expect(r.outcome, CatalogSyncOutcome.updated);
  });
}
