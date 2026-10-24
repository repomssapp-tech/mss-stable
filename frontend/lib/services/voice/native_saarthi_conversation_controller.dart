import 'dart:async';
import 'package:flutter/foundation.dart';
import 'native_agent_transport.dart';
import 'pcm_speech_output.dart';
import 'saarthi_conversation_controller.dart';

/// A persistent Sarvam conversation, with local capture stopped for playback.
/// Reviewed turns keep the existing editable transcript workflow.
class NativeSaarthiConversationController
    extends SaarthiConversationController {
  NativeSaarthiConversationController({
    required super.agent,
    required super.transport,
    required super.microphone,
    required super.language,
    super.screenReader,
    super.persistLanguage,
    super.replyGuard,
    NativeAgentTransport? native,
    PcmSpeechOutput? output,
  }) : native = native ?? MssNativeAgentTransport(),
       output = output ?? DevicePcmSpeechOutput() {
    _events = this.native.events.listen(_event);
  }
  final NativeAgentTransport native;
  final PcmSpeechOutput output;
  StreamSubscription<Object>? _events;
  StreamSubscription<Uint8List>? _samples;
  int _generation = 0;
  bool _disposed = false;
  bool _nativeSession = false;
  bool _greeted = false;
  Future<void> _work = Future.value();
  Timer? _limit;
  List<Uint8List> _replyAudio = [];
  List<Uint8List> _lastAudio = [];
  int _replyBytes = 0;
  int _rate = 16000;
  int _lastRate = 16000;
  String? _lastLanguage;
  bool get _useNative =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !reviewBeforeSend &&
      !longerPauses;
  @override
  bool get canRepeat =>
      (_lastAudio.isNotEmpty && _lastLanguage == language) || super.canRepeat;

  bool _current(int version) => !_disposed && active && version == _generation;
  void _phase(ConversationPhase value) {
    if (_disposed) return;
    phase = value;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    if (!_useNative) return super.resume();
    if (!active || _disposed) return;
    await pause();
    if (!active || _disposed) return;
    final version = ++_generation;
    _nativeSession = true;
    editing = false;
    error = null;
    draft = '';
    _phase(ConversationPhase.connecting);
    _limit = Timer(
      const Duration(seconds: 40),
      () => unawaited(_fail('VOICE_PROVIDER_UNAVAILABLE')),
    );
    try {
      await agent.connect();
      await agent.setResponseLanguage(language);
      await native.connect(
        language,
        agent.conversationHistory,
        skipGreeting: _greeted,
      );
      if (!_current(version)) return;
      // The first greeting is played before capture. Resumes discard the new
      // vendor greeting and reopen capture after its completion event.
    } catch (failure) {
      if (_current(version)) {
        await _fail(
          failure.toString().contains('UNAUTHORIZED')
              ? 'UNAUTHORIZED'
              : 'VOICE_UNAVAILABLE',
        );
      }
    }
  }

  void _event(Object raw) {
    if (!_nativeSession || _disposed || !active) return;
    final version = _generation;
    _work = _work
        .then((_) async {
          if (!_current(version) || !_nativeSession) return;
          if (raw is Uint8List) {
            _replyBytes += raw.length;
            if (_replyBytes > 1920000) {
              throw StateError('VOICE_CONNECTION_SLOW');
            }
            _replyAudio.add(raw);
            if (readAloud) output.add(raw);
            return;
          }
          if (raw is! Map) return;
          switch (raw['type']) {
            case 'listen':
              _greeted = true;
              await _listen(version);
            case 'transcript.partial':
              draft = raw['text'] as String;
              notifyListeners();
            case 'transcript.user':
              _limit?.cancel();
              final text = raw['text'] as String;
              await _stopMic();
              if (!_current(version)) return;
              draft = text;
              lastRequest = text;
              agent.acceptNativeTranscript(text, user: true);
              _phase(ConversationPhase.thinking);
              _limit = Timer(
                const Duration(seconds: 35),
                () => unawaited(_fail('VOICE_PROVIDER_UNAVAILABLE')),
              );
            case 'transcript.agent':
              agent.acceptNativeTranscript(raw['text'] as String, user: false);
            case 'results':
              agent.acceptNativeResults(raw['results']);
            case 'output.start':
              _limit?.cancel();
              await _stopMic();
              if (!_current(version)) return;
              _rate = raw['sample_rate'] as int? ?? 16000;
              _replyAudio = [];
              _replyBytes = 0;
              if (readAloud) await output.start(_rate);
              if (_current(version)) {
                _phase(
                  readAloud
                      ? ConversationPhase.speaking
                      : ConversationPhase.thinking,
                );
              }
            case 'output.end':
              _greeted = true;
              if (readAloud) await output.finish();
              if (!_current(version)) return;
              _lastAudio = _replyAudio;
              _lastRate = _rate;
              _lastLanguage = language;
              if (screenReader || !readAloud || !handsFree) {
                await pause();
                return;
              }
              await Future<void>.delayed(replyGuard);
              if (_current(version)) await _listen(version);
            case 'output.interrupt':
              await output.stop();
            case 'error':
              await _fail(raw['code'] as String? ?? 'VOICE_UNAVAILABLE');
            case 'ended':
              await pause();
          }
        })
        .catchError((Object failure) async {
          if (_current(version)) {
            await _fail(
              failure is StateError && failure.message == 'MIC_PERMISSION'
                  ? 'MIC_PERMISSION'
                  : 'speech-unavailable',
            );
          }
        });
  }

  Future<void> _listen(int version) async {
    _limit?.cancel();
    if (!_current(version)) return;
    final stream = await microphone.start();
    if (!_current(version)) {
      await microphone.stop();
      return;
    }
    native.input(true);
    _samples = stream.listen((bytes) {
      if (_current(version) && phase == ConversationPhase.listening) {
        native.audio(bytes);
      }
    }, onError: (Object _) => unawaited(_fail('MIC_UNAVAILABLE')));
    draft = '';
    _phase(ConversationPhase.listening);
    _limit = Timer(const Duration(seconds: 60), () => unawaited(finishTurn()));
  }

  Future<void> _stopMic() async {
    native.input(false);
    await microphone.stop();
    final samples = _samples;
    _samples = null;
    if (samples != null) unawaited(samples.cancel());
  }

  @override
  Future<void> finishTurn() async {
    if (!_nativeSession) return super.finishTurn();
    if (phase != ConversationPhase.listening) return;
    _limit?.cancel();
    _phase(ConversationPhase.transcribing);
    await _stopMic();
    _limit = Timer(
      const Duration(seconds: 12),
      () => unawaited(_fail('NO_SPEECH')),
    );
  }

  Future<void> _closeNative() async {
    ++_generation;
    _nativeSession = false;
    _limit?.cancel();
    await native.close();
    await microphone.stop();
    final samples = _samples;
    _samples = null;
    if (samples != null) unawaited(samples.cancel());
    await output.stop();
    _work = Future.value();
  }

  @override
  Future<void> pause() async {
    await _closeNative();
    await super.pause();
  }

  @override
  Future<void> send(String text) async {
    await _closeNative();
    await super.send(text);
  }

  @override
  Future<void> repeat() async {
    if (_lastAudio.isEmpty || _lastLanguage != language) return super.repeat();
    await pause();
    final version = _generation;
    error = null;
    _phase(ConversationPhase.speaking);
    try {
      await output.start(_lastRate);
      for (final bytes in _lastAudio) {
        if (!_current(version)) return;
        output.add(bytes);
      }
      await output.finish();
      if (_current(version)) _phase(ConversationPhase.paused);
    } catch (_) {
      if (_current(version)) await _fail('speech-unavailable');
    }
  }

  Future<void> _fail(String code) async {
    await pause();
    error = code;
    _phase(ConversationPhase.error);
  }

  @override
  Future<void> end() async {
    await _closeNative();
    _greeted = false;
    await super.end();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await end();
    await _events?.cancel();
    await native.dispose();
    await output.dispose();
    await super.dispose();
    _replyAudio.clear();
    _lastAudio.clear();
    _disposed = true;
  }
}
