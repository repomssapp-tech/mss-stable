/// Backend routes the app calls that are NOT in `backend/New API Ref`.
///
/// The reference documents schemes, catalog updates, notifications and
/// promotions. Everything below replaced a table, RPC or function of the old
/// hosted backend and has no published contract yet, so each path is an ASSUMPTION. They are
/// all listed here so they can be checked against the real server in one place;
/// until a route exists the server answers 404/501 and the feature falls back to
/// its existing offline/failure behaviour (see each caller).
///
/// All paths are relative to `/v1` (see [ApiClient]).
library;

class PendingEndpoints {
  PendingEndpoints._();

  /// `POST {password}` → `{unlocked: bool}` — beta gate check
  /// (was the `beta_gate_config` table, compared on the device).
  static const String betaGateVerify = '/beta-gate/verify';

  /// `POST {conversation_uid, ...}` — store a finished voice/chat conversation
  /// (was the `voice_chat_sessions` table).
  static const String chatSessions = '/me/chat-sessions';

  /// `POST {answers: {field_id: value}}` once, right after a guest signs up —
  /// carries the questionnaire answers kept on the device to the new account,
  /// then the server discards them (DEV 1 task 1.4 "upgrade path"). Not called
  /// yet: the route and the on-device answers store do not exist. Until then
  /// AppProvider._uploadGuestAnswers sends the profile through the existing
  /// profile write.
  static const String guestUpgrade = '/me/guest-upgrade';

  static const String analyticsEvents = '/analytics/events';
}
