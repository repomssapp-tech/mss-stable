import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_version.dart';
import '../app_info_service.dart';
import 'app_release.dart';
import '../../config/edition.dart';
import '../location_lock/location_lock_config.dart';

/// Whether a newer app build has been published in the public releases repo.
///
/// The app is sideloaded (no store update path), so the only way users hear of
/// a new build is this check. It asks the public GitHub releases API with no
/// token, compares the newest `app-vX.Y.Z+N` build number against the installed
/// `versionCode`, and stays silent on every failure (offline, timeout, rate
/// limit, malformed reply): it must never hold up or break the app.
class AppUpdateService {
  AppUpdateService({
    http.Client? client,
    Future<AppVersion?> Function()? installedVersion,
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? clock,
    Duration timeout = requestTimeout,
  }) : _client = client ?? http.Client(),
       _timeout = timeout,
       _installedVersion = installedVersion ?? AppInfoService.installedVersion,
       _preferences = preferences ?? SharedPreferences.getInstance,
       _clock = clock ?? DateTime.now;

  static final AppUpdateService instance = AppUpdateService();

  /// The public, releases-only repository CI publishes every signed build to.
  /// The source repository is private, so its own releases 404 for users.
  /// Each edition has its own, so an update for one edition never reaches
  /// another edition's phones.
  static final String releasesRepo = kEdition.releasesRepo;

  /// The newest few releases. The list (not `/releases/latest`) is read so a
  /// non-app release marked "latest" cannot hide an app build.
  static final Uri releasesApi = Uri.parse(
    'https://api.github.com/repos/$releasesRepo/releases?per_page=10',
  );

  /// The permanent "latest release" page, opened from Settings.
  static final Uri latestReleasePage = Uri.parse(
    'https://github.com/$releasesRepo/releases/latest',
  );

  /// Checks on returning to the foreground are at most this often. The
  /// unauthenticated API allows 60 requests an hour per IP address.
  static const Duration resumeGap = Duration(hours: 6);

  static const Duration requestTimeout = Duration(seconds: 8);

  static const String lastCheckKey = 'app_update_last_check_ms';
  static const String dismissedBuildKey = 'app_update_dismissed_build';

  final http.Client _client;
  final Future<AppVersion?> Function() _installedVersion;
  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _clock;
  final Duration _timeout;

  /// The release to tell the user about, or null when there is none (or the
  /// check failed). [onStart] checks regardless of the last check's time; a
  /// check on resume is skipped within [resumeGap] of the last one.
  Future<AppRelease?> check({bool onStart = false}) async {
    // The dev/test build is a separate app (com.inschemes.app.dev): it is
    // never offered production builds.
    if (kIsDevChannel) return null;
    try {
      final installed = await _installedVersion();
      if (installed == null) return null;
      final prefs = await _preferences();
      final now = _clock();
      if (!onStart && !isDue(prefs.getInt(lastCheckKey), now)) return null;
      // Recorded before the request, so a failing check (rate limit) is not
      // retried on every resume either.
      await prefs.setInt(lastCheckKey, now.millisecondsSinceEpoch);
      final release = await _fetchNewest();
      if (release == null) return null;
      final notify = shouldNotify(
        release: release,
        installed: installed,
        dismissedBuild: prefs.getInt(dismissedBuildKey),
      );
      return notify ? release : null;
    } catch (e) {
      debugPrint('[AppUpdateService] check skipped: $e');
      return null;
    }
  }

  /// "Later": [release] (and anything older) is not offered again; a newer
  /// build is.
  Future<void> dismiss(AppRelease release) async {
    try {
      final prefs = await _preferences();
      await prefs.setInt(dismissedBuildKey, release.version.build);
    } catch (e) {
      debugPrint('[AppUpdateService] dismissal not saved: $e');
    }
  }

  /// True when [lastCheckMs] is unset, at least [gap] ago, or in the future
  /// (the phone's clock was moved back).
  static bool isDue(
    int? lastCheckMs,
    DateTime now, {
    Duration gap = resumeGap,
  }) {
    if (lastCheckMs == null) return true;
    final elapsed = now.difference(
      DateTime.fromMillisecondsSinceEpoch(lastCheckMs),
    );
    return elapsed.isNegative || elapsed >= gap;
  }

  /// Android installs over the current app only when the new `versionCode` is
  /// higher, so the build number alone decides whether a release is newer.
  static bool shouldNotify({
    required AppRelease release,
    required AppVersion installed,
    int? dismissedBuild,
  }) {
    final build = release.version.build;
    return build > installed.build && build > (dismissedBuild ?? 0);
  }

  Future<AppRelease?> _fetchNewest() async {
    final response = await _client
        .get(
          releasesApi,
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        )
        .timeout(_timeout);
    // 403/429 (rate limit), 404 and anything else: say nothing.
    if (response.statusCode != 200) return null;
    return AppRelease.newestOf(jsonDecode(response.body));
  }
}
