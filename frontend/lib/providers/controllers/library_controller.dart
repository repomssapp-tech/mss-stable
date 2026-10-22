import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/scheme_model.dart';
import '../../services/account/session_cache_service.dart';
import '../../services/catalog/scheme_id_migration.dart';
import '../../services/library/library_sync_service.dart';

/// Owns the user's saved-content lists — bookmarked schemes, the recently
/// viewed carousel, and the saved eligibility-results set — plus their
/// SharedPreferences persistence (via [SessionCacheService]).
///
/// Extracted from `AppProvider` (frontend refactor C1.4, slice 3) and used
/// behind the `AppProvider` facade: `AppProvider` forwards this controller's
/// `notifyListeners`, so every existing consumer keeps calling
/// `provider.bookmarkedIds` / `provider.toggleBookmark(...)` unchanged.
///
/// Two pieces deliberately stay on `AppProvider`, not here: the
/// `_allSchemes`-derived `bookmarkedSchemes` / `recentlyViewedSchemes` /
/// `savedEligibilitySchemes` getters (they need the catalog list). Keeping the
/// lists in step with the server is `LibrarySyncService`'s job; this controller
/// is the [LibrarySyncHost] it reads and writes.
///
/// `toggleBookmark` / `addToRecentlyViewed` / `saveEligibilityResults` notify
/// (as they did on `AppProvider`). [hydrate] and [reset] are deliberately
/// silent: their call sites (`_loadState`, `logout`, `deleteAccount`, the auth
/// `signedOut` branch) each already emit an `AppProvider` notification
/// immediately afterwards, so the observable notify topology is unchanged.
class LibraryController extends ChangeNotifier implements LibrarySyncHost {
  List<String> _bookmarkedIds = [];
  List<String> _recentlyViewedIds = [];
  List<String> _savedEligibilitySchemeIds = [];
  DateTime? _lastEligibilitySavedAt;

  static const int _recentlyViewedCap = 5;

  List<String> get bookmarkedIds => _bookmarkedIds;
  List<String> get recentlyViewedIds => _recentlyViewedIds;
  List<String> get savedEligibilitySchemeIds => _savedEligibilitySchemeIds;
  DateTime? get lastEligibilitySavedAt => _lastEligibilitySavedAt;
  bool get hasSavedEligibilityResults => _savedEligibilitySchemeIds.isNotEmpty;

  /// Seeds every list from the cache during startup. Silent — the caller
  /// (`AppProvider._loadState`) notifies once the whole state is loaded.
  Future<void> hydrate() async {
    _bookmarkedIds = await SessionCacheService.instance.getBookmarks() ?? [];
    _recentlyViewedIds =
        await SessionCacheService.instance.getRecentlyViewed() ?? [];
    _savedEligibilitySchemeIds =
        await SessionCacheService.instance.getSavedEligibilityResults() ?? [];
    _lastEligibilitySavedAt = await SessionCacheService.instance
        .getLastEligibilitySavedAt();
  }

  /// Rewrites any stored bookmark / recently-viewed entry that is actually a
  /// `schemeCode` (not an `id`) to the matching scheme's `id`, so `id` is the
  /// single canonical key going forward (H7: in the real catalog `id` and
  /// `schemeCode` always differ -- e.g. "SCH000001" vs "TN001" -- so an older
  /// entry saved by code would otherwise never match anything looked up by
  /// id). Idempotent and silent -- the caller (`AppProvider.loadSchemes`,
  /// once the catalog it needs for the id/code mapping is loaded) notifies.
  void normalizeBookmarkKeys(List<Scheme> allSchemes) {
    final codeToId = <String, String>{
      for (final s in allSchemes)
        if (s.schemeCode.isNotEmpty) s.schemeCode: s.id,
    };
    if (codeToId.isEmpty) return;

    bool remap(List<String> ids) {
      var changed = false;
      for (var i = 0; i < ids.length; i++) {
        final mapped = codeToId[ids[i]];
        if (mapped != null && mapped != ids[i]) {
          ids[i] = mapped;
          changed = true;
        }
      }
      return changed;
    }

    final bookmarksChanged = remap(_bookmarkedIds);
    final recentlyViewedChanged = remap(_recentlyViewedIds);

    if (bookmarksChanged) {
      _bookmarkedIds = _bookmarkedIds.toSet().toList();
      unawaited(SessionCacheService.instance.saveBookmarks(_bookmarkedIds));
    }
    if (recentlyViewedChanged) {
      _recentlyViewedIds = _recentlyViewedIds.toSet().toList();
      unawaited(
        SessionCacheService.instance.saveRecentlyViewed(_recentlyViewedIds),
      );
    }
  }

  /// Carries saved items across the 2026 catalog migration: rewrites pre-2026
  /// ids (and legacy codes) to their new ids via [idMap] and drops entries
  /// whose scheme no longer exists. Idempotent and silent -- the caller
  /// (`AppProvider.loadSchemes`) notifies. Does nothing when [knownIds] is
  /// empty, so a failed catalog load can never wipe the user's saved items.
  void migrateLegacyIds(Map<String, String> idMap, Set<String> knownIds) {
    if (knownIds.isEmpty) return;

    final bookmarks = SchemeIdMigration.migrate(
      _bookmarkedIds,
      idMap,
      knownIds,
    );
    if (bookmarks != null) {
      _bookmarkedIds = bookmarks;
      unawaited(SessionCacheService.instance.saveBookmarks(_bookmarkedIds));
    }

    final recent = SchemeIdMigration.migrate(
      _recentlyViewedIds,
      idMap,
      knownIds,
    );
    if (recent != null) {
      _recentlyViewedIds = recent;
      unawaited(
        SessionCacheService.instance.saveRecentlyViewed(_recentlyViewedIds),
      );
    }

    final eligibility = SchemeIdMigration.migrate(
      _savedEligibilitySchemeIds,
      idMap,
      knownIds,
    );
    if (eligibility != null) {
      _savedEligibilitySchemeIds = eligibility;
      unawaited(
        SessionCacheService.instance.saveSavedEligibilityResults(
          _savedEligibilitySchemeIds,
          _lastEligibilitySavedAt ?? DateTime.now(),
        ),
      );
    }
  }

  void toggleBookmark(String id) {
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    notifyListeners();
    unawaited(SessionCacheService.instance.saveBookmarks(_bookmarkedIds));
  }

  void addToRecentlyViewed(String id) {
    _recentlyViewedIds.remove(id); // move to front
    _recentlyViewedIds.insert(0, id);
    if (_recentlyViewedIds.length > _recentlyViewedCap) {
      _recentlyViewedIds = _recentlyViewedIds.sublist(0, _recentlyViewedCap);
    }
    notifyListeners();
    unawaited(
      SessionCacheService.instance.saveRecentlyViewed(_recentlyViewedIds),
    );
  }

  /// Drops [id] from the recently viewed list (Saved > Recently Viewed > Manage).
  void removeFromRecentlyViewed(String id) {
    if (!_recentlyViewedIds.remove(id)) return;
    notifyListeners();
    unawaited(
      SessionCacheService.instance.saveRecentlyViewed(_recentlyViewedIds),
    );
  }

  /// Replaces the saved eligibility set and stamps the save time. Persists to
  /// the cache; the caller (`AppProvider`) is responsible for the optional
  /// server mirror.
  Future<void> saveEligibilityResults(List<String> schemeIds) async {
    _savedEligibilitySchemeIds = List<String>.from(schemeIds);
    _lastEligibilitySavedAt = DateTime.now();
    notifyListeners();
    await SessionCacheService.instance.saveSavedEligibilityResults(
      _savedEligibilitySchemeIds,
      _lastEligibilitySavedAt!,
    );
  }

  // ── LibrarySyncHost ───────────────────────────────────────────────────

  @override
  List<String> get bookmarks => _bookmarkedIds;

  @override
  List<String> get eligibilityIds => _savedEligibilitySchemeIds;

  @override
  Future<void> applyRemoteBookmarks(List<String> ids) async {
    _bookmarkedIds = List<String>.from(ids);
    notifyListeners();
    await SessionCacheService.instance.saveBookmarks(_bookmarkedIds);
  }

  @override
  Future<void> applyRemoteEligibility(
    List<String> ids,
    DateTime? savedAt,
  ) async {
    _savedEligibilitySchemeIds = List<String>.from(ids);
    _lastEligibilitySavedAt = savedAt ?? DateTime.now();
    notifyListeners();
    await SessionCacheService.instance.saveSavedEligibilityResults(
      _savedEligibilitySchemeIds,
      _lastEligibilitySavedAt!,
    );
  }

  /// Full reset for logout / account deletion / auth `signedOut`. Silent — the
  /// caller notifies.
  void reset() {
    _bookmarkedIds.clear();
    _recentlyViewedIds.clear();
    _savedEligibilitySchemeIds.clear();
    _lastEligibilitySavedAt = null;
  }
}
