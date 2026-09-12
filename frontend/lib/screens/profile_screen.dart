import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_spacing.dart';
import '../utils/constants.dart';
import 'notifications_screen.dart';
import 'profile/profile_banner_card.dart';
import 'profile/profile_eligibility_details_card.dart';
import 'profile/profile_navigation_sections.dart';
import 'profile/profile_user_info_card.dart';

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
    final unreadCount = provider.notifications.where((n) => !n['read']).length;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          context.l10n.profileTitle,
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Notification Bell with Badge
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.hairline),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
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
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
