import '../../../models/mss_entity.dart';
import 'scheme_adapter_text_utils.dart';

/// Immutable container holding resolved eligibility criteria, conditions,
/// limits, and facet-matching values.
class SchemeEligibilityData {
  final List<String> elCriteriaList;
  final String ageRange;
  final String turnoverLimits;
  final String investmentLimits;
  final List<String> allowedBusinessTypes;
  final String educationRequirements;
  final List<String> mandatoryConditions;
  final List<String> optionalConditions;
  final List<String> specialCategories;
  final int? eligibilityMinAge;
  final int? eligibilityMaxAge;
  final List<String> eligibilityGenderValues;
  final List<String> eligibilityBusinessStageValues;

  const SchemeEligibilityData({
    required this.elCriteriaList,
    required this.ageRange,
    required this.turnoverLimits,
    required this.investmentLimits,
    required this.allowedBusinessTypes,
    required this.educationRequirements,
    required this.mandatoryConditions,
    required this.optionalConditions,
    required this.specialCategories,
    required this.eligibilityMinAge,
    required this.eligibilityMaxAge,
    required this.eligibilityGenderValues,
    required this.eligibilityBusinessStageValues,
  });
}

/// Resolves narrative and structured eligibility criteria, limits, and facet
/// fields for a scheme entity.
class SchemeEligibilityResolver {
  SchemeEligibilityResolver._();

  static SchemeEligibilityData resolve(
    MssEntity entity, {
    required String targetBeneficiary,
    required String langCode,
  }) {
    final content = entity.content;
    final eligibilityObj =
        (content['eligibility'] as Map<String, dynamic>?) ?? {};
    final eligibilityTextObj =
        (content['eligibilityText'] as Map<String, dynamic>?) ?? {};

    final elCriteriaList = <String>[];
    final structuredEl = eligibilityObj['structured'] as Map<String, dynamic>?;
    final narrativeEl = eligibilityObj['narrative'] as Map<String, dynamic>?;

    // A. Narrative Summary & Bullets
    if (narrativeEl != null) {
      final nSum = SchemeAdapterTextUtils.getLocalizedText(
        narrativeEl['summary'],
        langCode,
      );
      if (nSum.isNotEmpty) elCriteriaList.add(nSum);

      final nBullets = SchemeAdapterTextUtils.asList(
        narrativeEl['bulletPoints'],
      );
      if (nBullets != null) {
        for (final b in nBullets) {
          final s = SchemeAdapterTextUtils.getLocalizedText(b, langCode);
          if (s.isNotEmpty && !elCriteriaList.contains(s)) {
            elCriteriaList.add(s);
          }
        }
      }
    }

    // B. Direct Eligibility Text / Rules
    final elSum = SchemeAdapterTextUtils.getLocalizedText(
      eligibilityTextObj['summary'],
      langCode,
    );
    if (elSum.isNotEmpty && !elCriteriaList.contains(elSum)) {
      elCriteriaList.add(elSum);
    }

    final elRules = SchemeAdapterTextUtils.asList(content['eligibilityRules']);
    if (elRules != null) {
      for (final rule in elRules) {
        final rText = SchemeAdapterTextUtils.getLocalizedText(rule, langCode);
        if (rText.isNotEmpty && !elCriteriaList.contains(rText)) {
          elCriteriaList.add(rText);
        }
      }
    }

    // C. Structured Conditions Parsing
    String ageRange = '';
    String turnoverLimits = '';
    String investmentLimits = '';
    String educationRequirements = '';
    final allowedBusinessTypes = <String>[];
    final mandatoryConditions = <String>[];
    final optionalConditions = <String>[];
    final specialCategories = <String>[];

    // Facet-matching fields for RecommendationEngine -- populated below
    // alongside the display-text fields, from the SAME structured object.
    int? eligibilityMinAge;
    int? eligibilityMaxAge;
    final eligibilityGenderValues = <String>[];
    final eligibilityBusinessStageValues = <String>[];

    if (structuredEl != null) {
      // Each facet is its own nested object: {text, applies, ...values}.
      // `applies` (not mere key presence) is the authoritative signal that
      // the facet actually constrains this scheme -- see taxonomy_engine.py
      // and build_search_index.py's use of the same "applies" gate.
      final ageObj = structuredEl['age'] as Map<String, dynamic>?;
      if (ageObj?['applies'] == true) {
        final aMin = ageObj?['minYears'];
        final aMax = ageObj?['maxYears'];
        eligibilityMinAge = aMin is int ? aMin : int.tryParse('$aMin');
        eligibilityMaxAge = aMax is int ? aMax : int.tryParse('$aMax');
        if (aMin != null || aMax != null) {
          ageRange = '${aMin ?? 18} - ${aMax ?? "No upper limit"} years';
          elCriteriaList.add('Applicant Age: $ageRange');
        }
      }

      final genderObj = structuredEl['gender'] as Map<String, dynamic>?;
      if (genderObj?['applies'] == true) {
        final values = SchemeAdapterTextUtils.asList(genderObj?['values']);
        if (values != null) {
          eligibilityGenderValues.addAll(values.map((e) => e.toString()));
        }
      }

      final businessStageObj =
          structuredEl['businessStage'] as Map<String, dynamic>?;
      if (businessStageObj?['applies'] == true) {
        final values = SchemeAdapterTextUtils.asList(
          businessStageObj?['values'],
        );
        if (values != null) {
          eligibilityBusinessStageValues.addAll(
            values.map((e) => e.toString()),
          );
        }
      }

      final turnoverObj = structuredEl['turnover'] as Map<String, dynamic>?;
      final tMin = turnoverObj?['minInr'];
      final tMax = turnoverObj?['maxInr'];
      if (turnoverObj?['applies'] == true && (tMin != null || tMax != null)) {
        turnoverLimits = '₹${tMin ?? 0} to ₹${tMax ?? "No limit"}';
        elCriteriaList.add('Enterprise Turnover: $turnoverLimits');
      }

      final investmentObj = structuredEl['investment'] as Map<String, dynamic>?;
      final iMin = investmentObj?['minInr'];
      final iMax = investmentObj?['maxInr'];
      if (investmentObj?['applies'] == true &&
          (iMin != null || iMax != null)) {
        investmentLimits = '₹${iMin ?? 0} to ₹${iMax ?? "No limit"}';
        elCriteriaList.add('Plant & Machinery Investment: $investmentLimits');
      }

      final enterpriseObj = structuredEl['enterprise'] as Map<String, dynamic>?;
      if (enterpriseObj?['applies'] == true) {
        final bTypes = SchemeAdapterTextUtils.asList(enterpriseObj?['types']);
        if (bTypes != null && bTypes.isNotEmpty) {
          allowedBusinessTypes.addAll(bTypes.map((e) => e.toString()));
          elCriteriaList.add(
            'Eligible Business Types: ${allowedBusinessTypes.join(', ')}',
          );
        }
      }

      final otherConds = structuredEl['otherConditions'] as List?;
      if (otherConds != null) {
        for (final oc in otherConds) {
          final s = SchemeAdapterTextUtils.getLocalizedText(oc, langCode);
          if (s.isNotEmpty) {
            mandatoryConditions.add(s);
            if (!elCriteriaList.contains(s)) elCriteriaList.add(s);
          }
        }
      }

      final specialCategoryObj =
          structuredEl['specialCategory'] as Map<String, dynamic>?;
      if (specialCategoryObj?['applies'] == true) {
        final sCats = SchemeAdapterTextUtils.asList(
          specialCategoryObj?['values'],
        );
        if (sCats != null) {
          for (final sc in sCats) {
            final s = sc.toString();
            if (s.isNotEmpty) specialCategories.add(s);
          }
        }
      }

      final locationObj = structuredEl['location'] as Map<String, dynamic>?;
      final locText = locationObj?['text'];
      if (locationObj?['applies'] == true &&
          locText is String &&
          locText.isNotEmpty &&
          !elCriteriaList.contains('Location: $locText')) {
        elCriteriaList.add('Location: $locText');
      }
    }

    if (elCriteriaList.isEmpty && targetBeneficiary.isNotEmpty) {
      elCriteriaList.add('Target Beneficiaries: $targetBeneficiary');
    }

    return SchemeEligibilityData(
      elCriteriaList: elCriteriaList,
      ageRange: ageRange,
      turnoverLimits: turnoverLimits,
      investmentLimits: investmentLimits,
      allowedBusinessTypes: allowedBusinessTypes,
      educationRequirements: educationRequirements,
      mandatoryConditions: mandatoryConditions,
      optionalConditions: optionalConditions,
      specialCategories: specialCategories,
      eligibilityMinAge: eligibilityMinAge,
      eligibilityMaxAge: eligibilityMaxAge,
      eligibilityGenderValues: eligibilityGenderValues,
      eligibilityBusinessStageValues: eligibilityBusinessStageValues,
    );
  }
}
