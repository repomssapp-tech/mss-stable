import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:frontend/services/search/scheme_understanding_engine.dart';
import 'package:frontend/services/voice/assistant_session_controller.dart';
import 'package:frontend/services/voice/http_voice_agent_controller.dart';
import 'package:frontend/services/voice/recorded_transcription_service.dart';
import 'package:frontend/services/voice/voice_agent_controller.dart';

class _Client extends ApiClient {
  _Client(this.handler);
  final Future<Object?> Function(String, dynamic) handler;
  final List<(String, dynamic)> calls = [];
  @override
  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    expect(requiresAuth, isTrue);
    calls.add((path, body));
    return ApiResponse(
      data: await handler(path, body),
      statusCode: 200,
      headers: const {},
    );
  }
}

class _Audio implements RecordedSpeechOutput {
  final played = <Uint8List>[];
  Completer<void>? done;
  @override
  Future<void> play(Uint8List bytes) {
    played.add(bytes);
    done = Completer<void>();
    return done!.future;
  }

  @override
  Future<void> stop() async {
    if (done != null && !done!.isCompleted) done!.complete();
  }

  @override
  Future<void> dispose() => stop();
}

HttpVoiceAgentController _controller(_Client client, _Audio audio) =>
    HttpVoiceAgentController(
      client: client,
      output: audio,
      available: () => true,
      languageCode: () => 'ta',
      session: AssistantSessionController(
        engine: const LocalSchemeUnderstandingEngine(),
        schemes: const [],
        profile: UserProfile(),
      ),
    );

void main() {
  test(
    'HTTP session never opens microphone and sends the selected language',
    () async {
      final client = _Client(
        (path, body) async => path == '/chat'
            ? {
                'reply': 'வணக்கம்',
                'results': [
                  {'id': 'DEMO', 'name': 'Synthetic scheme'},
                ],
              }
            : {
                'audio': base64Encode([1, 2, 3]),
                'mime_type': 'audio/mpeg',
              },
      );
      final audio = _Audio(), agent = _controller(client, _Audio());
      await agent.dispose();
      final active = _controller(client, audio);
      final events = <VoiceAgentEvent>[];
      final subscription = active.events.listen(events.add);
      await active.connect();
      expect(client.calls, isEmpty);
      expect(active.state.isListening, isFalse);
      await active.setResponseLanguage('hi-IN');
      await active.sendText('Help me');
      await pumpEventQueue();
      expect(client.calls.map((entry) => entry.$1), ['/chat', '/voice/speech']);
      expect(client.calls.first.$2['language'], 'hi');
      expect(active.state.outputTranscript, 'வணக்கம்');
      expect(audio.played, hasLength(1));
      expect(active.state.isSpeaking, isTrue);
      expect(
        events.indexWhere(
          (event) => event.type == VoiceAgentEventType.schemeResults,
        ),
        lessThan(
          events.indexWhere(
            (event) => event.type == VoiceAgentEventType.outputTranscriptDone,
          ),
        ),
      );
      await active.interrupt();
      await pumpEventQueue();
      expect(active.state.isSpeaking, isFalse);
      expect(active.state.isListening, isFalse);
      await subscription.cancel();
      await active.dispose();
    },
  );
  test('interrupt ignores stale reply and speech completions', () async {
    final reply = Completer<Object?>();
    final client = _Client((_, _) => reply.future), audio = _Audio();
    final agent = _controller(client, audio);
    await agent.connect();
    await agent.sendText('old turn');
    expect(agent.state.isProcessing, isTrue);
    await agent.interrupt();
    reply.complete({'reply': 'stale answer', 'results': []});
    await pumpEventQueue();
    expect(agent.state.outputTranscript, isEmpty);
    expect(audio.played, isEmpty);
    expect(client.calls, hasLength(1));
    await agent.dispose();
  });
  test(
    'failed reply retains reviewed text and retry does not duplicate history',
    () async {
      var attempt = 0;
      final client = _Client((path, _) async {
        if (path == '/voice/speech') throw StateError('speech offline');
        if (++attempt == 1) throw StateError('offline');
        return {'reply': 'The text reply remains usable.', 'results': []};
      });
      final agent = _controller(client, _Audio());
      await agent.connect();
      await agent.sendText('My reviewed request');
      await pumpEventQueue();
      expect(agent.pendingText, 'My reviewed request');
      await agent.retry();
      await pumpEventQueue();
      expect(agent.pendingText, isNull);
      expect(agent.state.outputTranscript, 'The text reply remains usable.');
      expect(agent.state.usingCloud, isTrue);
      expect(agent.state.message, 'speech-unavailable');
      final retried = client.calls
          .where((entry) => entry.$1 == '/chat')
          .last
          .$2;
      expect(retried['messages'], hasLength(1));
      await agent.dispose();
    },
  );
  test(
    'closing during TTS prevents playback while preserving the reply',
    () async {
      final speech = Completer<Object?>();
      final client = _Client(
        (path, _) async => path == '/chat'
            ? {'reply': 'Readable reply', 'results': []}
            : speech.future,
      );
      final audio = _Audio(), agent = _controller(client, _Audio());
      await agent.dispose();
      final active = _controller(client, audio);
      await active.connect();
      await active.sendText('request');
      await pumpEventQueue();
      await active.close();
      speech.complete({'audio': 'AAAA'});
      await pumpEventQueue();
      expect(audio.played, isEmpty);
      expect(active.state.outputTranscript, 'Readable reply');
      await active.dispose();
    },
  );
  test(
    'transcription uses authenticated Node API and handles expired jobs',
    () async {
      final client = _Client((path, body) async {
        if (path == '/voice/transcriptions') return {'handle': 'owner-handle'};
        throw const ApiException(
          statusCode: 403,
          errorCode: 'INVALID_TRANSCRIPTION_HANDLE',
          message: 'expired',
        );
      });
      final service = RestRecordedTranscriptionService(client: client);
      expect(
        await service.submit(Uint8List.fromList([0, 1]), 'ta-IN'),
        'owner-handle',
      );
      expect(client.calls.first.$2, {'audio': 'AAE=', 'language': 'ta-IN'});
      expect(
        (await service.poll('owner-handle')).phase,
        TranscriptionPhase.failed,
      );
    },
  );
  test(
    'mismatched speech language is never played or retried through chat',
    () async {
      final client = _Client(
        (path, _) async => path == '/chat'
            ? {'reply': 'தமிழ் பதில்', 'language': 'ta', 'results': []}
            : {'audio': 'AAAA', 'language': 'hi'},
      );
      final audio = _Audio(), agent = _controller(client, _Audio());
      await agent.dispose();
      final active = _controller(client, audio);
      addTearDown(active.dispose);
      await active.connect();
      await active.sendText('hello');
      await active.turnCompleted;
      expect(audio.played, isEmpty);
      expect(active.state.outputTranscript, 'தமிழ் பதில்');
      expect(active.state.message, 'speech-unavailable');
      expect(client.calls.where((c) => c.$1 == '/chat'), hasLength(1));
    },
  );
}
