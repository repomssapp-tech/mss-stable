import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Category Navigation Architecture & Exact Data Consistency Tests', () {
    final repo = SchemeRepository.instance;
    final translator = CentralizedTranslator.instance;

    setUpAll(() async {
      await repo.getAllSchemes();
    });

    test(
      '1. SHG & Artisan returns clean exact dataset without BioCARE or WING',
      () async {
        final schemes = await repo.getSchemesByCategory('SHG & Artisan');
        expect(schemes.isNotEmpty, isTrue);

        final schemeNames = schemes.map((s) => s.name.toLowerCase()).toList();

        // Verify unrelated schemes like BioCARE and WING are NOT present
        expect(schemeNames.any((n) => n.contains('biocare')), isFalse);
        expect(schemeNames.any((n) => n.contains('wing')), isFalse);

        // Verify every returned scheme belongs to SHG / Artisan / Vishwakarma / Weaver / Craftsman
        for (final s in schemes) {
          final text =
              '${s.name} ${s.schemeType} ${s.category} ${s.targetBeneficiary} ${s.searchKeywords} ${s.overview}'
                  .toLowerCase();
          final matchesCategory =
              text.contains('artisan') ||
              text.contains('shg') ||
              text.contains('vishwakarma') ||
              text.contains('weaver') ||
              text.contains('craftsman') ||
              text.contains('self help');
          expect(
            matchesCategory,
            isTrue,
            reason:
                'Scheme ${s.name} does not belong to SHG & Artisan category',
          );
        }
      },
    );

    test(
      '2. MSME Category returns schemes matching MSME criteria',
      () async {
        final schemes = await repo.getSchemesByCategory('MSME');
        expect(schemes.length, greaterThanOrEqualTo(100));

        for (final s in schemes) {
          final text =
              '${s.name} ${s.schemeType} ${s.category} ${s.sector} ${s.targetBeneficiary} ${s.searchKeywords} ${s.overview}'
                  .toLowerCase();
          final matchesMSME =
              text.contains('msme') ||
              text.contains('micro') ||
              text.contains('udyam') ||
              text.contains('business');
          expect(
            matchesMSME,
            isTrue,
            reason: 'Scheme ${s.name} does not belong to MSME category',
          );
        }
      },
    );

    test('3. Women Entrepreneurs Category returns schemes matching Women criteria', () async {
      final schemes = await repo.getSchemesByCategory('Women Entrepreneurs');
      expect(schemes.length, greaterThanOrEqualTo(40));

      for (final s in schemes) {
        final text =
            '${s.name} ${s.schemeType} ${s.category} ${s.targetBeneficiary} ${s.searchKeywords}'
                .toLowerCase();
        final matchesWomen =
            text.contains('women') ||
            text.contains('female') ||
            text.contains('mahila') ||
            text.contains('stree');
        expect(
          matchesWomen,
          isTrue,
          reason:
              'Scheme ${s.name} does not belong to Women Entrepreneurs category',
        );
      }
    });

    test('4. Business Loans & Credit Category returns schemes matching Loan criteria', () async {
      final schemes = await repo.getSchemesByCategory(
        'Business Loans & Credit',
      );
      expect(schemes.length, greaterThanOrEqualTo(31));

      for (final s in schemes) {
        final text =
            '${s.name} ${s.schemeType} ${s.category} ${s.searchKeywords} ${s.overview}'
                .toLowerCase();
        final matchesLoan =
            text.contains('loan') ||
            text.contains('credit') ||
            text.contains('mudra') ||
            text.contains('cgtmse') ||
            text.contains('financing') ||
            text.contains('working capital');
        expect(
          matchesLoan,
          isTrue,
          reason:
              'Scheme ${s.name} does not belong to Business Loans & Credit category',
        );
      }
    });

    test('5. Startup Category returns schemes', () async {
      final schemes = await repo.getSchemesByCategory('Startup');
      expect(schemes.length, greaterThanOrEqualTo(15));
    });

    test('6. Technology Category returns schemes', () async {
      final schemes = await repo.getSchemesByCategory('Technology');
      expect(schemes.length, greaterThanOrEqualTo(15));
    });

    test(
      '7. Export & Trade Promotion Category returns schemes',
      () async {
        final schemes = await repo.getSchemesByCategory(
          'Export & Trade Promotion',
        );
        expect(schemes.length, greaterThanOrEqualTo(19));
      },
    );

    test('8. Manufacturing Category returns schemes', () async {
      final schemes = await repo.getSchemesByCategory('Manufacturing');
      expect(schemes.length, greaterThanOrEqualTo(12));
    });

    test(
      '9. All Category Titles translate cleanly to Tamil via CentralizedTranslator',
      () {
        expect(translator.translateTag('MSME'), equals('MSME'));
        expect(translator.translateTag('Startup'), equals('ஸ்டார்ட்அப்'));
        expect(
          translator.translateTag('Women Entrepreneurs'),
          equals('பெண் தொழில்முனைவோர்'),
        );
        expect(
          translator.translateTag('Business Loans & Credit'),
          equals('தொழில் கடன்கள் & கடன் உதவி'),
        );
        expect(
          translator.translateTag('Export & Trade Promotion'),
          equals('ஏற்றுமதி & வர்த்தக ஊக்குவிப்பு'),
        );
        expect(
          translator.translateTag('SHG & Artisan'),
          equals('சுய உதவிக்குழு & கைவினைஞர்'),
        );
        expect(translator.translateTag('Technology'), equals('தொழில்நுட்பம்'));
        expect(
          translator.translateTag('Manufacturing'),
          equals('உற்பத்தித் துறை'),
        );
      },
    );
  });
}
