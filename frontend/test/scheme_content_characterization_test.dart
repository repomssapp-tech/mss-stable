import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

/// Pins what English, Hindi and Tamil scheme content looks like, so the content
/// path can stay language-generic without changing any of the three. Written
/// against the per-language code it replaced and passing on both.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  final translator = CentralizedTranslator.instance;

  String? stored(MssEntity e, String lang, String key) {
    final loc = e.raw['localization'];
    final block = loc is Map ? loc[lang] : null;
    final v = block is Map ? block[key] : null;
    return v is String && v.trim().isNotEmpty ? v : null;
  }

  setUpAll(() async {
    bundle = await MssCatalogBundle.load();
    await translator.ensureLoaded();
    LanguagePackManager.instance.resetForTesting();
    await LanguagePackManager.instance.loadPack('hi');
    await LanguagePackManager.instance.loadPack('ta');
  });

  const handBuilt = Scheme(
    id: 'char_1',
    schemeCode: 'CHAR_1',
    name: 'A Novel Scheme Name',
    shortName: 'Loan',
    fullSchemeName: 'A Novel Scheme Name In Full',
    ministry: 'A Novel Ministry',
    governmentLevel: 'State',
    category: 'Loan',
    targetBeneficiary: 'Some novel unmatched people',
    overview: 'A novel overview nobody translated.',
    objectives: 'A novel objective.',
    benefits: 'A novel benefit.',
    rawBenefitsDisplayText: 'A novel benefit display.',
    verificationStatus: 'Loan',
    eligibilityCriteria: ['Loan'],
    requiredDocuments: ['Loan'],
    applicationProcess: ['Loan'],
    documents: [SchemeDocument(name: 'Aadhaar Card Proof', mandatory: 'Yes')],
    requiredServices: [
      SchemeService(name: 'A novel service', category: 'Loan'),
    ],
    faqs: [
      {'question': 'Loan', 'answer': 'A novel answer.'},
    ],
  );

  group('English', () {
    test('every field is the catalog value, untouched', () {
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle);
        final shown = LocalizedScheme.fromScheme(s, 'en');
        expect(shown.name, s.name, reason: e.id);
        expect(shown.fullSchemeName, s.fullSchemeName, reason: e.id);
        expect(shown.overview, s.overview, reason: e.id);
        expect(shown.benefits, s.benefits, reason: e.id);
        expect(shown.category, s.category, reason: e.id);
        expect(shown.eligibilityCriteria, s.eligibilityCriteria, reason: e.id);
        expect(shown.applicationProcess, s.applicationProcess, reason: e.id);
        expect(shown.requiredDocuments, s.requiredDocuments, reason: e.id);
        expect(identical(shown.documents, s.documents), isTrue, reason: e.id);
      }
    });

    test('a hand-built scheme passes through', () {
      final shown = LocalizedScheme.fromScheme(handBuilt, 'en');
      expect(shown.name, handBuilt.name);
      expect(shown.fullSchemeName, handBuilt.fullSchemeName);
      expect(shown.documents.single.mandatory, 'Yes');
    });
  });

  group('Hindi', () {
    test('stored text wins, per field', () {
      var checked = 0;
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'hi');
        final shown = LocalizedScheme.fromScheme(s, 'hi');
        expect(shown.name, stored(e, 'hi', 'name') ?? s.name, reason: e.id);
        expect(shown.fullSchemeName, shown.name, reason: e.id);
        expect(
          shown.overview,
          stored(e, 'hi', 'summary') ??
              stored(e, 'hi', 'description') ??
              s.overview,
          reason: e.id,
        );
        expect(
          shown.benefits,
          stored(e, 'hi', 'benefitsText') ?? s.benefits,
          reason: e.id,
        );
        expect(shown.rawBenefitsDisplayText, shown.benefits, reason: e.id);
        checked++;
      }
      expect(checked, greaterThan(400));
    });

    test('numbered steps are renumbered with the Hindi word', () {
      var checked = 0;
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'hi');
        final steps = s.extras.storedSteps('hi');
        if (steps.isEmpty ||
            steps.length != s.applicationProcess.length ||
            !s.applicationProcess.every((l) => l.startsWith('Step '))) {
          continue;
        }
        final shown = LocalizedScheme.fromScheme(s, 'hi').applicationProcess;
        for (var i = 0; i < steps.length; i++) {
          expect(shown[i], 'चरण ${i + 1}: ${steps[i]}', reason: e.id);
        }
        checked++;
      }
      expect(checked, greaterThan(50));
    });

    test('text with no stored value stays English, never a mix', () {
      final shown = LocalizedScheme.fromScheme(handBuilt, 'hi');
      final loan = translator.localizeTagFor('hi', 'Loan');
      expect(loan, isNot('Loan'));
      expect(shown.name, handBuilt.name);
      expect(shown.fullSchemeName, handBuilt.name);
      expect(shown.shortName, handBuilt.shortName);
      expect(shown.ministry, handBuilt.ministry);
      expect(shown.overview, handBuilt.overview);
      expect(shown.objectives, handBuilt.objectives);
      expect(shown.benefits, handBuilt.benefits);
      expect(shown.rawBenefitsDisplayText, handBuilt.benefits);
      expect(shown.targetBeneficiary, handBuilt.targetBeneficiary);
      expect(shown.category, loan);
      expect(shown.verificationStatus, loan);
      // Lists with no stored translation are not run through the dictionary.
      expect(shown.eligibilityCriteria, ['Loan']);
      expect(shown.applicationProcess, ['Loan']);
      // Document names are.
      expect(shown.requiredDocuments, [translator.localizeFor('hi', 'Loan')]);
      expect(
        shown.faqs.single['question'],
        translator.localizeFor('hi', 'Loan'),
      );
      expect(shown.faqs.single['answer'], 'A novel answer.');
      // The canonical flag stays readable by `isMandatory`.
      expect(shown.documents.single.mandatory, 'Yes');
      expect(shown.documents.single.isMandatory, isTrue);
      expect(shown.requiredServices.single.name, 'A novel service');
      expect(shown.requiredServices.single.category, loan);
    });

    test('stored document names and record text are used', () {
      var names = 0;
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'hi');
        final storedNames = s.extras.storedDocumentNames('hi');
        if (storedNames.length != s.requiredDocuments.length ||
            storedNames.isEmpty) {
          continue;
        }
        final shown = LocalizedScheme.fromScheme(s, 'hi').requiredDocuments;
        for (var i = 0; i < shown.length; i++) {
          if (storedNames[i].isNotEmpty) {
            expect(shown[i], storedNames[i], reason: e.id);
            names++;
          }
        }
      }
      expect(names, greaterThan(100));
    });
  });

  group('Tamil', () {
    test('stored text wins, per field', () {
      var checked = 0;
      for (final e in bundle.schemes) {
        final name = stored(e, 'ta', 'name');
        if (name == null) continue;
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'ta');
        final shown = LocalizedScheme.fromScheme(s, 'ta');
        expect(shown.name, name.trim(), reason: e.id);
        expect(shown.fullSchemeName, name.trim(), reason: e.id);
        final summary = stored(e, 'ta', 'summary');
        if (summary != null) {
          expect(shown.overview, summary.trim(), reason: e.id);
        }
        checked++;
      }
      expect(checked, greaterThan(300));
    });

    test('a record with no Tamil keeps its English name, unrewritten', () {
      final mh = bundle.schemes.firstWhere(
        (s) => (s.raw['provenance'] as Map)['jurisdiction'] == 'maharashtra',
      );
      final s = MssSchemeAdapter.toScheme(mh, bundle, langCode: 'ta');
      expect(LocalizedScheme.fromScheme(s, 'ta').name, s.name);
      expect(s.getName('ta'), s.name);
    });

    test('numbered steps are renumbered with the Tamil word', () {
      var checked = 0;
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'ta');
        final steps = s.extras.storedSteps('ta');
        if (steps.isEmpty ||
            steps.length != s.applicationProcess.length ||
            !s.applicationProcess.every((l) => l.startsWith('Step '))) {
          continue;
        }
        final shown = LocalizedScheme.fromScheme(s, 'ta').applicationProcess;
        for (var i = 0; i < steps.length; i++) {
          expect(shown[i], 'படி ${i + 1}: ${steps[i]}', reason: e.id);
        }
        checked++;
      }
      expect(checked, greaterThan(50));
    });

    test('text with no stored value goes through the rewriting engine', () {
      final shown = LocalizedScheme.fromScheme(handBuilt, 'ta');
      expect(shown.name, translator.translate(handBuilt.name));
      expect(
        shown.fullSchemeName,
        translator.translate(handBuilt.fullSchemeName),
      );
      expect(shown.shortName, translator.translateTag('Loan'));
      expect(shown.ministry, translator.translate(handBuilt.ministry));
      expect(shown.overview, translator.translate(handBuilt.overview));
      expect(shown.objectives, translator.translate(handBuilt.objectives));
      expect(shown.benefits, translator.translate(handBuilt.benefits));
      expect(shown.rawBenefitsDisplayText, shown.benefits);
      expect(shown.category, translator.translateTag('Loan'));
      expect(shown.verificationStatus, translator.translate('Loan'));
      expect(shown.eligibilityCriteria, [translator.translate('Loan')]);
      expect(shown.applicationProcess, [translator.translate('Loan')]);
      expect(shown.requiredDocuments, [translator.translate('Loan')]);
      expect(
        shown.documents.single.name,
        translator.translate('Aadhaar Card Proof'),
      );
      // The canonical flag stays readable by `isMandatory` (it was translated,
      // which lost the Required badge on all 194 mandatory documents).
      expect(shown.documents.single.mandatory, 'Yes');
      expect(shown.documents.single.isMandatory, isTrue);
      expect(
        shown.requiredServices.single.name,
        translator.translate('A novel service'),
      );
    });

    test('stored Tamil document names are used, in line with the English', () {
      var names = 0;
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'ta');
        final stored = s.extras.storedDocumentNames('ta');
        if (stored.isEmpty || stored.length != s.requiredDocuments.length) {
          continue;
        }
        final shown = LocalizedScheme.fromScheme(s, 'ta').requiredDocuments;
        for (var i = 0; i < shown.length; i++) {
          if (stored[i].isNotEmpty) {
            expect(shown[i], stored[i], reason: e.id);
            names++;
          }
        }
      }
      expect(names, greaterThan(600));
    });

    test('a name stored on the document record reaches the required list', () {
      var names = 0;
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'ta');
        final shown = LocalizedScheme.fromScheme(s, 'ta').requiredDocuments;
        for (final d in s.documents) {
          final own = d.translated('name', 'ta');
          if (own.isEmpty || s.extras.storedDocumentNames('ta').isNotEmpty) {
            continue;
          }
          expect(shown, contains(own), reason: e.id);
          names++;
        }
      }
      expect(names, 49);
    });

    test('scheme text carries none of the corrected mistranslations', () {
      // Andaman read as Andhra, infomediary as medical, handholding as a door
      // handle and an amount, "application" as an app, garbled text.
      const wrong = [
        'ஆந்திரா மற்றும் நிகோபார்',
        'தகவல் மருத்துவ',
        'வசதி/கைப்பிடி',
        'கையடக்கத் தொகை',
        'வட்டி காட்டுங்கள்',
        'பயன்பாடு இல்லை (_',
      ];
      for (final e in bundle.schemes) {
        final block = (e.raw['localization'] as Map)['ta'];
        if (block is! Map) continue;
        for (final value in block.values) {
          for (final w in wrong) {
            expect(value.toString(), isNot(contains(w)), reason: e.id);
          }
        }
      }
    });

    test('document names carry none of the corrected mistranslations', () {
      // pitch as music, promotion as a job promotion, quotation as a citation,
      // promoter as advertiser, a command instead of a label, and a scheme
      // name translated (BIG as big).
      const wrong = [
        'சுருதி',
        'பதவி உயர்வு',
        'மேற்கோள்',
        'விளம்பரதாரர்',
        'ஏற்றுமதி செய்யுங்கள்',
        'ஆன்லைன் பெரிய',
      ];
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'ta');
        for (final name in s.extras.storedDocumentNames('ta')) {
          for (final w in wrong) {
            expect(name, isNot(contains(w)), reason: e.id);
          }
        }
      }
    });

    test('no document text is a word-by-word Tamil and English mix', () {
      final mixed = RegExp(r'[\u0B80-\u0BFF].*\b[a-z]{3,}\b.*\b[a-z]{3,}\b');
      final offenders = <String>[];
      for (final e in bundle.schemes) {
        final s = MssSchemeAdapter.toScheme(e, bundle, langCode: 'ta');
        final shown = LocalizedScheme.fromScheme(s, 'ta');
        final stored = s.extras.storedDocumentNames('ta').toSet();
        for (final d in shown.documents) {
          for (final t in [
            d.name,
            d.description,
            d.issuingAuthority,
            d.remarks,
          ]) {
            if (mixed.hasMatch(t) && !stored.contains(t)) {
              offenders.add('${e.id}: $t');
            }
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('a mixed beneficiary falls back to the whole original', () {
      const scheme = Scheme(
        id: 'char_2',
        schemeCode: 'CHAR_2',
        name: 'x',
        targetBeneficiary: 'Some novel unmatched people',
      );
      expect(
        LocalizedScheme.fromScheme(scheme, 'ta').targetBeneficiary,
        'Some novel unmatched people',
      );
    });
  });

  group('Scheme getters', () {
    test('read the language pack for Hindi and Tamil', () {
      for (final lang in const ['hi', 'ta']) {
        for (final e in bundle.schemes) {
          final name = stored(e, lang, 'name');
          if (name == null) continue;
          final s = MssSchemeAdapter.toScheme(e, bundle, langCode: lang);
          expect(s.getName(lang), name, reason: e.id);
          final benefits = stored(e, lang, 'benefitsText');
          if (benefits != null) {
            expect(s.getBenefits(lang), benefits, reason: e.id);
          }
        }
      }
    });

    test('fall back to the English value', () {
      expect(handBuilt.getName('hi'), handBuilt.name);
      expect(handBuilt.getOverview('ta'), handBuilt.overview);
      expect(handBuilt.getBenefits('ta'), handBuilt.benefits);
    });
  });

  group('translator', () {
    test('unknown languages return the input unchanged', () {
      expect(translator.localizeFor('xx', 'Loan'), 'Loan');
      expect(translator.localizeTagFor('xx', 'Loan'), 'Loan');
      expect(translator.localizeFor('xx', null), '');
    });

    test('Hindi is exact lookup, Tamil rewrites', () {
      const phrase = 'Provides capital subsidy to novel people';
      expect(translator.localizeFor('hi', phrase), phrase);
      expect(translator.localizeFor('ta', phrase), isNot(phrase));
    });
  });
}
