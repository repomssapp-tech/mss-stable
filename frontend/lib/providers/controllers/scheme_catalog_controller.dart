import 'package:flutter/foundation.dart';

import '../../services/recommendation/recommendation_engine.dart';
import '../../models/scheme_model.dart';
import '../../models/user_profile.dart';
import '../../services/catalog/scheme_catalog_sync_service.dart';
import '../../services/catalog/scheme_repository.dart';

/// Owns the loaded scheme catalog (`_allSchemes`), the ranked
/// `recommendedSchemes` list, the load/error flags, and the background
/// catalog-sync state, plus the `loadSchemes` / `syncSchemeCatalog` flows.
///
/// Extracted from `AppProvider` (frontend refactor C1.4, slice 7) and used
/// behind the `AppProvider` facade: `AppProvider` forwards this controller's
/// `notifyListeners`, so `provider.allSchemes` / `provider.recommendedSchemes`
/// / `provider.loadSchemes()` / `provider.syncSchemeCatalog()` keep working
/// unchanged.
///
/// The catalog list depends on the user's profile (for ranking) and the
/// selected language (for the repository query), both of which stay on
/// `AppProvider`. Rather than duplicate that state here, `loadSchemes` /
/// `syncSchemeCatalog` / [recomputeRecommendations] take the current
/// `langCode` + `profile` as arguments — `AppProvider` passes `_selectedLanguage`
/// and `_profile` at each call site, exactly the values the pre-split code read.
///
/// Notify topology is unchanged: `loadSchemes` notifies twice (loading on,
/// loading off) and `syncSchemeCatalog` notifies at the same points as before,
/// all forwarded. [recomputeRecommendations] is deliberately SILENT — its
/// `AppProvider` call sites (the auth-state listener, the realtime profile
/// stream, `updateProfile`) each emit an `AppProvider` notification immediately
/// afterwards.
class SchemeCatalogController extends ChangeNotifier {
  SchemeCatalogController({SchemeCatalogSyncService? catalogSyncService})
    : _catalogSyncService =
          catalogSyncService ?? SchemeCatalogSyncService.instance;

  final SchemeCatalogSyncService _catalogSyncService;

  // ── Scheme data (loaded from the bundled catalog via SchemeRepository) ──────────
  List<Scheme> _allSchemes = [];
  List<MapEntry<Scheme, RecommendationResult>> _recommendedSchemes = [];
  bool _schemesLoading = false;
  String? _schemesError;
  CatalogSyncResult? _catalogSyncResult;
  bool _catalogSyncing = false;

  List<Scheme> get allSchemes => _allSchemes;

  /// True once the catalog has loaded at least one scheme. Used by the
  /// auth-state listener to avoid clobbering a good ranking with an empty one
  /// before the first `loadSchemes` completes.
  bool get hasSchemes => _allSchemes.isNotEmpty;

  // Recommended schemes (ranked by RecommendationEngine against cached list)
  List<MapEntry<Scheme, RecommendationResult>> get recommendedSchemes =>
      _recommendedSchemes;

  // Scheme loading state
  bool get schemesLoading => _schemesLoading;
  String? get schemesError => _schemesError;
  CatalogSyncResult? get catalogSyncResult => _catalogSyncResult;
  bool get catalogSyncing => _catalogSyncing;

  String get catalogStatusLabel {
    final manifest = _catalogSyncResult?.manifest;
    if (manifest == null) return 'Bundled · ${_allSchemes.length} schemes';
    final date = manifest.publishedAt.toLocal();
    return 'v${manifest.version} · ${date.day}/${date.month}/${date.year}';
  }

  bool _recommendationsOverriddenForTesting = false;
  bool _allSchemesOverriddenForTesting = false;

  /// Test-only seam, reached through `AppProvider.setRecommendedSchemesForTesting`
  /// (which carries the `@visibleForTesting` annotation). Pins the ranked list
  /// and makes `loadSchemes` stop recomputing it.
  void setRecommendedSchemesForTesting(
    List<MapEntry<Scheme, RecommendationResult>> schemes,
  ) {
    _recommendationsOverriddenForTesting = true;
    _recommendedSchemes = schemes;
    notifyListeners();
  }

  /// Test-only seam, reached through `AppProvider.setAllSchemesForTesting`.
  /// Pins `allSchemes` (and therefore `bookmarkedSchemes` /
  /// `recentlyViewedSchemes`, which filter it by id) without a network call,
  /// and makes `loadSchemes` stop overwriting it.
  void setAllSchemesForTesting(List<Scheme> schemes) {
    _allSchemesOverriddenForTesting = true;
    _allSchemes = schemes;
    notifyListeners();
  }

  /// Recompute the ranked list against [profile] and the currently loaded
  /// catalog. Silent — the caller notifies. Matches the pre-split inline
  /// recompute at the auth-listener / profile-stream / `updateProfile` sites,
  /// which were unconditional (they did not consult the testing override).
  void recomputeRecommendations(UserProfile profile) {
    _recommendedSchemes = RecommendationEngine.getRecommendations(
      profile,
      _allSchemes,
    );
  }

  // Load (or reload) all schemes and recompute recommendations
  ///
  /// A request that arrives while a load is running is queued and re-run once
  /// the current load finishes (latest parameters win, `forceRefresh` sticks),
  /// and the returned future completes only after that re-run. Previously the
  /// late request was dropped, so a language switch during the startup load
  /// left the schemes adapted for the old language.
  Future<void> loadSchemes({
    required String langCode,
    required UserProfile profile,
    bool forceRefresh = false,
  }) {
    final running = _inFlightLoad;
    if (running != null) {
      _queuedLoad = (
        langCode: langCode,
        profile: profile,
        forceRefresh: forceRefresh || (_queuedLoad?.forceRefresh ?? false),
      );
      return running;
    }
    final run = _drainLoads((
      langCode: langCode,
      profile: profile,
      forceRefresh: forceRefresh,
    )).whenComplete(() => _inFlightLoad = null);
    _inFlightLoad = run;
    return run;
  }

  Future<void>? _inFlightLoad;
  ({String langCode, UserProfile profile, bool forceRefresh})? _queuedLoad;

  Future<void> _drainLoads(
    ({String langCode, UserProfile profile, bool forceRefresh}) first,
  ) async {
    var current = first;
    while (true) {
      await _loadOnce(
        langCode: current.langCode,
        profile: current.profile,
        forceRefresh: current.forceRefresh,
      );
      final next = _queuedLoad;
      _queuedLoad = null;
      if (next == null) return;
      current = next;
    }
  }

  Future<void> _loadOnce({
    required String langCode,
    required UserProfile profile,
    required bool forceRefresh,
  }) async {
    if (forceRefresh) SchemeRepository.instance.clearCache();

    _schemesLoading = true;
    _schemesError = null;
    notifyListeners();

    try {
      if (!_allSchemesOverriddenForTesting) {
        _allSchemes = await SchemeRepository.instance.getAllSchemes(
          langCode: langCode,
        );
      }
      if (!_recommendationsOverriddenForTesting) {
        _recommendedSchemes = RecommendationEngine.getRecommendations(
          profile,
          _allSchemes,
        );
      }
    } catch (e) {
      _schemesError = e.toString();
      debugPrint('[AppProvider] loadSchemes error: $e');
    } finally {
      _schemesLoading = false;
      notifyListeners();
    }
  }

  Future<CatalogSyncResult> syncSchemeCatalog({
    required String langCode,
    required UserProfile profile,
    bool force = false,
  }) async {
    if (_catalogSyncing) {
      return _catalogSyncResult ??
          const CatalogSyncResult(CatalogSyncOutcome.throttled);
    }
    _catalogSyncing = true;
    notifyListeners();
    CatalogSyncResult result;
    try {
      result = await _catalogSyncService.syncIfNeeded(force: force);
    } catch (error) {
      result = CatalogSyncResult(
        CatalogSyncOutcome.rejected,
        manifest: _catalogSyncResult?.manifest,
        message: error.toString(),
      );
    }
    _catalogSyncResult = result;
    _catalogSyncing = false;
    if (result.changed) {
      await loadSchemes(
        langCode: langCode,
        profile: profile,
        forceRefresh: true,
      );
    } else {
      notifyListeners();
    }
    return result;
  }
}
