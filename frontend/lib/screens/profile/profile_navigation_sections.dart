import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/common/custom_confirm_dialog.dart';
import '../regular_mode/help_support_screen.dart';
import '../regular_mode/language_selection_screen.dart';
import '../regular_mode/settings_screen.dart';
import 'profile_about_dialog.dart';
import 'profile_widgets.dart';

/// Navigation section 1: Saved Schemes & Language Selection.
class ProfileNavigationCard1 extends StatelessWidget {
  final AppProvider provider;

  const ProfileNavigationCard1({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileGroupCard(
      tiles: [
        ProfileTile(
          icon: Icons.bookmark_border_outlined,
          iconColor: const Color(0xFFEA580C),
          iconBgColor: const Color(0xFFFFF3E0),
          title: context.l10n.navSaved,
          subtitle: context.l10n.subSavedSchemes,
          onTap: () {
            provider.updateTabIndex(3);
          },
        ),
        ProfileTile(
          icon: Icons.language_outlined,
          iconColor: const Color(0xFF7C3AED),
          iconBgColor: const Color(0xFFF3E8FF),
          title: context.l10n.languageSetting,
          subtitle: context.l10n.subLanguage,
          trailingText: provider.selectedLanguage == 'ta' ? 'தமிழ்' : 'English',
          showDivider: false,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(isOnboarding: false),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Navigation section 2: Settings, Help & Support, About.
class ProfileNavigationCard2 extends StatelessWidget {
  const ProfileNavigationCard2({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileGroupCard(
      tiles: [
        ProfileTile(
          icon: Icons.settings_outlined,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
          title: context.l10n.profileSettingsTitle,
          subtitle: context.l10n.subSettings,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        ProfileTile(
          icon: Icons.chat_bubble_outline,
          iconColor: const Color(0xFFDB2777),
          iconBgColor: const Color(0xFFFCE7F3),
          title: context.l10n.helpFaqSetting,
          subtitle: context.l10n.subHelpSupport,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpSupportScreen(),
              ),
            );
          },
        ),
        ProfileTile(
          icon: Icons.info_outline,
          iconColor: const Color(0xFFCA8A04),
          iconBgColor: const Color(0xFFFEF9C3),
          title: context.l10n.aboutTitle,
          showDivider: false,
          onTap: () => showAboutAppDialog(context),
        ),
      ],
    );
  }
}

/// Logout action card with confirmation dialog.
class ProfileLogoutCard extends StatelessWidget {
  final AppProvider provider;

  const ProfileLogoutCard({
    super.key,
    required this.provider,
  });

  void _handleLogout(BuildContext context) {
    CustomConfirmDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFFEF4444),
      iconBgColor: const Color(0xFFFEE2E2),
      title: context.l10n.confirmLogoutTitle,
      message: context.l10n.confirmLogoutMsg,
      confirmLabel: context.l10n.logoutButton,
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () => provider.logout(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileGroupCard(
      tiles: [
        ProfileTile(
          icon: Icons.logout_outlined,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          title: context.l10n.logoutButton,
          subtitle: context.l10n.subLogout,
          textColor: const Color(0xFFDC2626),
          showDivider: false,
          onTap: () => _handleLogout(context),
        ),
      ],
    );
  }
}
