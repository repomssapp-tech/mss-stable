import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_extras.dart';
import 'package:frontend/screens/regular_mode/scheme_details/scheme_action_target.dart';

void main() {
  group('SchemeExtras without legacy source', () {
    final raw = <String, dynamic>{
      'content': {
        'status': {'value': 'active', 'asOf': '2026-09-01'},
        'applicationProcess': {
          'applicationStatus': 'unknown',
          'procedureType': 'official',
          'statusCheckedOn': '2026-09-01',
          'deadline': 'Rolling',
          'prerequisite': 'Udyam registration',
          'applicationFeeText': 'Nil',
        },
        'benefitFacts': {
          'facts': [
            {'type': 'grant', 'cap_amount': 100000},
          ],
        },
        'contacts': {'phone': '1800-000'},
      },
      'localization': {
        'ta': {
          'statusNote': 'நிலை குறிப்பு',
          'stepsList': ['படி 1'],
        },
      },
    };
    final extras = SchemeExtras.fromEntity(raw);

    test('keeps application details', () {
      expect(extras.isEmpty, isFalse);
      expect(extras.applicationStatus, 'unknown');
      expect(extras.procedureType, 'official');
      expect(extras.statusCheckedOn, '2026-09-01');
      expect(extras.deadline, 'Rolling');
      expect(extras.prerequisite, 'Udyam registration');
      expect(extras.fees, 'Nil');
      expect(extras.statusValue, 'active');
      expect(extras.statusAsOf, '2026-09-01');
    });

    test('keeps benefit facts, contacts and localized fields', () {
      expect(extras.benefitFacts('en').single.type, 'grant');
      expect(extras.contacts('en').single.value, '1800-000');
      expect(extras.statusNote('ta'), 'நிலை குறிப்பு');
      expect(extras.storedSteps('ta'), ['படி 1']);
    });

    test('missing values stay absent', () {
      final bare = SchemeExtras.fromEntity({
        'content': {
          'applicationProcess': {'procedureType': 'official'},
        },
      });
      expect(bare.applicationStatus, isEmpty);
      expect(bare.deadline, isEmpty);
      expect(bare.fees, isEmpty);
    });

    test('record with neither source nor extras is empty', () {
      expect(SchemeExtras.fromEntity({'content': {}}).isEmpty, isTrue);
    });
  });

  group('resolveSchemeAction', () {
    SchemeActionTarget go(String status, {String apply = 'https://a.gov.in'}) =>
        resolveSchemeAction(
          applicationUrl: apply,
          schemeUrl: 'https://info.gov.in',
          officialWebsite: '',
          applicationStatus: status,
        );

    test('confirmed open application with a link is a direct Apply', () {
      final t = go('open');
      expect(t.kind, SchemeActionKind.apply);
      expect(t.url, 'https://a.gov.in');
    });

    test('unknown or missing status never implies open', () {
      for (final s in ['unknown', '']) {
        final t = go(s);
        expect(t.kind, SchemeActionKind.officialInfo, reason: s);
        expect(t.url, 'https://info.gov.in');
      }
    });

    test('closed status keeps the information link', () {
      expect(go('closed').kind, SchemeActionKind.officialInfo);
    });

    test('no usable link disables the action', () {
      final t = resolveSchemeAction(
        applicationUrl: 'javascript:alert(1)',
        schemeUrl: '',
        officialWebsite: '',
        applicationStatus: 'open',
      );
      expect(t.isEnabled, isFalse);
    });
  });
}
