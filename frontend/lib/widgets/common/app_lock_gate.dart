import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/security/app_lock_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// Wraps the whole app (MaterialApp.builder). While an administrator has
/// locked the app this builds ONLY the locked screen: the app's navigator and
/// every screen under it are removed from the tree, not hidden behind a
/// cover, so there is nothing underneath to reach. The server refuses the
/// locked app anyway (see [AppLockService]); after the unlock the app starts
/// again from its first screen with the user still signed in.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child, this.service});

  final Widget child;
  final AppLockService? service;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  AppLockService get _service => widget.service ?? AppLockService.instance;
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_onLockChanged);
    _schedule();
    unawaited(_service.check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_onLockChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_service.check());
  }

  void _onLockChanged() {
    _schedule();
    if (mounted) setState(() {});
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(
      _service.isLocked
          ? AppLockService.checkWhileLockedEvery
          : AppLockService.checkEvery,
      (_) => unawaited(_service.check()),
    );
  }

  Future<void> _checkAgain() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _service.check();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _service.value;
    if (!state.locked) return widget.child;
    return AppLockedScreen(
      message: state.message,
      checking: _checking,
      onCheckAgain: _checkAgain,
    );
  }
}

/// The only screen of a locked app. It has no way into the app: no back
/// button, no sign-in and no sign-out; "Check again" asks the server.
class AppLockedScreen extends StatelessWidget {
  const AppLockedScreen({
    super.key,
    required this.message,
    required this.checking,
    required this.onCheckAgain,
  });

  final String? message;
  final bool checking;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: const BoxDecoration(
                        color: AppColors.dangerSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.danger,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.appLockedTitle,
                    textAlign: TextAlign.center,
                    style: context.text.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.appLockedBody,
                    textAlign: TextAlign.center,
                    style: context.text.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appLockedMessageLabel,
                            style: context.text.cardTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            message!,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton(
                    onPressed: checking ? null : onCheckAgain,
                    child: Text(
                      checking
                          ? l10n.appLockedChecking
                          : l10n.appLockedCheckAgain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
