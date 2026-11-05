import '../../../services/recommendation/for_you_picks.dart';
import '../../../services/recommendation/recommendation_engine.dart';
import '../../../models/scheme_filter.dart';
import '../../../models/scheme_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/catalog/centralized_translator.dart';

export '../../../models/scheme_filter.dart'
    show
        schemeIsNationwide,
        applySchemeFilters,
        hasActiveSchemeFilters,
        activeSchemeFilterCount;

String getLocalizedTagOrCategory(String text, String langCode) {
  return CentralizedTranslator.instance.localizeTagFor(langCode, text);
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

  /// Nothing cleared the score gate, so the list holds the closest partial
  /// matches instead (see `pickForYou`). Not empty: the view shows them
  /// under a "no perfect match yet" heading.
  partialMatches,
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
) => applySchemeFilters(input, filters);

String _compact(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');

/// True when [query] is this scheme's name, short name or the acronym written
/// in brackets in its name ("... (PMEGP)"); case, spaces and punctuation are
/// ignored. Generic words and queries under three characters never match.
bool isExactSchemeQuery(Scheme scheme, String query) {
  final q = _compact(query);
  if (q.length < 3) return false;
  if (_compact(scheme.name) == q) return true;
  if (_compact(scheme.name.replaceAll(RegExp(r'\([^()]*\)'), '')) == q) {
    return true;
  }
  if (scheme.shortName.isNotEmpty && _compact(scheme.shortName) == q) {
    return true;
  }
  for (final m in RegExp(r'\(([^()]{2,40})\)').allMatches(scheme.name)) {
    if (_compact(m.group(1)!) == q) return true;
  }
  return false;
}

/// Exact name/acronym matches for [query] among [candidates] that [shown]
/// lacks (dropped by "For Me" or a facet filter). The results view lists them
/// last with a "not applicable" pill so a scheme the user typed by name never
/// just disappears.
List<Scheme> exactMatchesHidden({
  required String query,
  required List<Scheme> candidates,
  required List<Scheme> shown,
}) {
  final shownIds = {for (final s in shown) s.id};
  return [
    for (final s in candidates)
      if (!shownIds.contains(s.id) && isExactSchemeQuery(s, query)) s,
  ];
}

/// Resolves the "For Me" results view from the master result set, through
/// the same `pickForYou` as Home's "Recommended for you": FilterPanel facets
/// first, then the score gate (>= RecommendationEngine.forMeThreshold). When
/// nothing clears the gate, the closest partial matches are returned with
/// [ForMeEmptyState.partialMatches], so a usable profile always sees
/// something. Never the catalog. Empty only for:
///  - [ForMeEmptyState.completeProfile] when the profile is too sparse;
///  - [ForMeEmptyState.noMatches] when nothing matches at all.
/// Strong matches keep [master]'s order; partial ones are best first.
/// Pure — no BuildContext.
ForMeViewResult computeForMeView({
  required List<Scheme> master,
  required UserProfile profile,
  required Map<String, dynamic> filters,
}) {
  final filtered = applyProviderFacetFilters(master, filters);
  final picks = pickForYou(
    profile: profile,
    ranked: RecommendationEngine.getRecommendations(profile, filtered),
  );
  switch (picks.tier) {
    case ForYouTier.needsProfile:
      return const ForMeViewResult(<Scheme>[], ForMeEmptyState.completeProfile);
    case ForYouTier.none:
      return const ForMeViewResult(<Scheme>[], ForMeEmptyState.noMatches);
    case ForYouTier.partial:
      return ForMeViewResult([
        for (final e in picks.items) e.key,
      ], ForMeEmptyState.partialMatches);
    case ForYouTier.strong:
      final ids = {for (final e in picks.items) e.key.id};
      return ForMeViewResult([
        for (final s in filtered)
          if (ids.contains(s.id)) s,
      ], ForMeEmptyState.none);
  }
}
