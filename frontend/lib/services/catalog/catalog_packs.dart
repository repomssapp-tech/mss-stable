import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// One entry of `manifest.packs` in the core catalog file: the core itself, or
/// a jurisdiction pack (central, tamil_nadu, ...) holding that jurisdiction's
/// schemes plus their applicability and search-index rows.
class CatalogPackInfo {
  const CatalogPackInfo({
    required this.id,
    required this.kind,
    required this.file,
    required this.required,
    this.jurisdiction = '',
    this.tenantId = '',
    this.sha256 = '',
    this.bytes = 0,
    this.recordCounts = const {},
  });

  factory CatalogPackInfo.fromJson(Map<dynamic, dynamic> json) {
    final counts = json['recordCounts'];
    return CatalogPackInfo(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      file: json['file'] as String? ?? '',
      required: json['required'] == true,
      jurisdiction: json['jurisdiction'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      sha256: (json['sha256'] as String? ?? '').toLowerCase(),
      bytes: json['bytes'] as int? ?? 0,
      recordCounts: counts is Map
          ? {
              for (final e in counts.entries)
                if (e.key is String && e.value is int)
                  e.key as String: e.value as int,
            }
          : const {},
    );
  }

  final String id;
  final String kind;
  final String file;

  /// Always loaded; a build that cannot find it refuses to start.
  final bool required;
  final String jurisdiction;

  /// The jurisdiction owner this pack belongs to. Only the id is carried
  /// today; branding and access rules arrive with tenants.
  final String tenantId;
  final String sha256;
  final int bytes;

  /// Rows this pack contributes to each partitioned section.
  final Map<String, int> recordCounts;

  bool get isJurisdiction => kind == 'jurisdiction';
}

/// Reads a catalog file by name (e.g. `catalog_tamil_nadu.json.gz`); null when
/// the file is not installed on this device.
typedef CatalogPackReader = Future<Uint8List?> Function(String file);

/// Decompresses and decodes one gzip catalog file.
typedef CatalogPackParser =
    Future<Map<String, dynamic>> Function(Uint8List gzipBytes);

/// The jurisdiction packs listed by a core file's manifest, merged back into the
/// registry of sections the single-file bundle used to be.
class CatalogPacks {
  CatalogPacks._();

  static List<CatalogPackInfo> listed(Map<String, dynamic> manifest) {
    final raw = manifest['packs'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) CatalogPackInfo.fromJson(item),
    ].where((p) => p.isJurisdiction).toList(growable: false);
  }

  /// Reads, verifies (SHA-256 against the core manifest) and merges every
  /// installed jurisdiction pack into [bundle] in place. A pack that is not
  /// installed is skipped, unless it is required. Returns the ids of the packs
  /// merged and the packs that were not installed.
  static Future<({List<String> loaded, List<CatalogPackInfo> missing})>
  mergeInto(
    Map<String, dynamic> bundle,
    Map<String, dynamic> manifest,
    CatalogPackReader read,
    CatalogPackParser parse,
  ) async {
    final loaded = <CatalogPackInfo>[];
    final parsed = <String, Map<String, dynamic>>{};
    final missing = <CatalogPackInfo>[];
    for (final info in listed(manifest)) {
      final bytes = await read(info.file);
      if (bytes == null) {
        if (info.required) {
          throw StateError('Required catalog pack ${info.file} is missing.');
        }
        missing.add(info);
        continue;
      }
      final actual = sha256.convert(bytes).toString().toLowerCase();
      if (actual != info.sha256) {
        throw StateError(
          'Catalog pack ${info.file} does not match its manifest SHA-256 '
          '(expected ${info.sha256}, got $actual).',
        );
      }
      parsed[info.file] = await parse(bytes);
      loaded.add(info);
    }

    // Partitioned sections say so themselves: the core keeps their metadata and
    // a `packSlot`, the position where pack rows go inside the core rows.
    for (final entry in bundle.entries.toList()) {
      final base = entry.value;
      if (base is! Map || !base.containsKey('packSlot')) continue;
      final coreRows = (base['data'] as List?) ?? const [];
      final slot = (base['packSlot'] as int?) ?? coreRows.length;
      final rows = <dynamic>[...coreRows.take(slot)];
      for (final info in loaded) {
        final section = parsed[info.file]![entry.key];
        final data = section is Map ? section['data'] : null;
        if (data is List) rows.addAll(data);
      }
      rows.addAll(coreRows.skip(slot));
      base['data'] = rows;
      base.remove('packSlot');
    }

    if (missing.isNotEmpty) _discount(bundle, manifest, missing);
    return (loaded: [for (final p in loaded) p.id], missing: missing);
  }

  /// A dropped pack's rows are simply absent; the counts the integrity check
  /// compares against must not expect them.
  static void _discount(
    Map<String, dynamic> bundle,
    Map<String, dynamic> manifest,
    List<CatalogPackInfo> missing,
  ) {
    final counts = manifest['recordCounts'];
    var dropped = 0;
    for (final pack in missing) {
      pack.recordCounts.forEach((section, n) {
        if (counts is Map && counts[section] is int) {
          counts[section] = (counts[section] as int) - n;
        }
        final body = bundle[section];
        final meta = body is Map ? body['metadata'] : null;
        if (meta is Map && meta['recordCount'] is int) {
          meta['recordCount'] = (meta['recordCount'] as int) - n;
        }
        if (section.endsWith('_catalog.json')) dropped += n;
      });
    }
    if (manifest['entityCount'] is int) {
      manifest['entityCount'] = (manifest['entityCount'] as int) - dropped;
    }
  }
}
