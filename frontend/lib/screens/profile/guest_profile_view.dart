import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../widgets/common/sign_in_required_sheet.dart';
import '../regular_mode/home/home_profile_completion_card.dart';
import 'profile_navigation_sections.dart';

/// The Profile tab for a guest (DEV 1 task 1.5). A guest has no account
/// profile, so instead of the profile cards this shows its status as
/// Pending, the shared completion card at 0%, and a way to sign in. Settings,
/// help and about stay reachable.
class GuestProfileView extends StatelessWidget {
  const GuestProfileView({super.key, required this.provider});

  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PendingStatusChip(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.guestProfilePendingNote,
                style: context.text.body.copyWith(color: AppColors.textBody),
              ),
              const SizedBox(height: AppSpacing.lg),
              HomeProfileCompletionCard(provider: provider),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('guest-profile-sign-in'),
                  style: FilledButton.styleFrom( // style-ok: CTA height
                    minimumSize: const Size.fromHeight(AppSize.tapTarget),
                  ),
                  onPressed: () => openSignIn(context),
                  child: Text(l10n.guestSignInAction),
                ),
              ),
            ],
          ),
        ),
        const ProfileNavigationCard2(),
      ],
    );
  }
}

/// "Pending" status: the profile exists only on this phone until sign-in.
class _PendingStatusChip extends StatelessWidget {
  const _PendingStatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: AppSize.iconSm,
            color: AppColors.warningOnSoft,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.l10n.guestProfilePending,
            style: context.text.label.copyWith(color: AppColors.warningOnSoft),
          ),
        ],
      ),
    );
  }
}
