import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';

/// Top bar for Saarthi companion mode containing notifications bell with
/// unread indicator and profile photo avatar.
class SaarthiTopBar extends StatelessWidget {
  const SaarthiTopBar({
    super.key,
    required this.provider,
  });

  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasUnread = provider.notifications.any((n) => n['read'] == false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  key: const Key('saarthi-notifications-btn'),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF0F172A),
                    size: 24,
                  ),
                  tooltip: context.l10n.notificationsGroupHeader,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (hasUnread)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              key: const Key('saarthi-profile-avatar-btn'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: ClipOval(
                  child: () {
                    final photo = provider.effectiveProfilePhoto;
                    if (photo.isEmpty) {
                      return Image.asset(
                        'assets/images/supporting assets/user_avatar.webp',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      );
                    }
                    if (photo.startsWith('http://') ||
                        photo.startsWith('https://')) {
                      return Image.network(
                        photo,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                      );
                    }
                    final file = File(photo);
                    if (file.existsSync()) {
                      return Image.file(
                        file,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      );
                    }
                    return Image.asset(
                      'assets/images/supporting assets/user_avatar.webp',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    );
                  }(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
