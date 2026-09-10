import 'package:flutter/foundation.dart';

/// Owns the transient search-and-filter UI state: the current free-text search
/// query and the active scheme facet filters.
///
/// Extracted from `AppProvider` (frontend refactor C1.4, slice 4) and used
/// behind the `AppProvider` facade: `AppProvider` forwards this controller's
/// `notifyListeners`, so consumers keep calling `provider.filters` /
/// `provider.updateFilter(...)` unchanged.
///
/// This state is deliberately in-memory only — it is never persisted and never
/// reset on logout/deleteAccount (the provider is rebuilt on sign-out, which
/// clears it). Every mutator notifies, exactly as the pre-split code did.
///
/// Filters are a plain string-keyed map (see `lib/models/scheme_filter.dart`);
/// regular search is never silently narrowed by the profile, so the map starts
/// empty.
class SearchFilterController extends ChangeNotifier {
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filters => _filters;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateFilter(String key, dynamic value) {
    _filters[key] = value;
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    notifyListeners();
  }
}
