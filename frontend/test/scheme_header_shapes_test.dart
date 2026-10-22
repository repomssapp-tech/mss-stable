import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mss_entity.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/catalog/mss_scheme_adapter.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';

/// Issue 152, task 1: a localized map reaching code that cast it to
/// `String?` made the whole catalog conversion throw (`_Map<String, dynamic>
/// is not a subtype of String?`). The header resolver must resolve scalar and
/// localized-map values alike, for every record, in every language.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const langs = ['en', 'hi', 'ta'];
  late MssCatalogBundle bundle;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load();
  });

  Map<String, dynamic> deepCopy(Map<String, dynamic> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  /// A normalized record shaped like the supplied preview: no legacy
  /// `source`, localized objects wherever plain text used to be, and no
  /// overview so the eligibility-summary fallback runs.
  MssEntity previewShaped(MssEntity base) {
    final raw = deepCopy(base.raw)..remove('source');
    final content = (raw['content'] as Map).cast<String, dynamic>();
    final classification = (content['classification'] as Map? ?? {})
        .cast<String, dynamic>();
    final gov = (classification['government'] as Map? ?? {})
        .cast<String, dynamic>();
    Map<String, String> loc(String en, String hi, String ta) => {
      'en': en,
      'hi': hi,
      'ta': ta,
    };
    gov['levelText'] = loc('Central', 'केंद्रीय', 'மத்திய');
    gov['statesText'] = loc('All India', 'पूरे भारत में', 'இந்தியா முழுவதும்');
    gov['districtsText'] = loc(
      'All districts',
      'सभी जिले',
      'அனைத்து மாவட்டங்கள்',
    );
    classification['government'] = gov;
    classification['sectorsText'] = loc(
      'Manufacturing',
      'विनिर्माण',
      'உற்பத்தி',
    );
    classification['schemeTypeText'] = loc('Subsidy', 'सब्सिडी', 'மானியம்');
    content['classification'] = classification;
    content.remove('overview');
    content.remove('summary');
    content.remove('description');
    content['eligibilityText'] = {
      'summary': loc(
        'Open to registered MSMEs.',
        'पंजीकृत एमएसएमई के लिए खुला।',
        'பதிவு செய்யப்பட்ட எம்எஸ்எம்இ-களுக்கு.',
      ),
    };
    raw['content'] = content;
    return MssEntity.fromJson(raw);
  }

  group('preview-shaped record (no source, localized maps)', () {
    test('converts in en, hi and ta without throwing', () {
      final entity = previewShaped(bundle.schemes.first);
      for (final lang in langs) {
        expect(
          () => MssSchemeAdapter.toScheme(entity, bundle, langCode: lang),
          returnsNormally,
          reason: lang,
        );
      }
    });

    test('resolves localized scalars and the eligibility fallback', () {
      final entity = previewShaped(bundle.schemes.first);
      final en = MssSchemeAdapter.toScheme(entity, bundle, langCode: 'en');
      expect(en.governmentLevel, 'Central');
      expect(en.sector, 'Manufacturing');
      expect(en.schemeType, 'Subsidy');
      expect(en.overview, 'Open to registered MSMEs.');
      final hi = MssSchemeAdapter.toScheme(entity, bundle, langCode: 'hi');
      expect(hi.governmentLevel, 'केंद्रीय');
      expect(hi.sector, 'विनिर्माण');
    });

    test('a plain-string eligibilityText still works', () {
      final raw = deepCopy(previewShaped(bundle.schemes.first).raw);
      final content = (raw['content'] as Map).cast<String, dynamic>();
      content['eligibilityText'] = 'Plain text eligibility.';
      raw['content'] = content;
      final scheme = MssSchemeAdapter.toScheme(
        MssEntity.fromJson(raw),
        bundle,
        langCode: 'en',
      );
      expect(scheme.overview, 'Plain text eligibility.');
    });

    test('missing fields stay absent instead of throwing', () {
      final raw = deepCopy(previewShaped(bundle.schemes.first).raw);
      final content = (raw['content'] as Map).cast<String, dynamic>()
        ..remove('classification')
        ..remove('eligibilityText');
      raw['content'] = content;
      final scheme = MssSchemeAdapter.toScheme(
        MssEntity.fromJson(raw),
        bundle,
        langCode: 'en',
      );
      expect(scheme.sector, isEmpty);
      expect(scheme.state, isEmpty);
    });
  });

  group('every bundled scheme', () {
    test('converts in en, hi and ta, as shipped and without source', () {
      for (final entity in bundle.schemes) {
        final stripped = MssEntity.fromJson(
          deepCopy(entity.raw)..remove('source'),
        );
        for (final lang in langs) {
          for (final e in [entity, stripped, previewShaped(entity)]) {
            try {
              MssSchemeAdapter.toScheme(e, bundle, langCode: lang);
            } catch (err, st) {
              fail('${entity.id} ($lang) failed: $err\n$st');
            }
          }
        }
      }
    });

    test(
      'the repository returns all schemes with no conversion failures',
      () async {
        final repo = SchemeRepository.instance;
        for (final lang in langs) {
          repo.clearCache();
          final all = await repo.getAllSchemes(langCode: lang);
          expect(all.length, bundle.schemes.length, reason: lang);
          expect(repo.conversionFailures, isEmpty, reason: lang);
        }
      },
    );
  });
}
