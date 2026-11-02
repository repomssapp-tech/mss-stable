import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/user_profile.dart';
import '../account/app_session.dart';
import '../network/api_client.dart';
import 'assistant_session_controller.dart';
import 'cloud_voice_protocol.dart';
import 'voice_agent_controller.dart';
import 'voice_language.dart';
import 'recorded_speech_output.dart';

export 'recorded_speech_output.dart';

export 'cloud_voice_protocol.dart';

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
       _output = output ?? DeviceSpeechOutput(),
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
  bool speakReplies = true;
  Future<void> _turnCompleted = Future.value();
  Future<void> get turnCompleted => _turnCompleted;
  Uint8List? _lastAudio;
  String? _lastReply;
  String? _lastReplyLanguage;
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
    final code = VoiceLanguage.code(language);
    if (_lastReplyLanguage != null && _lastReplyLanguage != code) {
      _lastAudio = null;
      _lastReply = null;
      _lastReplyLanguage = null;
    }
    _selectedLanguage = code;
  }

  List<Map<String, String>> get conversationHistory =>
      _history.map((item) => Map<String, String>.from(item)).toList();

  /// Replaces the context sent with the next turn: empty for a new chat, or the
  /// saved turns of a chat being continued (trimmed like a live conversation).
  void restoreHistory(List<Map<String, String>> turns) {
    _history
      ..clear()
      ..addAll(turns);
    while (_history.length > 8 ||
        _history.fold<int>(0, (sum, item) => sum + item['content']!.length) >
            8000) {
      _history.removeAt(0);
    }
    _pending = null;
    _lastAudio = null;
    _lastReply = null;
    _lastReplyLanguage = null;
  }

  /// Native calls share the same accessible transcript and correction history.
  void acceptNativeTranscript(String text, {required bool user}) {
    if (_disposed || text.trim().isEmpty) return;
    _history.add({'role': user ? 'user' : 'assistant', 'content': text});
    while (_history.length > 8 ||
        _history.fold<int>(0, (sum, item) => sum + item['content']!.length) >
            7000) {
      _history.removeAt(0);
    }
    if (!user) {
      _lastReply = text;
      _lastReplyLanguage =
          _selectedLanguage ?? VoiceLanguage.code(_languageCode());
      _lastAudio = null;
    }
    _events.add(
      VoiceAgentEvent(
        user
            ? VoiceAgentEventType.inputTranscriptDone
            : VoiceAgentEventType.outputTranscriptDone,
        text: text,
        data: {'messageId': 'native-${++_turn}'},
      ),
    );
  }

  void acceptNativeResults(Object? results) {
    if (_disposed) return;
    _events.add(
      VoiceAgentEvent(
        VoiceAgentEventType.schemeResults,
        data: {
          'results': parseCloudSchemeResultsAttribute(
            jsonEncode({
              'schema': 'in-schemes-results-v1',
              'results': results ?? [],
            }),
          ),
        },
      ),
    );
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
    _turnCompleted = _complete(value, turn, _generation);
    unawaited(_turnCompleted);
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
          (data['reply'] as String).trim().isEmpty ||
          (data['language'] != null && data['language'] != language)) {
        throw StateError('Invalid reply');
      }
      final reply = (data['reply'] as String).trim();
      if (data['engine'] == 'sarvam_voice_agent' &&
          !VoiceLanguage.hasMainScript(reply, language)) {
        throw StateError('Invalid reply language');
      }
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
      _lastAudio = null;
      _lastReply = reply;
      _lastReplyLanguage = language;
      _set(
        _state.copyWith(outputTranscript: reply, isProcessing: speakReplies),
      );
      if (speakReplies) await _speakReply(reply, language, generation);
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

  Future<void> _speakReply(
    String reply,
    String language,
    int generation,
  ) async {
    var bytes = _lastAudio;
    if (bytes == null) {
      final speech = await _client
          .post('/voice/speech', body: {'text': reply, 'language': language})
          .timeout(const Duration(seconds: 35));
      if (_disposed || generation != _generation || _state.isMuted) return;
      final body = speech.data;
      if (body is! Map ||
          body['audio'] is! String ||
          (body['audio'] as String).length > 8000000 ||
          (body['language'] != null && body['language'] != language)) {
        throw StateError('Invalid audio');
      }
      bytes = base64Decode(body['audio'] as String);
      _lastAudio = bytes;
    }
    if (_disposed || generation != _generation || _state.isMuted) return;
    _set(_state.copyWith(isSpeaking: true, isProcessing: false));
    _events.add(const VoiceAgentEvent(VoiceAgentEventType.speechStarted));
    await _output.play(bytes);
  }

  bool get canReplay =>
      _lastReply != null &&
      _lastReplyLanguage ==
          (_selectedLanguage ?? VoiceLanguage.code(_languageCode()));

  Future<void> replayLastReply() async {
    if (!canReplay) return;
    final reply = _lastReply, language = _lastReplyLanguage;
    if (reply == null || language == null) return;
    await interrupt();
    final generation = _generation;
    _set(
      _state.copyWith(isProcessing: true, isMuted: false, clearMessage: true),
    );
    try {
      await _speakReply(reply, language, generation);
    } catch (_) {
      if (generation == _generation) {
        _set(_state.copyWith(message: 'speech-unavailable'));
      }
    } finally {
      if (generation == _generation) {
        _set(_state.copyWith(isProcessing: false, isSpeaking: false));
      }
    }
  }

  /// Speaks [reply] again, which may be any earlier reply of the conversation.
  Future<void> replay(String reply) async {
    if (reply != _lastReply) {
      _lastAudio = null;
      _lastReply = reply;
    }
    _lastReplyLanguage =
        _selectedLanguage ?? VoiceLanguage.code(_languageCode());
    await replayLastReply();
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
      _turnCompleted = _complete(_pending!, _turn, _generation);
      unawaited(_turnCompleted);
    }
  }

  String? get pendingText => _pending;

  /// A correction supersedes the last exchange so a misheard age, location or
  /// scheme name cannot remain as context for the corrected request.
  void discardLastExchange(String request) {
    if (_history.isNotEmpty &&
        _history.last['role'] == 'user' &&
        _history.last['content'] == request) {
      _history.removeLast();
    }
    if (_history.length >= 2 &&
        _history[_history.length - 2]['role'] == 'user' &&
        _history[_history.length - 2]['content'] == request) {
      _history.removeRange(_history.length - 2, _history.length);
    }
    if (_pending == request) _pending = null;
    _lastAudio = null;
    _lastReply = null;
    _lastReplyLanguage = null;
  }

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
