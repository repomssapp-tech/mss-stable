import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../models/scheme_model.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../saarthi_message.dart';
import 'saarthi_compact_scheme_card.dart';
import 'saarthi_home_models.dart';

/// Animated waveform bar indicating live assistant speech.
class SaarthiWaveformBar extends StatelessWidget {
  const SaarthiWaveformBar({
    super.key,
    required this.height,
    required this.animDelay,
    required this.waveController,
  });

  final double height;
  final double animDelay;
  final AnimationController waveController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveController,
      builder: (context, child) {
        final scale =
            0.5 +
            0.5 * math.sin(waveController.value * math.pi * 2 + animDelay);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.hairline),
          width: 2.5,
          height: height * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      },
    );
  }
}

/// User speech bubble item in companion transcript.
class SaarthiUserMessage extends StatelessWidget {
  const SaarthiUserMessage({
    super.key,
    required this.message,
  });

  final SaarthiMessage message;

  @override
  Widget build(BuildContext context) {
    final timeStr = SaarthiHomeHelpers.formatTimestamp(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.tight,
        bottom: AppSpacing.md,
        left: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.l10n.companionYouTimestampLabel(timeStr),
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Assistant response bubble with optional speaking waveform and recommended scheme cards.
class SaarthiAiMessage extends StatelessWidget {
  const SaarthiAiMessage({
    super.key,
    required this.message,
    required this.waveController,
  });

  final SaarthiMessage message;
  final AnimationController waveController;

  @override
  Widget build(BuildContext context) {
    final timeStr = SaarthiHomeHelpers.formatTimestamp(message.timestamp);
    final isSpeaking = message.speakingState == 'speaking';

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.hairline,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEFF6FF),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/saarthi/sarathi.webp',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.companionAiTimestampLabel(timeStr),
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.42,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (isSpeaking) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SaarthiWaveformBar(
                                  height: 6,
                                  animDelay: 12,
                                  waveController: waveController,
                                ),
                                SaarthiWaveformBar(
                                  height: 9,
                                  animDelay: 6,
                                  waveController: waveController,
                                ),
                                SaarthiWaveformBar(
                                  height: 12,
                                  animDelay: 14,
                                  waveController: waveController,
                                ),
                                SaarthiWaveformBar(
                                  height: 7,
                                  animDelay: 8,
                                  waveController: waveController,
                                ),
                                SaarthiWaveformBar(
                                  height: 10,
                                  animDelay: 10,
                                  waveController: waveController,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: FitOneLine(
                                    child: Text(
                                      context.l10n.companionSpeakingBadge,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: const Color(0xFF059669),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message.schemeResults != null &&
              message.schemeResults!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.only(left: 43),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Flexible(
                        child: Text(
                          context.l10n.recommendedForYou,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.companionRankedResultsCaption,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      height: 1.35,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  ...message.schemeResults!.map(
                    (Scheme scheme) => SaarthiCompactSchemeCard(
                      scheme: scheme,
                      metadata: metadataForScheme(
                        scheme,
                        message.cloudSchemeResults,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrollable transcript section displaying user and AI messages, empty state, and scroll-to-latest button.
class SaarthiTranscriptView extends StatelessWidget {
  const SaarthiTranscriptView({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isUserScrolling,
    required this.onScrollToLatest,
    required this.waveController,
    required this.voiceStatusText,
  });

  final List<SaarthiMessage> messages;
  final ScrollController scrollController;
  final bool isUserScrolling;
  final VoidCallback onScrollToLatest;
  final AnimationController waveController;
  final String voiceStatusText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: messages.isEmpty
              ? Center(
                  key: const ValueKey('voice-empty-state'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          voiceStatusText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.tight),
                        Text(
                          context.l10n.companionEmptyStateHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            height: 1.45,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('voice-transcript-list'),
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    if (message.role == 'user') {
                      return SaarthiUserMessage(message: message);
                    }
                    return SaarthiAiMessage(
                      message: message,
                      waveController: waveController,
                    );
                  },
                ),
        ),
        if (isUserScrolling)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: onScrollToLatest,
                icon: const Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  CentralizedTranslator.instance.localize('Latest'),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
