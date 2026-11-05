import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import 'avatar_cache_manager.dart';
import 'profile_photo_handler.dart';
import '../../widgets/common/name_initial_avatar.dart';
import '../../utils/app_text.dart';

/// The Profile header: the person's photo, name, profile status and contact
/// details on the app's blue.
class ProfileBannerCard extends StatelessWidget {
  final AppProvider provider;

  const ProfileBannerCard({super.key, required this.provider});

  static const double _photoSize = AppSize.avatarLg;

  Widget _photo() {
    final photo = provider.effectiveProfilePhoto;
    final initial = NameInitialAvatar(
      name: provider.profile.name,
      size: _photoSize,
    );
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: photo,
        cacheManager: avatarCacheManager,
        width: _photoSize,
        height: _photoSize,
        fit: BoxFit.cover,
        // Loading or failed: the name initial, never a blank or a broken
        // image.
        placeholder: (context, url) => initial,
        errorWidget: (context, url, error) => initial,
      );
    }
    if (photo.isNotEmpty) {
      return Image.file(
        File(photo),
        width: _photoSize,
        height: _photoSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/supporting assets/user_avatar.webp',
          width: _photoSize,
          height: _photoSize,
          fit: BoxFit.cover,
        ),
      );
    }
    return initial;
  }

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;
    final isComplete = provider.profileCompletionPercentage == 100;
    void pickPhoto() => changeProfilePicture(context, provider);
    final onBlue = context.text.bodySmall.copyWith(
      color: AppColors.textOnPrimary,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo; tapping it (or the camera badge) changes it.
          Semantics(
            button: true,
            label: context.l10n.changeProfilePhoto,
            onTap: pickPhoto,
            excludeSemantics: true,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textOnPrimary,
                      width: AppSize.borderWidthSelected,
                    ),
                  ),
                  child: ClipOval(child: _photo()),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: AppSize.iconLg,
                    height: AppSize.iconLg,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textOnPrimary,
                        width: AppSize.borderWidth,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: AppSize.iconSm,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: pickPhoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isNotEmpty ? profile.name : '-',
                  style: context.text.titleSmall.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                // Profile status: a quiet white tag either way, with a tick
                // or a note icon.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.hairline,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isComplete
                            ? Icons.check_rounded
                            : Icons.edit_note_rounded,
                        color: isComplete
                            ? AppColors.success
                            : AppColors.warningText,
                        size: AppSize.iconSm,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          isComplete
                              ? context.l10n.profileVerified
                              : context.l10n.profileIncomplete,
                          style: context.text.label.copyWith(
                            color: isComplete
                                ? AppColors.success
                                : AppColors.warningText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  profile.mobile.isNotEmpty ? '+91 ${profile.mobile}' : '-',
                  style: onBlue,
                ),
                const SizedBox(height: AppSpacing.xs),
                // An address has no spaces; it breaks between characters on
                // a second line rather than being cut off.
                Text(
                  profile.email.isNotEmpty ? profile.email : '-',
                  style: onBlue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
