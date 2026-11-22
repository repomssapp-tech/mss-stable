import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
import 'package:frontend/services/questionnaire/questionnaire_recommendation_service.dart';

void main() {
  const service = QuestionnaireRecommendationService();

  test('woman answer boosts tagged schemes and keeps general schemes', () {
    const general = Scheme(id: 'general', name: 'General support');
    const women = Scheme(
      id: 'women',
      name: 'Women support',
      specialCategories: ['women'],
    );

    final results = service.rank(
      const [general, women],
      const {'general_gender': 'woman'},
    );

    expect(results.map((result) => result.scheme.id), ['women', 'general']);
    expect(
      results.every((result) => result.fit != QuestionnaireFit.notNow),
      isTrue,
    );
  });

  test('state-specific schemes can rank not now outside their state', () {
    const national = Scheme(
      id: 'national',
      name: 'National support',
      appliesNationally: true,
    );
    const maharashtra = Scheme(
      id: 'maharashtra',
      name: 'Maharashtra support',
      appliesNationally: false,
      stateCodes: ['IN-MH'],
    );

    final results = service.rank(
      const [national, maharashtra],
      const {'general_state': 'Tamil Nadu'},
    );

    expect(results.first.scheme.id, 'national');
    expect(results.first.fit, QuestionnaireFit.possible);
    expect(results.last.fit, QuestionnaireFit.notNow);
    expect(results.last.reasonKey, 'assessmentReasonStateExcluded');
  });

  test('location-restricted schemes need confirmed coverage for Good fit', () {
    const local = Scheme(
      id: 'local',
      name: 'Local working capital loan',
      appliesNationally: false,
      stateCodes: ['IN-TN'],
    );
    const unknown = Scheme(
      id: 'unknown',
      name: 'Working capital loan with unclear coverage',
      appliesNationally: false,
    );
    const answers = {
      'scheme_goal': ['daily_working_cash'],
    };
    expect(
      service.rank(const [local], answers).single.fit,
      QuestionnaireFit.possible,
    );

    final results = service.rank(
      const [unknown, local],
      {...answers, 'general_state': 'Tamil Nadu'},
    );
    expect(results.map((result) => (result.scheme.id, result.fit)), [
      ('local', QuestionnaireFit.good),
      ('unknown', QuestionnaireFit.possible),
    ]);
  });

  test('age limits affect fit at the boundary', () {
    const scheme = Scheme(
      id: 'age-limited',
      name: 'Age-limited support',
      eligibilityMinAge: 18,
      eligibilityMaxAge: 45,
    );

    final atLimit = service.rank(const [scheme], const {'owner_age': 45});
    final overLimit = service.rank(const [scheme], const {'owner_age': 46});

    expect(atLimit.single.fit, QuestionnaireFit.possible);
    expect(overLimit.single.fit, QuestionnaireFit.notNow);
    expect(overLimit.single.reasonKey, 'assessmentReasonAgeExcluded');
  });

  test('nationwide coverage and weak personalization do not earn Good fit', () {
    const scheme = Scheme(
      id: 'unrelated',
      name: 'General rural support',
      appliesNationally: true,
      searchKeywords: 'An export finance authority',
    );
    final results = service.rank(
      const [scheme],
      const {
        'general_state': 'Tamil Nadu',
        'business_location': {'area': 'village_rural'},
        'export_status': 'planning_to_export',
      },
    );
    expect(results.single.fit, QuestionnaireFit.possible);
  });

  test('Good fit requires the requested support and known eligibility', () {
    const eligible = Scheme(
      id: 'finance',
      name: 'Working capital loan',
      appliesNationally: true,
    );
    const training = Scheme(id: 'training', name: 'Working capital training');
    const restricted = Scheme(
      id: 'restricted',
      name: 'Working capital loan for women',
      eligibilityGenderValues: ['female'],
    );
    final answers = {
      'scheme_goal': ['daily_working_cash'],
      'assistance_needed': ['money_loans_subsidy'],
    };
    expect(
      service
          .rank(const [training, restricted, eligible], answers)
          .map((result) => (result.scheme.id, result.fit)),
      [
        ('finance', QuestionnaireFit.good),
        ('restricted', QuestionnaireFit.possible),
        ('training', QuestionnaireFit.possible),
      ],
    );
    final profile = UserProfile(gender: 'Male', state: 'Tamil Nadu');
    final base = RecommendationEngine.evaluate(profile, restricted);
    expect(base.restriction, RecommendationRestriction.gender);
    expect(
      service.rank(const [restricted], answers, profile: profile).single.fit,
      QuestionnaireFit.notNow,
    );
  });

  test('relevant answers boost schemes without excluding other schemes', () {
    const examples = [
      ('export_status', 'planning_to_export', 'Export promotion'),
      ('has_gi_tag', 'yes', 'Geographical Indication support'),
      ('cluster_membership', 'part_of_a_cluster', 'Cluster development'),
      ('org_structure', 'self_help_group_shg', 'Self-Help Group credit'),
      (
        'digital_literacy_level',
        'basic_whatsapp_upi_only',
        'Digital literacy training',
      ),
      ('tax_compliance_comfort', 'need_basic_guidance', 'GST training'),
      ('special_focus_zone', ['tribal_area'], 'Tribal enterprise support'),
      (
        'business_location',
        {'area': 'village_rural'},
        'Rural business support',
      ),
    ];
    for (final (field, answer, title) in examples) {
      final results = service.rank(
        [
          const Scheme(id: 'general', name: 'General support'),
          Scheme(id: 'match', name: title),
        ],
        {field: answer},
      );

      expect(results.map((result) => result.scheme.id), [
        'match',
        'general',
      ], reason: field);
      expect(
        results.every((result) => result.fit != QuestionnaireFit.notNow),
        isTrue,
      );
    }
  });
}
