import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/analytics/app_analytics.dart';
import '../../models/questionnaire.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../services/questionnaire/assessment_fields.dart';
import '../../services/questionnaire/questionnaire_answers_store.dart';
import '../../services/questionnaire/questionnaire_profile_prefill.dart';
import '../../services/questionnaire/questionnaire_qa_metrics.dart';
import '../../services/questionnaire/questionnaire_repository.dart';
import '../../services/recommendation/profile_canonicalizer.dart';
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
  final String? interactionId;
  final ValueChanged<Map<String, Object?>>? onAnswersCompleted;

  const SmartAssessmentBottomSheet({
    super.key,
    required this.cardTitle,
    required this.cardType,
    this.onCompleted,
    this.interactionId,
    this.onAnswersCompleted,
  });

  static void show(
    BuildContext context,
    String title,
    String type,
    void Function(Map<String, Object?> answers, String? interactionId)
    onCompleted, {
    String? source,
  }) {
    final analytics = AppAnalytics.instance;
    final interactionId = analytics.interactionId();
    analytics.track(
      AnalyticsEvent.questionnaireStarted,
      interactionId: interactionId,
      properties: {'source': source ?? type},
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartAssessmentBottomSheet(
        cardTitle: title,
        cardType: type,
        interactionId: interactionId,
        onAnswersCompleted: (answers) => onCompleted(answers, interactionId),
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
  final Set<String> _profilePrefilled = {};
  late final Future<void> _ready;
  late final List<QuestionnaireField> _categoryFields;
  String _language = 'en';
  int _currentIndex = 0;
  bool _completed = false;
  final _shownFields = <String>{};
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
    final profile = ProfileCanonicalizer.canonicalize(provider.profile);
    _language = provider.selectedLanguage;
    _categoryFields = assessmentFields(
      definition,
      title: widget.cardTitle,
      cardType: widget.cardType,
    );
    _answers.addAll(saved);

    for (final field in definition.allFields) {
      final answer = QuestionnaireProfilePrefill.valueFor(field, profile);
      if (answer != null && _store.isValidAnswer(field, answer)) {
        _answers[field.id] = answer;
        _profilePrefilled.add(field.id);
      }
    }
    final area = QuestionnaireProfilePrefill.businessArea(profile);
    if (area != null) _answers['business_location'] = {'area': area};
  }

  List<QuestionnaireField> _relevantFields() {
    final businessAge = _answers['business_age'];
    return _categoryFields.where((field) {
      return field.requiredFor == 'both' ||
          businessAge == null ||
          field.requiredFor ==
              (businessAge == 'not_started_yet_aspiring'
                  ? 'aspiring_msme'
                  : 'existing_msme');
    }).toList();
  }

  List<QuestionnaireField> _visibleFields() => _relevantFields()
      .where((field) => !_profilePrefilled.contains(field.id))
      .toList();

  void _changeAnswer(QuestionnaireField field, Object? answer) {
    final saveFailedMessage = context.l10n.questionnaireSaveFailed;
    setState(() {
      if (answer == null) {
        _answers.remove(field.id);
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
    final fields = _visibleFields();
    if (_currentIndex >= fields.length) return;
    final field = fields[_currentIndex];
    if (skipCurrent) _changeAnswer(field, null);
    await _saveQueue;
    if (!mounted || _saveError != null) return;
    final answer = _answers[field.id];
    AppAnalytics.instance.track(
      AnalyticsEvent.questionnaireProgress,
      interactionId: widget.interactionId,
      properties: {
        'field_id': field.id,
        'action': answer != null && _store.isValidAnswer(field, answer)
            ? 'answered'
            : 'skipped',
      },
    );
    _qa?.advance(
      field.id,
      answered: answer != null && _store.isValidAnswer(field, answer),
    );

    if (_currentIndex + 1 >= _visibleFields().length) {
      await _finish();
      return;
    }
    setState(() => _currentIndex++);
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    await _saveQueue;
    if (!mounted || _saveError != null) return;
    final relevantIds = {
      'general_state',
      'business_location',
      'is_maharashtra_domicile',
      'owner_age',
      if (_profilePrefilled.contains('general_gender')) 'general_gender',
      if (_profilePrefilled.contains('social_category')) 'social_category',
      for (final field in _relevantFields()) field.id,
    };
    final validAnswers = {
      for (final entry in _answers.entries)
        if (relevantIds.contains(entry.key)) entry.key: entry.value,
    };
    _completed = true;
    _qa?.completed = true;
    navigator.pop();
    widget.onAnswersCompleted?.call(validAnswers);
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _qa?.reportRun();
    AppAnalytics.instance.track(
      AnalyticsEvent.questionnaireClosed,
      interactionId: widget.interactionId,
      properties: {'outcome': _completed ? 'completed' : 'abandoned'},
    );
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
    if (fields.isEmpty) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FilledButton(
            onPressed: _finish,
            child: Text(context.l10n.assessSkipToResults),
          ),
        ),
      );
    }
    final field = fields[_currentIndex];
    _qa?.showField(field.id);
    if (widget.interactionId != null && _shownFields.add(field.id)) {
      AppAnalytics.instance.track(
        AnalyticsEvent.questionnaireProgress,
        interactionId: widget.interactionId,
        properties: {'field_id': field.id, 'action': 'shown'},
      );
    }

    final l10n = context.l10n;
    final progress = (_currentIndex + 1) / fields.length;
    final cardTitle = CentralizedTranslator.instance.localizeTagFor(
      _language,
      widget.cardTitle,
    );
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: sheetHeight,
          maxHeight: sheetHeight,
          maxWidth: 680,
        ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(field.id),
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
                      const SizedBox(height: AppSpacing.lg),
                      QuestionnaireFieldControl(
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
                    ],
                  ),
                ),
              ),
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
    );
  }

  void _goBack() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }
}
