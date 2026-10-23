import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import 'notification_helpers.dart';
import 'notification_style.dart';

/// One row of the notification inbox, the same for every category: category
/// icon, title (bold while unread), a two-line preview, category and time, and
/// an unread dot. Tapping opens the details; a long press starts selection.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  /// The notification in the inbox map shape (`NotificationItemDto.toUiMap`).
  final Map<String, dynamic> item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final style = NotificationStyle.of(context, item['category']?.toString());
    final unread = item['read'] != true;
    final title = item['title']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';

    return NotificationSelectionSemantics(
      selectionMode: isSelectionMode,
      selected: isSelected,
      child: Material(
        color: isSelected
            ? AppColors.primarySoft
            : unread
            ? AppColors.surface
            : AppColors.background,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.iconMuted,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      // Wrap, not Row: a long Tamil or Hindi category label and
                      // time-ago text go on two lines instead of the label
                      // being cut off with an ellipsis.
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            style.label,
                            style: context.text.label.copyWith(
                              color: style.color,
                            ),
                          ),
                          Text(
                            '  •  ${NotificationHelpers.timeAgo(context, item)}',
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  children: [
                    if (unread)
                      Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (!isSelectionMode)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.md),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.iconMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
