import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mss_models.dart';
import '../models/scheme_model.dart';
import '../models/user_profile.dart';
import 'hybrid_scheme_search.dart';
import 'intelligent_scheme_search.dart' show SchemeSearchMatch;
import 'mss_api_client.dart';
import 'mss_catalog_bundle.dart';
import 'mss_scheme_adapter.dart';
import '../engine/recommendation_engine.dart';

extension _UserProfileApiMapping on UserProfile {
  Map<String, dynamic> toApiProfile() {
    final m = <String, dynamic>{};
    if (state.isNotEmpty) m['state'] = state;
    if (gender.isNotEmpty) m['gender'] = gender;
    if (community.isNotEmpty) m['community'] = community;
    if (businessStage.isNotEmpty) m['businessStage'] = businessStage;
    if (businessIndustry.isNotEmpty) m['sector'] = businessIndustry;
    if (employmentStatus.isNotEmpty) m['employmentStatus'] = employmentStatus;
    return m;
  }
}

/// SchemeRepository
/// ─────────────────
/// Single source of truth for all scheme-related data.
/// Powered by an online-first network policy over MssApiClient with graceful
/// fallback to the offline MssCatalogBundle.
class SchemeRepository {
  SchemeRepository._({MssApiClient? apiClient})
      : _apiClient = apiClient ?? MssApiClient();

  static final SchemeRepository instance = SchemeRepository._();

  /// Create a repository instance with a custom or mocked MssApiClient (e.g. for testing).
  factory SchemeRepository.withApiClient(MssApiClient apiClient) =>
      SchemeRepository._(apiClient: apiClient);

  final MssApiClient _apiClient;
  SupabaseClient get _db => Supabase.instance.client;

  // ── In-memory cache ──────────────────────────────────────────────────
  List<Scheme>? _cachedSchemes;
  Map<String, Scheme>? _schemeByIdMap;
  String? _cachedLanguage;
  Future<MssCatalogBundle>? _bundleFuture;
  Map<String, int>? _cachedCategoryCounts;

  void clearCache() {
    _cachedSchemes = null;
    _schemeByIdMap = null;
    _cachedLanguage = null;
    _bundleFuture = null;
    _cachedCategoryCounts = null;
  }

  /// Determines whether an error is retryable (network/timeout/5xx) so offline
  /// catalog fallback should be triggered, vs non-retryable (e.g., 404/400)
  /// which should be allowed to throw or return null/empty.
  bool _isRetryableError(Object e) {
    if (e is MssApiException) {
      return e.isRetryable;
    }
    // Network/socket/timeout/parse errors are retryable connectivity issues
    return true;
  }

  Future<MssCatalogBundle> _loadBundle() =>
      _bundleFuture ??= MssCatalogBundle.load();

  // ── 1. getTotalSchemeCount() ──────────────────────────────────────────
  /// Returns total number of schemes from server metadata, with offline count fallback.
  Future<int> getTotalSchemeCount() async {
    try {
      final rawJson = await _apiClient.getMetadata();
      final meta = MssMeta.fromJson(rawJson);
      if (meta.entityCounts.containsKey('scheme')) {
        return meta.entityCounts['scheme']!;
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] getTotalSchemeCount online error: $e');
    }

    final schemes = await getAllSchemes();
    return schemes.length;
  }

  // ── 2. getTopRecommendedSchemes() ─────────────────────────────────────
  /// Returns top [limit] recommended schemes for user profile sorted by relevance score.
  Future<List<Scheme>> getTopRecommendedSchemes(
    UserProfile profile, {
    int limit = 5,
  }) async {
    try {
      final recommended = await getRecommendedSchemes(profile);
      if (recommended.isNotEmpty) {
        return recommended.take(limit).toList();
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] getTopRecommendedSchemes online error: $e');
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
  /// Intentionally local to avoid 8 sequential network roundtrips on UI build.
  Future<Map<String, int>> getCategoryCounts(
    UserProfile profile, {
    String activeFilter = 'All',
  }) async {
    if (_cachedCategoryCounts != null && activeFilter == 'All') {
      return _cachedCategoryCounts!;
    }

    final Map<String, int> counts = {};
    final categoriesToQuery = [
      "MSME",
      "Startup",
      "Women Entrepreneurs",
      "Business Loans & Credit",
      "SHG & Artisan",
      "Technology",
      "Manufacturing",
      "Export & Trade Promotion",
    ];

    for (final cat in categoriesToQuery) {
      final matches = await getSchemesByCategory(cat);
      counts[cat] = matches.length;
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
  /// Intelligently ranks natural-language English, Tamil, and Tanglish queries.
  /// Online-first via POST /v1/search with offline fallback.
  Future<List<Scheme>> searchSchemes(
    String query, {
    String langCode = 'en',
  }) async {
    if (query.trim().isEmpty) return getAllSchemes(langCode: langCode);

    try {
      final rawJson = await _apiClient.search(
        query: query,
        language: langCode,
      );
      final searchResp = MSSSearchResponse.fromJson(rawJson);
      if (searchResp.results.isNotEmpty) {
        final bundle = await _loadBundle();
        return searchResp.results
            .map((r) => MssSchemeAdapter.schemeResultToScheme(
                  r,
                  bundle,
                  langCode: langCode,
                ))
            .toList();
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] online search failed, falling back offline: $e');
    }

    // Offline fallback
    final matches = await searchSchemeMatchesOffline(query, langCode: langCode);
    return matches.map((match) => match.scheme).toList(growable: false);
  }

  // ── 7. searchSchemeMatches() ──────────────────────────────────────────
  /// Returns scored matches for conversational search and voice result UIs.
  /// Online-first via POST /v1/search with offline fallback.
  Future<List<SchemeSearchMatch>> searchSchemeMatches(
    String query, {
    int? limit,
    String langCode = 'en',
  }) async {
    if (query.trim().isEmpty) {
      final all = await getAllSchemes(langCode: langCode);
      final slice = limit != null ? all.take(limit) : all;
      return slice
          .map((s) => SchemeSearchMatch(scheme: s, score: 1.0, reasons: const []))
          .toList();
    }

    try {
      final rawJson = await _apiClient.search(
        query: query,
        language: langCode,
        limit: limit,
      );
      final searchResp = MSSSearchResponse.fromJson(rawJson);
      if (searchResp.results.isNotEmpty) {
        final bundle = await _loadBundle();
        return searchResp.results.map((r) {
          final scheme = MssSchemeAdapter.schemeResultToScheme(
            r,
            bundle,
            langCode: langCode,
          );
          var reasons = r.matchReasons
              .map((m) => m.detail)
              .where((d) => d.isNotEmpty)
              .toList();
          if (reasons.isEmpty && r.explanation.summary.isNotEmpty) {
            reasons = [r.explanation.summary];
          }
          return SchemeSearchMatch(
            scheme: scheme,
            score: r.matchScore,
            reasons: reasons,
          );
        }).toList();
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] online searchSchemeMatches failed: $e');
    }

    return searchSchemeMatchesOffline(query, limit: limit, langCode: langCode);
  }

  /// Offline rank fallback for searchSchemeMatches
  Future<List<SchemeSearchMatch>> searchSchemeMatchesOffline(
    String query, {
    int? limit,
    String langCode = 'en',
  }) async {
    final bundle = await _loadBundle();
    return HybridSchemeSearch.rank(
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
    final scores = HybridSchemeSearch.build(bundle).scoreByQuery(label);
    final ranked = List<Scheme>.from(matches);
    ranked.sort((a, b) {
      final scoreCmp = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
      return scoreCmp != 0 ? scoreCmp : a.id.compareTo(b.id);
    });
    return ranked;
  }

  // ── 8. getSchemesByCategory() ─────────────────────────────────────────
  /// Returns schemes matching a specific category key.
  /// Online-first via POST /v1/search with offline category predicate fallback.
  Future<List<Scheme>> getSchemesByCategory(
    String category, {
    String langCode = 'en',
  }) async {
    if (category.trim().isEmpty) return getAllSchemes(langCode: langCode);

    try {
      final rawJson = await _apiClient.search(
        query: category,
        language: langCode,
      );
      final searchResp = MSSSearchResponse.fromJson(rawJson);
      if (searchResp.results.isNotEmpty) {
        final bundle = await _loadBundle();
        return searchResp.results
            .map((r) => MssSchemeAdapter.schemeResultToScheme(
                  r,
                  bundle,
                  langCode: langCode,
                ))
            .toList();
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] online category search failed: $e');
    }

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

      if (q.contains('export') || q.contains('trade') || q.contains('foreign')) {
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
  /// Online-first via POST /v1/search with offline fallback.
  Future<List<Scheme>> getSchemesByMinistry(String ministry) async {
    if (ministry.trim().isEmpty) return getAllSchemes();

    try {
      final rawJson = await _apiClient.search(query: ministry);
      final searchResp = MSSSearchResponse.fromJson(rawJson);
      if (searchResp.results.isNotEmpty) {
        final bundle = await _loadBundle();
        return searchResp.results
            .map((r) => MssSchemeAdapter.schemeResultToScheme(r, bundle))
            .toList();
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] online getSchemesByMinistry error: $e');
    }

    final q = ministry.toLowerCase().trim();
    final all = await getAllSchemes();

    final matches = all.where((s) {
      final sponsor = s.sponsoringBody.toLowerCase();
      final issuer = s.issuingBody.toLowerCase();
      final fullText = '${s.name} ${s.shortName} ${s.searchKeywords}'
          .toLowerCase();

      return sponsor.contains(q) || issuer.contains(q) || fullText.contains(q);
    }).toList();
    return _rankByQuery(matches, ministry);
  }

  // ── 10. getSchemesByState() ───────────────────────────────────────────
  /// Returns schemes applicable to a specific state or All India.
  /// Online-first via POST /v1/search (profile.state) with offline fallback.
  Future<List<Scheme>> getSchemesByState(String state) async {
    if (state.trim().isEmpty) return getAllSchemes();

    try {
      final rawJson = await _apiClient.search(
        query: state,
        profile: {'state': state},
      );
      final searchResp = MSSSearchResponse.fromJson(rawJson);
      if (searchResp.results.isNotEmpty) {
        final bundle = await _loadBundle();
        return searchResp.results
            .map((r) => MssSchemeAdapter.schemeResultToScheme(r, bundle))
            .toList();
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] online getSchemesByState error: $e');
    }

    final q = state.toLowerCase().trim();
    final all = await getAllSchemes();

    final matches = all.where((s) {
      final st = s.state.toLowerCase();
      final code = s.schemeCode.toLowerCase();
      final name = s.name.toLowerCase();

      if (q.contains('tamil nadu') || q == 'tn') {
        return st.contains('tamil') ||
            st.contains('tn') ||
            code.contains('tn_') ||
            name.contains('tamil');
      }

      return st.contains(q) || code.contains(q) || name.contains(q);
    }).toList();
    return _rankByQuery(matches, state);
  }

  // ── 11. getSchemeById() ───────────────────────────────────────────────
  /// Loads a Scheme by ID or Code in O(1) time.
  /// Online-first via GET /v1/schemes/{id} with offline fallback.
  /// Non-retryable 404 / UNKNOWN_SCHEME returns null without falling back.
  Future<Scheme?> getSchemeById(String id, {String langCode = 'en'}) async {
    if (id.trim().isEmpty) return null;

    try {
      final rawJson = await _apiClient.getSchemeDetail(id, lang: langCode);
      final intel = MssSchemeIntelligence.fromJson(rawJson);
      final bundle = await _loadBundle();
      return MssSchemeAdapter.schemeIntelligenceToScheme(
        intel,
        bundle,
        langCode: langCode,
      );
    } catch (e) {
      if (e is MssApiException &&
          (e.statusCode == 404 || e.code == 'UNKNOWN_SCHEME')) {
        // Genuine 404 / UNKNOWN_SCHEME: non-retryable "not found", return null
        return null;
      }
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] online getSchemeById error: $e');
    }

    // Offline fallback
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
  /// Returns schemes ranked by relevance to the user's profile.
  /// Online-first via POST /v1/eligibility with offline RecommendationEngine fallback.
  Future<List<Scheme>> getRecommendedSchemes(UserProfile profile) async {
    try {
      final rawJson = await _apiClient.checkEligibility(
        profile: profile.toApiProfile(),
        onlyEligible: false,
      );
      final elResp = MssApplicabilityResponse.fromJson(rawJson);
      if (elResp.results.isNotEmpty) {
        final schemes = <Scheme>[];
        for (final item in elResp.results) {
          final s = await getSchemeById(item.schemeId);
          if (s != null) schemes.add(s);
        }
        if (schemes.isNotEmpty) return schemes;
      }
    } catch (e) {
      if (!_isRetryableError(e)) rethrow;
      debugPrint('[SchemeRepository] online getRecommendedSchemes error: $e');
    }

    // Offline RecommendationEngine fallback
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
      final rows = await _db.from('profiles').select().eq('id', uid).limit(1);
      if ((rows as List).isEmpty) {
        debugPrint('[SchemeRepository] No profile found for user UUID: $uid');
        return null;
      }
      return UserProfile.fromJson(rows[0]);
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
      await _db.from('profiles').upsert(profile.toSupabase());
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
          .eq('id', profile.googleUserId);
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
