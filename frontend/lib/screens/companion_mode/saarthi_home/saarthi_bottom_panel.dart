import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../saarthi_message.dart';
import 'saarthi_home_models.dart';
import '../../../utils/app_text.dart';

/// Labeled accessible button control used inside [SaarthiAccessibleVoiceControls].
class SaarthiLabeledControl extends StatelessWidget {
  const SaarthiLabeledControl({
    super.key,
    required this.controlKey,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Key controlKey;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: controlKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.tight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(height: AppSpacing.tight),
                FitOneLine(
                  child: Text(
                    label,
                    style: AppGoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Start voice speaking button when companion mode is in idle state.
class SaarthiStartVoiceButton extends StatelessWidget {
  const SaarthiStartVoiceButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.companionStartSpeakingSemantic,
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton.icon(
          key: const Key('saarthi-start-speaking'),
          onPressed: () {
            unawaited(HapticFeedback.mediumImpact());
            onPressed();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.mic_rounded, size: 27),
          label: Text(
            context.l10n.companionTapToSpeak,
            style: AppGoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// Voice status banner indicating current speech activity (listening/processing/speaking).
class SaarthiVoiceStatusBanner extends StatelessWidget {
  const SaarthiVoiceStatusBanner({
    super.key,
    required this.voiceState,
    required this.cloudConnectionError,
    required this.cloudRetrying,
  });

  final SaarthiVoiceState voiceState;
  final String? cloudConnectionError;
  final bool cloudRetrying;

  @override
  Widget build(BuildContext context) {
    final statusText = SaarthiHomeHelpers.voiceStatusText(
      context,
      voiceState,
      cloudConnectionError: cloudConnectionError,
      cloudRetrying: cloudRetrying,
    );

    final icon = cloudConnectionError != null
        ? Icons.error_outline_rounded
        : cloudRetrying
        ? Icons.sync_rounded
        : switch (voiceState) {
            SaarthiVoiceState.listening => Icons.hearing_rounded,
            SaarthiVoiceState.processing => Icons.search_rounded,
            SaarthiVoiceState.speaking => Icons.volume_up_rounded,
            _ => Icons.mic_none_rounded,
          };
    final color = SaarthiHomeHelpers.statusColor(
      voiceState,
      cloudConnectionError: cloudConnectionError,
    );

    return Semantics(
      liveRegion: true,
      label: statusText,
      child: Container(
        key: const Key('saarthi-voice-status'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: AppGoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accessible voice controls for companion mode (primary mic button + end call).
class SaarthiAccessibleVoiceControls extends StatelessWidget {
  const SaarthiAccessibleVoiceControls({
    super.key,
    required this.voiceState,
    required this.onPrimaryMicTap,
    required this.onEndConversation,
  });

  final SaarthiVoiceState voiceState;
  final VoidCallback onPrimaryMicTap;
  final VoidCallback onEndConversation;

  @override
  Widget build(BuildContext context) {
    final listening = voiceState == SaarthiVoiceState.listening;
    final speaking = voiceState == SaarthiVoiceState.speaking;
    final primaryColor = listening
        ? const Color(0xFF047857)
        : speaking
        ? const Color(0xFF7C3AED)
        : const Color(0xFF1D4ED8);
    final primaryIcon = listening
        ? Icons.stop_rounded
        : speaking
        ? Icons.front_hand_rounded
        : Icons.mic_rounded;
    final primaryLabel = listening
        ? context.l10n.companionStop
        : speaking
        ? context.l10n.companionInterrupt
        : context.l10n.companionSpeak;

    return Container(
      key: const Key('saarthi-accessible-controls'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Semantics(
              button: true,
              label: context.l10n.saarthiVoiceControlLabel(primaryLabel),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: primaryColor,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      key: const Key('saarthi-primary-voice-control'),
                      customBorder: const CircleBorder(),
                      onTap: onPrimaryMicTap,
                      child: SizedBox.square(
                        dimension: 72,
                        child: Icon(primaryIcon, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  FitOneLine(
                    child: Text(
                      primaryLabel,
                      style: AppGoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: SaarthiLabeledControl(
              controlKey: const Key('saarthi-end-control'),
              icon: Icons.call_end_rounded,
              label: context.l10n.companionEnd,
              color: const Color(0xFFB91C1C),
              onTap: () {
                unawaited(HapticFeedback.mediumImpact());
                onEndConversation();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom control panel for Saarthi companion mode handling idle trigger card,
/// live status banner, accessible voice buttons, and cloud connection indicators.
class SaarthiBottomPanel extends StatelessWidget {
  const SaarthiBottomPanel({
    super.key,
    required this.isConversationActive,
    required this.voiceState,
    required this.usingCloudVoice,
    required this.cloudRetrying,
    required this.cloudConnectionError,
    required this.onStartConversation,
    required this.onPrimaryMicTap,
    required this.onEndConversation,
    required this.onRetryCloudVoice,
  });

  final bool isConversationActive;
  final SaarthiVoiceState voiceState;
  final bool usingCloudVoice;
  final bool cloudRetrying;
  final String? cloudConnectionError;
  final VoidCallback onStartConversation;
  final VoidCallback onPrimaryMicTap;
  final VoidCallback onEndConversation;
  final VoidCallback onRetryCloudVoice;

  @override
  Widget build(BuildContext context) {
    const Color kBrandBlue = Color(0xFF2563EB);
    const Color kDarkSlate = Color(0xFF0F172A);
    const Color kSlate500 = Color(0xFF64748B);

    if (!isConversationActive) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onStartConversation,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEFF6FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kBrandBlue.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      context.l10n.companionAskAnything,
                      style: AppGoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: kDarkSlate,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      context.l10n.companionTapToSpeakHint,
                      style: AppGoogleFonts.inter(fontSize: 10, color: kSlate500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SaarthiStartVoiceButton(onPressed: onStartConversation),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SaarthiVoiceStatusBanner(
            voiceState: voiceState,
            cloudConnectionError: cloudConnectionError,
            cloudRetrying: cloudRetrying,
          ),
          if (cloudConnectionError != null) ...[
            const SizedBox(height: AppSpacing.tight),
            Text(
              cloudConnectionError!,
              textAlign: TextAlign.center,
              style: AppGoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFFB91C1C),
              ),
            ),
            TextButton.icon(
              key: const Key('saarthi-cloud-retry'),
              onPressed: cloudRetrying ? null : onRetryCloudVoice,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(
                CentralizedTranslator.instance.localize('Retry voice'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SaarthiAccessibleVoiceControls(
            voiceState: voiceState,
            onPrimaryMicTap: onPrimaryMicTap,
            onEndConversation: onEndConversation,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                usingCloudVoice
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_sync_outlined,
                size: 12,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: FitOneLine(
                  child: Text(
                    usingCloudVoice
                        ? context.l10n.companionSecureLiveSession
                        : context.l10n.companionLiveConnectionRequired,
                    style: AppGoogleFonts.inter(
                      fontSize: 9.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
