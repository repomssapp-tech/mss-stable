/// Resolves which navigation-mode value to trust when a server profile row /
/// realtime echo arrives. Same pending-value-with-grace-window pattern as
/// [LanguageReconciler] (see `language_reconciler.dart`), duplicated rather
/// than shared so each stays a simple, independently-testable single-field
/// guard. Self-contained: holds only its own pending-value state, no
/// `AppProvider` field access.
///
/// If the user just switched navigation mode explicitly, a server value that
/// still shows the OLD mode is a stale echo -- [reconcile] keeps the user's
/// choice for a short window. Once the server agrees (or the window lapses)
/// it goes back to trusting the server value.
class NavigationModeReconciler {
  String? _pendingMode;
  DateTime? _pendingModeSince;

  /// Call when the user explicitly changes navigation mode, before the
  /// change is persisted/echoed back by the server.
  void markPending(String mode) {
    _pendingMode = mode;
    _pendingModeSince = DateTime.now();
  }

  /// Clears any pending choice (e.g. on logout/account deletion, where the
  /// navigation mode is also reset to the default).
  void reset() {
    _pendingMode = null;
    _pendingModeSince = null;
  }

  String reconcile(String serverMode) {
    final pending = _pendingMode;
    final since = _pendingModeSince;
    if (pending == null || since == null) return serverMode;
    if (serverMode == pending) {
      _pendingMode = null;
      _pendingModeSince = null;
      return serverMode;
    }
    if (DateTime.now().difference(since) < const Duration(seconds: 20)) {
      return pending;
    }
    _pendingMode = null;
    _pendingModeSince = null;
    return serverMode;
  }
}
