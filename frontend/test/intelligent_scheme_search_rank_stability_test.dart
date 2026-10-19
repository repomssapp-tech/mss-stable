import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/search/intelligent_scheme_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2.1 perf fix: caching _normalize's two RegExps as static finals, adding
  // a memoization cache, and an alreadyNormalized fast path for the
  // intent.terms hot loop must not change rank() output at all. This golden
  // snapshot was captured against the real catalog bundle both before and
  // after the fix (verified identical via `git stash` of the fix file) --
  // it exists so a future change to the matching logic can't silently
  // reorder results without a test noticing.
  test('ranking the real catalog for a representative statement stays '
      'byte-identical to the pre-perf-fix snapshot', () async {
    final schemes = await SchemeRepository.instance.getAllSchemes();
    const statement =
        'I am a woman in Tamil Nadu and need a loan to start a manufacturing business';

    final matches = IntelligentSchemeSearch.rank(statement, schemes, limit: 5);

    expect(
      matches.map((m) => m.scheme.schemeCode).toList(),
      equals([
        'TN2026-045',
        'TN2026-004',
        'TN2026-043',
        'TN2026-042',
        'CEN2026-112',
      ]),
    );
    expect(
      matches.map((m) => double.parse(m.score.toStringAsFixed(4))).toList(),
      equals([0.9989, 0.9985, 0.9985, 0.9983, 0.9981]),
    );
  });
}
