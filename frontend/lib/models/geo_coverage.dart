import '../services/recommendation/indian_states.dart';

/// Where a scheme applies, kept apart from who runs it.
///
/// A central-government scheme is not automatically nationwide (e.g. one
/// limited to the North Eastern states), and a scheme whose catalog record
/// carries no coverage data is [unknown], never assumed to be "All India" or
/// a default state. Coverage comes only from the record's
/// `classification.government` block (`appliesNationally`, `states`,
/// `statesText`), never from scheme names or IDs.
class GeoCoverage {
  const GeoCoverage({this.appliesNationally, this.stateCodes = const {}});

  static const unknown = GeoCoverage();

  /// True: every state. False: only [stateCodes]. Null: not stated.
  final bool? appliesNationally;

  /// ISO 3166-2:IN codes, e.g. `IN-TN`.
  final Set<String> stateCodes;

  bool get isNationwide => appliesNationally == true;

  bool get isKnown => isNationwide || stateCodes.isNotEmpty;

  /// Whether this coverage includes [state] (a name in any supported
  /// language, a short code or an ISO code). A nationwide label ("All
  /// India") matches nationwide coverage only. An unrecognized [state]
  /// matches nothing.
  bool coversState(String state) {
    if (isNationwideLabel(state)) return isNationwide;
    final code = normalizeStateCode(state);
    if (code == null) return false;
    return isNationwide || stateCodes.contains(code);
  }

  /// Reads a catalog `classification.government` block. Explicit `states`
  /// win; `statesText` is read only when that list is empty.
  factory GeoCoverage.fromGovernment(Map<dynamic, dynamic> gov) {
    final national = gov['appliesNationally'];
    final codes = <String>{};
    final states = gov['states'];
    if (states is List) {
      for (final s in states) {
        final code = normalizeStateCode(s?.toString() ?? '');
        if (code != null) codes.add(code);
      }
    }
    final text = gov['statesText']?.toString() ?? '';
    if (codes.isEmpty && national != true && text.trim().isNotEmpty) {
      final fromText = GeoCoverage.fromLabel(text);
      if (national is! bool) return fromText;
      codes.addAll(fromText.stateCodes);
    }
    return GeoCoverage(
      appliesNationally: national is bool ? national : null,
      stateCodes: Set.unmodifiable(codes),
    );
  }

  /// Reads a free-text coverage label such as "All India", "Tamil Nadu" or
  /// "North Eastern States and Sikkim". Anything unrecognized is [unknown].
  factory GeoCoverage.fromLabel(String label) {
    if (label.trim().isEmpty) return unknown;
    if (isNationwideLabel(label)) {
      return const GeoCoverage(appliesNationally: true);
    }
    final single = normalizeStateCode(label);
    if (single != null) {
      return GeoCoverage(appliesNationally: false, stateCodes: {single});
    }
    // Several states in one label: match whole English names only.
    final text = ' ${_words(label)} ';
    final codes = <String>{
      for (final e in _codeByName.entries)
        if (text.contains(' ${e.key} ')) e.value,
      for (final region in _regions.entries)
        if (text.contains(' ${region.key} ')) ...region.value,
    };
    if (codes.isEmpty) return unknown;
    return GeoCoverage(
      appliesNationally: false,
      stateCodes: Set.unmodifiable(codes),
    );
  }

  /// True for labels meaning "the whole country" ("All India", "Pan-India",
  /// "Nationwide", ...).
  static bool isNationwideLabel(String label) {
    final compact = label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    const exact = {
      'india',
      'national',
      'nationwide',
      'acrossindia',
      'allstates',
      'allstatesut',
      'allstatesuts',
    };
    return exact.contains(compact) ||
        compact.startsWith('allindia') ||
        compact.startsWith('panindia');
  }

  /// `IN-XX` for a state or union territory given as a name ("Tamil Nadu",
  /// "तमिलनाडु"), a short code ("tn") or an ISO code ("IN-TN"); null when
  /// [input] names none.
  static String? normalizeStateCode(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;
    final iso = RegExp(
      r'^in[-_ ]?([a-z]{2})$',
      caseSensitive: false,
    ).firstMatch(raw);
    final short = iso?.group(1) ?? (raw.length == 2 ? raw : null);
    if (short != null) {
      final upper = short.toUpperCase();
      final code = 'IN-${_legacyCodes[upper] ?? upper}';
      if (_names.containsKey(code)) return code;
    }
    return _codeByName[_words(IndianStates.canonical(raw))];
  }

  /// English name for an `IN-XX` code, or null.
  static String? stateName(String code) => _names[code];

  /// Lowercase words separated by single spaces, `&` read as "and".
  static String _words(String s) => s
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z]+'), ' ')
      .trim();

  static const Map<String, String> _names = {
    'IN-AN': 'Andaman and Nicobar Islands',
    'IN-AP': 'Andhra Pradesh',
    'IN-AR': 'Arunachal Pradesh',
    'IN-AS': 'Assam',
    'IN-BR': 'Bihar',
    'IN-CH': 'Chandigarh',
    'IN-CG': 'Chhattisgarh',
    'IN-DH': 'Dadra and Nagar Haveli and Daman and Diu',
    'IN-DL': 'Delhi',
    'IN-GA': 'Goa',
    'IN-GJ': 'Gujarat',
    'IN-HR': 'Haryana',
    'IN-HP': 'Himachal Pradesh',
    'IN-JK': 'Jammu and Kashmir',
    'IN-JH': 'Jharkhand',
    'IN-KA': 'Karnataka',
    'IN-KL': 'Kerala',
    'IN-LA': 'Ladakh',
    'IN-LD': 'Lakshadweep',
    'IN-MP': 'Madhya Pradesh',
    'IN-MH': 'Maharashtra',
    'IN-MN': 'Manipur',
    'IN-ML': 'Meghalaya',
    'IN-MZ': 'Mizoram',
    'IN-NL': 'Nagaland',
    'IN-OD': 'Odisha',
    'IN-PY': 'Puducherry',
    'IN-PB': 'Punjab',
    'IN-RJ': 'Rajasthan',
    'IN-SK': 'Sikkim',
    'IN-TN': 'Tamil Nadu',
    'IN-TG': 'Telangana',
    'IN-TR': 'Tripura',
    'IN-UP': 'Uttar Pradesh',
    'IN-UK': 'Uttarakhand',
    'IN-WB': 'West Bengal',
  };

  /// Superseded ISO codes still seen in data.
  static const Map<String, String> _legacyCodes = {
    'CT': 'CG',
    'OR': 'OD',
    'TS': 'TG',
    'UT': 'UK',
    'DD': 'DH',
    'DN': 'DH',
  };

  static final Map<String, String> _codeByName = {
    for (final e in _names.entries) _words(e.value): e.key,
  };

  /// The North Eastern Region as defined by the Ministry of DoNER: eight
  /// states including Sikkim.
  static const Set<String> _northEast = {
    'IN-AR',
    'IN-AS',
    'IN-MN',
    'IN-ML',
    'IN-MZ',
    'IN-NL',
    'IN-SK',
    'IN-TR',
  };

  static const Map<String, Set<String>> _regions = {
    'north eastern states': _northEast,
    'north eastern region': _northEast,
    'north east': _northEast,
    'northeast': _northEast,
    'ner': _northEast,
  };
}
