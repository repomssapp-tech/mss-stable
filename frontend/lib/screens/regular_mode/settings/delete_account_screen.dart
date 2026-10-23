import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/account/account_api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../widgets/common/account_deletion_dialogs.dart';
import '../../login_screen.dart';

/// Where the deletion has got to.
enum _Phase { removing, verifying, clearing, done, failed }

/// Full-screen progress of deleting the account.
///
/// 1. the server deletes the account;
/// 2. the server is asked whether it still knows the account (it must not);
/// 3. this phone forgets the account;
/// then the login screen opens. A refusal (no connection, a session that is
/// too old, a rate limit) leaves everything as it was and offers a way forward.
/// The screen cannot be left while the deletion runs.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _doneHold = Duration(milliseconds: 1400);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  _Phase _phase = _Phase.removing;
  AccountDeletionOutcome? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final provider = context.read<AppProvider>();
    setState(() {
      _phase = _Phase.removing;
      _failure = null;
    });
    final outcome = await provider.requestAccountDeletion(
      onVerifying: () {
        if (mounted) setState(() => _phase = _Phase.verifying);
      },
    );
    if (!mounted) return;
    if (outcome != AccountDeletionOutcome.deleted) {
      setState(() {
        _phase = _Phase.failed;
        _failure = outcome;
      });
      return;
    }
    setState(() => _phase = _Phase.clearing);
    await provider.completeAccountDeletion();
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    // Rest the badge: it must not keep pulsing behind the message below.
    _pulse.stop();
    await Future<void>.delayed(_doneHold);
    if (!mounted) return;
    // Tell the user their data is kept for 30 days and how to reactivate.
    await showAccountDeletedDialog(
      context,
      AccountApiService.instance.lastPurgeAfter,
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _failureMessage(AppLocalizations l10n) => switch (_failure) {
    AccountDeletionOutcome.reauthRequired => l10n.deleteAccountErrReauth,
    AccountDeletionOutcome.rateLimited => l10n.deleteAccountErrRateLimited,
    AccountDeletionOutcome.unavailable => l10n.deleteAccountErrUnavailable,
    AccountDeletionOutcome.notVerified => l10n.deleteAccountErrNotVerified,
    _ => l10n.deleteAccountErrOffline,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = _phase == _Phase.failed;
    final done = _phase == _Phase.done;
    final title = failed
        ? l10n.deleteAccountFailedTitle
        : done
        ? l10n.deleteAccountDone
        : l10n.deleteAccountScreenTitle;

    return PopScope(
      canPop: failed,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Badge(phase: _phase, pulse: _pulse),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: context.text.titleMedium.copyWith(
                          color: failed
                              ? AppColors.danger
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (failed) ...[
                      Text(
                        _failureMessage(l10n),
                        textAlign: TextAlign.center,
                        style: context.text.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ..._failureActions(context),
                    ] else ...[
                      _Steps(phase: _phase),
                      if (!done) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.deleteAccountKeepOpen,
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _failureActions(BuildContext context) {
    final l10n = context.l10n;
    if (_failure == AccountDeletionOutcome.reauthRequired) {
      return [
        ElevatedButton(
          onPressed: () => context.read<AppProvider>().logout(context),
          child: Text(
            l10n.deleteAccountSignOutAgain,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.deleteAccountBack),
        ),
      ];
    }
    return [
      ElevatedButton(
        onPressed: _run,
        child: Text(l10n.deleteAccountRetry, textAlign: TextAlign.center),
      ),
      const SizedBox(height: AppSpacing.md),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.deleteAccountBack),
      ),
    ];
  }
}

/// The round badge: a pulsing ring with a spinner while it runs, a check when
/// done, a cross when it failed.
class _Badge extends StatelessWidget {
  const _Badge({required this.phase, required this.pulse});

  final _Phase phase;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final failed = phase == _Phase.failed;
    final done = phase == _Phase.done;
    final color = done ? AppColors.success : AppColors.danger;
    final icon = failed
        ? Icons.error_outline_rounded
        : done
        ? Icons.check_rounded
        : Icons.delete_forever_rounded;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!failed && !done)
              const SizedBox.square(
                dimension: 112,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.danger,
                ),
              ),
            ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.06).animate(
                CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Icon(icon, color: color, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three steps with a check for each finished one and a spinner on the
/// current one.
class _Steps extends StatelessWidget {
  const _Steps({required this.phase});

  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const order = [_Phase.removing, _Phase.verifying, _Phase.clearing];
    final labels = [
      l10n.deleteAccountStepRemoving,
      l10n.deleteAccountStepVerifying,
      l10n.deleteAccountStepClearing,
    ];
    final current = phase == _Phase.done ? 3 : order.indexOf(phase);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.lgAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  SizedBox.square(
                    dimension: 22,
                    child: i < current
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 22,
                          )
                        : i == current
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.hairline),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: AppColors.iconMuted,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: context.text.body.copyWith(
                        color: i <= current
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: i == current
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
