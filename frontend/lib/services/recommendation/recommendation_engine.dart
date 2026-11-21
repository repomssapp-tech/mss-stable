import '../../models/user_profile.dart';
import '../../models/scheme_model.dart';
import '../search/hybrid_scheme_search.dart';
import '../../models/scheme_filter.dart';
import 'indian_states.dart';
import 'profile_canonicalizer.dart';

enum RecommendationRestriction { state, gender, age }

class RecommendationResult {
  final double score; // 0.0 to 1.0
  final List<String> matchingReasons;
  final List<String> missingRequirements;
  final List<String> missingDocuments;
  final RecommendationRestriction? restriction;
  final bool needsEligibilityReview;
  final bool usesFallbackScore;

  RecommendationResult({
    required this.score,
    required this.matchingReasons,
    required this.missingRequirements,
    required this.missingDocuments,
    this.restriction,
    this.needsEligibilityReview = false,
    this.usesFallbackScore = false,
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
  static const double _wSectorStage =
      0.25; // business-stage / eligibility-gate match
  static const double _wSector =
      0.20; // profile industry appears in scheme sector

  /// Scores every scheme in [schemes] for [profile], best first. The profile
  /// is canonicalised once (see [ProfileCanonicalizer]) rather than per scheme.
  static List<MapEntry<Scheme, RecommendationResult>> getRecommendations(
    UserProfile profile,
    List<Scheme> schemes, {
    int? ageInYears,
    Set<String> additionalCategories = const {},
  }) {
    final canonical = ProfileCanonicalizer.canonicalize(profile);
    final results = <MapEntry<Scheme, RecommendationResult>>[];
    for (var scheme in schemes) {
      final res = _score(
        canonical,
        scheme,
        ageInYears: ageInYears,
        additionalCategories: additionalCategories,
      );
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

  /// Scores one [scheme] for [profile]. The profile may have been filled in
  /// any supported language: it is canonicalised to English first, because
  /// the catalog's eligibility facets are English.
  static RecommendationResult evaluate(UserProfile profile, Scheme scheme) =>
      _score(ProfileCanonicalizer.canonicalize(profile), scheme);

  /// [p] must already be canonical (see [ProfileCanonicalizer.canonicalize]).
  static RecommendationResult _score(
    UserProfile p,
    Scheme scheme, {
    int? ageInYears,
    Set<String> additionalCategories = const {},
  }) {
    double score = 0.0;
    final matchingReasons = <String>[];
    final missingRequirements = <String>[];
    final missingDocuments = <String>[];

    RecommendationRestriction? restriction;
    var needsEligibilityReview = false;
    final age = ageInYears ?? (p.dob == null ? null : p.age);
    final isTN = p.state == 'Tamil Nadu';
    final isFemale = p.gender == 'Female' || p.gender == 'Transgender';
    final profileCategories = <String>{
      ...additionalCategories,
      if (p.community == 'SC') 'sc',
      if (p.community == 'ST') 'st',
      if (p.community == 'OBC') 'obc',
      if (isFemale) 'women',
      if (p.gender == 'Transgender') 'transgender',
      if (ProfileCanonicalizer.isDifferentlyAbled(p.disability))
        'differently_abled',
      if (p.veteran) 'ex_servicemen',
      if (p.community == 'Minority' ||
          _minorityReligions.contains(p.religion.toLowerCase()))
        'minority',
    };
    final isSCST =
        profileCategories.contains('sc') || profileCategories.contains('st');
    final schemeCategories = scheme.specialCategories
        .map((c) => c.toLowerCase())
        .toSet();

    // Document checks helper: We check what documents they might miss based on profile inputs.
    // By default, we assume they have Aadhaar and PAN (or they are easy to obtain, but we flag if not filled in profile)
    // We will flag missing documents if the scheme requires them.
    for (var doc in scheme.requiredDocuments) {
      if (doc == 'Nativity Certificate (TN)' && !isTN) {
        missingDocuments.add(doc);
      } else if (doc == 'Community Certificate' && p.community == 'General') {
        // General category usually doesn't have a community certificate, but if the scheme requires it, it's flagged
        missingDocuments.add(doc);
      } else if (doc == 'Degree/Diploma Certificate' &&
          p.educationLevel == 'School') {
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

    RecommendationResult disqualified(RecommendationRestriction? reason) =>
        RecommendationResult(
          score: 0,
          matchingReasons: matchingReasons,
          missingRequirements: missingRequirements,
          missingDocuments: missingDocuments,
          restriction: reason,
          needsEligibilityReview: reason == null,
        );

    final hasState = IndianStates.code(p.state) != null;
    final stateIsNational = schemeAppliesNationally(scheme);
    final hasStateRestriction =
        !stateIsNational &&
        (scheme.stateCodes.isNotEmpty ||
            (scheme.appliesNationally == null &&
                IndianStates.code(scheme.state) != null));
    if (scheme.appliesNationally == false && !hasStateRestriction) {
      needsEligibilityReview = true;
    }
    if (hasStateRestriction && !schemeAppliesInState(scheme, p.state)) {
      missingRequirements.add(
        'Residency: This scheme is for residents of ${scheme.state}.',
      );
      return disqualified(hasState ? RecommendationRestriction.state : null);
    }
    if (hasStateRestriction) {
      matchingReasons.add(
        'Location: You reside in ${scheme.state} where this scheme is offered.',
      );
      score += _wState;
    } else if (stateIsNational && hasState) {
      matchingReasons.add(
        'Coverage: Applies across India, including ${p.state}.',
      );
      score += _wNationalCoverage;
    }

    final targetUpper = scheme.targetBeneficiary.toUpperCase();
    final hasWomenKeyword = _womenTarget.hasMatch(targetUpper);
    final allowedGenders = scheme.eligibilityGenderValues
        .map((value) => value.toLowerCase())
        .toSet();
    final matchesGender =
        allowedGenders.contains(p.gender.toLowerCase()) ||
        (allowedGenders.contains('female') && isFemale);
    if (allowedGenders.isNotEmpty && !matchesGender) {
      final alternateAudience = _alternateGenderAudience.stringMatch(
        targetUpper,
      );
      final alternateCommunities = {
        if (alternateAudience != null &&
            _scheduledCaste.hasMatch(alternateAudience))
          'sc',
        if (alternateAudience != null &&
            _scheduledTribe.hasMatch(alternateAudience))
          'st',
      };
      if (profileCategories.intersection(alternateCommunities).isEmpty) {
        missingRequirements.add(
          'Gender: This scheme targets ${scheme.eligibilityGenderValues.join(', ')} applicants.',
        );
        final hasGender = const {
          'Male',
          'Female',
          'Other',
          'Transgender',
        }.contains(p.gender);
        final knowsCommunity =
            p.community.trim().isNotEmpty ||
            additionalCategories.any(
              const {'general', 'sc', 'st', 'obc'}.contains,
            );
        return disqualified(
          hasGender && (alternateCommunities.isEmpty || knowsCommunity)
              ? RecommendationRestriction.gender
              : null,
        );
      }
    }
    if (matchesGender ||
        (allowedGenders.isEmpty && hasWomenKeyword && isFemale)) {
      matchingReasons.add('Gender: You match the target demographic.');
      score += _wGender;
    }

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
    if (scheme.eligibilityMinAge != null || scheme.eligibilityMaxAge != null) {
      final minAge = scheme.eligibilityMinAge ?? 0;
      final maxAge = scheme.eligibilityMaxAge ?? 200;
      if (age != null && age >= minAge && age <= maxAge) {
        matchingReasons.add(
          'Age: Your age ($age) is within the eligible range of $minAge-$maxAge years.',
        );
        score += _wAge;
      } else if (age != null) {
        restriction = RecommendationRestriction.age;
        missingRequirements.add(
          'Age: Your age ($age) is outside the eligible range of $minAge-$maxAge years.',
        );
      } else {
        needsEligibilityReview = true;
      }
    }

    // 5. Business stage -- SUBSTANTIVE: scheme declares eligible stages
    //    and the profile's stage maps into them.
    if (scheme.eligibilityBusinessStageValues.isNotEmpty) {
      final mappedStage = _mapBusinessStage(p.businessStage);
      final wantsStage = scheme.eligibilityBusinessStageValues
          .map((s) => s.toLowerCase())
          .toSet();
      if (mappedStage != null && wantsStage.contains(mappedStage)) {
        matchingReasons.add(
          'Business Stage: Your business stage (${p.businessStage}) matches.',
        );
        score += _wSectorStage;
      } else {
        needsEligibilityReview = true;
        missingRequirements.add(
          'Business Stage: This scheme targets ${scheme.eligibilityBusinessStageValues.join(', ')} businesses.',
        );
      }
    }

    // 6. Sector / interest overlap -- SUBSTANTIVE: the profile's industry
    //    literally appears in the scheme's sector / category / keywords, or
    //    both name the same taxonomy industry (so an industry typed in Hindi
    //    or Tamil -- "कपड़ा", "ஜவுளி" -- reaches English scheme text).
    if (p.businessIndustry.trim().length > 2) {
      final industry = p.businessIndustry.toLowerCase();
      final sectorHay =
          '${scheme.sector} ${scheme.category} ${scheme.searchKeywords}'
              .toLowerCase();
      var aligned = sectorHay.contains(industry);
      if (!aligned) {
        final profileIndustries =
            SchemeSearchTaxonomy.normalize(industry)['industries'] ?? const [];
        if (profileIndustries.isNotEmpty) {
          final schemeIndustries =
              SchemeSearchTaxonomy.normalize(sectorHay)['industries'] ??
              const [];
          aligned = profileIndustries.any(schemeIndustries.contains);
        }
      }
      if (aligned) {
        matchingReasons.add(
          'Sector: Aligned with your ${p.businessIndustry} focus.',
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
    if (_isFounderRole(p) && founderThemeWords.any(themeHay.contains)) {
      matchingReasons.add(
        'Focus: This scheme supports entrepreneurs/startups, which matches '
        'your profile.',
      );
      score += _wSectorStage;
    } else if (_isArtisanRole(p) && artisanThemeWords.any(themeHay.contains)) {
      matchingReasons.add(
        'Focus: This scheme supports artisans/craftspeople, which matches '
        'your profile.',
      );
      score += _wSectorStage;
    }

    // 7. Genuinely unconstrained scheme that matched nothing at all --
    //    keep it findable (search / browse) but well below the "For Me"
    //    bar. This is NOT a match, it is the absence of one.
    final usesFallbackScore = score == 0 && matchingReasons.isEmpty;
    if (usesFallbackScore) {
      score = 0.3;
      matchingReasons.add(
        'Relevance: No specific eligibility conflicts detected.',
      );
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
      restriction: restriction,
      needsEligibilityReview: needsEligibilityReview,
      usesFallbackScore: usesFallbackScore,
      matchingReasons: matchingReasons,
      missingRequirements: missingRequirements,
      missingDocuments: missingDocuments,
    );
  }

  static final _womenTarget = RegExp(r'\b(?:WOMEN|WOMAN|FEMALE)\b');
  static const _womenAudience = r'(?:WOMEN|WOMAN|FEMALE)(?:\s+ENTREPRENEURS?)?';
  static const _communityAudience =
      r'(?:SC\s*/\s*ST|SC|ST|SCHEDULED CASTES?|SCHEDULED TRIBES?)(?:\s+ENTREPRENEURS?)?';
  static final _alternateGenderAudience = RegExp(
    '\\b(?:$_womenAudience\\s+(?:AND/)?OR\\s+$_communityAudience|'
    '$_communityAudience\\s+(?:AND/)?OR\\s+$_womenAudience)\\b',
  );
  static final _scheduledCaste = RegExp(r'\b(?:SC|SCHEDULED CASTES?)\b');
  static final _scheduledTribe = RegExp(r'\b(?:ST|SCHEDULED TRIBES?)\b');

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
