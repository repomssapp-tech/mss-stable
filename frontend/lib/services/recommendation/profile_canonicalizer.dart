import 'dart:ui' show Locale;

import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import 'indian_states.dart';

/// Rewrites a [UserProfile]'s option-style fields into one language-independent
/// (English) form so the recommendation engine can compare them against the
/// English catalog whatever language the profile was filled in.
///
/// Onboarding stores the *label the user tapped*, so a profile created in
/// Tamil holds "பெண்" and one in Hindi holds "महिला"; voice facts and older
/// profiles hold English. Each field has its own label table (Hindi "अन्य" is
/// both gender-Other and community-Others). A value that is not recognised is
/// returned unchanged, so free text is never lost.
class ProfileCanonicalizer {
  const ProfileCanonicalizer._();

  static final List<String> _languages = [
    for (final locale in AppLocalizations.supportedLocales) locale.languageCode,
  ];

  /// A copy of [p] with gender, state, community, education, employment,
  /// disability and religion in canonical English form.
  static UserProfile canonicalize(UserProfile p) => p.copyWith(
    gender: gender(p.gender),
    state: IndianStates.canonical(p.state),
    community: community(p.community),
    educationLevel: education(p.educationLevel),
    qualification: education(p.qualification),
    employmentStatus: employmentRoles(p.employmentStatus).join(', '),
    disability: disability(p.disability),
    religion: religion(p.religion),
  );

  // ── Per-field label tables ──────────────────────────────────────────────

  static String gender(String raw) => _gender.resolve(raw);
  static String community(String raw) => _community.resolve(raw);
  static String education(String raw) => _education.resolve(raw);
  static String employment(String raw) => _employment.resolve(raw);
  static Set<String> employmentRoles(String raw) => {
    for (final entry in raw.split(','))
      if (entry.trim().isNotEmpty) employment(entry),
  };
  static String disability(String raw) => _yesNo.resolve(raw);
  static String religion(String raw) => _religion.resolve(raw);

  /// Whether a canonical [disability] value means the person is differently
  /// abled. The form stores "Yes"/"No"; older data used "None".
  static bool isDifferentlyAbled(String canonicalDisability) {
    final v = canonicalDisability.trim().toLowerCase();
    return v.isNotEmpty && v != 'no' && v != 'none';
  }

  static final _Table _gender = _Table.build(
    labels: {
      'Male': [(l) => l.genderMale],
      'Female': [(l) => l.genderFemale],
      'Other': [(l) => l.genderOther],
    },
    extra: {
      'Male': ['m', 'man', 'boy'],
      'Female': ['f', 'woman', 'women', 'girl'],
      'Transgender': [
        'transgender',
        'trans',
        'திருநங்கை',
        'மூன்றாம் பாலினத்தவர்',
        'ट्रांसजेंडर',
      ],
      'Other': ['others'],
    },
  );

  static final _Table _community = _Table.build(
    labels: {
      'General': [(l) => l.commGeneral, (l) => l.commGeneralOc],
      'OBC': [(l) => l.commObc, (l) => l.commObcBcMbc],
      'EWS': [(l) => l.commEws, (l) => l.commEwsCategory],
      'SC': [(l) => l.commSc, (l) => l.commScCategory],
      'ST': [(l) => l.commSt, (l) => l.commStCategory],
      'Minority': [(l) => l.commMinority],
      'Others': [(l) => l.commOthers],
    },
    extra: {
      'General': ['oc', 'open category'],
      'OBC': ['bc', 'mbc', 'bc / mbc', 'backward class'],
      'SC': ['scheduled caste'],
      'ST': ['scheduled tribe'],
      'Others': ['other'],
    },
  );

  static final _Table _education = _Table.build(
    labels: {
      'School': [(l) => l.eduSchool],
      'Diploma': [(l) => l.eduDiploma],
      'Undergraduate': [(l) => l.eduUndergraduate],
      'Postgraduate': [(l) => l.eduPostgraduate],
      'Ph.D.': [(l) => l.eduPhd],
    },
    extra: {
      'School': ['school', '10th', '12th', 'high school'],
      'Diploma': ['diploma', 'iti', 'diploma / iti'],
      'Undergraduate': ['undergraduate', 'graduate', 'degree', 'bachelor'],
      'Postgraduate': ['postgraduate', 'master', 'masters'],
      'Ph.D.': ['phd', 'ph.d', 'doctorate'],
    },
  );

  static final _Table _employment = _Table.build(
    labels: {
      'Student': [(l) => l.empStudent],
      'Farmer': [(l) => l.empFarmer],
      'Entrepreneur': [(l) => l.aspiringEntrepreneur],
      'Business': [(l) => l.existingBusiness],
      'MSME Owner': [(l) => l.msmeOwner],
      'Artisan / SHG Member': [(l) => l.artisanShg],
      'Salaried': [(l) => l.empSalaried],
      'Self-employed': [(l) => l.empSelfEmployed],
      'Unemployed': [(l) => l.empUnemployed],
      'Retired': [(l) => l.empRetired],
    },
    extra: {
      'Self-employed': ['self employed', 'self-employed'],
      'Entrepreneur': ['aspiring entrepreneur'],
      'Business': ['existing business', 'business owner'],
      'MSME Owner': ['msme'],
      'Artisan / SHG Member': ['artisan', 'artisan_shg'],
    },
  );

  static final _Table _yesNo = _Table.build(
    labels: {
      'Yes': [(l) => l.valYes],
      'No': [(l) => l.valNo],
    },
    extra: {
      'No': ['none', 'nil'],
    },
  );

  static final _Table _religion = _Table.build(
    labels: const {},
    extra: {
      'Hindu': ['hindu', 'हिंदू', 'हिन्दू', 'இந்து'],
      'Muslim': ['muslim', 'मुस्लिम', 'इस्लाम', 'முஸ்லிம்', 'இஸ்லாம்'],
      'Christian': ['christian', 'ईसाई', 'கிறிஸ்தவர்', 'கிறித்தவர்'],
      'Sikh': ['sikh', 'सिख', 'சீக்கியர்'],
      'Buddhist': ['buddhist', 'बौद्ध', 'பௌத்தர்', 'புத்த மதம்'],
      'Jain': ['jain', 'जैन', 'சமணர்', 'ஜைனர்'],
      'Parsi': ['parsi', 'पारसी', 'பார்சி', 'zoroastrian'],
    },
  );
}

/// Label -> canonical value, built from the ARB labels of every supported
/// language plus hand-listed variants.
class _Table {
  _Table._(this._map);

  final Map<String, String> _map;

  static String _key(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  factory _Table.build({
    required Map<String, List<String Function(AppLocalizations)>> labels,
    required Map<String, List<String>> extra,
  }) {
    final map = <String, String>{};
    for (final entry in labels.entries) {
      map[_key(entry.key)] = entry.key;
      for (final code in ProfileCanonicalizer._languages) {
        final l10n = lookupAppLocalizations(Locale(code));
        for (final label in entry.value) {
          map[_key(label(l10n))] = entry.key;
        }
      }
    }
    for (final entry in extra.entries) {
      map[_key(entry.key)] = entry.key;
      for (final alias in entry.value) {
        map[_key(alias)] = entry.key;
      }
    }
    return _Table._(map);
  }

  /// The canonical value for [raw], or [raw] trimmed when it is not a known
  /// label.
  String resolve(String raw) => _map[_key(raw)] ?? raw.trim();
}
