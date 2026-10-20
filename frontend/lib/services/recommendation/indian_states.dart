/// English <-> Hindi <-> Tamil names of India's states and union territories,
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

  static Map<String, String>? _lookup;

  static Map<String, String> get _table => _lookup ??= {
    for (final entry in _aliases.entries) ...{
      _key(entry.key): entry.key,
      for (final alias in entry.value) _key(alias): entry.key,
    },
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
