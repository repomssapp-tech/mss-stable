/// Build-time edition: which MSS app this build is.
///
/// One codebase builds three apps. The edition is chosen with
/// `--dart-define=MSS_EDITION=<key>` (CI reads it from the repository
/// variable `MSS_EDITION`). Without it the build is the Central edition,
/// which is the original MSS app, unchanged.
///
/// | key       | App               | Android app ID          | State       |
/// |-----------|-------------------|-------------------------|-------------|
/// | `central` | MSS               | `com.inschemes.app`     | any (none)  |
/// | `tn`      | MSS Tamil Nadu    | `com.inschemes.app.tn`  | Tamil Nadu  |
/// | `mh`      | MSS Maharashtra   | `com.inschemes.app.mh`  | Maharashtra |
///
/// The Android app ID and launcher name are set from the same define in
/// `android/app/build.gradle.kts`; keep the two tables in step.
library;

import 'package:flutter/foundation.dart';

/// The raw edition key from the build.
const String kEditionKey = String.fromEnvironment(
  'MSS_EDITION',
  defaultValue: 'central',
);

/// True for an edition tied to one state (Tamil Nadu, Maharashtra). Such a
/// build shows Central schemes plus that state's schemes only, offers only
/// that state's languages and never asks for GPS.
const bool kEditionHasState = kEditionKey == 'tn' || kEditionKey == 'mh';

const bool _kDevChannel =
    String.fromEnvironment('MSS_CHANNEL', defaultValue: 'prod') == 'dev';

/// This build's Android app ID (the same rule as `build.gradle.kts`):
/// `com.inschemes.app`, plus `.tn` / `.mh` for a state edition, plus `.dev`
/// for a dev build.
const String kAppId =
    'com.inschemes.app'
    '${kEditionKey == 'tn'
        ? '.tn'
        : kEditionKey == 'mh'
        ? '.mh'
        : ''}'
    '${_kDevChannel ? '.dev' : ''}';

/// Where Google sign-in returns to: a link only this app opens. Each app has
/// its own, so with MSS and MSS Dev (or a state edition) on the same phone the
/// sign-in always comes back to the app that started it.
const String kAuthRedirectUrl = '$kAppId://login-callback/';

/// The original MSS app's return link, which the server uses when the app
/// sends none.
const String kDefaultAuthRedirectUrl = 'com.inschemes.app://login-callback/';

/// Where every edition's official releases are published (public). Dev
/// pre-releases go to the private mss-dev repository and are never offered
/// as updates.
const String kStableReleasesRepo = 'repomssapp-tech/mss-stable';

/// Everything that differs between editions.
@immutable
class EditionConfig {
  const EditionConfig({
    required this.key,
    required this.appName,
    required this.defaultLanguage,
    required this.releasesRepo,
    this.stateCode,
  });

  /// `central`, `tn` or `mh`.
  final String key;

  /// The app's name, as on the launcher.
  final String appName;

  /// ISO 3166-2 code of the edition's state (`IN-TN`, `IN-MH`), or null for
  /// the Central edition.
  final String? stateCode;

  /// Language the app opens in on a fresh install.
  final String defaultLanguage;

  /// Public GitHub repository (`owner/name`) whose releases this edition
  /// checks for app updates: mss-stable, the only public MSS repository. A
  /// stable release carries one APK per edition (`mss-<key>-<version>.apk`)
  /// and each app downloads only its own (see AppRelease), so one edition's
  /// APK never reaches another edition's phones.
  final String releasesRepo;

  static const central = EditionConfig(
    key: 'central',
    appName: 'MSS',
    defaultLanguage: 'en',
    releasesRepo: kStableReleasesRepo,
  );

  static const tamilNadu = EditionConfig(
    key: 'tn',
    appName: 'MSS Tamil Nadu',
    stateCode: 'IN-TN',
    defaultLanguage: 'ta',
    releasesRepo: kStableReleasesRepo,
  );

  static const maharashtra = EditionConfig(
    key: 'mh',
    appName: 'MSS Maharashtra',
    stateCode: 'IN-MH',
    defaultLanguage: 'mr',
    releasesRepo: kStableReleasesRepo,
  );

  static const all = [central, tamilNadu, maharashtra];

  /// The edition for [key]; an unknown key is the Central edition.
  static EditionConfig forKey(String key) => switch (key.trim().toLowerCase()) {
    'tn' => tamilNadu,
    'mh' => maharashtra,
    _ => central,
  };
}

/// This build's edition.
const EditionConfig kEdition = kEditionKey == 'tn'
    ? EditionConfig.tamilNadu
    : kEditionKey == 'mh'
    ? EditionConfig.maharashtra
    : EditionConfig.central;
