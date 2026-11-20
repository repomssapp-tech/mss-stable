import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../services/location_lock/location_lock.dart';
import '../../services/location_lock/location_lock_config.dart';
import '../../services/location_lock/location_lock_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// Wraps the app (MaterialApp.builder) when [kLocationLockEnabled]. Until the
/// phone's GPS has placed the user in an Indian state with no fake-location
/// app and no VPN, ONLY the location screen is built: the app's navigator is
/// not in the tree. The check runs at every start and again when the app
/// returns to the foreground after [recheckAfter].
class LocationLockGate extends StatefulWidget {
  const LocationLockGate({super.key, required this.child, this.service});

  final Widget child;
  final LocationLockService? service;

  /// How long the app may stay in the background before the GPS is checked
  /// again on return.
  static const Duration recheckAfter = Duration(minutes: 15);

  @override
  State<LocationLockGate> createState() => _LocationLockGateState();
}

class _LocationLockGateState extends State<LocationLockGate>
    with WidgetsBindingObserver {
  LocationLockService get _service =>
      widget.service ?? LocationLockService.instance;

  bool _passed = false;
  bool _checking = false;
  LocationCheckFailure? _failure;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checking = true;
    unawaited(_run(requestPermission: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null
          ? Duration.zero
          : DateTime.now().difference(_pausedAt!);
      // Back from Settings while blocked: check at once. Otherwise only
      // after a long absence.
      if (!_passed || away >= LocationLockGate.recheckAfter) {
        unawaited(_check(requestPermission: false));
      }
    }
  }

  Future<void> _check({required bool requestPermission}) async {
    if (_checking) return;
    setState(() => _checking = true);
    await _run(requestPermission: requestPermission);
  }

  Future<void> _run({required bool requestPermission}) async {
    final result = await _service.verify(requestPermission: requestPermission);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (result.isOk) {
        _passed = true;
        _failure = null;
      } else if (_passed && _isTransient(result.failure!)) {
        // Signal lost on a re-check: keep the app open on the last lock.
      } else {
        _passed = false;
        _failure = result.failure;
      }
    });
  }

  /// A failure that says nothing about the user faking their location.
  static bool _isTransient(LocationCheckFailure f) =>
      f == LocationCheckFailure.noFix ||
      f == LocationCheckFailure.lowAccuracy ||
      f == LocationCheckFailure.lookupFailed;

  @override
  Widget build(BuildContext context) {
    if (_passed && LocationScope.current.value != null) return widget.child;
    return LocationRequiredScreen(
      failure: _failure,
      checking: _checking,
      onRetry: () => _check(requestPermission: true),
    );
  }
}

/// The only screen until the location check passes. No back button and no
/// way into the app.
class LocationRequiredScreen extends StatelessWidget {
  const LocationRequiredScreen({
    super.key,
    required this.failure,
    required this.checking,
    required this.onRetry,
  });

  final LocationCheckFailure? failure;
  final bool checking;
  final VoidCallback onRetry;

  static String message(AppLocalizations l10n, LocationCheckFailure f) =>
      switch (f) {
        LocationCheckFailure.serviceOff => l10n.locationErrServiceOff,
        LocationCheckFailure.permissionDenied => l10n.locationErrPermission,
        LocationCheckFailure.permissionDeniedForever =>
          l10n.locationErrPermissionForever,
        LocationCheckFailure.approximateOnly => l10n.locationErrApproximate,
        LocationCheckFailure.mockLocation => l10n.locationErrMock,
        LocationCheckFailure.vpn => l10n.locationErrVpn,
        LocationCheckFailure.impossibleJump => l10n.locationErrJump,
        LocationCheckFailure.lowAccuracy ||
        LocationCheckFailure.noFix => l10n.locationErrWeakSignal,
        LocationCheckFailure.outsideIndia => l10n.locationErrOutsideIndia,
        LocationCheckFailure.lookupFailed => l10n.locationErrLookup,
      };

  /// Failures only a system settings page can fix.
  static bool needsSettings(LocationCheckFailure? f) =>
      f == LocationCheckFailure.serviceOff ||
      f == LocationCheckFailure.permissionDeniedForever ||
      f == LocationCheckFailure.approximateOnly;

  Future<void> _openSettings() async {
    if (failure == LocationCheckFailure.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = failure;
    final isError = f != null;
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
                      decoration: BoxDecoration(
                        color: isError
                            ? AppColors.dangerSoft
                            : AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isError
                            ? Icons.location_off_rounded
                            : Icons.my_location_rounded,
                        color: isError ? AppColors.danger : AppColors.primary,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.locationGateTitle,
                    textAlign: TextAlign.center,
                    style: context.text.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isError ? message(l10n, f) : l10n.locationGateBody,
                    textAlign: TextAlign.center,
                    style: context.text.body.copyWith(
                      color: isError
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (checking)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.locationGateChecking,
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    FilledButton(
                      onPressed: onRetry,
                      child: Text(
                        isError
                            ? l10n.locationGateRetry
                            : l10n.locationGateAllow,
                      ),
                    ),
                    if (needsSettings(f)) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: _openSettings,
                        child: Text(l10n.locationGateOpenSettings),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
