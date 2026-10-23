import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../services/account/app_session.dart';
import '../../services/onboarding/home_tour_store.dart';
import '../../services/updates/app_release.dart';
import '../../services/updates/app_update_service.dart';
import '../../utils/app_colors.dart';
import '../onboarding/home_tour.dart';
import 'app_toast.dart';
import 'custom_confirm_dialog.dart';

/// Opens [uri] outside the app; false when nothing could open it.
typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> openExternalUrl(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[openExternalUrl] $uri: $e');
    return false;
  }
}

/// The "Update available" dialog for [release]: "Update" opens its download
/// (Android's installer takes over once the APK is downloaded; a sideloaded app
/// cannot install itself silently), "Later" or closing the dialog stops
/// offering this build until a newer one is published.
Future<void> showAppUpdateNotice(
  BuildContext context, {
  required AppRelease release,
  required AppUpdateService service,
  UrlOpener open = openExternalUrl,
}) async {
  var update = false;
  await CustomConfirmDialog.show(
    context,
    icon: Icons.system_update_rounded,
    iconColor: AppColors.primary,
    iconBgColor: AppColors.primarySoft,
    title: context.l10n.updateAvailableTitle,
    message: context.l10n.updateAvailableMessage(release.version.name),
    cancelLabel: context.l10n.updateActionLater,
    confirmLabel: context.l10n.updateActionUpdate,
    confirmColor: AppColors.primary,
    onConfirm: () => update = true,
  );
  if (!update) {
    await service.dismiss(release);
    return;
  }
  if (!context.mounted) return;
  await openUpdateLink(context, release.updateUrl, open: open);
}

/// Opens [uri]; shows a short error when no app could open it.
Future<void> openUpdateLink(
  BuildContext context,
  Uri uri, {
  UrlOpener open = openExternalUrl,
}) async {
  final opened = await open(uri);
  if (!opened && context.mounted) {
    AppToast.showError(context, context.l10n.updateOpenFailed);
  }
}

/// Checks for a newer app build when the app shell starts and when the app
/// returns to the foreground (at most every [AppUpdateService.resumeGap]), and
/// offers it once per app session. Never blocks [child].
class AppUpdateWatcher extends StatefulWidget {
  const AppUpdateWatcher({
    super.key,
    required this.child,
    this.service,
    this.open = openExternalUrl,
  });

  final Widget child;

  /// Defaults to [AppUpdateService.instance].
  final AppUpdateService? service;
  final UrlOpener open;

  @visibleForTesting
  static void resetForTest() {
    _AppUpdateWatcherState._offered = false;
    _AppUpdateWatcherState._startChecked = false;
  }

  @override
  State<AppUpdateWatcher> createState() => _AppUpdateWatcherState();
}

class _AppUpdateWatcherState extends State<AppUpdateWatcher>
    with WidgetsBindingObserver {
  AppUpdateService get _service => widget.service ?? AppUpdateService.instance;

  /// Per app process, not per shell: the shell is rebuilt (mode switch, sign
  /// in), which must neither re-offer the notice nor skip the resume throttle.
  static bool _offered = false;
  static bool _startChecked = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final onStart = !_startChecked;
    _startChecked = true;
    unawaited(_check(onStart: onStart));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check({bool onStart = false}) async {
    if (_offered || _checking) return;
    _checking = true;
    try {
      final release = await _service.check(onStart: onStart);
      if (release == null || !mounted) return;
      // The first-run home tour owns the screen: wait while it is on screen or
      // still due to start (it starts a couple of seconds after the shell).
      for (var i = 0; i < 20 && await _tourPending(); i++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (!mounted) return;
      }
      if (!mounted || HomeTour.isShowing) return;
      _offered = true;
      await showAppUpdateNotice(
        context,
        release: release,
        service: _service,
        open: widget.open,
      );
    } finally {
      _checking = false;
    }
  }

  Future<bool> _tourPending() async {
    if (HomeTour.isShowing) return true;
    final id = AppSession.instance.userId;
    if (id == null || id.isEmpty) return false;
    return !await const HomeTourStore().isDone(id);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
