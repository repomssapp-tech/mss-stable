import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/l10n/l10n.dart';
import 'package:frontend/widgets/common/app_toast.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text.dart';
import 'notifications/notification_helpers.dart';
import 'notifications/notification_category_bar.dart';
import 'notifications/notification_detail_screen.dart';
import 'notifications/notification_cards.dart';
import 'notifications/notification_empty_state.dart';

export 'notifications/notification_helpers.dart';
export 'notifications/notification_category_bar.dart';
export 'notifications/notification_detail_screen.dart';
export 'notifications/notification_cards.dart';
export 'notifications/notification_empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  final String? initialFilter;
  const NotificationsScreen({super.key, this.initialFilter});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late String _activeFilter;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'All';
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _handleCardTap(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    if (_isSelectionMode) {
      _toggleSelection(id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationDetailScreen(item: item),
      ),
    );
  }

  void _startSelection(Map<String, dynamic> item) {
    if (_isSelectionMode) return;
    setState(() {
      _isSelectionMode = true;
      _selectedIds
        ..clear()
        ..add(item['id']?.toString() ?? '');
    });
  }

  /// Splits [items] (newest first) into Today / Yesterday / Earlier groups,
  /// leaving out empty ones. Items without a date go to Earlier.
  List<(String, List<Map<String, dynamic>>)> _groupByDay(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final buckets = <List<Map<String, dynamic>>>[[], [], []];
    for (final item in items) {
      final at = DateTime.tryParse(
        item['created_at']?.toString() ?? '',
      )?.toLocal();
      if (at != null && !at.isBefore(today)) {
        buckets[0].add(item);
      } else if (at != null && !at.isBefore(yesterday)) {
        buckets[1].add(item);
      } else {
        buckets[2].add(item);
      }
    }
    final l10n = context.l10n;
    final labels = [l10n.notifToday, l10n.notifYesterday, l10n.notifEarlier];
    return [
      for (var i = 0; i < 3; i++)
        if (buckets[i].isNotEmpty) (labels[i], buckets[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final list = provider.notifications;

    final visible = _activeFilter == 'All'
        ? list
        : list.where((n) => n['category'] == _activeFilter).toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: AppConstants.primaryText),
                tooltip: context.l10n.notifCancelSelectionTooltip,
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        title: Text(
          _isSelectionMode
              ? context.l10n.notifSelectedCount(_selectedIds.length)
              : context.l10n.notificationsGroupHeader,
          style: AppGoogleFonts.poppins(
            color: AppConstants.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.done_all,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  tooltip: context.l10n.notifTooltipMarkRead,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          provider.markNotificationsRead(_selectedIds.toList());
                          AppToast.showSuccess(
                            context,
                            context.l10n.notifToastSelectedRead,
                          );
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 22,
                  ),
                  tooltip: context.l10n.notifTooltipDeleteSelected,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          provider.deleteNotifications(_selectedIds.toList());
                          AppToast.showSuccess(
                            context,
                            context.l10n.notifToastSelectedDeleted,
                          );
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        },
                ),
                const SizedBox(width: AppSpacing.sm),
              ]
            : [
                PopupMenuButton<String>(
                  color: AppColors.surface,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppConstants.primaryText,
                    size: 22,
                  ),
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      provider.markAllNotificationsRead();
                      AppToast.showSuccess(
                        context,
                        context.l10n.notifToastAllRead,
                      );
                    } else if (value == 'delete_all') {
                      provider.deleteAllNotifications();
                      AppToast.showSuccess(
                        context,
                        context.l10n.notifToastAllDeleted,
                      );
                    } else if (value == 'select') {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedIds.clear();
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.done_all,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.notifMarkAllAsRead,
                              softWrap: true,
                              style: AppGoogleFonts.inter(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_sweep_outlined,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.notifDeleteAll,
                              softWrap: true,
                              style: AppGoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.checklist_rtl_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.select,
                              softWrap: true,
                              style: AppGoogleFonts.inter(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          NotificationCategoryBar(
            activeFilter: _activeFilter,
            categories: kNotificationCategories,
            onSelectCategory: (catKey) {
              setState(() {
                _activeFilter = catKey;
              });
            },
          ),
          Expanded(
            child: visible.isEmpty
                ? const SingleChildScrollView(child: NotificationEmptyState())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      for (final group in _groupByDay(context, visible)) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            group.$1,
                            style: context.text.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        for (final item in group.$2)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: NotificationTile(
                              item: item,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(item['id']),
                              onTap: () => _handleCardTap(item),
                              onLongPress: () => _startSelection(item),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
