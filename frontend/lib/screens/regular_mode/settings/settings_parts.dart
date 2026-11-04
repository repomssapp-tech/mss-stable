import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/name_initial_avatar.dart';

/// A quiet heading over a group of settings rows.
class SettingsGroupHeader extends StatelessWidget {
  const SettingsGroupHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: context.text.label.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// One bordered card holding a group of [SettingsRow]s.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// A settings row: icon, title, optional subtitle, then a value and chevron
/// or a control such as a switch.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.control,
    this.onTap,
    this.danger = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? control;
  final VoidCallback? onTap;

  /// Red title and icon, for destructive rows like deleting the account.
  final bool danger;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.dangerStrong : AppColors.primary;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, color: accent, size: AppSize.icon),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.text.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: danger
                                ? AppColors.dangerStrong
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (control != null)
                    control!
                  else ...[
                    if (value != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        value!,
                        style: context.text.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.iconMuted,
                      size: AppSize.icon,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: AppSize.borderWidth,
            thickness: AppSize.borderWidth,
            color: AppColors.border,
            indent: AppSpacing.lg + AppSize.icon + AppSpacing.md,
          ),
      ],
    );
  }
}

/// Companion mode has no Profile tab, so Settings opens with who is signed
/// in and how complete their profile is.
class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({super.key, required this.provider});

  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    const size = AppSize.avatar;
    final photo = provider.effectiveProfilePhoto;
    final initial = NameInitialAvatar(name: provider.profile.name, size: size);
    Widget avatar = initial;
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      avatar = Image.network(
        photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => initial,
      );
    } else if (photo.isNotEmpty && File(photo).existsSync()) {
      avatar = Image.file(
        File(photo),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => initial,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: AppSize.borderWidth),
      ),
      child: Row(
        children: [
          ClipOval(child: avatar),
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
                  style: context.text.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  provider.profile.mobile.isNotEmpty
                      ? provider.profile.mobile
                      : (provider.mobileNumber.isNotEmpty
                            ? provider.mobileNumber
                            : '+91'),
                  style: context.text.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.profileCompletionFormat(
                    provider.profileCompletionPercentage,
                  ),
                  style: context.text.label.copyWith(
                    color: AppColors.primaryStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The navigation mode chooser: regular (tabs) or companion (assistant).
void showNavigationModeDialog(BuildContext context, AppProvider provider) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.navigationModeSetting,
                      style: context.text.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.iconMuted,
                    ),
                    tooltip: context.l10n.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                context.l10n.settingsNavModeDialogBody,
                style: context.text.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ModeOption(
                provider: provider,
                mode: 'regular',
                title: context.l10n.navRegularNavigationTitle,
                subtitle: context.l10n.settingsRegularSubtitle,
                icon: Icons.layers_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ModeOption(
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

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.provider,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final AppProvider provider;
  final String mode;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isSelected = provider.navigationMode == mode;
    return Material(
      color: isSelected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? AppSize.borderWidthSelected : AppSize.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.iconMuted,
                size: AppSize.iconLg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.text.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.iconMuted,
                size: AppSize.icon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
