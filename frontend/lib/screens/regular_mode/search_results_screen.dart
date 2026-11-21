import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/scheme_model.dart';
import '../../services/analytics/app_analytics.dart';
import '../../providers/app_state_provider.dart';
import '../../services/questionnaire/questionnaire_qa_metrics.dart';
import '../../services/questionnaire/questionnaire_recommendation_service.dart';
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
    this.assessmentFits = const {},
    this.interactionId,
  });

  final String title;
  final String? type;
  final List<Scheme>? initialSchemes;
  final bool keepFilters;
  final Map<String, QuestionnaireFit> assessmentFits;
  final String? interactionId;

  static void openAssessment(
    BuildContext context, {
    required String title,
    required List<Scheme> schemes,
    required Map<String, Object?> answers,
    String? interactionId,
  }) {
    const engine = QuestionnaireRecommendationService();
    final ordered = engine.rank(
      schemes,
      answers,
      profile: context.read<AppProvider>().profile,
    );
    QuestionnaireQaMetrics.emit('results', {
      for (final fit in QuestionnaireFit.values)
        fit.name: ordered.where((result) => result.fit == fit).length,
    });
    AppAnalytics.instance.track(
      AnalyticsEvent.questionnaireResults,
      interactionId: interactionId,
      properties: {
        'good': ordered.where((row) => row.fit == QuestionnaireFit.good).length,
        'possible': ordered
            .where((row) => row.fit == QuestionnaireFit.possible)
            .length,
        'not_now': ordered
            .where((row) => row.fit == QuestionnaireFit.notNow)
            .length,
      },
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchResultsScreen(
          title: title,
          type: 'assessment',
          interactionId: interactionId,
          initialSchemes: ordered.map((result) => result.scheme).toList(),
          assessmentFits: {
            for (final result in ordered) result.scheme.id: result.fit,
          },
        ),
      ),
    );
  }

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
          : BrowseScope(
              title: title,
              type: type,
              schemes: initialSchemes,
              assessmentFits: assessmentFits,
              interactionId: interactionId,
            ),
    );
  }
}
