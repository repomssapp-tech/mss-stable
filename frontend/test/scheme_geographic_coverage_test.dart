// Issue #143 (1): where a scheme applies comes from the catalog's structured
// coverage -- `classification.government.appliesNationally` and the explicit
// `states` codes -- not from the government level (a central scheme can be
// limited to some states), and never from the scheme's name or id. A record
// that gives no coverage stays unknown instead of defaulting to All India or
// Tamil Nadu.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/models/scheme_filter.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/screens/regular_mode/categories/discover_counts.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/recommendation/indian_states.dart';

const _northEast = [
  'Arunachal Pradesh',
  'Assam',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Sikkim',
  'Tripura',
];

/// CEN2026-090 as the corrected catalog describes it: a central scheme for
/// the North Eastern states and Sikkim only.
MssEntity _nerScheme() => MssEntity.fromJson({
  'identity': {
    'id': 'CEN2026-090',
    'code': 'CEN2026-090',
    'entityType': 'scheme',
    'name': 'Promotion of MSME in NER and SIKKIM',
  },
  'content': {
    'classification': {
      'government': {
        'level': 'central',
        'levelText': 'Central',
        'appliesNationally': false,
        'states': [
          'IN-AR',
          'IN-AS',
          'IN-MN',
          'IN-ML',
          'IN-MZ',
          'IN-NL',
          'IN-SK',
          'IN-TR',
        ],
      },
    },
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  late Scheme ner;
  setUpAll(() async {
    bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
    ner = MssSchemeAdapter.toScheme(_nerScheme(), bundle);
  });

  group('IndianStates.code', () {
    test('names, short codes and ISO codes normalize to one code', () {
      for (final raw in [
        'Tamil Nadu',
        'tamil nadu',
        'tn',
        'TN',
        'IN-TN',
        'in-tn',
        'தமிழ்நாடு',
        'तमिलनाडु',
      ]) {
        expect(IndianStates.code(raw), 'IN-TN', reason: raw);
      }
      expect(IndianStates.code('Kerala'), 'IN-KL');
      expect(IndianStates.code('OR'), 'IN-OD'); // superseded code
      expect(IndianStates.code('Atlantis'), isNull);
      expect(IndianStates.code(''), isNull);
      expect(IndianStates.nameForCode('IN-SK'), 'Sikkim');
    });
  });

  group('a central scheme limited to some states', () {
    test('the adapter keeps ownership and coverage apart', () {
      expect(ner.governmentLevel, 'Central');
      expect(ner.appliesNationally, isFalse);
      expect(ner.stateCodes, hasLength(8));
      // No statesText: the display text is built from the codes.
      expect(ner.state, contains('Sikkim'));
    });

    test('appears in the North East and nowhere else', () {
      for (final state in _northEast) {
        expect(schemeAppliesInState(ner, state), isTrue, reason: state);
      }
      for (final state in ['Tamil Nadu', 'Maharashtra', 'Kerala']) {
        expect(schemeAppliesInState(ner, state), isFalse, reason: state);
      }
      expect(schemeAppliesNationally(ner), isFalse);
      expect(DiscoverCounts.matchesState(ner, 'Assam'), isTrue);
      expect(DiscoverCounts.matchesState(ner, 'Tamil Nadu'), isFalse);
      expect(
        applySchemeFilters([ner], {'coverage': 'state', 'state': 'Kerala'}),
        isEmpty,
      );
      expect(
        applySchemeFilters([ner], {'coverage': 'state', 'state': 'IN-SK'}),
        [ner],
      );
    });
  });

  group('coverage is never inferred', () {
    test('missing coverage stays unknown', () {
      final unknown = MssSchemeAdapter.toScheme(
        MssEntity.fromJson({
          'identity': {
            'id': 'X-1',
            'code': 'X-1',
            'entityType': 'scheme',
            'name': 'Some central scheme',
          },
          'content': {
            'classification': {
              'government': {'level': 'central'},
            },
          },
        }),
        bundle,
      );
      expect(unknown.state, isEmpty); // not "All India"
      expect(unknown.appliesNationally, isNull);
      for (final state in ['Tamil Nadu', 'Assam']) {
        expect(schemeAppliesInState(unknown, state), isFalse, reason: state);
      }
    });

    test('a scheme name or id naming a state does not place it there', () {
      const scheme = Scheme(
        id: 'TN_2026_001',
        schemeCode: 'tn_2026_001',
        name: 'Tamil Nadu Entrepreneurs Scheme',
        state: 'Maharashtra',
        appliesNationally: false,
        stateCodes: ['IN-MH'],
      );
      expect(schemeAppliesInState(scheme, 'Tamil Nadu'), isFalse);
      expect(schemeAppliesInState(scheme, 'tn'), isFalse);
      expect(schemeAppliesInState(scheme, 'Maharashtra'), isTrue);
    });
  });

  group('SchemeRepository.getSchemesByState on the shipped catalog', () {
    final repo = SchemeRepository.instance;

    Future<Set<String>> ids(String state) async => {
      for (final s in await repo.getSchemesByState(state)) s.id,
    };

    test('Tamil Nadu, tn and IN-TN give the same schemes', () async {
      final byName = await ids('Tamil Nadu');
      expect(byName, isNotEmpty);
      expect(await ids('tn'), byName);
      expect(await ids('IN-TN'), byName);
      expect(await ids('தமிழ்நாடு'), byName);
    });

    test('CEN2026-090 is excluded outside the North East', () async {
      for (final state in ['Tamil Nadu', 'Maharashtra', 'Kerala']) {
        expect(await ids(state), isNot(contains('CEN2026-090')), reason: state);
      }
    });

    test('genuine nationwide schemes stay available everywhere', () async {
      for (final state in ['Tamil Nadu', 'Maharashtra', 'Kerala', 'Assam']) {
        final got = await ids(state);
        expect(got, contains('CEN2026-085'), reason: state); // PMEGP
        // The all-India central scheme filed in the Tamil Nadu dataset.
        expect(got, contains('TN2026-049'), reason: state);
      }
    });

    test('state schemes stay in their own state', () async {
      final tn = await ids('Tamil Nadu');
      final mh = await ids('Maharashtra');
      expect(tn.any((id) => id.startsWith('MAH')), isFalse);
      // Only the all-India scheme of the Tamil Nadu dataset reaches Maharashtra.
      expect(mh.where((id) => id.startsWith('TN2026-')), {'TN2026-049'});
      expect(tn, contains('TN2026-044')); // central_state, run by Tamil Nadu
      expect(await ids('Kerala'), isNot(contains('TN2026-044')));
    });
  });
}
