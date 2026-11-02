import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../network/api_exception.dart';

import 'http_voice_agent_controller.dart';
import 'realtime_speech_transport.dart';
import 'voice_microphone.dart';
import 'voice_language.dart';

enum ConversationPhase {
  idle,
  connecting,
  listening,
  transcribing,
  thinking,
  speaking,
  paused,
  error,
}

/// Half-duplex conversation: input is completely stopped before inference or
/// audio output. Every async operation is invalidated by pause, edit or End.
class SaarthiConversationController extends ChangeNotifier {
  SaarthiConversationController({
    required this.agent,
    required this.transport,
    required this.microphone,
    required this.language,
    this.screenReader = false,
    this.persistLanguage,
    this.replyGuard = const Duration(milliseconds: 900),
  }) {
    _events = transport.events.listen(_onSpeech);
    agent.addListener(_onAgent);
    agent.speakReplies = !screenReader;
  }
  final HttpVoiceAgentController agent;
  final RealtimeSpeechTransport transport;
  final VoiceMicrophone microphone;
  final Duration replyGuard;
  final Future<void> Function(String)? persistLanguage;
  bool screenReader;
  String language;
  bool longerPauses = false;
  bool? _readAloudPreference;
  bool get canRepeat => agent.canReplay;
  bool get readAloud => agent.speakReplies;
  ConversationPhase phase = ConversationPhase.idle;
  String draft = '';
  String lastRequest = '';
  String? error;
  bool active = false;
  bool editing = false;
  bool reviewBeforeSend = false;

  /// Keep listening after each spoken reply. Off: wait (paused) for the user
  /// to tap to speak again.
  bool handsFree = true;
  int _generation = 0;
  bool _disposed = false;
  bool _finishing = false;
  String? _replacedRequest;
  int _captured = 0;
  Timer? _turnLimit;
  Timer? _finalLimit;
  Timer? _partialUpdate;
  StreamSubscription<LiveSpeechEvent>? _events;
  StreamSubscription<Uint8List>? _audio;

  /// How loud the microphone is right now, 0 to 1, for the listening waves.
  final ValueNotifier<double> inputLevel = ValueNotifier<double>(0);

  /// Measures a chunk of 16-bit microphone audio into [inputLevel].
  @protected
  void reportInput(Uint8List bytes) {
    if (bytes.length < 2) return;
    final samples = bytes.buffer.asByteData(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i + 1 < bytes.length; i += 8) {
      final sample = samples.getInt16(i, Endian.little) / 32768;
      sum += sample * sample;
      count++;
    }
    final rms = math.sqrt(sum / count);
    // Square root, because speech is far quieter than full scale.
    inputLevel.value = rms < 0.005 ? 0 : (math.sqrt(rms) * 2).clamp(0, 1);
  }

  void _update(ConversationPhase value) {
    if (_disposed) return;
    phase = value;
    notifyListeners();
  }

  void _onAgent() {
    if (!active ||
        _disposed ||
        editing ||
        phase == ConversationPhase.paused ||
        phase == ConversationPhase.error) {
      return;
    }
    if (agent.state.isSpeaking) {
      _update(ConversationPhase.speaking);
    } else if (agent.state.isProcessing) {
      _update(ConversationPhase.thinking);
    }
  }

  Future<void> start() async {
    if (_disposed) return;
    active = true;
    await resume();
  }

  Future<void> resume() async {
    if (!active || _disposed) return;
    final generation = ++_generation;
    _update(ConversationPhase.connecting);
    await _stopInput();
    if (!_current(generation)) return;
    await agent.interrupt();
    if (!_current(generation)) return;
    editing = false;
    error = null;
    draft = '';
    _finishing = false;
    _captured = 0;
    _update(ConversationPhase.connecting);
    try {
      await agent.connect();
      await agent.setResponseLanguage(language);
      await transport.connect(
        language: language,
        silenceMs: longerPauses ? 1800 : 1200,
      );
      if (!_current(generation)) return;
      final stream = await microphone.start();
      if (!_current(generation)) {
        await microphone.stop();
        return;
      }
      _audio = stream.listen((bytes) {
        if (!_current(generation) || phase != ConversationPhase.listening) {
          return;
        }
        _captured += bytes.length;
        if (_captured <= 960000) {
          reportInput(bytes);
          transport.audio(bytes);
        } else {
          unawaited(finishTurn());
        }
      }, onError: (Object _) => unawaited(_fail('MIC_UNAVAILABLE')));
      _update(ConversationPhase.listening);
      _turnLimit = Timer(
        const Duration(seconds: 30),
        () => unawaited(finishTurn()),
      );
    } catch (error) {
      if (_current(generation)) {
        await _fail(_failureCode(error));
      }
    }
  }

  bool _current(int generation) =>
      !_disposed && active && generation == _generation;

  String _failureCode(Object error) {
    if (error is ApiException && error.statusCode == 401) return 'UNAUTHORIZED';
    final message = error is StateError ? error.message : '';
    if (message.contains('Authentication') || message == 'UNAUTHORIZED') {
      return 'UNAUTHORIZED';
    }
    if (message == 'MIC_PERMISSION') return message;
    if (RegExp(r'^(VOICE_|AUTH_|SILENCE_)[A-Z_]+$').hasMatch(message)) {
      return message;
    }
    return 'VOICE_UNAVAILABLE';
  }

  void _onSpeech(LiveSpeechEvent event) {
    if (!active ||
        _disposed ||
        editing ||
        ![
          ConversationPhase.listening,
          ConversationPhase.transcribing,
          ConversationPhase.connecting,
        ].contains(phase)) {
      return;
    }
    switch (event.type) {
      case 'transcript.partial':
        draft = event.text;
        // Cap live-text rebuilds; PCM frames never rebuild the UI.
        _partialUpdate ??= Timer(const Duration(milliseconds: 120), () {
          _partialUpdate = null;
          if (!_disposed && active) notifyListeners();
        });
      case 'speech_end':
        unawaited(_waitForFinal());
      case 'transcript.final':
        final text = event.text.trim();
        // Requests are sent without a review step, so a result with no words
        // ("...") counts as not having heard anything.
        if (!text.contains(RegExp(r'[\p{L}\p{N}]', unicode: true))) {
          unawaited(_fail('NO_SPEECH'));
          return;
        }
        _finalLimit?.cancel();
        draft = text;
        if (reviewBeforeSend) {
          unawaited(correct());
        } else {
          unawaited(send(text));
        }
      case 'error':
        unawaited(_fail(event.code ?? 'VOICE_UNAVAILABLE'));
    }
  }

  Future<void> _waitForFinal() async {
    if (phase != ConversationPhase.listening) return;
    final generation = _generation;
    _update(ConversationPhase.transcribing);
    _turnLimit?.cancel();
    try {
      await microphone.stop();
    } catch (_) {
      await _fail('MIC_UNAVAILABLE');
      return;
    }
    if (!_current(generation) || phase != ConversationPhase.transcribing) {
      return;
    }
    _finalLimit = Timer(
      const Duration(seconds: 10),
      () => unawaited(_fail('FINAL_TIMEOUT')),
    );
  }

  Future<void> finishTurn() async {
    if (_finishing || phase != ConversationPhase.listening) return;
    _finishing = true;
    await _waitForFinal();
    if (phase == ConversationPhase.transcribing) {
      try {
        transport.finish();
      } catch (_) {
        await _fail('VOICE_CONNECTION_LOST');
      }
    }
  }

  Future<bool> _stopInput() async {
    inputLevel.value = 0;
    _turnLimit?.cancel();
    _finalLimit?.cancel();
    _partialUpdate?.cancel();
    _partialUpdate = null;
    final audio = _audio;
    _audio = null;
    // Stop capture before cancelling its stream; native streams can wait for
    // recorder shutdown when cancellation is awaited first.
    var stopped = true;
    try {
      await microphone.stop();
    } catch (_) {
      stopped = false;
    }
    if (audio != null) unawaited(audio.cancel().catchError((Object _) {}));
    try {
      await transport.close();
    } catch (_) {
      stopped = false;
    }
    return stopped;
  }

  Future<void> send(String text) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 2000 || _disposed) return;
    active = true;
    final generation = ++_generation;
    editing = false;
    error = null;
    draft = value;
    lastRequest = value;
    _update(ConversationPhase.thinking);
    final stopped = await _stopInput();
    if (!_current(generation)) return;
    if (!stopped) {
      await _fail('MIC_UNAVAILABLE');
      return;
    }
    try {
      await agent.connect();
      await agent.setResponseLanguage(language);
      final replaced = _replacedRequest;
      _replacedRequest = null;
      if (replaced != null) agent.discardLastExchange(replaced);
      await agent.sendText(value);
      await agent.turnCompleted;
      if (!_current(generation)) return;
      if (agent.state.message != null) {
        await _fail(agent.state.message!);
        return;
      }
      // A screen reader owns reading the reply. Resume is explicit so its
      // speech cannot be misinterpreted as the user's next request.
      if (screenReader || !readAloud || !handsFree) {
        _update(ConversationPhase.paused);
        return;
      }
      await Future<void>.delayed(replyGuard);
      if (_current(generation)) await resume();
    } catch (error) {
      if (_current(generation)) await _fail(_failureCode(error));
    }
  }

  Future<void> pause() async {
    ++_generation;
    _update(ConversationPhase.paused);
    await _stopInput();
    await agent.interrupt();
  }

  /// The user corrected the reviewed transcript before sending it.
  void updateDraft(String text) {
    if (_disposed) return;
    draft = text;
    notifyListeners();
  }

  Future<void> correct({bool blank = false}) async {
    final previous = draft.isNotEmpty ? draft : lastRequest;
    await pause();
    _replacedRequest = !blank && previous == lastRequest && previous.isNotEmpty
        ? previous
        : null;
    editing = true;
    draft = blank ? '' : previous;
    notifyListeners();
  }

  Future<void> updateAccessibility(bool enabled) async {
    if (enabled == screenReader) return;
    await pause();
    screenReader = enabled;
    agent.speakReplies = _readAloudPreference ?? !enabled;
    notifyListeners();
  }

  Future<void> configure({
    String? languageCode,
    bool? longPauses,
    bool? aloud,
    bool? review,
    bool? continueListening,
  }) async {
    await pause();
    if (languageCode != null) {
      language = VoiceLanguage.code(languageCode);
      await agent.setResponseLanguage(language);
      try {
        await persistLanguage?.call(language);
      } catch (_) {
        // Keep the explicit selection for this conversation if storage fails.
      }
    }
    if (longPauses != null) longerPauses = longPauses;
    if (aloud != null) {
      _readAloudPreference = aloud;
      agent.speakReplies = aloud;
    }
    if (review != null) reviewBeforeSend = review;
    if (continueListening != null) handsFree = continueListening;
    notifyListeners();
  }

  Future<void> repeat() async {
    if (!canRepeat) return;
    await pause();
    error = null;
    final generation = _generation;
    _update(ConversationPhase.thinking);
    await agent.replayLastReply();
    if (_current(generation)) {
      if (agent.state.message != null) {
        await _fail(agent.state.message!);
      } else {
        _update(ConversationPhase.paused);
      }
    }
  }

  /// Speaks [reply] (any earlier reply, saved ones too) again.
  Future<void> hear(String reply) async {
    if (_disposed || reply.trim().isEmpty) return;
    active = true;
    await pause();
    error = null;
    final generation = _generation;
    _update(ConversationPhase.thinking);
    try {
      await agent.connect();
      await agent.setResponseLanguage(language);
      await agent.replay(reply);
    } catch (error) {
      if (_current(generation)) await _fail(_failureCode(error));
      return;
    }
    if (_current(generation)) {
      if (agent.state.message != null) {
        await _fail(agent.state.message!);
      } else {
        _update(ConversationPhase.paused);
      }
    }
  }

  Future<void> _fail(String code) async {
    ++_generation;
    error = code;
    _update(ConversationPhase.error);
    await _stopInput();
    await agent.interrupt();
  }

  Future<void> end() async {
    active = false;
    ++_generation;
    _update(ConversationPhase.idle);
    await _stopInput();
    await agent.close();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await end();
    _disposed = true;
    agent.removeListener(_onAgent);
    await _events?.cancel();
    await transport.dispose();
    await microphone.dispose();
    inputLevel.dispose();
    super.dispose();
  }
}
