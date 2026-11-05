import '../../models/scheme_model.dart';
import '../../models/user_profile.dart';
import 'recommendation_engine.dart';

/// Which kind of list Home's "Recommended for you" and Search's "For Me"
/// show. Both screens resolve it through [pickForYou], so they always agree.
enum ForYouTier {
  /// Schemes at or above [RecommendationEngine.forMeThreshold].
  strong,

  /// Nothing cleared the threshold, so the closest partial matches are shown
  /// under a "no perfect match yet" note.
  partial,

  /// The profile is too sparse to personalise: ask the user to complete it.
  needsProfile,

  /// A usable profile with no match at all, not even a partial one.
  none,
}

class ForYouPicks {
  const ForYouPicks(this.items, this.tier);

  /// Best first.
  final List<MapEntry<Scheme, RecommendationResult>> items;
  final ForYouTier tier;
}

/// How many partial matches to offer when nothing is a strong match.
const int forYouPartialLimit = 10;

/// Resolves the "for you" list from [ranked] (best first, as
/// [RecommendationEngine.getRecommendations] returns it):
///  - a profile too sparse to judge → [ForYouTier.needsProfile];
///  - any scheme at or above the threshold → those, [ForYouTier.strong];
///  - otherwise the top [forYouPartialLimit] with any positive score →
///    [ForYouTier.partial], so a usable profile always has something to see;
///  - otherwise [ForYouTier.none].
ForYouPicks pickForYou({
  required UserProfile profile,
  required List<MapEntry<Scheme, RecommendationResult>> ranked,
}) {
  if (!RecommendationEngine.hasEnoughProfileForRecommendation(profile)) {
    return const ForYouPicks([], ForYouTier.needsProfile);
  }
  final strong = [
    for (final e in ranked)
      if (e.value.score >= RecommendationEngine.forMeThreshold) e,
  ];
  if (strong.isNotEmpty) return ForYouPicks(strong, ForYouTier.strong);
  final partial = [
    for (final e in ranked)
      if (e.value.score > 0) e,
  ].take(forYouPartialLimit).toList();
  if (partial.isNotEmpty) return ForYouPicks(partial, ForYouTier.partial);
  return const ForYouPicks([], ForYouTier.none);
}
