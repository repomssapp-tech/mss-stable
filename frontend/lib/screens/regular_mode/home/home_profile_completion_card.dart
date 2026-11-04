import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
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
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.lgAll,
          image: DecorationImage(
            image: ResizeImage(
              AssetImage(
                'assets/images/Background/profile process banner.webp',
              ),
              width: 1080,
            ),
            fit: BoxFit.cover,
            // The art sits on the right; keep it in view on tall cards.
            alignment: Alignment.centerRight,
          ),
        ),
        child: InkWell(
          onTap:
              onTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BasicProfileScreen()),
                );
              },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                // Progress ring with the percent inside.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: AppSize.tapTarget,
                      height: AppSize.tapTarget,
                      child: CircularProgressIndicator(
                        value: completion / 100.0,
                        strokeWidth: 4.0,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.primarySoft,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      "$completion%",
                      style: context.text.label.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.completeYourProfile,
                        style: context.text.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.unlockPersonalizedSchemeRecommendations,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                // Keeps the text clear of the banner's own art on the right.
                const SizedBox(width: 84), // spacing-ok: banner art width
              ],
            ),
          ),
        ),
      ),
    );
  }
}
