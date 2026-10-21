import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/search/scheme_understanding_engine.dart';
import 'package:frontend/services/voice/assistant_session_controller.dart';
import 'package:frontend/services/voice/http_voice_agent_controller.dart';
import 'package:frontend/services/voice/realtime_speech_transport.dart';
import 'package:frontend/services/voice/saarthi_conversation_controller.dart';
import 'package:frontend/services/voice/voice_microphone.dart';

class _Microphone implements VoiceMicrophone {
  bool recording = false;
  int starts = 0;
  final chunks = StreamController<Uint8List>.broadcast();
  @override
  Future<Stream<Uint8List>> start() async {
    recording = true;
    starts++;
    return chunks.stream;
  }

  @override
  Future<void> stop() async {
    recording = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await chunks.close();
  }
}

class _Transport implements RealtimeSpeechTransport {
  final output = StreamController<LiveSpeechEvent>.broadcast();
  final connections = <(String, int)>[];
  Completer<void>? connecting;
  int finishes = 0;
  bool closed = true;
  @override
  Stream<LiveSpeechEvent> get events => output.stream;
  @override
  Future<void> connect({
    required String language,
    required int silenceMs,
  }) async {
    connections.add((language, silenceMs));
    if (connecting != null) await connecting!.future;
    closed = false;
  }

  @override
  void audio(Uint8List bytes) {}
  @override
  void finish() {
    finishes++;
  }

  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  Future<void> dispose() async {
    await close();
    await output.close();
  }

  void emit(String type, {String text = '', String? code}) =>
      output.add(LiveSpeechEvent(type, text: text, code: code));
}

class _Output implements RecordedSpeechOutput {
  Completer<void>? playing;
  int plays = 0;
  @override
  Future<void> play(Uint8List bytes) {
    plays++;
    playing = Completer<void>();
    return playing!.future;
  }

  @override
  Future<void> stop() async {
    if (playing?.isCompleted == false) playing!.complete();
  }

  @override
  Future<void> dispose() => stop();
}

class _Client extends ApiClient {
  _Client(this.microphone);
  final _Microphone microphone;
  final paths = <String>[];
  final chatBodies = <dynamic>[];
  Completer<Object?>? reply;
  @override
  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    expect(
      microphone.recording,
      isFalse,
      reason: 'Microphone must stop before inference and playback',
    );
    paths.add(path);
    if (path == '/chat') chatBodies.add(body);
    return ApiResponse(
      data: path == '/chat'
          ? (reply == null
                ? {'reply': 'A readable reply.', 'results': []}
                : await reply!.future)
          : {
              'audio': base64Encode([1, 2, 3]),
              'mime_type': 'audio/mpeg',
            },
      statusCode: 200,
      headers: const {},
    );
  }
}

class _Harness {
  _Harness({bool screenReader = false}) {
    client = _Client(microphone);
    session = AssistantSessionController(
      engine: const LocalSchemeUnderstandingEngine(),
      schemes: const [],
      profile: UserProfile(),
    );
    agent = HttpVoiceAgentController(
      session: session,
      client: client,
      output: audio,
      available: () => true,
    );
    conversation = SaarthiConversationController(
      agent: agent,
      transport: transport,
      microphone: microphone,
      language: 'ta',
      screenReader: screenReader,
      replyGuard: Duration.zero,
    );
  }
  final microphone = _Microphone();
  final transport = _Transport();
  final audio = _Output();
  late final _Client client;
  late final AssistantSessionController session;
  late final HttpVoiceAgentController agent;
  late final SaarthiConversationController conversation;
  Future<void> dispose() async {
    await conversation.dispose();
    await agent.dispose();
    session.dispose();
  }
}

void main() {
  test(
    'one start listens, endpoint final replies and resumes after completed audio',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.conversation.start();
      expect(h.microphone.recording, isTrue);
      h.transport.emit('transcript.partial', text: 'வணக்கம்');
      h.transport.emit('speech_end');
      await pumpEventQueue();
      expect(h.microphone.recording, isFalse);
      expect(h.conversation.phase, ConversationPhase.transcribing);
      h.transport.emit('transcript.final', text: 'வணக்கம் உதவி');
      await pumpEventQueue();
      expect(h.client.paths, ['/chat', '/voice/speech']);
      expect(h.conversation.phase, ConversationPhase.speaking);
      expect(h.microphone.recording, isFalse);
      h.audio.playing!.complete();
      await pumpEventQueue();
      expect(h.microphone.recording, isTrue);
      expect(h.microphone.starts, 2);
      expect(h.transport.connections, [('ta', 1200), ('ta', 1200)]);
    },
  );
  test(
    'pause while inference runs ignores late replies and never restarts input',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.client.reply = Completer<Object?>();
      await h.conversation.start();
      h.transport.emit('transcript.final', text: 'my request');
      await pumpEventQueue();
      await h.conversation.pause();
      h.client.reply!.complete({'reply': 'late reply', 'results': []});
      await pumpEventQueue();
      expect(h.microphone.recording, isFalse);
      expect(h.audio.plays, 0);
      expect(h.client.paths, ['/chat']);
      expect(h.conversation.phase, ConversationPhase.paused);
    },
  );
  test('pause during speech stops output and keeps microphone off', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.conversation.start();
    h.transport.emit('transcript.final', text: 'business loan');
    await pumpEventQueue();
    expect(h.audio.plays, 1);
    await h.conversation.pause();
    await pumpEventQueue();
    expect(h.audio.playing!.isCompleted, isTrue);
    expect(h.microphone.recording, isFalse);
    expect(h.microphone.starts, 1);
  });
  test(
    'screen reader uses text and explicit resume instead of recording its speech',
    () async {
      final h = _Harness(screenReader: true);
      addTearDown(h.dispose);
      await h.conversation.start();
      h.transport.emit('transcript.final', text: 'business loan');
      await pumpEventQueue();
      expect(h.client.paths, ['/chat']);
      expect(h.conversation.phase, ConversationPhase.paused);
      expect(h.microphone.recording, isFalse);
      expect(h.audio.plays, 0);
      await h.conversation.resume();
      expect(h.microphone.recording, isTrue);
    },
  );
  test(
    'failed final preserves partial only for correction and never submits it',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.conversation.start();
      h.transport.emit('transcript.partial', text: 'a partially heard request');
      h.transport.emit('error', code: 'VOICE_FINAL_TIMEOUT');
      await pumpEventQueue();
      expect(h.client.paths, isEmpty);
      expect(h.microphone.recording, isFalse);
      await h.conversation.correct();
      expect(h.conversation.editing, isTrue);
      expect(h.conversation.draft, 'a partially heard request');
      await h.conversation.configure(
        languageCode: 'hi',
        longPauses: true,
        aloud: false,
      );
      await h.conversation.resume();
      expect(h.transport.connections.last, ('hi', 1800));
    },
  );
  test(
    'review option pauses with a final transcript before any inference',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.conversation.configure(review: true);
      await h.conversation.start();
      h.transport.emit('transcript.final', text: 'My reviewed words');
      await pumpEventQueue();
      expect(h.conversation.editing, isTrue);
      expect(h.conversation.draft, 'My reviewed words');
      expect(h.client.paths, isEmpty);
      expect(h.microphone.recording, isFalse);
    },
  );
  test(
    'End while connecting invalidates the pending microphone start',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.transport.connecting = Completer<void>();
      final starting = h.conversation.start();
      await pumpEventQueue();
      await h.conversation.end();
      h.transport.connecting!.complete();
      await starting;
      await pumpEventQueue();
      expect(h.microphone.starts, 0);
      expect(h.conversation.phase, ConversationPhase.idle);
    },
  );
  test('manual finish stops capture and waits for a true final', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.conversation.start();
    await h.conversation.finishTurn();
    expect(h.transport.finishes, 1);
    expect(h.microphone.recording, isFalse);
    expect(h.client.paths, isEmpty);
    expect(h.conversation.phase, ConversationPhase.transcribing);
  });
  test(
    'repeat uses cached audio without another chat or speech provider call',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.conversation.start();
      h.transport.emit('transcript.final', text: 'repeat this reply');
      await pumpEventQueue();
      await h.conversation.pause();
      await pumpEventQueue();
      final repeating = h.conversation.repeat();
      await pumpEventQueue();
      expect(h.audio.plays, 2);
      expect(h.client.paths, ['/chat', '/voice/speech']);
      h.audio.playing!.complete();
      await repeating;
      expect(h.microphone.recording, isFalse);
    },
  );
  test(
    'correcting a reply removes the misheard exchange from model history',
    () async {
      final h = _Harness(screenReader: true);
      addTearDown(h.dispose);
      await h.conversation.send('wrong business');
      await h.conversation.correct();
      await h.conversation.send('bakery business');
      expect(h.client.chatBodies.last['messages'], [
        {'role': 'user', 'content': 'bakery business'},
      ]);
      expect(h.microphone.recording, isFalse);
    },
  );
  test(
    'enabling accessibility during listening stops capture and speech',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.conversation.start();
      await h.conversation.updateAccessibility(true);
      expect(h.microphone.recording, isFalse);
      expect(h.transport.closed, isTrue);
      expect(h.conversation.screenReader, isTrue);
      expect(h.conversation.readAloud, isFalse);
      expect(h.conversation.phase, ConversationPhase.paused);
      h.transport.emit('transcript.final', text: 'late words');
      await pumpEventQueue();
      expect(h.client.paths, isEmpty);
    },
  );
}
