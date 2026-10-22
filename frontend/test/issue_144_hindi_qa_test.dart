// Regression tests for issue #144 (Hindi QA of 1.4.3+11).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/controllers/library_controller.dart';
import 'package:frontend/screens/regular_mode/categories/categories_section_lists.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _devanagari = RegExp(r'[ऀ-ॿ]');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Scheme> all;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    LanguagePackManager.instance.isLanguageActiveOverride = (_) => true;
    LanguagePackManager.instance.hasValidPackOverride = (_) => true;
    await CentralizedTranslator.instance.ensureLoaded();
    // The app loads the Hindi pack when the user switches language.
    await LanguagePackManager.instance.loadPack('hi');
    all = await SchemeRepository.instance.getAllSchemes();
  });

  tearDownAll(() {
    LanguagePackManager.instance.isLanguageActiveOverride = null;
    LanguagePackManager.instance.hasValidPackOverride = null;
  });

  group('catalogue', () {
    test('every Tamil Nadu scheme has a Hindi name, summary and category', () {
      final tn = all.where((s) => s.id.startsWith('TN2026-')).toList();
      expect(tn, hasLength(53));
      for (final s in tn) {
        final hi = s.toLocalized('hi');
        expect(hi.name, matches(_devanagari), reason: '${s.id} name');
        expect(hi.overview, matches(_devanagari), reason: '${s.id} overview');
        expect(hi.category, matches(_devanagari), reason: '${s.id} category');
      }
    });

    test('TANSIDCO export scheme reads in Hindi (HI-143-02)', () {
      final s = all.firstWhere(
        (s) => s.name.startsWith('TANSIDCO Export Promotion'),
      );
      final hi = s.toLocalized('hi');
      expect(hi.name, contains('निर्यात'));
      expect(hi.overview, matches(_devanagari));
    });

    test('Startup India FoF 2.0 is not labelled Tamil Nadu (DATA-143-01)', () {
      final s = all.firstWhere((s) => s.id == 'CEN2026-190');
      for (final lang in ['en', 'hi', 'ta']) {
        final l = s.toLocalized(lang);
        for (final v in [l.ministry, l.sponsoringBody, l.department]) {
          expect(v, isNot(contains('Tamil Nadu')), reason: '$lang: $v');
          expect(v, isNot(contains('तमिलनाडु')), reason: '$lang: $v');
          expect(v, isNot(contains('தமிழ்நாடு')), reason: '$lang: $v');
        }
      }
      expect(s.toLocalized('hi').ministry, contains('वाणिज्य'));
    });
  });

  group('dictionary', () {
    String hi(String en) =>
        CentralizedTranslator.instance.localizeFor('hi', en);

    test('TReDS steps 3 and 4 are Hindi (HI-143-03)', () {
      for (final en in [
        '3. Bank Bidding',
        'Multiple banks and NBFCs view the accepted factoring unit and submit '
            'competing discount rate bids in an online auction.',
        'Financiers compete; lowest discount interest rate is automatically '
            'selected.',
        '4. Payment Settlement',
        'The winning financier pays the discounted invoice amount to the MSME '
            'bank account within T+1 days. The buyer repays the financier on '
            'due date.',
        'Immediate cash realization for MSME without collateral or recourse.',
      ]) {
        expect(hi(en), matches(_devanagari), reason: en);
      }
    });

    test('institution names and scheme lines are Hindi (HI-143-04)', () {
      for (final en in [
        'Tamil Nadu Industrial Investment Corporation',
        "Prime Minister's Employment Generation Programme (PMEGP), "
            'State-specific capital subsidies.',
        'SMILE (SIDBI Make in India Loan for Enterprises), ARISE, Speed Plus.',
        'Cluster',
      ]) {
        expect(hi(en), matches(_devanagari), reason: en);
      }
    });

    test('benefit-fact headings are translated (HI-143-01)', () {
      for (final en in ['Capital subsidy', 'Guarantee', 'Rental assistance']) {
        expect(
          CentralizedTranslator.instance.localizeTagFor('hi', en),
          matches(_devanagari),
          reason: en,
        );
        expect(
          CentralizedTranslator.instance.localizeTagFor('ta', en),
          isNot(en),
          reason: en,
        );
      }
    });
  });

  group('app strings', () {
    test(
      'EMI tenure suffix and valuation sectors are Hindi (COPY/HI-143)',
      () async {
        final l10n = await AppLocalizations.delegate.load(const Locale('hi'));
        expect(l10n.emiTenureSuffixMo, 'माह');
        for (final v in [
          l10n.valuationSectorSaasTech,
          l10n.valuationSectorEcommerce,
          l10n.valuationSectorFintech,
          l10n.valuationSectorAgritech,
        ]) {
          expect(v, matches(_devanagari));
        }
      },
    );
  });

  test('Recently Viewed items can be removed (FN-143-01)', () async {
    final library = LibraryController();
    library.addToRecentlyViewed('CEN2026-085');
    library.addToRecentlyViewed('TN2026-001');
    library.removeFromRecentlyViewed('CEN2026-085');
    expect(library.recentlyViewedIds, ['TN2026-001']);
  });

  testWidgets('Discover rows grow with the text scale (UI-143-01)', (
    tester,
  ) async {
    late double normal, large;
    final provider = AppProvider()..setLoggedInForTesting(true);
    for (final scale in [1.0, 1.6]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Builder(
            builder: (context) {
              final h = discoverRowHeight(context, provider);
              if (scale == 1.0) {
                normal = h;
              } else {
                large = h;
              }
              return const SizedBox();
            },
          ),
        ),
      );
    }
    expect(normal, 126);
    expect(large, greaterThan(normal + 40));
  });
}
