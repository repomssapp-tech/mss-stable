import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/l10n/l10n.dart';
import 'package:frontend/widgets/common/app_toast.dart';
import 'regular_mode/basic_profile_screen.dart';
import '../utils/app_spacing.dart';
import 'notifications/notification_helpers.dart';
import 'notifications/notification_category_bar.dart';
import 'notifications/notification_section.dart';
import 'notifications/notification_cards.dart';
import 'notifications/notification_empty_state.dart';

export 'notifications/notification_helpers.dart';
export 'notifications/notification_category_bar.dart';
export 'notifications/notification_section.dart';
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

  void _handleCardTap(String id, AppProvider provider) {
    if (_isSelectionMode) {
      _toggleSelection(id);
    } else {
      provider.markNotificationRead(id);
    }
  }

  void _handleProfileTap(String id, AppProvider provider) {
    if (_isSelectionMode) {
      _toggleSelection(id);
    } else {
      provider.markNotificationRead(id);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BasicProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final list = provider.notifications;

    // Filtered lists for each section
    final newSchemes = list
        .where((n) => n['category'] == 'new_schemes')
        .toList();
    final reminders = list.where((n) => n['category'] == 'reminders').toList();
    final updates = list.where((n) => n['category'] == 'updates').toList();
    final profileAlerts = list
        .where((n) => n['category'] == 'profile')
        .toList();

    final showEmpty =
        (_activeFilter == 'new_schemes' && newSchemes.isEmpty) ||
        (_activeFilter == 'reminders' && reminders.isEmpty) ||
        (_activeFilter == 'updates' && updates.isEmpty) ||
        (_activeFilter == 'profile' && profileAlerts.isEmpty) ||
        list.isEmpty;

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
          style: GoogleFonts.poppins(
            color: AppConstants.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.done_all,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  tooltip: context.l10n.notifTooltipMarkRead,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          provider.markNotificationsRead(_selectedIds.toList());
                          AppToast.showSuccess(
                            context,
                            CentralizedTranslator.instance.localize(
                              'Selected notifications marked as read',
                            ),
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
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                  tooltip: context.l10n.notifTooltipDeleteSelected,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          provider.deleteNotifications(_selectedIds.toList());
                          AppToast.showSuccess(
                            context,
                            CentralizedTranslator.instance.localize(
                              'Selected notifications deleted',
                            ),
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
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                        CentralizedTranslator.instance.localize(
                          'All notifications marked as read',
                        ),
                      );
                    } else if (value == 'delete_all') {
                      provider.deleteAllNotifications();
                      AppToast.showSuccess(
                        context,
                        CentralizedTranslator.instance.localize(
                          'All notifications deleted',
                        ),
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
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.notifMarkAllAsRead,
                              softWrap: true,
                              style: GoogleFonts.inter(fontSize: 13.5),
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
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.notifDeleteAll,
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: const Color(0xFFEF4444),
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
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.select,
                              softWrap: true,
                              style: GoogleFonts.inter(fontSize: 13.5),
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
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // 1. New Scheme Alerts Section
                  if ((_activeFilter == 'All' ||
                          _activeFilter == 'new_schemes') &&
                      newSchemes.isNotEmpty)
                    NotificationSection(
                      title: context.l10n.notifNewSchemeAlertsTitle,
                      subtitle: context.l10n.notifNewSchemeAlertsSubtitle,
                      headerIcon: Icons.notifications_active_outlined,
                      headerIconBg: const Color(0xFFE8F5E9),
                      headerIconColor: const Color(0xFF16A34A),
                      cards: newSchemes
                          .map(
                            (item) => NewSchemeNotificationCard(
                              item: item,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(item['id']),
                              onTap: () => _handleCardTap(
                                item['id'] as String,
                                provider,
                              ),
                            ),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'new_schemes';
                        });
                      },
                    ),

                  // 2. Deadline Reminders Section
                  if ((_activeFilter == 'All' ||
                          _activeFilter == 'reminders') &&
                      reminders.isNotEmpty)
                    NotificationSection(
                      title: context.l10n.notifDeadlineRemindersTitle,
                      subtitle: context.l10n.notifDeadlineRemindersSubtitle,
                      headerIcon: Icons.calendar_today_outlined,
                      headerIconBg: const Color(0xFFFFEBEE),
                      headerIconColor: const Color(0xFFD32F2F),
                      cards: reminders
                          .map(
                            (item) => DeadlineNotificationCard(
                              item: item,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(item['id']),
                              onTap: () => _handleCardTap(
                                item['id'] as String,
                                provider,
                              ),
                            ),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'reminders';
                        });
                      },
                    ),

                  // 3. Government Updates Section
                  if ((_activeFilter == 'All' || _activeFilter == 'updates') &&
                      updates.isNotEmpty)
                    NotificationSection(
                      title: context.l10n.notifGovtUpdatesTitle,
                      subtitle: context.l10n.notifGovtUpdatesSubtitle,
                      headerIcon: Icons.campaign_outlined,
                      headerIconBg: const Color(0xFFEFF6FF),
                      headerIconColor: const Color(0xFF2563EB),
                      cards: updates
                          .map(
                            (item) => GovtUpdateNotificationCard(
                              item: item,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(item['id']),
                              onTap: () => _handleCardTap(
                                item['id'] as String,
                                provider,
                              ),
                            ),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'updates';
                        });
                      },
                    ),

                  // 4. Profile Completion Reminders Section
                  if ((_activeFilter == 'All' || _activeFilter == 'profile') &&
                      profileAlerts.isNotEmpty)
                    NotificationSection(
                      title: context.l10n.notifProfileRemindersTitle,
                      subtitle: context.l10n.notifProfileRemindersSubtitle,
                      headerIcon: Icons.person_outline,
                      headerIconBg: const Color(0xFFF3E5F5),
                      headerIconColor: const Color(0xFF7B1FA2),
                      cards: profileAlerts
                          .map(
                            (item) => ProfileReminderNotificationCard(
                              item: item,
                              profileCompletion:
                                  provider.profileCompletionPercentage,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(item['id']),
                              onTap: () =>
                                  _toggleSelection(item['id'] as String),
                              onOpenProfile: () => _handleProfileTap(
                                item['id'] as String,
                                provider,
                              ),
                            ),
                          )
                          .toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'profile';
                        });
                      },
                    ),

                  // Empty State if no notifications match filter
                  if (showEmpty) const NotificationEmptyState(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
