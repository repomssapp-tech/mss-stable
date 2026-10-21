import 'dart:convert';
import 'dart:typed_data';

import '../network/api_client.dart';
import '../network/api_exception.dart';

enum TranscriptionPhase { pending, completed, failed, empty }

class TranscriptionResult {
  const TranscriptionResult(this.phase, {this.transcript = '', this.language});
  final TranscriptionPhase phase;
  final String transcript;
  final String? language;
}

abstract interface class RecordedTranscriptionService {
  Future<String> submit(Uint8List audio, String language);
  Future<TranscriptionResult> poll(String handle);
}

class RestRecordedTranscriptionService implements RecordedTranscriptionService {
  RestRecordedTranscriptionService({ApiClient? client})
    : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  @override
  Future<String> submit(Uint8List audio, String language) async {
    final response = await _client
        .post(
          '/voice/transcriptions',
          body: {'audio': base64Encode(audio), 'language': language},
        )
        .timeout(const Duration(seconds: 90));
    final data = response.data;
    if (data is! Map || data['handle'] is! String) {
      throw StateError('Invalid transcription job');
    }
    return data['handle'] as String;
  }

  @override
  Future<TranscriptionResult> poll(String handle) async {
    late final ApiResponse<dynamic> response;
    try {
      response = await _client
          .post('/voice/transcriptions/status', body: {'handle': handle})
          .timeout(const Duration(seconds: 45));
    } on ApiException catch (error) {
      if (error.statusCode == 403) {
        return const TranscriptionResult(TranscriptionPhase.failed);
      }
      rethrow;
    }
    final data = response.data;
    if (data is! Map) throw StateError('Invalid transcription response');
    return switch (data['state']) {
      'pending' => const TranscriptionResult(TranscriptionPhase.pending),
      'failed' => const TranscriptionResult(TranscriptionPhase.failed),
      'empty' => const TranscriptionResult(TranscriptionPhase.empty),
      'completed' when data['transcript'] is String => TranscriptionResult(
        TranscriptionPhase.completed,
        transcript: data['transcript'] as String,
        language: data['language'] as String?,
      ),
      _ => throw StateError('Invalid transcription state'),
    };
  }
}
