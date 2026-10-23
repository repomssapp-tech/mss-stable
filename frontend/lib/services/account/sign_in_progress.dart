import 'dart:async';

import 'package:flutter/widgets.dart';

/// Where a Google sign-in is, from the app's side.
enum SignInPhase {
  /// Nothing in flight; the Sign in button may be used.
  idle,

  /// Google's page is open in the browser; the user is picking an account.
  inBrowser,

  /// The user is back in the app and the sign-in is being finished (the
  /// callback is arriving or the code is being exchanged). The login screen
  /// shows a loading overlay so a second sign-in cannot be started.
  completing,
}

/// Tracks a Google sign-in across the browser round trip, so the login screen
/// can block a second attempt while the first is finishing.
///
/// Returning from the browser without finishing (back button, closed tab) has
/// no callback to wait for, so after [resumeGrace] the phase goes back to idle.
class SignInProgress {
  SignInProgress._() {
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  static final SignInProgress instance = SignInProgress._();

  /// How long to wait for the sign-in callback after the app comes back to the
  /// foreground before treating the sign-in as abandoned.
  static const Duration resumeGrace = Duration(seconds: 6);

  /// Upper bound for finishing a sign-in once the callback has arrived.
  static const Duration completeTimeout = Duration(seconds: 30);

  // Kept so the listener is not garbage collected.
  // ignore: unused_field
  late final AppLifecycleListener _lifecycle;

  final ValueNotifier<SignInPhase> phase = ValueNotifier(SignInPhase.idle);
  Timer? _timer;

  /// Google's page was opened in the browser.
  void browserOpened() {
    _set(SignInPhase.inBrowser);
  }

  /// The callback with the sign-in code arrived: the app is finishing it.
  void completing() {
    _set(SignInPhase.completing, timeout: completeTimeout);
  }

  /// The sign-in finished, failed or was abandoned.
  void finish() {
    _set(SignInPhase.idle);
  }

  void _onResume() {
    if (phase.value == SignInPhase.inBrowser) {
      // Back from the browser: the callback is normally delivered right away.
      _set(SignInPhase.completing, timeout: resumeGrace);
    }
  }

  void _set(SignInPhase next, {Duration? timeout}) {
    _timer?.cancel();
    _timer = null;
    phase.value = next;
    if (timeout != null) {
      _timer = Timer(timeout, () {
        _timer = null;
        phase.value = SignInPhase.idle;
      });
    }
  }

  @visibleForTesting
  void resetForTest() {
    _timer?.cancel();
    _timer = null;
    phase.value = SignInPhase.idle;
  }
}
