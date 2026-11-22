import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';

/// Rule: if a scheme, institution or authority already has a name in Tamil,
/// Hindi (or Marathi) in the catalog, that stored name is shown as is -- it is
/// never replaced by a runtime translation, and nothing is invented where no
/// stored name exists.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;
  final translator = CentralizedTranslator.instance;

  String? stored(MssEntity e, String lang, String key) {
    final loc = e.raw['localization'];
    final block = loc is Map ? loc[lang] : null;
    final v = block is Map ? block[key] : null;
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  setUpAll(() async {
    bundle = await MssCatalogBundle.load();
    await translator.ensureLoaded();
    await LanguagePackManager.instance.loadPack('hi');
    await LanguagePackManager.instance.loadPack('ta');
  });

  for (final lang in ['hi', 'ta']) {
    group('stored $lang names win over translation', () {
      test('scheme name and short name', () {
        var checked = 0;
        var translationWouldDiffer = 0;
        for (final e in bundle.schemes) {
          final name = stored(e, lang, 'name');
          final shortName = stored(e, lang, 'shortName');
          if (name == null && shortName == null) continue;
          final scheme = MssSchemeAdapter.toScheme(e, bundle, langCode: lang);
          final shown = LocalizedScheme.fromScheme(scheme, lang);
          if (name != null) {
            expect(shown.name, name, reason: '${e.id} name');
            if (translator.translate(scheme.name) != name) {
              translationWouldDiffer++;
            }
            checked++;
          }
          if (shortName != null) {
            expect(shown.shortName, shortName, reason: '${e.id} shortName');
          }
        }
        expect(checked, greaterThan(200));
        expect(
          translationWouldDiffer,
          greaterThan(0),
          reason: 'the rule must be exercised, not vacuous',
        );
      });

      test('ministry, department and agency use the stored name', () {
        var withStored = 0;
        for (final e in bundle.schemes) {
          final scheme = MssSchemeAdapter.toScheme(e, bundle, langCode: lang);
          final shown = LocalizedScheme.fromScheme(scheme, lang);
          final byField = {
            'ministry': shown.ministry,
            'department': shown.department,
            'implementingAgency': shown.implementingAgency,
            'sponsoringBody': shown.sponsoringBody,
            'issuingBody': shown.issuingBody,
          };
          byField.forEach((field, text) {
            final native = scheme.nativeName(field, lang);
            if (native != null) {
              expect(text, native, reason: '${e.id} $field');
              withStored++;
            }
          });
        }
        expect(withStored, greaterThan(300));
      });

      test('department uses the record\'s own stored authority text', () {
        var checked = 0;
        for (final e in bundle.schemes) {
          final own = stored(e, lang, 'authority');
          if (own == null) continue;
          final scheme = MssSchemeAdapter.toScheme(e, bundle, langCode: lang);
          if (scheme.nativeName('department', lang) != null) {
            expect(scheme.nativeName('department', lang), own, reason: e.id);
            checked++;
          }
        }
        expect(checked, greaterThan(100));
      });

      test('authority and institution names come from the entity', () {
        var checked = 0;
        for (final type in ['authority', 'institution']) {
          for (final e in bundle.getCatalog(type)) {
            final name = stored(e, lang, 'name');
            if (name == null) continue;
            expect(e.getLocalizedName(lang), name, reason: e.id);
            checked++;
          }
        }
        expect(checked, greaterThan(0));
      });
    });
  }

  test('nothing is invented where the catalog has no stored name', () {
    // Maharashtra records carry no Tamil at all.
    final mh = bundle.schemes.firstWhere(
      (s) => (s.raw['provenance'] as Map)['jurisdiction'] == 'maharashtra',
    );
    final scheme = MssSchemeAdapter.toScheme(mh, bundle, langCode: 'ta');
    expect(scheme.nativeName('department', 'ta'), isNull);
    expect(scheme.nativeName('shortName', 'ta'), isNull);
  });

  test('Marathi names are stored and offered for Maharashtra only', () {
    final mh = bundle.schemes.firstWhere(
      (s) =>
          (s.raw['provenance'] as Map)['jurisdiction'] == 'maharashtra' &&
          stored(s, 'mr', 'authority') != null,
    );
    final scheme = MssSchemeAdapter.toScheme(mh, bundle);
    expect(
      scheme.nativeName('department', 'mr'),
      stored(mh, 'mr', 'authority'),
    );
    expect(bundle.isLanguageActive('mr'), isTrue);
    expect(bundle.offeredLanguagesFor('maharashtra'), contains('mr'));
  });

  for (final lang in ['hi', 'ta']) {
    test('stored $lang eligibility and steps replace the English lists', () {
      var elig = 0;
      var steps = 0;
      for (final e in bundle.schemes) {
        final scheme = MssSchemeAdapter.toScheme(e, bundle, langCode: lang);
        final shown = LocalizedScheme.fromScheme(scheme, lang);
        final storedElig = scheme.extras.storedEligibility(lang);
        if (storedElig.isNotEmpty) {
          expect(shown.eligibilityCriteria, storedElig, reason: e.id);
          elig++;
        }
        final storedSteps = scheme.extras.storedSteps(lang);
        if (storedSteps.isNotEmpty &&
            storedSteps.length == scheme.applicationProcess.length) {
          expect(shown.applicationProcess.length, storedSteps.length);
          for (var i = 0; i < storedSteps.length; i++) {
            expect(shown.applicationProcess[i], contains(storedSteps[i]));
          }
          steps++;
        }
      }
      expect(elig, greaterThan(100));
      expect(steps, greaterThan(50));
    });
  }

  test('every scheme states its available, offered and default languages', () {
    for (final e in bundle.schemes) {
      expect(e.availableLanguages, contains('en'), reason: e.id);
      expect(e.availableLanguages, contains(e.defaultLanguage), reason: e.id);
      expect(
        e.offeredLanguages.every(e.availableLanguages.contains),
        isTrue,
        reason: e.id,
      );
      expect(
        e.offeredLanguages.contains('mr'),
        (e.raw['provenance'] as Map)['jurisdiction'] == 'maharashtra',
        reason: e.id,
      );
    }
    final tn = bundle.schemes.firstWhere((s) => s.id.startsWith('TN2026'));
    expect(tn.availableLanguages, ['en', 'hi', 'mr', 'ta']);
  });
}
