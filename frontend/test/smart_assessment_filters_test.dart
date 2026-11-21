import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/questionnaire.dart';
import 'package:frontend/models/scheme_model.dart';
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

  test('adaptive order selects a question that changes top results', () {
    final schemes = [
      for (var index = 0; index < 10; index++)
        Scheme(id: 'general-$index', name: 'General $index'),
      for (var index = 0; index < 10; index++)
        Scheme(
          id: 'women-$index',
          name: 'Women $index',
          specialCategories: const ['women'],
        ),
    ];
    const question = QuestionnaireField(
      id: 'social_category',
      type: 'multi_select',
      requiredFor: 'both',
      question: {},
      hints: {},
      options: [
        QuestionnaireOption(value: 'woman', labels: {}),
        QuestionnaireOption(value: 'sc', labels: {}),
      ],
      parts: [],
      answerRules: {},
      subInput: null,
    );

    final next = service.chooseNextQuestion(
      schemes: schemes,
      fields: const [question],
      answers: const {},
      excludedIds: const {},
    );

    expect(next?.id, 'social_category');
  });
}
