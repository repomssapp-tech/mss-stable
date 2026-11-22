import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../basic_profile_screen.dart';
import '../../../widgets/common/sign_in_required_sheet.dart';
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
    // A guest has no account profile yet: always 0%, and the card leads to
    // sign-in instead of the profile form.
    final guest = provider.isGuest;
    final completion = guest ? 0 : provider.profileCompletionPercentage;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(
          onTap:
              onTap ??
              () {
                if (guest) {
                  SignInRequiredSheet.show(context);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BasicProfileScreen(resume: true),
                  ),
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
                        guest
                            ? context.l10n.guestProfileIncomplete
                            : context.l10n.completeYourProfile,
                        style: context.text.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        guest
                            ? context.l10n.guestProfileSignInPrompt
                            : context
                                  .l10n
                                  .unlockPersonalizedSchemeRecommendations,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
