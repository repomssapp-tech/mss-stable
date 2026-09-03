// ignore_for_file: avoid_print
//
// COMMIT 2 — "For Me" must FILTER, not match the whole catalog.
//
// Phase 2 finding: RecommendationEngine.evaluate started every scheme at
// score = 1.0 and only ever subtracted, so a populated (or even an empty)
// profile kept ~all 219 schemes above the 0.4 "For Me" gate. The engine is
// now ADDITIVE (base 0.0, positively-matched facets add weight, hard
// disqualifications return 0.0 early), and "For Me" is gated on both a
// usable profile and score >= RecommendationEngine.forMeThreshold.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/engine/recommendation_engine.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart'
    show
        applyProviderFacetFilters,
        computeForMeView,
        ForMeEmptyState;
import 'package:frontend/services/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Scheme> all;

  setUpAll(() async {
    all = await SchemeRepository.instance.getAllSchemes();
  });

  UserProfile populated({String state = 'Tamil Nadu'}) => UserProfile(
        gender: 'Female',
        community: 'SC',
        state: state,
        dob: DateTime(2001, 1, 1),
        educationLevel: 'Undergraduate',
        businessIndustry: 'MSME',
        businessStage: 'Idea',
        profileCompleted: true,
      );

  test('additive engine: base score is 0 — an unmatched pair no longer scores '
      '~1.0 the way the subtractive engine did', () {
    final generic = Scheme(
      id: 'SYNTH_1',
      name: 'Generic Central Scheme',
      state: 'All India',
      category: 'General',
    );
    // Empty profile: no dob, no gender, all defaults.
    final r = RecommendationEngine.evaluate(UserProfile(), generic);
    expect(r.score, lessThan(RecommendationEngine.forMeThreshold),
        reason: 'empty profile must not clear the For Me gate');
    expect(r.score, lessThan(0.5));
  });

  test('populated profile: the "For Me" set is MATERIALLY smaller than the '
      'full 219-scheme catalog (not just < all)', () {
    final forMe = RecommendationEngine.forMeSchemes(populated(), all);
    print('For Me (populated) = ${forMe.length} / ${all.length}');
    expect(forMe, isNotEmpty);
    // A scheme that matches nothing substantive (only national coverage)
    // scores 0.20 and is excluded — so the personalised set is well under
    // the whole catalog, not a rounding error below it.
    expect(forMe.length, lessThan((0.7 * all.length).round()));
  });

  test('empty profile: "For Me" is empty and the screen must show the '
      '"complete your profile" state', () {
    expect(
      RecommendationEngine.hasEnoughProfileForRecommendation(UserProfile()),
      isFalse,
    );
    expect(RecommendationEngine.forMeSchemes(UserProfile(), all), isEmpty);
    // A brand-new user who only picked a state is still not enough.
    expect(
      RecommendationEngine.hasEnoughProfileForRecommendation(
        UserProfile(state: 'Kerala'),
      ),
      isFalse,
    );
  });

  test('a facet change further shrinks the result: a Karnataka profile keeps '
      'fewer schemes than the same profile in Tamil Nadu', () {
    final tnSet = RecommendationEngine.forMeSchemes(populated(), all);
    final kaSet =
        RecommendationEngine.forMeSchemes(populated(state: 'Karnataka'), all);
    print('TN For Me = ${tnSet.length}, Karnataka For Me = ${kaSet.length}');
    expect(kaSet.length, lessThan(tnSet.length),
        reason: 'Tamil-Nadu-scoped schemes must drop out for a Karnataka user');
  });

  test('a well-matched profile/scheme pair lands in a confident band, not '
      'pinned at 1.0', () {
    final womenScheme = Scheme(
      id: 'SYNTH_WOMEN',
      name: 'Women Entrepreneurs Support',
      state: 'All India',
      category: 'Women Entrepreneurs',
      targetBeneficiary: 'Women entrepreneurs',
      eligibilityGenderValues: const ['female'],
    );
    final r = RecommendationEngine.evaluate(populated(), womenScheme);
    expect(r.score, greaterThanOrEqualTo(RecommendationEngine.forMeThreshold));
    expect(r.score, lessThanOrEqualTo(1.0));
    expect(r.matchingReasons, isNotEmpty);
  });

  test('hard disqualifications still return exactly 0.0', () {
    final maleTn = UserProfile(
      gender: 'Male',
      state: 'Tamil Nadu',
      community: 'General',
      dob: DateTime(1990, 1, 1),
      profileCompleted: true,
    );
    // Women-only (structured gender facet).
    final womenOnly = Scheme(
      id: 'SYNTH_WO',
      name: 'Women Only',
      state: 'All India',
      eligibilityGenderValues: const ['female'],
      targetBeneficiary: 'Women',
    );
    expect(RecommendationEngine.evaluate(maleTn, womenOnly).score, 0.0);

    // Other-state-scoped scheme.
    final kaOnly = Scheme(
      id: 'SYNTH_KA',
      name: 'Karnataka Only',
      state: 'Karnataka',
    );
    expect(RecommendationEngine.evaluate(maleTn, kaOnly).score, 0.0);
  });

  // ── search_screen pure decision functions (COMMIT 2, REQUIRED 2) ──────

  group('applyProviderFacetFilters', () {
    final mixed = [
      Scheme(id: 'A', name: 'A', state: 'Tamil Nadu', category: 'MSME'),
      Scheme(id: 'B', name: 'B', state: 'Karnataka', category: 'MSME'),
      Scheme(id: 'C', name: 'C', state: 'All India', category: 'Startup'),
      Scheme(id: 'D', name: 'D', state: 'Maharashtra', category: 'Startup'),
    ];

    test('empty filter map is a no-op', () {
      expect(applyProviderFacetFilters(mixed, const {}).length, mixed.length);
      expect(
        applyProviderFacetFilters(mixed, const {'state': 'All'}).length,
        mixed.length,
      );
    });

    test('a state facet narrows to that state + All India only', () {
      final out = applyProviderFacetFilters(mixed, const {'state': 'Karnataka'});
      expect(out.map((s) => s.id), unorderedEquals(['B', 'C']));
      expect(out.length, lessThan(mixed.length));
    });

    test('a category facet narrows by category/sector token', () {
      final out = applyProviderFacetFilters(mixed, const {'category': 'Startup'});
      expect(out.map((s) => s.id), unorderedEquals(['C', 'D']));
    });
  });

  group('computeForMeView', () {
    test('sparse profile -> completeProfile empty state, no schemes, '
        'never the catalog', () {
      final view = computeForMeView(
        master: all,
        profile: UserProfile(),
        filters: const {},
      );
      expect(view.emptyState, ForMeEmptyState.completeProfile);
      expect(view.schemes, isEmpty);
    });

    test('populated profile but every master scheme is ineligible -> '
        'noMatches empty state, no catalog fallback', () {
      final onlyKarnatakaOnly = [
        Scheme(id: 'KO_1', name: 'KA only', state: 'Karnataka'),
        Scheme(id: 'KO_2', name: 'KA only 2', state: 'Karnataka'),
      ];
      final view = computeForMeView(
        master: onlyKarnatakaOnly,
        profile: populated(), // Tamil Nadu profile
        filters: const {},
      );
      expect(view.emptyState, ForMeEmptyState.noMatches);
      expect(view.schemes, isEmpty);
    });

    test('populated profile with matches -> none empty state and a strict '
        'subset of the catalog', () {
      final view = computeForMeView(
        master: all,
        profile: populated(),
        filters: const {},
      );
      expect(view.emptyState, ForMeEmptyState.none);
      expect(view.schemes, isNotEmpty);
      expect(view.schemes.length, lessThan(all.length));
    });

    test('a FilterPanel state facet intersects with the score gate and '
        'further shrinks the For-Me set', () {
      final unfiltered = computeForMeView(
        master: all,
        profile: populated(),
        filters: const {},
      ).schemes;
      final filtered = computeForMeView(
        master: all,
        profile: populated(),
        filters: const {'state': 'Karnataka'},
      ).schemes;
      print('For Me unfiltered=${unfiltered.length}, '
          '+state=Karnataka facet=${filtered.length}');
      expect(filtered.length, lessThan(unfiltered.length));
      // Every survivor is either All-India or Karnataka — the facet really
      // applied, it is not just the score gate.
      for (final s in filtered) {
        final st = s.state.toLowerCase();
        expect(st == 'all india' || st.contains('karnataka'), isTrue);
      }
    });
  });
}
