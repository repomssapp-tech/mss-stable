/// Build-time switches for the location lock and the dev channel.
///
/// Both default to off, so a production build (no `--dart-define`) behaves
/// exactly as before. The dev build passes
/// `--dart-define=MSS_CHANNEL=dev --dart-define=MSS_LOCATION_LOCK=true`.
library;

import '../../config/edition.dart';

/// `dev` for the separate testing build, `prod` otherwise.
const String kAppChannel = String.fromEnvironment(
  'MSS_CHANNEL',
  defaultValue: 'prod',
);

/// True in the separate dev build (installs beside the store app as
/// `com.inschemes.app.dev` and never checks for production updates).
const bool kIsDevChannel = kAppChannel == 'dev';

/// Whether the app is locked to the state the phone's GPS is in.
///
/// A state edition (Tamil Nadu, Maharashtra) is already tied to its state,
/// so it never runs the GPS lock, even in its dev build.
const bool kLocationLockEnabled =
    bool.fromEnvironment('MSS_LOCATION_LOCK', defaultValue: false) &&
    !kEditionHasState;
