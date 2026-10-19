import '../../models/user_profile.dart';
import '../../models/scheme_model.dart';

class RecommendationResult {
  final double score; // 0.0 to 1.0
  final List<String> matchingReasons;
  final List<String> missingRequirements;
  final List<String> missingDocuments;

  RecommendationResult({
    required this.score,
    required this.matchingReasons,
    required this.missingRequirements,
    required this.missingDocuments,
  });

  int get percentage => (score * 100).round();
}

class RecommendationEngine {
  /// The score at/above which a scheme is considered a personalised "For Me"
  /// match. Shared by the search screen's list gate and its
  /// `_matchingProfileCount` badge so the two never disagree.
  static const double forMeThreshold = 0.4;

  // ── Additive facet weights ────────────────────────────────────────────
  // evaluate() starts every scheme at 0.0 and ADDS a weight ONLY for a
  // SUBSTANTIVE positive match: the profile facet is set, the scheme
  // actually constrains on that facet, and the profile satisfies it. A
  // scheme being *silent* on a facet earns nothing. Hard disqualifications
  // short-circuit to 0.0. Tuned so a scheme that matches nothing
  // substantive (only national coverage) stays at 0.20 < [forMeThreshold],
  // a reasonably-matched profile lands ~0.45-0.65, and a well-matched one
  // ~0.7-0.9.
  static const double _wState =
      0.20; // exact state match (scheme scoped to the profile's state)
  // National / all-India coverage is true for *every* user, so it is the
  // weakest possible personalisation signal — worth less than an exact state
  // match. A national scheme now needs one genuinely strong facet match
  // (gender / age / stage) OR two lighter ones to clear [forMeThreshold],
  // instead of "you live in India + any one weak signal".
  static const double _wNationalCoverage = 0.15;
  static const double _wAge = 0.25; // scheme has an age gate the profile is in
  static const double _wGender =
      0.25; // scheme is gender-scoped, profile matches
  static const double _wCommunity = 0.20; // special-category / SC-ST overlap
  static const double _wEducation =
      0.15; // scheme's education rule is satisfied
  static const double _wSectorStage =
      0.25; // business-stage / eligibility-gate match
  static const double _wSector =
      0.20; // profile industry appears in scheme sector

  static List<MapEntry<Scheme, RecommendationResult>> getRecommendations(
    UserProfile profile,
    List<Scheme> schemes,
  ) {
    final results = <MapEntry<Scheme, RecommendationResult>>[];
    for (var scheme in schemes) {
      final res = evaluate(profile, scheme);
      results.add(MapEntry(scheme, res));
    }
    // Sort by score descending, scheme id as a deterministic tiebreak so
    // recomputing (e.g. on every profile sync) never reorders tied schemes.
    results.sort((a, b) {
      final scoreCmp = b.value.score.compareTo(a.value.score);
      return scoreCmp != 0 ? scoreCmp : a.key.id.compareTo(b.key.id);
    });
    return results;
  }

  /// Whether [profile] carries enough distinguishing facets for a
  /// personalised "For Me" match to be meaningful. A brand-new
  /// `UserProfile()` — which ships non-empty *defaults* for state /
  /// community / education / businessStage — is NOT enough: without an
  /// explicit date of birth and gender the engine cannot tell it apart
  /// from any other new user, and "For Me" would degrade to "All".
  static bool hasEnoughProfileForRecommendation(UserProfile profile) {
    if (profile.profileCompleted) return true;
    final hasAge = profile.dob != null;
    final hasGender = profile.gender.trim().isNotEmpty;
    return hasAge && hasGender;
  }

  /// The schemes a *usable* [profile] is eligible for at or above
  /// [forMeThreshold]. Returns an empty list (not the catalog) when the
  /// profile is too sparse — the caller shows a "complete your profile"
  /// empty state in that case.
  static List<Scheme> forMeSchemes(UserProfile profile, List<Scheme> schemes) {
    if (!hasEnoughProfileForRecommendation(profile)) return const [];
    return getRecommendations(
      profile,
      schemes,
    ).where((e) => e.value.score >= forMeThreshold).map((e) => e.key).toList();
  }

  static RecommendationResult evaluate(UserProfile profile, Scheme scheme) {
    double score = 0.0;
    final matchingReasons = <String>[];
    final missingRequirements = <String>[];
    final missingDocuments = <String>[];

    // Get basic stats
    final age = profile.age;
    final hasAge = profile.dob != null;
    final isTN = profile.state.toLowerCase() == 'tamil nadu';
    final isFemale =
        profile.gender.toLowerCase() == 'female' ||
        profile.gender.toLowerCase() == 'transgender';
    final isSCST =
        profile.community.toLowerCase() == 'sc' ||
        profile.community.toLowerCase() == 'st';
    final isSpecialCommunity =
        isSCST ||
        profile.community.toLowerCase() == 'obc' ||
        profile.community.toLowerCase() == 'minority' ||
        profile.community.toLowerCase() == 'ews';
    final isStudent = profile.employmentStatus.toLowerCase() == 'student';

    // Document checks helper: We check what documents they might miss based on profile inputs.
    // By default, we assume they have Aadhaar and PAN (or they are easy to obtain, but we flag if not filled in profile)
    // We will flag missing documents if the scheme requires them.
    for (var doc in scheme.requiredDocuments) {
      if (doc == 'Nativity Certificate (TN)' && !isTN) {
        missingDocuments.add(doc);
      } else if (doc == 'Community Certificate' &&
          profile.community.toLowerCase() == 'general') {
        // General category usually doesn't have a community certificate, but if the scheme requires it, it's flagged
        missingDocuments.add(doc);
      } else if (doc == 'Degree/Diploma Certificate' &&
          profile.educationLevel == 'School') {
        missingDocuments.add(doc);
      } else if (doc == 'Artisan Identity Card (DC Handicrafts)') {
        // Unless they specifically have it, flag as missing (simulate for demonstration)
        missingDocuments.add(doc);
      } else if (doc == 'DPIIT Certificate of Recognition' ||
          doc ==
              'Certificate of Incorporation (Pvt Ltd / LLP / Registered Partnership)') {
        missingDocuments.add(doc);
      } else if (doc == 'Project Report / Business Plan' ||
          doc == 'Project Report / DPR' ||
          doc == 'Project Report') {
        // Project report is always missing initially for new entrepreneurs
        missingDocuments.add(doc);
      } else if (doc == 'Quotations for machinery/equipment' ||
          doc ==
              'Price Quotation of machinery/equipment or items to be purchased') {
        missingDocuments.add(doc);
      }
    }

    // Early-return helper for a hard disqualification: the profile concretely
    // contradicts a real, exclusive scheme rule.
    RecommendationResult disqualified() => RecommendationResult(
      score: 0.0,
      matchingReasons: matchingReasons,
      missingRequirements: missingRequirements,
      missingDocuments: missingDocuments,
    );

    switch (scheme.id.toUpperCase()) {
      case 'NEEDS':
      case 'IN115':
        // HARD: State residency is exclusive.
        if (!isTN) {
          missingRequirements.add(
            'Residency: This scheme is strictly for residents of Tamil Nadu.',
          );
          return disqualified();
        }
        matchingReasons.add('Location: You reside in Tamil Nadu.');
        score += _wState;

        // Education
        if (profile.educationLevel == 'School') {
          missingRequirements.add(
            'Education: Requires a college Degree, Diploma, ITI, or Vocational Certificate.',
          );
        } else {
          matchingReasons.add(
            'Education: You hold a college degree/diploma (${profile.educationLevel}).',
          );
          score += _wEducation;
        }

        // First Gen Graduate Bonus
        if (profile.firstGenGraduate) {
          score += 0.1;
          matchingReasons.add(
            'Priority: You are a First-Generation Graduate (priority selection).',
          );
        }

        // Age limits -- General: 21-35, Special (Women, SC/ST, BC, OBC): 21-45
        final maxAge = (isFemale || isSpecialCommunity) ? 45 : 35;
        if (age >= 21 && age <= maxAge) {
          matchingReasons.add(
            'Age: Your age ($age) is within the eligible range of 21-$maxAge years.',
          );
          score += _wAge;
        } else {
          missingRequirements.add(
            'Age: Your age ($age) is outside the eligible range of 21-$maxAge years.',
          );
        }

        matchingReasons.add(
          'Funding: Supports project costs from ₹10 Lakhs to ₹5 Crores.',
        );
        break;

      case 'PMEGP':
      case 'IN130':
        // Open to any citizen 18+ with a viable plan -- broadly eligible.
        matchingReasons.add(
          'Age: Eligible for any citizen above 18 years (you are $age).',
        );
        if (age >= 18) score += _wAge;
        score += _wSectorStage; // open, self-employment/manufacturing oriented

        if (profile.educationLevel == 'School') {
          matchingReasons.add(
            'Education: VIII standard pass criteria applies for larger projects.',
          );
          score += _wEducation * 0.5;
        } else {
          matchingReasons.add(
            'Education: You satisfy the minimum VIII standard pass requirement.',
          );
          score += _wEducation;
        }

        if (isTN) {
          matchingReasons.add(
            'Implementation: Supported in Tamil Nadu via DIC and KVIC offices.',
          );
          score += _wState * 0.5;
        }
        break;

      case 'STANDUP_INDIA':
      case 'IN168':
        // HARD: reserved for Women entrepreneurs and SC/ST individuals.
        final eligibleCategory = isFemale || isSCST;
        if (!eligibleCategory) {
          missingRequirements.add(
            'Category: Stand-Up India is reserved for Women entrepreneurs and SC/ST category individuals.',
          );
          return disqualified();
        }
        // HARD: minimum age.
        if (age < 18) {
          missingRequirements.add('Age: Must be at least 18 years old.');
          return disqualified();
        }

        score += _wSectorStage; // cleared the reserved-category gate
        if (isFemale) {
          matchingReasons.add(
            'Gender: You match the requirement for Women entrepreneurs.',
          );
          score += _wGender;
        }
        if (isSCST) {
          matchingReasons.add(
            'Community: You match the requirement for SC/ST category borrowers.',
          );
          score += _wCommunity;
        }
        if (hasAge) score += _wAge;
        matchingReasons.add(
          'Project Type: Facilitates greenfield projects between ₹10 Lakhs and ₹1 Crore.',
        );
        break;

      case 'MUDRA':
      case 'IN128':
        // Very general: collateral-free credit for any viable micro business.
        matchingReasons.add(
          'Eligibility: Open to all Indian citizens with a viable business plan.',
        );
        matchingReasons.add(
          'Collateral: 100% collateral-free loan up to ₹10 Lakhs.',
        );
        score += _wSectorStage + _wState * 0.5;
        if (hasAge && age >= 18) score += _wAge;
        break;

      case 'WEP':
      case 'IN212':
        // Women Entrepreneurship Platform -- designed for, not exclusive to.
        if (isFemale) {
          matchingReasons.add(
            'Gender: Designed for women-led businesses and female founders.',
          );
          score += _wGender + _wSectorStage;
        } else {
          missingRequirements.add(
            'Gender: This platform is specifically designed to support Women Entrepreneurs.',
          );
          score += 0.05;
        }
        matchingReasons.add(
          'Aggregation: Provides aggregated support for mentoring, incubation, and networking.',
        );
        break;

      case 'TREAD':
      case 'IN195':
        // HARD: exclusively for women (groups or individuals).
        if (!isFemale) {
          missingRequirements.add(
            'Gender: TREAD is exclusively for groups or individual Women seeking self-employment.',
          );
          return disqualified();
        }
        matchingReasons.add(
          'Gender: Exclusively supports women entrepreneur groups.',
        );
        score += _wGender + _wSectorStage;
        matchingReasons.add(
          'Funding structure: Government grants up to 30% of the project cost through registered NGOs.',
        );
        break;

      case 'KALAIGNAR_KAIVINAI':
      case 'IN074':
        // HARD: TN artisans only.
        if (!isTN) {
          missingRequirements.add(
            'Residency: Strictly for artisans residing in Tamil Nadu.',
          );
          return disqualified();
        }
        matchingReasons.add('Location: You reside in Tamil Nadu.');
        score += _wState;
        // The Pehchan Artisan Card itself can't be inferred, but when the
        // profile's role is artisan / SHG member this is a genuine "For Me"
        // match; for anyone else it stays a weak, findable-but-not-personal
        // result.
        if (_isArtisanRole(profile)) {
          matchingReasons.add(
            'Occupation: Your profile identifies you as an artisan / SHG member.',
          );
          score += _wSectorStage;
          missingRequirements.add(
            'Artisan Status: You will still need a valid Pehchan Artisan Card from the Ministry of Textiles.',
          );
        } else {
          missingRequirements.add(
            'Artisan Status: Must hold a valid Pehchan Artisan Card from the Ministry of Textiles.',
          );
          score += 0.1;
        }
        break;

      case 'STARTUP_TN':
      case 'IN182':
        // HARD: must be incorporated/registered in Tamil Nadu.
        if (!isTN) {
          missingRequirements.add(
            'Residency: Startups must be incorporated or registered in Tamil Nadu.',
          );
          return disqualified();
        }
        matchingReasons.add(
          'Location: Available for startups incorporated in Tamil Nadu.',
        );
        score += _wState;
        // DPIIT recognition can't be inferred, but a profile that identifies
        // as building / running a business is the intended audience — treat
        // it as a real match. Others stay findable but sub-threshold.
        if (_isFounderRole(profile)) {
          matchingReasons.add(
            'Stage: Your profile identifies you as an entrepreneur / business owner.',
          );
          score += _wSectorStage;
          missingRequirements.add(
            'DPIIT Recognition: You will still need registration and recognition from DPIIT (Govt of India).',
          );
        } else {
          missingRequirements.add(
            'DPIIT Recognition: Requires registration and recognition from DPIIT (Govt of India).',
          );
          score += 0.1;
        }
        matchingReasons.add(
          'Innovation: Offers TANSEED grants of up to ₹15 Lakhs.',
        );
        break;

      case 'POST_MATRIC':
        if (isStudent) {
          matchingReasons.add('Occupation: You are a Student.');
          score += _wSectorStage;
        } else {
          missingRequirements.add(
            'Occupation: Intended for students currently enrolled in Class 11 to PhD.',
          );
        }
        if (profile.community.toLowerCase() == 'general') {
          missingRequirements.add(
            'Community: Priority is given to SC, ST, OBC and Minority community students.',
          );
        } else {
          matchingReasons.add(
            'Community: You belong to a priority group (${profile.community}).',
          );
          score += _wCommunity;
        }
        matchingReasons.add('Academic: Supports Class 11 to PhD levels.');
        break;

      case 'MERIT_MEANS':
        if (isStudent) {
          score += _wSectorStage;
        } else {
          missingRequirements.add(
            'Occupation: Designed for students in UG & PG professional courses.',
          );
        }
        if (profile.annualIncome > 250000) {
          missingRequirements.add(
            'Income: Requires family annual income below ₹2.5 Lakhs.',
          );
        } else {
          matchingReasons.add(
            'Income: Your family income is below ₹2.5 Lakhs.',
          );
          score += _wCommunity;
        }
        matchingReasons.add(
          'Academic: Designed for UG & PG professional courses.',
        );
        break;

      case 'INSPIRE':
        if (isStudent) {
          score += _wSectorStage;
        } else {
          missingRequirements.add(
            'Occupation: For students pursuing basic/natural sciences.',
          );
        }
        if (profile.age >= 17 && profile.age <= 22) {
          matchingReasons.add('Age: You fit the age bracket of 17-22 years.');
          score += _wAge;
        } else {
          missingRequirements.add('Age: Designed for youth aged 17-22 years.');
        }
        matchingReasons.add(
          'Academic: For top 1% performers in Class 12 pursuing basic sciences.',
        );
        break;

      case 'PRAGATI':
        // HARD: female students only.
        if (!isFemale) {
          missingRequirements.add('Gender: Exclusively for female students.');
          return disqualified();
        }
        matchingReasons.add('Gender: Female candidate.');
        score += _wGender + _wSectorStage;
        if (profile.educationLevel == 'Undergraduate' ||
            profile.educationLevel == 'Diploma' ||
            profile.educationLevel == 'Postgraduate') {
          matchingReasons.add(
            'Academic: Enrolled in eligible level (${profile.educationLevel}).',
          );
          score += _wEducation;
        } else {
          missingRequirements.add(
            'Academic: Designed for Diploma, UG or PG courses.',
          );
        }
        break;

      default:
        // 1. State / Residency -- HARD when the scheme is scoped to a
        //    different state than the profile.
        final schemeState = scheme.state.toLowerCase().trim();
        final stateIsNational =
            schemeState.isEmpty ||
            schemeState == 'all india' ||
            schemeState == 'pan-india' ||
            schemeState.contains('pan-india') ||
            schemeState.contains('all india');
        if (!stateIsNational &&
            schemeState != profile.state.toLowerCase().trim()) {
          missingRequirements.add(
            'Residency: This scheme is for residents of ${scheme.state}.',
          );
          return disqualified();
        }
        if (!stateIsNational) {
          matchingReasons.add(
            'Location: You reside in ${scheme.state} where this scheme is offered.',
          );
          score += _wState;
        } else if (profile.state.trim().isNotEmpty) {
          matchingReasons.add(
            'Coverage: Applies across India, including ${profile.state}.',
          );
          score += _wNationalCoverage;
        }

        // 2. Gender -- structured eligibility.gender facet is authoritative
        //    when the catalog asserts it; free-text targetBeneficiary is the
        //    fallback. A female-only scheme HARD-excludes non-female profiles.
        final targetUpper = scheme.targetBeneficiary.toUpperCase();
        final hasWomenKeyword =
            targetUpper.contains('WOMEN') || targetUpper.contains('FEMALE');
        bool wantsFemale = false;
        if (scheme.eligibilityGenderValues.isNotEmpty) {
          wantsFemale = scheme.eligibilityGenderValues.any(
            (v) => v.toLowerCase() == 'female',
          );
        } else {
          wantsFemale = hasWomenKeyword;
        }
        if (wantsFemale) {
          if (!isFemale) {
            missingRequirements.add(
              'Gender: This scheme is targeted towards Women/Female entrepreneurs.',
            );
            return disqualified();
          }
          // SUBSTANTIVE: the scheme is gender-scoped and the profile matches.
          matchingReasons.add(
            'Gender: You match the target female demographic.',
          );
          score += _wGender;
        }
        // A gender-agnostic scheme earns NOTHING for gender -- "silent on X"
        // is not a match (previously this granted +_wGender to every scheme
        // for anyone with a gender set, which recreated the "no info => still
        // matches" bug at a lower score).

        // 3. Special-category -- structured eligibility.specialCategory facet
        //    is authoritative when populated; SC/ST keyword is the fallback.
        //    A mismatch is a soft miss (priority, not exclusive), never a
        //    hard zero.
        final hasSCSTKeyword =
            targetUpper.contains('SC/') ||
            targetUpper.contains('SC ') ||
            targetUpper.contains('ST ') ||
            targetUpper.contains('SC-ST') ||
            targetUpper.contains('SC/ST');
        if (scheme.specialCategories.isNotEmpty) {
          final profileCategories = <String>{
            if (profile.community.toLowerCase() == 'sc') 'sc',
            if (profile.community.toLowerCase() == 'st') 'st',
            if (isFemale) 'women',
            if (profile.gender.toLowerCase() == 'transgender') 'transgender',
            if (profile.disability.isNotEmpty &&
                profile.disability.toLowerCase() != 'none')
              'differently_abled',
            if (profile.veteran) 'ex_servicemen',
            if (_minorityReligions.contains(profile.religion.toLowerCase()))
              'minority',
          };
          final schemeCategories = scheme.specialCategories
              .map((c) => c.toLowerCase())
              .toSet();
          final overlap = schemeCategories.intersection(profileCategories);
          if (overlap.isEmpty) {
            missingRequirements.add(
              'Community/Category: Priority is for ${scheme.specialCategories.join(', ')}.',
            );
          } else {
            matchingReasons.add(
              'Community/Category: Matches the ${overlap.join(', ')} priority category.',
            );
            score += _wCommunity;
          }
        } else if (hasSCSTKeyword) {
          if (isSCST) {
            matchingReasons.add(
              'Community: Matches the SC/ST priority demographic.',
            );
            score += _wCommunity;
          } else {
            missingRequirements.add(
              'Community: Priority/eligibility is for SC/ST categories.',
            );
          }
        }

        // 4. Age -- SUBSTANTIVE only: the scheme declares an age gate
        //    (eligibility.age.{minYears,maxYears}) AND the profile has a real
        //    DOB AND the age falls in range. A scheme with no age gate earns
        //    nothing here. Out-of-range is a soft miss, not a hard zero.
        if (scheme.eligibilityMinAge != null ||
            scheme.eligibilityMaxAge != null) {
          final minAge = scheme.eligibilityMinAge ?? 0;
          final maxAge = scheme.eligibilityMaxAge ?? 200;
          if (hasAge && age >= minAge && age <= maxAge) {
            matchingReasons.add(
              'Age: Your age ($age) is within the eligible range of $minAge-$maxAge years.',
            );
            score += _wAge;
          } else if (hasAge) {
            missingRequirements.add(
              'Age: Your age ($age) is outside the eligible range of $minAge-$maxAge years.',
            );
          }
        }

        // 5. Business stage -- SUBSTANTIVE: scheme declares eligible stages
        //    and the profile's stage maps into them.
        if (scheme.eligibilityBusinessStageValues.isNotEmpty) {
          final mappedStage = _mapBusinessStage(profile.businessStage);
          final wantsStage = scheme.eligibilityBusinessStageValues
              .map((s) => s.toLowerCase())
              .toSet();
          if (mappedStage != null && wantsStage.contains(mappedStage)) {
            matchingReasons.add(
              'Business Stage: Your business stage (${profile.businessStage}) matches.',
            );
            score += _wSectorStage;
          } else {
            missingRequirements.add(
              'Business Stage: This scheme targets ${scheme.eligibilityBusinessStageValues.join(', ')} businesses.',
            );
          }
        }

        // 6. Sector / interest overlap -- SUBSTANTIVE: the profile's industry
        //    literally appears in the scheme's sector / category / keywords.
        if (profile.businessIndustry.trim().length > 2) {
          final industry = profile.businessIndustry.toLowerCase();
          final sectorHay =
              '${scheme.sector} ${scheme.category} ${scheme.searchKeywords}'
                  .toLowerCase();
          if (sectorHay.contains(industry)) {
            matchingReasons.add(
              'Sector: Aligned with your ${profile.businessIndustry} focus.',
            );
            score += _wSector;
          }
        }

        // 6b. Role <-> scheme theme -- SUBSTANTIVE: the onboarding role the
        //     user picked lines up with what the scheme is *about*. This is
        //     what lets a Tamil Nadu startup grant (state-scoped, otherwise
        //     silent on facets) clear the "For Me" bar for a Tamil Nadu user
        //     who identifies as an entrepreneur, instead of sitting at the
        //     bare state-match score.
        final themeHay =
            '${scheme.sector} ${scheme.category} ${scheme.searchKeywords} '
                    '${scheme.name} ${scheme.targetBeneficiary}'
                .toLowerCase();
        const founderThemeWords = [
          'startup',
          'start-up',
          'start up',
          'entrepreneur',
          'incubat',
          'seed fund',
          'seed grant',
          'venture',
          'self-employment',
          'self employment',
          'enterprise creation',
        ];
        const artisanThemeWords = [
          'artisan',
          'handicraft',
          'handloom',
          'weaver',
          'khadi',
          'craft',
          'kaivinai',
          'cottage industr',
        ];
        if (_isFounderRole(profile) &&
            founderThemeWords.any(themeHay.contains)) {
          matchingReasons.add(
            'Focus: This scheme supports entrepreneurs/startups, which matches '
            'your profile.',
          );
          score += _wSectorStage;
        } else if (_isArtisanRole(profile) &&
            artisanThemeWords.any(themeHay.contains)) {
          matchingReasons.add(
            'Focus: This scheme supports artisans/craftspeople, which matches '
            'your profile.',
          );
          score += _wSectorStage;
        }

        // 7. Genuinely unconstrained scheme that matched nothing at all --
        //    keep it findable (search / browse) but well below the "For Me"
        //    bar. This is NOT a match, it is the absence of one.
        if (score == 0.0 && matchingReasons.isEmpty) {
          score = 0.3;
          matchingReasons.add(
            'Relevance: No specific eligibility conflicts detected.',
          );
        }
        break;
    }

    // Adjust score based on missing documents (slight penalty), preserved
    // from the previous model.
    if (score > 0.0 && missingDocuments.isNotEmpty) {
      final docRatio =
          (scheme.requiredDocuments.length - missingDocuments.length) /
          scheme.requiredDocuments.length;
      score = score * (0.8 + 0.2 * docRatio);
    }

    return RecommendationResult(
      score: score.clamp(0.0, 1.0),
      matchingReasons: matchingReasons,
      missingRequirements: missingRequirements,
      missingDocuments: missingDocuments,
    );
  }

  // Role self-identification from the "About You" onboarding step
  // (UserProfile.employmentStatus). Canonical titles: Student,
  // Aspiring Entrepreneur, Existing Business, MSME Owner, Farmer,
  // Artisan / SHG Member.
  static bool _isArtisanRole(UserProfile p) {
    final e = p.employmentStatus.toLowerCase();
    return e.contains('artisan') || e.contains('shg');
  }

  static bool _isFounderRole(UserProfile p) {
    final e = p.employmentStatus.toLowerCase();
    return e.contains('entrepreneur') ||
        e.contains('business') ||
        e.contains('msme') ||
        e.contains('self-employed') ||
        e.contains('self employed');
  }

  // Catalog eligibility.businessStage vocab (derived from scheme_catalog.json):
  // 'new', 'existing', 'expansion', 'diversification'. UserProfile's
  // businessStage is a separate, coarser onboarding-form vocab: 'Idea',
  // 'Prototype', 'Registered', 'Operational', 'Expansion'. Maps the latter
  // onto the former; returns null for stages with no reasonable mapping.
  static String? _mapBusinessStage(String profileStage) {
    switch (profileStage.toLowerCase()) {
      case 'idea':
      case 'prototype':
        return 'new';
      case 'registered':
      case 'operational':
        return 'existing';
      case 'expansion':
        return 'expansion';
      default:
        return null;
    }
  }

  // Religions the catalog's eligibility.specialCategory 'minority' value
  // refers to (India's officially notified religious minorities).
  static const _minorityReligions = {
    'muslim',
    'christian',
    'sikh',
    'buddhist',
    'parsi',
    'jain',
  };
}
