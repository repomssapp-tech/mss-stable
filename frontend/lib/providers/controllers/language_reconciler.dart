/// Resolves which language value to trust when a server profile row /
/// realtime echo arrives, extracted from `AppProvider` (frontend refactor,
/// decomposition follow-up). Self-contained: holds only its own pending-value
/// state, no `AppProvider` field access.
///
/// If the user just switched language explicitly, a server value that still
/// shows the OLD language is a stale echo — [reconcile] keeps the user's
/// choice for a short window. Once the server agrees (or the window lapses)
/// it goes back to trusting the server value.
class LanguageReconciler {
  String? _pendingLanguage;
  DateTime? _pendingLanguageSince;

  /// Call when the user explicitly changes language, before the change is
  /// persisted/echoed back by the server.
  void markPending(String lang) {
    _pendingLanguage = lang;
    _pendingLanguageSince = DateTime.now();
  }

  /// Clears any pending choice (e.g. on logout/account deletion, where the
  /// language is also reset to the default).
  void reset() {
    _pendingLanguage = null;
    _pendingLanguageSince = null;
  }

  String reconcile(String serverLang) {
    final pending = _pendingLanguage;
    final since = _pendingLanguageSince;
    if (pending == null || since == null) return serverLang;
    if (serverLang == pending) {
      _pendingLanguage = null;
      _pendingLanguageSince = null;
      return serverLang;
    }
    if (DateTime.now().difference(since) < const Duration(seconds: 20)) {
      return pending;
    }
    _pendingLanguage = null;
    _pendingLanguageSince = null;
    return serverLang;
  }
}
