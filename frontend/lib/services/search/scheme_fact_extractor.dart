import 'intelligent_scheme_search.dart';
import 'scheme_understanding_models.dart';

/// Extracts structured eligibility facts from free-form user statements
/// and follow-up answers in English, Tamil, or romanized Tamil.
class SchemeFactExtractor {
  const SchemeFactExtractor._();

  static void mergeExtractedFacts(
    Map<EligibilityFactKey, EligibilityFact> target,
    Map<EligibilityFactKey, EligibilityFact> extracted,
  ) {
    for (final entry in extracted.entries) {
      final previous = target[entry.key];
      if (previous != null &&
          previous.value.toLowerCase() != entry.value.value.toLowerCase() &&
          previous.source == EligibilityFactSource.profile) {
        target[entry.key] = entry.value.copyWith(
          confirmed: false,
          conflictingValue: previous.value,
        );
      } else {
        target[entry.key] = entry.value;
      }
    }
  }

  static Map<EligibilityFactKey, EligibilityFact> extractFacts(
    String input,
    EligibilityFactSource source, {
    EligibilityFactKey? requestedFact,
  }) {
    final normalized = normalize(input);
    final facts = <EligibilityFactKey, EligibilityFact>{};

    void add(EligibilityFactKey key, String value, [double confidence = 0.9]) {
      facts[key] = EligibilityFact(
        key: key,
        value: value,
        confidence: confidence,
        source: source,
        confirmed:
            source == EligibilityFactSource.followUp ||
            source == EligibilityFactSource.edited,
      );
    }

    final ageMatch = RegExp(
      r'(?:age\s*(?:is)?\s*)?(\d{1,2})\s*(?:years?\s*old|yrs?|vayasu|வயது)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(input);
    if (ageMatch != null && ageMatch.group(1) != null) {
      add(EligibilityFactKey.age, ageMatch.group(1)!);
    }

    final money = extractMoney(input);
    if (money != null) {
      final isIncome = RegExp(
        r'income|salary|earn|varumanam|வருமானம்|சம்பளம்',
        caseSensitive: false,
        unicode: true,
      ).hasMatch(input);
      final isFunding = RegExp(
        r'loan|fund|capital|kadan|கடன்|நிதி|முதலீடு',
        caseSensitive: false,
        unicode: true,
      ).hasMatch(input);
      if (requestedFact == EligibilityFactKey.annualIncome || isIncome) {
        add(EligibilityFactKey.annualIncome, money.round().toString());
      } else if (requestedFact == EligibilityFactKey.fundingNeed || isFunding) {
        add(EligibilityFactKey.fundingNeed, money.round().toString());
      }
    }

    final state = firstAlias(normalized, {
      'Tamil Nadu': ['tamil nadu', 'தமிழ்நாடு', 'தமிழ் நாடு', 'tn'],
      'Karnataka': ['karnataka', 'கர்நாடகா'],
      'Kerala': ['kerala', 'கேரளா'],
      'Andhra Pradesh': ['andhra pradesh', 'andhra'],
      'Telangana': ['telangana'],
      'Punjab': ['punjab'],
      'Maharashtra': ['maharashtra'],
      'Other state': ['other state', 'வேறு மாநிலம்'],
    });
    if (state != null) add(EligibilityFactKey.state, state);

    final district = firstAlias(normalized, {
      'Chennai': ['chennai', 'சென்னை'],
      'Coimbatore': ['coimbatore', 'kovai', 'கோவை'],
      'Madurai': ['madurai', 'மதுரை'],
      'Tiruchirappalli': ['trichy', 'tiruchirappalli', 'திருச்சி'],
      'Salem': ['salem', 'சேலம்'],
      'Tirunelveli': ['tirunelveli', 'nellai', 'நெல்லை'],
    });
    if (district != null) add(EligibilityFactKey.district, district);

    final gender = firstAlias(normalized, {
      'Female': [
        'female',
        'woman',
        'women',
        'girl',
        'mother',
        'daughter',
        'pengal',
        'magalir',
        'pen',
        'பெண்',
        'பெண்கள்',
        'மகளிர்',
        'தாய்',
      ],
      'Male': ['male', 'man', 'father', 'boy', 'ஆண்', 'தந்தை'],
      'Transgender': ['transgender', 'திருநங்கை', 'திருநம்பி'],
      'Prefer not to say': ['prefer not to say', 'சொல்ல விரும்பவில்லை'],
    });
    if (gender != null) add(EligibilityFactKey.gender, gender);

    final community = firstAlias(normalized, {
      'SC': ['scheduled caste', 'sc', 'dalit', 'பட்டியல் சாதி', 'ஆதிதிராவிடர்'],
      'ST': ['scheduled tribe', 'st', 'tribal', 'பழங்குடி'],
      'OBC': ['obc', 'backward class', 'bc', 'பிற்படுத்தப்பட்டோர்'],
      'EWS': ['ews', 'economically weaker'],
      'Minority': ['minority', 'sirupaanmai', 'சிறுபான்மை'],
      'General': ['general category', 'general'],
    });
    if (community != null) add(EligibilityFactKey.community, community);

    final occupation = firstAlias(normalized, {
      'Student': ['student', 'college student', 'maanavar', 'மாணவர்', 'மாணவி'],
      'Farmer': ['farmer', 'vivasayi', 'uzhavar', 'விவசாயி', 'உழவர்'],
      'Artisan': ['artisan', 'weaver', 'kaivinai', 'கைவினைஞர்', 'நெசவாளர்'],
      'Fisher': ['fisherman', 'fisher', 'meenavar', 'மீனவர்'],
      'Self-employed': [
        'self employed',
        'self-employed',
        'suyathozhil',
        'சுயதொழில்',
      ],
      'Business owner': ['business owner', 'entrepreneur', 'தொழில்முனைவோர்'],
      'Unemployed': ['unemployed', 'no job', 'velai illa', 'வேலை இல்லை'],
      'Homemaker': ['homemaker', 'housewife', 'இல்லத்தரசி'],
      'Retired': ['retired', 'pensioner', 'ஓய்வு பெற்ற'],
      'Salaried': ['salaried', 'employee', 'வேலையில்'],
    });
    if (occupation != null) add(EligibilityFactKey.occupation, occupation);

    if (RegExp(
      r'not\s+(?:a\s+)?student|student\s+illa|மாணவ(?:ர்|ி)?\s+இல்லை',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(input)) {
      add(EligibilityFactKey.studentStatus, 'No');
      if (facts[EligibilityFactKey.occupation]?.value == 'Student') {
        facts.remove(EligibilityFactKey.occupation);
      }
    } else if (occupation == 'Student') {
      add(EligibilityFactKey.studentStatus, 'Yes');
    }

    final education = firstAlias(normalized, {
      'School': ['school', '10th', '12th', 'பள்ளி'],
      'Diploma': ['diploma', 'iti', 'டிப்ளமோ', 'ஐடிஐ'],
      'Undergraduate': [
        'undergraduate',
        'degree',
        'bachelor',
        'ug',
        'பட்டப்படிப்பு',
      ],
      'Postgraduate': [
        'postgraduate',
        'masters',
        'master degree',
        'pg',
        'முதுகலை',
      ],
      'Ph.D.': ['phd', 'doctorate', 'முனைவர்'],
    });
    if (education != null) add(EligibilityFactKey.education, education);

    if (containsAny(normalized, [
      'disabled',
      'disability',
      'differently abled',
      'maatru thiranali',
      'மாற்றுத்திறனாளி',
    ])) {
      add(EligibilityFactKey.disability, 'Yes');
    }

    final marital = firstAlias(normalized, {
      'Widowed': ['widow', 'widowed', 'விதவை'],
      'Married': ['married', 'திருமணமான'],
      'Single': ['single', 'unmarried', 'திருமணமாகாத'],
    });
    if (marital != null) add(EligibilityFactKey.maritalStatus, marital);

    final businessStage = firstAlias(normalized, {
      'New business': [
        'start a business',
        'new business',
        'starting business',
        'தொழில் தொடங்க',
      ],
      'Existing business': [
        'existing business',
        'running business',
        'உள்ள தொழில்',
      ],
      'Expansion': ['expand', 'expansion', 'scaling up', 'விரிவுபடுத்த'],
    });
    if (businessStage != null) {
      add(EligibilityFactKey.businessStage, businessStage);
    }

    final sector = firstAlias(normalized, {
      'Manufacturing': ['manufacturing', 'factory', 'plant', 'உற்பத்தி'],
      'Food processing': ['food processing', 'bakery', 'உணவு பதப்படுத்துதல்'],
      'Technology': ['technology', 'software', 'tech', 'தொழில்நுட்பம்'],
      'Retail': ['retail', 'shop', 'store', 'kadai', 'கடை'],
      'Agriculture': ['agriculture', 'farming', 'விவசாயம்'],
    });
    if (sector != null) add(EligibilityFactKey.businessSector, sector);

    final landMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:acre|acres|ekkar|ஏக்கர்)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(input);
    if (landMatch != null) {
      add(EligibilityFactKey.landholding, '${landMatch.group(1)} acres');
    }

    if (requestedFact != null && !facts.containsKey(requestedFact)) {
      final direct = input.trim();
      if (direct.isNotEmpty) {
        if ({
          EligibilityFactKey.disability,
          EligibilityFactKey.studentStatus,
        }.contains(requestedFact)) {
          final yes = containsAny(normalized, ['yes', 'ஆம்', 'aama', 'irukku']);
          final no = containsAny(normalized, [
            'no',
            'இல்லை',
            'illa',
            'kidaiyathu',
          ]);
          if (yes || no) add(requestedFact, yes ? 'Yes' : 'No', 0.86);
        } else {
          add(requestedFact, direct, 0.72);
        }
      }
    }
    return facts;
  }

  static double? extractMoney(String input) {
    final match =
        RegExp(
          r'(?:₹|rs\.?|rupees?)?\s*(\d+(?:\.\d+)?)\s*(crore|crores|lakh|lakhs|lac|thousand|k|லட்சம்|கோடி)?',
          caseSensitive: false,
          unicode: true,
        ).allMatches(input.replaceAll(',', '')).where((candidate) {
          final suffix = candidate.group(2);
          final prefix = input.substring(0, candidate.start).toLowerCase();
          return suffix != null ||
              RegExp(r'₹|rs\.?|rupees?').hasMatch(candidate.group(0) ?? '') ||
              RegExp(r'income|salary|loan|fund|வருமானம்|கடன்|நிதி').hasMatch(
                prefix.split(' ').reversed.take(3).toList().reversed.join(' '),
              );
        }).firstOrNull;
    if (match == null || match.group(1) == null) return null;
    return scaledMoney(match.group(1)!, match.group(2));
  }

  static double scaledMoney(String amountText, String? unitText) {
    final amount = double.parse(amountText);
    final unit = normalize(unitText ?? '');
    if (containsAny(unit, ['crore', 'கோடி'])) return amount * 10000000;
    if (containsAny(unit, ['lakh', 'lac', 'லட்சம்'])) return amount * 100000;
    if (containsAny(unit, ['thousand', 'k'])) return amount * 1000;
    return amount;
  }

  static String? firstAlias(
    String normalized,
    Map<String, List<String>> values,
  ) {
    for (final entry in values.entries) {
      if (entry.value.any((alias) => contains(normalized, alias))) {
        return entry.key;
      }
    }
    return null;
  }

  static bool containsAny(String text, Iterable<String> aliases) =>
      aliases.any((alias) => contains(text, alias));

  static bool contains(String text, String alias) {
    final normalizedAlias = normalize(alias);
    if (normalizedAlias.isEmpty) return false;
    if (' $text '.contains(' $normalizedAlias ')) return true;
    if (normalizedAlias.contains(' ') || normalizedAlias.length < 5) {
      return false;
    }
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(normalizedAlias)) return false;
    return text
        .split(' ')
        .any(
          (token) =>
              RegExp(r'^[a-z0-9]+$').hasMatch(token) &&
              token.length >= 5 &&
              IntelligentSchemeSearch.withinOneEdit(token, normalizedAlias),
        );
  }

  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0B80-\u0BFF]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
