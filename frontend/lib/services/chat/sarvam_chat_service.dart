import '../../services/catalog/centralized_translator.dart';
import '../account/app_session.dart';
import '../backend/pending_endpoints.dart';
import '../network/api_client.dart';
import '../voice/voice_language.dart';

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

/// Chat client for the backend text assistant (`POST /chat`, an assumed route
/// listed in `PendingEndpoints`). The bearer token identifies the account; the
/// request carries only the messages and the language.
class RestSarvamChatClient implements SarvamChatClient {
  RestSarvamChatClient({ApiClient? client}) : _client = client;

  final ApiClient? _client;

  @override
  Future<SarvamChatResponse> complete({
    required List<SarvamChatMessage> messages,
    required String language,
  }) async {
    if (!AppSession.instance.isSignedIn) {
      throw const SarvamChatException('Sign in to chat with Saarthi.');
    }

    try {
      final response = await (_client ?? ApiClient.instance).post(
        PendingEndpoints.chat,
        body: {
          'language': VoiceLanguage.chatCode(language),
          'messages': messages.map((message) => message.toJson()).toList(),
        },
      );
      final data = response.data;
      if (data is! Map || data['reply'] is! String) {
        throw SarvamChatException(
          CentralizedTranslator.instance.localize(
            'Saarthi returned an unexpected response.',
          ),
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
      throw SarvamChatException(
        CentralizedTranslator.instance.localize(
          'Could not reach Saarthi. Check your connection and try again.',
        ),
      );
    }
  }
}
