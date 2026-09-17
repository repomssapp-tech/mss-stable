import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/scheme_model.dart';
import '../../models/user_profile.dart';
import '../search/hybrid_scheme_search.dart';
import '../search/intelligent_scheme_search.dart' show SchemeSearchMatch;
import 'mss_catalog_bundle.dart';
import 'mss_scheme_adapter.dart';
import '../recommendation/recommendation_engine.dart';

/// SchemeRepository
/// ─────────────────
/// Single source of truth for all scheme-related data. Scheme discovery
/// (search, categories, details, recommendations) is offline-only, reading
/// exclusively from the local MssCatalogBundle -- see docs and
/// 2026-09-04's offline-first migration. Profile persistence still goes
/// through Supabase directly (see the methods below _db).
class SchemeRepository {
  SchemeRepository._();

  static final SchemeRepository instance = SchemeRepository._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── In-memory cache ──────────────────────────────────────────────────
  List<Scheme>? _cachedSchemes;
  Map<String, Scheme>? _schemeByIdMap;
  String? _cachedLanguage;
  Future<MssCatalogBundle>? _bundleFuture;
  Map<String, int>? _cachedCategoryCounts;

  // ── Search in-flight deduplication & short-term query memoization ───────
  final Map<String, Future<List<Scheme>>> _inFlightSchemeSearches = {};
  final Map<String, _CachedSearch<List<Scheme>>> _searchSchemesCache = {};
  final Map<String, Future<List<SchemeSearchMatch>>> _inFlightMatchSearches =
      {};
  final Map<String, _CachedSearch<List<SchemeSearchMatch>>>
  _searchMatchesCache = {};
  static const Duration _searchCacheTtl = Duration(seconds: 15);

  void clearCache() {
    _cachedSchemes = null;
    _schemeByIdMap = null;
    _cachedLanguage = null;
    _bundleFuture = null;
    _cachedCategoryCounts = null;
    _inFlightSchemeSearches.clear();
    _searchSchemesCache.clear();
    _inFlightMatchSearches.clear();
    _searchMatchesCache.clear();
    // Resetting _bundleFuture alone isn't enough: MssCatalogBundle.load()
    // has its own static singleton short-circuit that would keep returning
    // the bundle from whatever was on disk at first load. Without this, a
    // successful background catalog sync would silently never take effect
    // until the app process fully restarts.
    MssCatalogBundle.invalidate();
  }

  Future<MssCatalogBundle> _loadBundle() =>
      _bundleFuture ??= MssCatalogBundle.load();

  // ── 1. getTotalSchemeCount() ──────────────────────────────────────────
  /// Returns total number of schemes from the local catalog. Offline-only --
  /// scheme discovery never hits the network.
  Future<int> getTotalSchemeCount() async {
    final schemes = await getAllSchemes();
    return schemes.length;
  }

  // ── 2. getTopRecommendedSchemes() ─────────────────────────────────────
  /// Returns top [limit] recommended schemes for user profile sorted by relevance score.
  /// Offline-only -- delegates to getRecommendedSchemes (local scoring).
  Future<List<Scheme>> getTopRecommendedSchemes(
    UserProfile profile, {
    int limit = 5,
  }) async {
    final recommended = await getRecommendedSchemes(profile);
    if (recommended.isNotEmpty) {
      return recommended.take(limit).toList();
    }

    // Fallback: Client-side RecommendationEngine
    final all = await getAllSchemes();
    final recommendations = RecommendationEngine.getRecommendations(
      profile,
      all,
    );
    return recommendations
        .where((e) => e.value.score > 0)
        .map((e) => e.key)
        .take(limit)
        .toList();
  }

  // ── 3. getCategoryCounts() ────────────────────────────────────────────
  /// Computes dynamic category scheme counts once and caches results.
  /// Single pass over the catalog testing all 8 fixed categories per scheme,
  /// instead of the previous 8 independent calls into getSchemesByCategory()
  /// -- each of which rebuilt the same per-scheme canonicalText string from
  /// scratch, so the catalog was effectively string-scanned 8x over on every
  /// cold Search-tab open. The per-category predicates below are copied
  /// verbatim from _getSchemesByCategoryOffline's exact-match branches for
  /// these 8 category names, so the counts here and the list you get from
  /// tapping a category tile (which still goes through
  /// _getSchemesByCategoryOffline) can never drift apart -- keep them in
  /// sync if either changes.
  Future<Map<String, int>> getCategoryCounts(
    UserProfile profile, {
    String activeFilter = 'All',
  }) async {
    if (_cachedCategoryCounts != null && activeFilter == 'All') {
      return _cachedCategoryCounts!;
    }

    const categoriesToQuery = [
      "MSME",
      "Startup",
      "Women Entrepreneurs",
      "Business Loans & Credit",
      "SHG & Artisan",
      "Technology",
      "Manufacturing",
      "Export & Trade Promotion",
    ];

    final all = await getAllSchemes();
    final Map<String, int> counts = {for (final c in categoriesToQuery) c: 0};

    for (final s in all) {
      final cat = s.category.toLowerCase();
      final type = s.schemeType.toLowerCase();
      final target = s.targetBeneficiary.toLowerCase();
      final kw = s.searchKeywords.toLowerCase();
      final sector = s.sector.toLowerCase();
      final canonicalText =
          '${s.name} ${s.shortName} ${s.schemeType} ${s.category} ${s.sector} ${s.searchKeywords} ${s.overview}'
              .toLowerCase();

      if (cat.contains('msme') ||
          sector.contains('msme') ||
          target.contains('msme') ||
          canonicalText.contains('micro') ||
          canonicalText.contains('udyam')) {
        counts['MSME'] = counts['MSME']! + 1;
      }
      if (cat.contains('startup') ||
          kw.contains('startup') ||
          kw.contains('dpiit') ||
          canonicalText.contains('incubator') ||
          canonicalText.contains('seed fund')) {
        counts['Startup'] = counts['Startup']! + 1;
      }
      if (target.contains('women') ||
          kw.contains('women') ||
          target.contains('female') ||
          canonicalText.contains('mahila') ||
          canonicalText.contains('stree')) {
        counts['Women Entrepreneurs'] = counts['Women Entrepreneurs']! + 1;
      }
      if (type.contains('loan') ||
          cat.contains('loan') ||
          cat.contains('credit') ||
          canonicalText.contains('loan') ||
          canonicalText.contains('credit') ||
          canonicalText.contains('mudra') ||
          canonicalText.contains('cgtmse') ||
          canonicalText.contains('working capital') ||
          canonicalText.contains('term loan') ||
          canonicalText.contains('svanidhi') ||
          canonicalText.contains('standup') ||
          canonicalText.contains('financing') ||
          canonicalText.contains('collateral-free') ||
          canonicalText.contains('collateral free')) {
        counts['Business Loans & Credit'] = counts['Business Loans & Credit']! + 1;
      }
      if (target.contains('artisan') ||
          target.contains('shg') ||
          kw.contains('vishwakarma') ||
          kw.contains('weaver') ||
          canonicalText.contains('craftsman')) {
        counts['SHG & Artisan'] = counts['SHG & Artisan']! + 1;
      }
      if (cat.contains('tech') ||
          sector.contains('tech') ||
          kw.contains('technology') ||
          canonicalText.contains('digital') ||
          canonicalText.contains('r&d')) {
        counts['Technology'] = counts['Technology']! + 1;
      }
      if (sector.contains('manufactur') ||
          cat.contains('manufactur') ||
          kw.contains('manufacturing') ||
          canonicalText.contains('production') ||
          canonicalText.contains('factory')) {
        counts['Manufacturing'] = counts['Manufacturing']! + 1;
      }
      if (cat.contains('export') ||
          sector.contains('export') ||
          kw.contains('export') ||
          canonicalText.contains('trade promotion') ||
          canonicalText.contains('exhibition')) {
        counts['Export & Trade Promotion'] = counts['Export & Trade Promotion']! + 1;
      }
    }

    if (activeFilter == 'All') {
      _cachedCategoryCounts = Map.unmodifiable(counts);
    }
    return counts;
  }

  // ── 4. getDynamicSearchHint() ─────────────────────────────────────────
  /// Returns dynamic search hint prompt from loaded catalog entries.
  /// Intentionally local for instantaneous UI search bar rendering.
  Future<String> getDynamicSearchHint([String langCode = 'en']) async {
    final all = await getAllSchemes(langCode: langCode);
    if (all.isEmpty) return 'PMEGP, Startup India, MSME loans...';
    final sample = (List<Scheme>.from(all)..shuffle()).first;
    final name = sample.getName(langCode);
    return name.isNotEmpty
        ? name
        : (sample.shortName.isNotEmpty ? sample.shortName : sample.name);
  }

  // ── 5. getAllSchemes() ────────────────────────────────────────────────
  /// Returns the complete curated catalog of schemes (217 records) for [langCode].
  /// Kept local/offline as baseline catalog data (no /v1/schemes/all bulk endpoint exists).
  Future<List<Scheme>> getAllSchemes({String langCode = 'en'}) async {
    if (_cachedSchemes != null && _cachedLanguage == langCode) {
      return _cachedSchemes!;
    }

    try {
      final bundle = await _loadBundle();
      final schemeEntities = bundle.schemes;

      final schemes = <Scheme>[];
      final byIdMap = <String, Scheme>{};

      for (final entity in schemeEntities) {
        final scheme = MssSchemeAdapter.toScheme(
          entity,
          bundle,
          langCode: langCode,
        );
        schemes.add(scheme);
        byIdMap[scheme.id.toLowerCase()] = scheme;
        if (scheme.schemeCode.isNotEmpty) {
          byIdMap[scheme.schemeCode.toLowerCase()] = scheme;
        }
      }

      _cachedLanguage = langCode;
      _cachedSchemes = List.unmodifiable(schemes);
      _schemeByIdMap = Map.unmodifiable(byIdMap);
      return _cachedSchemes!;
    } catch (e) {
      debugPrint('[SchemeRepository] catalog bundle load error: $e');
      return _cachedSchemes ?? const [];
    }
  }

  // ── 6. searchSchemes() ────────────────────────────────────────────────
  /// Intelligently ranks natural-language English and Tamil queries.
  /// 100% on-device search via HybridSchemeSearch over MssCatalogBundle.
  /// Deduplicated in-flight and memoized for 15s to eliminate redundant CPU ranking work.
  Future<List<Scheme>> searchSchemes(
    String query, {
    String langCode = 'en',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAllSchemes(langCode: langCode);

    final cacheKey = '$langCode:${trimmed.toLowerCase()}';

    // 1. Fresh memoized cache check (instant response, 0ms latency)
    final cached = _searchSchemesCache[cacheKey];
    if (cached != null && cached.isFresh) {
      return cached.data;
    }

    // 2. Singleflight: Deduplicate concurrent in-flight requests for identical query
    final inFlight = _inFlightSchemeSearches[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _executeSearchSchemes(trimmed, langCode);
    _inFlightSchemeSearches[cacheKey] = future;

    try {
      final results = await future;
      _searchSchemesCache[cacheKey] = _CachedSearch(results);
      return results;
    } finally {
      _inFlightSchemeSearches.remove(cacheKey);
    }
  }

  Future<List<Scheme>> _executeSearchSchemes(
    String query,
    String langCode,
  ) async {
    final matches = await searchSchemeMatchesOffline(query, langCode: langCode);
    return matches.map((match) => match.scheme).toList(growable: false);
  }

  // ── 7. searchSchemeMatches() ──────────────────────────────────────────
  /// Returns scored matches for conversational search and voice result UIs.
  /// 100% on-device search via HybridSchemeSearch over MssCatalogBundle.
  /// Deduplicated in-flight and memoized for 15s to eliminate redundant CPU ranking work.
  Future<List<SchemeSearchMatch>> searchSchemeMatches(
    String query, {
    int? limit,
    String langCode = 'en',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      final all = await getAllSchemes(langCode: langCode);
      final slice = limit != null ? all.take(limit) : all;
      return slice
          .map(
            (s) => SchemeSearchMatch(scheme: s, score: 1.0, reasons: const []),
          )
          .toList();
    }

    final cacheKey = '$langCode:$limit:${trimmed.toLowerCase()}';

    // 1. Fresh memoized cache check
    final cached = _searchMatchesCache[cacheKey];
    if (cached != null && cached.isFresh) {
      return cached.data;
    }

    // 2. Singleflight deduplication
    final inFlight = _inFlightMatchSearches[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _executeSearchSchemeMatches(trimmed, limit, langCode);
    _inFlightMatchSearches[cacheKey] = future;

    try {
      final results = await future;
      _searchMatchesCache[cacheKey] = _CachedSearch(results);
      return results;
    } finally {
      _inFlightMatchSearches.remove(cacheKey);
    }
  }

  Future<List<SchemeSearchMatch>> _executeSearchSchemeMatches(
    String query,
    int? limit,
    String langCode,
  ) async {
    return searchSchemeMatchesOffline(query, limit: limit, langCode: langCode);
  }

  /// Offline rank fallback for searchSchemeMatches
  Future<List<SchemeSearchMatch>> searchSchemeMatchesOffline(
    String query, {
    int? limit,
    String langCode = 'en',
  }) async {
    final bundle = await _loadBundle();
    return await HybridSchemeSearch.rank(
      query,
      bundle,
      limit: limit,
      langCode: langCode,
    );
  }

  /// Ranks an already-filtered (category/ministry/state) offline listing by
  /// the same relevance engine [searchSchemes] uses, instead of leaving it in
  /// arbitrary catalog order. Does NOT drop members with a zero score --
  /// this is a ranking pass over a completeness-first filter, not a second
  /// search; a scheme legitimately in the category that just doesn't share
  /// keywords with [label] still belongs in the results.
  Future<List<Scheme>> _rankByQuery(List<Scheme> matches, String label) async {
    if (matches.length <= 1) return matches;
    final bundle = await _loadBundle();
    final scores = (await HybridSchemeSearch.build(bundle)).scoreByQuery(label);
    final ranked = List<Scheme>.from(matches);
    ranked.sort((a, b) {
      final scoreCmp = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
      return scoreCmp != 0 ? scoreCmp : a.id.compareTo(b.id);
    });
    return ranked;
  }

  // ── 8. getSchemesByCategory() ─────────────────────────────────────────
  /// Returns schemes matching a specific category key. Offline-only.
  Future<List<Scheme>> getSchemesByCategory(
    String category, {
    String langCode = 'en',
  }) async {
    if (category.trim().isEmpty) return getAllSchemes(langCode: langCode);
    return _getSchemesByCategoryOffline(category, langCode: langCode);
  }

  Future<List<Scheme>> _getSchemesByCategoryOffline(
    String category, {
    String langCode = 'en',
  }) async {
    final q = category.toLowerCase().trim();
    final all = await getAllSchemes(langCode: langCode);

    final matches = all.where((s) {
      final cat = s.category.toLowerCase();
      final type = s.schemeType.toLowerCase();
      final target = s.targetBeneficiary.toLowerCase();
      final kw = s.searchKeywords.toLowerCase();
      final sector = s.sector.toLowerCase();
      final canonicalText =
          '${s.name} ${s.shortName} ${s.schemeType} ${s.category} ${s.sector} ${s.searchKeywords} ${s.overview}'
              .toLowerCase();
      final fullText = '$canonicalText ${s.benefits}'.toLowerCase();

      if (q == 'msme') {
        return cat.contains('msme') ||
            sector.contains('msme') ||
            target.contains('msme') ||
            canonicalText.contains('micro') ||
            canonicalText.contains('udyam');
      }
      if (q == 'startup') {
        return cat.contains('startup') ||
            kw.contains('startup') ||
            kw.contains('dpiit') ||
            canonicalText.contains('incubator') ||
            canonicalText.contains('seed fund');
      }
      if (q == 'women entrepreneurs' || q == 'women') {
        return target.contains('women') ||
            kw.contains('women') ||
            target.contains('female') ||
            canonicalText.contains('mahila') ||
            canonicalText.contains('stree');
      }
      if (q == 'business loans & credit' || q == 'loans') {
        return type.contains('loan') ||
            cat.contains('loan') ||
            cat.contains('credit') ||
            canonicalText.contains('loan') ||
            canonicalText.contains('credit') ||
            canonicalText.contains('mudra') ||
            canonicalText.contains('cgtmse') ||
            canonicalText.contains('working capital') ||
            canonicalText.contains('term loan') ||
            canonicalText.contains('svanidhi') ||
            canonicalText.contains('standup') ||
            canonicalText.contains('financing') ||
            canonicalText.contains('collateral-free') ||
            canonicalText.contains('collateral free');
      }
      if (q == 'shg & artisan' || q == 'artisan') {
        return target.contains('artisan') ||
            target.contains('shg') ||
            kw.contains('vishwakarma') ||
            kw.contains('weaver') ||
            canonicalText.contains('craftsman');
      }
      if (q == 'technology') {
        return cat.contains('tech') ||
            sector.contains('tech') ||
            kw.contains('technology') ||
            canonicalText.contains('digital') ||
            canonicalText.contains('r&d');
      }
      if (q == 'manufacturing') {
        return sector.contains('manufactur') ||
            cat.contains('manufactur') ||
            kw.contains('manufacturing') ||
            canonicalText.contains('production') ||
            canonicalText.contains('factory');
      }
      if (q == 'export & trade promotion' || q == 'export') {
        return cat.contains('export') ||
            sector.contains('export') ||
            kw.contains('export') ||
            canonicalText.contains('trade promotion') ||
            canonicalText.contains('exhibition');
      }

      if (q.contains('export') ||
          q.contains('trade') ||
          q.contains('foreign')) {
        return cat.contains('export') ||
            sector.contains('export') ||
            kw.contains('export') ||
            fullText.contains('export') ||
            fullText.contains('trade') ||
            fullText.contains('dgft') ||
            fullText.contains('customs') ||
            fullText.contains('ship');
      }

      if (q.contains('grow') ||
          q.contains('growth') ||
          q.contains('expand') ||
          q.contains('scaling')) {
        return cat.contains('msme') ||
            cat.contains('business') ||
            type.contains('subsidy') ||
            kw.contains('growth') ||
            fullText.contains('growth') ||
            fullText.contains('expansion') ||
            fullText.contains('moderniz') ||
            fullText.contains('subsidy') ||
            fullText.contains('technology') ||
            fullText.contains('incentive') ||
            fullText.contains('scale');
      }

      if (q.contains('fund') ||
          q.contains('financ') ||
          q.contains('loan') ||
          q.contains('credit') ||
          q.contains('capital') ||
          q.contains('money')) {
        return type.contains('loan') ||
            cat.contains('loan') ||
            cat.contains('credit') ||
            cat.contains('finance') ||
            fullText.contains('loan') ||
            fullText.contains('credit') ||
            fullText.contains('fund') ||
            fullText.contains('mudra') ||
            fullText.contains('cgtmse') ||
            fullText.contains('capital') ||
            fullText.contains('grant') ||
            fullText.contains('subsidy') ||
            fullText.contains('working capital');
      }

      if (q.contains('start') ||
          q.contains('launch') ||
          q.contains('startup') ||
          q.contains('incubat')) {
        return cat.contains('startup') ||
            kw.contains('startup') ||
            kw.contains('dpiit') ||
            fullText.contains('incubator') ||
            fullText.contains('seed fund') ||
            fullText.contains('pmegp') ||
            fullText.contains('mudra') ||
            fullText.contains('entrepreneur') ||
            fullText.contains('start') ||
            fullText.contains('new business');
      }

      if (q.contains('udyam') || q.contains('register')) {
        return cat.contains('msme') ||
            fullText.contains('udyam') ||
            fullText.contains('register') ||
            fullText.contains('compliance') ||
            fullText.contains('msme');
      }

      if (q == 'msme' || q.contains('msme')) {
        return cat.contains('msme') ||
            sector.contains('msme') ||
            target.contains('msme') ||
            fullText.contains('micro') ||
            fullText.contains('udyam') ||
            fullText.contains('small');
      }

      if (q.contains('women') || q.contains('female') || q.contains('mahila')) {
        return target.contains('women') ||
            kw.contains('women') ||
            target.contains('female') ||
            fullText.contains('mahila') ||
            fullText.contains('stree');
      }

      if (q.contains('shg') || q.contains('artisan') || q.contains('craft')) {
        return target.contains('artisan') ||
            target.contains('shg') ||
            kw.contains('vishwakarma') ||
            kw.contains('weaver') ||
            fullText.contains('craftsman');
      }

      if (q.contains('tech') || q.contains('digital')) {
        return cat.contains('tech') ||
            sector.contains('tech') ||
            kw.contains('technology') ||
            fullText.contains('digital') ||
            fullText.contains('r&d');
      }

      if (q.contains('manufactur') ||
          q.contains('factory') ||
          q.contains('product')) {
        return sector.contains('manufactur') ||
            cat.contains('manufactur') ||
            kw.contains('manufacturing') ||
            fullText.contains('production') ||
            fullText.contains('factory');
      }

      final words = q.split(' ').where((w) => w.length > 2);
      for (final w in words) {
        if (cat.contains(w) ||
            sector.contains(w) ||
            target.contains(w) ||
            fullText.contains(w)) {
          return true;
        }
      }

      return cat.contains(q) ||
          sector.contains(q) ||
          target.contains(q) ||
          fullText.contains(q);
    }).toList();

    if (matches.isEmpty) {
      final fallback = all
          .where(
            (s) =>
                s.category.toLowerCase().contains('business') ||
                s.category.toLowerCase().contains('msme') ||
                s.sector.toLowerCase().contains('msme'),
          )
          .toList();
      return _rankByQuery(fallback, category);
    }

    return _rankByQuery(matches, category);
  }

  // ── 9. getSchemesByMinistry() ─────────────────────────────────────────
  /// Returns schemes sponsored or issued by a given ministry/department.
  /// Offline-only.
  Future<List<Scheme>> getSchemesByMinistry(String ministry) async {
    if (ministry.trim().isEmpty) return getAllSchemes();

    final q = ministry.toLowerCase().trim();
    final all = await getAllSchemes();

    final matches = all.where((s) {
      final sponsor = s.sponsoringBody.toLowerCase();
      final issuer = s.issuingBody.toLowerCase();
      final fullText = '${s.name} ${s.shortName} ${s.searchKeywords}'
          .toLowerCase();

      if (q.contains('msme') || q.contains('micro, small')) {
        return sponsor.contains('msme') ||
            sponsor.contains('micro, small') ||
            issuer.contains('msme') ||
            issuer.contains('micro, small') ||
            fullText.contains('msme') ||
            s.category.toLowerCase().contains('msme');
      }
      if (q.contains('finance')) {
        return sponsor.contains('finance') ||
            issuer.contains('finance') ||
            fullText.contains('finance') ||
            fullText.contains('financial') ||
            fullText.contains('banking');
      }
      if (q.contains('rural')) {
        return sponsor.contains('rural') ||
            issuer.contains('rural') ||
            fullText.contains('rural');
      }
      if (q.contains('education')) {
        return sponsor.contains('education') ||
            issuer.contains('education') ||
            fullText.contains('education') ||
            fullText.contains('student');
      }
      if (q.contains('agriculture') || q.contains('farmer')) {
        return sponsor.contains('agriculture') ||
            issuer.contains('agriculture') ||
            fullText.contains('agriculture') ||
            fullText.contains('farmer');
      }
      if (q.contains('skill')) {
        return sponsor.contains('skill') ||
            issuer.contains('skill') ||
            fullText.contains('skill') ||
            fullText.contains('vocational');
      }
      if (q.contains('social justice')) {
        return sponsor.contains('social justice') ||
            issuer.contains('social justice') ||
            fullText.contains('social justice');
      }
      if (q.contains('housing') || q.contains('urban')) {
        return sponsor.contains('housing') ||
            sponsor.contains('urban') ||
            issuer.contains('housing') ||
            issuer.contains('urban') ||
            fullText.contains('housing');
      }
      if (q.contains('health')) {
        return sponsor.contains('health') ||
            issuer.contains('health') ||
            fullText.contains('health') ||
            fullText.contains('ayushman');
      }

      return sponsor.contains(q) || issuer.contains(q) || fullText.contains(q);
    }).toList();
    return _rankByQuery(matches, ministry);
  }

  // ── 10. getSchemesByState() ───────────────────────────────────────────
  /// Returns schemes applicable to a specific state or All India.
  /// Offline-only.
  Future<List<Scheme>> getSchemesByState(String state) async {
    if (state.trim().isEmpty) return getAllSchemes();

    final q = state.toLowerCase().trim();
    final all = await getAllSchemes();

    final matches = all.where((s) {
      final st = s.state.toLowerCase();
      final code = s.schemeCode.toLowerCase();
      final name = s.name.toLowerCase();
      final isCentral =
          s.governmentLevel.toLowerCase() == 'central' ||
          st.contains('all india') ||
          st.isEmpty;

      if (q.contains('tamil nadu') || q == 'tn') {
        return isCentral ||
            st.contains('tamil') ||
            st.contains('tn') ||
            code.contains('tn_') ||
            name.contains('tamil');
      }

      return isCentral ||
          st.contains(q) ||
          code.contains(q) ||
          name.contains(q);
    }).toList();
    return _rankByQuery(matches, state);
  }

  // ── 11. getSchemeById() ───────────────────────────────────────────────
  /// Loads a Scheme by ID or Code in O(1) time. Offline-only.
  Future<Scheme?> getSchemeById(String id, {String langCode = 'en'}) async {
    if (id.trim().isEmpty) return null;

    await getAllSchemes(langCode: langCode);
    final key = id.trim().toLowerCase();
    final cached = _schemeByIdMap?[key];
    if (cached != null) return cached;

    try {
      final bundle = await _loadBundle();
      final entity = bundle.getEntity(id);
      if (entity != null && entity.entityType == 'scheme') {
        return MssSchemeAdapter.toScheme(entity, bundle, langCode: langCode);
      }
    } catch (e) {
      debugPrint('[SchemeRepository] getSchemeById offline fallback error: $e');
    }

    return null;
  }

  // ── 12. getRecommendedSchemes() ───────────────────────────────────────
  /// Returns schemes ranked by relevance to the user's profile. Offline-only
  /// via the local RecommendationEngine scoring pass.
  Future<List<Scheme>> getRecommendedSchemes(UserProfile profile) async {
    final all = await getAllSchemes();

    final scored = all.map((s) {
      double score = 0.5;

      final keywords = '${s.searchKeywords} ${s.targetBeneficiary} ${s.sector}'
          .toLowerCase();

      if (s.state.toLowerCase() == 'all india') score += 0.1;
      if (profile.state.isNotEmpty &&
          s.state.toLowerCase().contains(profile.state.toLowerCase())) {
        score += 0.2;
      }

      if (profile.gender.toLowerCase() == 'female' &&
          keywords.contains('women')) {
        score += 0.15;
      }

      if ((profile.community.toLowerCase() == 'sc' ||
              profile.community.toLowerCase() == 'st') &&
          (keywords.contains('sc/st') || keywords.contains('scheduled'))) {
        score += 0.15;
      }

      if (profile.businessStage.isNotEmpty &&
          keywords.contains(profile.businessStage.toLowerCase())) {
        score += 0.15;
      }

      if (profile.businessIndustry.isNotEmpty &&
          keywords.contains(profile.businessIndustry.toLowerCase())) {
        score += 0.1;
      }

      if ((profile.fundingRequired) > 0 &&
          s.maxFunding != null &&
          s.maxFunding! >= profile.fundingRequired) {
        score += 0.1;
      }

      return MapEntry(s, score.clamp(0.0, 1.0));
    }).toList();

    scored.sort((a, b) {
      final scoreCmp = b.value.compareTo(a.value);
      return scoreCmp != 0 ? scoreCmp : a.key.id.compareTo(b.key.id);
    });
    return scored.map((e) => e.key).toList();
  }

  // ── 13. getSavedSchemes() ─────────────────────────────────────────────
  /// Returns schemes for a list of bookmarked scheme IDs.
  /// Evaluates each ID via getSchemeById (online-first with offline fallback).
  Future<List<Scheme>> getSavedSchemes(List<String> bookmarkedIds) async {
    if (bookmarkedIds.isEmpty) return [];

    final schemes = <Scheme>[];
    for (final id in bookmarkedIds) {
      final s = await getSchemeById(id);
      if (s != null) schemes.add(s);
    }
    if (schemes.isNotEmpty) return schemes;

    final all = await getAllSchemes();
    return all
        .where(
          (s) =>
              bookmarkedIds.contains(s.id) ||
              bookmarkedIds.contains(s.schemeCode),
        )
        .toList();
  }

  // ── Profile Database Management Methods (Supabase — UNCHANGED) ────────

  /// Retrieves a user profile by their UUID from public.profiles table.
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final rows = await _db
          .from('profiles')
          .select()
          .eq('id', uid)
          .limit(1)
          .timeout(const Duration(seconds: 8));
      if ((rows as List).isEmpty) {
        debugPrint('[SchemeRepository] No profile found for user UUID: $uid');
        return null;
      }
      final merged = Map<String, dynamic>.from(rows[0] as Map);

      // The app collects business/applicant fields but stores them in a
      // separate table (startup_profiles). getProfile() replaces the whole
      // in-memory profile, so without this merge those fields silently
      // reset to defaults on every login / background sync.
      try {
        final startup = await _db
            .from('startup_profiles')
            .select('industry, business_stage, business_registered, '
                'funding_required_amount, registration_numbers')
            .eq('user_id', uid)
            .order('is_active', ascending: false)
            .limit(1)
            .timeout(const Duration(seconds: 8));
        if ((startup as List).isNotEmpty) {
          (startup[0] as Map).forEach((k, v) {
            if (v != null) merged.putIfAbsent(k.toString(), () => v);
          });
        }
      } catch (e) {
        debugPrint('[SchemeRepository] startup_profiles fetch skipped: $e');
      }
      return UserProfile.fromJson(merged);
    } catch (e) {
      debugPrint('[SchemeRepository] Error fetching profile: $e');
      return null;
    }
  }

  /// Creates a new profile record in the database.
  Future<void> createProfile(UserProfile profile) async {
    try {
      debugPrint(
        '[SchemeRepository] Creating profile for user UUID: ${profile.googleUserId}',
      );
      await _db
          .from('profiles')
          .upsert(profile.toSupabase())
          .timeout(const Duration(seconds: 15));
      debugPrint('[SchemeRepository] Profile successfully created.');
    } catch (e) {
      debugPrint('[SchemeRepository] Error creating profile: $e');
      rethrow;
    }
  }

  /// Updates an existing profile record in the database.
  Future<void> updateProfile(UserProfile profile) async {
    try {
      debugPrint(
        '[SchemeRepository] Updating profile for user UUID: ${profile.googleUserId}',
      );
      await _db
          .from('profiles')
          .update(profile.toSupabase())
          .eq('id', profile.googleUserId)
          .timeout(const Duration(seconds: 15));
      debugPrint('[SchemeRepository] Profile successfully updated.');
    } catch (e) {
      debugPrint('[SchemeRepository] Error updating profile: $e');
      rethrow;
    }
  }

  /// Updates the last login timestamp for the user.
  Future<void> updateLastLogin(String uid) async {
    try {
      debugPrint(
        '[SchemeRepository] Updating last login timestamp for user UUID: $uid',
      );
      await _db
          .from('profiles')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', uid);
      debugPrint(
        '[SchemeRepository] Last login timestamp successfully updated.',
      );
    } catch (e) {
      debugPrint('[SchemeRepository] Error updating last login: $e');
    }
  }
}

/// Simple in-memory search memoization record with TTL checking
class _CachedSearch<T> {
  _CachedSearch(this.data) : timestamp = DateTime.now();
  final T data;
  final DateTime timestamp;

  bool get isFresh =>
      DateTime.now().difference(timestamp) < SchemeRepository._searchCacheTtl;
}
