import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../utils/app_spacing.dart';
import 'question_node.dart';
import 'smart_assessment/assessment_profile_matcher.dart';
import 'smart_assessment/assessment_question_card.dart';
import 'smart_assessment/assessment_question_flows.dart';
import 'smart_assessment/assessment_sheet_footer.dart';
import 'smart_assessment/assessment_sheet_header.dart';

export 'question_node.dart';

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

  // Question flow for this category, state, or ministry
  late Map<String, QuestionNode> _questionFlow;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  void _initializeFlow() {
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    // The flow's translated fields follow the active language (Tamil or Hindi).
    final language = Provider.of<AppProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    final l10nTa = lookupAppLocalizations(
      Locale(language == 'hi' ? 'hi' : 'ta'),
    );

    final result = resolveQuestionFlow(
      cardTitle: widget.cardTitle,
      cardType: widget.cardType,
      l10nEn: l10nEn,
      l10nTa: l10nTa,
    );

    _questionFlow = result.flow;
    _currentQuestionId = result.initialQuestionId;

    _seedCurrentAnswerFromProfile();
  }

  /// Pre-select the answer for the current question when the onboarding
  /// profile already contains it (caste, income, gender, age, education,
  /// home-state domicile). The user still taps to confirm or change it --
  /// nothing is auto-submitted -- but they no longer re-enter data the app
  /// already has.
  void _seedCurrentAnswerFromProfile() {
    if (_answers.containsKey(_currentQuestionId)) return;
    final node = _questionFlow[_currentQuestionId];
    if (node == null) return;

    final profile = Provider.of<AppProvider>(context, listen: false).profile;
    final preset = AssessmentProfileMatcher.profileDefaultFor(
      node,
      profile,
      widget.cardTitle,
    );
    if (preset != null) _answers[_currentQuestionId] = preset;
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
    final result = AssessmentProfileMatcher.computeSubmissionResults(
      currentProfile: provider.profile,
      answers: _answers,
      questionFlow: _questionFlow,
      cardTitle: widget.cardTitle,
      cardType: widget.cardType,
    );

    result.applyToProvider(provider);
    Navigator.pop(context);
    widget.onCompleted();
  }

  String _getLocalizedCardTitle(String rawTitle, String language) {
    return CentralizedTranslator.instance.localizeTagFor(language, rawTitle);
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
    const totalSteps = 5;
    final currentStep = _questionHistory.length + 1;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    final stepLabel = l10n.assessStepLabel(currentStep, totalSteps);
    final backLabel = l10n.back;
    final skipLabel = l10n.assessSkipToResults;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
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
          AssessmentSheetHeader(
            cardTitleLocalized: cardTitleLocalized,
            rawCardTitle: widget.cardTitle,
            cardType: widget.cardType,
            themeColor: themeColor,
            progress: progress,
            stepLabel: stepLabel,
            closeTooltip: l10n.close,
            isTamil: isTamil,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AssessmentQuestionCard(
            currentQuestionId: _currentQuestionId,
            rawNode: rawNode,
            localizedNode: localizedNode,
            selectedAnswer: _answers[_currentQuestionId],
            themeColor: themeColor,
            isTamil: isTamil,
            onOptionSelected: _onOptionSelected,
          ),
          const SizedBox(height: AppSpacing.lg),
          AssessmentSheetFooter(
            showBackButton: _questionHistory.isNotEmpty,
            onBack: _goBack,
            onSubmit: _submitAnswers,
            themeColor: themeColor,
            isTamil: isTamil,
            backLabel: backLabel,
            skipLabel: skipLabel,
          ),
        ],
      ),
    );
  }
}
