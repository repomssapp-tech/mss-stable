import 'package:supabase_flutter/supabase_flutter.dart';

class SarvamChatMessage {
  const SarvamChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class SarvamChatResponse {
  const SarvamChatResponse({required this.reply, this.usage});

  final String reply;
  final Map<String, dynamic>? usage;
}

class SarvamChatException implements Exception {
  const SarvamChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class SarvamChatClient {
  Future<SarvamChatResponse> complete({
    required List<SarvamChatMessage> messages,
    required String language,
  });
}

class SupabaseSarvamChatClient implements SarvamChatClient {
  SupabaseSarvamChatClient({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<SarvamChatResponse> complete({
    required List<SarvamChatMessage> messages,
    required String language,
  }) async {
    var session = _client.auth.currentSession;
    if (session == null) {
      throw const SarvamChatException('Sign in to chat with Saarthi.');
    }
    if (session.isExpired) {
      session = (await _client.auth.refreshSession()).session;
      if (session == null) {
        throw const SarvamChatException(
          'Your session expired. Please sign in again.',
        );
      }
    }

    try {
      final response = await _client.functions.invoke(
        'sarvam-chat',
        body: {
          'language': language == 'ta' ? 'ta' : 'en',
          'messages': messages.map((message) => message.toJson()).toList(),
        },
      );
      final data = response.data;
      if (data is! Map || data['reply'] is! String) {
        throw const SarvamChatException(
          'Saarthi returned an unexpected response.',
        );
      }
      final reply = (data['reply'] as String).trim();
      if (reply.isEmpty) {
        throw const SarvamChatException('Saarthi returned an empty response.');
      }
      final rawUsage = data['usage'];
      return SarvamChatResponse(
        reply: reply,
        usage: rawUsage is Map ? Map<String, dynamic>.from(rawUsage) : null,
      );
    } on SarvamChatException {
      rethrow;
    } catch (_) {
      throw const SarvamChatException(
        'Could not reach Saarthi. Check your connection and try again.',
      );
    }
  }
}
