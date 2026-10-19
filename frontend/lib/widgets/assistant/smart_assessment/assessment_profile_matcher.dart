import '../../../models/user_profile.dart';
import '../../../providers/app_state_provider.dart';
import '../question_node.dart';

/// Represents the calculated results of questionnaire submission.
class AssessmentSubmissionResult {
  final UserProfile updatedProfile;
  final String? stateFilter;
  final String? categoryFilter;
  final String? ministryFilter;
  final List<String> schemeTypes;
  final List<String> beneficiaries;

  const AssessmentSubmissionResult({
    required this.updatedProfile,
    this.stateFilter,
    this.categoryFilter,
    this.ministryFilter,
    required this.schemeTypes,
    required this.beneficiaries,
  });

  /// Applies the updated profile and filters to the [AppProvider].
  void applyToProvider(AppProvider provider) {
    provider.clearFilters();
    if (stateFilter != null) {
      provider.updateFilter('state', stateFilter);
    } else if (categoryFilter != null) {
      provider.updateFilter('category', categoryFilter);
    } else if (ministryFilter != null) {
      provider.updateFilter('ministry', ministryFilter);
    }
    if (schemeTypes.isNotEmpty) {
      provider.updateFilter('schemeTypes', schemeTypes);
    }
    if (beneficiaries.isNotEmpty) {
      provider.updateFilter('beneficiaries', beneficiaries);
    }
    provider.updateProfile(updatedProfile);
  }
}

/// Helper containing pure profile pre-seeding and answer submission calculation logic.
class AssessmentProfileMatcher {
  /// Returns the raw option string on [node] that matches the current
  /// profile, or null when the question is not one the profile can answer.
  static String? profileDefaultFor(
    QuestionNode node,
    UserProfile profile,
    String cardTitle,
  ) {
    final id = node.id.toLowerCase();
    final q = node.questionText.toLowerCase();

    String? pick(bool Function(String optLower) test) {
      for (final o in node.options) {
        if (test(o.toLowerCase())) return o;
      }
      return null;
    }

    // Gender
    if (id.contains('gender') || q.contains('your gender')) {
      final g = profile.gender.toLowerCase();
      if (g.contains('female') || g.contains('woman')) {
        return pick((o) => o.contains('female') || o.contains('women'));
      }
      if (g.contains('male') || g.contains('man')) {
        return pick((o) => o.contains('male') || o.contains('men'));
      }
      if (g.contains('trans') || g.contains('other')) {
        return pick((o) => o.contains('other') || o.contains('transgender'));
      }
      return null;
    }

    // Caste / social category
    if (id.contains('caste') ||
        id.contains('reservation') ||
        q.contains('caste') ||
        q.contains('social category') ||
        q.contains('reservation list')) {
      final c = profile.community.toLowerCase();
      if (c.isEmpty) return null;
      if (c.contains('scheduled') ||
          c == 'sc' ||
          c == 'st' ||
          c.contains('sc/') ||
          c.contains('/st') ||
          c.contains('sc ') ||
          c.contains(' st')) {
        return pick((o) => o.contains('sc') || o.contains('st'));
      }
      if (c.contains('obc') ||
          c.contains('bc') ||
          c.contains('sebc') ||
          c.contains('mbc') ||
          c.contains('backward')) {
        return pick(
          (o) =>
              o.contains('obc') ||
              o.contains('bc') ||
              o.contains('sebc') ||
              o.contains('backward'),
        );
      }
      if (c.contains('ews') || c.contains('minor')) {
        return pick((o) => o.contains('ews') || o.contains('minor'));
      }
      if (c.contains('general') || c.contains('open')) {
        return pick((o) => o.contains('general') || o.contains('open'));
      }
      return null;
    }

    // Annual income (household). Options are ascending brackets in lakhs.
    if (id.contains('income') ||
        (q.contains('annual') && q.contains('income'))) {
      final inc = profile.annualIncome;
      if (inc <= 0) return null;
      for (final o in node.options) {
        final ol = o.toLowerCase();
        final nums = RegExp(r'([\d.]+)')
            .allMatches(ol)
            .map((m) => double.tryParse(m.group(1)!) ?? 0)
            .where((n) => n > 0)
            .map((n) => n * 100000) // "lakhs"
            .toList();
        if (nums.isEmpty) continue;
        final isLower =
            ol.contains('under') || ol.contains('below') || ol.contains('less');
        final isUpper =
            ol.contains('over') || ol.contains('above') || ol.contains('more');
        if (isLower && inc < nums.first) return o;
        if (isUpper && inc >= nums.first) return o;
        if (!isLower && !isUpper && nums.length >= 2) {
          if (inc >= nums.first && inc <= nums.last) return o;
        }
      }
      return null;
    }

    // Applicant age (ministry flow).
    if (id == 'min_q2' || q.contains('current age')) {
      final dob = profile.dob;
      if (dob == null) return null;
      final now = DateTime.now();
      var age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      for (final o in node.options) {
        final ol = o.toLowerCase();
        final nums = RegExp(
          r'(\d+)',
        ).allMatches(ol).map((m) => int.parse(m.group(1)!)).toList();
        if (nums.isEmpty) continue;
        if (ol.contains('above') || ol.contains('+')) {
          if (age >= nums.first) return o;
        } else if (nums.length >= 2 && age >= nums.first && age <= nums.last) {
          return o;
        }
      }
      return null;
    }

    // Education level (education flow, first question).
    if (id == 'edu_q1' || q.contains('level of education')) {
      final e = profile.educationLevel.toLowerCase();
      if (e.isEmpty) return null;
      if (e.contains('phd') ||
          e.contains('ph.d') ||
          e.contains('doctor') ||
          e.contains('research')) {
        return pick((o) => o.contains('ph.d') || o.contains('research'));
      }
      if (e.contains('post') || e.contains('master') || e.contains('pg')) {
        return pick((o) => o.contains('postgraduate'));
      }
      if (e.contains('under') ||
          e.contains('bachelor') ||
          e.contains('ug') ||
          e.contains('graduat') ||
          e.contains('degree')) {
        return pick((o) => o.contains('undergraduate'));
      }
      if (e.contains('school') ||
          e.contains('12') ||
          e.contains('10') ||
          e.contains('secondary') ||
          e.contains('hsc') ||
          e.contains('sslc')) {
        return pick((o) => o.contains('schooling'));
      }
      return null;
    }

    // State domicile (state flow, first question).
    if (id == 'state_q1' || q.contains('permanent resident')) {
      final ps = profile.state.trim().toLowerCase();
      if (ps.isEmpty) return null;
      final card = cardTitle.trim().toLowerCase();
      final sameState =
          ps == card ||
          (card.isNotEmpty && (ps.contains(card) || card.contains(ps)));
      return pick(
        (o) => sameState
            ? (o.contains('yes') ||
                  o.contains('domicile') ||
                  o.contains('permanent'))
            : (o.contains('no') || o.contains('temporary')),
      );
    }

    return null;
  }

  /// Calculates the updated profile and filters from answered questions.
  static AssessmentSubmissionResult computeSubmissionResults({
    required UserProfile currentProfile,
    required Map<String, String> answers,
    required Map<String, QuestionNode> questionFlow,
    required String cardTitle,
    required String cardType,
  }) {
    String gender = currentProfile.gender;
    String state = currentProfile.state;
    String community = currentProfile.community;
    double income = currentProfile.annualIncome;
    String employment = currentProfile.employmentStatus;
    bool existingBiz = currentProfile.existingBusiness;
    String bizStage = currentProfile.businessStage;

    answers.forEach((qId, ans) {
      if (qId.contains('income') ||
          qId.contains('turnover') ||
          qId.endsWith('q5') ||
          qId.contains('q4_income')) {
        if (ans.contains('Under ₹1') ||
            ans.contains('Under ₹1.2') ||
            ans.contains('Under ₹1.5') ||
            ans.contains('Under ₹1.8')) {
          income = 120000.0;
        } else if (ans.contains('₹1.2') ||
            ans.contains('₹1.5') ||
            ans.contains('Under ₹2') ||
            ans.contains('Under ₹2.5')) {
          income = 200000.0;
        } else if (ans.contains('₹2.5') ||
            ans.contains('₹1.8 - ₹3') ||
            ans.contains('₹2 - ₹8') ||
            ans.contains('₹1.5 - ₹5')) {
          income = 450000.0;
        } else if (ans.contains('Over ₹8') ||
            ans.contains('Over ₹6') ||
            ans.contains('Over ₹10') ||
            ans.contains('Over ₹5')) {
          income = 900000.0;
        }
      }

      if (qId.contains('caste') ||
          qId.contains('category') ||
          qId.contains('reservation')) {
        if (ans.contains('SC')) {
          community = 'SC';
        } else if (ans.contains('ST')) {
          community = 'ST';
        } else if (ans.contains('OBC') ||
            ans.contains('BC') ||
            ans.contains('SEBC') ||
            ans.contains('MBC')) {
          community = 'OBC';
        } else if (ans.contains('EWS')) {
          community = 'EWS';
        } else {
          community = 'General';
        }
      }

      if (qId.contains('gender')) {
        if (ans.contains('Female') ||
            ans.contains('woman') ||
            ans.contains('Women')) {
          gender = 'Female';
        } else if (ans.contains('Male') ||
            ans.contains('man') ||
            ans.contains('Men')) {
          gender = 'Male';
        } else if (ans.contains('Other') || ans.contains('Transgender')) {
          gender = 'Other';
        }
      }

      if (qId.contains('livelihood') ||
          qId.contains('profession') ||
          qId.contains('occupation') ||
          qId.contains('employment')) {
        if (ans.contains('Farmer') || ans.contains('Agri')) {
          employment = 'Farmer';
        } else if (ans.contains('Student')) {
          employment = 'Student';
        } else if (ans.contains('Business') ||
            ans.contains('Startup') ||
            ans.contains('entrepreneur')) {
          employment = 'Business Owner';
        } else if (ans.contains('Self-employed') || ans.contains('artisan')) {
          employment = 'Self-employed';
        } else if (ans.contains('Unemployed') || ans.contains('Worker')) {
          employment = 'Unemployed';
        }
      }

      if (qId.contains('business') || qId.contains('startup')) {
        if (ans.contains('Yes')) existingBiz = true;
        if (ans.contains('Idea')) bizStage = 'Idea';
        if (ans.contains('Prototype')) bizStage = 'Prototype';
        if (ans.contains('Operational') || ans.contains('Registered')) {
          bizStage = 'Operational';
        }
      }
    });

    final Set<String> pickedSchemeTypes = {};
    final Set<String> pickedBeneficiaries = {};
    answers.forEach((qId, ans) {
      final a = ans.toLowerCase();
      final q = qId.toLowerCase();
      final qText = (questionFlow[qId]?.questionText ?? '').toLowerCase();
      final isGenderQ = q.contains('gender') || qText.contains('your gender');
      final isDemographicQ =
          q.contains('demographic') || qText.contains('woman or sc/st');

      if (a.contains('loan') ||
          a.contains('credit') ||
          a.contains('mudra') ||
          a.contains('kcc') ||
          a.contains('working capital') ||
          a.contains('micro-credit') ||
          a.contains('micro credit')) {
        pickedSchemeTypes.add('loans');
      }
      if (a.contains('guarantee') || a.contains('cgtmse')) {
        pickedSchemeTypes.add('guarantee');
      }
      if (a.contains('subsid') ||
          a.contains('subvention') ||
          a.contains('reimburs') ||
          a.contains('waiver') ||
          a.contains('margin money') ||
          a.contains('toolkit') ||
          a.contains('incentive')) {
        pickedSchemeTypes.add('subsidies');
      }
      if (a.contains('grant') ||
          a.contains('seed fund') ||
          a.contains('equity') ||
          a.contains('fellowship') ||
          a.contains('corpus') ||
          a.contains('cash transfer') ||
          a.contains('allowance') ||
          a.contains('pension') ||
          a.contains('scholarship')) {
        pickedSchemeTypes.add('grants');
      }
      if (a.contains('training') ||
          a.contains('pmkvy') ||
          a.contains('skill') ||
          a.contains('mentor') ||
          a.contains('incubat')) {
        pickedSchemeTypes.add('training');
      }
      if (a.contains('exhibition') ||
          a.contains('stall') ||
          a.contains('market') ||
          a.contains('export') ||
          a.contains('international fair') ||
          a.contains('trade')) {
        pickedSchemeTypes.add('market');
      }
      if (a.contains('infrastructure') ||
          a.contains('cluster') ||
          a.contains('hardware') ||
          a.contains('software infra')) {
        pickedSchemeTypes.add('infra');
      }

      if (isDemographicQ) {
        if (a.contains('woman') || a.contains('women')) {
          pickedBeneficiaries.add('women');
        }
        if (a.contains('sc/st') ||
            a.contains('sc / st') ||
            a.contains('scst')) {
          pickedBeneficiaries
            ..add('sc')
            ..add('st');
        }
      }
      if (q.startsWith('women')) {
        pickedBeneficiaries.add('women');
      }
      if (isGenderQ) {
        if (a.contains('female') || a.contains('women')) {
          pickedBeneficiaries.add('women');
        }
        if (a.contains('transgender') || a.contains('other')) {
          pickedBeneficiaries.add('transgender');
        }
      }
    });

    String? stateFilter;
    String? categoryFilter;
    String? ministryFilter;

    if (cardType == 'state') {
      state = cardTitle;
      stateFilter = state;
    } else if (cardType == 'category') {
      categoryFilter = cardTitle;
    } else if (cardType == 'ministry') {
      ministryFilter = cardTitle;
    }

    final updatedProfile = UserProfile(
      name: currentProfile.name,
      dob: currentProfile.dob,
      gender: gender,
      mobile: currentProfile.mobile,
      email: currentProfile.email,
      state: state,
      district: currentProfile.district,
      city: currentProfile.city,
      pinCode: currentProfile.pinCode,
      community: community,
      religion: currentProfile.religion,
      educationLevel: currentProfile.educationLevel,
      firstGenGraduate: currentProfile.firstGenGraduate,
      annualIncome: income,
      employmentStatus: employment,
      existingBusiness: existingBiz,
      businessStage: bizStage,
      businessIndustry: currentProfile.businessIndustry,
      fundingRequired: currentProfile.fundingRequired,
      registrationNumbers: currentProfile.registrationNumbers,
      profileCompleted: currentProfile.profileCompleted,
      disability: currentProfile.disability,
      language: currentProfile.language,
      navigationMode: currentProfile.navigationMode,
    );

    return AssessmentSubmissionResult(
      updatedProfile: updatedProfile,
      stateFilter: stateFilter,
      categoryFilter: categoryFilter,
      ministryFilter: ministryFilter,
      schemeTypes: pickedSchemeTypes.toList(),
      beneficiaries: pickedBeneficiaries.toList(),
    );
  }
}
