import '../../models/scheme_model.dart';
import '../../models/scheme_filter.dart';
import '../../models/questionnaire.dart';

enum QuestionnaireFit { good, possible, notNow }

class QuestionnaireRankedScheme {
  const QuestionnaireRankedScheme({
    required this.scheme,
    required this.score,
    required this.fit,
    required this.reasonKey,
  });

  final Scheme scheme;
  final int score;
  final QuestionnaireFit fit;
  final String reasonKey;
}

/// Ranks a browse set from assessment answers without changing profile data.
class QuestionnaireRecommendationService {
  const QuestionnaireRecommendationService();

  QuestionnaireField? chooseNextQuestion({
    required List<Scheme> schemes,
    required List<QuestionnaireField> fields,
    required Map<String, Object?> answers,
    required Set<String> excludedIds,
    bool includeAnswered = false,
  }) {
    final candidates = rank(
      schemes,
      answers,
    ).take(30).map((result) => result.scheme).toList(growable: false);
    if (candidates.isEmpty) return null;
    final baseline = rank(
      candidates,
      answers,
    ).take(5).map((result) => result.scheme.id).toList(growable: false);
    QuestionnaireField? best;
    var bestImpact = 0.0;
    for (final field in fields) {
      if (excludedIds.contains(field.id) ||
          (!includeAnswered && answers.containsKey(field.id)) ||
          _questionScenarios(field).length < 2) {
        continue;
      }
      var totalImpact = 0.0;
      var scenarios = 0;
      for (final value in _questionScenarios(field)) {
        final hypothetical = Map<String, Object?>.of(answers)
          ..[field.id] = value;
        final topIds = rank(
          candidates,
          hypothetical,
        ).take(5).map((result) => result.scheme.id).toList(growable: false);
        totalImpact += _topFiveDisplacement(baseline, topIds);
        scenarios++;
      }
      final impact = scenarios == 0 ? 0.0 : totalImpact / scenarios;
      if (impact > bestImpact) {
        bestImpact = impact;
        best = field;
      }
    }
    return bestImpact >= 0.05 ? best : null;
  }

  List<Object?> _questionScenarios(QuestionnaireField field) {
    if (field.type == 'number') {
      final minimum = field.answerRules['min'];
      final maximum = field.answerRules['max'];
      if (minimum is num && maximum is num && minimum < maximum) {
        return [
          minimum.toInt(),
          ((minimum + maximum) / 2).round(),
          maximum.toInt(),
        ];
      }
    }
    if (field.type == 'multi_select') {
      return field.options.map((option) => [option.value]).toList();
    }
    return field.options.map((option) => option.value).toList();
  }

  double _topFiveDisplacement(List<String> baseline, List<String> scenario) {
    if (baseline.isEmpty) return 0;
    final totalDisplacement = baseline.fold<int>(0, (total, id) {
      final oldIndex = baseline.indexOf(id);
      final newIndex = scenario.indexOf(id);
      return total + (newIndex < 0 ? 5 : (oldIndex - newIndex).abs());
    });
    return totalDisplacement / (baseline.length * 5);
  }

  List<QuestionnaireRankedScheme> rank(
    List<Scheme> schemes,
    Map<String, Object?> answers,
  ) {
    final domicileAnswer = answers['is_maharashtra_domicile'];
    final state =
        answers['general_state'] as String? ??
        (domicileAnswer is Map<String, Object?> &&
                domicileAnswer['resident'] == true
            ? 'Maharashtra'
            : '');
    final nature = (answers['business_nature'] as String? ?? '').toLowerCase();
    final goals = [
      ..._values(answers['scheme_goal']),
      ..._values(answers['general_need']),
    ];
    final assistance = _values(answers['assistance_needed']);
    final categories = _categories(answers['social_category']);
    if ([
      'general_gender',
      'owner_gender',
    ].any((key) => answers[key] == 'woman')) {
      categories.add('women');
    }
    final age = answers['owner_age'] is int
        ? answers['owner_age'] as int
        : null;
    final businessAge = answers['business_age'] as String?;
    final scored = schemes.indexed.map((entry) {
      final scheme = entry.$2;
      var score = 0;
      final stateMatch =
          state.isNotEmpty && schemeAppliesInState(scheme, state);
      final stateMismatch =
          state.isNotEmpty &&
          scheme.appliesNationally == false &&
          scheme.stateCodes.isNotEmpty &&
          !stateMatch;
      final ageMismatch =
          age != null &&
          ((scheme.eligibilityMinAge != null &&
                  age < scheme.eligibilityMinAge!) ||
              (scheme.eligibilityMaxAge != null &&
                  age > scheme.eligibilityMaxAge!));
      final stageMismatch =
          businessAge != null &&
          _stageMismatch(businessAge, scheme.eligibilityBusinessStageValues);
      if (stateMatch) score += 3;
      final hay =
          '${scheme.schemeType} ${scheme.sector} ${scheme.category} '
                  '${scheme.searchKeywords} ${scheme.targetBeneficiary}'
              .toLowerCase();
      if (nature.isNotEmpty && _matchesNature(nature, hay)) score += 2;
      final goalMatch = goals.any((goal) => _matchesGoal(goal, hay));
      final assistanceMatch = assistance.any(
        (answer) => _matchesAssistance(answer, hay),
      );
      if (goalMatch) score += 2;
      if (assistanceMatch) score++;
      final schemeCategories = scheme.specialCategories
          .map((value) => value.toLowerCase())
          .toSet();
      if (categories.intersection(schemeCategories).isNotEmpty) {
        score += 2;
      }
      if (stateMismatch || ageMismatch || stageMismatch) score -= 8;
      final reasonKey = stateMismatch
          ? 'assessmentReasonStateExcluded'
          : ageMismatch
          ? 'assessmentReasonAgeExcluded'
          : stageMismatch
          ? 'assessmentReasonStageExcluded'
          : stateMatch
          ? 'assessmentReasonState'
          : categories.intersection(schemeCategories).isNotEmpty
          ? 'assessmentReasonCategory'
          : _matchesNature(nature, hay)
          ? 'assessmentReasonNature'
          : goalMatch
          ? 'assessmentReasonGoal'
          : 'assessmentReasonGeneral';
      final fit = stateMismatch || ageMismatch || stageMismatch
          ? QuestionnaireFit.notNow
          : score >= 4
          ? QuestionnaireFit.good
          : QuestionnaireFit.possible;
      return (
        scheme: scheme,
        score: score,
        index: entry.$1,
        fit: fit,
        reasonKey: reasonKey,
      );
    }).toList();
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore == 0 ? a.index.compareTo(b.index) : byScore;
    });
    return scored
        .map(
          (item) => QuestionnaireRankedScheme(
            scheme: item.scheme,
            score: item.score,
            fit: item.fit,
            reasonKey: item.reasonKey,
          ),
        )
        .toList(growable: false);
  }

  List<String> _values(Object? answer) => switch (answer) {
    String value => [value.toLowerCase()],
    List<Object?> values =>
      values.whereType<String>().map((value) => value.toLowerCase()).toList(),
    _ => const [],
  };

  bool _stageMismatch(String answer, List<String> eligibleStages) {
    if (eligibleStages.isEmpty) return false;
    final stages = eligibleStages.map((stage) => stage.toLowerCase()).toList();
    final expected = switch (answer) {
      'not_started_yet_aspiring' => const [
        'idea',
        'aspiring',
        'new',
        'startup',
      ],
      'less_than_1_year' => const ['new', 'startup', 'less than 1', 'under 1'],
      '1_3_years' => const ['1-3', '1 to 3', 'early', 'startup'],
      '3_plus_years' => const ['3+', 'established', 'operational', 'expansion'],
      _ => const <String>[],
    };
    return expected.isNotEmpty &&
        !stages.any((stage) => expected.any(stage.contains));
  }

  bool _matchesGoal(String goal, String hay) => switch (goal) {
    'start_a_new_business' =>
      hay.contains('start-up') ||
          hay.contains('startup') ||
          hay.contains('entrepreneur') ||
          hay.contains('new unit'),
    'start_business' =>
      hay.contains('start-up') ||
          hay.contains('startup') ||
          hay.contains('entrepreneur') ||
          hay.contains('new unit'),
    'expand_existing_business' =>
      hay.contains('expansion') ||
          hay.contains('scale up') ||
          hay.contains('upgrade'),
    'expand_business' =>
      hay.contains('expansion') ||
          hay.contains('scale up') ||
          hay.contains('upgrade'),
    'buy_machinery_upgrade_tech' =>
      hay.contains('machinery') ||
          hay.contains('technology') ||
          hay.contains('equipment'),
    'equipment_technology' =>
      hay.contains('machinery') ||
          hay.contains('technology') ||
          hay.contains('equipment'),
    'daily_working_cash' =>
      hay.contains('working capital') ||
          hay.contains('cash credit') ||
          hay.contains('working cash'),
    'working_capital' =>
      hay.contains('working capital') ||
          hay.contains('cash credit') ||
          hay.contains('working cash'),
    'marketing_export' =>
      hay.contains('marketing') ||
          hay.contains('export') ||
          hay.contains('buyer'),
    'marketing_training' =>
      hay.contains('marketing') ||
          hay.contains('training') ||
          hay.contains('buyer'),
    _ => false,
  };

  bool _matchesAssistance(String assistance, String hay) =>
      switch (assistance) {
        'money_loans_subsidy' =>
          hay.contains('loan') ||
              hay.contains('credit') ||
              hay.contains('subsidy') ||
              hay.contains('grant'),
        'machines_technology' =>
          hay.contains('machinery') ||
              hay.contains('technology') ||
              hay.contains('equipment'),
        'hiring_staff_training' =>
          hay.contains('training') ||
              hay.contains('skill') ||
              hay.contains('employment'),
        'finding_buyers_marketing' =>
          hay.contains('marketing') ||
              hay.contains('export') ||
              hay.contains('buyer'),
        _ => false,
      };

  Set<String> _categories(Object? answer) {
    final selected = answer is List<Object?>
        ? answer.whereType<String>().toSet()
        : <String>{};
    return {
      if (selected.contains('woman')) 'women',
      if (selected.contains('sc')) 'sc',
      if (selected.contains('st')) 'st',
      if (selected.contains('person_with_disability_divyangjan'))
        'differently_abled',
      if (selected.contains('obc')) 'obc',
    };
  }

  bool _matchesNature(String nature, String hay) => switch (nature) {
    'manufacturing' => hay.contains('manufactur') || hay.contains('production'),
    'services' => hay.contains('service'),
    'trading_retail' => hay.contains('trading') || hay.contains('retail'),
    'agro_food_processing' =>
      hay.contains('agro') || hay.contains('food') || hay.contains('farm'),
    _ => false,
  };
}
