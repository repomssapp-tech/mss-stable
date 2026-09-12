import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive.dart';
import '../saarthi_message.dart';
import 'saarthi_home_models.dart';

/// Character header banner and compact active status header for Saarthi companion mode.
class SaarthiCharacterHeader extends StatelessWidget {
  const SaarthiCharacterHeader({
    super.key,
    required this.isConversationActive,
    required this.userName,
    required this.voiceState,
    required this.usingCloudVoice,
    required this.cloudRetrying,
    required this.cloudConnectionError,
  });

  final bool isConversationActive;
  final String userName;
  final SaarthiVoiceState voiceState;
  final bool usingCloudVoice;
  final bool cloudRetrying;
  final String? cloudConnectionError;

  @override
  Widget build(BuildContext context) {
    const Color kDarkSlate = Color(0xFF0F172A);
    final statusColor = SaarthiHomeHelpers.statusColor(
      voiceState,
      cloudConnectionError: cloudConnectionError,
    );
    final statusLabel = SaarthiHomeHelpers.statusLabel(
      context,
      voiceState,
      cloudConnectionError: cloudConnectionError,
      cloudRetrying: cloudRetrying,
    );

    if (isConversationActive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.28),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/saarthi/sarathi.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MSS Saarthi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kDarkSlate,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        statusLabel,
                        key: ValueKey(voiceState),
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.tight,
                ),
                decoration: BoxDecoration(
                  color: cloudConnectionError == null
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cloudConnectionError == null
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cloudConnectionError == null
                          ? Icons.graphic_eq_rounded
                          : Icons.cloud_off_outlined,
                      size: 14,
                      color: cloudConnectionError == null
                          ? const Color(0xFF047857)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: FitOneLine(
                        child: Text(
                          usingCloudVoice
                              ? context.l10n.companionVoiceConnected
                              : cloudRetrying
                              ? context.l10n.companionConnectingShort
                              : context.l10n.companionVoiceOffline,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: cloudConnectionError == null
                                ? const Color(0xFF047857)
                                : const Color(0xFFDC2626),
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
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                width: isConversationActive ? 56 : 170,
                height: isConversationActive ? 56 : 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                    width: isConversationActive ? 2 : 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/saarthi/sarathi.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!isConversationActive) ...[
                const Positioned(
                  left: 0,
                  top: 55,
                  child: Icon(Icons.star, color: Color(0xFF93C5FD), size: 14),
                ),
                const Positioned(
                  right: 0,
                  top: 45,
                  child: Icon(Icons.star, color: Color(0xFF93C5FD), size: 16),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.tight),
        Column(
          children: [
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kDarkSlate,
                  ),
                  children: [
                    TextSpan(
                      text: '${AppConstants.getTimeGreeting(context.l10n)} ',
                    ),
                    TextSpan(
                      text: '$userName! 👋',
                      style: const TextStyle(color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.hairline),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: kDarkSlate,
                  ),
                  children: [
                    TextSpan(text: '${context.l10n.companionIntroPrefix} '),
                    const TextSpan(
                      text: 'Saarthi',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: context.l10n.companionIntroSuffix),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
