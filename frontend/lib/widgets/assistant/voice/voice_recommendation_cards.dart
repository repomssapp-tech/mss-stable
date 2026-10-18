import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_model.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../services/search/intelligent_scheme_search.dart';
import '../../../services/search/scheme_understanding_engine.dart';
import '../../../services/voice/assistant_session_controller.dart';
import '../../../utils/app_spacing.dart';
import 'voice_transcript_widgets.dart';

class VoiceRecommendationCard extends StatelessWidget {
  const VoiceRecommendationCard({
    super.key,
    required this.recommendation,
    required this.presentInTamil,
    required this.l10n,
    this.onSchemeSelected,
  });

  final SchemeRecommendation recommendation;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = recommendation.scheme;
    final label = switch (recommendation.state) {
      SchemeMatchState.strongMatch => l10n.voiceMatchStrong,
      SchemeMatchState.likelyMatch => l10n.voiceMatchLikely,
      SchemeMatchState.needsInformation => l10n.voiceMatchNeedsConfirmation,
      SchemeMatchState.notSuitable => l10n.voiceMatchNotSuitable,
      SchemeMatchState.noConfidentMatch => l10n.voiceMatchNoConfident,
    };
    final color = switch (recommendation.state) {
      SchemeMatchState.strongMatch => const Color(0xFF22C55E),
      SchemeMatchState.likelyMatch => const Color(0xFF60A5FA),
      SchemeMatchState.needsInformation => const Color(0xFFF59E0B),
      _ => const Color(0xFFF87171),
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: InkWell(
        key: Key('voice-result-${scheme.id}'),
        onTap: () => onSchemeSelected?.call(scheme),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.052),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheme.toLocalized(presentInTamil ? 'ta' : 'en').name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.tight,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.62)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.tight),
              if (recommendation.reasons.isNotEmpty)
                _resultLine(
                  Icons.check_circle_outline,
                  l10n.voiceWhyThisFits(
                    recommendation.reasons.join(' • '),
                  ),
                  const Color(0xFF86EFAC),
                ),
              if (recommendation.unknownRequirements.isNotEmpty)
                _resultLine(
                  Icons.help_outline,
                  l10n.voiceStillConfirm(
                    recommendation.unknownRequirements.take(2).join(' • '),
                  ),
                  const Color(0xFFFCD34D),
                ),
              _resultLine(
                recommendation.isTrusted
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                recommendation.isTrusted
                    ? l10n.voiceSourceVerified
                    : l10n.voiceSourceUnverified,
                recommendation.isTrusted
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFFCA5A5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultLine(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: AppSpacing.tight),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFFF1F5F9),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class VoiceLegacyResultsSection extends StatelessWidget {
  const VoiceLegacyResultsSection({
    super.key,
    required this.matches,
    required this.presentInTamil,
    required this.l10n,
    this.onSchemeSelected,
  });

  final List<SchemeSearchMatch> matches;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.voiceBestMatchingSchemes,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        ...matches
            .take(3)
            .map(
              (match) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.tight),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: Key('voice-result-${match.scheme.id}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.white.withValues(alpha: 0.055),
                    title: Text(
                      match.scheme
                          .toLocalized(presentInTamil ? 'ta' : 'en')
                          .name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      match.reasons.join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                      ),
                    ),
                    onTap: () => onSchemeSelected?.call(match.scheme),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class VoiceConversationalResultsSection extends StatelessWidget {
  const VoiceConversationalResultsSection({
    super.key,
    required this.session,
    required this.showAllRecommendations,
    required this.presentInTamil,
    required this.l10n,
    required this.onToggleAllResults,
    required this.onOpenSearch,
    this.onSchemeSelected,
    this.onReviewProfile,
    this.hasUnsavedProfileFacts = false,
  });

  final AssistantSessionState session;
  final bool showAllRecommendations;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final VoidCallback onToggleAllResults;
  final VoidCallback onOpenSearch;
  final ValueChanged<Scheme>? onSchemeSelected;
  final VoidCallback? onReviewProfile;
  final bool hasUnsavedProfileFacts;

  @override
  Widget build(BuildContext context) {
    final allRecommendations = session.recommendations;
    final recommendations = showAllRecommendations
        ? allRecommendations
        : allRecommendations.take(3).toList(growable: false);

    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.voiceSchemesSuitedToSituation,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.voiceFoundCount(allRecommendations.length),
              key: const Key('voice-result-count'),
              style: GoogleFonts.inter(
                color: const Color(0xFF93C5FD),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.tight),
            TextButton(
              key: const Key('voice-view-all-results'),
              onPressed: onOpenSearch,
              child: Text(
                CentralizedTranslator.instance.localize('Open search'),
                style: const TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ),
        ...recommendations.map(
          (rec) => VoiceRecommendationCard(
            recommendation: rec,
            presentInTamil: presentInTamil,
            l10n: l10n,
            onSchemeSelected: onSchemeSelected,
          ),
        ),
        if (allRecommendations.length > 3)
          TextButton.icon(
            key: const Key('voice-toggle-all-results'),
            onPressed: onToggleAllResults,
            icon: Icon(
              showAllRecommendations
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 17,
            ),
            label: Text(
              showAllRecommendations
                  ? l10n.voiceShowTop3
                  : l10n.voiceShowAllMatches(allRecommendations.length),
            ),
          ),
        if (onReviewProfile != null && hasUnsavedProfileFacts) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('voice-review-profile'),
            onPressed: onReviewProfile,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
            label: Text(
              CentralizedTranslator.instance.localize(
                'Review and save confirmed details',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class RegularVoiceRecommendationCard extends StatelessWidget {
  const RegularVoiceRecommendationCard({
    super.key,
    required this.recommendation,
    required this.presentInTamil,
    required this.l10n,
    this.onSchemeSelected,
  });

  final SchemeRecommendation recommendation;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    final localized = recommendation.scheme.toLocalized(
      presentInTamil ? 'ta' : 'en',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        key: Key('voice-result-${recommendation.scheme.id}'),
        onTap: () => onSchemeSelected?.call(recommendation.scheme),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF111624),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF29334E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      localized.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 17,
                    color: Color(0xFF8B9BFF),
                  ),
                ],
              ),
              if (recommendation.reasons.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  l10n.voiceWhyThisFits(
                    recommendation.reasons.join(' • '),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB7C0D2),
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.tight),
              Text(
                recommendation.isTrusted
                    ? l10n.voiceSourceVerified
                    : l10n.voiceConfirmEligibility,
                style: GoogleFonts.inter(
                  color: recommendation.isTrusted
                      ? const Color(0xFF70D6B2)
                      : const Color(0xFFFFC46B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegularVoiceRecommendationsSection extends StatelessWidget {
  const RegularVoiceRecommendationsSection({
    super.key,
    required this.session,
    required this.showAllRecommendations,
    required this.presentInTamil,
    required this.l10n,
    required this.onToggleAllResults,
    this.onSchemeSelected,
    this.onReviewProfile,
    this.hasUnsavedProfileFacts = false,
  });

  final AssistantSessionState session;
  final bool showAllRecommendations;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final VoidCallback onToggleAllResults;
  final ValueChanged<Scheme>? onSchemeSelected;
  final VoidCallback? onReviewProfile;
  final bool hasUnsavedProfileFacts;

  @override
  Widget build(BuildContext context) {
    final all = session.recommendations;
    final visible = showAllRecommendations
        ? all
        : all.take(3).toList(growable: false);

    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.voiceForYou,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.voiceFoundCount(all.length),
              key: const Key('voice-result-count'),
              style: GoogleFonts.inter(
                color: const Color(0xFF929DB2),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...visible.map(
          (rec) => RegularVoiceRecommendationCard(
            recommendation: rec,
            presentInTamil: presentInTamil,
            l10n: l10n,
            onSchemeSelected: onSchemeSelected,
          ),
        ),
        if (all.length > 3)
          TextButton.icon(
            key: const Key('voice-toggle-all-results'),
            onPressed: onToggleAllResults,
            icon: Icon(
              showAllRecommendations
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
            ),
            label: Text(
              showAllRecommendations
                  ? l10n.voiceShowTop3
                  : l10n.voiceShowAllMatches(all.length),
            ),
          ),
        if (onReviewProfile != null && hasUnsavedProfileFacts)
          TextButton.icon(
            key: const Key('voice-review-profile'),
            onPressed: onReviewProfile,
            icon: const Icon(Icons.tune_rounded, size: 17),
            label: Text(l10n.voiceReviewDetails),
          ),
      ],
    );
  }
}

class RegularVoiceLegacyResultsSection extends StatelessWidget {
  const RegularVoiceLegacyResultsSection({
    super.key,
    required this.matches,
    required this.presentInTamil,
    required this.l10n,
    this.onSchemeSelected,
  });

  final List<SchemeSearchMatch> matches;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.voiceForYou,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...matches.take(3).map(
          (match) => VoiceTurnSchemeCard(
            match: match,
            presentInTamil: presentInTamil,
            onSchemeSelected: onSchemeSelected,
          ),
        ),
      ],
    );
  }
}
