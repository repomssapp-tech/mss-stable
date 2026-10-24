import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// One permission MSS asks for after sign-in.
enum AppPermission { notifications, microphone, installUpdates, photos }

/// Talks to the OS about [AppPermission]s; replaced in tests.
class AppPermissionsPlatform {
  const AppPermissionsPlatform();

  Permission _of(AppPermission p) => switch (p) {
    AppPermission.notifications => Permission.notification,
    AppPermission.microphone => Permission.microphone,
    AppPermission.installUpdates => Permission.requestInstallPackages,
    // Android 13+ asks for photos; older Android for storage.
    AppPermission.photos => Permission.photos,
  };

  Future<bool> isGranted(AppPermission p) async {
    try {
      final status = await _of(p).status;
      if (status.isGranted || status.isLimited) return true;
      if (p == AppPermission.photos) return await Permission.storage.isGranted;
      return false;
    } catch (e) {
      debugPrint('[AppPermissions] status $p: $e');
      return false;
    }
  }

  Future<bool> request(AppPermission p) async {
    try {
      final status = await _of(p).request();
      if (status.isGranted || status.isLimited) return true;
      if (p == AppPermission.photos) {
        return (await Permission.storage.request()).isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('[AppPermissions] request $p: $e');
      return false;
    }
  }
}

/// Whether this install has been through the permissions screen.
class AppPermissionsStore {
  const AppPermissionsStore();

  static const String askedKey = 'app_permissions_v1_asked';

  Future<bool> isAsked() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(askedKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> markAsked() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(askedKey, true);
    } catch (_) {}
  }
}

/// Goes to [next], through the permissions screen the first time after
/// sign-in on this install.
Future<void> replaceWithPermissionsFirst(
  BuildContext context,
  Widget next, {
  AppPermissionsStore store = const AppPermissionsStore(),
}) async {
  final asked = await store.isAsked();
  if (!context.mounted) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => asked
          ? next
          : AppPermissionsScreen(
              onDone: (ctx) {
                store.markAsked();
                Navigator.of(ctx).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => next),
                );
              },
            ),
    ),
  );
}

/// "Allow MSS to…": notifications, microphone, installing updates, photos and
/// documents, each with why it is needed. Nothing is required: Continue works
/// whatever the user allowed.
class AppPermissionsScreen extends StatefulWidget {
  const AppPermissionsScreen({
    super.key,
    required this.onDone,
    this.platform = const AppPermissionsPlatform(),
  });

  final void Function(BuildContext context) onDone;
  final AppPermissionsPlatform platform;

  @override
  State<AppPermissionsScreen> createState() => _AppPermissionsScreenState();
}

class _AppPermissionsScreenState extends State<AppPermissionsScreen>
    with WidgetsBindingObserver {
  final Map<AppPermission, bool> _granted = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // "Install updates" is granted in a Settings page; re-read on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    for (final p in AppPermission.values) {
      final g = await widget.platform.isGranted(p);
      if (!mounted) return;
      setState(() => _granted[p] = g);
    }
  }

  Future<void> _request(AppPermission p) async {
    final g = await widget.platform.request(p);
    if (mounted) setState(() => _granted[p] = g);
  }

  Future<void> _allowAll() async {
    setState(() => _busy = true);
    for (final p in AppPermission.values) {
      if (_granted[p] == true) continue;
      await _request(p);
      if (!mounted) return;
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(AppPermission, IconData, String, String)>[
      (
        AppPermission.notifications,
        Icons.notifications_active_rounded,
        l10n.permNotificationsTitle,
        l10n.permNotificationsBody,
      ),
      (
        AppPermission.microphone,
        Icons.mic_rounded,
        l10n.permMicrophoneTitle,
        l10n.permMicrophoneBody,
      ),
      (
        AppPermission.installUpdates,
        Icons.system_update_rounded,
        l10n.permInstallTitle,
        l10n.permInstallBody,
      ),
      (
        AppPermission.photos,
        Icons.folder_rounded,
        l10n.permFilesTitle,
        l10n.permFilesBody,
      ),
    ];
    final allGranted = AppPermission.values.every((p) => _granted[p] == true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text(
                    l10n.permTitle,
                    style: context.text.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.permSubtitle,
                    style: context.text.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final (p, icon, title, body) in rows) ...[
                    _PermissionRow(
                      icon: icon,
                      title: title,
                      body: body,
                      granted: _granted[p] == true,
                      allowLabel: l10n.permAllow,
                      allowedLabel: l10n.permAllowed,
                      onAllow: () => _request(p),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!allGranted)
                    FilledButton(
                      onPressed: _busy ? null : _allowAll,
                      child: Text(l10n.permAllowAll),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  allGranted
                      ? FilledButton(
                          onPressed: () => widget.onDone(context),
                          child: Text(l10n.permContinue),
                        )
                      : TextButton(
                          onPressed: () => widget.onDone(context),
                          child: Text(l10n.permNotNow),
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

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.granted,
    required this.allowLabel,
    required this.allowedLabel,
    required this.onAllow,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool granted;
  final String allowLabel;
  final String allowedLabel;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: granted ? AppColors.success : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: context.text.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          granted
              ? Semantics(
                  label: allowedLabel,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                )
              : OutlinedButton(onPressed: onAllow, child: Text(allowLabel)),
        ],
      ),
    );
  }
}
