import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// LanguagePackManager
/// ───────────────────
/// Manages downloading, sha256 verification, caching, and in-memory indexing of
/// on-demand language packs (e.g. Hindi `hi`, Tamil `ta`) per MASTER_PLAN §4.
///
/// Features:
/// - O(1) lookup by (lang, entityType, entityId).
/// - Atomic file caching so partial downloads never corrupt active packs.
/// - Sha256 integrity verification against release.json metadata.
/// - Silent fallback to English when a pack is missing or invalid (Decision D3).
class LanguagePackManager {
  LanguagePackManager._();
  static final LanguagePackManager instance = LanguagePackManager._();

  static const String _cacheSubdir = 'mss_language_packs';

  /// In-memory index: key is "$lang:$entityType:$entityId" -> fields map.
  final Map<String, Map<String, dynamic>> _indexedContent = {};
  final Set<String> _loadedLanguages = {};

  bool isLanguageLoaded(String lang) => _loadedLanguages.contains(lang);

  /// Generates the composite key for O(1) lookups.
  static String _key(String lang, String entityType, String entityId) =>
      '$lang:$entityType:$entityId';

  /// Returns the localized field value if available in the loaded language pack.
  String? getField({
    required String lang,
    required String entityType,
    required String entityId,
    required String fieldName,
  }) {
    if (!_loadedLanguages.contains(lang)) return null;
    final entityMap = _indexedContent[_key(lang, entityType, entityId)];
    if (entityMap == null) return null;
    
    // Check exact match, camelCase, or snake_case
    final camelKey = _camelCase(fieldName);
    final snakeKey = _snakeCase(fieldName);
    final val = entityMap[fieldName] ?? entityMap[camelKey] ?? entityMap[snakeKey];
    if (val is String && val.trim().isNotEmpty) {
      return val;
    }
    return null;
  }

  static String _camelCase(String s) {
    return s.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
  }

  static String _snakeCase(String s) {
    return s.replaceAllMapped(RegExp(r'([A-Z])'), (m) => '_${m[1]!.toLowerCase()}');
  }

  /// Returns whether this translated entity has been verified by a human reviewer.
  bool isVerified({
    required String lang,
    required String entityType,
    required String entityId,
  }) {
    final entityMap = _indexedContent[_key(lang, entityType, entityId)];
    return entityMap?['verified'] == true;
  }

  /// Asynchronously loads a language pack into memory.
  /// Tries: 1) Cached file in local app documents, 2) Shipped asset pack.
  Future<bool> loadPack(String lang) async {
    if (_loadedLanguages.contains(lang)) return true;

    try {
      // 1. Try local cache directory
      final cachedBytes = await _readCachedPack(lang);
      if (cachedBytes != null) {
        final parsed = _decompressAndParse(cachedBytes);
        if (parsed != null) {
          _indexPackData(lang, parsed);
          _loadedLanguages.add(lang);
          return true;
        }
      }

      // 2. Try bundled asset pack
      final assetPath = 'assets/catalog/catalog_pack_$lang.json.gz';
      try {
        final assetData = await rootBundle.load(assetPath);
        final bytes = assetData.buffer.asUint8List();
        final parsed = _decompressAndParse(bytes);
        if (parsed != null) {
          _indexPackData(lang, parsed);
          _loadedLanguages.add(lang);
          return true;
        }
      } catch (_) {
        // Asset pack may not exist for some languages yet
      }

      return false;
    } catch (e) {
      debugPrint('LanguagePackManager: Error loading pack for $lang: $e');
      return false;
    }
  }

  /// Installs and verifies a downloaded compressed pack into cache atomically.
  Future<bool> installPackBytes({
    required String lang,
    required Uint8List compressedBytes,
    required String expectedSha256,
  }) async {
    try {
      final actualSha256 = sha256.convert(compressedBytes).toString().toLowerCase();
      if (actualSha256 != expectedSha256.toLowerCase()) {
        debugPrint('LanguagePackManager: SHA-256 mismatch for $lang pack. Discarding.');
        return false;
      }

      // Verify it can decompress and parse
      final parsed = _decompressAndParse(compressedBytes);
      if (parsed == null) {
        debugPrint('LanguagePackManager: Failed to parse $lang pack payload.');
        return false;
      }

      // Atomic file write
      final dir = await _getCacheDir();
      final tempFile = File('${dir.path}/temp_$lang.json.gz');
      final targetFile = File('${dir.path}/catalog_pack_$lang.json.gz');

      await tempFile.writeAsBytes(compressedBytes, flush: true);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);

      // Index in memory
      _indexPackData(lang, parsed);
      _loadedLanguages.add(lang);
      return true;
    } catch (e) {
      debugPrint('LanguagePackManager: Error installing pack for $lang: $e');
      return false;
    }
  }

  void _indexPackData(String lang, Map<String, dynamic> packJson) {
    final data = packJson['data'];
    if (data is! List) return;

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final entityType = item['entityType'] as String?;
      final entityId = item['entityId'] as String?;
      if (entityType != null && entityId != null) {
        _indexedContent[_key(lang, entityType, entityId)] = item;
      }
    }
  }

  Map<String, dynamic>? _decompressAndParse(Uint8List compressedBytes) {
    try {
      final decompressed = GZipDecoder().decodeBytes(compressedBytes);
      final jsonStr = utf8.decode(decompressed);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('LanguagePackManager: Decompression error: $e');
      return null;
    }
  }

  Future<Uint8List?> _readCachedPack(String lang) async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/catalog_pack_$lang.json.gz');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  Directory? _customCacheDir;

  @visibleForTesting
  Map<String, dynamic>? _releaseManifest;

  /// Sets the active release manifest for pack verification and kill-switch checks.
  void setReleaseManifest(Map<String, dynamic>? manifest) {
    _releaseManifest = manifest;
  }

  Map<String, dynamic>? get releaseManifest => _releaseManifest;

  @visibleForTesting
  bool Function(String lang)? isLanguageActiveOverride;

  @visibleForTesting
  bool Function(String lang)? hasValidPackOverride;

  /// Loads release.json if not already loaded in memory.
  Future<void> ensureReleaseManifestLoaded() async {
    if (_releaseManifest != null || isLanguageActiveOverride != null) return;
    try {
      final assetStr = await rootBundle.loadString('assets/catalog/release.json');
      _releaseManifest = jsonDecode(assetStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('LanguagePackManager: failed to load release manifest: $e');
    }
  }

  /// Checks if the given language is listed as active in the current release manifest.
  bool isLanguageActiveInRelease(String lang) {
    if (isLanguageActiveOverride != null) {
      return isLanguageActiveOverride!(lang);
    }
    final manifest = _releaseManifest;
    if (manifest != null) {
      final packs = manifest['languagePacks'] as Map<String, dynamic>?;
      if (packs != null && packs.containsKey(lang)) {
        final packInfo = packs[lang] as Map<String, dynamic>?;
        if (packInfo != null && packInfo.containsKey('isActive')) {
          return packInfo['isActive'] == true;
        }
      }
      final activeLangs = manifest['activeLanguages'] as List<dynamic>?;
      if (activeLangs != null) {
        return activeLangs.contains(lang);
      }
    }
    return false;
  }

  /// Checks if a valid, parseable language pack is available (in-memory, cache, or asset).
  Future<bool> hasValidPack(String lang) async {
    if (hasValidPackOverride != null) {
      return hasValidPackOverride!(lang);
    }
    if (_loadedLanguages.contains(lang) &&
        _indexedContent.keys.any((k) => k.startsWith('$lang:'))) {
      return true;
    }
    try {
      final cachedBytes = await _readCachedPack(lang);
      if (cachedBytes != null) {
        final parsed = _decompressAndParse(cachedBytes);
        if (parsed != null && (parsed['data'] as List?)?.isNotEmpty == true) {
          return true;
        }
      }
    } catch (_) {}

    try {
      final assetPath = 'assets/catalog/catalog_pack_$lang.json.gz';
      final assetData = await rootBundle.load(assetPath);
      final bytes = assetData.buffer.asUint8List();
      final parsed = _decompressAndParse(bytes);
      if (parsed != null && (parsed['data'] as List?)?.isNotEmpty == true) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Returns true iff the release manifest lists the language as active AND a valid pack is present.
  Future<bool> isLanguageSupported(String lang) async {
    if (isLanguageActiveOverride != null) {
      if (!isLanguageActiveOverride!(lang)) return false;
    } else {
      await ensureReleaseManifestLoaded();
      if (!isLanguageActiveInRelease(lang)) {
        return false;
      }
    }
    return await hasValidPack(lang);
  }

  void setCacheDirectoryForTesting(Directory dir) {
    _customCacheDir = dir;
  }

  Future<Directory> _getCacheDir() async {
    if (_customCacheDir != null) return _customCacheDir!;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      final temp = Directory('${Directory.systemTemp.path}/$_cacheSubdir');
      if (!await temp.exists()) {
        await temp.create(recursive: true);
      }
      return temp;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_cacheSubdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Clears in-memory index (used primarily for unit testing).
  @visibleForTesting
  void resetForTesting() {
    _indexedContent.clear();
    _loadedLanguages.clear();
    _releaseManifest = null;
    isLanguageActiveOverride = null;
    hasValidPackOverride = null;
  }
}
