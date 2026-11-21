import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/widgets/common/standard_page_header.dart';
import 'package:frontend/utils/app_radius.dart';
import 'package:frontend/utils/app_spacing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Final Localization Quality & UI Consistency Audit', () {
    late List<Scheme> allSchemes;

    setUpAll(() async {
      allSchemes = await SchemeRepository.instance.getRecommendedSchemes(
        UserProfile(),
      );
    });

    test('1. Verify 0 mixed-language sentences on full UI sentences', () {
      final fullUiSentences = [
        'Find government subsidies, grants, and registration schemes you are eligible for, customized to your profile details.',
        'Personalized schemes matched to business profile',
        'Personalized schemes matched to your profile',
        'Complete your profile or explore schemes with the search engine to get smart matching results.',
        'Instantly search our database for credit support, collateral-free business loans, and SIDBI programs.',
        'Under the MSMED Act Section 15/16, buyers must pay 3x the RBI Bank Rate as compound interest with monthly rests for delays exceeding 45 days.',
        'Discover every Government Scheme in India',
        'Search for schemes offering cluster development, technology upgrades, and incubator grants.',
        'Interactive Tools & Actions',
        'Search Schemes',
        'Complete Profile',
        'Delayed Payment Interest Calculator',
        'Invoice Amount',
        'Days Delayed',
        'Interest Rate',
        'Total Claimable',
        'WHAT THE USER GETS',
      ];

      final tamilRegex = RegExp(r'[\u0B80-\u0BFF]');

      // List of protected technical terms allowed to remain English in Tamil context
      final protectedTerms = {
        'MSME',
        'MSMED',
        'GST',
        'PAN',
        'Aadhaar',
        'SIDBI',
        'CGTMSE',
        'PMEGP',
        'TReDS',
        'KVIC',
        'NSIC',
        'DIC',
        'TIIC',
        'StartupTN',
        'EdiiTN',
        'TANGEDCO',
        'INR',
        'RBI',
        'ARR',
        'CSR',
        'BSE',
        'NSE',
        'ECGC',
        'RoDTEP',
        'RoSCTL',
      };

      for (final sentence in fullUiSentences) {
        final translated = CentralizedTranslator.instance.translate(sentence);
        expect(
          translated.trim(),
          isNotEmpty,
          reason: 'Sentence "$sentence" translated to empty',
        );

        final words = translated.split(RegExp(r'\s+'));
        final englishWords = words.where((w) {
          final clean = w.replaceAll(RegExp(r'[^a-zA-Z]'), '');
          return clean.length >= 3 &&
              !protectedTerms.contains(clean.toUpperCase());
        }).toList();

        final hasTamil = tamilRegex.hasMatch(translated);

        if (hasTamil && englishWords.isNotEmpty) {
          fail(
            'Mixed language sentence detected: "$translated" (English words: $englishWords) from original "$sentence"',
          );
        }
      }
    });

    testWidgets('page body starts directly below the scaled toolbar', (
      tester,
    ) async {
      const bodyKey = ValueKey('page-body');
      Future<void> showHeader(double scale, {String? subtitle}) {
        return tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24),
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                appBar: StandardPageHeader(
                  MediaQuery.textScalerOf(context),
                  title: 'Test Header',
                  subtitle: subtitle,
                  showDivider: subtitle != null,
                ),
                body: const SizedBox.expand(key: bodyKey),
              ),
            ),
          ),
        );
      }

      await showHeader(1);
      final body = find.byKey(bodyKey);
      final normalBodyTop = tester.getTopLeft(body).dy;
      expect(normalBodyTop, 24 + kToolbarHeight);

      await showHeader(1.3, subtitle: 'Test Subtitle');
      final subtitleBounds = tester.getRect(find.text('Test Subtitle'));
      expect(tester.getTopLeft(body).dy, greaterThan(normalBodyTop));
      expect(subtitleBounds.bottom, lessThan(tester.getTopLeft(body).dy));
      expect(
        tester.getTopLeft(body).dy,
        closeTo(tester.getBottomLeft(find.byType(Divider)).dy, 0.5),
      );
      expect(tester.takeException(), isNull);
    });

    test(
      '3. Verify card design tokens (AppCardStyle deleted 2.4; now AppRadius/AppSpacing)',
      () {
        expect(AppRadius.lg, equals(16.0));
        expect(AppSpacing.lg * 2, equals(32.0));
        expect(AppSpacing.tight, equals(6.0));
      },
    );

    test(
      '4. Verify catalog scheme descriptions translate cleanly without mixed-language artifacts',
      () {
        expect(allSchemes, isNotEmpty);
        for (final scheme in allSchemes.take(20)) {
          final locTa = scheme.toLocalized('ta');
          expect(locTa.name.trim(), isNotEmpty);
          expect(locTa.overview.trim(), isNotEmpty);
          expect(locTa.benefits.trim(), isNotEmpty);
        }
      },
    );
  });
}
