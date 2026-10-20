// A typed scheme name or acronym must stay findable even when "For Me" or a
// facet filter would drop it: the results view shows it with a distinct
// "not applicable" pill instead of pretending the scheme does not exist.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/screens/regular_mode/search/search_models.dart';

Scheme _scheme(String id, String name, {String shortName = ''}) => Scheme(
  id: id,
  name: name,
  state: 'All India',
  category: 'General',
  shortName: shortName,
);

void main() {
  final pmegp = _scheme(
    'PMEGP',
    'Prime Minister’s Employment Generation Programme (PMEGP)',
  );
  final other = _scheme('LOAN1', 'Credit Guarantee for Micro Enterprises');
  final dduGky = _scheme(
    'DDUGKY',
    'Deen Dayal Upadhyaya Grameen Kaushalya Yojana',
    shortName: 'DDU-GKY',
  );

  group('isExactSchemeQuery', () {
    test('matches an acronym in the name, ignoring case', () {
      expect(isExactSchemeQuery(pmegp, 'pmegp'), isTrue);
      expect(isExactSchemeQuery(pmegp, ' PMEGP '), isTrue);
    });

    test('matches the full name and the short name', () {
      expect(
        isExactSchemeQuery(
          pmegp,
          'prime minister’s employment generation programme',
        ),
        isTrue,
      );
      expect(isExactSchemeQuery(dduGky, 'ddugky'), isTrue);
      expect(isExactSchemeQuery(dduGky, 'DDU GKY'), isTrue);
    });

    test('does not match generic words or very short queries', () {
      expect(isExactSchemeQuery(pmegp, 'loan'), isFalse);
      expect(isExactSchemeQuery(pmegp, 'employment'), isFalse);
      expect(isExactSchemeQuery(pmegp, 'pm'), isFalse);
      expect(isExactSchemeQuery(pmegp, ''), isFalse);
    });
  });

  group('exactMatchesHidden', () {
    test('returns the exact match that the filters dropped', () {
      final hidden = exactMatchesHidden(
        query: 'pmegp',
        candidates: [pmegp, other],
        shown: const [],
      );
      expect(hidden.map((s) => s.id), ['PMEGP']);
    });

    test('does not repeat a scheme that is already shown', () {
      final hidden = exactMatchesHidden(
        query: 'pmegp',
        candidates: [pmegp, other],
        shown: [pmegp],
      );
      expect(hidden, isEmpty);
    });

    test('ignores a generic query', () {
      final hidden = exactMatchesHidden(
        query: 'loan',
        candidates: [pmegp, other],
        shown: const [],
      );
      expect(hidden, isEmpty);
    });
  });
}
