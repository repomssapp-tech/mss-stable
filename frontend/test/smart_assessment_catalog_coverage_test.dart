import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/questionnaire.dart';
import 'package:frontend/models/scheme_filter.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
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

  test(
    'shipped schemes match the requested support and shared eligibility',
    () {
      final targets = {
        for (final scheme in catalog)
          if (const {
            'CEN2026-001',
            'CEN2026-003',
            'CEN2026-004',
            'CEN2026-018',
            'CEN2026-150',
          }.contains(scheme.id))
            scheme.id: scheme,
      };
      expect(targets, hasLength(5));
      final profile = UserProfile(
        state: 'Tamil Nadu',
        gender: 'Male',
        businessStage: 'Operational',
      );
      Map<String, QuestionnaireFit> fits(Map<String, Object?> answers) => {
        for (final result in service.rank(
          targets.values.toList(),
          answers,
          profile: profile,
        ))
          result.scheme.id: result.fit,
      };

      final export = fits({'export_status': 'planning_to_export'});
      expect(export['CEN2026-150'], QuestionnaireFit.good);
      expect(export['CEN2026-001'], QuestionnaireFit.possible);
      expect(export['CEN2026-018'], QuestionnaireFit.possible);
      expect(export['CEN2026-004'], QuestionnaireFit.possible);

      final finance = fits({
        'assistance_needed': ['money_loans_subsidy'],
      });
      expect(finance['CEN2026-018'], QuestionnaireFit.good);
      expect(finance['CEN2026-004'], QuestionnaireFit.possible);
      expect(finance['CEN2026-003'], QuestionnaireFit.notNow);

      final standUp = catalog.firstWhere(
        (scheme) => scheme.id == 'CEN2026-137',
      );
      final scFounder = UserProfile(
        state: 'Tamil Nadu',
        gender: 'Male',
        community: 'SC',
        businessStage: 'Idea',
        dob: DateTime(1995),
      );
      final recommendation = RecommendationEngine.evaluate(scFounder, standUp);
      expect(recommendation.restriction, isNull);
      expect(
        service
            .rank(
              [standUp],
              {
                'assistance_needed': ['money_loans_subsidy'],
              },
              profile: scFounder,
            )
            .single
            .fit,
        QuestionnaireFit.good,
      );
    },
  );

  test('generic export plans prioritise broad export programmes', () {
    final schemes = catalog
        .where(
          (scheme) => const {
            'CEN2026-020',
            'CEN2026-025',
            'CEN2026-088',
            'CEN2026-089',
            'CEN2026-094',
            'CEN2026-150',
          }.contains(scheme.id),
        )
        .toList();
    expect(schemes, hasLength(6));
    const answers = {'export_status': 'planning_to_export'};
    final general = service.rank(
      schemes,
      answers,
      profile: UserProfile(gender: 'Female'),
    );
    expect(general.first.scheme.id, 'CEN2026-150');
    expect(
      general.skip(1).map((row) => row.fit),
      everyElement(QuestionnaireFit.possible),
    );
    final withoutSector = [
      for (final scheme in schemes)
        Scheme(
          id: scheme.id,
          name: scheme.name,
          schemeType: scheme.schemeType,
          targetBeneficiary: scheme.targetBeneficiary,
        ),
    ];
    final downloaded = service.rank(withoutSector, answers);
    expect(downloaded.first.scheme.id, 'CEN2026-150');
    expect(downloaded.map((row) => row.fit), general.map((row) => row.fit));
    final coir = service
        .rank(
          schemes,
          const {'export_status': 'yes_currently_exporting'},
          profile: UserProfile(
            gender: 'Female',
            businessIndustry: 'Coir products',
          ),
        )
        .firstWhere((row) => row.scheme.id == 'CEN2026-020');
    expect(coir.fit, QuestionnaireFit.good);
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
    // Use a nationwide scheme with no applicable restrictions as a witness.
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
