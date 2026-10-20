// Every filter, run against EVERY scheme in the real catalog, in every language.
//
// - a Discover card's count equals the size of the list it opens
// - each facet (offer type, beneficiary, coverage, state) returns exactly the
//   schemes it describes, and the count shown on its chip is that same number
// - combined facets intersect
// - every scheme survives the facet that describes it
// - every browse title and filter label is translated in Tamil and Hindi
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/l10n/app_localizations_en.dart';
import 'package:frontend/l10n/app_localizations_hi.dart';
import 'package:frontend/l10n/app_localizations_ta.dart';
import 'package:frontend/models/scheme_filter.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/screens/regular_mode/categories/discover_counts.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';

bool _stateOk(Scheme s, String state) =>
    schemeIsNationwide(s) ||
    s.state.toLowerCase().contains(state.toLowerCase());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Scheme> all;
  setUpAll(() async {
    all = await SchemeRepository.instance.getAllSchemes();
  });

  test('the whole catalog is loaded', () {
    expect(all.length, greaterThan(300));
  });

  group('browse cards', () {
    test('every card count equals the size of the list it opens', () {
      final counts = DiscoverCounts.compute(all);
      void check(String kind, List<String> labels) {
        for (final label in labels) {
          expect(
            DiscoverCounts.schemesFor(label, kind, all).length,
            counts[label],
            reason: '$kind "$label"',
          );
        }
      }

      check('category', DiscoverCounts.categoryLabels);
      check('ministry', DiscoverCounts.ministryLabels);
      check('state', DiscoverCounts.stateLabels);
    });

    test('a browse list only ever holds catalog schemes', () {
      final ids = all.map((s) => s.id).toSet();
      for (final label in DiscoverCounts.categoryLabels) {
        final list = DiscoverCounts.schemesFor(label, 'category', all);
        expect(list.every((s) => ids.contains(s.id)), isTrue, reason: label);
      }
    });
  });

  group('offer types', () {
    for (final g in kSchemeTypeGroups) {
      test('"${g.id}" returns exactly the schemes of that type', () {
        final got = applySchemeFilters(all, {
          'schemeTypes': [g.id],
        }).map((s) => s.id).toSet();
        final want = all.where(g.matches).map((s) => s.id).toSet();
        expect(got, want);
        expect(schemeFacetCount(all, {}, 'schemeTypes', g.id), want.length);
      });
    }
  });

  group('beneficiaries', () {
    for (final (code, _) in kBeneficiaryOptions) {
      test('"$code" returns exactly the schemes for that group', () {
        final got = applySchemeFilters(all, {
          'beneficiaries': [code],
        }).map((s) => s.id).toSet();
        final want = all
            .where(
              (s) => s.specialCategories
                  .map((e) => e.toLowerCase())
                  .contains(code),
            )
            .map((s) => s.id)
            .toSet();
        expect(got, want);
        expect(schemeFacetCount(all, {}, 'beneficiaries', code), want.length);
      });
    }
  });

  group('coverage and state', () {
    test('nationwide keeps only nationwide schemes, and all of them', () {
      final got = applySchemeFilters(all, {'coverage': 'nationwide'});
      expect(got.every(schemeIsNationwide), isTrue);
      expect(got.length, all.where(schemeIsNationwide).length);
    });

    test('a state keeps nationwide schemes plus that state, nothing else', () {
      for (final state in [
        'Maharashtra',
        'Tamil Nadu',
        'Kerala',
        'Karnataka',
        'Uttar Pradesh',
        'Gujarat',
      ]) {
        final got = applySchemeFilters(all, {
          'coverage': 'state',
          'state': state,
        });
        expect(got.every((s) => _stateOk(s, state)), isTrue, reason: state);
        expect(
          got.length,
          all.where((s) => _stateOk(s, state)).length,
          reason: state,
        );
      }
    });

    test("a Maharashtra user never sees another state's own scheme", () {
      final got = applySchemeFilters(all, {
        'coverage': 'state',
        'state': 'Maharashtra',
      });
      final foreign = got.where(
        (s) =>
            !schemeIsNationwide(s) &&
            !s.state.toLowerCase().contains('maharashtra'),
      );
      expect(foreign, isEmpty);
    });
  });

  group('every scheme survives the facet that describes it', () {
    test('state, nationwide and offer type', () {
      for (final s in all) {
        if (schemeIsNationwide(s)) {
          expect(applySchemeFilters([s], {'coverage': 'nationwide'}), [
            s,
          ], reason: s.id);
        } else if (s.state.trim().isNotEmpty) {
          expect(
            applySchemeFilters([s], {'coverage': 'state', 'state': s.state}),
            [s],
            reason: s.id,
          );
          expect(
            applySchemeFilters([s], {'coverage': 'nationwide'}),
            isEmpty,
            reason: s.id,
          );
        }
        for (final g in kSchemeTypeGroups.where((g) => g.matches(s))) {
          expect(
            applySchemeFilters(
              [s],
              {
                'schemeTypes': [g.id],
              },
            ),
            [s],
            reason: '${s.id} / ${g.id}',
          );
        }
      }
    });

    test('beneficiary group', () {
      for (final s in all) {
        for (final c in s.specialCategories.map((e) => e.toLowerCase())) {
          expect(
            applySchemeFilters(
              [s],
              {
                'beneficiaries': [c],
              },
            ),
            [s],
            reason: '${s.id} / $c',
          );
        }
      }
    });
  });

  group('combined facets', () {
    test('state + offer type is the intersection', () {
      for (final g in kSchemeTypeGroups) {
        final got = applySchemeFilters(all, {
          'coverage': 'state',
          'state': 'Maharashtra',
          'schemeTypes': [g.id],
        }).map((s) => s.id).toSet();
        final want = all
            .where((s) => _stateOk(s, 'Maharashtra') && g.matches(s))
            .map((s) => s.id)
            .toSet();
        expect(got, want, reason: g.id);
      }
    });

    test('two beneficiary groups are a union, one offer type narrows it', () {
      final women = applySchemeFilters(all, {
        'beneficiaries': ['women'],
      });
      final womenOrSc = applySchemeFilters(all, {
        'beneficiaries': ['women', 'sc'],
      });
      expect(womenOrSc.length, greaterThanOrEqualTo(women.length));
      final womenLoans = applySchemeFilters(all, {
        'beneficiaries': ['women'],
        'schemeTypes': ['loans'],
      });
      expect(womenLoans.length, lessThanOrEqualTo(women.length));
      expect(womenLoans.every(women.contains), isTrue);
    });

    test('clearing every facet returns the whole catalog', () {
      expect(applySchemeFilters(all, const {}).length, all.length);
      expect(
        applySchemeFilters(all, {
          'coverage': '',
          'state': 'All',
          'schemeTypes': <String>[],
          'beneficiaries': <String>[],
        }).length,
        all.length,
      );
    });
  });

  group('languages', () {
    final latin = RegExp(r'[A-Za-z]{3,}');

    // Acronyms that stay as they are in every language.
    const acronyms = {'filterBenSc', 'filterBenSt'};

    for (final lang in ['ta', 'hi']) {
      testWidgets('browse card titles are translated in $lang', (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        );
        // Exactly what the Discover screen shows: categories from the ARB,
        // ministries and states through the translator.
        final shown = [
          for (final l in DiscoverCounts.categoryLabels)
            localizedCategoryLabel(ctx, l),
          for (final l in [
            ...DiscoverCounts.ministryLabels,
            ...DiscoverCounts.stateLabels,
          ])
            CentralizedTranslator.instance.localizeFor(lang, l),
        ];
        final untranslated = [
          for (final s in shown)
            if (latin.hasMatch(s)) s,
        ];
        expect(untranslated, isEmpty, reason: '$lang: $untranslated');
      });
    }

    test('filter and sort labels are translated in Tamil and Hindi', () {
      final en = AppLocalizationsEn();
      final ta = AppLocalizationsTa();
      final hi = AppLocalizationsHi();
      final getters = <String, String Function(AppLocalizations)>{
        'filterTitle': (l) => l.filterTitle,
        'filterClearAll': (l) => l.filterClearAll,
        'filterGroupCoverage': (l) => l.filterGroupCoverage,
        'filterGroupOffers': (l) => l.filterGroupOffers,
        'filterGroupFor': (l) => l.filterGroupFor,
        'filterCoverageNationwide': (l) => l.filterCoverageNationwide,
        'filterTypeLoans': (l) => l.filterTypeLoans,
        'filterTypeSubsidies': (l) => l.filterTypeSubsidies,
        'filterTypeGrants': (l) => l.filterTypeGrants,
        'filterTypeGuarantee': (l) => l.filterTypeGuarantee,
        'filterTypeTraining': (l) => l.filterTypeTraining,
        'filterTypeMarket': (l) => l.filterTypeMarket,
        'filterTypeInfra': (l) => l.filterTypeInfra,
        'filterBenWomen': (l) => l.filterBenWomen,
        'filterBenSc': (l) => l.filterBenSc,
        'filterBenSt': (l) => l.filterBenSt,
        'filterBenDifferentlyAbled': (l) => l.filterBenDifferentlyAbled,
        'filterBenTransgender': (l) => l.filterBenTransgender,
        'filterBenMinority': (l) => l.filterBenMinority,
        'filterBenExServicemen': (l) => l.filterBenExServicemen,
        'sortRelevance': (l) => l.sortRelevance,
        'sortBestMatch': (l) => l.sortBestMatch,
        'sortSchemeNameAz': (l) => l.sortSchemeNameAz,
        'clearFiltersAndExplore': (l) => l.clearFiltersAndExplore,
        'schemeNotApplicable': (l) => l.schemeNotApplicable,
      };
      getters.forEach((name, get) {
        final e = get(en);
        expect(e, isNotEmpty, reason: name);
        for (final entry in {'ta': get(ta), 'hi': get(hi)}.entries) {
          expect(entry.value, isNotEmpty, reason: '$name (${entry.key})');
          if (!acronyms.contains(name)) {
            expect(
              entry.value,
              isNot(e),
              reason: '$name (${entry.key}) is English',
            );
          }
          expect(
            latin.hasMatch(entry.value),
            isFalse,
            reason: '$name (${entry.key}) has English: ${entry.value}',
          );
        }
      });
    });
  });
}
