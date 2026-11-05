import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_size.dart';
import '../utils/app_spacing.dart';
import 'notifications_screen.dart';
import 'profile/profile_banner_card.dart';
import 'profile/profile_eligibility_details_card.dart';
import 'profile/profile_navigation_sections.dart';
import 'profile/profile_user_info_card.dart';
import '../utils/app_text.dart';

// Re-exports for clean modular access and backwards compatibility
export 'profile/avatar_cache_manager.dart';
export 'profile/profile_about_dialog.dart';
export 'profile/profile_banner_card.dart';
export 'profile/profile_eligibility_details_card.dart';
export 'profile/profile_navigation_sections.dart';
export 'profile/profile_photo_handler.dart';
export 'profile/profile_user_info_card.dart';
export 'profile/profile_value_formatters.dart';
export 'profile/profile_widgets.dart';

/// Clean coordinator for the Profile view.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final unreadCount = provider.unreadNotificationCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.profileTitle,
          style: context.text.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Notification bell; the badge carries the unread count.
          IconButton(
            tooltip: context.l10n.notificationsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppColors.danger,
              label: Text('$unreadCount'),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: AppSize.iconLg,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            ProfileBannerCard(provider: provider),
            ProfileUserInfoCard(provider: provider),
            ProfileEligibilityDetailsCard(provider: provider),
            ProfileNavigationCard1(provider: provider),
            const ProfileNavigationCard2(),
            ProfileLogoutCard(provider: provider),
            // Room to scroll the last card clear of the floating nav bar.
            SizedBox(
              height: AppSpacing.xxxl + MediaQuery.paddingOf(context).bottom,
            ),
          ],
        ),
      ),
    );
  }
}
