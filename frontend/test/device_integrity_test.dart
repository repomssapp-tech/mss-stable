// The security gate: Developer options / USB debugging, VPNs other than
// Tailscale and AdGuard, and open or sign-in-page Wi-Fi block the app; the
// gate clears by itself once the problem is fixed.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/security/device_integrity_service.dart';
import 'package:frontend/widgets/common/device_integrity_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntegrityReport.problems', () {
    test('a clean phone has no problems', () {
      expect(const IntegrityReport().problems, isEmpty);
      expect(
        const IntegrityReport(wifiConnected: true, wifiOpen: false).problems,
        isEmpty,
      );
    });

    test('developer options or USB debugging block', () {
      expect(const IntegrityReport(developerOptions: true).problems, [
        IntegrityProblem.developerOptions,
      ]);
      expect(const IntegrityReport(usbDebugging: true).problems, [
        IntegrityProblem.developerOptions,
      ]);
    });

    test('only Tailscale and AdGuard VPNs are allowed', () {
      for (final kind in ['tailscale', 'adguard']) {
        expect(
          IntegrityReport(vpnActive: true, vpnKind: kind).problems,
          isEmpty,
          reason: kind,
        );
      }
      expect(
        const IntegrityReport(vpnActive: true, vpnKind: 'other').problems,
        [IntegrityProblem.vpn],
      );
    });

    test('open or sign-in-page Wi-Fi blocks; unknown security does not', () {
      expect(
        const IntegrityReport(wifiConnected: true, wifiOpen: true).problems,
        [IntegrityProblem.publicWifi],
      );
      expect(
        const IntegrityReport(
          wifiConnected: true,
          wifiOpen: false,
          wifiCaptivePortal: true,
        ).problems,
        [IntegrityProblem.publicWifi],
      );
      expect(const IntegrityReport(wifiConnected: true).problems, isEmpty);
    });

    test('a native report map is read', () {
      final r = IntegrityReport.fromMap({
        'developerOptions': false,
        'usbDebugging': false,
        'vpnActive': true,
        'vpnKind': 'other',
        'wifiConnected': true,
        'wifiOpen': null,
        'wifiCaptivePortal': true,
      });
      expect(r.problems, [IntegrityProblem.vpn, IntegrityProblem.publicWifi]);
    });
  });

  testWidgets('the gate blocks while a problem exists and clears after', (
    tester,
  ) async {
    const channel = MethodChannel(DeviceIntegrityService.channelName);
    var report = <String, Object?>{'vpnActive': true, 'vpnKind': 'other'};
    final opened = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'report') return report;
      opened.add((call.arguments as Map)['kind'] as String);
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final network = StreamController<Object?>.broadcast();
    addTearDown(network.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceIntegrityGate(
          enforced: true,
          networkChanges: network.stream,
          child: const Scaffold(body: Text('app')),
        ),
      ),
    );
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.integrityVpnTitle), findsOneWidget);

    await tester.tap(find.text(l10n.integrityOpenVpn));
    await tester.pump();
    expect(opened, ['vpn']);

    // The user turns the VPN off; the next network change clears the gate.
    report = {'vpnActive': false};
    network.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.integrityVpnTitle), findsNothing);
    expect(find.text('app'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('debug and profile builds are never blocked', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeviceIntegrityGate(
          enforced: false,
          child: Scaffold(body: Text('app')),
        ),
      ),
    );
    expect(find.text('app'), findsOneWidget);
  });
}
