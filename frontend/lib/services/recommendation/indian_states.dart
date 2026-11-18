/// English <-> Hindi <-> Tamil <-> Marathi names of India's states and union territories,
/// used to recognise a profile's free-text / geocoded state in any language.
///
/// The profile's state is typed by the user or filled by the device geocoder,
/// so it can arrive as "Tamil Nadu", "तमिलनाडु" or "தமிழ்நாடு". The catalog
/// scopes schemes by the English name.
class IndianStates {
  const IndianStates._();

  /// English name -> other accepted spellings (Hindi, Tamil, common English
  /// variants). The English name itself is always accepted.
  static const Map<String, List<String>> _aliases = {
    'Andhra Pradesh': ['आंध्र प्रदेश', 'ஆந்திரப் பிரதேசம்', 'ஆந்திரா'],
    'Arunachal Pradesh': ['अरुणाचल प्रदेश', 'அருணாசலப் பிரதேசம்'],
    'Assam': ['असम', 'அசாம்'],
    'Bihar': ['बिहार', 'பீகார்'],
    'Chhattisgarh': ['छत्तीसगढ़', 'छत्तीसगढ', 'சத்தீஸ்கர்'],
    'Goa': ['गोवा', 'கோவா'],
    'Gujarat': ['गुजरात', 'குஜராத்'],
    'Haryana': ['हरियाणा', 'ஹரியானா'],
    'Himachal Pradesh': [
      'हिमाचल प्रदेश',
      'இமாசலப் பிரதேசம்',
      'இமாச்சலப் பிரதேசம்',
    ],
    'Jharkhand': ['झारखंड', 'ஜார்க்கண்ட்'],
    'Karnataka': ['कर्नाटक', 'கர்நாடகா', 'கர்நாடகம்'],
    'Kerala': ['केरल', 'கேரளா', 'கேரளம்'],
    'Madhya Pradesh': ['मध्य प्रदेश', 'மத்தியப் பிரதேசம்', 'மத்திய பிரதேசம்'],
    'Maharashtra': ['महाराष्ट्र', 'மகாராஷ்டிரா', 'மகாராஷ்டிரம்'],
    'Manipur': ['मणिपुर', 'மணிப்பூர்'],
    'Meghalaya': ['मेघालय', 'மேகாலயா'],
    'Mizoram': ['मिजोरम', 'மிசோரம்'],
    'Nagaland': ['नागालैंड', 'நாகாலாந்து'],
    'Odisha': ['ओडिशा', 'उड़ीसा', 'ஒடிசா', 'orissa'],
    'Punjab': ['पंजाब', 'பஞ்சாப்'],
    'Rajasthan': ['राजस्थान', 'ராஜஸ்தான்'],
    'Sikkim': ['सिक्किम', 'சிக்கிம்'],
    'Tamil Nadu': ['तमिलनाडु', 'தமிழ்நாடு', 'தமிழ் நாடு', 'tamilnadu', 'tn'],
    'Telangana': ['तेलंगाना', 'தெலங்கானா', 'தெலுங்கானா'],
    'Tripura': ['त्रिपुरा', 'திரிபுரா'],
    'Uttar Pradesh': ['उत्तर प्रदेश', 'உத்தரப் பிரதேசம்', 'உத்தர பிரதேசம்'],
    'Uttarakhand': ['उत्तराखंड', 'உத்தராகண்டம்', 'உத்தரகாண்ட்', 'uttaranchal'],
    'West Bengal': ['पश्चिम बंगाल', 'மேற்கு வங்காளம்', 'மேற்கு வங்கம்'],
    'Delhi': ['दिल्ली', 'டெல்லி', 'nct of delhi', 'new delhi', 'नई दिल्ली'],
    'Jammu and Kashmir': ['जम्मू और कश्मीर', 'ஜம்மு காஷ்மீர்', 'jammu kashmir'],
    'Ladakh': ['लद्दाख', 'லடாக்'],
    'Puducherry': ['पुदुचेरी', 'புதுச்சேரி', 'pondicherry'],
    'Chandigarh': ['चंडीगढ़', 'चंडीगढ', 'சண்டிகர்'],
    'Andaman and Nicobar Islands': [
      'अंडमान और निकोबार द्वीप समूह',
      'அந்தமான் நிக்கோபார் தீவுகள்',
      'andaman nicobar',
    ],
    'Lakshadweep': ['लक्षद्वीप', 'லட்சத்தீவு'],
    'Dadra and Nagar Haveli and Daman and Diu': [
      'दादरा और नगर हवेली और दमन और दीव',
      'தாதர் நாகர் ஹவேலி மற்றும் டாமன் டையூ',
      'daman and diu',
      'dadra and nagar haveli',
    ],
  };

  /// Marathi spellings that differ from the Hindi one in [_aliases]; every other
  /// state is written the same way in both.
  static const Map<String, String> _marathi = {
    'Assam': 'आसाम',
    'Chhattisgarh': 'छत्तीसगड',
    'Kerala': 'केरळ',
    'Manipur': 'मणिपूर',
    'Mizoram': 'मिझोराम',
    'Nagaland': 'नागालँड',
    'Tamil Nadu': 'तमिळनाडू',
    'Telangana': 'तेलंगणा',
    'Jammu and Kashmir': 'जम्मू आणि काश्मीर',
    'Ladakh': 'लडाख',
    'Puducherry': 'पुडुचेरी',
    'Chandigarh': 'चंडीगड',
    'Andaman and Nicobar Islands': 'अंदमान आणि निकोबार बेटे',
    'Dadra and Nagar Haveli and Daman and Diu':
        'दादरा आणि नगर हवेली आणि दमण आणि दीव',
  };

  /// English name -> ISO 3166-2:IN code, the form the catalog stores in
  /// `classification.government.states`.
  static const Map<String, String> _isoCodes = {
    'Andhra Pradesh': 'IN-AP',
    'Arunachal Pradesh': 'IN-AR',
    'Assam': 'IN-AS',
    'Bihar': 'IN-BR',
    'Chhattisgarh': 'IN-CT',
    'Goa': 'IN-GA',
    'Gujarat': 'IN-GJ',
    'Haryana': 'IN-HR',
    'Himachal Pradesh': 'IN-HP',
    'Jharkhand': 'IN-JH',
    'Karnataka': 'IN-KA',
    'Kerala': 'IN-KL',
    'Madhya Pradesh': 'IN-MP',
    'Maharashtra': 'IN-MH',
    'Manipur': 'IN-MN',
    'Meghalaya': 'IN-ML',
    'Mizoram': 'IN-MZ',
    'Nagaland': 'IN-NL',
    'Odisha': 'IN-OD',
    'Punjab': 'IN-PB',
    'Rajasthan': 'IN-RJ',
    'Sikkim': 'IN-SK',
    'Tamil Nadu': 'IN-TN',
    'Telangana': 'IN-TG',
    'Tripura': 'IN-TR',
    'Uttar Pradesh': 'IN-UP',
    'Uttarakhand': 'IN-UK',
    'West Bengal': 'IN-WB',
    'Delhi': 'IN-DL',
    'Jammu and Kashmir': 'IN-JK',
    'Ladakh': 'IN-LA',
    'Puducherry': 'IN-PY',
    'Chandigarh': 'IN-CH',
    'Andaman and Nicobar Islands': 'IN-AN',
    'Lakshadweep': 'IN-LD',
    'Dadra and Nagar Haveli and Daman and Diu': 'IN-DH',
  };

  /// Superseded ISO codes still seen in data (`OR` became `OD`, ...).
  static const Map<String, String> _formerCodes = {
    'OR': 'IN-OD',
    'TS': 'IN-TG',
    'UT': 'IN-UK',
    'UA': 'IN-UK',
    'CG': 'IN-CT',
    'DN': 'IN-DH',
    'DD': 'IN-DH',
  };

  static Map<String, String>? _namesByCode;

  static Map<String, String> get _names =>
      _namesByCode ??= {for (final e in _isoCodes.entries) e.value: e.key};

  static final RegExp _codeShape = RegExp(r'^(?:IN[-_ ]?)?([A-Z]{2})$');

  /// The ISO 3166-2 code (`IN-TN`) for a state given as a code (`IN-TN`,
  /// `tn`) or as a name in any supported language; null when unrecognised.
  /// "Tamil Nadu", "tn", "IN-TN" and "தமிழ்நாடு" all give `IN-TN`.
  static String? code(String raw) {
    final shape = _codeShape.firstMatch(raw.trim().toUpperCase());
    if (shape != null) {
      final short = shape.group(1)!;
      final iso = 'IN-$short';
      if (_names.containsKey(iso)) return iso;
      final former = _formerCodes[short];
      if (former != null) return former;
    }
    return _isoCodes[canonical(raw)];
  }

  /// English name for an ISO code from [code]; null when unknown.
  static String? nameForCode(String isoCode) => _names[isoCode];

  /// English names of every state and union territory, A-Z: the values a
  /// structured state picker offers.
  static List<String> get names =>
      _isoCodes.keys.toList(growable: false)..sort();

  static final RegExp _devanagari = RegExp(r'[ऀ-ॿ]');
  static final RegExp _tamil = RegExp(r'[஀-௿]');

  /// [englishName] as written in [lang] (`hi`, `ta`, `mr`); the English name for
  /// English or when no spelling in that script is known.
  static String displayName(String englishName, String lang) {
    if (lang == 'mr' && _marathi.containsKey(englishName)) {
      return _marathi[englishName]!;
    }
    final script = switch (lang) {
      'hi' || 'mr' => _devanagari,
      'ta' => _tamil,
      _ => null,
    };
    if (script == null) return englishName;
    for (final alias in _aliases[englishName] ?? const <String>[]) {
      if (script.hasMatch(alias)) return alias;
    }
    return englishName;
  }

  static Map<String, String>? _lookup;

  static Map<String, String> get _table => _lookup ??= {
    for (final entry in _aliases.entries) ...{
      _key(entry.key): entry.key,
      for (final alias in entry.value) _key(alias): entry.key,
    },
    for (final entry in _marathi.entries) _key(entry.value): entry.key,
  };

  static final RegExp _latin = RegExp(r'^[a-z0-9 ]+$');

  static String _key(String s) => s
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[.,]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// The English catalog name for [raw] (any supported language), or [raw]
  /// trimmed when it is not recognised.
  static String canonical(String raw) {
    final text = _key(raw);
    if (text.isEmpty) return raw.trim();
    final exact = _table[text];
    if (exact != null) return exact;
    // A geocoded value can carry extra words ("तमिलनाडु राज्य"); match a known
    // non-Latin name inside it, longest first so the most specific one wins.
    // Latin aliases are only matched exactly: short ones ("goa", "tn") would
    // otherwise hit unrelated words.
    final nonLatin =
        _table.keys.where((k) => !_latin.hasMatch(k) && k.length >= 4).toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    for (final alias in nonLatin) {
      if (text.contains(alias)) return _table[alias]!;
    }
    return raw.trim();
  }
}
