import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_elevation.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../utils/constants.dart';
import '../../../widgets/common/app_icon_button.dart';
import '../../../widgets/common/app_tappable.dart';
import '../../../widgets/common/quick_pills.dart';
import '../../../widgets/onboarding/home_tour_targets.dart';
import 'home_language_button.dart';

class HomeHeaderSection extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback? onSearchBarTap;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onVoiceQuery;
  final VoidCallback onNotificationTap;

  const HomeHeaderSection({
    super.key,
    required this.provider,
    this.onSearchBarTap,
    this.onFilterPressed,
    this.onVoiceQuery,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGreetingAndNotifications(context),
        const SizedBox(height: AppSpacing.xxl),
        _buildSearchAndFilter(context),
        const SizedBox(height: AppSpacing.sm),
        QuickPills(
          onSelected: (q) {
            if (onVoiceQuery != null) {
              onVoiceQuery!(q);
            } else {
              provider.updateSearchQuery(q);
              provider.updateTabIndex(1);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGreetingAndNotifications(BuildContext context) {
    final displayName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ').first
        : context.l10n.commonUserFallback;
    final unread = provider.notifications
        .where((n) => n['read'] == false)
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      AppConstants.getTimeGreeting(context.l10n),
                      style: context.text.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ExcludeSemantics(
                    child: Text("👋", style: AppGoogleFonts.inter(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.hairline),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style:
                          (provider.isGuest
                                  ? context.text.titleMedium
                                  : context.text.headline)
                              .copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!provider.isGuest) ...[
                    const SizedBox(width: AppSpacing.tight),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Solid brand-blue buttons: the background art has white round icons
        // (chart, rupee, people) right here, and white buttons blended in.
        Row(
          children: [
            HomeHeaderAction(child: HomeLanguageButton(provider: provider)),
            const SizedBox(width: AppSpacing.sm),
            HomeHeaderAction(
              child: AppIconButton(
                icon: Icons.notifications_none_rounded,
                semanticLabel: context.l10n.notificationsTooltip,
                badgeSemantics: unread > 0
                    ? context.l10n.notificationsUnreadCount(unread)
                    : null,
                badgeCount: unread > 0 ? unread : null,
                size: AppSize.iconLg,
                color: AppColors.textOnPrimary,
                backgroundColor: AppColors.primary,
                backgroundSize: 40,
                onPressed: onNotificationTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      key: HomeTourTargets.search,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTappable(
              onTap: () => onSearchBarTap?.call(),
              semanticLabel: context.l10n.searchPlaceholder,
              minSize: const Size(AppSize.tapTarget, AppSize.tapTarget),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.searchPlaceholder,
                      style: context.text.body.copyWith(
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 20, width: 1, color: AppColors.border),
          const SizedBox(width: AppSpacing.sm),
          AppTappable(
            onTap: () {
              if (onFilterPressed != null) {
                onFilterPressed!();
              } else {
                provider.updateTabIndex(1);
              }
            },
            semanticLabel: context.l10n.filter,
            borderRadius: AppRadius.pillAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.tight,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: AppRadius.pillAll,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: AppSize.iconSm,
                    color: Color(0xFF1E293B),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.l10n.filter,
                    style: context.text.label.copyWith(
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A raised header button: a soft brand-coloured glow so it reads as a
/// control, not as part of the background illustration.
class HomeHeaderAction extends StatelessWidget {
  const HomeHeaderAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
