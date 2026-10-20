import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/mss_catalog_bundle.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';

/// The same 20 search intents asked in English, Hindi and Tamil must reach
/// on-topic schemes in the top 5. Search is lexical (taxonomy + query
/// expansion, no ML), so this guards the Hindi/Tamil vocabulary in
/// backend/catalog/search_taxonomy.json against regressing below English.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MssCatalogBundle bundle;

  setUpAll(() async {
    bundle = await MssCatalogBundle.load(overrideChecksumForTest: true);
  });

  // (English, Hindi, Tamil, regex on the scheme's English name / overview)
  const intents = <(String, String, String, String)>[
    ('artisan', 'कारीगर', 'கைவினைஞர்', r'Vishwakarma|Artisan|Handicraft|Coir'),
    ('loan', 'ऋण', 'கடன்', r'Loan|Credit|Mudra|CGTMSE|PMEGP|Fund'),
    ('subsidy', 'सब्सिडी', 'மானியம்', r'Subsid|Capital|PMEGP|Interest'),
    ('training', 'प्रशिक्षण', 'பயிற்சி', r'Training|Skill|ESDP|Capacity'),
    ('skill development', 'कौशल विकास', 'திறன் மேம்பாடு', r'Skill|Training'),
    (
      'startup',
      'स्टार्टअप',
      'ஸ்டார்ட்அப்',
      r'Startup|Start-up|Innovation|AIM|BIRAC|Seed',
    ),
    (
      'credit guarantee',
      'क्रेडिट गारंटी',
      'கடன் உத்தரவாதம்',
      r'Credit Guarantee|Guarantee|CGTMSE',
    ),
    (
      'women entrepreneur',
      'महिला उद्यमी',
      'பெண் தொழில்முனைவோர்',
      r'Women|Mahila|Udyami',
    ),
    ('micro enterprise', 'सूक्ष्म उद्यम', 'குறுந்தொழில்', r'Micro|MSME|PMEGP'),
    (
      'cluster development',
      'क्लस्टर विकास',
      'கிளஸ்டர் மேம்பாடு',
      r'Cluster|MSE-CDP|SFURTI',
    ),
    (
      'food processing',
      'खाद्य प्रसंस्करण',
      'உணவு பதப்படுத்துதல்',
      r'Food|PMFME|Processing|Agro',
    ),
    ('solar energy', 'सौर ऊर्जा', 'சூரிய சக்தி', r'Solar|Renewable|Energy'),
    ('khadi', 'खादी', 'காதி', r'Khadi|KVIC|Village'),
    (
      'self employment',
      'स्वरोजगार',
      'சுய வேலைவாய்ப்பு',
      r'Self|Employment|PMEGP',
    ),
    (
      'scheduled caste',
      'अनुसूचित जाति',
      'பட்டியல் சாதி',
      r'Scheduled|Stand-Up|Ambedkar|SC/ST|SC-ST',
    ),
    (
      'loan without collateral for micro enterprises',
      'सूक्ष्म उद्यमों के लिए बिना गारंटी ऋण',
      'குறுந்தொழில்களுக்கு பிணையற்ற கடன்',
      r'CGTMSE|Guarantee|Mudra|Collateral|Credit',
    ),
    (
      'support for women to start a business',
      'महिलाओं के लिए व्यवसाय शुरू करने में सहायता',
      'பெண்கள் தொழில் தொடங்க உதவி',
      r'Women|Mahila|Mudra|Stand-Up|WEP|Udyam',
    ),
    (
      'help to export my products',
      'अपने उत्पाद निर्यात करने में मदद',
      'என் பொருட்களை ஏற்றுமதி செய்ய உதவி',
      r'Export',
    ),
    (
      'weaver handloom support',
      'बुनकर हथकरघा सहायता',
      'நெசவாளர் கைத்தறி உதவி',
      r'Handloom|Weaver|Textile|Khadi|Handicraft',
    ),
    (
      'startup money for a new business',
      'नया व्यवसाय शुरू करने के लिए पैसे',
      'புதிய தொழில் தொடங்க பணம்',
      r'Loan|Credit|Mudra|PMEGP|Startup|Seed|Subsid|Employment',
    ),
  ];

  Future<int> hitsFor(int language) async {
    var hits = 0;
    final misses = <String>[];
    for (final intent in intents) {
      final query = switch (language) {
        0 => intent.$1,
        1 => intent.$2,
        _ => intent.$3,
      };
      final expected = RegExp(intent.$4, caseSensitive: false);
      final matches = await HybridSchemeSearch.rank(query, bundle, limit: 10);
      final hit = matches.take(5).any((m) {
        final s = m.scheme;
        return expected.hasMatch('${s.name} ${s.shortName} ${s.overview}');
      });
      if (hit) {
        hits++;
      } else {
        misses.add(query);
      }
    }
    // ignore: avoid_print
    print(
      'lang=${const ['en', 'hi', 'ta'][language]} hit@5=$hits/'
      '${intents.length} misses=$misses',
    );
    return hits;
  }

  test(
    'English, Hindi and Tamil reach on-topic schemes in the top 5',
    () async {
      final en = await hitsFor(0);
      final hi = await hitsFor(1);
      final ta = await hitsFor(2);

      expect(en, greaterThanOrEqualTo(minEnglish));
      expect(hi, greaterThanOrEqualTo(minHindi));
      expect(ta, greaterThanOrEqualTo(minTamil));
    },
  );
}

// Measured with the Hindi/Tamil vocabulary and Hindi/Tamil text index in
// place (before either: en 18, hi 19, ta 14), then with the English summary /
// description text indexed (en 19; ta 20 -> 19: one Tamil query's English
// expansions now also match descriptions, a trade accepted for the +15 point
// gain on the 900-query set). Search is deterministic, so these are exact
// regression floors.
const minEnglish = 19;
const minHindi = 20;
const minTamil = 19;
