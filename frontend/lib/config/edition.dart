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
  /// checks for app updates. Each edition has its own, so one edition's
  /// update never reaches another edition's phones.
  final String releasesRepo;

  static const central = EditionConfig(
    key: 'central',
    appName: 'MSS',
    defaultLanguage: 'en',
    releasesRepo: 'nyxri0f8/MSS_App-releases',
  );

  static const tamilNadu = EditionConfig(
    key: 'tn',
    appName: 'MSS Tamil Nadu',
    stateCode: 'IN-TN',
    defaultLanguage: 'ta',
    releasesRepo: 'repomssapp-tech/mss-tn-releases',
  );

  static const maharashtra = EditionConfig(
    key: 'mh',
    appName: 'MSS Maharashtra',
    stateCode: 'IN-MH',
    defaultLanguage: 'mr',
    releasesRepo: 'repomssapp-tech/mss-mh-releases',
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
