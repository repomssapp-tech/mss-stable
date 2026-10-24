import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Why MSS refuses to run on this phone right now.
enum IntegrityProblem {
  /// Developer options or USB debugging is on.
  developerOptions,

  /// A VPN other than Tailscale or AdGuard is connected.
  vpn,

  /// Connected to Wi-Fi with no password, or one that needs a sign-in page.
  publicWifi,
}

/// What the Android side reports (DeviceIntegrityBridge.kt).
@immutable
class IntegrityReport {
  const IntegrityReport({
    this.developerOptions = false,
    this.usbDebugging = false,
    this.vpnActive = false,
    this.vpnKind = 'none',
    this.wifiConnected = false,
    this.wifiOpen,
    this.wifiCaptivePortal = false,
  });

  factory IntegrityReport.fromMap(Map<Object?, Object?> m) => IntegrityReport(
    developerOptions: m['developerOptions'] == true,
    usbDebugging: m['usbDebugging'] == true,
    vpnActive: m['vpnActive'] == true,
    vpnKind: m['vpnKind']?.toString() ?? 'none',
    wifiConnected: m['wifiConnected'] == true,
    wifiOpen: m['wifiOpen'] is bool ? m['wifiOpen'] as bool : null,
    wifiCaptivePortal: m['wifiCaptivePortal'] == true,
  );

  final bool developerOptions;
  final bool usbDebugging;
  final bool vpnActive;

  /// `none`, `tailscale`, `adguard` (both allowed) or `other`.
  final String vpnKind;
  final bool wifiConnected;

  /// Null when Android does not say (before Android 12).
  final bool? wifiOpen;
  final bool wifiCaptivePortal;

  static const Set<String> allowedVpns = {'tailscale', 'adguard'};

  /// The problems that block the app, in the order the user should fix them.
  List<IntegrityProblem> get problems => [
    if (developerOptions || usbDebugging) IntegrityProblem.developerOptions,
    if (vpnActive && !allowedVpns.contains(vpnKind)) IntegrityProblem.vpn,
    if (wifiConnected && (wifiOpen == true || wifiCaptivePortal))
      IntegrityProblem.publicWifi,
  ];
}

/// Asks Android whether the phone is safe enough to run MSS.
///
/// Only enforced in release builds on Android ([enforced]): debug and profile
/// builds run on emulators and test phones, which have developer options on.
class DeviceIntegrityService {
  DeviceIntegrityService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'com.inschemes.app/device_integrity';
  static final DeviceIntegrityService instance = DeviceIntegrityService();

  final MethodChannel _channel;

  static bool get enforced =>
      kReleaseMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  /// The current report; a clean one when the platform cannot answer, so a
  /// missing bridge never locks everyone out.
  Future<IntegrityReport> report() async {
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>('report');
      return map == null
          ? const IntegrityReport()
          : IntegrityReport.fromMap(map);
    } catch (e) {
      debugPrint('[DeviceIntegrity] report failed: $e');
      return const IntegrityReport();
    }
  }

  /// Opens the settings page that fixes [problem].
  Future<bool> openSettings(IntegrityProblem problem) async {
    final kind = switch (problem) {
      IntegrityProblem.developerOptions => 'developer',
      IntegrityProblem.vpn => 'vpn',
      IntegrityProblem.publicWifi => 'wifi',
    };
    try {
      return await _channel.invokeMethod<bool>('openSettings', {
            'kind': kind,
          }) ??
          false;
    } catch (e) {
      debugPrint('[DeviceIntegrity] openSettings failed: $e');
      return false;
    }
  }
}
