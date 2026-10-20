import 'package:flutter/material.dart';

import '../../models/scheme_model.dart';
import 'search/browse_scope.dart';
import 'search_screen.dart';

/// A browse / results page.
///
/// It is the Search screen itself -- same header controls, Filter / For Me /
/// Sort strip, results list and empty states -- opened on a base set, so
/// browsing a category looks and behaves exactly like a search.
///
/// [type] is 'category' | 'ministry' | 'state' | 'eligible' for a browse page
/// (the list is [initialSchemes] when given, so it always matches the count on
/// the card that opened it), or null / 'query' to show the results of [title]
/// as a search query.
///
/// A pushed page starts with no filters, unless [keepFilters] is set because
/// the caller has just applied the browse questionnaire's answers.
class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({
    super.key,
    required this.title,
    this.type,
    this.initialSchemes,
    this.keepFilters = false,
  });

  final String title;
  final String? type;
  final List<Scheme>? initialSchemes;
  final bool keepFilters;

  bool get _isQuery {
    final t = type?.toLowerCase();
    return (t == null || t == 'query') && title.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return SearchScreen(
      showBack: true,
      keepFilters: keepFilters,
      initialQuery: _isQuery ? title : null,
      scope: _isQuery
          ? null
          : BrowseScope(title: title, type: type, schemes: initialSchemes),
    );
  }
}
