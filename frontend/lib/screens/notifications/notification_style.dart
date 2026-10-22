import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';

/// Icon, colours and label for a notification category, shared by the inbox
/// list and the details screen so both look the same.
class NotificationStyle {
  const NotificationStyle(this.icon, this.color, this.background, this.label);

  final IconData icon;
  final Color color;
  final Color background;
  final String label;

  static NotificationStyle of(BuildContext context, String? category) {
    final l10n = context.l10n;
    switch (category) {
      case 'new_schemes':
        return NotificationStyle(
          Icons.auto_awesome_rounded,
          AppColors.success,
          AppColors.successSoft,
          l10n.notifCatNewSchemes,
        );
      case 'reminders':
        return NotificationStyle(
          Icons.event_rounded,
          AppColors.dangerStrong,
          AppColors.dangerSoft,
          l10n.notifCatReminders,
        );
      case 'profile':
        return NotificationStyle(
          Icons.person_rounded,
          AppColors.warningOnSoft,
          AppColors.warningSoft,
          l10n.notifCatProfile,
        );
      case 'updates':
      default:
        return NotificationStyle(
          Icons.campaign_rounded,
          AppColors.primary,
          AppColors.primarySoft,
          l10n.notifCatUpdates,
        );
    }
  }
}
