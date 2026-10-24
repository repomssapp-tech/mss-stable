import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/security/device_integrity_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// Covers the whole app while the phone is not safe enough to run MSS:
/// Developer options / USB debugging on, a VPN other than Tailscale or
/// AdGuard, or open / sign-in-page Wi-Fi. Re-checks when the network changes,
/// when the app comes back to the foreground, and every [recheckEvery], and
/// disappears by itself once the problem is fixed.
class DeviceIntegrityGate extends StatefulWidget {
  const DeviceIntegrityGate({
    super.key,
    required this.child,
    this.service,
    this.enforced,
    this.networkChanges,
  });

  final Widget child;
  final DeviceIntegrityService? service;

  /// Defaults to [DeviceIntegrityService.enforced] (release builds on Android).
  final bool? enforced;

  /// Defaults to connectivity_plus; tests pass their own stream.
  final Stream<Object?>? networkChanges;

  static const Duration recheckEvery = Duration(seconds: 20);

  @override
  State<DeviceIntegrityGate> createState() => _DeviceIntegrityGateState();
}

class _DeviceIntegrityGateState extends State<DeviceIntegrityGate>
    with WidgetsBindingObserver {
  DeviceIntegrityService get _service =>
      widget.service ?? DeviceIntegrityService.instance;
  bool get _enforced => widget.enforced ?? DeviceIntegrityService.enforced;

  List<IntegrityProblem> _problems = const [];
  StreamSubscription<Object?>? _network;
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (!_enforced) return;
    WidgetsBinding.instance.addObserver(this);
    _network = (widget.networkChanges ?? Connectivity().onConnectivityChanged)
        .listen((_) => _check());
    _timer = Timer.periodic(DeviceIntegrityGate.recheckEvery, (_) => _check());
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _network?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final problems = (await _service.report()).problems;
      if (!mounted) return;
      if (problems.length != _problems.length ||
          !problems.every(_problems.contains)) {
        setState(() => _problems = problems);
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_problems.isEmpty) return widget.child;
    return Stack(
      children: [
        // The app keeps its state underneath but cannot be used.
        ExcludeSemantics(child: IgnorePointer(child: widget.child)),
        Positioned.fill(
          child: DeviceIntegrityBlockScreen(
            problems: _problems,
            onOpenSettings: (p) async {
              await _service.openSettings(p);
            },
            onCheckAgain: _check,
          ),
        ),
      ],
    );
  }
}

/// The full-screen message shown by [DeviceIntegrityGate].
class DeviceIntegrityBlockScreen extends StatelessWidget {
  const DeviceIntegrityBlockScreen({
    super.key,
    required this.problems,
    required this.onOpenSettings,
    required this.onCheckAgain,
  });

  final List<IntegrityProblem> problems;
  final ValueChanged<IntegrityProblem> onOpenSettings;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    (String, String, IconData) copy(IntegrityProblem p) => switch (p) {
      IntegrityProblem.developerOptions => (
        l10n.integrityDevTitle,
        l10n.integrityDevBody,
        Icons.developer_mode_rounded,
      ),
      IntegrityProblem.vpn => (
        l10n.integrityVpnTitle,
        l10n.integrityVpnBody,
        Icons.vpn_lock_rounded,
      ),
      IntegrityProblem.publicWifi => (
        l10n.integrityWifiTitle,
        l10n.integrityWifiBody,
        Icons.wifi_lock_rounded,
      ),
    };
    final first = problems.first;
    final settingsLabel = switch (first) {
      IntegrityProblem.developerOptions => l10n.integrityOpenDeveloper,
      IntegrityProblem.vpn => l10n.integrityOpenVpn,
      IntegrityProblem.publicWifi => l10n.integrityOpenWifi,
    };

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.dangerSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppColors.danger,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.integrityTitle,
                textAlign: TextAlign.center,
                style: context.text.headline.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.integritySubtitle,
                textAlign: TextAlign.center,
                style: context.text.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final p in problems) ...[
                Builder(
                  builder: (context) {
                    final (title, body, icon) = copy(p);
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: AppColors.danger),
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
                                    color: AppColors.textBody,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => onOpenSettings(first),
                child: Text(settingsLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: onCheckAgain,
                child: Text(l10n.integrityCheckAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
