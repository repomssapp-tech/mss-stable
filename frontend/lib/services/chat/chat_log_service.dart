import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/app_session.dart';
import '../backend/pending_endpoints.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

enum ChatMessageSpeaker { user, assistant }

@immutable
class ChatMessageRecord {
  const ChatMessageRecord({
    required this.id,
    required this.speaker,
    required this.text,
    required this.timestamp,
    this.recommendations,
  });

  final String id;
  final ChatMessageSpeaker speaker;
  final String text;
  final DateTime timestamp;
  final dynamic recommendations;

  ChatMessageRecord copyWith({
    String? text,
    dynamic recommendations,
    bool clearRecommendations = false,
  }) => ChatMessageRecord(
    id: id,
    speaker: speaker,
    text: text ?? this.text,
    timestamp: timestamp,
    recommendations: clearRecommendations
        ? null
        : recommendations ?? this.recommendations,
  );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'speaker': speaker.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
    if (recommendations != null) {
      map['recommendations'] = recommendations;
    }
    return map;
  }

  factory ChatMessageRecord.fromJson(Map<String, dynamic> json) {
    dynamic parsedRecommendations = false;
    final rawRecs = json['recommendations'];
    if (rawRecs is bool) {
      parsedRecommendations = rawRecs;
    } else if (rawRecs is List) {
      parsedRecommendations = rawRecs.map((e) => e.toString()).toList();
    }

    return ChatMessageRecord(
      id: json['id'] as String? ?? '',
      speaker: json['speaker'] == 'assistant'
          ? ChatMessageSpeaker.assistant
          : ChatMessageSpeaker.user,
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ??
                DateTime.now().toUtc()
          : DateTime.now().toUtc(),
      recommendations: parsedRecommendations,
    );
  }
}

/// Pure mapping utility that transforms internal chat data into the exact
/// session payload stored by the backend, stripping away
/// all transient and UI-only properties (such as typing indicators, animation states).
class ChatPayloadMapper {
  const ChatPayloadMapper._();

  /// Detects the language of a text string by checking for Tamil Unicode
  /// characters (U+0B80–U+0BFF). Returns 'ta' for Tamil, 'en' otherwise.
  static String _detectLanguage(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0B80 && rune <= 0x0BFF) return 'ta';
    }
    return 'en';
  }

  /// Constructs a single session payload.
  static Map<String, dynamic> mapMessagesToSessionRow({
    required String conversationUid,
    required List<ChatMessageRecord> messages,
    required String mode,
    Map<String, dynamic>? baseMetadata,
    String? userId,
  }) {
    if (messages.isEmpty) return const {};

    final transcript = <Map<String, dynamic>>[];
    var currentTurn = 0;

    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final text = m.text.trim();
      if (text.isEmpty) continue;

      if (m.speaker == ChatMessageSpeaker.user) {
        currentTurn++;
        transcript.add({
          'turn': currentTurn,
          'role': 'user',
          'text': text,
          'timestamp': m.timestamp.toIso8601String(),
          'detected_language': _detectLanguage(text),
        });
      } else {
        if (currentTurn == 0) currentTurn = 1;
        transcript.add({
          'turn': currentTurn,
          'role': 'ai',
          'text': text,
          'timestamp': m.timestamp.toIso8601String(),
          'token_usage_ai': 0,
          'interrupted_by_user': false,
          'recommendations':
              (m.recommendations is List &&
                  (m.recommendations as List).isNotEmpty)
              ? m.recommendations
              : false,
        });
      }
    }

    if (transcript.isEmpty) return const {};

    final createdAt = messages.first.timestamp.toIso8601String();
    final endedAt = messages.last.timestamp.toIso8601String();
    final durationSec = messages.last.timestamp
        .difference(messages.first.timestamp)
        .inSeconds;
    const status = 'completed';

    return {
      'session_id': conversationUid,
      'user_id': userId,
      'status': status,
      'transcript': transcript,
      'session_metrics': {
        'total_duration_sec': durationSec,
        'total_turns': currentTurn,
        'session_ended_type': status,
        'metadata': ?baseMetadata,
      },
      'created_at': createdAt,
      'ended_at': endedAt,
    };
  }
}

/// Service that buffers conversation speech both in memory and locally on disk,
/// and uploads the completed conversation to the backend in a single request
/// when the session ends.
///
/// Sends one finished conversation to the backend. Throws when the server does
/// not accept it, so the session stays queued on disk.
typedef ChatSessionUploader = Future<void> Function(Map<String, dynamic> row);

/// Default uploader: `POST` to the chat-sessions route (an assumed route, see
/// `PendingEndpoints`). The owner is taken from the bearer token, so the row's
/// `user_id` is not sent.
Future<void> uploadChatSessionToBackend(Map<String, dynamic> row) async {
  final body = Map<String, dynamic>.of(row)..remove('user_id');
  await ApiClient.instance.post(PendingEndpoints.chatSessions, body: body);
}

/// Features:
/// 1. Real-time in-memory buffer for 0ms latency during active speech.
/// 2. Local disk persistence via SharedPreferences to survive app crashes or abrupt closes.
/// 3. Offline retry queue that automatically uploads unsaved sessions upon reconnection.
class ChatLogService {
  ChatLogService({String? conversationUid}) {
    startSession(customUid: conversationUid);
  }

  static const String _pendingSessionsKey = 'chat_log_pending_sessions';
  static const String _sessionDataPrefix = 'chat_log_session_';

  late String _conversationUid;
  final List<ChatMessageRecord> _messages = [];
  bool _isFlushing = false;
  bool _isFlushed = false;

  /// Owner captured when the session STARTS, not when it is flushed.
  ///
  /// Resolving the user at flush time attributed a session to whoever happened
  /// to be signed in at upload, so a queued session could be stamped with a
  /// different user than the one who actually spoke it. Capture it up front.
  String? _sessionUserId;

  String get conversationUid => _conversationUid;
  bool get isFlushed => _isFlushed;
  int get messageCount => _messages.length;

  /// Generates a RFC-4122 compliant UUID v4 string.
  static String generateUuidV4() {
    final random = math.Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant RFC4122
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Initializes or resets a session with a unique conversation UID.
  void startSession({String? customUid}) {
    _conversationUid = (customUid != null && customUid.trim().isNotEmpty)
        ? customUid.trim()
        : generateUuidV4();
    _messages.clear();
    _isFlushing = false;
    _isFlushed = false;
    _sessionUserId = _currentUserId();
  }

  /// Current signed-in user id, or null if auth is unavailable/not yet restored.
  static String? _currentUserId() {
    return AppSession.instance.userId;
  }

  /// Inserts or updates an in-memory message record by message ID,
  /// and mirrors the updated session state to local disk asynchronously.
  void upsertMessage({
    required String id,
    required ChatMessageSpeaker speaker,
    required String text,
    DateTime? timestamp,
    dynamic recommendations,
  }) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    final existingIndex = _messages.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _messages[existingIndex] = _messages[existingIndex].copyWith(
        text: cleaned,
        recommendations: recommendations,
      );
    } else {
      _messages.add(
        ChatMessageRecord(
          id: id,
          speaker: speaker,
          text: cleaned,
          timestamp: (timestamp ?? DateTime.now()).toUtc(),
          recommendations: recommendations,
        ),
      );
    }

    // Persist active state locally so speech is never lost on sudden process exit
    unawaited(_persistSessionLocally());
  }

  /// Convenience helper to record a user speech/text turn.
  void recordUserMessage(String text, {String? id}) {
    final messageId = id ?? 'user-${generateUuidV4()}';
    upsertMessage(id: messageId, speaker: ChatMessageSpeaker.user, text: text);
  }

  /// Convenience helper to record a Saarthi agent reply.
  void recordAiMessage(String text, {String? id, dynamic recommendations}) {
    final messageId = id ?? 'assistant-${generateUuidV4()}';
    upsertMessage(
      id: messageId,
      speaker: ChatMessageSpeaker.assistant,
      text: text,
      recommendations: recommendations,
    );
  }

  /// Transforms in-memory messages into a structured JSON session matching
  /// the schema of `public.voice_chat_sessions`.
  Map<String, dynamic> buildSessionRow({
    required String mode,
    Map<String, dynamic>? baseMetadata,
    String? userId,
  }) {
    // Prefer the owner captured at session start; fall back to the live session
    // only if this instance never saw one (e.g. restored from disk).
    final resolvedUserId = userId ?? _sessionUserId ?? _currentUserId();

    // The backend accepts authenticated writes only: every row must be bound to
    // its owner. Without a user there is no lawful row to write, so
    // build nothing rather than emit an unattributable orphan that the server
    // will reject anyway.
    if (resolvedUserId == null) {
      debugPrint(
        '[ChatLogService] No authenticated user for session $_conversationUid; '
        'skipping upload (session stays on disk until sign-in).',
      );
      return const {};
    }

    return ChatPayloadMapper.mapMessagesToSessionRow(
      conversationUid: _conversationUid,
      messages: _messages,
      mode: mode,
      baseMetadata: baseMetadata,
      userId: resolvedUserId,
    );
  }

  /// Dedicated batch upload method that reads the entire local cache for the
  /// current session and uploads it to the backend.
  ///
  /// CRITICAL RULE: Clears the local cache IF AND ONLY IF the upload
  /// returns a successful response. If the network fails, local cache remains
  /// intact for future recovery.
  Future<bool> syncChatSession({
    String mode = 'voice',
    ChatSessionUploader? uploader,
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    return flushSessionLogs(
      mode: mode,
      uploader: uploader,
      metadata: metadata,
      userId: userId,
    );
  }

  /// Persists current in-memory messages to local disk (SharedPreferences).
  Future<void> _persistSessionLocally() async {
    try {
      if (_messages.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final key = '$_sessionDataPrefix$_conversationUid';
      final serialized = jsonEncode(_messages.map((m) => m.toJson()).toList());
      await prefs.setString(key, serialized);

      final pendingList = prefs.getStringList(_pendingSessionsKey) ?? [];
      if (!pendingList.contains(_conversationUid)) {
        pendingList.add(_conversationUid);
        await prefs.setStringList(_pendingSessionsKey, pendingList);
      }
    } catch (e) {
      debugPrint('[ChatLogService] Local disk write notice: $e');
    }
  }

  /// Removes session from local disk once successfully uploaded.
  Future<void> _clearLocalSession(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_sessionDataPrefix$uid';
      await prefs.remove(key);

      final pendingList = prefs.getStringList(_pendingSessionsKey) ?? [];
      if (pendingList.contains(uid)) {
        pendingList.remove(uid);
        await prefs.setStringList(_pendingSessionsKey, pendingList);
      }
    } catch (e) {
      debugPrint('[ChatLogService] Local disk clear notice: $e');
    }
  }

  /// Sends accumulated turns to the backend in a single request. Protected by
  /// an atomic idempotency latch.
  ///
  /// If the server is unreachable or the device is offline, the conversation remains
  /// securely stored in SharedPreferences and will be uploaded automatically.
  Future<bool> flushSessionLogs({
    String mode = 'voice',
    ChatSessionUploader? uploader,
    Map<String, dynamic>? metadata,
    String? userId,
  }) async {
    debugPrint(
      '[ChatLogService] flushSessionLogs() triggered. In-memory messages: ${_messages.length}, isFlushed: $_isFlushed, isFlushing: $_isFlushing',
    );
    if (_isFlushed || _isFlushing) {
      debugPrint(
        '[ChatLogService] Flush aborted: already completed or in-progress.',
      );
      return false;
    }
    _isFlushing = true;

    try {
      // 0. Without an owner the row cannot be written (the server binds the
      //    session to the token's account). Bail out BEFORE the empty-row branch below, which
      //    deletes the local copy -- an unauthenticated flush must preserve
      //    the session on disk, not discard it.
      if ((userId ?? _sessionUserId ?? _currentUserId()) == null) {
        debugPrint(
          '[ChatLogService] No authenticated user; session $_conversationUid '
          'preserved on disk for retry after sign-in.',
        );
        await _persistSessionLocally();
        return false;
      }

      // 1. Build session row from in-memory records
      var sessionRow = buildSessionRow(
        mode: mode,
        baseMetadata: metadata,
        userId: userId,
      );

      // If in-memory buffer was empty, check if saved state exists on disk
      if (sessionRow.isEmpty) {
        debugPrint(
          '[ChatLogService] Memory was empty; checking local disk for session $_conversationUid...',
        );
        await _loadSessionFromLocalDisk();
        sessionRow = buildSessionRow(mode: mode, baseMetadata: metadata);
      }

      if (sessionRow.isEmpty) {
        debugPrint(
          '[ChatLogService] ⚠️ No conversation recorded (empty conversation). Nothing to upload.',
        );
        _isFlushed = true;
        await _clearLocalSession(_conversationUid);
        return false;
      }

      // 2. Guarantee local disk persistence before attempting network call
      await _persistSessionLocally();

      // 3. Upload the session in one request
      debugPrint('[ChatLogService] Uploading session $_conversationUid');
      await (uploader ?? uploadChatSessionToBackend)(sessionRow);
      _isFlushed = true;

      // 4. Clean up local disk cache now that the server has stored the session
      await _clearLocalSession(_conversationUid);
      debugPrint('[ChatLogService] Session $_conversationUid uploaded.');
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[ChatLogService] ❌ Cloud upload failed (offline/network error): $error',
      );
      debugPrint(
        '[ChatLogService] Session $_conversationUid is safely preserved in local disk queue for automatic retry.',
      );
      debugPrint('$stackTrace');
      return false;
    } finally {
      _isFlushing = false;
    }
  }

  /// Restores messages from disk if RAM was cleared.
  Future<void> _loadSessionFromLocalDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_sessionDataPrefix$_conversationUid');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _messages.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _messages.add(ChatMessageRecord.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatLogService] Notice reading local session: $e');
    }
  }

  /// Flushes any pending offline sessions stored on local disk to the backend.
  /// Can be called on app startup or when internet connectivity is re-established.
  static Future<int> syncPendingOfflineQueue({
    ChatSessionUploader? uploader,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUids = prefs.getStringList(_pendingSessionsKey) ?? [];
      if (pendingUids.isEmpty) return 0;

      // Nothing in the queue can be written without an owner; retrying would
      // just be refused on every launch. Leave the queue untouched and
      // drain it after the user signs in.
      if (_currentUserId() == null) {
        debugPrint(
          '[ChatLogService] Offline sync deferred: no authenticated user '
          '(${pendingUids.length} session(s) still queued).',
        );
        return 0;
      }

      final upload = uploader ?? uploadChatSessionToBackend;
      var syncedCount = 0;

      for (final uid in List<String>.from(pendingUids)) {
        try {
          final raw = prefs.getString('$_sessionDataPrefix$uid');
          if (raw == null || raw.isEmpty) {
            pendingUids.remove(uid);
            await prefs.remove('$_sessionDataPrefix$uid');
            continue;
          }

          final decoded = jsonDecode(raw) as List<dynamic>;
          final service = ChatLogService(conversationUid: uid);
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              service._messages.add(ChatMessageRecord.fromJson(item));
            }
          }

          final sessionRow = service.buildSessionRow(mode: 'voice');
          if (sessionRow.isNotEmpty) {
            await upload(sessionRow);
            debugPrint(
              '[ChatLogService] Offline sync: successfully uploaded pending session $uid.',
            );
          }

          // Cleared IF AND ONLY IF the upload succeeded
          await prefs.remove('$_sessionDataPrefix$uid');
          pendingUids.remove(uid);
          syncedCount++;
        } catch (e) {
          debugPrint(
            '[ChatLogService] Offline sync notice for session $uid: $e',
          );

          // Distinguish "try again later" from "will never succeed". A network
          // error is retryable; a rejected payload or a duplicate (already
          // uploaded) is not -- keeping those queued
          // retries a doomed insert on every launch, forever.
          if (_isPermanentUploadFailure(e)) {
            debugPrint(
              '[ChatLogService] Session $uid dropped from queue: permanent '
              'rejection, retrying cannot succeed.',
            );
            await prefs.remove('$_sessionDataPrefix$uid');
            pendingUids.remove(uid);
          }
        }
      }

      await prefs.setStringList(_pendingSessionsKey, pendingUids);
      return syncedCount;
    } catch (e) {
      debugPrint('[ChatLogService] Offline sync queue notice: $e');
      return 0;
    }
  }

  /// True when an upload failure can never succeed on retry, so the queued
  /// session should be dropped rather than retried on every launch.
  ///
  /// Retryable (returns false): network/timeout errors, 401 (sign in again),
  /// 429 and 5xx. Permanent (returns true): the server refused the payload
  /// (400/403/413/422) or already has the session (409).
  static bool _isPermanentUploadFailure(Object error) {
    if (error is ApiException) {
      return const {400, 403, 409, 413, 422}.contains(error.statusCode);
    }
    return false;
  }
}
