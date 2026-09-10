import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../models/user_profile.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../utils/responsive.dart';
import '../../utils/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';

/// Pre-localized questionnaire node for UI rendering.
class LocalizedQuestionNode {
  final String id;
  final String questionText;
  final String? subtitleText;
  final List<String> options;
  final QuestionNode rawNode;

  const LocalizedQuestionNode({
    required this.id,
    required this.questionText,
    this.subtitleText,
    required this.options,
    required this.rawNode,
  });

  String? nextId(String selectedLocalizedOption) {
    final index = options.indexOf(selectedLocalizedOption);
    final rawOption = (index >= 0 && index < rawNode.options.length)
        ? rawNode.options[index]
        : selectedLocalizedOption;
    return rawNode.nextId?.call(rawOption);
  }
}

/// Questionnaire node model supporting 3-tier localization:
/// Priority 1: Direct Tamil fields (questionTextTa, optionsTa, subtitleTextTa)
/// Priority 2: CentralizedTranslator fallback
/// Priority 3: English default
class QuestionNode {
  final String id;
  final String questionText;
  final String? questionTextTa;
  final String? subtitleText;
  final String? subtitleTextTa;
  final List<String> options;
  final List<String>? optionsTa;
  final String? Function(String selectedOption)? nextId;

  const QuestionNode({
    required this.id,
    required this.questionText,
    this.questionTextTa,
    this.subtitleText,
    this.subtitleTextTa,
    required this.options,
    this.optionsTa,
    this.nextId,
  });

  LocalizedQuestionNode toLocalized(String language) {
    final isTamil = language == 'ta';

    final String qText = isTamil
        ? ((questionTextTa != null && questionTextTa!.trim().isNotEmpty)
              ? questionTextTa!
              : CentralizedTranslator.instance.translate(questionText))
        : questionText;

    String? subText;
    if (subtitleText != null) {
      subText = isTamil
          ? ((subtitleTextTa != null && subtitleTextTa!.trim().isNotEmpty)
                ? subtitleTextTa!
                : CentralizedTranslator.instance.translate(subtitleText!))
          : subtitleText;
    }

    final List<String> locOptions = [];
    for (int i = 0; i < options.length; i++) {
      final rawOpt = options[i];
      if (isTamil) {
        if (optionsTa != null &&
            i < optionsTa!.length &&
            optionsTa![i].trim().isNotEmpty) {
          locOptions.add(optionsTa![i]);
        } else {
          locOptions.add(CentralizedTranslator.instance.translate(rawOpt));
        }
      } else {
        locOptions.add(rawOpt);
      }
    }

    return LocalizedQuestionNode(
      id: id,
      questionText: qText,
      subtitleText: subText,
      options: List.unmodifiable(locOptions),
      rawNode: this,
    );
  }
}

class SmartAssessmentBottomSheet extends StatefulWidget {
  final String cardTitle;
  final String cardType; // 'category', 'ministry', 'state'
  final VoidCallback onCompleted;

  const SmartAssessmentBottomSheet({
    super.key,
    required this.cardTitle,
    required this.cardType,
    required this.onCompleted,
  });

  static void show(
    BuildContext context,
    String title,
    String type,
    VoidCallback onCompleted,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartAssessmentBottomSheet(
        cardTitle: title,
        cardType: type,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<SmartAssessmentBottomSheet> createState() =>
      _SmartAssessmentBottomSheetState();
}

class _SmartAssessmentBottomSheetState
    extends State<SmartAssessmentBottomSheet> {
  late String _currentQuestionId;
  final Map<String, String> _answers = {};
  final List<String> _questionHistory = [];

  // Define Question Flows for different categories, states, and ministries
  late Map<String, QuestionNode> _questionFlow;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  void _initializeFlow() {
    final title = widget.cardTitle.toLowerCase().trim();
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    final l10nTa = lookupAppLocalizations(const Locale('ta'));

    if (widget.cardType == 'category') {
      if (title.contains('educat') ||
          title.contains('scholar') ||
          title.contains('student')) {
        _questionFlow = _getEducationFlow(l10nEn, l10nTa);
        _currentQuestionId = 'edu_q1';
      } else if (title.contains('women') ||
          title.contains('child') ||
          title.contains('matern')) {
        _questionFlow = _getWomenFlow(l10nEn, l10nTa);
        _currentQuestionId = 'women_q1';
      } else if (title.contains('agri') ||
          title.contains('farm') ||
          title.contains('crop')) {
        _questionFlow = _getAgricultureFlow(l10nEn, l10nTa);
        _currentQuestionId = 'agri_q1';
      } else if (title.contains('skill') ||
          title.contains('employ') ||
          title.contains('job')) {
        _questionFlow = _getSkillFlow(l10nEn, l10nTa);
        _currentQuestionId = 'skill_q1';
      } else if (title.contains('tech') ||
          title.contains('export') ||
          title.contains('trade')) {
        _questionFlow = _getTechExportFlow(l10nEn, l10nTa);
        _currentQuestionId = 'te_q1';
      } else if (title.contains('business') ||
          title.contains('msme') ||
          title.contains('start') ||
          title.contains('artisan') ||
          title.contains('loan') ||
          title.contains('credit')) {
        _questionFlow = _getBusinessFlow(l10nEn, l10nTa);
        _currentQuestionId = 'biz_q1';
      } else {
        _questionFlow = _getDefaultCategoryFlow(l10nEn, l10nTa);
        _currentQuestionId = 'cat_q1';
      }
    } else if (widget.cardType == 'state') {
      _questionFlow = _getStateFlow(widget.cardTitle, l10nEn, l10nTa);
      _currentQuestionId = 'state_q1';
    } else {
      _questionFlow = _getMinistryFlow(widget.cardTitle, l10nEn, l10nTa);
      _currentQuestionId = 'min_q1';
    }
    _seedCurrentAnswerFromProfile();
  }

  /// Pre-select the answer for the current question when the onboarding
  /// profile already contains it (caste, income, gender, age, education,
  /// home-state domicile). The user still taps to confirm or change it --
  /// nothing is auto-submitted -- but they no longer re-enter data the app
  /// already has. A no-op when the profile field is empty or the question
  /// asks something new.
  void _seedCurrentAnswerFromProfile() {
    if (_answers.containsKey(_currentQuestionId)) return;
    final node = _questionFlow[_currentQuestionId];
    if (node == null) return;
    final preset = _profileDefaultFor(node);
    if (preset != null) _answers[_currentQuestionId] = preset;
  }

  /// Returns the raw option string on [node] that matches the current
  /// profile, or null when the question is not one the profile can answer.
  String? _profileDefaultFor(QuestionNode node) {
    final p = Provider.of<AppProvider>(context, listen: false).profile;
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
      final g = p.gender.toLowerCase();
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
      final c = p.community.toLowerCase();
      if (c.isEmpty) return null;
      if (c.contains('scheduled') || c == 'sc' || c == 'st' ||
          c.contains('sc/') || c.contains('/st') || c.contains('sc ') ||
          c.contains(' st')) {
        return pick((o) => o.contains('sc') || o.contains('st'));
      }
      if (c.contains('obc') || c.contains('bc') || c.contains('sebc') ||
          c.contains('mbc') || c.contains('backward')) {
        return pick((o) =>
            o.contains('obc') || o.contains('bc') || o.contains('sebc') ||
            o.contains('backward'));
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
      final inc = p.annualIncome;
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
      final dob = p.dob;
      if (dob == null) return null;
      final now = DateTime.now();
      var age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      for (final o in node.options) {
        final ol = o.toLowerCase();
        final nums = RegExp(r'(\d+)')
            .allMatches(ol)
            .map((m) => int.parse(m.group(1)!))
            .toList();
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
      final e = p.educationLevel.toLowerCase();
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
      final ps = p.state.trim().toLowerCase();
      if (ps.isEmpty) return null;
      final card = widget.cardTitle.trim().toLowerCase();
      final sameState =
          ps == card || (card.isNotEmpty && (ps.contains(card) || card.contains(ps)));
      return pick((o) => sameState
          ? (o.contains('yes') || o.contains('domicile') || o.contains('permanent'))
          : (o.contains('no') || o.contains('temporary')));
    }

    return null;
  }

  Color _getThemeColor() {
    return const Color(0xFF2563EB); // Unified Royal Blue theme
  }

  void _onOptionSelected(
    String selectedLocalizedOption,
    LocalizedQuestionNode localizedNode,
  ) {
    setState(() {
      // Find raw option string for downstream answer logic
      final index = localizedNode.options.indexOf(selectedLocalizedOption);
      final rawOption =
          (index >= 0 && index < localizedNode.rawNode.options.length)
          ? localizedNode.rawNode.options[index]
          : selectedLocalizedOption;

      _answers[_currentQuestionId] = rawOption;
      _questionHistory.add(_currentQuestionId);

      final nextId = localizedNode.nextId(selectedLocalizedOption);

      if (nextId != null && _questionFlow.containsKey(nextId)) {
        _currentQuestionId = nextId;
        _seedCurrentAnswerFromProfile();
      } else {
        _submitAnswers();
      }
    });
  }

  void _goBack() {
    if (_questionHistory.isNotEmpty) {
      setState(() {
        _currentQuestionId = _questionHistory.removeLast();
        _answers.remove(_currentQuestionId);
        _seedCurrentAnswerFromProfile();
      });
    }
  }

  void _submitAnswers() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final profile = provider.profile;

    String gender = profile.gender;
    String state = profile.state;
    String community = profile.community;
    double income = profile.annualIncome;
    String employment = profile.employmentStatus;
    bool existingBiz = profile.existingBusiness;
    String bizStage = profile.businessStage;

    _answers.forEach((qId, ans) {
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
        } else if (ans.contains('Other') ||
            ans.contains('Transgender')) {
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

    // Turn the "what do you need" answers into real result filters so the
    // list the user lands on is actually narrowed by what they picked --
    // scheme-type facets from the intent questions, special-category facets
    // only from questions that explicitly target a beneficiary group.
    final Set<String> pickedSchemeTypes = {};
    final Set<String> pickedBeneficiaries = {};
    _answers.forEach((qId, ans) {
      final a = ans.toLowerCase();
      final q = qId.toLowerCase();
      final qText = (_questionFlow[qId]?.questionText ?? '').toLowerCase();
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
        if (a.contains('sc/st') || a.contains('sc / st') || a.contains('scst')) {
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

    provider.clearFilters();
    if (widget.cardType == 'state') {
      state = widget.cardTitle;
      provider.updateFilter('state', state);
    } else if (widget.cardType == 'category') {
      provider.updateFilter('category', widget.cardTitle);
    } else if (widget.cardType == 'ministry') {
      provider.updateFilter('ministry', widget.cardTitle);
    }
    if (pickedSchemeTypes.isNotEmpty) {
      provider.updateFilter('schemeTypes', pickedSchemeTypes.toList());
    }
    if (pickedBeneficiaries.isNotEmpty) {
      provider.updateFilter('beneficiaries', pickedBeneficiaries.toList());
    }

    final updatedProfile = UserProfile(
      name: profile.name,
      dob: profile.dob,
      gender: gender,
      mobile: profile.mobile,
      email: profile.email,
      state: state,
      district: profile.district,
      city: profile.city,
      pinCode: profile.pinCode,
      community: community,
      religion: profile.religion,
      educationLevel: profile.educationLevel,
      firstGenGraduate: profile.firstGenGraduate,
      annualIncome: income,
      employmentStatus: employment,
      existingBusiness: existingBiz,
      businessStage: bizStage,
      businessIndustry: profile.businessIndustry,
      fundingRequired: profile.fundingRequired,
      registrationNumbers: profile.registrationNumbers,
      profileCompleted: profile.profileCompleted,
      disability: profile.disability,
      language: profile.language,
      navigationMode: profile.navigationMode,
    );

    provider.updateProfile(updatedProfile);
    Navigator.pop(context);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final language = provider.selectedLanguage;
    final isTamil = language == 'ta';
    final l10n = context.l10n;

    final rawNode = _questionFlow[_currentQuestionId];
    if (rawNode == null) return const SizedBox.shrink();

    final localizedNode = rawNode.toLocalized(language);
    final cardTitleLocalized = _getLocalizedCardTitle(
      widget.cardTitle,
      language,
    );

    final themeColor = _getThemeColor();
    final totalSteps = 5;
    final currentStep = _questionHistory.length + 1;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    final stepLabel = l10n.assessStepLabel(currentStep, totalSteps);
    final backLabel = l10n.back;
    final skipLabel = l10n.assessSkipToResults;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: widget.cardType == 'state'
                          ? EdgeInsets.zero
                          : const EdgeInsets.all(AppSpacing.tight),
                      decoration: widget.cardType == 'state'
                          ? null
                          : BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                      child: widget.cardType == 'state'
                          ? Image.asset(
                              _getStateMapAsset(widget.cardTitle),
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return CustomPaint(
                                  size: const Size(32, 32),
                                  painter: StateMapPainter(widget.cardTitle),
                                );
                              },
                            )
                          : Icon(
                              widget.cardType == 'ministry'
                                  ? Icons.account_balance_rounded
                                  : Icons.grid_view_rounded,
                              color: themeColor,
                              size: 16,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        cardTitleLocalized,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          fontSize: isTamil ? 13.0 : 14.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: l10n.close,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFEFF6FF),
                    color: themeColor,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                stepLabel,
                style: GoogleFonts.inter(
                  fontSize: isTamil ? 9.5 : 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Animated Question Box
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<String>(_currentQuestionId),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedNode.questionText,
                  style: GoogleFonts.poppins(
                    fontSize: isTamil ? 13.8 : 15.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: isTamil ? 1.35 : 1.25,
                  ),
                ),
                if (localizedNode.subtitleText != null &&
                    localizedNode.subtitleText!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    localizedNode.subtitleText!,
                    style: GoogleFonts.inter(
                      fontSize: isTamil ? 10.5 : 11.5,
                      color: const Color(0xFF64748B),
                      height: isTamil ? 1.35 : 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Options list
                ...List.generate(localizedNode.options.length, (index) {
                  final optionLocalized = localizedNode.options[index];
                  final rawOption = rawNode.options[index];
                  final isSelected = _answers[_currentQuestionId] == rawOption;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          _onOptionSelected(optionLocalized, localizedNode),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.lg,
                        ),
                        alignment: Alignment.centerLeft,
                        backgroundColor: isSelected
                            ? themeColor.withValues(alpha: 0.06)
                            : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? themeColor
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        optionLocalized,
                        maxLines: 3,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.inter(
                          fontSize: isTamil ? 11.5 : 12.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? themeColor
                              : const Color(0xFF334155),
                          height: isTamil ? 1.35 : 1.25,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Footer controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_questionHistory.isNotEmpty)
                Flexible(
                  child: TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: FitOneLine(
                      child: Text(
                        backLabel,
                        style: GoogleFonts.inter(
                          fontSize: isTamil ? 11.0 : 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Flexible(
                child: TextButton(
                  onPressed: _submitAnswers,
                  style: TextButton.styleFrom(foregroundColor: themeColor),
                  child: FitOneLine(
                    child: Text(
                      skipLabel,
                      style: GoogleFonts.inter(
                        fontSize: isTamil ? 11.0 : 12.0,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocalizedCardTitle(String rawTitle, String language) {
    if (language != 'ta') return rawTitle;
    return CentralizedTranslator.instance.translateTag(rawTitle);
  }

  // --- QUESTION FLOW GENERATORS ---

  Map<String, QuestionNode> _getEducationFlow(
      AppLocalizations en, AppLocalizations ta) {
    return {
      'edu_q1': QuestionNode(
        id: 'edu_q1',
        questionText: en.assessEduQ1,
        questionTextTa: ta.assessEduQ1,
        options: [
          en.assessEduQ1Opt1,
          en.assessEduQ1Opt2,
          en.assessEduQ1Opt3,
          en.assessEduQ1Opt4,
        ],
        optionsTa: [
          ta.assessEduQ1Opt1,
          ta.assessEduQ1Opt2,
          ta.assessEduQ1Opt3,
          ta.assessEduQ1Opt4,
        ],
        nextId: (ans) => ans.contains("Schooling")
            ? "edu_q2_school"
            : ans.contains("Research")
            ? "edu_q2_research"
            : "edu_q2_college",
      ),
      'edu_q2_school': QuestionNode(
        id: 'edu_q2_school',
        questionText: en.assessEduQ2School,
        questionTextTa: ta.assessEduQ2School,
        options: [
          en.assessEduQ2SchoolOpt1,
          en.assessEduQ2SchoolOpt2,
          en.assessEduQ2SchoolOpt3,
        ],
        optionsTa: [
          ta.assessEduQ2SchoolOpt1,
          ta.assessEduQ2SchoolOpt2,
          ta.assessEduQ2SchoolOpt3,
        ],
        nextId: (_) => "edu_q3_school",
      ),
      'edu_q2_college': QuestionNode(
        id: 'edu_q2_college',
        questionText: en.assessEduQ2College,
        questionTextTa: ta.assessEduQ2College,
        options: [
          en.assessEduQ2CollegeOpt1,
          en.assessEduQ2CollegeOpt2,
          en.assessEduQ2CollegeOpt3,
          en.assessEduQ2CollegeOpt4,
        ],
        optionsTa: [
          ta.assessEduQ2CollegeOpt1,
          ta.assessEduQ2CollegeOpt2,
          ta.assessEduQ2CollegeOpt3,
          ta.assessEduQ2CollegeOpt4,
        ],
        nextId: (_) => "edu_q3_college",
      ),
      'edu_q2_research': QuestionNode(
        id: 'edu_q2_research',
        questionText: en.assessEduQ2Research,
        questionTextTa: ta.assessEduQ2Research,
        options: [
          en.assessEduQ2ResearchOpt1,
          en.assessEduQ2ResearchOpt2,
          en.assessEduQ2ResearchOpt3,
        ],
        optionsTa: [
          ta.assessEduQ2ResearchOpt1,
          ta.assessEduQ2ResearchOpt2,
          ta.assessEduQ2ResearchOpt3,
        ],
        nextId: (_) => "edu_q3_research",
      ),
      'edu_q3_school': QuestionNode(
        id: 'edu_q3_school',
        questionText: en.assessEduQ3School,
        questionTextTa: ta.assessEduQ3School,
        options: [
          en.assessEduQ3SchoolOpt1,
          en.assessEduQ3SchoolOpt2,
          en.assessEduQ3SchoolOpt3,
        ],
        optionsTa: [
          ta.assessEduQ3SchoolOpt1,
          ta.assessEduQ3SchoolOpt2,
          ta.assessEduQ3SchoolOpt3,
        ],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q3_college': QuestionNode(
        id: 'edu_q3_college',
        questionText: en.assessEduQ3College,
        questionTextTa: ta.assessEduQ3College,
        options: [
          en.assessEduQ3CollegeOpt1,
          en.assessEduQ3CollegeOpt2,
        ],
        optionsTa: [
          ta.assessEduQ3CollegeOpt1,
          ta.assessEduQ3CollegeOpt2,
        ],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q3_research': QuestionNode(
        id: 'edu_q3_research',
        questionText: en.assessEduQ3Research,
        questionTextTa: ta.assessEduQ3Research,
        options: [
          en.assessEduQ3ResearchOpt1,
          en.assessEduQ3ResearchOpt2,
          en.assessEduQ3ResearchOpt3,
        ],
        optionsTa: [
          ta.assessEduQ3ResearchOpt1,
          ta.assessEduQ3ResearchOpt2,
          ta.assessEduQ3ResearchOpt3,
        ],
        nextId: (_) => "edu_q4_caste",
      ),
      'edu_q4_caste': QuestionNode(
        id: 'edu_q4_caste',
        questionText: en.assessEduQ4Caste,
        questionTextTa: ta.assessEduQ4Caste,
        options: [
          en.assessEduQ4CasteOpt1,
          en.assessEduQ4CasteOpt2,
          en.assessEduQ4CasteOpt3,
          en.assessEduQ4CasteOpt4,
        ],
        optionsTa: [
          ta.assessEduQ4CasteOpt1,
          ta.assessEduQ4CasteOpt2,
          ta.assessEduQ4CasteOpt3,
          ta.assessEduQ4CasteOpt4,
        ],
        nextId: (_) => "edu_q5_income",
      ),
      'edu_q5_income': QuestionNode(
        id: 'edu_q5_income',
        questionText: en.assessEduQ5Income,
        questionTextTa: ta.assessEduQ5Income,
        options: [
          en.assessEduQ5IncomeOpt1,
          en.assessEduQ5IncomeOpt2,
          en.assessEduQ5IncomeOpt3,
        ],
        optionsTa: [
          ta.assessEduQ5IncomeOpt1,
          ta.assessEduQ5IncomeOpt2,
          ta.assessEduQ5IncomeOpt3,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getWomenFlow(
      AppLocalizations en, AppLocalizations ta) {
    return {
      'women_q1': QuestionNode(
        id: 'women_q1',
        questionText: en.assessWomenQ1,
        questionTextTa: ta.assessWomenQ1,
        options: [
          en.assessWomenQ1Opt1,
          en.assessWomenQ1Opt2,
          en.assessWomenQ1Opt3,
          en.assessWomenQ1Opt4,
        ],
        optionsTa: [
          ta.assessWomenQ1Opt1,
          ta.assessWomenQ1Opt2,
          ta.assessWomenQ1Opt3,
          ta.assessWomenQ1Opt4,
        ],
        nextId: (ans) => ans.contains("Mother")
            ? "women_q2_maternal"
            : ans.contains("Child")
            ? "women_q2_girl"
            : ans.contains("Entrepreneur")
            ? "women_q2_biz"
            : "women_q2_welfare",
      ),
      'women_q2_maternal': QuestionNode(
        id: 'women_q2_maternal',
        questionText: en.assessWomenQ2Maternal,
        questionTextTa: ta.assessWomenQ2Maternal,
        options: [
          en.assessWomenQ2MaternalOpt1,
          en.assessWomenQ2MaternalOpt2,
          en.assessWomenQ2MaternalOpt3,
        ],
        optionsTa: [
          ta.assessWomenQ2MaternalOpt1,
          ta.assessWomenQ2MaternalOpt2,
          ta.assessWomenQ2MaternalOpt3,
        ],
        nextId: (_) => "women_q3_matern_reg",
      ),
      'women_q2_girl': QuestionNode(
        id: 'women_q2_girl',
        questionText: en.assessWomenQ2Girl,
        questionTextTa: ta.assessWomenQ2Girl,
        options: [
          en.assessWomenQ2GirlOpt1,
          en.assessWomenQ2GirlOpt2,
          en.assessWomenQ2GirlOpt3,
        ],
        optionsTa: [
          ta.assessWomenQ2GirlOpt1,
          ta.assessWomenQ2GirlOpt2,
          ta.assessWomenQ2GirlOpt3,
        ],
        nextId: (ans) => ans.contains("Adolescent")
            ? "women_q3_girl_edu"
            : "women_q3_girl_save",
      ),
      'women_q2_biz': QuestionNode(
        id: 'women_q2_biz',
        questionText: en.assessWomenQ2Biz,
        questionTextTa: ta.assessWomenQ2Biz,
        options: [
          en.assessWomenQ2BizOpt1,
          en.assessWomenQ2BizOpt2,
        ],
        optionsTa: [
          ta.assessWomenQ2BizOpt1,
          ta.assessWomenQ2BizOpt2,
        ],
        nextId: (_) => "women_q3_biz_credit",
      ),
      'women_q2_welfare': QuestionNode(
        id: 'women_q2_welfare',
        questionText: en.assessWomenQ2Welfare,
        questionTextTa: ta.assessWomenQ2Welfare,
        options: [
          en.assessWomenQ2WelfareOpt1,
          en.assessWomenQ2WelfareOpt2,
        ],
        optionsTa: [
          ta.assessWomenQ2WelfareOpt1,
          ta.assessWomenQ2WelfareOpt2,
        ],
        nextId: (_) => "women_q3_welfare_pension",
      ),
      'women_q3_matern_reg': QuestionNode(
        id: 'women_q3_matern_reg',
        questionText: en.assessWomenQ3MaternReg,
        questionTextTa: ta.assessWomenQ3MaternReg,
        options: [
          en.assessWomenQ3MaternRegOpt1,
          en.assessWomenQ3MaternRegOpt2,
        ],
        optionsTa: [
          ta.assessWomenQ3MaternRegOpt1,
          ta.assessWomenQ3MaternRegOpt2,
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_girl_save': QuestionNode(
        id: 'women_q3_girl_save',
        questionText: en.assessWomenQ3GirlSave,
        questionTextTa: ta.assessWomenQ3GirlSave,
        options: [
          en.assessWomenQ3GirlSaveOpt1,
          en.assessWomenQ3GirlSaveOpt2,
        ],
        optionsTa: [
          ta.assessWomenQ3GirlSaveOpt1,
          ta.assessWomenQ3GirlSaveOpt2,
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_girl_edu': QuestionNode(
        id: 'women_q3_girl_edu',
        questionText: en.assessWomenQ3GirlEdu,
        questionTextTa: ta.assessWomenQ3GirlEdu,
        options: [
          en.assessWomenQ3GirlEduOpt1,
          en.assessWomenQ3GirlEduOpt2,
        ],
        optionsTa: [
          ta.assessWomenQ3GirlEduOpt1,
          ta.assessWomenQ3GirlEduOpt2,
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_biz_credit': QuestionNode(
        id: 'women_q3_biz_credit',
        questionText: en.assessWomenQ3BizCredit,
        questionTextTa: ta.assessWomenQ3BizCredit,
        options: [
          en.assessWomenQ3BizCreditOpt1,
          en.assessWomenQ3BizCreditOpt2,
          en.assessWomenQ3BizCreditOpt3,
        ],
        optionsTa: [
          ta.assessWomenQ3BizCreditOpt1,
          ta.assessWomenQ3BizCreditOpt2,
          ta.assessWomenQ3BizCreditOpt3,
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q3_welfare_pension': QuestionNode(
        id: 'women_q3_welfare_pension',
        questionText: en.assessWomenQ3WelfarePension,
        questionTextTa: ta.assessWomenQ3WelfarePension,
        options: [
          en.assessWomenQ3WelfarePensionOpt1,
          en.assessWomenQ3WelfarePensionOpt2,
        ],
        optionsTa: [
          ta.assessWomenQ3WelfarePensionOpt1,
          ta.assessWomenQ3WelfarePensionOpt2,
        ],
        nextId: (_) => "women_q4_caste",
      ),
      'women_q4_caste': QuestionNode(
        id: 'women_q4_caste',
        questionText: en.assessWomenQ4Caste,
        questionTextTa: ta.assessWomenQ4Caste,
        options: [
          en.assessWomenQ4CasteOpt1,
          en.assessWomenQ4CasteOpt2,
          en.assessWomenQ4CasteOpt3,
          en.assessWomenQ4CasteOpt4,
        ],
        optionsTa: [
          ta.assessWomenQ4CasteOpt1,
          ta.assessWomenQ4CasteOpt2,
          ta.assessWomenQ4CasteOpt3,
          ta.assessWomenQ4CasteOpt4,
        ],
        nextId: (_) => "women_q5_income",
      ),
      'women_q5_income': QuestionNode(
        id: 'women_q5_income',
        questionText: en.assessWomenQ5Income,
        questionTextTa: ta.assessWomenQ5Income,
        options: [
          en.assessWomenQ5IncomeOpt1,
          en.assessWomenQ5IncomeOpt2,
          en.assessWomenQ5IncomeOpt3,
        ],
        optionsTa: [
          ta.assessWomenQ5IncomeOpt1,
          ta.assessWomenQ5IncomeOpt2,
          ta.assessWomenQ5IncomeOpt3,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getBusinessFlow(
      AppLocalizations en, AppLocalizations ta) {
    return {
      'biz_q1': QuestionNode(
        id: 'biz_q1',
        questionText: en.assessBizQ1,
        questionTextTa: ta.assessBizQ1,
        options: [
          en.assessBizQ1Opt1,
          en.assessBizQ1Opt2,
          en.assessBizQ1Opt3,
          en.assessBizQ1Opt4,
        ],
        optionsTa: [
          ta.assessBizQ1Opt1,
          ta.assessBizQ1Opt2,
          ta.assessBizQ1Opt3,
          ta.assessBizQ1Opt4,
        ],
        nextId: (ans) => ans.contains("MSME")
            ? "biz_q2_msme"
            : ans.contains("Startup")
            ? "biz_q2_startup"
            : ans.contains("trader")
            ? "biz_q2_artisan"
            : "biz_q2_idea",
      ),
      'biz_q2_msme': QuestionNode(
        id: 'biz_q2_msme',
        questionText: en.assessBizQ2Msme,
        questionTextTa: ta.assessBizQ2Msme,
        options: [
          en.assessBizQ2MsmeOpt1,
          en.assessBizQ2MsmeOpt2,
          en.assessBizQ2MsmeOpt3,
        ],
        optionsTa: [
          ta.assessBizQ2MsmeOpt1,
          ta.assessBizQ2MsmeOpt2,
          ta.assessBizQ2MsmeOpt3,
        ],
        nextId: (_) => "biz_q3_msme_need",
      ),
      'biz_q2_startup': QuestionNode(
        id: 'biz_q2_startup',
        questionText: en.assessBizQ2Startup,
        questionTextTa: ta.assessBizQ2Startup,
        options: [
          en.assessBizQ2StartupOpt1,
          en.assessBizQ2StartupOpt2,
          en.assessBizQ2StartupOpt3,
        ],
        optionsTa: [
          ta.assessBizQ2StartupOpt1,
          ta.assessBizQ2StartupOpt2,
          ta.assessBizQ2StartupOpt3,
        ],
        nextId: (_) => "biz_q3_startup_need",
      ),
      'biz_q2_artisan': QuestionNode(
        id: 'biz_q2_artisan',
        questionText: en.assessBizQ2Artisan,
        questionTextTa: ta.assessBizQ2Artisan,
        options: [
          en.assessBizQ2ArtisanOpt1,
          en.assessBizQ2ArtisanOpt2,
        ],
        optionsTa: [
          ta.assessBizQ2ArtisanOpt1,
          ta.assessBizQ2ArtisanOpt2,
        ],
        nextId: (_) => "biz_q3_artisan_need",
      ),
      'biz_q2_idea': QuestionNode(
        id: 'biz_q2_idea',
        questionText: en.assessBizQ2Idea,
        questionTextTa: ta.assessBizQ2Idea,
        options: [
          en.assessBizQ2IdeaOpt1,
          en.assessBizQ2IdeaOpt2,
        ],
        optionsTa: [
          ta.assessBizQ2IdeaOpt1,
          ta.assessBizQ2IdeaOpt2,
        ],
        nextId: (_) => "biz_q3_msme_need",
      ),
      'biz_q3_msme_need': QuestionNode(
        id: 'biz_q3_msme_need',
        questionText: en.assessBizQ3MsmeNeed,
        questionTextTa: ta.assessBizQ3MsmeNeed,
        options: [
          en.assessBizQ3MsmeNeedOpt1,
          en.assessBizQ3MsmeNeedOpt2,
          en.assessBizQ3MsmeNeedOpt3,
        ],
        optionsTa: [
          ta.assessBizQ3MsmeNeedOpt1,
          ta.assessBizQ3MsmeNeedOpt2,
          ta.assessBizQ3MsmeNeedOpt3,
        ],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q3_startup_need': QuestionNode(
        id: 'biz_q3_startup_need',
        questionText: en.assessBizQ3StartupNeed,
        questionTextTa: ta.assessBizQ3StartupNeed,
        options: [
          en.assessBizQ3StartupNeedOpt1,
          en.assessBizQ3StartupNeedOpt2,
          en.assessBizQ3StartupNeedOpt3,
        ],
        optionsTa: [
          ta.assessBizQ3StartupNeedOpt1,
          ta.assessBizQ3StartupNeedOpt2,
          ta.assessBizQ3StartupNeedOpt3,
        ],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q3_artisan_need': QuestionNode(
        id: 'biz_q3_artisan_need',
        questionText: en.assessBizQ3ArtisanNeed,
        questionTextTa: ta.assessBizQ3ArtisanNeed,
        options: [
          en.assessBizQ3ArtisanNeedOpt1,
          en.assessBizQ3ArtisanNeedOpt2,
          en.assessBizQ3ArtisanNeedOpt3,
        ],
        optionsTa: [
          ta.assessBizQ3ArtisanNeedOpt1,
          ta.assessBizQ3ArtisanNeedOpt2,
          ta.assessBizQ3ArtisanNeedOpt3,
        ],
        nextId: (_) => "biz_q4_demographics",
      ),
      'biz_q4_demographics': QuestionNode(
        id: 'biz_q4_demographics',
        questionText: en.assessBizQ4Demographics,
        questionTextTa: ta.assessBizQ4Demographics,
        options: [
          en.assessBizQ4DemographicsOpt1,
          en.assessBizQ4DemographicsOpt2,
          en.assessBizQ4DemographicsOpt3,
          en.assessBizQ4DemographicsOpt4,
        ],
        optionsTa: [
          ta.assessBizQ4DemographicsOpt1,
          ta.assessBizQ4DemographicsOpt2,
          ta.assessBizQ4DemographicsOpt3,
          ta.assessBizQ4DemographicsOpt4,
        ],
        nextId: (_) => "biz_q5_turnover",
      ),
      'biz_q5_turnover': QuestionNode(
        id: 'biz_q5_turnover',
        questionText: en.assessBizQ5Turnover,
        questionTextTa: ta.assessBizQ5Turnover,
        options: [
          en.assessBizQ5TurnoverOpt1,
          en.assessBizQ5TurnoverOpt2,
          en.assessBizQ5TurnoverOpt3,
          en.assessBizQ5TurnoverOpt4,
        ],
        optionsTa: [
          ta.assessBizQ5TurnoverOpt1,
          ta.assessBizQ5TurnoverOpt2,
          ta.assessBizQ5TurnoverOpt3,
          ta.assessBizQ5TurnoverOpt4,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getAgricultureFlow(
      AppLocalizations en, AppLocalizations ta) {
    return {
      'agri_q1': QuestionNode(
        id: 'agri_q1',
        questionText: en.assessAgriQ1,
        questionTextTa: ta.assessAgriQ1,
        options: [
          en.assessAgriQ1Opt1,
          en.assessAgriQ1Opt2,
          en.assessAgriQ1Opt3,
          en.assessAgriQ1Opt4,
        ],
        optionsTa: [
          ta.assessAgriQ1Opt1,
          ta.assessAgriQ1Opt2,
          ta.assessAgriQ1Opt3,
          ta.assessAgriQ1Opt4,
        ],
        nextId: (_) => "agri_q2",
      ),
      'agri_q2': QuestionNode(
        id: 'agri_q2',
        questionText: en.assessAgriQ2,
        questionTextTa: ta.assessAgriQ2,
        options: [
          en.assessAgriQ2Opt1,
          en.assessAgriQ2Opt2,
          en.assessAgriQ2Opt3,
          en.assessAgriQ2Opt4,
        ],
        optionsTa: [
          ta.assessAgriQ2Opt1,
          ta.assessAgriQ2Opt2,
          ta.assessAgriQ2Opt3,
          ta.assessAgriQ2Opt4,
        ],
        nextId: (_) => "agri_q3_caste",
      ),
      'agri_q3_caste': QuestionNode(
        id: 'agri_q3_caste',
        questionText: en.assessAgriQ3Caste,
        questionTextTa: ta.assessAgriQ3Caste,
        options: [
          en.assessAgriQ3CasteOpt1,
          en.assessAgriQ3CasteOpt2,
          en.assessAgriQ3CasteOpt3,
          en.assessAgriQ3CasteOpt4,
        ],
        optionsTa: [
          ta.assessAgriQ3CasteOpt1,
          ta.assessAgriQ3CasteOpt2,
          ta.assessAgriQ3CasteOpt3,
          ta.assessAgriQ3CasteOpt4,
        ],
        nextId: (_) => "agri_q4_income",
      ),
      'agri_q4_income': QuestionNode(
        id: 'agri_q4_income',
        questionText: en.assessAgriQ4Income,
        questionTextTa: ta.assessAgriQ4Income,
        options: [
          en.assessAgriQ4IncomeOpt1,
          en.assessAgriQ4IncomeOpt2,
          en.assessAgriQ4IncomeOpt3,
        ],
        optionsTa: [
          ta.assessAgriQ4IncomeOpt1,
          ta.assessAgriQ4IncomeOpt2,
          ta.assessAgriQ4IncomeOpt3,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getSkillFlow(
      AppLocalizations en, AppLocalizations ta) {
    return {
      'skill_q1': QuestionNode(
        id: 'skill_q1',
        questionText: en.assessSkillQ1,
        questionTextTa: ta.assessSkillQ1,
        options: [
          en.assessSkillQ1Opt1,
          en.assessSkillQ1Opt2,
          en.assessSkillQ1Opt3,
          en.assessSkillQ1Opt4,
        ],
        optionsTa: [
          ta.assessSkillQ1Opt1,
          ta.assessSkillQ1Opt2,
          ta.assessSkillQ1Opt3,
          ta.assessSkillQ1Opt4,
        ],
        nextId: (_) => "skill_q2",
      ),
      'skill_q2': QuestionNode(
        id: 'skill_q2',
        questionText: en.assessSkillQ2,
        questionTextTa: ta.assessSkillQ2,
        options: [
          en.assessSkillQ2Opt1,
          en.assessSkillQ2Opt2,
          en.assessSkillQ2Opt3,
          en.assessSkillQ2Opt4,
        ],
        optionsTa: [
          ta.assessSkillQ2Opt1,
          ta.assessSkillQ2Opt2,
          ta.assessSkillQ2Opt3,
          ta.assessSkillQ2Opt4,
        ],
        nextId: (_) => "skill_q3",
      ),
      'skill_q3': QuestionNode(
        id: 'skill_q3',
        questionText: en.assessSkillQ3,
        questionTextTa: ta.assessSkillQ3,
        options: [
          en.assessSkillQ3Opt1,
          en.assessSkillQ3Opt2,
        ],
        optionsTa: [
          ta.assessSkillQ3Opt1,
          ta.assessSkillQ3Opt2,
        ],
        nextId: (_) => "skill_q4_income",
      ),
      'skill_q4_income': QuestionNode(
        id: 'skill_q4_income',
        questionText: en.assessSkillQ4Income,
        questionTextTa: ta.assessSkillQ4Income,
        options: [
          en.assessSkillQ4IncomeOpt1,
          en.assessSkillQ4IncomeOpt2,
          en.assessSkillQ4IncomeOpt3,
        ],
        optionsTa: [
          ta.assessSkillQ4IncomeOpt1,
          ta.assessSkillQ4IncomeOpt2,
          ta.assessSkillQ4IncomeOpt3,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getTechExportFlow(
      AppLocalizations en, AppLocalizations ta) {
    return {
      'te_q1': QuestionNode(
        id: 'te_q1',
        questionText: en.assessTeQ1,
        questionTextTa: ta.assessTeQ1,
        options: [
          en.assessTeQ1Opt1,
          en.assessTeQ1Opt2,
          en.assessTeQ1Opt3,
          en.assessTeQ1Opt4,
        ],
        optionsTa: [
          ta.assessTeQ1Opt1,
          ta.assessTeQ1Opt2,
          ta.assessTeQ1Opt3,
          ta.assessTeQ1Opt4,
        ],
        nextId: (_) => "te_q2",
      ),
      'te_q2': QuestionNode(
        id: 'te_q2',
        questionText: en.assessTeQ2,
        questionTextTa: ta.assessTeQ2,
        options: [
          en.assessTeQ2Opt1,
          en.assessTeQ2Opt2,
          en.assessTeQ2Opt3,
          en.assessTeQ2Opt4,
        ],
        optionsTa: [
          ta.assessTeQ2Opt1,
          ta.assessTeQ2Opt2,
          ta.assessTeQ2Opt3,
          ta.assessTeQ2Opt4,
        ],
        nextId: (_) => "te_q3_turnover",
      ),
      'te_q3_turnover': QuestionNode(
        id: 'te_q3_turnover',
        questionText: en.assessTeQ3Turnover,
        questionTextTa: ta.assessTeQ3Turnover,
        options: [
          en.assessTeQ3TurnoverOpt1,
          en.assessTeQ3TurnoverOpt2,
          en.assessTeQ3TurnoverOpt3,
        ],
        optionsTa: [
          ta.assessTeQ3TurnoverOpt1,
          ta.assessTeQ3TurnoverOpt2,
          ta.assessTeQ3TurnoverOpt3,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getDefaultCategoryFlow(
      AppLocalizations en, AppLocalizations ta) {
    return {
      'cat_q1': QuestionNode(
        id: 'cat_q1',
        questionText: en.assessCatQ1,
        questionTextTa: ta.assessCatQ1,
        options: [
          en.assessCatQ1Opt1,
          en.assessCatQ1Opt2,
          en.assessCatQ1Opt3,
          en.assessCatQ1Opt4,
        ],
        optionsTa: [
          ta.assessCatQ1Opt1,
          ta.assessCatQ1Opt2,
          ta.assessCatQ1Opt3,
          ta.assessCatQ1Opt4,
        ],
        nextId: (_) => "cat_q2",
      ),
      'cat_q2': QuestionNode(
        id: 'cat_q2',
        questionText: en.assessCatQ2,
        questionTextTa: ta.assessCatQ2,
        options: [
          en.assessCatQ2Opt1,
          en.assessCatQ2Opt2,
          en.assessCatQ2Opt3,
        ],
        optionsTa: [
          ta.assessCatQ2Opt1,
          ta.assessCatQ2Opt2,
          ta.assessCatQ2Opt3,
        ],
        nextId: (_) => "cat_q3",
      ),
      'cat_q3': QuestionNode(
        id: 'cat_q3',
        questionText: en.assessCatQ3,
        questionTextTa: ta.assessCatQ3,
        options: [
          en.assessCatQ3Opt1,
          en.assessCatQ3Opt2,
          en.assessCatQ3Opt3,
        ],
        optionsTa: [
          ta.assessCatQ3Opt1,
          ta.assessCatQ3Opt2,
          ta.assessCatQ3Opt3,
        ],
        nextId: (_) => "cat_q4",
      ),
      'cat_q4': QuestionNode(
        id: 'cat_q4',
        questionText: en.assessCatQ4,
        questionTextTa: ta.assessCatQ4,
        options: [
          en.assessCatQ4Opt1,
          en.assessCatQ4Opt2,
          en.assessCatQ4Opt3,
          en.assessCatQ4Opt4,
        ],
        optionsTa: [
          ta.assessCatQ4Opt1,
          ta.assessCatQ4Opt2,
          ta.assessCatQ4Opt3,
          ta.assessCatQ4Opt4,
        ],
        nextId: (_) => "cat_q5",
      ),
      'cat_q5': QuestionNode(
        id: 'cat_q5',
        questionText: en.assessCatQ5,
        questionTextTa: ta.assessCatQ5,
        options: [
          en.assessCatQ5Opt1,
          en.assessCatQ5Opt2,
          en.assessCatQ5Opt3,
        ],
        optionsTa: [
          ta.assessCatQ5Opt1,
          ta.assessCatQ5Opt2,
          ta.assessCatQ5Opt3,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getStateFlow(
      String stateName, AppLocalizations en, AppLocalizations ta) {
    return {
      'state_q1': QuestionNode(
        id: 'state_q1',
        questionText: en.assessStateQ1(stateName),
        questionTextTa: ta.assessStateQ1(stateName),
        options: [
          en.assessStateQ1Opt1,
          en.assessStateQ1Opt2,
        ],
        optionsTa: [
          ta.assessStateQ1Opt1,
          ta.assessStateQ1Opt2,
        ],
        nextId: (_) => "state_q2",
      ),
      'state_q2': QuestionNode(
        id: 'state_q2',
        questionText: en.assessStateQ2(stateName),
        questionTextTa: ta.assessStateQ2(stateName),
        options: [
          en.assessStateQ2Opt1,
          en.assessStateQ2Opt2,
          en.assessStateQ2Opt3,
          en.assessStateQ2Opt4,
        ],
        optionsTa: [
          ta.assessStateQ2Opt1,
          ta.assessStateQ2Opt2,
          ta.assessStateQ2Opt3,
          ta.assessStateQ2Opt4,
        ],
        nextId: (_) => "state_q3",
      ),
      'state_q3': QuestionNode(
        id: 'state_q3',
        questionText: en.assessStateQ3(stateName),
        questionTextTa: ta.assessStateQ3(stateName),
        options: [
          en.assessStateQ3Opt1,
          en.assessStateQ3Opt2,
          en.assessStateQ3Opt3,
          en.assessStateQ3Opt4,
        ],
        optionsTa: [
          ta.assessStateQ3Opt1,
          ta.assessStateQ3Opt2,
          ta.assessStateQ3Opt3,
          ta.assessStateQ3Opt4,
        ],
        nextId: (_) => "state_q4",
      ),
      'state_q4': QuestionNode(
        id: 'state_q4',
        questionText: en.assessStateQ4,
        questionTextTa: ta.assessStateQ4,
        options: [
          en.assessStateQ4Opt1,
          en.assessStateQ4Opt2,
          en.assessStateQ4Opt3,
          en.assessStateQ4Opt4,
        ],
        optionsTa: [
          ta.assessStateQ4Opt1,
          ta.assessStateQ4Opt2,
          ta.assessStateQ4Opt3,
          ta.assessStateQ4Opt4,
        ],
        nextId: (_) => "state_q5",
      ),
      'state_q5': QuestionNode(
        id: 'state_q5',
        questionText: en.assessStateQ5,
        questionTextTa: ta.assessStateQ5,
        options: [
          en.assessStateQ5Opt1,
          en.assessStateQ5Opt2,
          en.assessStateQ5Opt3,
        ],
        optionsTa: [
          ta.assessStateQ5Opt1,
          ta.assessStateQ5Opt2,
          ta.assessStateQ5Opt3,
        ],
        nextId: (_) => null,
      ),
    };
  }

  Map<String, QuestionNode> _getMinistryFlow(
      String ministryName, AppLocalizations en, AppLocalizations ta) {
    return {
      'min_q1': QuestionNode(
        id: 'min_q1',
        questionText: en.assessMinQ1,
        questionTextTa: ta.assessMinQ1,
        options: [
          en.assessMinQ1Opt1,
          en.assessMinQ1Opt2,
          en.assessMinQ1Opt3,
          en.assessMinQ1Opt4,
        ],
        optionsTa: [
          ta.assessMinQ1Opt1,
          ta.assessMinQ1Opt2,
          ta.assessMinQ1Opt3,
          ta.assessMinQ1Opt4,
        ],
        nextId: (_) => "min_q2",
      ),
      'min_q2': QuestionNode(
        id: 'min_q2',
        questionText: en.assessMinQ2,
        questionTextTa: ta.assessMinQ2,
        options: [
          en.assessMinQ2Opt1,
          en.assessMinQ2Opt2,
          en.assessMinQ2Opt3,
        ],
        optionsTa: [
          ta.assessMinQ2Opt1,
          ta.assessMinQ2Opt2,
          ta.assessMinQ2Opt3,
        ],
        nextId: (_) => "min_q3",
      ),
      'min_q3': QuestionNode(
        id: 'min_q3',
        questionText: en.assessMinQ3,
        questionTextTa: ta.assessMinQ3,
        options: [
          en.assessMinQ3Opt1,
          en.assessMinQ3Opt2,
        ],
        optionsTa: [
          ta.assessMinQ3Opt1,
          ta.assessMinQ3Opt2,
        ],
        nextId: (_) => "min_q4",
      ),
      'min_q4': QuestionNode(
        id: 'min_q4',
        questionText: en.assessMinQ4,
        questionTextTa: ta.assessMinQ4,
        options: [
          en.assessMinQ4Opt1,
          en.assessMinQ4Opt2,
          en.assessMinQ4Opt3,
          en.assessMinQ4Opt4,
        ],
        optionsTa: [
          ta.assessMinQ4Opt1,
          ta.assessMinQ4Opt2,
          ta.assessMinQ4Opt3,
          ta.assessMinQ4Opt4,
        ],
        nextId: (_) => "min_q5",
      ),
      'min_q5': QuestionNode(
        id: 'min_q5',
        questionText: en.assessMinQ5,
        questionTextTa: ta.assessMinQ5,
        options: [
          en.assessMinQ5Opt1,
          en.assessMinQ5Opt2,
          en.assessMinQ5Opt3,
        ],
        optionsTa: [
          ta.assessMinQ5Opt1,
          ta.assessMinQ5Opt2,
          ta.assessMinQ5Opt3,
        ],
        nextId: (_) => null,
      ),
    };
  }
}

String _getStateMapAsset(String stateName) {
  final rawPath = _getStateMapAssetRaw(stateName);
  return rawPath.replaceAll(
    'assets/images/States and UTs/',
    'assets/images/States assets/',
  );
}

String _getStateMapAssetRaw(String stateName) {
  switch (stateName.toLowerCase().trim()) {
    case 'tamil nadu':
      return 'assets/images/States and UTs/States/Tamil nadu.webp';
    case 'maharashtra':
      return 'assets/images/States and UTs/States/maharashtra.webp';
    case 'uttar pradesh':
      return 'assets/images/States and UTs/States/uttar_pradesh.webp';
    case 'karnataka':
      return 'assets/images/States and UTs/States/karnataka.webp';
    case 'gujarat':
      return 'assets/images/States and UTs/States/gujarat.webp';
    case 'arunachal pradesh':
      return 'assets/images/States and UTs/States/Anrunachal pradhesh.webp';
    case 'assam':
      return 'assets/images/States and UTs/States/Assam.webp';
    case 'bihar':
      return 'assets/images/States and UTs/States/Bihar.webp';
    case 'chhattisgarh':
      return 'assets/images/States and UTs/States/Chhatishgar.webp';
    case 'kerala':
      return 'assets/images/States and UTs/States/Kerala.webp';
    case 'andhra pradesh':
      return 'assets/images/States and UTs/States/andhra pradesh.webp';
    case 'goa':
      return 'assets/images/States and UTs/States/goa.webp';
    case 'haryana':
      return 'assets/images/States and UTs/States/haryana.webp';
    case 'himachal pradesh':
      return 'assets/images/States and UTs/States/himachal pradesh.webp';
    case 'jharkhand':
      return 'assets/images/States and UTs/States/jharkhand.webp';
    case 'madhya pradesh':
      return 'assets/images/States and UTs/States/madhya pradesh.webp';
    case 'manipur':
      return 'assets/images/States and UTs/States/manipur.webp';
    case 'meghalaya':
      return 'assets/images/States and UTs/States/meghalaya.webp';
    case 'mizoram':
      return 'assets/images/States and UTs/States/mizoram.webp';
    case 'nagaland':
      return 'assets/images/States and UTs/States/nagaland.webp';
    case 'odisha':
      return 'assets/images/States and UTs/States/odisha.webp';
    case 'punjab':
      return 'assets/images/States and UTs/States/punjab.webp';
    case 'rajasthan':
      return 'assets/images/States and UTs/States/rajasthan.webp';
    case 'sikkim':
      return 'assets/images/States and UTs/States/sikkim.webp';
    case 'telangana':
      return 'assets/images/States and UTs/States/telangana.webp';
    case 'tripura':
      return 'assets/images/States and UTs/States/tripura.webp';
    case 'uttarakhand':
    case 'uttarkhand':
      return 'assets/images/States and UTs/States/uttarkhand.webp';
    case 'west bengal':
      return 'assets/images/States and UTs/States/west bengal.webp';
    default:
      return 'assets/images/States and UTs/States/Tamil nadu.webp';
  }
}

class StateMapPainter extends CustomPainter {
  final String stateName;
  StateMapPainter(this.stateName);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (stateName == 'Tamil Nadu') {
      path.moveTo(w * 0.2, h * 0.1);
      path.quadraticBezierTo(w * 0.6, h * 0.05, w * 0.85, h * 0.15);
      path.lineTo(w * 0.8, h * 0.55);
      path.quadraticBezierTo(w * 0.65, h * 0.85, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.35, h * 0.85, w * 0.25, h * 0.55);
      path.close();
    } else if (stateName == 'Maharashtra') {
      path.moveTo(w * 0.1, h * 0.4);
      path.lineTo(w * 0.3, h * 0.15);
      path.lineTo(w * 0.75, h * 0.2);
      path.lineTo(w * 0.9, h * 0.38);
      path.lineTo(w * 0.82, h * 0.78);
      path.lineTo(w * 0.48, h * 0.82);
      path.lineTo(w * 0.2, h * 0.65);
      path.close();
    } else if (stateName == 'Uttar Pradesh') {
      path.moveTo(w * 0.08, h * 0.35);
      path.lineTo(w * 0.35, h * 0.2);
      path.lineTo(w * 0.8, h * 0.25);
      path.lineTo(w * 0.92, h * 0.5);
      path.lineTo(w * 0.72, h * 0.78);
      path.lineTo(w * 0.52, h * 0.68);
      path.lineTo(w * 0.32, h * 0.78);
      path.lineTo(w * 0.18, h * 0.52);
      path.close();
    } else if (stateName == 'Karnataka') {
      path.moveTo(w * 0.35, h * 0.08);
      path.quadraticBezierTo(w * 0.75, h * 0.22, w * 0.6, h * 0.52);
      path.quadraticBezierTo(w * 0.8, h * 0.72, w * 0.65, h * 0.92);
      path.lineTo(w * 0.4, h * 0.88);
      path.quadraticBezierTo(w * 0.2, h * 0.58, w * 0.35, h * 0.32);
      path.close();
    } else if (stateName == 'Gujarat') {
      path.moveTo(w * 0.25, h * 0.22);
      path.lineTo(w * 0.52, h * 0.12);
      path.lineTo(w * 0.78, h * 0.22);
      path.lineTo(w * 0.82, h * 0.52);
      path.lineTo(w * 0.58, h * 0.82);
      path.lineTo(w * 0.42, h * 0.58);
      path.lineTo(w * 0.12, h * 0.48);
      path.lineTo(w * 0.22, h * 0.34);
      path.close();
    } else {
      path.moveTo(w * 0.5, h * 0.1);
      path.quadraticBezierTo(w * 0.8, h * 0.1, w * 0.8, h * 0.45);
      path.quadraticBezierTo(w * 0.8, h * 0.75, w * 0.5, h * 0.95);
      path.quadraticBezierTo(w * 0.2, h * 0.75, w * 0.2, h * 0.45);
      path.quadraticBezierTo(w * 0.2, h * 0.1, w * 0.5, h * 0.1);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
