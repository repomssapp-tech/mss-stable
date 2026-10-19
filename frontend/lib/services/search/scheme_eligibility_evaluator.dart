import 'dart:math' as math;

import 'intelligent_scheme_search.dart';
import 'scheme_fact_extractor.dart';
import 'scheme_understanding_models.dart';

/// Evaluates scheme criteria against user facts and selects the highest-value
/// missing follow-up question.
class SchemeEligibilityEvaluator {
  const SchemeEligibilityEvaluator._();

  static SchemeRecommendation evaluate(
    SchemeSearchMatch match,
    Map<EligibilityFactKey, EligibilityFact> facts, {
    required bool isTrusted,
  }) {
    final scheme = match.scheme;
    final eligibilityRaw = [
      scheme.targetBeneficiary,
      scheme.eligibilityCriteria.join(' '),
      scheme.state,
    ].join(' ');
    final eligibility = SchemeFactExtractor.normalize(eligibilityRaw);
    final reasons = <String>[...match.reasons];
    final unknowns = <String>[];
    final unknownKeys = <EligibilityFactKey>[];
    final disqualifiers = <String>[];
    var passed = 0;
    var checked = 0;

    void requireFact(
      EligibilityFactKey key,
      String label,
      bool Function(String value) passes,
      String success,
      String failure,
    ) {
      checked++;
      final fact = facts[key];
      if (fact == null || fact.value.toLowerCase().contains('prefer not')) {
        unknowns.add(label);
        unknownKeys.add(key);
      } else if (passes(fact.value)) {
        passed++;
        reasons.add(success);
      } else {
        disqualifiers.add(failure);
      }
    }

    final schemeState = scheme.state.trim();
    if (schemeState.isNotEmpty &&
        !SchemeFactExtractor.containsAny(
          SchemeFactExtractor.normalize(schemeState),
          ['all india', 'central', 'nationwide'],
        )) {
      requireFact(
        EligibilityFactKey.state,
        'State of residence',
        (value) =>
            SchemeFactExtractor.normalize(
              value,
            ).contains(SchemeFactExtractor.normalize(schemeState)) ||
            SchemeFactExtractor.normalize(
              schemeState,
            ).contains(SchemeFactExtractor.normalize(value)),
        'Available in your state',
        'This scheme is limited to $schemeState residents.',
      );
    }

    if (SchemeFactExtractor.containsAny(eligibility, [
      'women',
      'woman',
      'female',
      'girl',
      'widow',
    ])) {
      requireFact(
        EligibilityFactKey.gender,
        'Gender/category requirement',
        (value) => SchemeFactExtractor.containsAny(
          SchemeFactExtractor.normalize(value),
          ['female', 'transgender'],
        ),
        'Matches the women-focused beneficiary group',
        'This scheme is restricted to women or the stated eligible category.',
      );
    }

    final communityOptions = <String>[];
    if (RegExp(r'\bsc\b|scheduled caste').hasMatch(eligibility)) {
      communityOptions.add('sc');
    }
    if (RegExp(r'\bst\b|scheduled tribe|tribal').hasMatch(eligibility)) {
      communityOptions.add('st');
    }
    if (RegExp(r'\bobc\b|backward class').hasMatch(eligibility)) {
      communityOptions.add('obc');
    }
    if (SchemeFactExtractor.containsAny(eligibility, [
      'minority',
      'சிறுபான்மை',
    ])) {
      communityOptions.add('minority');
    }
    if (communityOptions.isNotEmpty &&
        !SchemeFactExtractor.containsAny(eligibility, [
          'priority',
          'including',
          'women, sc',
          'women sc',
        ])) {
      requireFact(
        EligibilityFactKey.community,
        'Community/category',
        (value) =>
            communityOptions.contains(SchemeFactExtractor.normalize(value)),
        'Matches the eligible community/category',
        'Your community/category does not match this restricted scheme.',
      );
    }

    final ageRange = _ageRange(eligibilityRaw.toLowerCase());
    if (ageRange != null) {
      requireFact(
        EligibilityFactKey.age,
        'Age',
        (value) {
          final age = int.tryParse(
            RegExp(r'\d+').firstMatch(value)?.group(0) ?? '',
          );
          return age != null && age >= ageRange.$1 && age <= ageRange.$2;
        },
        'Age is within the published range',
        'Age is outside the published ${ageRange.$1}-${ageRange.$2} range.',
      );
    }

    final incomeCeiling = _incomeCeiling(eligibilityRaw.toLowerCase());
    if (incomeCeiling != null) {
      requireFact(
        EligibilityFactKey.annualIncome,
        'Annual family income',
        (value) => (double.tryParse(value) ?? double.infinity) <= incomeCeiling,
        'Income is within the published ceiling',
        'Income appears above the published scheme ceiling.',
      );
    }

    if (SchemeFactExtractor.containsAny(eligibility, [
      'student',
      'students',
      'pupil',
    ])) {
      requireFact(
        EligibilityFactKey.studentStatus,
        'Current student status',
        (value) => SchemeFactExtractor.normalize(value) == 'yes',
        'Matches the student beneficiary group',
        'This scheme requires the applicant to be a student.',
      );
    }
    if (SchemeFactExtractor.containsAny(eligibility, [
      'farmer',
      'farmers',
      'cultivator',
    ])) {
      requireFact(
        EligibilityFactKey.occupation,
        'Farmer status',
        (value) => SchemeFactExtractor.normalize(value) == 'farmer',
        'Matches the farmer beneficiary group',
        'This scheme is intended for farmers or cultivators.',
      );
    }
    if (SchemeFactExtractor.containsAny(eligibility, [
      'artisan',
      'weaver',
      'craftsperson',
    ])) {
      requireFact(
        EligibilityFactKey.occupation,
        'Artisan status',
        (value) => SchemeFactExtractor.containsAny(
          SchemeFactExtractor.normalize(value),
          ['artisan', 'weaver'],
        ),
        'Matches the artisan beneficiary group',
        'This scheme requires artisan or related occupational status.',
      );
    }
    if (SchemeFactExtractor.containsAny(eligibility, [
      'disabled',
      'disability',
      'differently abled',
    ])) {
      requireFact(
        EligibilityFactKey.disability,
        'Disability category',
        (value) => SchemeFactExtractor.normalize(value) == 'yes',
        'Matches the disability beneficiary category',
        'This scheme is restricted to applicants with the stated disability category.',
      );
    }
    if (SchemeFactExtractor.containsAny(eligibility, ['widow', 'widowed'])) {
      requireFact(
        EligibilityFactKey.maritalStatus,
        'Widow status',
        (value) => SchemeFactExtractor.normalize(value) == 'widowed',
        'Matches the widow beneficiary category',
        'This scheme is restricted to widowed applicants.',
      );
    }

    final eligibilityScore = checked == 0
        ? 0.68
        : (passed + unknownKeys.length * 0.52) / checked;
    var score = match.score * 0.72 + eligibilityScore * 0.28;
    if (!isTrusted) score *= 0.82;
    if (disqualifiers.isNotEmpty) score *= 0.2;

    final state = disqualifiers.isNotEmpty
        ? SchemeMatchState.notSuitable
        : score >= 0.80 && unknowns.isEmpty
        ? SchemeMatchState.strongMatch
        : score >= 0.58 && unknowns.length <= 1
        ? SchemeMatchState.likelyMatch
        : SchemeMatchState.needsInformation;
    return SchemeRecommendation(
      scheme: scheme,
      score: score.clamp(0, 1),
      state: state,
      reasons: List.unmodifiable(reasons.toSet().take(3)),
      unknownRequirements: List.unmodifiable(unknowns.toSet()),
      disqualifiers: List.unmodifiable(disqualifiers),
      isTrusted: isTrusted,
    );
  }

  static FollowUpQuestion? chooseQuestion(
    List<SchemeRecommendation> recommendations,
    Map<EligibilityFactKey, EligibilityFact> facts,
    Map<EligibilityFactKey, FollowUpQuestion> questions,
  ) {
    final scores = <EligibilityFactKey, double>{};
    for (var index = 0; index < math.min(5, recommendations.length); index++) {
      final recommendation = recommendations[index];
      for (final unknown in recommendation.unknownRequirements) {
        final key = keyForUnknown(unknown);
        if (key != null && !facts.containsKey(key)) {
          scores.update(
            key,
            (score) => score + recommendation.score / (index + 1),
            ifAbsent: () => recommendation.score / (index + 1),
          );
        }
      }
    }
    if (scores.isEmpty) return null;
    final selected = scores.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return questions[selected.key];
  }

  static EligibilityFactKey? keyForUnknown(String unknown) {
    final value = unknown.toLowerCase();
    if (value.contains('state')) return EligibilityFactKey.state;
    if (value.contains('age')) return EligibilityFactKey.age;
    if (value.contains('income')) return EligibilityFactKey.annualIncome;
    if (value.contains('gender')) return EligibilityFactKey.gender;
    if (value.contains('community')) return EligibilityFactKey.community;
    if (value.contains('student')) return EligibilityFactKey.studentStatus;
    if (value.contains('farmer') || value.contains('artisan')) {
      return EligibilityFactKey.occupation;
    }
    if (value.contains('disability')) return EligibilityFactKey.disability;
    if (value.contains('widow')) return EligibilityFactKey.maritalStatus;
    return null;
  }

  static (int, int)? _ageRange(String eligibility) {
    if (!SchemeFactExtractor.containsAny(eligibility, [
      'age',
      'aged',
      'years old',
      'years of age',
    ])) {
      return null;
    }
    final between = RegExp(
      r'(\d{1,2})\s*(?:-|to|–)\s*(\d{1,2})',
    ).firstMatch(eligibility);
    if (between != null &&
        between.group(1) != null &&
        between.group(2) != null) {
      return (int.parse(between.group(1)!), int.parse(between.group(2)!));
    }
    final minimum = RegExp(
      r'(?:above|at least|minimum)\s*(\d{1,2})',
    ).firstMatch(eligibility);
    if (minimum != null && minimum.group(1) != null) {
      return (int.parse(minimum.group(1)!), 120);
    }
    final maximum = RegExp(
      r'(?:up to|below|maximum)\s*(\d{1,2})',
    ).firstMatch(eligibility);
    if (maximum != null && maximum.group(1) != null) {
      return (0, int.parse(maximum.group(1)!));
    }
    return null;
  }

  static double? _incomeCeiling(String eligibility) {
    if (!SchemeFactExtractor.containsAny(eligibility, [
      'income',
      'annual family income',
    ])) {
      return null;
    }
    final match = RegExp(
      r'(?:below|less than|up to|not exceed(?:ing)?)\s*(?:rs\.?|₹)?\s*(\d+(?:\.\d+)?)\s*(lakh|lakhs|crore|thousand)?',
    ).firstMatch(eligibility.replaceAll(',', ''));
    if (match == null || match.group(1) == null) return null;
    return SchemeFactExtractor.scaledMoney(match.group(1)!, match.group(2));
  }
}
