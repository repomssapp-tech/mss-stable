import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/account/rest_auth_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../widgets/common/app_toast.dart';
import '../../splash_screen.dart';

/// Modal dialog for listing active account sessions and revoking them.
class ActiveSessionsDialog extends StatefulWidget {
  const ActiveSessionsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ActiveSessionsDialog(),
    );
  }

  @override
  State<ActiveSessionsDialog> createState() => _ActiveSessionsDialogState();
}

class _ActiveSessionsDialogState extends State<ActiveSessionsDialog> {
  bool _loading = true;
  List<UserSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      final list = await RestAuthService.instance.getSessions();
      if (mounted) {
        setState(() {
          _sessions = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _revokeSession(UserSession session) async {
    try {
      await RestAuthService.instance.deleteSession(session.id);
      if (session.current) {
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      } else {
        await _fetchSessions();
        if (mounted) {
          AppToast.showSuccess(context, context.l10n.sessionRevoked);
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.showWarning(context, context.l10n.sessionRevokeFailed);
      }
    }
  }

  Future<void> _logoutAll() async {
    try {
      await RestAuthService.instance.logoutAll();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.showWarning(context, context.l10n.logoutAllFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.devices_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.activeSessionsSetting,
                    style: context.text.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.iconMuted),
                  tooltip: context.l10n.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const SizedBox(
                height: 120, // spacing-ok
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    context.l10n.noActiveSessions,
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sessions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            session.current
                                ? Icons.phone_android_rounded
                                : Icons.devices_other_rounded,
                            color: session.current
                                ? AppColors.primary
                                : AppColors.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      session.current
                                          ? context.l10n.sessionCurrent
                                          : context.l10n.sessionOtherDevice,
                                      style: context.text.label.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (session.current) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: AppSpacing.hairline,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: AppColors.successSoft,
                                          borderRadius: AppRadius.xsAll,
                                        ),
                                        child: Text(
                                          context.l10n.activeBadge,
                                          style: context.text.label.copyWith(
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.hairline),
                                Text(
                                  context.l10n.sessionSignedInAt(
                                    session.authenticatedAt
                                        .toLocal()
                                        .toString()
                                        .split('.')[0],
                                  ),
                                  style: context.text.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!session.current)
                            TextButton(
                              onPressed: () => _revokeSession(session),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger,
                              ),
                              child: Text(context.l10n.revokeSession),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _sessions.isEmpty ? null : _logoutAll,
              icon: const Icon(Icons.logout, size: 16),
              label: Text(context.l10n.logoutAllSessions),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.dangerBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
