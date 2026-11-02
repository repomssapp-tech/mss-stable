import '../services/catalog/content_language_resolver.dart';

/// One labelled contact line, e.g. `(phone, '+91 22 3105 9000')`. [key] is the
/// source key; known keys are labelled from the ARB files by the UI, unknown
/// ones fall back to [SchemeExtras.humanize].
typedef SchemeContactLine = ({String key, String value});

/// One structured benefit fact, already localised for display.
class SchemeBenefitFact {
  const SchemeBenefitFact({
    required this.type,
    required this.metrics,
    required this.notes,
  });

  /// Source `type` (e.g. `grant`, `loan`).
  final String type;

  /// Numeric attributes in source order: `(key, value)`. The UI formats them
  /// by key.
  final List<MapEntry<String, num>> metrics;

  /// Localised text parts (`cap_text`, `basis`, `scope`, `note`...).
  final List<String> notes;
}

/// Read-only view over the parts of a 2026 scheme record that the flat
/// `Scheme` model has no dedicated field for. It wraps the verbatim source
/// record plus the per-language `localization` blocks, so nothing in the
/// source is lost and new keys stay reachable.
class SchemeExtras {
  const SchemeExtras._(
    this._source,
    this._localization,
    this._jurisdiction,
    this._portal,
    this.legacyCodes,
    this._normalized,
  );

  static const SchemeExtras empty = SchemeExtras._({}, {}, '', {}, [], {});

  /// `content` keys that carry the extras of a normalized (database-built)
  /// record, which has no legacy `source` block.
  static const _normalizedKeys = [
    'applicationProcess',
    'status',
    'benefitFacts',
    'contacts',
  ];

  factory SchemeExtras.fromEntity(Map<String, dynamic> raw) {
    final source = _asMap(raw['source']);
    final content = raw['content'];
    final contentMap = content is Map ? _asMap(content) : const {};
    final normalized = <String, dynamic>{
      for (final k in _normalizedKeys)
        if (contentMap[k] != null) k: contentMap[k],
    };
    if (source.isEmpty && normalized.isEmpty) return empty;
    final loc = _asMap(raw['localization']);
    final provenance = raw['provenance'];
    final Map<String, dynamic> portal = _asMap(contentMap['portalInfo']);
    final identity = raw['identity'];
    final codes = identity is Map ? identity['legacyCodes'] : null;
    return SchemeExtras._(
      source,
      loc,
      provenance is Map ? (provenance['jurisdiction'] as String? ?? '') : '',
      portal,
      [
        if (codes is List)
          for (final c in codes)
            if (c is Map && c['code'] is String) c['code'] as String,
      ],
      normalized,
    );
  }

  /// Any `Map` (JSON-decoded or hand-built) as `Map<String, dynamic>`.
  static Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const {};

  final Map<String, dynamic> _source;
  final Map<String, dynamic> _localization;
  final String _jurisdiction;

  /// The [_normalizedKeys] of `content`; the fallback for every field the
  /// legacy [_source] block would otherwise supply.
  final Map<String, dynamic> _normalized;

  /// Resolved entry of the jurisdiction's portals directory, when the scheme
  /// names one (`how_to_apply.portal`).
  final Map<String, dynamic> _portal;

  /// Pre-2026 codes of this scheme (`TN130`, `IN130`...). The private-AI
  /// knowledge base still names schemes by these codes.
  final List<String> legacyCodes;

  bool get isEmpty => _source.isEmpty && _normalized.isEmpty;

  /// `central`, `tamil_nadu`, `maharashtra`, ... (from the import provenance).
  String get jurisdiction => _jurisdiction;

  Map<String, dynamic> get _how => _asMap(_source['how_to_apply']);

  /// `content.applicationProcess` of a normalized record.
  Map<String, dynamic> get _proc => _asMap(_normalized['applicationProcess']);

  /// First non-empty text of [legacy] then [normalized].
  String _text(Object? legacy, Object? normalized) {
    final a = ContentLanguageResolver.text(legacy);
    return a.isNotEmpty ? a : ContentLanguageResolver.text(normalized);
  }

  dynamic _loc(String lang, String key) {
    final code = ContentLanguageResolver.normalizeCode(lang);
    final block = _localization[code];
    if (block is Map && block[key] != null) return block[key];
    final en = _localization['en'];
    return en is Map ? en[key] : null;
  }

  String _str(dynamic v) => v is String ? v.trim() : '';

  /// A list the source stores per language (`eligibility`, `how_to_apply.steps`)
  /// in [lang] only -- no English fallback, so callers can tell "no stored
  /// text" from "stored text".
  List<String> _storedList(Object? field, String lang) {
    if (field is! Map) return const [];
    final v = field[ContentLanguageResolver.normalizeCode(lang)];
    if (v is! List) return const [];
    return [
      for (final item in v)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  /// A normalized record keeps its per-language lists in
  /// `localization.<lang>.<key>`; used only when there is no legacy source.
  List<String> _localizedList(String lang, String key) {
    final block = _localization[ContentLanguageResolver.normalizeCode(lang)];
    final v = block is Map ? block[key] : null;
    if (v is! List) return const [];
    return [
      for (final item in v)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  List<String> storedEligibility(String lang) => _source.isEmpty
      ? _localizedList(lang, 'eligibilityList')
      : _storedList(_source['eligibility'], lang);

  List<String> storedSteps(String lang) => _source.isEmpty
      ? _localizedList(lang, 'stepsList')
      : _storedList(_how['steps'], lang);

  /// Names of the required documents in [lang] (`localization.<lang>.documents`),
  /// in the same order as the English list. Empty when the catalogue has none.
  List<String> storedDocumentNames(String lang) {
    final block = _localization[ContentLanguageResolver.normalizeCode(lang)];
    final v = block is Map ? block['documents'] : null;
    if (v is! List) return const [];
    return [for (final item in v) item is String ? item.trim() : ''];
  }

  // ── Status ────────────────────────────────────────────────────────────
  Map<String, dynamic> get _status => _asMap(_normalized['status']);

  String get statusValue {
    final v = _str((_source['status'] as Map?)?['value']);
    return (v.isNotEmpty ? v : _str(_status['value'])).toLowerCase();
  }

  String get statusAsOf {
    final v = _str((_source['status'] as Map?)?['as_of']);
    return v.isNotEmpty ? v : _str(_status['asOf']);
  }

  /// Empty when the English note is the catalogue's own bookkeeping ("Catalogue
  /// status active; verification verified (high).", "Staging record MSME2015-010
  /// (renamed); web check...", "Verified active via live portal (HTTP 200...)"),
  /// which reads like debug text; the application status is shown separately.
  /// Notes that tell the user something about the scheme stay.
  String statusNote(String lang) {
    final en = ContentLanguageResolver.text(_loc('en', 'statusNote'), 'en');
    if (_internalStatusNote.hasMatch(en)) return '';
    return ContentLanguageResolver.text(_loc(lang, 'statusNote'), lang);
  }

  static final RegExp _internalStatusNote = RegExp(
    r'^(Catalogue status [\w ]+; verification [\w ]+ \(\w+\)'
    r'|Staging record '
    r'|Verified active '
    r'|Verified against a live official page'
    r'|Verified\s*[-–] '
    r'|Historical/closed\s*[-–] source audit pending'
    r'|Needs final official-page confirmation)',
  );

  /// `open`, `closed`, `unknown`, `historical_or_superseded`, `announced`,
  /// `temporarily unavailable`... as given by the source.
  String get applicationStatus =>
      _text(_how['application_status'], _proc['applicationStatus']);
  String get procedureType =>
      _text(_how['procedure_type'], _proc['procedureType']);
  String get deadline => _text(_how['deadline'], _proc['deadline']);
  String get prerequisite => _text(_how['prerequisite'], _proc['prerequisite']);
  String get statusCheckedOn =>
      _text(_how['status_checked_on'], _proc['statusCheckedOn']);

  /// Application fees; `fees` may be text or a structured value.
  String get fees => _text(_how['fees'], _proc['applicationFeeText']);

  // ── Contacts ──────────────────────────────────────────────────────────
  static const List<String> _contactOrder = [
    'phone',
    'helpline',
    'email',
    'website',
    'office',
    'address',
    'hours',
  ];

  List<SchemeContactLine> contacts(String lang) {
    var base = _source['contacts'];
    if (base is! Map || base.isEmpty) base = _normalized['contacts'];
    // No scheme-level contacts: fall back to the named portal's contact block.
    if (base is! Map || base.isEmpty) base = _portal['contact'];
    if (base is! Map) return const [];
    final translated = base == _portal['contact']
        ? null
        : _loc(lang, 'contacts');
    final merged = <String, dynamic>{
      ...base.cast<String, dynamic>(),
      if (translated is Map) ...translated.cast<String, dynamic>(),
    };
    final keys = <String>[
      ..._contactOrder.where(merged.containsKey),
      ...merged.keys.where((k) => !_contactOrder.contains(k)),
    ];
    final lines = <SchemeContactLine>[];
    for (final key in keys) {
      final value = ContentLanguageResolver.text(merged[key], lang);
      if (value.isNotEmpty) lines.add((key: key, value: value));
    }
    return lines;
  }

  // ── Benefit facts ─────────────────────────────────────────────────────
  static const _factMetaKeys = {'type', 'translations'};

  List<SchemeBenefitFact> benefitFacts(String lang) {
    var facts = (_source['benefit_facts'] as Map?)?['facts'];
    if (facts is! List) {
      // Normalized records carry the same block as `content.benefitFacts`,
      // either `{facts: [...]}` or the bare list.
      final nb = _normalized['benefitFacts'];
      facts = nb is Map ? nb['facts'] : nb;
    }
    if (facts is! List) return const [];
    final code = ContentLanguageResolver.normalizeCode(lang);
    final out = <SchemeBenefitFact>[];
    for (final fact in facts.whereType<Map>()) {
      final metrics = <MapEntry<String, num>>[];
      final notes = <String>[];
      final tr = (fact['translations'] as Map?)?[code];
      fact.forEach((k, v) {
        if (k is! String || _factMetaKeys.contains(k)) return;
        if (v is num) {
          metrics.add(MapEntry(k, v));
        } else if (v is String && v.trim().isNotEmpty) {
          // A translated note replaces its English source.
          final t = tr is Map ? ContentLanguageResolver.text(tr[k], lang) : '';
          notes.add(t.isNotEmpty ? t : v.trim());
        }
      });
      if (metrics.isEmpty && notes.isEmpty) continue;
      out.add(
        SchemeBenefitFact(
          type: (fact['type'] as String?) ?? '',
          metrics: metrics,
          notes: notes.toSet().toList(growable: false),
        ),
      );
    }
    return out;
  }

  // ── Links ─────────────────────────────────────────────────────────────
  /// Apply / info / guidelines links, then the named portal's links. [title]
  /// is set for portal links (the portal's own name).
  List<({String kind, String url, String? title})> links(String lang) {
    final out = <({String kind, String url, String? title})>[];
    final seen = <String>{};
    void add(String kind, String url, [String? title]) {
      if (url.isNotEmpty && seen.add(url)) {
        out.add((kind: kind, url: url, title: title));
      }
    }

    for (final kind in const ['apply', 'info', 'guidelines']) {
      add(kind, _str(_how['${kind}_url']));
    }
    final i18n = _portal['name_i18n'];
    final code = ContentLanguageResolver.normalizeCode(lang);
    final title = (i18n is Map ? _str(i18n[code]) : '').isNotEmpty
        ? _str((i18n as Map)[code])
        : _str(_portal['name']);
    add('portal', _str(_portal['url']), title.isEmpty ? null : title);
    add(
      'portalLogin',
      _str(_portal['apply_url_login']),
      title.isEmpty ? null : title,
    );
    add(
      'portalServices',
      _str(_portal['services_url']),
      title.isEmpty ? null : title,
    );
    return out;
  }

  // ── Names, relations, notes ───────────────────────────────────────────
  List<String> altNames(String lang) =>
      ContentLanguageResolver.list(_loc(lang, 'altNames'), lang);

  List<String> get relatedIds => ((_source['related_ids'] as List?) ?? const [])
      .whereType<String>()
      .toList(growable: false);

  List<String> notes(String lang) =>
      ContentLanguageResolver.list(_loc(lang, 'notes'), lang);

  /// Documents grouped by audience when the source keys them (e.g. individual
  /// vs self-help group). Empty when documents are a plain list.
  List<({String audience, List<String> items})> documentsByAudience() {
    final docs = _how['documents'];
    if (docs is! Map) return const [];
    return [
      for (final e in docs.entries)
        (
          audience: humanize(e.key.toString()),
          items: ContentLanguageResolver.list(e.value),
        ),
    ].where((g) => g.items.isNotEmpty).toList(growable: false);
  }

  /// True when the source flags [lang]'s text as machine-translated.
  bool isMachineTranslated(String lang) {
    final code = ContentLanguageResolver.normalizeCode(lang);
    return _source['${code}_is_machine_translation'] == true;
  }

  /// `snake_case` / `camelCase` -> `Snake case`.
  static String humanize(String key) {
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    if (spaced.isEmpty) return '';
    return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
  }
}
