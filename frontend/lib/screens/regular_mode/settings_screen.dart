import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n.dart';
import 'language_selection_screen.dart';
import 'basic_profile_screen.dart';
import 'help_support_screen.dart';
import 'legal_screens.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../utils/responsive.dart';
import '../../widgets/catalog_freshness_footer.dart';
import '../../utils/app_spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;

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
      onConfirm: () => provider.deleteAccount(context),
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

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
          style: GoogleFonts.inter(
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
                                    style: GoogleFonts.poppins(
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      buildFallbackText(),
                                );
                              }
                              if (File(photo).existsSync()) {
                                return Image.file(
                                  File(photo),
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
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
                            style: GoogleFonts.poppins(
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
                              : 'User',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
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
                          style: GoogleFonts.inter(
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
                            style: GoogleFonts.poppins(
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
            _buildGroupHeader(context.l10n.profileGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.person_outline,
                title: context.l10n.completeProfileTitle,
                value: context.l10n.profileCompletionFormat(
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
                value: provider.selectedLanguage == 'ta' ? 'தமிழ்' : 'English',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );
                },
                isLast: true,
              ),
            ]),

            // GROUP 3: Notifications
            _buildGroupHeader(context.l10n.notificationsGroupHeader),
            _buildGroupContainer([
              _buildSettingRow(
                icon: Icons.notifications_none,
                title: context.l10n.pushNotificationsSetting,
                widget: SizedBox(
                  height: 24,
                  child: Switch(
                    value: _pushNotifications,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF2563EB),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ]),

            // GROUP 4: Security & Privacy
            _buildGroupHeader(context.l10n.securityPrivacyGroupHeader),
            _buildGroupContainer([
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
                title: context.l10n.helpFaqSetting,
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
                isLast: true,
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
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
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
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Centered App Version Footer
            Center(
              child: Text(
                context.l10n.settingsAppVersion('1.2.0'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            CatalogFreshnessFooter(
              isTa: provider.selectedLanguage == 'ta',
            ),
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
        style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: titleColor ?? const Color(0xFF0F172A),
            ),
          ),
          trailing:
              widget ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Flexible(
                      child: FitOneLine(
                        alignment: Alignment.centerRight,
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
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
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}
