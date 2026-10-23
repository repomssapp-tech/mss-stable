import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../basic_profile_screen.dart';
import '../../../utils/app_text.dart';

class HomeProfileCompletionCard extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback? onTap;

  const HomeProfileCompletionCard({
    super.key,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completion = provider.profileCompletionPercentage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BasicProfileScreen()),
              );
            },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: ResizeImage(
                AssetImage(
                  'assets/images/Background/profile process banner.webp',
                ),
                width: 1080,
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: Progress ring with percent text inside
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: completion / 100.0,
                      strokeWidth: 4.0,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(
                        0xFFEFF6FF,
                      ).withValues(alpha: 0.8),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  Text(
                    "$completion%",
                    style: AppGoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),

              // Vertical Divider Line
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.md),

              // Middle: Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.completeYourProfile,
                      style: AppGoogleFonts.poppins(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.unlockPersonalizedSchemeRecommendations,
                      style: AppGoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Spacer to prevent text from overlapping the background banner image's built-in graphic
              const SizedBox(width: 84),
            ],
          ),
        ),
      ),
    );
  }
}
