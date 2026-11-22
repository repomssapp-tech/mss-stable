import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/catalog/adapter/scheme_resources_resolver.dart';
import 'package:frontend/services/catalog/adapter/scheme_eligibility_resolver.dart';

void main() {
  test('a child age ceiling never invents a minimum age of 18', () {
    final entity = MssEntity.fromJson({
      'identity': {'id': 'CHILD'},
      'content': {
        'eligibility': {
          'structured': {
            'age': {'applies': true, 'maxYears': 10},
          },
        },
      },
    });
    final result = SchemeEligibilityResolver.resolve(
      entity,
      targetBeneficiary: '',
      langCode: 'en',
    );
    expect(result.ageRange, 'Up to 10 years');
    expect(result.eligibilityMinAge, isNull);
    expect(result.eligibilityMaxAge, 10);
  });
  test('no service is invented when the catalog does not declare one', () {
    final result = SchemeResourcesResolver.resolve(
      MssEntity.fromJson({
        'identity': {'id': 'TEST'},
        'content': <String, dynamic>{},
      }),
      issuingBody: 'Agency',
      langCode: 'en',
    );
    expect(result.serviceList, isEmpty);
  });

  test('declared services retain their mandatory flags and translations', () {
    final entity = MssEntity.fromJson({
      'identity': {'id': 'TEST'},
      'content': {
        'requiredServices': [
          {
            'name': {'en': 'Registration', 'hi': 'पंजीकरण'},
            'mandatory': true,
          },
          {'name': 'Advice', 'mandatory': false},
        ],
      },
    });
    final services = SchemeResourcesResolver.resolve(
      entity,
      issuingBody: 'Agency',
      langCode: 'hi',
    ).serviceList;
    expect(services, hasLength(2));
    expect(services.first.translated('name', 'hi'), 'पंजीकरण');
    expect(services.map((s) => s.mandatory), [true, false]);
  });
}
