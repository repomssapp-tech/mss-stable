import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
}

/// Service that buffers conversation speech in memory during a voice session
/// and dispatches the completed conversation to Supabase public.chat_logs
/// in a single batch insert when the session ends.
class ChatLogService {
  ChatLogService({String? conversationUid}) {
    startSession(customUid: conversationUid);
  }

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

  /// Inserts or updates an in-memory message record by message ID.
  /// This prevents streaming speech deltas from generating partial duplicates.
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
  /// the schema of public.chat_logs.
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

  /// Sends accumulated turns to Supabase public.chat_logs table in a single
  /// batch HTTP request. Protected by an atomic idempotency latch.
  Future<bool> flushSessionLogs({
    String mode = 'voice',
    SupabaseClient? client,
    Map<String, dynamic>? metadata,
  }) async {
    if (_isFlushed || _isFlushing) {
      return false;
    }
    _isFlushing = true;

    try {
      final turns = buildTurns(mode: mode, baseMetadata: metadata);
      if (turns.isEmpty) {
        _isFlushed = true;
        return false;
      }

      final db = _resolveClient(client);
      if (db == null) {
        debugPrint('[ChatLogService] Supabase client not available. Skipping cloud log upload.');
        _isFlushed = true;
        return false;
      }

      await db.from('chat_logs').insert(turns);
      _isFlushed = true;
      debugPrint('[ChatLogService] Successfully flushed ${turns.length} turns for $_conversationUid to Supabase.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('[ChatLogService] Failed to flush chat logs to Supabase: $error');
      debugPrint('$stackTrace');
      return false;
    } finally {
      _isFlushing = false;
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
