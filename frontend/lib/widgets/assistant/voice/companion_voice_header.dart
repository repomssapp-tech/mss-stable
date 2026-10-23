import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/scheme_model.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../voice_edge_painter.dart';
import 'voice_overlay_models.dart';
import 'voice_transcript_widgets.dart';
import '../../../utils/app_text.dart';

class CompanionVoiceHeader extends StatelessWidget {
  const CompanionVoiceHeader({
    super.key,
    required this.isCompanion,
    required this.statusLabel,
    required this.statusColor,
    required this.l10n,
    required this.languageSelector,
    required this.cloudSessionInUse,
    required this.isMuted,
    this.onToggleMute,
    required this.onClose,
  });

  final bool isCompanion;
  final String statusLabel;
  final Color statusColor;
  final AppLocalizations l10n;
  final Widget languageSelector;
  final bool cloudSessionInUse;
  final bool isMuted;
  final VoidCallback? onToggleMute;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          image: true,
          label: l10n.voiceAiAssistant,
          child: SizedBox(
            width: 56,
            height: 56,
            child: ClipOval(
              child: Image.asset(
                'assets/images/saarthi/sarathi.webp',
                key: const Key('voice-assistant-image'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCompanion ? l10n.voiceHeaderTalkToSaarthi : l10n.askAi,
                style: AppGoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Semantics(
                liveRegion: true,
                label: statusLabel,
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Flexible(
                      child: FitOneLine(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          statusLabel,
                          key: const Key('voice-live-status'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppGoogleFonts.inter(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        languageSelector,
        if (cloudSessionInUse)
          IconButton(
            key: const Key('voice-mute-button'),
            tooltip: isMuted ? l10n.voiceUnmute : l10n.voiceMute,
            onPressed: onToggleMute,
            icon: Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        IconButton(
          key: const Key('voice-close-button'),
          tooltip: l10n.voiceCancelAssistantTooltip,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: Color(0xFFCBD5E1)),
        ),
      ],
    );
  }
}

class CompanionVoiceListeningArea extends StatelessWidget {
  const CompanionVoiceListeningArea({
    super.key,
    required this.isCompanion,
    required this.transcript,
    required this.hasConversationTurns,
    required this.speaking,
    required this.isListening,
    required this.cloudSessionInUse,
    required this.statusColor,
    required this.accent,
    required this.waveController,
    required this.soundLevel,
    this.typedController,
    required this.l10n,
    required this.onToggleListening,
    this.onSendTypedInput,
    this.onSuggestionSelected,
    this.showSuggestions = false,
  });

  final bool isCompanion;
  final String transcript;
  final bool hasConversationTurns;
  final bool speaking;
  final bool isListening;
  final bool cloudSessionInUse;
  final Color statusColor;
  final Color accent;
  final Animation<double> waveController;
  final ValueListenable<double> soundLevel;
  final TextEditingController? typedController;
  final AppLocalizations l10n;
  final VoidCallback onToggleListening;
  final VoidCallback? onSendTypedInput;
  final ValueChanged<String>? onSuggestionSelected;
  final bool showSuggestions;

  Widget _suggestionChip(String label) => ActionChip(
    label: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    onPressed: () => onSuggestionSelected?.call(label),
    side: BorderSide(color: accent),
    backgroundColor: accent.withValues(alpha: 0.18),
    labelStyle: const TextStyle(color: Colors.white),
    visualDensity: VisualDensity.compact,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasConversationTurns
                ? (speaking
                      ? l10n.voiceListenOrInterrupt
                      : isListening
                      ? l10n.voiceSpeakNaturallyPause
                      : l10n.voiceReadyForNextQuestion)
                : transcript.isEmpty
                ? l10n.voiceTellMeNaturally
                : transcript,
            key: const Key('voice-transcript'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppGoogleFonts.inter(
              color: transcript.isEmpty
                  ? const Color(0xFF94A3B8)
                  : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (showSuggestions) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.tight,
              runSpacing: AppSpacing.tight,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip(l10n.voiceSuggestionBusinessLoans),
                _suggestionChip(l10n.voiceSuggestionCollegeScholarship),
                _suggestionChip(l10n.voiceSuggestionFarmerSubsidy),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: cloudSessionInUse
                      ? Semantics(
                          label: l10n.voiceSemNoiseControlOn,
                          child: const Icon(
                            Icons.noise_control_off_rounded,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
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
                    backgroundColor: isListening
                        ? const Color(0xFF10B981)
                        : accent,
                    minimumSize: const Size(56, 56),
                  ),
                  icon: Icon(
                    speaking
                        ? Icons.front_hand_rounded
                        : isListening
                        ? Icons.stop_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VoiceLevelBars(
                    key: const Key('voice-level-bars'),
                    animation: waveController,
                    level: soundLevel,
                    active: isListening,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            speaking
                ? l10n.companionInterrupt
                : isListening
                ? l10n.voiceTapWhenFinished
                : l10n.companionTapToSpeak,
            textAlign: TextAlign.center,
            style: AppGoogleFonts.inter(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (cloudSessionInUse) ...[
            const SizedBox(height: AppSpacing.tight),
            Semantics(
              label: l10n.voiceSemNoiseControlOn,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF34D399),
                    size: 13,
                  ),
                  const SizedBox(width: AppSpacing.tight),
                  Text(
                    l10n.voiceDeviceNoiseControl,
                    style: AppGoogleFonts.inter(
                      color: const Color(0xFF6EE7B7),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isCompanion && typedController != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('voice-typed-input'),
                    controller: typedController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSendTypedInput?.call(),
                    style: AppGoogleFonts.inter(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: isCompanion
                          ? l10n.voiceTypeToSaarthiHint
                          : l10n.voiceTypeInstead,
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.tight),
                IconButton(
                  key: const Key('voice-send-text'),
                  tooltip: l10n.voiceSendMessageTooltip,
                  onPressed: onSendTypedInput,
                  icon: Icon(Icons.send_rounded, color: accent),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CompanionVoiceTranscriptSection extends StatelessWidget {
  const CompanionVoiceTranscriptSection({
    super.key,
    required this.conversationTurns,
    required this.isCompanion,
    required this.accent,
    required this.l10n,
    required this.presentInTamil,
    this.onSchemeSelected,
  });

  final List<VoiceTranscriptTurn> conversationTurns;
  final bool isCompanion;
  final Color accent;
  final AppLocalizations l10n;
  final bool presentInTamil;
  final ValueChanged<Scheme>? onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    final turnLimit = isCompanion ? 8 : 3;
    final visibleTurns = conversationTurns.length <= turnLimit
        ? conversationTurns
        : conversationTurns.sublist(conversationTurns.length - turnLimit);
    return Semantics(
      container: true,
      label: l10n.voiceConversationTranscript,
      child: Container(
        key: const Key('voice-conversation-transcript'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: accent, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.voiceConversation,
                  style: AppGoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final turn in visibleTurns)
              VoiceTranscriptBubble(
                turn: turn,
                presentInTamil: presentInTamil,
                l10n: l10n,
                onSchemeSelected: onSchemeSelected,
              ),
          ],
        ),
      ),
    );
  }
}
