import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/eligibility_questionnaire.dart';
import '../../../models/places_data.dart';
import '../../../models/user_profile.dart';
import '../../../services/account/eligibility_answers_store.dart';
import '../../../services/account/questionnaire_sync_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import 'eligibility_location.dart';
import 'eligibility_question_widgets.dart';

/// The profile questionnaire, one step at a time. Answers are kept on the phone and sent to
/// the MSS API ([QuestionnaireSyncService]).
///  * [quick]: a guest's short survey (the essential questions only).
///  * [allowSkip]: a guest on the long list may "Skip the rest".
///  * [mandatory]: Google sign-in, every question is needed and the screen cannot be left.
///  * [firstRun]: just entered the app; [onFinished] takes the user in.
/// Gender, age band and home state / district come from [profile], not asked twice.
class EligibilityCheckScreen extends StatefulWidget {
  const EligibilityCheckScreen({
    super.key,
    this.questionnaire,
    this.places,
    this.store = const EligibilityAnswersStore(),
    this.profile,
    this.quick = false,
    this.allowSkip = false,
    this.mandatory = false,
    this.firstRun = false,
    this.onFinished,
    this.sendAnswers,
    this.detect = detectPlace,
  });

  /// Injected by tests; loaded from the assets otherwise.
  final EligibilityQuestionnaire? questionnaire;
  final PlacesData? places;
  final EligibilityAnswersStore store;
  final UserProfile? profile;
  final bool quick;
  final bool allowSkip;
  final bool mandatory;
  final bool firstRun;
  final void Function(BuildContext context)? onFinished;

  /// Sends the saved answers; defaults to the real service. Injected by tests.
  final Future<bool> Function(String language)? sendAnswers;
  final Future<DetectedPlace?> Function() detect;

  @override
  State<EligibilityCheckScreen> createState() => _EligibilityCheckScreenState();
}

// Language-picker labels are fixed-script on purpose.
const _languageLabels = <String, String>{
  'en': 'English', // i18n-ok
  'mr': 'मराठी', // i18n-ok
  'hi': 'हिन्दी', // i18n-ok
  'ta': 'தமிழ்', // i18n-ok
};

/// The step that asks where the business is (it gets the location button).
const _placeStep = 1;

/// Picking a state or district clears the lists that depend on it.
const _prune = <String, List<String>>{
  'business_state': ['business_district', 'business_taluka', 'business_city'],
  'business_district': ['business_taluka'],
  'home_state': ['home_district'],
};

class _EligibilityCheckScreenState extends State<EligibilityCheckScreen> {
  EligibilityQuestionnaire? _q;
  PlacesData _places = PlacesData.empty;
  QuestionnaireAnswers _answers = {};
  QuestionnaireAnswers _derived = {};
  QuestionnaireLocation? _location;
  int _at = 0;
  String? _lang;
  String _error = '';
  String _locationNote = '';
  bool _locating = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final q = widget.questionnaire ?? await EligibilityQuestionnaire.load();
    final places = widget.places ?? await PlacesData.load();
    final saved = await widget.store.load();
    final location = await widget.store.loadLocation();
    if (!mounted) return;
    final derived = q.derive(widget.profile ?? UserProfile());
    setState(() {
      _q = q;
      _places = places;
      _derived = derived;
      _answers = {...saved, ...derived};
      _location = location;
    });
  }

  String get _language {
    final l = _lang ?? Localizations.localeOf(context).languageCode;
    return questionnaireLanguages.contains(l) ? l : 'en';
  }

  bool _needed(QuestionField f) => f.required || widget.mandatory;

  void _set(String id, Object? v) {
    setState(() {
      if (EligibilityQuestionnaire.isEmpty(v)) {
        _answers.remove(id);
      } else {
        _answers[id] = v;
      }
      for (final dep in _prune[id] ?? const <String>[]) {
        _answers.remove(dep);
      }
      _error = '';
    });
  }

  String _problem(EligibilityQuestionnaire q, int step) {
    final l10n = context.l10n;
    for (final f in q.fieldsInStep(step, _answers, _derived, quick: widget.quick)) {
      final v = _answers[f.id];
      if (_needed(f) &&
          (EligibilityQuestionnaire.isEmpty(v) ||
              (f.type == QuestionType.pair &&
                  (v is! Map || v['total'] == null || v['women'] == null)))) {
        return l10n.eligCheckNeeded(f.questionText(_language));
      }
      if (f.type == QuestionType.pair && v is Map) {
        final total = v['total'], women = v['women'];
        if (total is int && women is int && women > total) {
          return l10n.eligCheckWomenMore;
        }
      }
    }
    return '';
  }

  Future<void> _persist() async {
    final lang = Localizations.localeOf(context).languageCode;
    await widget.store.save(_answers);
    if (_location != null) await widget.store.saveLocation(_location!);
    final send =
        widget.sendAnswers ??
        (String l) => QuestionnaireSyncService.instance.sync(language: l);
    // Not awaited for the screen: a slow or missing network never blocks the user.
    send(lang).ignore();
  }

  void _finish() {
    if (widget.firstRun && widget.onFinished != null) {
      widget.onFinished!(context);
    } else {
      setState(() => _done = true);
    }
  }

  Future<void> _next(EligibilityQuestionnaire q) async {
    final steps = q.visibleSteps(_answers, _derived, quick: widget.quick);
    final msg = _problem(q, steps[_at.clamp(0, steps.length - 1)]);
    if (msg.isNotEmpty) {
      setState(() => _error = msg);
      return;
    }
    await _persist();
    if (!mounted) return;
    if (_at >= steps.length - 1) {
      _finish();
    } else {
      setState(() => _at++);
    }
  }

  /// A guest may stop once the short list is answered.
  Future<void> _skipRest() async {
    if (!EligibilityQuestionnaire.isComplete(_answers)) {
      setState(() => _error = context.l10n.eligCheckFirstIntro);
      return;
    }
    await _persist();
    if (!mounted) return;
    _finish();
  }

  Future<void> _locate(EligibilityQuestionnaire q) async {
    setState(() {
      _locating = true;
      _locationNote = context.l10n.eligCheckLocating;
    });
    final place = await widget.detect();
    if (!mounted) return;
    if (place == null) {
      setState(() {
        _locating = false;
        _locationNote = context.l10n.eligCheckLocationFail;
      });
      return;
    }
    final states = q.fields.firstWhere((f) => f.id == 'business_state');
    final wanted = place.state.toLowerCase().replaceAll(' & ', ' and ');
    final match = states.options.where((o) => o.text['en']!.toLowerCase() == wanted);
    setState(() {
      _location = place.location;
      if (match.isNotEmpty) {
        final key = match.first.value;
        _answers['business_state'] = key;
        _answers.remove('business_taluka');
        final district =
            PlacesData.match(_places.districts(key), place.district) ??
            place.district;
        if (district.isNotEmpty) _answers['business_district'] = district;
        if (place.city.isNotEmpty) _answers['business_city'] = place.city;
      }
      _locating = false;
      _locationNote = context.l10n.eligCheckLocationDone;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _q;
    return PopScope(
      // A new user cannot back out of the first questions.
      canPop: !(widget.firstRun || widget.mandatory),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          automaticallyImplyLeading: !(widget.firstRun || widget.mandatory),
          title: Text(
            widget.firstRun ? l10n.eligCheckFirstTitle : l10n.eligCheckTitle,
          ),
        ),
        body: SafeArea(
          child: q == null
              ? const Center(child: CircularProgressIndicator())
              : _done
              ? _savedView(context)
              : _stepView(context, q),
        ),
      ),
    );
  }

  Widget _stepView(BuildContext context, EligibilityQuestionnaire q) {
    final l10n = context.l10n;
    final text = context.text;
    final steps = q.visibleSteps(_answers, _derived, quick: widget.quick);
    final at = _at.clamp(0, steps.length - 1);
    final step = steps[at];
    final stepName = <String>[
      l10n.eligCheckStep0,
      l10n.eligCheckStep1,
      l10n.eligCheckStep2,
      l10n.eligCheckStep3,
      l10n.eligCheckStep4,
      l10n.eligCheckStep5,
    ][step];
    final last = at == steps.length - 1;
    final intro = widget.quick
        ? l10n.eligCheckQuickIntro
        : widget.mandatory
        ? l10n.eligCheckAllRequired
        : widget.firstRun
        ? l10n.eligCheckFirstIntro
        : l10n.eligCheckIntro;
    return Column(
      children: [
        LinearProgressIndicator(value: (at + 1) / steps.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                intro,
                style: text.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.eligCheckQuestionLanguage,
                style: text.label.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final l in questionnaireLanguages)
                    ChoiceChip(
                      label: Text(_languageLabels[l]!),
                      selected: _language == l,
                      onSelected: (_) => setState(() => _lang = l),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.eligCheckStepLabel(at + 1, steps.length),
                style: text.label.copyWith(color: AppColors.primaryStrong),
              ),
              Text(
                stepName,
                style: text.titleLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error.isNotEmpty) ...[
                Text(
                  _error,
                  style: text.body.copyWith(color: AppColors.dangerStrong),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (step == _placeStep) _locateBox(context, q),
              for (final f in q.fieldsInStep(
                step,
                _answers,
                _derived,
                quick: widget.quick,
              ))
                QuestionView(
                  key: ValueKey('${f.id}.$_language'),
                  field: f,
                  mandatory: widget.mandatory,
                  lang: _language,
                  value: _answers[f.id],
                  places: _places,
                  answers: _answers,
                  onChanged: (v) => _set(f.id, v),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              if (at > 0)
                TextButton(
                  onPressed: () async {
                    await _persist();
                    if (mounted) setState(() => _at = at - 1);
                  },
                  child: Text(
                    MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),
              if (widget.allowSkip)
                TextButton(
                  onPressed: _skipRest,
                  child: Text(l10n.eligCheckSkipRest),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () => _next(q),
                child: Text(
                  last
                      ? (widget.firstRun && widget.quick
                            ? l10n.eligCheckSaveGo
                            : l10n.eligCheckSave)
                      : MaterialLocalizations.of(context).continueButtonLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locateBox(BuildContext context, EligibilityQuestionnaire q) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _locating ? null : () => _locate(q),
            icon: _locating
                ? const SizedBox(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2), // spacing-ok
                  )
                : const Icon(Icons.my_location),
            label: Text(context.l10n.eligCheckLocate),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _locationNote.isNotEmpty
                ? _locationNote
                : context.l10n.eligCheckLocationNote,
            style: text.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _savedView(BuildContext context) {
    final l10n = context.l10n;
    final text = context.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: AppSpacing.xxxl,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.eligCheckSavedTitle,
              style: text.titleLarge.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.eligCheckSavedBody,
              style: text.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => setState(() {
                _done = false;
                _at = 0;
              }),
              child: Text(l10n.eligCheckEdit),
            ),
          ],
        ),
      ),
    );
  }
}
