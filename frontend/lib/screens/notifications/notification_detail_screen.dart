import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../widgets/common/app_toast.dart';
import '../regular_mode/basic_profile_screen.dart';
import 'notification_helpers.dart';
import 'notification_style.dart';
import '../../widgets/common/standard_page_header.dart';

/// Full view of one inbox notification: opened by tapping it in the inbox or
/// in the phone's notification shade. Shows the category, the full title and
/// message (selectable, so text such as a reference number can be copied),
/// when it arrived, and actions. Opening it marks it read.
class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.item});

  /// The notification in the inbox map shape (`NotificationItemDto.toUiMap`).
  final Map<String, dynamic> item;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  String get _id => widget.item['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.item['read'] != true && _id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Provider.of<AppProvider>(
          context,
          listen: false,
        ).markNotificationRead(_id);
      });
    }
  }

  String _receivedLabel(BuildContext context) {
    final raw = widget.item['created_at']?.toString();
    final at = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (at == null) return NotificationHelpers.timeAgo(context, widget.item);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMMd(locale).add_jm().format(at);
    return context.l10n.notifReceivedOn(date);
  }

  Future<void> _delete() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final l10n = context.l10n;
    provider.deleteNotifications([_id]);
    AppToast.showSuccess(context, l10n.notifDeletedToast);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = widget.item;
    final style = NotificationStyle.of(context, item['category']?.toString());
    final title = item['title']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';
    final isProfile = item['category'] == 'profile';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardPageHeader(
        MediaQuery.textScalerOf(context),
        title: l10n.notifDetailTitle,
        actions: [
          IconButton(
            tooltip: l10n.notifDeleteThis,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.danger,
            onPressed: _id.isEmpty ? null : _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: style.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(style.icon, color: style.color),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            style.label,
                            style: context.text.label.copyWith(
                              color: style.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SelectableText(
                      title,
                      style: context.text.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _receivedLabel(context),
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    SelectableText(
                      body,
                      style: context.text.body.copyWith(
                        color: AppColors.textBody,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isProfile) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                icon: const Icon(Icons.person_rounded),
                label: Text(l10n.completeProfileCta),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BasicProfileScreen(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
