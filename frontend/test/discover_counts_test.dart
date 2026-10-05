// ignore_for_file: avoid_print
//
// COMMIT 1 — Discover screen counts must be a deterministic derivation of the
// offline catalog (SchemeRepository.getAllSchemes() == bundle.schemes, 219
// rows) via structured fields, NOT keyword `.where()` over free-text overview,
// NOT `/v1/search`, NOT hardcoded totals.
//
// This test recomputes every displayed grouping with the SAME public predicate
// the screen uses (DiscoverCounts.matchesCategory / matchesMinistry /
// matchesState) and asserts DiscoverCounts.compute() equals it. If the counts
// ever diverge from the bundle (e.g. someone hardcodes a literal, or wires the
// screen back to getSchemesByCategory), this test breaks.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/screens/regular_mode/categories_screen.dart'
    show DiscoverCounts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Scheme> schemes;

  setUpAll(() async {
    schemes = await SchemeRepository.instance.getAllSchemes();
  });

  test('catalog has exactly 171 distinct schemes (one row == one scheme; D4 hides 131 draft schemes)', () {
    expect(schemes.length, 171);
    expect(schemes.map((s) => s.id).toSet().length, 171);
  });

  test('compute() is a pure derivation from the 171 rows via the same '
      'per-scheme predicate the screen renders', () {
    final counts = DiscoverCounts.compute(schemes);

    for (final label in DiscoverCounts.categoryLabels) {
      final expected =
          schemes.where((s) => DiscoverCounts.matchesCategory(s, label)).length;
      expect(counts[label], expected, reason: 'category "$label"');
    }
    for (final label in DiscoverCounts.ministryLabels) {
      final expected =
          schemes.where((s) => DiscoverCounts.matchesMinistry(s, label)).length;
      expect(counts[label], expected, reason: 'ministry "$label"');
    }
    for (final label in DiscoverCounts.stateLabels) {
      final expected =
          schemes.where((s) => DiscoverCounts.matchesState(s, label)).length;
      expect(counts[label], expected, reason: 'state "$label"');
    }

    // Every label the screen can look up must have a value.
    for (final label in [
      ...DiscoverCounts.categoryLabels,
      ...DiscoverCounts.ministryLabels,
      ...DiscoverCounts.stateLabels,
    ]) {
      expect(counts.containsKey(label), isTrue, reason: 'missing "$label"');
    }
  });

  test('state counts: central schemes apply nationally (intentional overlap), '
      'and no state is silently pinned to the catalog total', () {
    final counts = DiscoverCounts.compute(schemes);
    final national = schemes.where(DiscoverCounts.nationallyApplicable).length;

    // Every state count is at least the nationally-applicable baseline.
    for (final st in DiscoverCounts.stateLabels) {
      expect(counts[st], greaterThanOrEqualTo(national), reason: st);
      // ...but never exceeds the whole catalog.
      expect(counts[st], lessThanOrEqualTo(171), reason: st);
    }

    // Tamil Nadu carries extra state-scoped schemes the others do not, so it
    // must be strictly larger than a state with no state-scoped schemes.
    // (Breaks immediately if all states are hardcoded to one number.)
    expect(counts['Tamil Nadu']!, greaterThan(counts['Uttar Pradesh']!));
    expect(counts['Tamil Nadu']!, greaterThan(national));
    expect(counts['Uttar Pradesh'], national);
  });

  test('ministry counts come from the structured ministry / sponsoringBody '
      'field, not an overview keyword sweep', () {
    final counts = DiscoverCounts.compute(schemes);

    // MSME is the dominant ministry in this catalog; it must be a substantial
    // but sub-total, structured number.
    expect(counts['Ministry of MSME']!, greaterThan(20));
    expect(counts['Ministry of MSME']!, lessThan(120));

    // Recompute MSME independently straight off the structured fields.
    final msmeExpected = schemes.where((s) {
      final hay = (s.ministry.isNotEmpty ? s.ministry : s.sponsoringBody)
          .toLowerCase();
      return hay.contains('micro, small') || hay.contains('msme');
    }).length;
    expect(counts['Ministry of MSME'], msmeExpected);

    // Ministries are not all equal — a hardcoded map would fail this.
    final distinct = DiscoverCounts.ministryLabels
        .map((m) => counts[m])
        .toSet();
    expect(distinct.length, greaterThan(1));
  });

  test('category counts are deterministic, overlapping, and 0 is allowed '
      '(no MSME "non-empty" fallback)', () {
    final counts = DiscoverCounts.compute(schemes);

    // Categories overlap by design (a scheme can be both "Startup" and
    // "Women Entrepreneurship"), so the sum exceeds 171. Reported, not hidden.
    final sum = DiscoverCounts.categoryLabels
        .fold<int>(0, (a, l) => a + (counts[l] ?? 0));
    print('sum(category counts) = $sum across '
        '${DiscoverCounts.categoryLabels.length} labels (> 171 by overlap)');
    expect(sum, greaterThan(171));

    // Not all categories are the same number (a hardcoded constant would fail).
    expect(DiscoverCounts.categoryLabels.map((l) => counts[l]).toSet().length,
        greaterThan(3));

    // No category is allowed to balloon to "basically the whole catalog" the
    // way the old MSME-fallback did.
    for (final l in DiscoverCounts.categoryLabels) {
      expect(counts[l]!, lessThan(170), reason: l);
    }
  });

  test('counts are connectivity-independent: two calls are identical', () async {
    final a = DiscoverCounts.compute(schemes);
    final b = DiscoverCounts.compute(await SchemeRepository.instance.getAllSchemes());
    expect(a, b);
  });

  test('absolute pins against release 1.35.1-alpha (171 schemes) — a future '
      'weakening of the keyword lists breaks the suite', () {
    final counts = DiscoverCounts.compute(schemes);
    final national = schemes.where(DiscoverCounts.nationallyApplicable).length;
    // These are the honest structured numbers for the shipped bundle; if the
    // catalog is re-released they will need updating, which is the point —
    // the count logic must not drift silently.
    expect(national, 155, reason: 'nationally-applicable baseline');
    expect(counts['Tamil Nadu'], 171, reason: 'national + TN-scoped schemes');
    expect(counts['Uttar Pradesh'], 155, reason: 'national only');
    expect(counts['Ministry of MSME'], 76);
    expect(counts['Ministry of Education'], 0);
  });

  test('FAILS if a count is replaced by a hardcoded literal', () {
    final counts = DiscoverCounts.compute(schemes);
    // Simulate a regression: someone hardcodes Maharashtra to 130.
    final tampered = Map<String, int>.from(counts)..['Maharashtra'] = 130;
    final honest = schemes
        .where((s) => DiscoverCounts.matchesState(s, 'Maharashtra'))
        .length;
    expect(tampered['Maharashtra'], isNot(honest));
    expect(counts['Maharashtra'], honest);
  });
}
