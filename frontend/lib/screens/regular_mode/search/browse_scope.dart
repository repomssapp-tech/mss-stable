import '../../../models/scheme_model.dart';
import '../../../services/questionnaire/questionnaire_recommendation_service.dart';

/// What a browse page (Discover category / ministry / state, a home tile, the
/// eligible list) starts from, before any filter is applied.
///
/// Browse pages are the Search screen itself, opened on this base set, so the
/// list always matches the count on the card that opened it and the Filter /
/// For Me / Sort controls behave exactly as they do for a search.
class BrowseScope {
  const BrowseScope({
    required this.title,
    this.type,
    this.schemes,
    this.assessmentFits = const {},
    this.interactionId,
  });

  /// What the page is called ("Business & MSME", "Maharashtra", ...).
  final String title;

  /// 'category' | 'ministry' | 'state' | 'eligible'.
  final String? type;

  /// The base set when the caller already has it (so the page and the card
  /// count cannot disagree); null makes the page load it from the catalog.
  final List<Scheme>? schemes;
  final Map<String, QuestionnaireFit> assessmentFits;
  final String? interactionId;
}
