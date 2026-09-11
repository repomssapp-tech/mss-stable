import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/account/session_cache_service.dart';

/// Owns bottom-navigation state — the current tab index and its back-stack —
/// plus the SharedPreferences persistence for the index.
///
/// Extracted from `AppProvider` (frontend refactor C1.4) and used behind the
/// `AppProvider` facade: `AppProvider` forwards this controller's
/// `notifyListeners`, so every existing consumer keeps calling
/// `context.select((AppProvider p) => p.currentTabIndex)` unchanged.
///
/// `updateTabIndex` / `popTabIndex` notify (as they did on `AppProvider`). The
/// reset/hydrate helpers are deliberately silent: their call sites
/// (`_loadState`, `logout`, `deleteAccount`, the auth `signedOut` branch) each
/// already emit an `AppProvider` notification immediately afterwards, so the
/// observable notify topology is identical to the pre-split code.
class TabNavigationController extends ChangeNotifier {
  // Bottom Navigation: 0 Home · 1 Search · 2 Categories · 3 Saved Schemes · 4 Profile
  int _currentTabIndex = 0;
  final List<int> _tabHistory = [];

  int get currentTabIndex => _currentTabIndex;
  bool get hasTabHistory => _tabHistory.isNotEmpty;

  /// Seeds the index from the cache during startup. Silent — the caller
  /// (`AppProvider._loadState`) notifies once the whole state is loaded.
  Future<void> hydrate() async {
    _currentTabIndex = await SessionCacheService.instance.getCurrentTabIndex();
  }

  void updateTabIndex(int index, {bool addToHistory = true}) {
    if (_currentTabIndex == index) return;
    if (addToHistory) {
      if (_tabHistory.isEmpty || _tabHistory.last != _currentTabIndex) {
        _tabHistory.add(_currentTabIndex);
      }
    }
    _currentTabIndex = index;
    notifyListeners();
    unawaited(SessionCacheService.instance.saveCurrentTabIndex(index));
  }

  bool popTabIndex() {
    if (_tabHistory.isEmpty) return false;
    final prevIndex = _tabHistory.removeLast();
    _currentTabIndex = prevIndex;
    notifyListeners();
    unawaited(SessionCacheService.instance.saveCurrentTabIndex(prevIndex));
    return true;
  }

  /// Full reset for logout / account deletion: home tab, empty back-stack.
  /// Silent — the caller notifies.
  void reset() {
    _currentTabIndex = 0;
    _tabHistory.clear();
  }

  /// Index-only reset for the auth `signedOut` event, which historically left
  /// the back-stack untouched. Silent — the caller notifies.
  void resetIndexOnly() {
    _currentTabIndex = 0;
  }
}
