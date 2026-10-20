// The recommendation engine scores an English catalog, but a profile stores the
// label the user tapped -- "பெண்" in Tamil, "महिला" in Hindi. These tests pin
// that the same person gets the same recommendations in every language.
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/recommendation/indian_states.dart';
import 'package:frontend/services/recommendation/profile_canonicalizer.dart';
import 'package:frontend/services/recommendation/recommendation_engine.dart';
import 'package:frontend/services/search/hybrid_scheme_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Scheme> catalog;

  setUpAll(() async {
    await SchemeSearchTaxonomy.ensureLoaded();
    catalog = await SchemeRepository.instance.getAllSchemes();
  });

  AppLocalizations l10n(String code) => lookupAppLocalizations(Locale(code));

  const stateName = {'en': 'Tamil Nadu', 'hi': 'तमिलनाडु', 'ta': 'தமிழ்நாடு'};

  /// The same person, with every option label in [code]'s language.
  UserProfile personIn(String code, {String gender = 'female'}) {
    final l = l10n(code);
    return UserProfile(
      gender: gender == 'female' ? l.genderFemale : l.genderMale,
      state: stateName[code]!,
      community: l.commSc,
      educationLevel: l.eduUndergraduate,
      qualification: l.eduUndergraduate,
      employmentStatus: 'Aspiring Entrepreneur',
      disability: l.valNo,
      dob: DateTime(1996, 3, 14),
      businessStage: 'Idea',
      profileCompleted: true,
    );
  }

  group('ProfileCanonicalizer', () {
    test('every gender label in every language maps to one English value', () {
      for (final code in ['en', 'hi', 'ta']) {
        final l = l10n(code);
        expect(ProfileCanonicalizer.gender(l.genderMale), 'Male');
        expect(ProfileCanonicalizer.gender(l.genderFemale), 'Female');
        expect(ProfileCanonicalizer.gender(l.genderOther), 'Other');
      }
    });

    test('Hindi "अन्य" is gender-Other in one field and community-Others in '
        'another (per-field tables)', () {
      expect(ProfileCanonicalizer.gender('अन्य'), 'Other');
      expect(ProfileCanonicalizer.community('अन्य'), 'Others');
    });

    test('community and education labels, including the long English ones, '
        'canonicalise', () {
      for (final code in ['en', 'hi', 'ta']) {
        final l = l10n(code);
        expect(ProfileCanonicalizer.community(l.commSc), 'SC');
        expect(ProfileCanonicalizer.community(l.commScCategory), 'SC');
        expect(ProfileCanonicalizer.community(l.commObcBcMbc), 'OBC');
        expect(ProfileCanonicalizer.community(l.commGeneralOc), 'General');
        expect(
          ProfileCanonicalizer.education(l.eduUndergraduate),
          'Undergraduate',
        );
        expect(ProfileCanonicalizer.education(l.eduSchool), 'School');
        expect(ProfileCanonicalizer.education(l.eduPhd), 'Ph.D.');
      }
    });

    test('unrecognised free text is kept (trimmed), never blanked', () {
      expect(
        ProfileCanonicalizer.gender('  something else '),
        'something else',
      );
      expect(ProfileCanonicalizer.community(''), '');
    });

    test('"No" is NOT differently-abled in any language; "Yes" is', () {
      for (final code in ['en', 'hi', 'ta']) {
        final l = l10n(code);
        expect(
          ProfileCanonicalizer.isDifferentlyAbled(
            ProfileCanonicalizer.disability(l.valNo),
          ),
          isFalse,
          reason: code,
        );
        expect(
          ProfileCanonicalizer.isDifferentlyAbled(
            ProfileCanonicalizer.disability(l.valYes),
          ),
          isTrue,
          reason: code,
        );
      }
      expect(ProfileCanonicalizer.isDifferentlyAbled('None'), isFalse);
      expect(ProfileCanonicalizer.isDifferentlyAbled(''), isFalse);
    });

    test('religion in Hindi/Tamil script maps to the English name', () {
      expect(ProfileCanonicalizer.religion('मुस्लिम'), 'Muslim');
      expect(ProfileCanonicalizer.religion('கிறிஸ்தவர்'), 'Christian');
    });
  });

  group('IndianStates', () {
    test('English, Hindi and Tamil names resolve to the English name', () {
      expect(IndianStates.canonical('Tamil Nadu'), 'Tamil Nadu');
      expect(IndianStates.canonical('तमिलनाडु'), 'Tamil Nadu');
      expect(IndianStates.canonical('தமிழ்நாடு'), 'Tamil Nadu');
      expect(IndianStates.canonical('महाराष्ट्र'), 'Maharashtra');
      expect(IndianStates.canonical('மகாராஷ்டிரா'), 'Maharashtra');
      expect(IndianStates.canonical('Orissa'), 'Odisha');
    });

    test('a geocoded value with extra words still resolves', () {
      expect(IndianStates.canonical('तमिलनाडु राज्य'), 'Tamil Nadu');
    });

    test('unknown text is returned unchanged', () {
      expect(IndianStates.canonical('Atlantis'), 'Atlantis');
      expect(IndianStates.canonical(''), '');
    });
  });

  group('RecommendationEngine with non-English profiles', () {
    final womenOnly = Scheme(
      id: 'CEN2026-W1',
      name: 'Women Entrepreneurship Scheme',
      category: 'Women Entrepreneurs',
      state: 'All India',
      targetBeneficiary: 'Women',
      eligibilityGenderValues: const ['female'],
    );

    test('a Hindi or Tamil woman is eligible for a women-only scheme exactly '
        'as in English', () {
      final english = RecommendationEngine.evaluate(personIn('en'), womenOnly);
      expect(english.score, greaterThan(0.0));
      for (final code in ['hi', 'ta']) {
        final r = RecommendationEngine.evaluate(personIn(code), womenOnly);
        expect(r.score, english.score, reason: code);
        expect(r.missingRequirements, isEmpty, reason: code);
      }
    });

    test('a Hindi or Tamil man is still excluded from a women-only scheme', () {
      for (final code in ['en', 'hi', 'ta']) {
        final r = RecommendationEngine.evaluate(
          personIn(code, gender: 'male'),
          womenOnly,
        );
        expect(r.score, 0.0, reason: code);
      }
    });

    test('state residency is compared by state, not by spelling', () {
      final tnScheme = Scheme(
        id: 'TN2026-X',
        name: 'TN Scheme',
        state: 'Tamil Nadu',
        category: 'MSME',
        eligibilityMinAge: 18,
        eligibilityMaxAge: 45,
      );
      final kaScheme = Scheme(
        id: 'KA2026-X',
        name: 'Karnataka Scheme',
        state: 'Karnataka',
        category: 'MSME',
      );
      final english = RecommendationEngine.evaluate(personIn('en'), tnScheme);
      expect(english.score, greaterThanOrEqualTo(0.4));
      for (final code in ['hi', 'ta']) {
        expect(
          RecommendationEngine.evaluate(personIn(code), tnScheme).score,
          english.score,
          reason: code,
        );
        expect(
          RecommendationEngine.evaluate(personIn(code), kaScheme).score,
          0.0,
          reason: code,
        );
      }
    });

    test('SC priority is recognised from a Hindi/Tamil community label', () {
      final scScheme = Scheme(
        id: 'CEN2026-SC',
        name: 'SC Scheme',
        state: 'All India',
        category: 'MSME',
        specialCategories: const ['sc'],
      );
      for (final code in ['en', 'hi', 'ta']) {
        final r = RecommendationEngine.evaluate(personIn(code), scScheme);
        expect(
          r.matchingReasons.any((m) => m.contains('priority category')),
          isTrue,
          reason: code,
        );
      }
    });

    test('a profile that answered "No" to disability does not get the '
        'differently-abled priority (was credited to everyone)', () {
      final divyang = Scheme(
        id: 'CEN2026-D',
        name: 'Differently Abled Scheme',
        state: 'All India',
        category: 'MSME',
        specialCategories: const ['differently_abled'],
      );
      for (final code in ['en', 'hi', 'ta']) {
        final no = RecommendationEngine.evaluate(personIn(code), divyang);
        expect(
          no.matchingReasons.any((m) => m.contains('differently_abled')),
          isFalse,
          reason: '$code answered No',
        );
        final yes = RecommendationEngine.evaluate(
          personIn(code).copyWith(disability: l10n(code).valYes),
          divyang,
        );
        expect(
          yes.matchingReasons.any((m) => m.contains('differently_abled')),
          isTrue,
          reason: '$code answered Yes',
        );
      }
    });

    test('an industry typed in Hindi or Tamil reaches English scheme text', () {
      final textile = Scheme(
        id: 'CEN2026-T',
        name: 'Textile Upgradation Scheme',
        state: 'All India',
        category: 'Textiles',
        sector: 'Textiles and garments',
      );
      for (final industry in ['textile', 'कपड़ा', 'ஜவுளி']) {
        final r = RecommendationEngine.evaluate(
          personIn('en').copyWith(businessIndustry: industry),
          textile,
        );
        expect(
          r.matchingReasons.any((m) => m.startsWith('Sector:')),
          isTrue,
          reason: industry,
        );
      }
    });

    test('the same person gets identical recommendations for the WHOLE '
        'catalog in English, Hindi and Tamil', () {
      Map<String, double> scoresFor(String code) => {
        for (final e in RecommendationEngine.getRecommendations(
          personIn(code),
          catalog,
        ))
          e.key.id: e.value.score,
      };

      final english = scoresFor('en');
      expect(english, isNotEmpty);
      expect(
        english.values.where((s) => s >= RecommendationEngine.forMeThreshold),
        isNotEmpty,
        reason: 'the fixture must actually produce For Me matches',
      );
      for (final code in ['hi', 'ta']) {
        expect(scoresFor(code), english, reason: code);
      }
    });
  });
}
