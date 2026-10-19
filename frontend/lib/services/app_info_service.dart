import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/app_version.dart';

/// The version of the app that is actually installed on the device (the
/// pubspec `version:` as built: versionName + versionCode).
class AppInfoService {
  AppInfoService._();

  static Future<AppVersion?>? _cached;

  /// Null when the platform cannot report it (for example in widget tests).
  static Future<AppVersion?> installedVersion() => _cached ??= _read();

  static Future<AppVersion?> _read() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppVersion.tryParse('${info.version}+${info.buildNumber}');
    } catch (e) {
      debugPrint('[AppInfoService] version unavailable: $e');
      return null;
    }
  }

  @visibleForTesting
  static void overrideForTest(AppVersion? version) =>
      _cached = Future<AppVersion?>.value(version);

  @visibleForTesting
  static void resetForTest() => _cached = null;
}
