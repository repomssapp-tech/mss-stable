import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/questionnaire/questionnaire_profile_update.dart';
import '../../services/questionnaire/questionnaire_qa_metrics.dart';
import '../../services/questionnaire/questionnaire_recommendation_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../widgets/assistant/smart_assessment_bottom_sheet.dart';
import '../../widgets/common/sign_in_required_sheet.dart';
import 'scheme_details_screen.dart';

class QuestionnaireResultsScreen extends StatefulWidget {
  const QuestionnaireResultsScreen({
    super.key,
    required this.title,
    required this.cardType,
    required this.schemes,
    required this.catalogSchemes,
    required this.answers,
  });

  final String title;
  final String cardType;
  final List<Scheme> schemes;
  final List<Scheme> catalogSchemes;
  final Map<String, Object?> answers;

  @override
  State<QuestionnaireResultsScreen> createState() =>
      _QuestionnaireResultsScreenState();
}

class _QuestionnaireResultsScreenState
    extends State<QuestionnaireResultsScreen> {
  static const _groupLimit = 5;
  late final Map<QuestionnaireFit, List<QuestionnaireRankedScheme>> _groups;
  var _addedCatalogMatches = false;

  @override
  void initState() {
    super.initState();
    const service = QuestionnaireRecommendationService();
    final ranked = service.rank(widget.schemes, widget.answers);
    _groups = {
      for (final fit in QuestionnaireFit.values)
        fit: ranked
            .where((match) => match.fit == fit)
            .take(_groupLimit)
            .toList(),
    };
    final good = _groups[QuestionnaireFit.good]!;
    final possible = _groups[QuestionnaireFit.possible]!;
    final missing = _groupLimit - good.length - possible.length;
    if (missing > 0) {
      final cardIds = widget.schemes.map((scheme) => scheme.id).toSet();
      final extra = service
          .rank(
            widget.catalogSchemes
                .where((scheme) => !cardIds.contains(scheme.id))
                .toList(),
            widget.answers,
          )
          .where((match) => match.fit != QuestionnaireFit.notNow)
          .take(missing);
      for (final match in extra) {
        _groups[match.fit]!.add(match);
        _addedCatalogMatches = true;
      }
    }
    QuestionnaireQaMetrics.emit('results', {
      for (final entry in _groups.entries) entry.key.name: entry.value.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profileUpdate = QuestionnaireProfileUpdate.apply(
      provider.profile,
      widget.answers,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.assessmentResultsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(widget.title, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.assessmentResultsIntro,
            style: context.text.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: () => _changeAnswers(context),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.edit),
              ),
              if (provider.isLoggedIn && profileUpdate != null)
                FilledButton.icon(
                  onPressed: () => _saveProfile(context, provider),
                  icon: const Icon(Icons.person_outline),
                  label: Text(context.l10n.updateProfile),
                ),
            ],
          ),
          if (_addedCatalogMatches) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.assessmentFallbackNote,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _group(
            context,
            QuestionnaireFit.good,
            context.l10n.assessmentGoodFit,
          ),
          _group(
            context,
            QuestionnaireFit.possible,
            context.l10n.assessmentPossibleFit,
          ),
          _group(
            context,
            QuestionnaireFit.notNow,
            context.l10n.assessmentNotNow,
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, QuestionnaireFit fit, String heading) {
    final matches = _groups[fit]!;
    if (matches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final result in matches)
            Consumer<AppProvider>(
              builder: (context, provider, _) => Card(
                child: ListTile(
                  title: Text(
                    result.scheme.nativeName(
                          'name',
                          Localizations.localeOf(context).languageCode,
                        ) ??
                        result.scheme.name,
                  ),
                  subtitle: Text(_reason(context, result.reasonKey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip:
                            provider.bookmarkedIds.contains(result.scheme.id)
                            ? context.l10n.savedSchemeButton
                            : context.l10n.saveSchemeTooltip,
                        onPressed: () =>
                            _saveScheme(context, provider, result.scheme),
                        icon: Icon(
                          provider.bookmarkedIds.contains(result.scheme.id)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    QuestionnaireQaMetrics.emit('scheme_opened', {
                      'fit': fit.name,
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SchemeDetailsScreen(scheme: result.scheme),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _reason(BuildContext context, String key) => switch (key) {
    'assessmentReasonState' => context.l10n.assessmentReasonState,
    'assessmentReasonStateExcluded' =>
      context.l10n.assessmentReasonStateExcluded,
    'assessmentReasonAgeExcluded' => context.l10n.assessmentReasonAgeExcluded,
    'assessmentReasonStageExcluded' =>
      context.l10n.assessmentReasonStageExcluded,
    'assessmentReasonCategory' => context.l10n.assessmentReasonCategory,
    'assessmentReasonNature' => context.l10n.assessmentReasonNature,
    'assessmentReasonGoal' => context.l10n.assessmentReasonGoal,
    _ => context.l10n.assessmentReasonGeneral,
  };

  void _changeAnswers(BuildContext context) {
    SmartAssessmentBottomSheet.show(context, widget.title, widget.cardType, (
      updatedAnswers,
    ) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuestionnaireResultsScreen(
            title: widget.title,
            cardType: widget.cardType,
            schemes: widget.schemes,
            catalogSchemes: widget.catalogSchemes,
            answers: updatedAnswers,
          ),
        ),
      );
    }, editSavedAnswers: true);
  }

  Future<void> _saveScheme(
    BuildContext context,
    AppProvider provider,
    Scheme scheme,
  ) async {
    if (!await requireAccount(context, feature: SignInFeature.save) ||
        !context.mounted) {
      return;
    }
    provider.toggleBookmark(scheme.id);
  }

  Future<void> _saveProfile(BuildContext context, AppProvider provider) async {
    final updated = QuestionnaireProfileUpdate.apply(
      provider.profile,
      widget.answers,
    );
    if (updated == null) return;
    try {
      await provider.updateProfile(updated, requireCloudSync: true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.profileSaveFailed)));
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
    }
  }
}
