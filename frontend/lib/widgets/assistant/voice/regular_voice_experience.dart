import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/scheme_model.dart';
import '../../../utils/app_spacing.dart';
import '../voice_edge_painter.dart';
import 'voice_overlay_models.dart';
import 'voice_transcript_widgets.dart';

class RegularVoiceTopBar extends StatelessWidget {
  const RegularVoiceTopBar({
    super.key,
    required this.statusLabel,
    required this.l10n,
    required this.languageSelector,
    required this.onClose,
  });

  final String statusLabel;
  final AppLocalizations l10n;
  final Widget languageSelector;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D5DFB), Color(0xFF36C5F0)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.askAi,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Semantics(
                liveRegion: true,
                label: statusLabel,
                child: Text(
                  statusLabel,
                  key: const Key('voice-live-status'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFA8B0C2),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        languageSelector,
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          key: const Key('voice-close-button'),
          tooltip: l10n.voiceCancelAssistantTooltip,
          onPressed: onClose,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: const Color(0xFFD7DCE8),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class RegularVoicePresence extends StatelessWidget {
  const RegularVoicePresence({
    super.key,
    required this.isGenerating,
    required this.isListening,
    required this.speaking,
    required this.statusLabel,
    required this.waveController,
    required this.soundLevel,
    required this.l10n,
  });

  final bool isGenerating;
  final bool isListening;
  final bool speaking;
  final String statusLabel;
  final Animation<double> waveController;
  final ValueListenable<double> soundLevel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final active = isListening || speaking || isGenerating;
    return Center(
      child: Semantics(
        image: true,
        label: active ? statusLabel : l10n.voiceAiReady,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: active ? 154 : 138,
          height: active ? 154 : 138,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8B7CFF).withValues(alpha: active ? 0.95 : 0.72),
                const Color(0xFF3E7BFA).withValues(alpha: 0.58),
                const Color(0xFF17C4D8).withValues(alpha: 0.08),
              ],
              stops: const [0, 0.52, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF6D5DFB,
                ).withValues(alpha: active ? 0.42 : 0.20),
                blurRadius: active ? 54 : 34,
                spreadRadius: active ? 10 : 2,
              ),
            ],
          ),
          child: Center(
            child: VoiceLevelBars(
              key: const Key('voice-level-bars'),
              animation: waveController,
              level: soundLevel,
              active: isListening,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class RegularVoiceWelcome extends StatelessWidget {
  const RegularVoiceWelcome({
    super.key,
    required this.l10n,
    required this.onSuggestionSelected,
    this.accent = const Color(0xFF6D5DFB),
  });

  final AppLocalizations l10n;
  final ValueChanged<String> onSuggestionSelected;
  final Color accent;

  Widget _suggestionChip(String label) => ActionChip(
    label: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    onPressed: () => onSuggestionSelected(label),
    side: BorderSide(color: accent),
    backgroundColor: accent.withValues(alpha: 0.18),
    labelStyle: const TextStyle(color: Colors.white),
    visualDensity: VisualDensity.compact,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          l10n.howCanIHelp,
          key: const Key('voice-transcript'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.voiceTellMeSituationFindSchemes,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA6BA),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            _suggestionChip(l10n.voiceSuggestionBusinessLoans),
            _suggestionChip(l10n.voiceSuggestionCollegeScholarship),
            _suggestionChip(l10n.voiceSuggestionFarmerSubsidy),
          ],
        ),
      ],
    );
  }
}

class RegularVoiceTurn extends StatelessWidget {
  const RegularVoiceTurn({
    super.key,
    required this.turn,
    required this.presentInTamil,
    required this.l10n,
    this.onSchemeSelected,
  });

  final VoiceTranscriptTurn turn;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.speaker == VoiceTranscriptSpeaker.user;
    final label = isUser ? l10n.voiceSpeakerYou : l10n.voiceSpeakerAssistant;
    return Container(
      key: Key('voice-turn-${turn.id}'),
      margin: const EdgeInsets.only(bottom: 22),
      padding: EdgeInsets.only(left: isUser ? 34 : AppSpacing.none),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isUser ? const Color(0xFF7F8AA1) : const Color(0xFF8B9BFF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            turn.text,
            textAlign: isUser ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.inter(
              color: isUser ? const Color(0xFFC5CBD8) : const Color(0xFFF4F6FA),
              fontSize: isUser ? 15 : 17,
              fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
              height: 1.48,
              letterSpacing: -0.15,
            ),
          ),
          if (turn.schemeMatches.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...turn.schemeMatches
                .take(3)
                .map(
                  (match) => VoiceTurnSchemeCard(
                    match: match,
                    presentInTamil: presentInTamil,
                    onSchemeSelected: onSchemeSelected,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class RegularVoiceTranscript extends StatelessWidget {
  const RegularVoiceTranscript({
    super.key,
    required this.conversationTurns,
    required this.presentInTamil,
    required this.l10n,
    this.onSchemeSelected,
  });

  final List<VoiceTranscriptTurn> conversationTurns;
  final bool presentInTamil;
  final AppLocalizations l10n;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    final visibleTurns = conversationTurns.length <= 3
        ? conversationTurns
        : conversationTurns.sublist(conversationTurns.length - 3);
    return Semantics(
      container: true,
      label: l10n.voiceConversationTranscript,
      child: Column(
        key: const Key('voice-conversation-transcript'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final turn in visibleTurns)
            RegularVoiceTurn(
              turn: turn,
              presentInTamil: presentInTamil,
              l10n: l10n,
              onSchemeSelected: onSchemeSelected,
            ),
        ],
      ),
    );
  }
}

class RegularVoiceNotice extends StatelessWidget {
  const RegularVoiceNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF151A27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3142)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFFD4D9E5),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class RegularVoiceControls extends StatelessWidget {
  const RegularVoiceControls({
    super.key,
    required this.speaking,
    required this.isListening,
    required this.cloudSessionInUse,
    required this.l10n,
    required this.onToggleListening,
  });

  final bool speaking;
  final bool isListening;
  final bool cloudSessionInUse;
  final AppLocalizations l10n;
  final VoidCallback onToggleListening;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          speaking
              ? l10n.voiceTapToInterrupt
              : isListening
              ? l10n.voiceStatusListening
              : l10n.companionTapToSpeak,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFFA8B0C2),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        Semantics(
          button: true,
          label: speaking
              ? l10n.voiceSemInterrupt
              : isListening
              ? l10n.voiceStopListeningSemantic
              : l10n.voiceStartListeningSemantic,
          hint: l10n.voiceSemMicHint,
          onTap: onToggleListening,
          excludeSemantics: true,
          child: IconButton.filled(
            key: const Key('voice-primary-control'),
            onPressed: onToggleListening,
            style: IconButton.styleFrom(
              minimumSize: const Size(68, 68),
              backgroundColor: isListening
                  ? const Color(0xFFF1F3F8)
                  : const Color(0xFF6D5DFB),
              foregroundColor: isListening
                  ? const Color(0xFF121622)
                  : Colors.white,
              shadowColor: const Color(0xFF6D5DFB),
              elevation: 10,
            ),
            icon: Icon(
              speaking
                  ? Icons.front_hand_rounded
                  : isListening
                  ? Icons.stop_rounded
                  : Icons.mic_rounded,
              size: 28,
            ),
          ),
        ),
        if (cloudSessionInUse) ...[
          const SizedBox(height: 9),
          Text(
            l10n.voiceNoiseControlSecure,
            key: const Key('voice-cloud-disclosure'),
            style: GoogleFonts.inter(
              color: const Color(0xFF707A91),
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }
}
