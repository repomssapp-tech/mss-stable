import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ChatMessageSpeaker { user, assistant }

@immutable
class ChatMessageRecord {
  const ChatMessageRecord({
    required this.id,
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final ChatMessageSpeaker speaker;
  final String text;
  final DateTime timestamp;

  ChatMessageRecord copyWith({String? text}) => ChatMessageRecord(
        id: id,
        speaker: speaker,
        text: text ?? this.text,
        timestamp: timestamp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'speaker': speaker.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessageRecord.fromJson(Map<String, dynamic> json) {
    return ChatMessageRecord(
      id: json['id'] as String? ?? '',
      speaker: json['speaker'] == 'assistant'
          ? ChatMessageSpeaker.assistant
          : ChatMessageSpeaker.user,
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }
}

/// Service that buffers conversation speech both in memory and locally on disk,
/// and dispatches the completed conversation to Supabase `public.chat_logs`
/// table in a single batch insert when the session ends.
///
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
  }

  /// Inserts or updates an in-memory message record by message ID,
  /// and mirrors the updated session state to local disk asynchronously.
  void upsertMessage({
    required String id,
    required ChatMessageSpeaker speaker,
    required String text,
  }) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    final existingIndex = _messages.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _messages[existingIndex] = _messages[existingIndex].copyWith(text: cleaned);
    } else {
      _messages.add(
        ChatMessageRecord(
          id: id,
          speaker: speaker,
          text: cleaned,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    // Persist active state locally so speech is never lost on sudden process exit
    unawaited(_persistSessionLocally());
  }

  /// Convenience helper to record a user speech/text turn.
  void recordUserMessage(String text, {String? id}) {
    final messageId = id ?? 'user-${generateUuidV4()}';
    upsertMessage(
      id: messageId,
      speaker: ChatMessageSpeaker.user,
      text: text,
    );
  }

  /// Convenience helper to record a Saarthi agent reply.
  void recordAiMessage(String text, {String? id}) {
    final messageId = id ?? 'assistant-${generateUuidV4()}';
    upsertMessage(
      id: messageId,
      speaker: ChatMessageSpeaker.assistant,
      text: text,
    );
  }

  /// Pairs chronological in-memory messages into structured turns matching
  /// the schema of `public.chat_logs`.
  List<Map<String, dynamic>> buildTurns({
    required String mode,
    Map<String, dynamic>? baseMetadata,
  }) {
    if (_messages.isEmpty) return const [];

    final turns = <Map<String, dynamic>>[];
    var turnIndex = 1;
    final sanitizedMode = mode == 'text' ? 'text' : 'voice';
    final metadataPayload = baseMetadata ?? const {'source': 'flutter_frontend'};

    var i = 0;
    while (i < _messages.length) {
      final current = _messages[i];
      var currentText = current.text.trim();
      if (currentText.isEmpty) {
        i++;
        continue;
      }

      if (current.speaker == ChatMessageSpeaker.user) {
        // Accumulate consecutive user messages if any
        var nextIdx = i + 1;
        while (nextIdx < _messages.length &&
            _messages[nextIdx].speaker == ChatMessageSpeaker.user) {
          final nextText = _messages[nextIdx].text.trim();
          if (nextText.isNotEmpty) {
            currentText = '$currentText $nextText';
          }
          nextIdx++;
        }

        String aiMessage;
        if (nextIdx < _messages.length &&
            _messages[nextIdx].speaker == ChatMessageSpeaker.assistant) {
          aiMessage = _messages[nextIdx].text.trim();
          i = nextIdx + 1;
        } else {
          aiMessage = '(Session ended)';
          i = nextIdx;
        }

        turns.add({
          'conversation_uid': _conversationUid,
          'turn_index': turnIndex++,
          'mode': sanitizedMode,
          'user_message': currentText,
          'ai_message': aiMessage.isNotEmpty ? aiMessage : '(Session ended)',
          'metadata': metadataPayload,
        });
      } else {
        // Assistant spoke first (initial greeting)
        turns.add({
          'conversation_uid': _conversationUid,
          'turn_index': turnIndex++,
          'mode': sanitizedMode,
          'user_message': '(Session started)',
          'ai_message': currentText,
          'metadata': metadataPayload,
        });
        i++;
      }
    }

    return turns;
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

  /// Removes session from local disk once successfully uploaded to Supabase.
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

  /// Sends accumulated turns to Supabase public.chat_logs table in a single
  /// batch HTTP request. Protected by an atomic idempotency latch.
  ///
  /// If Supabase is unreachable or device is offline, the conversation remains
  /// securely stored in SharedPreferences and will be uploaded automatically.
  Future<bool> flushSessionLogs({
    String mode = 'voice',
    SupabaseClient? client,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint('[ChatLogService] flushSessionLogs() triggered. In-memory messages: ${_messages.length}, isFlushed: $_isFlushed, isFlushing: $_isFlushing');
    if (_isFlushed || _isFlushing) {
      debugPrint('[ChatLogService] Flush aborted: already completed or in-progress.');
      return false;
    }
    _isFlushing = true;

    try {
      // 1. Build turns from in-memory records
      var turns = buildTurns(mode: mode, baseMetadata: metadata);

      // If in-memory buffer was empty, check if saved state exists on disk
      if (turns.isEmpty) {
        debugPrint('[ChatLogService] Memory was empty; checking local disk for session $_conversationUid...');
        await _loadSessionFromLocalDisk();
        turns = buildTurns(mode: mode, baseMetadata: metadata);
      }

      if (turns.isEmpty) {
        debugPrint('[ChatLogService] ⚠️ No conversation turns recorded (empty conversation). Nothing to upload.');
        _isFlushed = true;
        await _clearLocalSession(_conversationUid);
        return false;
      }

      // 2. Guarantee local disk persistence before attempting network call
      await _persistSessionLocally();

      // 3. Resolve database client
      final db = _resolveClient(client);
      if (db == null) {
        debugPrint('[ChatLogService] ⚠️ Supabase client not available! Preserving session $_conversationUid on disk.');
        _isFlushed = true;
        return false;
      }

      // 4. Send single batch insert to Supabase public.chat_logs
      debugPrint('[ChatLogService] 🚀 Uploading ${turns.length} turn(s) for $_conversationUid to Supabase public.chat_logs:');
      for (final t in turns) {
        debugPrint('[ChatLogService]    Turn ${t['turn_index']}: User="${t['user_message']}" | AI="${t['ai_message']}"');
      }

      await db.from('chat_logs').insert(turns);
      _isFlushed = true;

      // 5. Clean up local disk cache now that Supabase has persisted the rows
      await _clearLocalSession(_conversationUid);
      debugPrint('[ChatLogService] ✅ Successfully flushed and confirmed ${turns.length} turns in Supabase public.chat_logs!');
      return true;
    } catch (error, stackTrace) {
      debugPrint('[ChatLogService] ❌ Cloud upload failed (offline/network error): $error');
      debugPrint('[ChatLogService] Session $_conversationUid is safely preserved in local disk queue for automatic retry.');
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

  /// Flushes any pending offline sessions stored on local disk to Supabase.
  /// Can be called on app startup or when internet connectivity is re-established.
  static Future<int> syncPendingOfflineQueue({SupabaseClient? client}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUids = prefs.getStringList(_pendingSessionsKey) ?? [];
      if (pendingUids.isEmpty) return 0;

      final db = client ?? (Supabase.instance.client);
      var syncedCount = 0;

      for (final uid in List<String>.from(pendingUids)) {
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

        final turns = service.buildTurns(mode: 'voice');
        if (turns.isNotEmpty) {
          await db.from('chat_logs').insert(turns);
          debugPrint('[ChatLogService] Offline sync: successfully uploaded pending session $uid (${turns.length} turns).');
        }

        await prefs.remove('$_sessionDataPrefix$uid');
        pendingUids.remove(uid);
        syncedCount++;
      }

      await prefs.setStringList(_pendingSessionsKey, pendingUids);
      return syncedCount;
    } catch (e) {
      debugPrint('[ChatLogService] Offline sync notice: $e');
      return 0;
    }
  }

  SupabaseClient? _resolveClient(SupabaseClient? provided) {
    if (provided != null) return provided;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
