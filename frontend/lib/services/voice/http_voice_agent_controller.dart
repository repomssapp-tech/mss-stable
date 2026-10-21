import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_profile.dart';
import '../account/app_session.dart';
import '../network/api_client.dart';
import 'assistant_session_controller.dart';
import 'cloud_voice_protocol.dart';
import 'voice_agent_controller.dart';
import 'voice_language.dart';

export 'cloud_voice_protocol.dart';

abstract interface class RecordedSpeechOutput {
  Future<void> play(Uint8List bytes);
  Future<void> stop();
  Future<void> dispose();
}

class _AudioOutput implements RecordedSpeechOutput {
  AudioPlayer? _player;
  Completer<void>? _finished;
  int _generation = 0;
  @override
  Future<void> play(Uint8List bytes) async {
    final ticket = _generation;
    final player = _player ??= AudioPlayer();
    final done = _finished = Completer<void>();
    final completion = player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      if (ticket != _generation) {
        await player.stop();
        return;
      }
      await done.future.timeout(const Duration(minutes: 3));
    } finally {
      await completion.cancel();
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    final done = _finished;
    _finished = null;
    if (done != null && !done.isCompleted) done.complete();
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
  }
}

/// Sequential recorded turns over the authenticated MSS API. No room, socket,
/// live microphone, or LiveKit credentials are involved.
class HttpVoiceAgentController extends ChangeNotifier
    implements VoiceAgentController {
  HttpVoiceAgentController({
    required this.session,
    ApiClient? client,
    RecordedSpeechOutput? output,
    String Function()? languageCode,
    bool Function()? available,
  }) : _client = client ?? ApiClient.instance,
       _output = output ?? _AudioOutput(),
       _languageCode = languageCode ?? (() => 'en'),
       _available = available ?? (() => AppSession.instance.isSignedIn);

  static HttpVoiceAgentController? tryCreate({
    required AssistantSessionController session,
    required UserProfile profile,
    String Function()? languageCode,
  }) => AppSession.instance.isSignedIn
      ? HttpVoiceAgentController(session: session, languageCode: languageCode)
      : null;

  @override
  final AssistantSessionController session;
  final ApiClient _client;
  final RecordedSpeechOutput _output;
  final String Function() _languageCode;
  final bool Function() _available;
  final _events = StreamController<VoiceAgentEvent>.broadcast();
  final List<Map<String, String>> _history = [];
  VoiceAgentState _state = const VoiceAgentState();
  bool _disposed = false;
  int _generation = 0;
  int _turn = 0;
  String? _selectedLanguage;
  String? _pending;
  @override
  VoiceAgentState get state => _state;
  @override
  Stream<VoiceAgentEvent> get events => _events.stream;
  void _set(VoiceAgentState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {}
  @override
  Future<void> connect() async {
    if (!_available()) throw StateError('Authentication required');
    _set(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.connected,
        usingCloud: true,
        isMuted: false,
        isListening: false,
        clearMessage: true,
      ),
    );
  }

  Future<void> setResponseLanguage(String language) async {
    _selectedLanguage = VoiceLanguage.code(language);
  }

  @override
  Future<void> sendText(String text) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 2000) {
      throw StateError('Invalid message');
    }
    if (_disposed || !_state.usingCloud || !_available()) {
      throw StateError('Disconnected');
    }
    await interrupt();
    _pending = value;
    final turn = ++_turn;
    _events.add(
      VoiceAgentEvent(
        VoiceAgentEventType.inputTranscriptDone,
        text: value,
        data: {'messageId': 'http-user-$turn'},
      ),
    );
    _set(
      _state.copyWith(
        inputTranscript: value,
        outputTranscript: '',
        isProcessing: true,
        clearMessage: true,
      ),
    );
    unawaited(_complete(value, turn, _generation));
  }

  Future<void> _complete(String text, int turn, int generation) async {
    final language = _selectedLanguage ?? VoiceLanguage.code(_languageCode());
    bool current() => !_disposed && generation == _generation;
    var answered = false;
    try {
      final response = await _client
          .post(
            '/chat',
            body: {
              'messages': [
                ..._history,
                {'role': 'user', 'content': text},
              ],
              'language': language,
            },
          )
          .timeout(const Duration(seconds: 65));
      if (!current()) return;
      final data = response.data;
      if (data is! Map ||
          data['reply'] is! String ||
          (data['reply'] as String).trim().isEmpty) {
        throw StateError('Invalid reply');
      }
      final reply = (data['reply'] as String).trim();
      _pending = null;
      answered = true;
      _history.addAll([
        {'role': 'user', 'content': text},
        {'role': 'assistant', 'content': reply},
      ]);
      while (_history.length > 8 ||
          _history.fold<int>(0, (sum, item) => sum + item['content']!.length) >
              8000) {
        _history.removeRange(0, 2);
      }
      final results = parseCloudSchemeResultsAttribute(
        jsonEncode({
          'schema': 'in-schemes-results-v1',
          'results': data['results'] ?? [],
        }),
      );
      _events.add(
        VoiceAgentEvent(
          VoiceAgentEventType.schemeResults,
          data: {'results': results},
        ),
      );
      _events.add(
        VoiceAgentEvent(
          VoiceAgentEventType.outputTranscriptDone,
          text: reply,
          data: {'messageId': 'http-assistant-$turn'},
        ),
      );
      _set(_state.copyWith(outputTranscript: reply, isProcessing: false));
      final speech = await _client
          .post('/voice/speech', body: {'text': reply, 'language': language})
          .timeout(const Duration(seconds: 35));
      if (!current() || _state.isMuted) return;
      final body = speech.data;
      if (body is! Map ||
          body['audio'] is! String ||
          (body['audio'] as String).length > 8000000) {
        throw StateError('Invalid audio');
      }
      final bytes = base64Decode(body['audio'] as String);
      _set(_state.copyWith(isSpeaking: true));
      _events.add(const VoiceAgentEvent(VoiceAgentEventType.speechStarted));
      await _output.play(bytes);
    } catch (_) {
      if (!current()) return;
      // Keep reviewed text pending for retry. An audio failure never replaces
      // a successful text reply or resends that conversation turn.
      _set(
        _state.copyWith(
          message: answered ? 'speech-unavailable' : 'reply-unavailable',
        ),
      );
    } finally {
      if (current()) {
        _set(_state.copyWith(isProcessing: false, isSpeaking: false));
        _events.add(const VoiceAgentEvent(VoiceAgentEventType.speechStopped));
      }
    }
  }

  @override
  Future<void> interrupt() async {
    _generation++;
    await _output.stop();
    _set(_state.copyWith(isProcessing: false, isSpeaking: false));
  }

  @override
  Future<void> setMuted(bool muted) async {
    if (muted) await interrupt();
    _set(_state.copyWith(isMuted: muted, isListening: false));
  }

  @override
  Future<void> retry() async {
    await interrupt();
    await connect();
    if (_pending != null) {
      _set(_state.copyWith(isProcessing: true, clearMessage: true));
      unawaited(_complete(_pending!, _turn, _generation));
    }
  }

  String? get pendingText => _pending;
  @override
  Future<void> close() async {
    await interrupt();
    _set(
      _state.copyWith(
        phase: VoiceAgentConnectionPhase.closed,
        usingCloud: false,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await close();
    _disposed = true;
    await _output.dispose();
    await _events.close();
    super.dispose();
  }
}
