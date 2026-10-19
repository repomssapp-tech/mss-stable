import 'dart:collection';

import '../services/catalog/language_pack_manager.dart';

/// Immutable wrapper around raw catalog JSON entities.
/// Preserves complete un-flattened raw structure while providing typed accessors
/// and multilingual localization fallback helper methods.
class MssEntity {
  final String id;
  final String entityType;
  final String code;
  final String status;
  final Map<String, dynamic> raw;

  MssEntity._({
    required this.id,
    required this.entityType,
    required this.code,
    required this.status,
    required this.raw,
  });

  factory MssEntity.fromJson(Map<String, dynamic> json) {
    final identity = json['identity'] as Map<String, dynamic>? ?? {};
    final id = (identity['id'] ?? json['entityId'] ?? '') as String;
    final entityType =
        (identity['entityType'] ?? json['entityType'] ?? '') as String;
    final code = (identity['code'] ?? '') as String;
    final status =
        (identity['status'] ?? json['status'] ?? 'unknown') as String;

    return MssEntity._(
      id: id,
      entityType: entityType,
      code: code,
      status: status,
      raw: UnmodifiableMapView(json),
    );
  }

  /// Multilingual name resolution per MASTER_PLAN §4:
  /// LanguagePack -> localization[preferredLang]['name'] -> English fallback -> code
  String getLocalizedName([String preferredLang = 'en']) {
    // 1. Check on-demand language pack if preferredLang is active
    if (preferredLang != 'en') {
      final packVal = LanguagePackManager.instance.getField(
        lang: preferredLang,
        entityType: entityType,
        entityId: id,
        fieldName: 'name',
      );
      if (packVal != null && packVal.isNotEmpty) {
        return packVal;
      }
    }

    // 2. Check bundled legacy localization block
    final loc = raw['localization'] as Map<String, dynamic>?;
    if (loc != null) {
      final preferred = loc[preferredLang] as Map<String, dynamic>?;
      if (preferred != null &&
          (preferred['name'] as String?)?.isNotEmpty == true) {
        return preferred['name'] as String;
      }
    }

    // 3. The record's own default language, then English
    final dflt = defaultLanguage;
    if (dflt != 'en') {
      final d = loc?[dflt];
      if (d is Map && (d['name'] as String?)?.isNotEmpty == true) {
        return d['name'] as String;
      }
    }
    final enLoc = loc?['en'] as Map<String, dynamic>?;
    if (enLoc != null && (enLoc['name'] as String?)?.isNotEmpty == true) {
      return enLoc['name'] as String;
    }
    final identity = raw['identity'] as Map<String, dynamic>?;
    if (identity != null && (identity['name'] as String?)?.isNotEmpty == true) {
      return identity['name'] as String;
    }
    return code;
  }

  /// Multilingual attribute resolution for any field (e.g. 'summary', 'overview', 'description', 'benefits').
  /// Fallback per MASTER_PLAN §4: LanguagePack -> localization[preferredLang] -> English fallback -> ''
  String getLocalizedAttribute(String key, [String preferredLang = 'en']) {
    // 1. Check on-demand language pack
    if (preferredLang != 'en') {
      final packVal = LanguagePackManager.instance.getField(
        lang: preferredLang,
        entityType: entityType,
        entityId: id,
        fieldName: key,
      );
      if (packVal != null && packVal.isNotEmpty) {
        return packVal;
      }
    }

    // 2. Check bundled legacy localization block
    final loc = raw['localization'] as Map<String, dynamic>?;
    if (loc != null) {
      final preferred = loc[preferredLang] as Map<String, dynamic>?;
      if (preferred != null &&
          (preferred[key] as String?)?.isNotEmpty == true) {
        return preferred[key] as String;
      }
    }

    // 3. The record's own default language, then English
    final dflt = defaultLanguage;
    if (dflt != 'en') {
      final d = loc?[dflt];
      if (d is Map && (d[key] as String?)?.isNotEmpty == true) {
        return d[key] as String;
      }
    }
    final en = loc?['en'] as Map<String, dynamic>?;
    if (en != null && (en[key] as String?)?.isNotEmpty == true) {
      return en[key] as String;
    }
    final attrs = raw['attributes'] as Map<String, dynamic>?;
    if (attrs != null && (attrs[key] as String?)?.isNotEmpty == true) {
      return attrs[key] as String;
    }

    return '';
  }

  /// `content.languages` stamped by the catalog build: languages the record
  /// carries (`available`), the ones the app offers for it (`offered`) and the
  /// one used when the selected language has no value (`default`).
  Map<String, dynamic> get _languages {
    final l = content['languages'];
    return l is Map ? l.cast<String, dynamic>() : const {};
  }

  List<String> get availableLanguages => _langList('available');
  List<String> get offeredLanguages => _langList('offered');
  String get defaultLanguage {
    final d = _languages['default'];
    return d is String && d.isNotEmpty ? d : 'en';
  }

  List<String> _langList(String key) {
    final v = _languages[key];
    return v is List
        ? [
            for (final c in v)
              if (c is String) c,
          ]
        : const [];
  }

  /// Accessors for nested entity sections
  Map<String, dynamic> get content =>
      (raw['content'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get identity =>
      (raw['identity'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get relationships =>
      (raw['relationships'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get search =>
      (raw['search'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get metadata =>
      (raw['metadata'] as Map<String, dynamic>?) ?? const {};

  List<Map<String, dynamic>> get references {
    final refs = relationships['references'] as List?;
    if (refs == null) return const [];
    return refs.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MssEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MssEntity(id: $id, type: $entityType, code: $code, status: $status)';
}
