import '../../../engine/recommendation_engine.dart';
import '../../../models/scheme_filter.dart';
import '../../../models/scheme_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/catalog/centralized_translator.dart';

export '../../../models/scheme_filter.dart'
    show schemeIsNationwide, applySchemeFilters, hasActiveSchemeFilters, activeSchemeFilterCount;

String getLocalizedTagOrCategory(String text, String langCode) {
  if (langCode != 'ta') return text;
  return CentralizedTranslator.instance.translateTag(text);
}

enum SearchState { idle, loading, results }

/// Which empty state the "For Me" results view should render.
enum ForMeEmptyState {
  /// There are matches to show.
  none,

  /// Profile is too sparse to personalise — show "complete your profile".
  completeProfile,

  /// Profile is usable but nothing cleared the score gate / facet filters.
  noMatches,
}

/// Result of resolving the "For Me" view: the schemes to show plus which
/// empty state (if any) applies. Pure data, unit-tested.
class ForMeViewResult {
  const ForMeViewResult(this.schemes, this.emptyState);
  final List<Scheme> schemes;
  final ForMeEmptyState emptyState;
}

/// Legacy name kept for [computeForMeView] and existing tests. The one
/// matcher now lives in `models/scheme_filter.dart`.
List<Scheme> applyProviderFacetFilters(
  List<Scheme> input,
  Map<String, dynamic> filters,
) =>
    applySchemeFilters(input, filters);

/// Resolves the "For Me" results view from the master result set. Additive:
/// score gate (>= RecommendationEngine.forMeThreshold) INTERSECTED with the
/// FilterPanel facets. Returns an empty list — never the catalog — with a
/// [ForMeEmptyState] the caller renders:
///  - [ForMeEmptyState.completeProfile] when the profile is too sparse;
///  - [ForMeEmptyState.noMatches] when it is usable but nothing qualifies.
/// Pure — no BuildContext.
ForMeViewResult computeForMeView({
  required List<Scheme> master,
  required UserProfile profile,
  required Map<String, dynamic> filters,
}) {
  if (!RecommendationEngine.hasEnoughProfileForRecommendation(profile)) {
    return const ForMeViewResult(<Scheme>[], ForMeEmptyState.completeProfile);
  }
  final gated = master
      .where(
        (s) =>
            RecommendationEngine.evaluate(profile, s).score >=
            RecommendationEngine.forMeThreshold,
      )
      .toList();
  final filtered = applyProviderFacetFilters(gated, filters);
  return ForMeViewResult(
    filtered,
    filtered.isEmpty ? ForMeEmptyState.noMatches : ForMeEmptyState.none,
  );
}
