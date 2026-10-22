import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/catalog_manifest.dart';
import 'package:frontend/models/geo_coverage.dart';
import 'package:frontend/models/scheme_extras.dart';
import 'package:frontend/screens/regular_mode/scheme_details/scheme_action_target.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeoCoverage', () {
    const northEast = [
      'Arunachal Pradesh',
      'Assam',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Sikkim',
      'Tripura',
    ];
    final regional = GeoCoverage.fromGovernment({
      'level': 'Central',
      'appliesNationally': false,
      'states': northEast,
    });

    test('central scheme limited to the North East is not nationwide', () {
      for (final s in northEast) {
        expect(regional.coversState(s), isTrue, reason: s);
      }
      for (final s in ['Tamil Nadu', 'Maharashtra', 'Kerala']) {
        expect(regional.coversState(s), isFalse, reason: s);
      }
    });

    test('nationwide scheme covers every state', () {
      final all = GeoCoverage.fromGovernment({'appliesNationally': true});
      expect(all.coversState('Kerala'), isTrue);
      expect(all.coversState('IN-TN'), isTrue);
    });

    test('state name, short code and ISO code are equivalent', () {
      final tn = GeoCoverage.fromGovernment({
        'appliesNationally': false,
        'states': ['IN-TN'],
      });
      for (final s in ['Tamil Nadu', 'tn', 'IN-TN']) {
        expect(tn.coversState(s), isTrue, reason: s);
      }
    });

    test('missing coverage stays unknown and matches no state', () {
      final none = GeoCoverage.fromGovernment({'level': 'Central'});
      expect(none.isKnown, isFalse);
      expect(none.coversState('Tamil Nadu'), isFalse);
    });
  });

  group('getSchemesByState on the shipped catalog', () {
    Future<Set<String>> ids(String state) async => {
      for (final s in await SchemeRepository.instance.getSchemesByState(state))
        s.id,
    };

    test('CEN2026-090 follows its explicit states only', () async {
      for (final s in [
        'Arunachal Pradesh',
        'Assam',
        'Manipur',
        'Meghalaya',
        'Mizoram',
        'Nagaland',
        'Sikkim',
        'Tripura',
      ]) {
        expect(await ids(s), contains('CEN2026-090'), reason: s);
      }
      for (final s in ['Tamil Nadu', 'Maharashtra', 'Kerala']) {
        expect(await ids(s), isNot(contains('CEN2026-090')), reason: s);
      }
    });

    test('Tamil Nadu, tn and IN-TN give the same result', () async {
      final a = await ids('Tamil Nadu');
      expect(await ids('tn'), a);
      expect(await ids('IN-TN'), a);
    });
  });

  group('CatalogManifest', () {
    test('parses camelCase version-specific release json', () {
      final m = CatalogManifest.fromAnyReleaseShape({
        'releaseTag': '1.37.0-alpha',
        'bundleSha256': 'a' * 64,
        'bundleBytes': 12345,
        'schemaVersion': '1.0.0',
        'recordCounts': {'scheme_catalog.json': 406},
      });
      expect(m.releaseVersion, '1.37.0-alpha');
      expect(m.sha256, 'a' * 64);
      expect(m.byteSize, 12345);
      expect(m.schemeCount, 406);
      expect(m.schemaVersion, 1);
    });

    test('still parses the snake_case current row', () {
      final m = CatalogManifest.fromAnyReleaseShape({
        'release_version': '1.37.0-alpha',
        'package_sha256': 'b' * 64,
        'package_byte_size': 99,
        'record_counts': {'scheme_catalog.json': 3},
      });
      expect(m.releaseVersion, '1.37.0-alpha');
      expect(m.byteSize, 99);
    });
  });

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
