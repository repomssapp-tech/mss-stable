import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n.dart';
import 'language_selection_screen.dart';
import 'basic_profile_screen.dart';
import 'help_support_screen.dart';
import 'legal_screens.dart';
import '../../widgets/common/custom_confirm_dialog.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/scheme/catalog_freshness_footer.dart';
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _handleDeleteAccount(BuildContext context, AppProvider provider) {
    CustomConfirmDialog.show(
      context,
      icon: Icons.delete_forever_rounded,
      iconColor: AppConstants.errorColor,
      iconBgColor: const Color(0xFFFEE2E2),
      title: context.l10n.deleteAccountTitle,
      message: context.l10n.deleteAccountMsg,
      confirmLabel: context.l10n.deleteButton,
      confirmColor: AppConstants.errorColor,
      onConfirm: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const DeleteAccountScreen(),
        ),
      ),
      isDestructive: true,
    );
  }

  void _showNavigationModePopup(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.l10n.navigationModeSetting,
                        style: AppGoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                      tooltip: context.l10n.close,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.l10n.settingsNavModeDialogBody,
                  style: AppGoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildModeOption(
                  context: context,
                  provider: provider,
                  mode: 'regular',
                  title: context.l10n.navRegularNavigationTitle,
                  subtitle: context.l10n.settingsRegularSubtitle,
                  icon: Icons.layers_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildModeOption(
                  context: context,
                  provider: provider,
                  mode: 'companion',
                  title: context.l10n.settingsCompanionTitle,
                  subtitle: context.l10n.settingsCompanionSubtitle,
                  icon: Icons.chat_bubble_outline_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required AppProvider provider,
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = provider.navigationMode == mode;
    return InkWell(
      onTap: () async {
        final navigator = Navigator.of(context, rootNavigator: true);
        navigator.pop();
        await provider.changeNavigationMode(mode);
        provider.updateTabIndex(0);
        navigator.popUntil((route) => route.isFirst);
        if (context.mounted) {
          AppToast.showSuccess(
            context,
            mode == 'companion'
                ? context.l10n.settingsSwitchedToCompanion
                : context.l10n.settingsSwitchedToRegular,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppGoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    subtitle,
                    style: AppGoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    // The Profile tab already shows the user's card and Edit Profile, so
    // repeating them here showed two different profile pages back to back.
    // Companion mode has no tab bar, so there Settings is the profile view.
    final showProfile = provider.navigationMode == 'companion';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          tooltip: context.l10n.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.profileSettingsTitle,
          style: AppGoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Adaptive Profile Header Card
            if (showProfile)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: provider.effectiveProfilePhoto.isNotEmpty
                          ? ClipOval(
                              child: () {
                                final photo = provider.effectiveProfilePhoto;
                                Widget buildFallbackText() => Text(
                                  provider.profile.name.isNotEmpty
                                      ? provider.profile.name[0].toUpperCase()
                                      : 'U',
                                  style: AppGoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
                                );

                                if (photo.startsWith('http://') ||
                                    photo.startsWith('https://')) {
                                  return Image.network(
                                    photo,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            buildFallbackText(),
                                  );
                                }
                                if (File(photo).existsSync()) {
                                  return Image.file(
                                    File(photo),
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            buildFallbackText(),
                                  );
                                }
                                return buildFallbackText();
                              }(),
                            )
                          : Text(
                              provider.profile.name.isNotEmpty
                                  ? provider.profile.name[0].toUpperCase()
                                  : 'U',
                              style: AppGoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.profile.name.isNotEmpty
                                ? provider.profile.name
                                : context.l10n.commonUserFallback,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppGoogleFonts.poppins(
                              fontSize: provider.selectedLanguage == 'ta'
                                  ? 14.5
                                  : 16.0,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              height: provider.selectedLanguage == 'ta'
                                  ? 1.35
                                  : 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.hairline),
                          Text(
                            provider.profile.mobile.isNotEmpty
                                ? provider.profile.mobile
                                : (provider.mobileNumber.isNotEmpty
                                      ? provider.mobileNumber
                                      : '+91'),
                            style: AppGoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.tight),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.l10n.profileCompletionFormat(
                                provider.profileCompletionPercentage,
                              ),
                              style: AppGoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // GROUP 0: Profile
            if (showProfile) _buildGroupHeader(context.l10n.profileGroupHeader),
            if (showProfile)
              _buildGroupContainer([
                _buildSettingRow(
                  icon: Icons.person_outline,
                  // A finished profile is edited, not completed. The progress goes
                  // under the title (not beside it), so the title keeps the whole
                  // row width and never wraps.
                  title: provider.profileCompletionPercentage >= 100
                      ? context.l10n.editProfile
                      : context.l10n.completeProfileTitle,
                  subtitle: context.l10n.profileCompletionFormat(
                    provider.profileCompletionPercentage,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BasicProfileScreen(),
                      ),
                    );
                  },
                  isLast: true,
                ),
              ]),

            // GROUP 1: Preferences
            _buildGroupHeader(context.l10n.preferencesGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.language,
                title: context.l10n.languageSetting,
                value: languageEndonym(provider.selectedLanguage),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const LanguageSelectionScreen(isOnboarding: false),
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.explore_outlined,
                title: context.l10n.navigationModeSetting,
                value: provider.navigationMode == 'companion'
                    ? context.l10n.navigationModeCompanion
                    : context.l10n.navigationModeRegular,
                onTap: () => _showNavigationModePopup(context, provider),
              ),
              _buildSettingRow(
                icon: Icons.record_voice_over_outlined,
                title: context.l10n.settingsSaarthiVoice,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SaarthiVoiceSettingsScreen(),
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: HapticsService.instance.enabled,
                builder: (context, on, _) => _buildSettingRow(
                  icon: Icons.vibration_rounded,
                  title: context.l10n.settingsHapticsTitle,
                  subtitle: context.l10n.settingsHapticsSubtitle,
                  widget: Switch(
                    value: on,
                    onChanged: HapticsService.instance.setEnabled,
                  ),
                  onTap: () => HapticsService.instance.setEnabled(!on),
                  isLast: true,
                ),
              ),
            ]),

            // GROUP 3 (Notifications) removed (2.0): the switch controlled
            // nothing -- no push delivery exists anywhere in this app. Re-add
            // it here, wired to provider.profile.notificationsEnabled (kept,
            // still persisted), once a real push-delivery path reads that
            // field server-side.

            // GROUP 4: Security & Privacy
            _buildGroupHeader(context.l10n.securityPrivacyGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.devices_outlined,
                title: context.l10n.activeSessionsSetting,
                onTap: () => ActiveSessionsDialog.show(context),
              ),
              _buildSettingRow(
                icon: Icons.security,
                title: context.l10n.privacyPolicySetting,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.article_outlined,
                title: context.l10n.termsConditionsSetting,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsScreen(),
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.delete_outline,
                title: context.l10n.deleteAccountSetting,
                titleColor: const Color(0xFFDC2626),
                onTap: () => _handleDeleteAccount(context, provider),
                isLast: true,
              ),
            ]),

            // GROUP 5: Support
            _buildGroupHeader(context.l10n.supportGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.help_outline,
                title: context.l10n.helpHeaderSupport,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const HelpSupportScreen(initialMode: 'faq'),
                    ),
                  );
                },
              ),
              _buildSettingRow(
                icon: Icons.contact_support_outlined,
                title: context.l10n.contactUsSetting,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const HelpSupportScreen(initialMode: 'contact'),
                    ),
                  );
                },
              ),
              // The app is sideloaded: new builds are only on GitHub releases.
              FutureBuilder<AppVersion?>(
                future: AppInfoService.installedVersion(),
                builder: (context, snapshot) {
                  final v = snapshot.data;
                  return _buildSettingRow(
                    icon: Icons.system_update_outlined,
                    title: context.l10n.settingsCheckUpdates,
                    subtitle: v == null
                        ? null
                        : context.l10n.settingsInstalledVersion(v.label),
                    onTap: () => openUpdateLink(
                      context,
                      AppUpdateService.latestReleasePage,
                    ),
                    isLast: true,
                  );
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.xxxl),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(
                context.l10n.logoutButton,
                style: AppGoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                CustomConfirmDialog.show(
                  context,
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.danger,
                  iconBgColor: const Color(0xFFFEE2E2),
                  title: context.l10n.confirmLogoutTitle,
                  message: context.l10n.confirmLogoutMsg,
                  confirmLabel: context.l10n.logoutButton,
                  confirmColor: AppColors.danger,
                  onConfirm: () => provider.logout(context),
                  isDestructive: true,
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Centered App Version Footer
            // The installed build's real version (was a stale '1.2.0' literal).
            Center(
              child: FutureBuilder<AppVersion?>(
                future: AppInfoService.installedVersion(),
                builder: (context, snapshot) {
                  final v = snapshot.data;
                  return Text(
                    v == null ? '' : context.l10n.settingsAppVersion(v.label),
                    style: AppGoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            const CatalogFreshnessFooter(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppGoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? subtitle,
    String? value,
    Widget? widget,
    VoidCallback? onTap,
    Color? titleColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.hairline,
          ),
          leading: Icon(
            icon,
            color: titleColor ?? const Color(0xFF2563EB),
            size: 20,
          ),
          title: Text(
            title,
            style: AppGoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: titleColor ?? const Color(0xFF0F172A),
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: context.text.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
          trailing:
              widget ??
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value != null)
                      Flexible(
                        child: FitOneLine(
                          alignment: Alignment.centerRight,
                          child: Text(
                            value,
                            style: AppGoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF94A3B8),
                      size: 16,
                    ),
                  ],
                ),
              ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}
