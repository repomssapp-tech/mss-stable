import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';
import '../../utils/responsive.dart';
import 'avatar_cache_manager.dart';
import 'profile_photo_handler.dart';
import '../../widgets/common/name_initial_avatar.dart';

/// Blue gradient header banner card with avatar, completion badge, and contact details.
class ProfileBannerCard extends StatelessWidget {
  final AppProvider provider;

  const ProfileBannerCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;
    final isComplete = provider.profileCompletionPercentage == 100;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1976D2), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative watermark icon
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.1,
                child: const Icon(
                  Icons.account_balance,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  // Avatar Stack with Camera Overlay
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Semantics(
                        button: true,
                        label: context.l10n.changeProfilePhoto,
                        child: GestureDetector(
                          onTap: () => changeProfilePicture(context, provider),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: () {
                                  final photo = provider.effectiveProfilePhoto;
                                  if (photo.startsWith('http://') ||
                                      photo.startsWith('https://')) {
                                    return CachedNetworkImage(
                                      imageUrl: photo,
                                      cacheManager: avatarCacheManager,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      // Loading or failed: the name initial, never a
                                      // blank or a broken image.
                                      placeholder: (context, url) =>
                                          NameInitialAvatar(
                                            name: provider.profile.name,
                                            size: 76,
                                          ),
                                      errorWidget: (context, url, error) =>
                                          NameInitialAvatar(
                                            name: provider.profile.name,
                                            size: 76,
                                          ),
                                    );
                                  }
                                  if (photo.isNotEmpty) {
                                    return Image.file(
                                      File(photo),
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Image.asset(
                                            'assets/images/supporting assets/user_avatar.webp',
                                            width: 76,
                                            height: 76,
                                            fit: BoxFit.cover,
                                          ),
                                    );
                                  }
                                  return NameInitialAvatar(
                                    name: provider.profile.name,
                                    size: 76,
                                  );
                                }(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Decorative badge: the avatar above carries the label.
                      ExcludeSemantics(
                        child: GestureDetector(
                          onTap: () => changeProfilePicture(context, provider),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // User Name, Badges & Contacts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.tight,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Text(
                              profile.name.isNotEmpty ? profile.name : '-',
                              style: GoogleFonts.poppins(
                                fontSize: provider.selectedLanguage == 'ta'
                                    ? 15.0
                                    : 16.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: provider.selectedLanguage == 'ta'
                                    ? 1.35
                                    : 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.tight,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                border: Border.all(
                                  color: isComplete
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFF59E0B),
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isComplete
                                        ? Icons.check_circle
                                        : Icons.warning_amber_rounded,
                                    color: isComplete
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFF59E0B),
                                    size: 10,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      isComplete
                                          ? context.l10n.profileVerified
                                          : context.l10n.profileIncomplete,
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        color: isComplete
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFFF59E0B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: Colors.white70,
                              size: 12,
                            ),
                            const SizedBox(width: AppSpacing.tight),
                            Flexible(
                              child: FitOneLine(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  profile.mobile.isNotEmpty
                                      ? '+91 ${profile.mobile}'
                                      : '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: Colors.white.withAlpha(230),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.tight),
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline,
                              color: Colors.white70,
                              size: 12,
                            ),
                            const SizedBox(width: AppSpacing.tight),
                            Expanded(
                              child: Text(
                                profile.email.isNotEmpty ? profile.email : '-',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white.withAlpha(230),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
