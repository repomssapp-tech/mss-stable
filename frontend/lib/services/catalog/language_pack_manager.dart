import 'package:flutter/foundation.dart';

import 'mss_catalog_bundle.dart';

/// LanguagePackManager
/// ───────────────────
/// O(1) per-language lookup of catalog text, for Hindi `hi`, Tamil `ta` and any
/// other language the catalog carries.
///
/// There are no separate language-pack files: every entity's translations live
/// in its own `localization.<lang>` block inside `catalog_bundle.json.gz`. This
/// class indexes those blocks by (language, entityType, entityId) on demand so
/// callers keep a cheap, synchronous `getField`. Which languages are switched
/// on comes from the bundle's embedded manifest (`manifest.languages`), so a
/// release can turn a language off without an app update.
///
/// A missing language, entity or field returns `null` and callers fall back to
/// English (Decision D3); nothing is ever invented.
class LanguagePackManager {
  LanguagePackManager._();
  static final LanguagePackManager instance = LanguagePackManager._();

  /// In-memory index: key is "$lang:$entityType:$entityId" -> localization block.
  final Map<String, Map<String, dynamic>> _indexedContent = {};
  final Set<String> _loadedLanguages = {};

  bool isLanguageLoaded(String lang) => _loadedLanguages.contains(lang);

  /// Generates the composite key for O(1) lookups.
  static String _key(String lang, String entityType, String entityId) =>
      '$lang:$entityType:$entityId';

  /// Returns the localized field value if available for [lang].
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
    final val =
        entityMap[fieldName] ?? entityMap[camelKey] ?? entityMap[snakeKey];
    if (val is String && val.trim().isNotEmpty) {
      return val;
    }
    return null;
  }

  static String _camelCase(String s) {
    return s.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
  }

  static String _snakeCase(String s) {
    return s.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => '_${m[1]!.toLowerCase()}',
    );
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

  /// Loads [lang] into the in-memory index from the catalog bundle. Returns
  /// false when the bundle has no content in that language.
  Future<bool> loadPack(String lang) async {
    if (_loadedLanguages.contains(lang)) return true;
    try {
      final bundle = await MssCatalogBundle.load();
      return indexBundle(lang, bundle);
    } catch (e) {
      debugPrint('LanguagePackManager: error loading $lang: $e');
      return false;
    }
  }

  /// Indexes every entity's `localization.<lang>` block from [bundle].
  @visibleForTesting
  bool indexBundle(String lang, MssCatalogBundle bundle) {
    var found = 0;
    for (final entity in bundle.byId.values) {
      final localization = entity.raw['localization'];
      final block = localization is Map ? localization[lang] : null;
      if (block is Map) {
        _indexedContent[_key(lang, entity.entityType, entity.id)] = block
            .cast<String, dynamic>();
        found++;
      }
    }
    if (found == 0) return false;
    _loadedLanguages.add(lang);
    return true;
  }

  Map<String, dynamic>? _releaseManifest;

  /// Sets the active manifest for kill-switch checks (tests).
  void setReleaseManifest(Map<String, dynamic>? manifest) {
    _releaseManifest = manifest;
  }

  Map<String, dynamic>? get releaseManifest => _releaseManifest;

  @visibleForTesting
  bool Function(String lang)? isLanguageActiveOverride;

  @visibleForTesting
  bool Function(String lang)? hasValidPackOverride;

  /// Loads the bundle's embedded manifest if not already in memory.
  Future<void> ensureReleaseManifestLoaded() async {
    if (_releaseManifest != null || isLanguageActiveOverride != null) return;
    try {
      _releaseManifest = (await MssCatalogBundle.load()).manifest;
    } catch (e) {
      debugPrint('LanguagePackManager: failed to load release manifest: $e');
    }
  }

  /// Checks if the given language is listed as active in the current manifest
  /// (`languages: [{code, isActive}]`).
  bool isLanguageActiveInRelease(String lang) {
    if (isLanguageActiveOverride != null) {
      return isLanguageActiveOverride!(lang);
    }
    final languages = _releaseManifest?['languages'];
    if (languages is List) {
      for (final item in languages) {
        if (item is Map && item['code'] == lang) {
          return item['isActive'] == true;
        }
      }
    }
    return false;
  }

  /// Checks that the catalog actually has content for [lang].
  Future<bool> hasValidPack(String lang) async {
    if (hasValidPackOverride != null) {
      return hasValidPackOverride!(lang);
    }
    if (_loadedLanguages.contains(lang) &&
        _indexedContent.keys.any((k) => k.startsWith('$lang:'))) {
      return true;
    }
    return loadPack(lang);
  }

  /// Returns true iff the manifest lists the language as active AND the catalog
  /// carries content in it.
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
