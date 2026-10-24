import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../services/account/app_session.dart';
import '../../services/onboarding/home_tour_store.dart';
import '../../services/updates/app_release.dart';
import '../../services/updates/app_update_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../onboarding/home_tour.dart';
import 'app_toast.dart';

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

/// The "Update available" dialog for [release]: the version name, what is
/// new or fixed in it (from the release notes), and "Update" / "Later".
/// "Update" opens its download (Android's installer takes over once the APK
/// is downloaded; a sideloaded app cannot install itself silently); "Later"
/// or closing the dialog stops offering this build until a newer one is
/// published.
Future<void> showAppUpdateNotice(
  BuildContext context, {
  required AppRelease release,
  required AppUpdateService service,
  UrlOpener open = openExternalUrl,
}) async {
  final update =
      await showDialog<bool>(
        context: context,
        builder: (_) => AppUpdateDialog(release: release),
      ) ??
      false;
  if (!update) {
    await service.dismiss(release);
    return;
  }
  if (!context.mounted) return;
  await openUpdateLink(context, release.updateUrl, open: open);
}

/// The notice's body. Pops `true` for "Update", `false` for "Later".
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.updateAvailableTitle,
              textAlign: TextAlign.center,
              style: context.text.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.updateAvailableMessage(release.version.displayName),
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(color: AppColors.textSecondary),
            ),
            if (release.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.updateWhatsNew,
                style: context.text.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in release.notes)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Text(
                                line,
                                style: line.startsWith('• ')
                                    ? context.text.bodySmall.copyWith(
                                        color: AppColors.textBody,
                                      )
                                    : context.text.label.copyWith(
                                        color: AppColors.primary,
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.updateActionLater),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.updateActionUpdate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
