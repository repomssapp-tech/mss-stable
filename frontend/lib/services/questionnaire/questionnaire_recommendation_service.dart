import '../../models/scheme_model.dart';
import '../../models/user_profile.dart';
import '../recommendation/recommendation_engine.dart';

enum QuestionnaireFit { good, possible, notNow }

class QuestionnaireRankedScheme {
  const QuestionnaireRankedScheme({
    required this.scheme,
    required this.score,
    required this.fit,
    required this.reasonKey,
  });

  final Scheme scheme;
  final double score;
  final QuestionnaireFit fit;
  final String reasonKey;
}

/// Ranks a browse set from assessment answers without changing profile data.
class QuestionnaireRecommendationService {
  const QuestionnaireRecommendationService();

  List<QuestionnaireRankedScheme> rank(
    List<Scheme> schemes,
    Map<String, Object?> answers, {
    UserProfile? profile,
  }) {
    final savedProfile = profile ?? UserProfile();
    final domicile = answers['is_maharashtra_domicile'];
    final state =
        answers['general_state'] as String? ??
        (savedProfile.state.isNotEmpty ? savedProfile.state : null) ??
        (domicile is Map<String, Object?> && domicile['resident'] == true
            ? 'Maharashtra'
            : '');
    final gender = savedProfile.gender.isNotEmpty
        ? savedProfile.gender
        : switch (answers['general_gender'] ?? answers['owner_gender']) {
            'woman' => 'Female',
            'man' => 'Male',
            'other' => 'Other',
            _ => '',
          };
    final industry = switch (answers['business_nature']) {
      'manufacturing' => 'Manufacturing',
      'services' => 'Services',
      'trading_retail' => 'Retail',
      'agro_food_processing' => 'Food Processing',
      _ => '',
    };
    final stage = switch (answers['business_age']) {
      'not_started_yet_aspiring' => 'Idea',
      'less_than_1_year' || '1_3_years' || '3_plus_years' => 'Operational',
      _ => '',
    };
    final assessmentProfile = savedProfile.copyWith(
      state: state,
      gender: gender,
      businessIndustry: savedProfile.businessIndustry.isNotEmpty
          ? savedProfile.businessIndustry
          : industry,
      businessStage: savedProfile.businessStage.isNotEmpty
          ? savedProfile.businessStage
          : stage,
    );
    final recommendations = RecommendationEngine.getRecommendations(
      assessmentProfile,
      schemes,
      ageInYears: answers['owner_age'] as int?,
      additionalCategories: _categories(answers['social_category']),
    );

    final goals = [
      ..._values(answers['scheme_goal']),
      ..._values(answers['general_need']),
    ].map((id) => _goalPatterns[id]).whereType<RegExp>().toList();
    final assistance = _values(
      answers['assistance_needed'],
    ).map((id) => _assistancePatterns[id]).whereType<RegExp>().toList();
    final exportStatus = answers['export_status'];
    final wantsExport =
        exportStatus == 'yes_currently_exporting' ||
        exportStatus == 'planning_to_export';
    final domesticOnly = exportStatus == 'domestic_india_only';
    final requested = [
      if (goals.isNotEmpty) goals,
      if (assistance.isNotEmpty) assistance,
      if (wantsExport) [_exportPattern],
    ];
    final supportTerms = _supportTerms(answers).toSet();
    final industries = assessmentProfile.businessIndustry
        .toLowerCase()
        .split(_wordBoundary)
        .map(_singular)
        .toSet();

    final ranked = <QuestionnaireRankedScheme>[];
    for (final MapEntry(key: scheme, value: recommendation)
        in recommendations) {
      final focus = [
        scheme.name,
        scheme.schemeType,
        scheme.sector,
        scheme.category,
        ...scheme.benefitTypesList,
        ...scheme.supportTypes,
      ].join(' ').toLowerCase();
      final matches = requested.where((patterns) {
        return patterns.any((pattern) => pattern.hasMatch(focus));
      }).length;
      final beneficiary = scheme.targetBeneficiary.toLowerCase().trim();
      final additionalMatch = supportTerms.any('$focus $beneficiary'.contains);
      final fitsRequest = requested.isEmpty
          ? recommendation.score >= RecommendationEngine.forMeThreshold
          : matches == requested.length;
      final exportEvidence =
          '${scheme.name.toLowerCase()} '
          '${scheme.sector.toLowerCase()} $beneficiary';
      final blocked = !scheme.isActive || recommendation.restriction != null;
      final needsReview =
          recommendation.needsEligibilityReview ||
          scheme.status.toUpperCase() != 'ACTIVE' ||
          _institutionalAudience.hasMatch(beneficiary) ||
          _needsExportAudienceReview(scheme, beneficiary, industries) ||
          (wantsExport && !_exportPattern.hasMatch(exportEvidence)) ||
          (exportStatus == 'planning_to_export' &&
              _registeredExporters.hasMatch(beneficiary));
      final fit = switch ((
        blocked,
        !needsReview &&
            fitsRequest &&
            !(domesticOnly && _exportPattern.hasMatch(focus)),
      )) {
        (true, _) => QuestionnaireFit.notNow,
        (false, true) => QuestionnaireFit.good,
        _ => QuestionnaireFit.possible,
      };
      ranked.add(
        QuestionnaireRankedScheme(
          scheme: scheme,
          score:
              (recommendation.usesFallbackScore ? 0 : recommendation.score) +
              matches +
              (additionalMatch ? 0.1 : 0),
          fit: fit,
          reasonKey: switch (recommendation.restriction) {
            RecommendationRestriction.state => 'assessmentReasonStateExcluded',
            RecommendationRestriction.age => 'assessmentReasonAgeExcluded',
            _ =>
              matches > 0 ? 'assessmentReasonGoal' : 'assessmentReasonGeneral',
          },
        ),
      );
    }
    ranked.sort((a, b) {
      final byFit = a.fit.index.compareTo(b.fit.index);
      if (byFit != 0) return byFit;
      final byScore = b.score.compareTo(a.score);
      return byScore == 0 ? a.scheme.id.compareTo(b.scheme.id) : byScore;
    });
    return ranked;
  }

  bool _needsExportAudienceReview(
    Scheme scheme,
    String beneficiary,
    Set<String> industries,
  ) {
    final sector = scheme.sector.toLowerCase().trim();
    if (_domesticSupplies.hasMatch('$sector $beneficiary')) {
      return true;
    }
    final exportIndustry =
        _exportIndustry.firstMatch(sector)?.group(1) ??
        _exportAudience.firstMatch(beneficiary)?.group(1) ??
        _exportProduct.firstMatch(scheme.name.toLowerCase())?.group(1);
    return exportIndustry != null &&
        !_broadExportAudiences.contains(exportIndustry) &&
        !industries.contains(_singular(exportIndustry));
  }

  static String _singular(String word) =>
      word.endsWith('s') ? word.substring(0, word.length - 1) : word;

  static final _wordBoundary = RegExp(r'[^a-z]+');
  static final _exportIndustry = RegExp(r'^([a-z]+) exports?\b');
  static final _exportAudience = RegExp(
    r'^(?:(?:eligible|registered|existing|indian|potential) )*([a-z][a-z-]*) (?:exporters?|msmes? and (?:registered )?exporters?)\b',
  );
  static final _exportProduct = RegExp(r'\bexporters? of ([a-z][a-z-]*)\b');
  static final _registeredExporters = RegExp(r'\bregistered exporters?\b');
  static final _domesticSupplies = RegExp(
    r'\b(?:domestic suppl(?:y|ies)|suppliers making qualifying categories of domestically manufactured goods)\b',
  );
  static const _broadExportAudiences = {
    'msme',
    'mse',
    'indian',
    'merchandise',
    'goods',
    'products',
    'general',
    'registered',
    'eligible',
    'potential',
    'manufacturer',
    'merchant',
    'existing',
    'new',
  };

  static final _institutionalAudience = RegExp(
    r'^(?:institutions? of the\b|(?:government|public sector) (?:agencies|departments|institutions)\b)',
  );
  static final _exportPattern = RegExp(
    r'\b(?:exports?|exporters?|exporting|international trade|overseas markets?)\b',
  );
  static final _startup = RegExp(
    r'\b(?:start[- ]?ups?|incubat\w*|seed fund\w*|new (?:unit|business|enterprise)|enterprise creation|self[- ]employment)\b',
  );
  static final _expansion = RegExp(r'\b(?:expansion|scale[- ]?up)\b');
  static final _technology = RegExp(
    r'\b(?:machinery|equipment|technology (?:support|assistance|upgrad\w*|adoption|transfer)|modernisation|modernization)\b',
  );
  static final _workingCapital = RegExp(
    r'\b(?:working capital|cash credit|working cash)\b',
  );
  static final _marketing = RegExp(
    r'\b(?:marketing|market access|market linkages?|trade fairs?|buyer(?:s|[- ]seller))\b',
  );
  static final _training = RegExp(
    r'\b(?:training|skills?|apprentice\w*|capacity building|staff recruitment)\b',
  );

  static final _goalPatterns = {
    'start_a_new_business': _startup,
    'start_business': _startup,
    'expand_existing_business': _expansion,
    'expand_business': _expansion,
    'buy_machinery_upgrade_tech': _technology,
    'equipment_technology': _technology,
    'daily_working_cash': _workingCapital,
    'working_capital': _workingCapital,
    'marketing_export': RegExp(
      '${_marketing.pattern}|${_exportPattern.pattern}',
    ),
    'marketing_training': RegExp('${_marketing.pattern}|${_training.pattern}'),
  };

  static final _assistancePatterns = {
    'money_loans_subsidy': RegExp(
      r'\b(?:loans?|credit|refinanc\w*|subsid\w*|grants?|finance|financing|equity|seed funding|interest subvention)\b',
    ),
    'machines_technology': _technology,
    'hiring_staff_training': _training,
    'finding_buyers_marketing': _marketing,
  };

  List<String> _values(Object? answer) => switch (answer) {
    String value => [value.toLowerCase()],
    List<Object?> values =>
      values.whereType<String>().map((value) => value.toLowerCase()).toList(),
    _ => const [],
  };

  Iterable<String> _supportTerms(Map<String, Object?> answers) sync* {
    final location = answers['business_location'];
    if (location is Map<String, Object?>) {
      yield* switch (location['area']) {
        'village_rural' => const ['rural', 'village'],
        'city_urban' => const ['urban', 'municipal'],
        _ => const <String>[],
      };
    }
    for (final zone in _values(answers['special_focus_zone'])) {
      yield* switch (zone) {
        'tribal_area' => const ['tribal'],
        'aspirational_district' => const ['aspirational district'],
        'backward_taluka' => const ['backward taluka', 'backward area'],
        'industrial_estate_midc' => const ['industrial estate'],
        _ => const <String>[],
      };
    }
    yield* switch (answers['org_structure']) {
      'sole_owner_proprietorship' => const ['proprietor', 'sole owner'],
      'partnership' || 'llp' => const ['partnership', ' llp'],
      'pvt_ltd' => const ['private limited', 'pvt. ltd'],
      'co_operative' => const ['cooperative', 'co-operative'],
      'self_help_group_shg' => const [
        'self-help group',
        'self help group',
        'shg',
      ],
      _ => const <String>[],
    };
    yield* switch (answers['digital_literacy_level']) {
      'basic_whatsapp_upi_only' => const ['digital literacy', 'digital skills'],
      'moderate_can_fill_online_forms' || 'advanced_accounting_e_commerce' =>
        const ['e-commerce', 'digitisation', 'digital adoption'],
      _ => const <String>[],
    };
    if (answers['has_gi_tag'] == 'yes') {
      yield* const ['geographical indication', 'gi tag', 'gi-tag'];
    }
    if (answers['cluster_membership'] == 'part_of_a_cluster') {
      yield 'cluster';
    }
    if (answers['tax_compliance_comfort'] == 'need_basic_guidance') {
      yield* const ['tax guidance', 'tax compliance', 'gst training'];
    }
  }

  Set<String> _categories(Object? answer) {
    final selected = answer is List<Object?>
        ? answer.whereType<String>().toSet()
        : <String>{};
    return {
      if (selected.contains('woman')) 'women',
      if (selected.contains('general')) 'general',
      if (selected.contains('sc')) 'sc',
      if (selected.contains('st')) 'st',
      if (selected.contains('person_with_disability_divyangjan'))
        'differently_abled',
      if (selected.contains('obc')) 'obc',
      if (selected.contains('minority')) 'minority',
      if (selected.contains('ex_serviceman')) 'ex_servicemen',
    };
  }
}
