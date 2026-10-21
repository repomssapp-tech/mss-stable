import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/search/scheme_understanding_engine.dart';
import 'package:frontend/services/voice/assistant_session_controller.dart';
import 'package:frontend/services/voice/http_voice_agent_controller.dart';
import 'package:frontend/services/voice/native_agent_transport.dart';
import 'package:frontend/services/voice/native_saarthi_conversation_controller.dart';
import 'package:frontend/services/voice/pcm_speech_output.dart';
import 'package:frontend/services/voice/realtime_speech_transport.dart';
import 'package:frontend/services/voice/saarthi_conversation_controller.dart';
import 'package:frontend/services/voice/voice_microphone.dart';

class Mic implements VoiceMicrophone {
  bool recording = false;
  final samples = StreamController<Uint8List>.broadcast();
  @override
  Future<Stream<Uint8List>> start() async {
    recording = true;
    return samples.stream;
  }

  @override
  Future<void> stop() async {
    recording = false;
  }

  @override
  Future<void> dispose() async {
    await samples.close();
  }
}

class Native implements NativeAgentTransport {
  final output = StreamController<Object>.broadcast();
  final connections = <(String, bool)>[];
  bool capturing = false, closed = true;
  int audioBytes = 0;
  @override
  Stream<Object> get events => output.stream;
  @override
  Future<void> connect(
    String language,
    List<Map<String, String>> history, {
    required bool skipGreeting,
  }) async {
    connections.add((language, skipGreeting));
    closed = false;
  }

  @override
  void input(bool enabled) {
    capturing = enabled;
  }

  @override
  void audio(Uint8List bytes) {
    audioBytes += bytes.length;
  }

  @override
  Future<void> close() async {
    closed = true;
    capturing = false;
  }

  @override
  Future<void> dispose() => output.close();
  void event(String type, {String? text}) =>
      output.add({'type': type, 'text': text});
}

class Output implements PcmSpeechOutput {
  Output(this.mic);
  final Mic mic;
  int bytes = 0, starts = 0;
  Completer<void>? draining;
  @override
  Future<void> start(int rate) async {
    expect(mic.recording, false);
    starts++;
  }

  @override
  void add(Uint8List data) {
    expect(mic.recording, false);
    bytes += data.length;
  }

  @override
  Future<void> finish() async {
    await draining?.future;
  }

  @override
  Future<void> stop() async {
    if (draining?.isCompleted == false) draining!.complete();
  }

  @override
  Future<void> dispose() async {}
}

class Legacy implements RealtimeSpeechTransport {
  final output = StreamController<LiveSpeechEvent>.broadcast();
  @override
  Stream<LiveSpeechEvent> get events => output.stream;
  @override
  Future<void> connect({
    required String language,
    required int silenceMs,
  }) async {}
  @override
  void audio(Uint8List bytes) {}
  @override
  void finish() {}
  @override
  Future<void> close() async {}
  @override
  Future<void> dispose() => output.close();
}

class RecordedOutput implements RecordedSpeechOutput {
  @override
  Future<void> play(Uint8List bytes) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class Harness {
  Harness({bool reader = false}) {
    session = AssistantSessionController(
      engine: const LocalSchemeUnderstandingEngine(),
      schemes: const [],
      profile: UserProfile(),
    );
    agent = HttpVoiceAgentController(
      session: session,
      output: RecordedOutput(),
      available: () => true,
      languageCode: () => 'ta',
    );
    output = Output(mic);
    controller = NativeSaarthiConversationController(
      agent: agent,
      transport: Legacy(),
      microphone: mic,
      language: 'ta',
      screenReader: reader,
      native: native,
      output: output,
      replyGuard: Duration.zero,
    );
  }
  final mic = Mic();
  final native = Native();
  late final Output output;
  late final AssistantSessionController session;
  late final HttpVoiceAgentController agent;
  late final NativeSaarthiConversationController controller;
  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 20));
  Future<void> greeting() async {
    native.event('output.start');
    native.output.add(Uint8List.fromList([1, 0, 2, 0]));
    native.event('output.end');
    await flush();
  }

  Future<void> dispose() async {
    await controller.dispose();
    await agent.dispose();
    session.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native greeting and real playback drain precede capture, then conversation retains context',
    () async {
      final h = Harness();
      try {
        await h.controller.start();
        expect(h.mic.recording, false);
        h.output.draining = Completer<void>();
        h.native.event('output.start');
        h.native.output.add(Uint8List.fromList([1, 0]));
        h.native.event('output.end');
        await h.flush();
        expect(h.controller.phase, ConversationPhase.speaking);
        expect(h.mic.recording, false);
        h.output.draining!.complete();
        await h.flush();
        expect(h.mic.recording, true);
        h.mic.samples.add(Uint8List.fromList([2, 0]));
        await h.flush();
        expect(h.native.audioBytes, 2);
        h.native.event('transcript.partial', text: 'தையல் கடை தொடங்கணும்');
        await h.flush();
        expect(
          h.mic.recording,
          true,
          reason: 'A transcript piece must not cut off speech',
        );
        expect(h.controller.draft, 'தையல் கடை தொடங்கணும்');
        h.native.event('transcript.user', text: 'தையல் கடை தொடங்கணும்');
        await h.flush();
        expect(h.mic.recording, false);
        h.native.event(
          'transcript.agent',
          text: 'நல்லது! எந்த ஊர்ல தொடங்கப் போறீங்க?',
        );
        await h.greeting();
        expect(
          h.agent.conversationHistory.last['content'],
          'நல்லது! எந்த ஊர்ல தொடங்கப் போறீங்க?',
        );
        expect(h.native.connections.length, 1);
        expect(h.output.starts, 2);
        expect(h.mic.recording, true);
      } finally {
        await h.dispose();
      }
    },
  );
  test(
    'Pause invalidates queued playback and late transcripts, resume skips duplicate greeting',
    () async {
      final h = Harness();
      try {
        await h.controller.start();
        await h.greeting();
        await h.controller.pause();
        expect(h.native.closed, true);
        expect(h.mic.recording, false);
        h.native.event('transcript.agent', text: 'தாமதமான பதில்');
        await h.flush();
        expect(h.agent.conversationHistory, isEmpty);
        await h.controller.resume();
        expect(h.native.connections.last, ('ta', true));
        h.native.event('listen');
        await h.flush();
        expect(h.mic.recording, true);
        await h.controller.end();
        expect(h.mic.recording, false);
        expect(h.native.closed, true);
      } finally {
        await h.dispose();
      }
    },
  );
  test(
    'screen reader owns reply reading and requires explicit Resume before capture',
    () async {
      final h = Harness(reader: true);
      try {
        await h.controller.start();
        await h.greeting();
        expect(h.output.starts, 0);
        expect(h.controller.phase, ConversationPhase.paused);
        expect(h.native.closed, true);
        await h.controller.resume();
        h.native.event('listen');
        await h.flush();
        expect(h.mic.recording, true);
        h.native.event('transcript.user', text: 'உதவி வேணும்');
        await h.flush();
        await h.greeting();
        expect(h.mic.recording, false);
        expect(h.controller.phase, ConversationPhase.paused);
      } finally {
        await h.dispose();
      }
    },
  );
  test(
    'replay uses cached native PCM and language changes invalidate it',
    () async {
      final h = Harness();
      try {
        await h.controller.start();
        await h.greeting();
        expect(h.controller.canRepeat, true);
        await h.controller.repeat();
        expect(h.output.starts, 2);
        expect(h.native.closed, true);
        expect(h.mic.recording, false);
        await h.controller.configure(languageCode: 'hi');
        expect(h.controller.canRepeat, false);
      } finally {
        await h.dispose();
      }
    },
  );
}
