import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/scheme_filter.dart';

/// The one facet matcher used by both the search screen and the results
/// screen. Normalized set-membership -- never a brittle literal compare.
void main() {
  Scheme s(
    String id, {
    String state = 'Tamil Nadu',
    String schemeType = '',
    List<String> special = const [],
    String category = '',
  }) => Scheme(
    id: id,
    name: id,
    state: state,
    schemeType: schemeType,
    category: category,
    specialCategories: special,
  );

  final catalog = [
    s('TN_LOAN', state: 'Tamil Nadu', schemeType: 'loan'),
    s('NAT_LOAN', state: 'Pan-India', schemeType: 'loan'),
    s('KA_SUBSIDY', state: 'Karnataka', schemeType: 'capital_subsidy'),
    s('NAT_GRANT', state: 'All India', schemeType: 'grant'),
    s('NAT_WOMEN', state: 'India', schemeType: 'loan', special: ['women']),
    s('TN_SC', state: 'Tamil Nadu', schemeType: 'grant', special: ['sc']),
  ];

  test('empty filter is a no-op', () {
    expect(applySchemeFilters(catalog, const {}).length, catalog.length);
    expect(hasActiveSchemeFilters(const {}), isFalse);
  });

  test('coverage=nationwide keeps only nationwide schemes', () {
    final out = applySchemeFilters(catalog, {'coverage': 'nationwide'});
    expect(
      out.map((e) => e.id),
      unorderedEquals(['NAT_LOAN', 'NAT_GRANT', 'NAT_WOMEN']),
    );
  });

  test('a state keeps that state + every nationwide labelling', () {
    final out = applySchemeFilters(catalog, {'state': 'Tamil Nadu'});
    expect(
      out.map((e) => e.id),
      unorderedEquals([
        'TN_LOAN',
        'TN_SC',
        'NAT_LOAN',
        'NAT_GRANT',
        'NAT_WOMEN',
      ]),
    );
  });

  test('scheme-type groups match by intent, not exact enum', () {
    final loans = applySchemeFilters(catalog, {
      'schemeTypes': ['loans'],
    });
    expect(
      loans.map((e) => e.id),
      unorderedEquals(['TN_LOAN', 'NAT_LOAN', 'NAT_WOMEN']),
    );

    final subsidies = applySchemeFilters(catalog, {
      'schemeTypes': ['subsidies'],
    });
    expect(subsidies.map((e) => e.id), ['KA_SUBSIDY']);
  });

  test('multiple type groups union; beneficiary intersects', () {
    final out = applySchemeFilters(catalog, {
      'schemeTypes': ['loans', 'grants'],
      'beneficiaries': ['women'],
    });
    expect(out.map((e) => e.id), ['NAT_WOMEN']);
  });

  test('facets compose as intersection', () {
    final out = applySchemeFilters(catalog, {
      'state': 'Tamil Nadu',
      'schemeTypes': ['grants'],
    });
    expect(out.map((e) => e.id), unorderedEquals(['NAT_GRANT', 'TN_SC']));
  });

  test('activeSchemeFilterCount counts groups, not values', () {
    expect(
      activeSchemeFilterCount({
        'coverage': 'nationwide',
        'schemeTypes': ['loans', 'grants'],
      }),
      2,
    );
  });

  test('schemeFacetCount previews a toggle in the current context', () {
    // Within "nationwide", how many are loans?
    final n = schemeFacetCount(
      catalog,
      {'coverage': 'nationwide'},
      'schemeTypes',
      'loans',
    );
    expect(n, 2); // NAT_LOAN, NAT_WOMEN
  });
}
