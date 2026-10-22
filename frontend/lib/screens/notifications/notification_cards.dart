import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';
import '../../utils/responsive.dart';
import 'notification_helpers.dart';

class NewSchemeNotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const NewSchemeNotificationCard({
    super.key,
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item['read'] as bool? ?? false;
    final isEducation = item['tag'] == 'Education';
    final Color iconBg = isEducation
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final Color iconCol = isEducation
        ? const Color(0xFF16A34A)
        : const Color(0xFFEA580C);
    final IconData icon = isEducation
        ? Icons.school
        : Icons.store_mall_directory_outlined;

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconCol, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            NotificationHelpers.seedText(
                              context,
                              item['title'],
                            ),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.tight),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.tight,
                            vertical: AppSpacing.hairline,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.l10n.notifBadgeNew,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tight),
                    Text(
                      NotificationHelpers.seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (item['tag'] != null)
                      NotificationHelpers.buildTag(
                        NotificationHelpers.tagLabel(context, item['tag']),
                        iconBg,
                        iconCol,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _timeColumnMaxWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NotificationHelpers.timeAgo(context, item),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return NotificationSelectionSemantics(
      selectionMode: isSelectionMode,
      selected: isSelected,
      child: card,
    );
  }
}

class DeadlineNotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const DeadlineNotificationCard({
    super.key,
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item['read'] as bool? ?? false;
    final isPostMatric = item['title'] == 'Post Matric Scholarship Scheme';
    final IconData icon = isPostMatric
        ? Icons.calendar_today_outlined
        : Icons.access_time;
    final Color iconBg = isPostMatric
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFF3E5F5);
    final Color iconCol = isPostMatric
        ? const Color(0xFFD32F2F)
        : const Color(0xFF7B1FA2);

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconCol, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NotificationHelpers.seedText(context, item['title']),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      NotificationHelpers.seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.tight,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Color(0xFFE11D48),
                        ),
                        const SizedBox(width: AppSpacing.hairline),
                        Text(
                          NotificationHelpers.deadline(context, item),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '•',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          NotificationHelpers.daysLeft(context, item),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _timeColumnMaxWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NotificationHelpers.timeAgo(context, item),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return NotificationSelectionSemantics(
      selectionMode: isSelectionMode,
      selected: isSelected,
      child: card,
    );
  }
}

class GovtUpdateNotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const GovtUpdateNotificationCard({
    super.key,
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item['read'] as bool? ?? false;
    final IconData icon = item['iconType'] == 'emblem'
        ? Icons.gavel_outlined
        : Icons.account_balance_outlined;

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NotificationHelpers.seedText(context, item['title']),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      NotificationHelpers.seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _timeColumnMaxWidth(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FitOneLine(
                              child: Text(
                                NotificationHelpers.timeAgo(context, item),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return NotificationSelectionSemantics(
      selectionMode: isSelectionMode,
      selected: isSelected,
      child: card,
    );
  }
}

class ProfileReminderNotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int profileCompletion;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onOpenProfile;

  const ProfileReminderNotificationCard({
    super.key,
    required this.item,
    required this.profileCompletion,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item['read'] as bool? ?? false;

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.tight,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isSelectionMode ? onTap : onOpenProfile,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E5F5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit_note_outlined,
                  color: Color(0xFF7B1FA2),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NotificationHelpers.seedText(context, item['title']),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      NotificationHelpers.seedText(context, item['body']),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.l10n.notifProfileCompletionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: profileCompletion / 100.0,
                              backgroundColor: const Color(0xFFF3E8FF),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C3AED),
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$profileCompletion%',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _timeColumnMaxWidth(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FitOneLine(
                              child: Text(
                                NotificationHelpers.timeAgo(context, item),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return NotificationSelectionSemantics(
      selectionMode: isSelectionMode,
      selected: isSelected,
      child: card,
    );
  }
}

/// The time/meta column beside a notification title may take about a quarter of
/// the screen, so it adapts to the phone's width and text scale instead of a
/// fixed size.
double _timeColumnMaxWidth(BuildContext context) {
  final media = MediaQuery.of(context);
  return media.size.width * 0.26 * media.textScaler.scale(1).clamp(1.0, 1.3);
}

/// Makes a notification card's selection state reach screen readers: in
/// selection mode the card is announced as checked or not checked, instead
/// of only showing a tick icon.
class NotificationSelectionSemantics extends StatelessWidget {
  const NotificationSelectionSemantics({
    super.key,
    required this.selectionMode,
    required this.selected,
    required this.child,
  });

  final bool selectionMode;
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!selectionMode) return child;
    return Semantics(container: true, checked: selected, child: child);
  }
}
