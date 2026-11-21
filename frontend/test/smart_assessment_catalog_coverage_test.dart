import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/questionnaire.dart';
import 'package:frontend/models/scheme_filter.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/questionnaire/questionnaire_recommendation_service.dart';
import 'package:frontend/services/questionnaire/questionnaire_repository.dart';
import 'package:frontend/services/recommendation/indian_states.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = QuestionnaireRecommendationService();
  late List<Scheme> catalog;
  late Map<String, QuestionnaireField> fields;

  setUpAll(() async {
    catalog = await SchemeRepository.instance.getAllSchemes();
    expect(catalog, isNotEmpty);
    final definition = await QuestionnaireRepository().load();
    fields = {for (final field in definition.allFields) field.id: field};
  });

  final states = <String?>[null, ...IndianStates.names];

  test('every general answer combination has a viable catalog result', () {
    final genders = fields['general_gender']!.options.map((o) => o.value);
    final needs = fields['general_need']!.options.map((o) => o.value).toList();
    var checked = 0;
    for (final state in states) {
      for (final gender in <String?>[null, ...genders]) {
        for (var mask = 0; mask < (1 << needs.length); mask++) {
          final answers = <String, Object?>{
            'general_state': ?state,
            'general_gender': ?gender,
            if (mask != 0)
              'general_need': [
                for (var i = 0; i < needs.length; i++)
                  if ((mask & (1 << i)) != 0) needs[i],
              ],
          };
          final ranked = service.rank(catalog, answers);
          if (!ranked.any(
            (r) => r.scheme.isActive && r.fit != QuestionnaireFit.notNow,
          )) {
            fail('No Good fit or Might fit for $answers');
          }
          checked++;
        }
      }
    }
    debugPrint(
      'Checked $checked general combinations across ${catalog.length} schemes.',
    );
  });

  test('all extended eligibility combinations keep a viable catalog result', () {
    final ageRules = fields['owner_age']!.answerRules;
    final stages = fields['business_age']!.options.map((o) => o.value);
    // State, age and business stage are the only inputs that can make a
    // scheme Not for you now. The other answers only change ranking.
    final candidates = catalog
        .where(
          (scheme) =>
              scheme.isActive &&
              schemeAppliesNationally(scheme) &&
              scheme.eligibilityMinAge == null &&
              scheme.eligibilityMaxAge == null &&
              scheme.eligibilityBusinessStageValues.isEmpty,
        )
        .toList();
    expect(candidates, isNotEmpty);
    final witness = candidates.take(1).toList();
    var checked = 0;
    for (final state in states) {
      for (final resident in const <bool?>[null, false, true]) {
        for (final stage in <String?>[null, ...stages]) {
          for (
            var age = (ageRules['min'] as int) - 1;
            age <= (ageRules['max'] as int);
            age++
          ) {
            final answers = <String, Object?>{
              'general_state': ?state,
              if (resident != null)
                'is_maharashtra_domicile': {
                  'resident': resident,
                  'district': '',
                },
              'business_age': ?stage,
              if (age >= (ageRules['min'] as int)) 'owner_age': age,
            };
            if (service.rank(witness, answers).single.fit ==
                QuestionnaireFit.notNow) {
              fail(
                'Catalog scheme ${witness.single.id} is excluded for $answers',
              );
            }
            checked++;
          }
        }
      }
    }
    debugPrint(
      'Checked $checked extended eligibility combinations with '
      '${witness.single.name} (${witness.single.id}).',
    );
  });
}
