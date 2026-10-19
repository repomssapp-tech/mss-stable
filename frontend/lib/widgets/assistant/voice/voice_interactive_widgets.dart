import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../services/search/official_grounded_search.dart';
import '../../../services/search/scheme_understanding_engine.dart';
import '../../../utils/app_spacing.dart';
import 'voice_overlay_models.dart';

String factLabel(BuildContext context, EligibilityFactKey key) {
  final l10n = context.l10n;
  return switch (key) {
    EligibilityFactKey.age => l10n.labelAge,
    EligibilityFactKey.state => l10n.voiceFactLabelState,
    EligibilityFactKey.district => l10n.filterDistrict,
    EligibilityFactKey.annualIncome => l10n.labelAnnualIncome,
    EligibilityFactKey.gender => l10n.labelGender,
    EligibilityFactKey.community => l10n.labelCommunity,
    EligibilityFactKey.occupation => l10n.voiceFactLabelSituation,
    EligibilityFactKey.education => l10n.labelEducation,
    EligibilityFactKey.disability => l10n.labelDisability,
    EligibilityFactKey.maritalStatus => l10n.voiceFactLabelMaritalStatus,
    EligibilityFactKey.studentStatus => l10n.empStudent,
    EligibilityFactKey.businessStage => l10n.labelBusinessStage,
    EligibilityFactKey.businessSector => l10n.voiceFactLabelSector,
    EligibilityFactKey.fundingNeed => l10n.voiceFactLabelFundingNeed,
    EligibilityFactKey.landholding => l10n.voiceFactLabelLandholding,
  };
}

String displayFactValue(AppLocalizations l10n, EligibilityFact fact) {
  if ({
    EligibilityFactKey.annualIncome,
    EligibilityFactKey.fundingNeed,
  }.contains(fact.key)) {
    final amount = double.tryParse(fact.value);
    if (amount != null) {
      if (amount >= 10000000) {
        return l10n.voiceFactCrore((amount / 10000000).toStringAsFixed(1));
      }
      if (amount >= 100000) {
        return l10n.voiceFactLakh((amount / 100000).toStringAsFixed(1));
      }
    }
  }
  return fact.hasConflict
      ? l10n.voiceFactConflictFormat(fact.conflictingValue!, fact.value)
      : fact.value;
}

class VoiceLanguageSelector extends StatelessWidget {
  const VoiceLanguageSelector({
    super.key,
    required this.showFallbackPicker,
    required this.languageBadgeLabel,
    required this.fallbackLanguage,
    required this.l10n,
    required this.onChangeLanguage,
  });

  final bool showFallbackPicker;
  final String languageBadgeLabel;
  final VoiceInputLanguage fallbackLanguage;
  final AppLocalizations l10n;
  final ValueChanged<VoiceInputLanguage> onChangeLanguage;

  @override
  Widget build(BuildContext context) {
    if (!showFallbackPicker) {
      return Semantics(
        label: l10n.voiceLanguageSemantic(languageBadgeLabel),
        child: Container(
          key: const Key('voice-language-auto-badge'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Text(
            languageBadgeLabel,
            style: GoogleFonts.inter(
              color: const Color(0xFF172554),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return Container(
      key: const Key('voice-language-fallback-picker'),
      padding: const EdgeInsets.all(AppSpacing.hairline),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _languageOption('EN', VoiceInputLanguage.english),
          _languageOption('தமிழ்', VoiceInputLanguage.tamil),
        ],
      ),
    );
  }

  Widget _languageOption(String label, VoiceInputLanguage language) {
    final selected = fallbackLanguage == language;
    return InkWell(
      key: Key('voice-language-${language.name}'),
      onTap: () => onChangeLanguage(language),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class VoiceFactChips extends StatelessWidget {
  const VoiceFactChips({
    super.key,
    required this.facts,
    this.isCompanion = true,
    required this.l10n,
    required this.onEditFact,
  });

  final Map<EligibilityFactKey, EligibilityFact> facts;
  final bool isCompanion;
  final AppLocalizations l10n;
  final ValueChanged<EligibilityFact> onEditFact;

  @override
  Widget build(BuildContext context) {
    final displayFacts = isCompanion
        ? facts.values.toList(growable: false)
        : facts.values.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.voiceWhatIUnderstood,
          style: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.tight),
        Wrap(
          spacing: AppSpacing.tight,
          runSpacing: AppSpacing.tight,
          children: displayFacts
              .map((fact) {
                final conflict = fact.hasConflict;
                return InputChip(
                  key: Key('voice-fact-${fact.key.name}'),
                  avatar: Icon(
                    conflict
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 15,
                    color: conflict
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF60A5FA),
                  ),
                  label: Text(
                    '${factLabel(context, fact.key)}: ${displayFactValue(l10n, fact)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => onEditFact(fact),
                  side: BorderSide(
                    color: conflict
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF334155),
                  ),
                  backgroundColor: const Color(0xFF172554),
                  labelStyle: const TextStyle(color: Colors.white),
                  visualDensity: VisualDensity.compact,
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class VoiceQuestionCard extends StatelessWidget {
  const VoiceQuestionCard({
    super.key,
    required this.question,
    required this.questionText,
    required this.l10n,
    required this.onOptionSelected,
    required this.onRepeatQuestion,
  });

  final FollowUpQuestion question;
  final String questionText;
  final AppLocalizations l10n;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onRepeatQuestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('voice-follow-up-question'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF60A5FA),
                size: 17,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  questionText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              IconButton(
                key: const Key('voice-repeat-question'),
                tooltip: l10n.voiceRepeatQuestionTooltip,
                onPressed: onRepeatQuestion,
                icon: const Icon(
                  Icons.volume_up_outlined,
                  color: Color(0xFF93C5FD),
                  size: 20,
                ),
              ),
            ],
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.tight,
              runSpacing: AppSpacing.tight,
              children: question.options
                  .map(
                    (option) => ActionChip(
                      key: Key(
                        'voice-answer-${option.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      label: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () => onOptionSelected(option),
                      backgroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.tight,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class RegularVoiceQuestionCard extends StatelessWidget {
  const RegularVoiceQuestionCard({
    super.key,
    required this.question,
    required this.questionText,
    required this.l10n,
    required this.speechOutputSupported,
    required this.onOptionSelected,
  });

  final FollowUpQuestion question;
  final String questionText;
  final AppLocalizations l10n;
  final bool speechOutputSupported;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('voice-follow-up-question'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF111624),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF303A58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: question.options
                  .map(
                    (option) => ActionChip(
                      key: Key(
                        'voice-answer-${option.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      label: Text(option),
                      onPressed: () => onOptionSelected(option),
                      backgroundColor: const Color(0xFF222A42),
                      side: const BorderSide(color: Color(0xFF46537B)),
                      labelStyle: const TextStyle(
                        color: Color(0xFFF2F4F8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (!speechOutputSupported) ...[
            const SizedBox(height: 10), // spacing-ok
            Text(
              l10n.voiceSpeechOutputUnavailable,
              style: GoogleFonts.inter(
                color: const Color(0xFFFFC46B),
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VoiceOnlineGroundingPill extends StatelessWidget {
  const VoiceOnlineGroundingPill({
    super.key,
    required this.groundingPhase,
    required this.groundedSources,
    required this.accentColor,
    required this.isCompanion,
    required this.l10n,
    required this.onOpenSource,
  });

  final OnlineGroundingPhase groundingPhase;
  final List<GroundedSource> groundedSources;
  final Color accentColor;
  final bool isCompanion;
  final AppLocalizations l10n;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    final isChecking = groundingPhase == OnlineGroundingPhase.checking;
    final isFound = groundingPhase == OnlineGroundingPhase.found;
    final icon = isChecking
        ? Icons.travel_explore
        : isFound
        ? Icons.verified_outlined
        : Icons.cloud_off_outlined;
    final title = switch (groundingPhase) {
      OnlineGroundingPhase.checking => l10n.voiceGroundingChecking,
      OnlineGroundingPhase.found => l10n.voiceGroundingFoundSources(
        groundedSources.length,
      ),
      OnlineGroundingPhase.unavailable => l10n.voiceGroundingUnavailable,
      OnlineGroundingPhase.noSources => l10n.voiceGroundingNoSources,
      OnlineGroundingPhase.idle => '',
    };

    if (!isCompanion) {
      final firstSource = isFound && groundedSources.isNotEmpty
          ? groundedSources.first
          : null;
      return Container(
        key: const Key('voice-online-grounding'),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1D2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isFound ? const Color(0xFF22C55E) : accentColor).withValues(
              alpha: 0.25,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isFound ? const Color(0xFF4ADE80) : accentColor,
                ),
                const SizedBox(width: AppSpacing.tight),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isChecking)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      key: const Key('voice-online-grounding-progress'),
                      strokeWidth: 1.5,
                      color: accentColor,
                    ),
                  ),
              ],
            ),
            if (firstSource != null) ...[
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                key: Key('voice-grounded-source-${firstSource.url}'),
                onTap: () => onOpenSource(firstSource.url.toString()),
                child: Text(
                  firstSource.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF93C5FD),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (isChecking || isFound) ...[
              const SizedBox(height: 3), // spacing-ok
              Text(
                l10n.voiceGroundingPrivacyNote,
                key: const Key('voice-grounding-privacy-note'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      key: const Key('voice-online-grounding'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1D2E),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: (isFound ? const Color(0xFF22C55E) : accentColor).withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isFound ? const Color(0xFF4ADE80) : accentColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE2E8F0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isChecking)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    key: const Key('voice-online-grounding-progress'),
                    strokeWidth: 1.5,
                    color: accentColor,
                  ),
                ),
            ],
          ),
          if (isFound) ...[
            const SizedBox(height: AppSpacing.tight),
            ...groundedSources.map(
              (source) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.tight),
                child: InkWell(
                  key: Key('voice-grounded-source-${source.url}'),
                  onTap: () => onOpenSource(source.url.toString()),
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.tight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                source.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF93C5FD),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          source.snippet,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFCBD5E1),
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          source.host,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4ADE80),
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (isChecking || isFound) ...[
            const SizedBox(height: AppSpacing.tight),
            Text(
              l10n.voiceGroundingPrivacyNote,
              key: const Key('voice-grounding-privacy-note'),
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 8.5,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
