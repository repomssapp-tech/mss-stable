import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/questionnaire.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../services/catalog/scheme_repository.dart';
import '../../services/questionnaire/questionnaire_answers_store.dart';
import '../../services/questionnaire/questionnaire_profile_prefill.dart';
import '../../services/questionnaire/questionnaire_qa_metrics.dart';
import '../../services/questionnaire/questionnaire_repository.dart';
import '../../services/questionnaire/questionnaire_recommendation_service.dart';
import '../../services/recommendation/indian_states.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import 'smart_assessment/assessment_sheet_header.dart';
import 'smart_assessment/questionnaire_field_control.dart';

export 'question_node.dart';

class SmartAssessmentBottomSheet extends StatefulWidget {
  final String cardTitle;
  final String cardType;
  final VoidCallback? onCompleted;
  final ValueChanged<Map<String, Object?>>? onAnswersCompleted;
  final bool editSavedAnswers;

  const SmartAssessmentBottomSheet({
    super.key,
    required this.cardTitle,
    required this.cardType,
    this.onCompleted,
    this.onAnswersCompleted,
    this.editSavedAnswers = false,
  });

  static void show(
    BuildContext context,
    String title,
    String type,
    ValueChanged<Map<String, Object?>> onCompleted, {
    bool editSavedAnswers = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartAssessmentBottomSheet(
        cardTitle: title,
        cardType: type,
        onAnswersCompleted: onCompleted,
        editSavedAnswers: editSavedAnswers,
      ),
    );
  }

  @override
  State<SmartAssessmentBottomSheet> createState() =>
      _SmartAssessmentBottomSheetState();
}

class _SmartAssessmentBottomSheetState
    extends State<SmartAssessmentBottomSheet> {
  final _repository = QuestionnaireRepository();
  final _store = QuestionnaireAnswersStore();
  final _qa = QuestionnaireQaMetrics.enabled ? QuestionnaireQaMetrics() : null;
  final Map<String, Object?> _answers = {};
  final List<String> _adaptiveFieldIds = [];
  List<Scheme> _candidateSchemes = const [];
  final Set<String> _profilePrefilled = {};
  late final Future<void> _ready;
  QuestionnaireDefinition? _definition;
  String _language = 'en';
  bool _usingGeneralScope = true;
  bool _candidateSchemesLoaded = false;
  int _currentIndex = 0;
  String? _saveError;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _ready = _loadQuestionnaire();
  }

  Future<void> _loadQuestionnaire() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final definition = await _repository.load();
    final saved = await _store.loadAnswers();
    final profile = provider.profile;
    _language = provider.selectedLanguage;
    _definition = definition;
    _answers.addAll(saved);

    final savedState = saved['general_state'];
    final profileState = _knownState(profile.state);
    final state = savedState is String
        ? savedState
        : profileState ??
              (widget.cardType == 'state'
                  ? _knownState(widget.cardTitle)
                  : null);
    _usingGeneralScope = _shouldUseGeneralScope(_language, state);

    for (final field in definition.allFields) {
      if (_answers.containsKey(field.id)) continue;
      final answer = QuestionnaireProfilePrefill.valueFor(field, profile);
      if (answer != null && _store.isValidAnswer(field, answer)) {
        _answers[field.id] = answer;
        _profilePrefilled.add(field.id);
      }
    }
    if (!_answers.containsKey('general_state') && widget.cardType == 'state') {
      final cardState = _knownState(widget.cardTitle);
      if (cardState != null) _answers['general_state'] = cardState;
    }
  }

  String? _knownState(String state) {
    final canonical = IndianStates.canonical(state);
    if (IndianStates.names.contains(canonical)) return canonical;
    final code = IndianStates.code(state);
    return code == null ? null : IndianStates.nameForCode(code);
  }

  bool _shouldUseGeneralScope(String language, String? state) =>
      language == 'ta' || state != 'Maharashtra';

  List<QuestionnaireField> _visibleFields() {
    final definition = _definition;
    if (definition == null) return const [];
    if (_usingGeneralScope) return definition.generalFields;

    const firstIds = ['scheme_goal', 'business_age', 'is_maharashtra_domicile'];
    final byId = {for (final field in definition.fields) field.id: field};
    return [
      ...firstIds.map((id) => byId[id]).whereType<QuestionnaireField>(),
      ..._adaptiveFieldIds
          .map((id) => byId[id])
          .whereType<QuestionnaireField>(),
    ];
  }

  List<QuestionnaireField> _adaptiveCandidates() {
    final definition = _definition;
    if (definition == null) return const [];
    final businessAge = _answers['business_age'];
    final requiredFor = businessAge == 'not_started_yet_aspiring'
        ? 'aspiring_msme'
        : 'existing_msme';
    const fixedIds = {'scheme_goal', 'business_age', 'is_maharashtra_domicile'};
    return definition.fields
        .where(
          (field) =>
              !fixedIds.contains(field.id) &&
              (field.requiredFor == 'both' ||
                  (businessAge is String && field.requiredFor == requiredFor)),
        )
        .toList(growable: false);
  }

  Future<void> _loadCandidateSchemes() async {
    if (_candidateSchemesLoaded) return;
    _candidateSchemesLoaded = true;
    try {
      _candidateSchemes = await SchemeRepository.instance.getAllSchemes();
    } catch (error) {
      debugPrint('[SmartAssessment] adaptive catalog unavailable: $error');
    }
  }

  QuestionnaireField? get _currentField {
    final fields = _visibleFields();
    if (_currentIndex >= fields.length) return null;
    return fields[_currentIndex];
  }

  void _changeAnswer(QuestionnaireField field, Object? answer) {
    final saveFailedMessage = context.l10n.questionnaireSaveFailed;
    setState(() {
      if (answer == null) {
        _answers.remove(field.id);
        _profilePrefilled.remove(field.id);
      } else {
        _answers[field.id] = answer;
      }
      _saveError = null;
    });
    _saveQueue = _saveQueue
        .then((_) async {
          if (answer != null && _store.isValidAnswer(field, answer)) {
            await _store.saveAnswer(field.id, answer);
          } else {
            await _store.clearAnswer(field.id);
          }
        })
        .catchError((Object error) {
          if (mounted) {
            setState(() => _saveError = saveFailedMessage);
          }
        });
  }

  Future<void> _advance({bool skipCurrent = false}) async {
    final field = _currentField;
    if (field == null) return;
    if (skipCurrent) _changeAnswer(field, null);
    await _saveQueue;
    if (!mounted || _saveError != null) return;
    final answer = _answers[field.id];
    _qa?.advance(
      field.id,
      answered: answer != null && _store.isValidAnswer(field, answer),
    );

    if (field.id == 'general_state' && _usingGeneralScope) {
      final selectedState = _answers[field.id] as String?;
      final shouldUseGeneral = _shouldUseGeneralScope(_language, selectedState);
      if (!shouldUseGeneral) {
        setState(() {
          _usingGeneralScope = false;
          _currentIndex = 0;
        });
        return;
      }
    }

    if (!_usingGeneralScope && _currentIndex >= 2 && _currentIndex < 6) {
      await _loadCandidateSchemes();
      if (!mounted || _saveError != null) return;
      final next = const QuestionnaireRecommendationService()
          .chooseNextQuestion(
            schemes: _candidateSchemes,
            fields: _adaptiveCandidates(),
            answers: _answers,
            excludedIds: {..._adaptiveFieldIds},
            includeAnswered: widget.editSavedAnswers,
          );
      if (next != null) {
        setState(() {
          _adaptiveFieldIds.add(next.id);
          _currentIndex++;
        });
        return;
      }
      await _finish();
      return;
    }

    final fields = _visibleFields();
    if (_currentIndex + 1 >= fields.length) {
      await _finish();
      return;
    }
    setState(() => _currentIndex++);
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    final saveFailedMessage = context.l10n.questionnaireSaveFailed;
    await _saveQueue;
    if (!mounted || _saveError != null) return;
    final fieldsById = {
      for (final field in _definition!.allFields) field.id: field,
    };
    final validAnswers = <String, Object?>{};
    for (final entry in _answers.entries) {
      final field = fieldsById[entry.key];
      if (field != null && _store.isValidAnswer(field, entry.value)) {
        validAnswers[entry.key] = entry.value;
      }
    }
    try {
      await _store.saveAnswers(validAnswers);
    } on ArgumentError {
      if (mounted) {
        setState(() => _saveError = saveFailedMessage);
      }
      return;
    } on StateError {
      if (mounted) {
        setState(() => _saveError = saveFailedMessage);
      }
      return;
    }
    _qa?.completed = true;
    navigator.pop();
    widget.onAnswersCompleted?.call(validAnswers);
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _qa?.reportRun();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(context, context.l10n.questionnaireLoadFailed);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return _questionnaire(context);
      },
    );
  }

  Widget _message(BuildContext context, String message) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ),
      ],
    ),
  );

  Widget _questionnaire(BuildContext context) {
    final fields = _visibleFields();
    final field = _currentField;
    if (field == null) {
      return _message(context, context.l10n.questionnaireLoadFailed);
    }
    _qa?.showField(field.id);

    final l10n = context.l10n;
    final maxQuestions = _usingGeneralScope ? fields.length : 7;
    final progress = ((_currentIndex + 1) / maxQuestions).clamp(0.0, 1.0);
    final cardTitle = CentralizedTranslator.instance.localizeTagFor(
      _language,
      widget.cardTitle,
    );
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 680),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AssessmentSheetHeader(
                  cardTitleLocalized: cardTitle,
                  rawCardTitle: widget.cardTitle,
                  cardType: widget.cardType,
                  themeColor: Theme.of(context).colorScheme.primary,
                  progress: progress,
                  stepLabel: l10n.assessStepLabel(
                    _currentIndex + 1,
                    fields.length,
                  ),
                  closeTooltip: l10n.close,
                  isTamil: _language == 'ta',
                  onClose: () => Navigator.pop(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  field.questionFor(_language),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_profilePrefilled.contains(field.id)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.questionnaireFromProfile,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                QuestionnaireFieldControl(
                  key: ValueKey(field.id),
                  field: field,
                  language: _language,
                  answer: _answers[field.id],
                  onChanged: (answer) => _changeAnswer(field, answer),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    if (_currentIndex > 0)
                      TextButton(onPressed: _goBack, child: Text(l10n.back)),
                    TextButton(
                      onPressed: () => _advance(skipCurrent: true),
                      child: Text(l10n.skip),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => _advance(),
                      child: Text(l10n.next),
                    ),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(l10n.assessSkipToResults),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBack() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }
}
