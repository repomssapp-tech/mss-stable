import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import 'language_selection_screen.dart';
import 'basic_profile_screen.dart';
import 'help_support_screen.dart';
import 'legal_screens.dart';
import '../../widgets/common/custom_confirm_dialog.dart';
import '../../widgets/scheme/catalog_freshness_footer.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../utils/language_names.dart';
import '../../utils/app_version.dart';
import '../../services/app_info_service.dart';
import '../../services/haptics/haptics_service.dart';
import '../../services/updates/app_update_service.dart';
import '../../widgets/common/app_update_prompt.dart';
import '../../design_v2/saarthi/saarthi_voice_settings_screen.dart';
import 'settings/active_sessions_dialog.dart';
import 'settings/delete_account_screen.dart';
import 'settings/settings_parts.dart';
import '../../widgets/common/standard_page_header.dart';
import '../../widgets/legal/copyright_notice.dart';
import '../../services/location_lock/location_lock_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _handleDeleteAccount(BuildContext context) {
    CustomConfirmDialog.show(
      context,
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.dangerStrong,
      iconBgColor: AppColors.dangerSoft,
      title: context.l10n.deleteAccountTitle,
      message: context.l10n.deleteAccountMsg,
      confirmLabel: context.l10n.deleteButton,
      confirmColor: AppColors.danger,
      onConfirm: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const DeleteAccountScreen(),
        ),
      ),
      isDestructive: true,
    );
  }

  void _handleLogout(BuildContext context, AppProvider provider) {
    CustomConfirmDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: AppColors.dangerStrong,
      iconBgColor: AppColors.dangerSoft,
      title: context.l10n.confirmLogoutTitle,
      message: context.l10n.confirmLogoutMsg,
      confirmLabel: context.l10n.logoutButton,
      confirmColor: AppColors.danger,
      onConfirm: () => provider.logout(context),
      isDestructive: true,
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final l10n = context.l10n;
    // The Profile tab already shows the user's card and Edit Profile, so
    // repeating them here showed two different profile pages back to back.
    // Companion mode has no tab bar, so there Settings is the profile view.
    final showProfile = provider.navigationMode == 'companion';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardPageHeader(
        title: l10n.profileSettingsTitle,
        elevation: 1,
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            if (showProfile) ...[
              const SizedBox(height: AppSpacing.md),
              SettingsProfileHeader(provider: provider),
              SettingsGroupHeader(l10n.profileGroupHeader),
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.person_outline_rounded,
                    // A finished profile is edited, not completed. The
                    // progress goes under the title, so the title keeps the
                    // whole row width and never wraps.
                    title: provider.profileCompletionPercentage >= 100
                        ? l10n.editProfile
                        : l10n.completeProfileTitle,
                    subtitle: l10n.profileCompletionFormat(
                      provider.profileCompletionPercentage,
                    ),
                    onTap: () => _push(context, const BasicProfileScreen()),
                    isLast: true,
                  ),
                ],
              ),
            ],

            SettingsGroupHeader(l10n.preferencesGroupHeader),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.language_rounded,
                  title: l10n.languageSetting,
                  value: languageEndonym(provider.selectedLanguage),
                  onTap: () => _push(
                    context,
                    const LanguageSelectionScreen(isOnboarding: false),
                  ),
                ),
                SettingsRow(
                  icon: Icons.explore_outlined,
                  title: l10n.navigationModeSetting,
                  value: provider.navigationMode == 'companion'
                      ? l10n.navigationModeCompanion
                      : l10n.navigationModeRegular,
                  onTap: () => showNavigationModeDialog(context, provider),
                ),
                SettingsRow(
                  icon: Icons.record_voice_over_outlined,
                  title: l10n.settingsSaarthiVoice,
                  onTap: () =>
                      _push(context, const SaarthiVoiceSettingsScreen()),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: HapticsService.instance.enabled,
                  builder: (context, on, _) => SettingsRow(
                    icon: Icons.vibration_rounded,
                    title: l10n.settingsHapticsTitle,
                    subtitle: l10n.settingsHapticsSubtitle,
                    control: Switch(
                      value: on,
                      onChanged: HapticsService.instance.setEnabled,
                    ),
                    onTap: () => HapticsService.instance.setEnabled(!on),
                    isLast: true,
                  ),
                ),
              ],
            ),

            // A Notifications group was removed (2.0): the switch controlled
            // nothing -- no push delivery exists anywhere in this app. Re-add
            // it here, wired to provider.profile.notificationsEnabled (kept,
            // still persisted), once a real push-delivery path reads that
            // field server-side.
            SettingsGroupHeader(l10n.securityPrivacyGroupHeader),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.devices_outlined,
                  title: l10n.activeSessionsSetting,
                  onTap: () => ActiveSessionsDialog.show(context),
                ),
                SettingsRow(
                  icon: Icons.shield_outlined,
                  title: l10n.privacyPolicySetting,
                  onTap: () => _push(context, const PrivacyPolicyScreen()),
                ),
                SettingsRow(
                  icon: Icons.article_outlined,
                  title: l10n.termsConditionsSetting,
                  onTap: () => _push(context, const TermsConditionsScreen()),
                ),
                SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  title: l10n.deleteAccountSetting,
                  danger: true,
                  onTap: () => _handleDeleteAccount(context),
                  isLast: true,
                ),
              ],
            ),

            SettingsGroupHeader(l10n.supportGroupHeader),
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.help_outline_rounded,
                  title: l10n.helpHeaderSupport,
                  onTap: () => _push(
                    context,
                    const HelpSupportScreen(initialMode: 'faq'),
                  ),
                ),
                SettingsRow(
                  icon: Icons.contact_support_outlined,
                  title: l10n.contactUsSetting,
                  onTap: () => _push(
                    context,
                    const HelpSupportScreen(initialMode: 'contact'),
                  ),
                ),
                // The app is sideloaded: new builds are only on GitHub
                // releases.
                FutureBuilder<AppVersion?>(
                  future: AppInfoService.installedVersion(),
                  builder: (context, snapshot) {
                    final v = snapshot.data;
                    return SettingsRow(
                      icon: Icons.system_update_outlined,
                      title: l10n.settingsCheckUpdates,
                      subtitle: v == null
                          ? null
                          : l10n.settingsInstalledVersion(v.label),
                      onTap: () => openUpdateLink(
                        context,
                        AppUpdateService.latestReleasePage,
                      ),
                      isLast: true,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),

            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: AppSize.iconSm),
              label: Text(l10n.logoutButton),
              onPressed: () => _handleLogout(context, provider),
            ),
            const SizedBox(height: AppSpacing.lg),

            // The installed build's real version (was a stale '1.2.0'
            // literal).
            Center(
              child: FutureBuilder<AppVersion?>(
                future: AppInfoService.installedVersion(),
                builder: (context, snapshot) {
                  final v = snapshot.data;
                  final label = v == null
                      ? ''
                      : l10n.settingsAppVersion(v.label);
                  return Text(
                    kIsDevChannel && label.isNotEmpty
                        ? '$label · ${l10n.locationDevBuildBadge}'
                        : label,
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  );
                },
              ),
            ),
            const CatalogFreshnessFooter(),
            const CopyrightNotice.line(),
          ],
        ),
      ),
    );
  }
}
