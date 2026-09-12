import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_model.dart';
import '../../../services/search/intelligent_scheme_search.dart';
import '../../../services/search/private_ai_knowledge_base.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import 'voice_overlay_models.dart';

class VoiceTranscriptBubble extends StatelessWidget {
  const VoiceTranscriptBubble({
    super.key,
    required this.turn,
    this.accentColor = const Color(0xFF6D5DFB),
    this.isCompanion = true,
    required this.presentInTamil,
    required this.l10n,
    this.onSchemeSelected,
  });

  final VoiceTranscriptTurn turn;
  final Color accentColor;
  final bool isCompanion;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.speaker == VoiceTranscriptSpeaker.user;
    final bubbleColor = isUser
        ? accentColor.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.075);
    final label = isUser ? l10n.voiceSpeakerYou : l10n.voiceSpeakerAssistant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: '$label: ${turn.text}',
        child: Container(
          key: Key('voice-turn-${turn.id}'),
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: Border.all(
              color: isUser
                  ? accentColor.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isUser ? const Color(0xFF93C5FD) : accentColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                turn.text,
                maxLines: isCompanion ? null : (isUser ? 3 : 5),
                overflow: isCompanion ? null : TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (turn.schemeMatches.isNotEmpty) ...[
                const SizedBox(height: 9), // spacing-ok
                Text(
                  l10n.voiceRecommendedForYou,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF86EFAC),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ...turn.schemeMatches.take(3).map(
                      (match) => VoiceTurnSchemeCard(
                        match: match,
                        accentColor: accentColor,
                        presentInTamil: presentInTamil,
                        onSchemeSelected: onSchemeSelected,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class VoiceTurnSchemeCard extends StatelessWidget {
  const VoiceTurnSchemeCard({
    super.key,
    required this.match,
    this.accentColor = const Color(0xFF6D5DFB),
    required this.presentInTamil,
    this.onSchemeSelected,
  });

  final SchemeSearchMatch match;
  final Color accentColor;
  final bool presentInTamil;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = match.scheme.toLocalized(presentInTamil ? 'ta' : 'en');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.tight),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('voice-result-${match.scheme.id}'),
          onTap: () => onSchemeSelected?.call(match.scheme),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: accentColor.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (match.reasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          match.reasons.join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 9.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.arrow_forward_rounded, size: 15, color: accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VoiceAssistantReplyCard extends StatelessWidget {
  const VoiceAssistantReplyCard({
    super.key,
    required this.reply,
    required this.accentColor,
    required this.isCompanion,
    required this.l10n,
    required this.onOpenSource,
  });

  final GroundedAssistantReply reply;
  final Color accentColor;
  final bool isCompanion;
  final AppLocalizations l10n;
  final ValueChanged<String> onOpenSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('voice-assistant-reply'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: accentColor),
              const SizedBox(width: AppSpacing.tight),
              Flexible(
                child: FitOneLine(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isCompanion ? 'Saarthi' : l10n.askAi,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reply.displayText,
            style: GoogleFonts.inter(
              color: const Color(0xFFE2E8F0),
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (reply.sourceUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const Key('voice-assistant-source'),
              onPressed: () => onOpenSource(reply.sourceUrl),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(
                reply.sourceLabel.isEmpty
                    ? l10n.voiceOpenOfficialSource
                    : reply.sourceLabel,
                style: const TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
