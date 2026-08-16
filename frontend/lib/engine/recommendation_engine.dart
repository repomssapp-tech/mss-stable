import '../models/user_profile.dart';
import '../models/scheme_model.dart';

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

  static RecommendationResult evaluate(UserProfile profile, Scheme scheme) {
    double score = 1.0;
    final matchingReasons = <String>[];
    final missingRequirements = <String>[];
    final missingDocuments = <String>[];

    // Get basic stats
    final age = profile.age;
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

    switch (scheme.id.toUpperCase()) {
      case 'NEEDS':
      case 'IN115':
        // State Match
        if (!isTN) {
          score = 0.0;
          missingRequirements.add(
            'Residency: This scheme is strictly for residents of Tamil Nadu.',
          );
        } else {
          matchingReasons.add('Location: You reside in Tamil Nadu.');
        }

        // Education Match
        if (profile.educationLevel == 'School') {
          score *= 0.2; // severe penalty
          missingRequirements.add(
            'Education: Requires a college Degree, Diploma, ITI, or Vocational Certificate.',
          );
        } else {
          matchingReasons.add(
            'Education: You hold a college degree/diploma (${profile.educationLevel}).',
          );
        }

        // First Gen Graduate Bonus
        if (profile.firstGenGraduate) {
          score = (score + 0.1).clamp(0.0, 1.0);
          matchingReasons.add(
            'Priority: You are a First-Generation Graduate (priority selection).',
          );
        }

        // Age limits
        // General: 21-35, Special (Women, SC/ST, BC, OBC, etc.): 21-45
        final maxAge = (isFemale || isSpecialCommunity) ? 45 : 35;
        if (age < 21 || age > maxAge) {
          score *= 0.3;
          missingRequirements.add(
            'Age: Your age ($age) is outside the eligible range of 21-$maxAge years.',
          );
        } else {
          matchingReasons.add(
            'Age: Your age ($age) is within the eligible range of 21-$maxAge years.',
          );
        }

        // Project Cost check
        // Eligible project cost: 10 Lakhs to 5 Crores
        if (profile.annualIncome > 50000000) {
          // arbitrary
          score *= 0.8;
        }
        matchingReasons.add(
          'Funding: Supports project costs from ₹10 Lakhs to ₹5 Crores.',
        );
        break;

      case 'PMEGP':
      case 'IN130':
        matchingReasons.add(
          'Age: Eligible for any citizen above 18 years (you are $age).',
        );

        // Education checks
        // VIII standard pass required for project >10L manufacturing or >5L service.
        // Since we don't have project cost input in profile, we check if education level is high enough.
        if (profile.educationLevel == 'School') {
          score *= 0.9;
          matchingReasons.add(
            'Education: VIII standard pass criteria applies for larger projects.',
          );
        } else {
          matchingReasons.add(
            'Education: You satisfy the minimum VIII standard pass requirement.',
          );
        }

        if (profile.state.toLowerCase() == 'tamil nadu') {
          matchingReasons.add(
            'Implementation: Supported in Tamil Nadu via DIC and KVIC offices.',
          );
        }
        break;

      case 'STANDUP_INDIA':
      case 'IN168':
        // Women or SC/ST
        final eligibleCategory = isFemale || isSCST;
        if (!eligibleCategory) {
          score = 0.0;
          missingRequirements.add(
            'Category: Stand-Up India is reserved for Women entrepreneurs and SC/ST category individuals.',
          );
        } else {
          if (isFemale) {
            matchingReasons.add(
              'Gender: You match the requirement for Women entrepreneurs.',
            );
          }
          if (isSCST) {
            matchingReasons.add(
              'Community: You match the requirement for SC/ST category borrowers.',
            );
          }
        }

        // Age
        if (age < 18) {
          score = 0.0;
          missingRequirements.add('Age: Must be at least 18 years old.');
        }

        matchingReasons.add(
          'Project Type: Facilitates greenfield projects between ₹10 Lakhs and ₹1 Crore.',
        );
        break;

      case 'MUDRA':
      case 'IN128':
        matchingReasons.add(
          'Eligibility: Open to all Indian citizens with a viable business plan.',
        );
        matchingReasons.add(
          'Collateral: 100% collateral-free loan up to ₹10 Lakhs.',
        );
        // High matching base score because Mudra is very general
        score = 1.0;
        break;

      case 'WEP':
      case 'IN212':
        if (!isFemale) {
          score *= 0.3;
          missingRequirements.add(
            'Gender: This platform is specifically designed to support Women Entrepreneurs.',
          );
        } else {
          matchingReasons.add(
            'Gender: Designed for women-led businesses and female founders.',
          );
        }
        matchingReasons.add(
          'Aggregation: Provides aggregated support for mentoring, incubation, and networking.',
        );
        break;

      case 'TREAD':
      case 'IN195':
        if (!isFemale) {
          score = 0.0;
          missingRequirements.add(
            'Gender: TREAD is exclusively for groups or individual Women seeking self-employment.',
          );
        } else {
          matchingReasons.add(
            'Gender: Exclusively supports women entrepreneur groups.',
          );
        }
        matchingReasons.add(
          'Funding structure: Government grants up to 30% of the project cost through registered NGOs.',
        );
        break;

      case 'KALAIGNAR_KAIVINAI':
      case 'IN074':
        if (!isTN) {
          score = 0.0;
          missingRequirements.add(
            'Residency: Strictly for artisans residing in Tamil Nadu.',
          );
        } else {
          matchingReasons.add('Location: You reside in Tamil Nadu.');
        }

        // Artisan check: if the profile lists "Artisan" or "Self-employed" as employment, or if community is special.
        // Since we removed Employment/Occupation, we check if they have general eligibility but flag Artisan Card.
        missingRequirements.add(
          'Artisan Status: Must hold a valid Pehchan Artisan Card from the Ministry of Textiles.',
        );
        score *=
            0.5; // lower match unless they explicitly select it in filters/search
        break;

      case 'STARTUP_TN':
      case 'IN182':
        if (!isTN) {
          score = 0.0;
          missingRequirements.add(
            'Residency: Startups must be incorporated or registered in Tamil Nadu.',
          );
        } else {
          matchingReasons.add(
            'Location: Available for startups incorporated in Tamil Nadu.',
          );
        }

        // General startup match
        missingRequirements.add(
          'DPIIT Recognition: Requires registration and recognition from DPIIT (Govt of India).',
        );
        score *= 0.7; // Needs DPIIT recognition
        matchingReasons.add(
          'Innovation: Offers TANSEED grants of up to ₹15 Lakhs.',
        );
        break;

      case 'POST_MATRIC':
        if (profile.employmentStatus.toLowerCase() != 'student') {
          score *= 0.5;
        } else {
          matchingReasons.add('Occupation: You are a Student.');
        }
        if (profile.community.toLowerCase() == 'general') {
          score *= 0.8;
          missingRequirements.add(
            'Community: Priority is given to SC, ST, OBC and Minority community students.',
          );
        } else {
          matchingReasons.add(
            'Community: You belong to a priority group (${profile.community}).',
          );
        }
        matchingReasons.add('Academic: Supports Class 11 to PhD levels.');
        break;

      case 'MERIT_MEANS':
        if (profile.employmentStatus.toLowerCase() != 'student') {
          score *= 0.4;
        }
        if (profile.annualIncome > 250000) {
          score *= 0.7;
          missingRequirements.add(
            'Income: Requires family annual income below ₹2.5 Lakhs.',
          );
        } else {
          matchingReasons.add(
            'Income: Your family income is below ₹2.5 Lakhs.',
          );
        }
        matchingReasons.add(
          'Academic: Designed for UG & PG professional courses.',
        );
        break;

      case 'INSPIRE':
        if (profile.employmentStatus.toLowerCase() != 'student') {
          score *= 0.3;
        }
        if (profile.age < 17 || profile.age > 22) {
          score *= 0.8;
          missingRequirements.add('Age: Designed for youth aged 17-22 years.');
        } else {
          matchingReasons.add('Age: You fit the age bracket of 17-22 years.');
        }
        matchingReasons.add(
          'Academic: For top 1% performers in Class 12 pursuing basic sciences.',
        );
        break;

      case 'PRAGATI':
        if (!isFemale) {
          score = 0.0;
          missingRequirements.add('Gender: Exclusively for female students.');
        } else {
          matchingReasons.add('Gender: Female candidate.');
        }
        if (profile.educationLevel != 'Undergraduate' &&
            profile.educationLevel != 'Diploma' &&
            profile.educationLevel != 'Postgraduate') {
          score *= 0.5;
          missingRequirements.add(
            'Academic: Designed for Diploma, UG or PG courses.',
          );
        } else {
          matchingReasons.add(
            'Academic: Enrolled in eligible level (${profile.educationLevel}).',
          );
        }
        break;

      default:
        // 1. State/Residency check
        if (scheme.state.isNotEmpty &&
            scheme.state.toLowerCase() != 'all india' &&
            scheme.state.toLowerCase() != 'pan-india' &&
            scheme.state.toLowerCase() != profile.state.toLowerCase()) {
          score = 0.0;
          missingRequirements.add(
            'Residency: This scheme is for residents of ${scheme.state}.',
          );
        } else {
          if (scheme.state.isNotEmpty &&
              scheme.state.toLowerCase() == profile.state.toLowerCase()) {
            matchingReasons.add(
              'Location: You reside in ${scheme.state} where this scheme is offered.',
            );
          }
        }

        // 2. Gender check -- structured eligibility.gender facet is
        // authoritative when the catalog actually asserts it (`applies`);
        // free-text targetBeneficiary keyword match is the fallback for
        // schemes where that facet wasn't populated, not a data conflict.
        final targetUpper = scheme.targetBeneficiary.toUpperCase();
        final hasWomenKeyword =
            targetUpper.contains('WOMEN') || targetUpper.contains('FEMALE');
        if (scheme.eligibilityGenderValues.isNotEmpty) {
          final wantsFemale = scheme.eligibilityGenderValues
              .any((v) => v.toLowerCase() == 'female');
          if (wantsFemale && !isFemale) {
            score = 0.0;
            missingRequirements.add(
              'Gender: This scheme is targeted towards Women/Female entrepreneurs.',
            );
          } else if (wantsFemale && isFemale) {
            matchingReasons.add(
              'Gender: You match the target female demographic.',
            );
          }
        } else if (hasWomenKeyword && !isFemale) {
          score = 0.0;
          missingRequirements.add(
            'Gender: This scheme is targeted towards Women/Female entrepreneurs.',
          );
        } else if (hasWomenKeyword && isFemale) {
          matchingReasons.add(
            'Gender: You match the target female demographic.',
          );
        }

        // 3. Special-category check -- structured eligibility.specialCategory
        // facet (sc/st/women/differently_abled/transgender/ex_servicemen/
        // minority) is authoritative when populated; free-text SC/ST keyword
        // match is the fallback. A mismatch is a soft penalty (priority
        // category, not always exclusive eligibility), never a hard zero.
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
            score *= 0.5;
            missingRequirements.add(
              'Community/Category: Priority is for ${scheme.specialCategories.join(', ')}.',
            );
          } else {
            matchingReasons.add(
              'Community/Category: Matches the ${overlap.join(', ')} priority category.',
            );
          }
        } else if (hasSCSTKeyword && !isSCST) {
          score *= 0.5;
          missingRequirements.add(
            'Community: Priority/eligibility is for SC/ST categories.',
          );
        } else if (hasSCSTKeyword && isSCST) {
          matchingReasons.add(
            'Community: Matches the SC/ST priority demographic.',
          );
        }

        // 4. Age check -- real, from eligibility.age.{minYears,maxYears}.
        if (scheme.eligibilityMinAge != null ||
            scheme.eligibilityMaxAge != null) {
          final minAge = scheme.eligibilityMinAge ?? 0;
          final maxAge = scheme.eligibilityMaxAge ?? 200;
          if (age < minAge || age > maxAge) {
            score *= 0.3;
            missingRequirements.add(
              'Age: Your age ($age) is outside the eligible range of $minAge-$maxAge years.',
            );
          } else {
            matchingReasons.add(
              'Age: Your age ($age) is within the eligible range of $minAge-$maxAge years.',
            );
          }
        }

        // 5. Business stage check -- real, from eligibility.businessStage.
        if (scheme.eligibilityBusinessStageValues.isNotEmpty) {
          final mappedStage = _mapBusinessStage(profile.businessStage);
          final wantsStage = scheme.eligibilityBusinessStageValues
              .map((s) => s.toLowerCase())
              .toSet();
          if (mappedStage != null && wantsStage.contains(mappedStage)) {
            matchingReasons.add(
              'Business Stage: Your business stage (${profile.businessStage}) matches.',
            );
          } else {
            score *= 0.7;
            missingRequirements.add(
              'Business Stage: This scheme targets ${scheme.eligibilityBusinessStageValues.join(', ')} businesses.',
            );
          }
        }

        // 6. No eligibility facet applied at all -- genuinely unconstrained,
        // not a fabricated per-scheme number. Every profile sees the same
        // (correct) result for a scheme with no restrictions.
        if (score > 0.0 && matchingReasons.isEmpty) {
          score = 0.7;
          matchingReasons.add(
            'Relevance: No specific eligibility conflicts detected.',
          );
        }
        break;
    }

    // Adjust score based on missing documents (slight penalty)
    if (score > 0.0 && missingDocuments.isNotEmpty) {
      // Scale score down slightly based on documents, but keep it high enough to recommend
      final docRatio =
          (scheme.requiredDocuments.length - missingDocuments.length) /
          scheme.requiredDocuments.length;
      score = (score * (0.8 + 0.2 * docRatio)).clamp(0.0, 1.0);
    }

    return RecommendationResult(
      score: score,
      matchingReasons: matchingReasons,
      missingRequirements: missingRequirements,
      missingDocuments: missingDocuments,
    );
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
