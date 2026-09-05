import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../services/assistant_session_controller.dart';
import '../../services/livekit_voice_agent_controller.dart';
import '../../services/intelligent_scheme_search.dart';
import '../../services/scheme_understanding_engine.dart';
import '../../services/speech_output_controller.dart';
import '../../services/voice_recognition_controller.dart';
import '../../services/voice_agent_controller.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import '../regular_mode/scheme_details_screen.dart';
import '../../services/centralized_translator.dart';
import '../../utils/responsive.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';
import '../../utils/constants.dart';
import '../../services/chat_log_service.dart';

enum SaarthiVoiceState { idle, listening, processing, speaking, ended }

class SaarthiMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final String? status; // 'transcribing' | null
  final List<Scheme>? schemeResults;
  final List<CloudSchemeResult>? cloudSchemeResults;
  final String? speakingState; // 'speaking' | null

  SaarthiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.status,
    this.schemeResults,
    this.cloudSchemeResults,
    this.speakingState,
  });

  SaarthiMessage copyWith({
    String? text,
    String? status,
    bool clearStatus = false,
    List<Scheme>? schemeResults,
    List<CloudSchemeResult>? cloudSchemeResults,
    String? speakingState,
    bool clearSpeakingState = false,
  }) {
    return SaarthiMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp,
      status: clearStatus ? null : status ?? this.status,
      schemeResults: schemeResults ?? this.schemeResults,
      cloudSchemeResults: cloudSchemeResults ?? this.cloudSchemeResults,
      speakingState: clearSpeakingState
          ? null
          : speakingState ?? this.speakingState,
    );
  }
}

@visibleForTesting
int cloudAssistantMessageTargetIndex(List<SaarthiMessage> messages) =>
    messages.isNotEmpty && messages.last.role == 'assistant'
    ? messages.length - 1
    : -1;

@visibleForTesting
int cloudSchemeResultTargetIndex(List<SaarthiMessage> messages) =>
    messages.isNotEmpty && messages.last.role == 'assistant'
    ? messages.length - 1
    : -1;

@visibleForTesting
bool isTransientCloudConnectionFailure(Object? error) {
  final detail = error?.toString().toLowerCase() ?? '';
  return detail.contains('network') ||
      detail.contains('socket') ||
      detail.contains('timeout') ||
      detail.contains('timed out') ||
      detail.contains('disconnected') ||
      detail.contains('host lookup') ||
      detail.contains('connection reset');
}

@visibleForTesting
bool shouldApplyCloudOutput({
  required String output,
  required String previousOutput,
}) => output.trim().isNotEmpty && output.trim() != previousOutput;

class SaarthiHomeScreen extends StatefulWidget {
  const SaarthiHomeScreen({super.key});

  @override
  State<SaarthiHomeScreen> createState() => _SaarthiHomeScreenState();
}

class _SaarthiHomeScreenState extends State<SaarthiHomeScreen>
    with TickerProviderStateMixin {
  // State variables for conversation mode
  bool _isConversationActive = false;
  bool _isUserScrolling = false;
  bool _autoScrolling = false;
  final List<SaarthiMessage> _messages = [];
  String _partialUserTranscript = '';

  // State machine voice state
  SaarthiVoiceState _voiceState = SaarthiVoiceState.idle;

  // Controllers
  late final AutomaticVoiceRecognitionController _recognitionController;
  late final NativeSpeechOutputController _speechOutputController;
  AssistantSessionController? _sessionController;
  LiveKitVoiceAgentController? _voiceAgentController;
  StreamSubscription<VoiceAgentEvent>? _voiceAgentEvents;

  // Animation controllers
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final ValueNotifier<double> _soundLevel;

  // Internal states
  VoiceRecognitionCapabilities? _recognitionCapabilities;
  bool _startingRecognition = false;
  bool _speaking = false;
  int _recognitionGeneration = 0;
  String? _lastSpokenTurn;
  String? _lastFinalTranscript;
  int _lastFinalRecognitionGeneration = -1;
  DateTime _lastSoundLevelUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _controllersInitialized = false;
  bool _usingCloudVoice = false;
  bool _cloudRetrying = false;
  String? _cloudConnectionError;
  String _lastCloudInputTranscript = '';
  String _lastCloudOutputTranscript = '';
  List<Scheme>? _pendingCloudSchemes;
  List<CloudSchemeResult>? _pendingCloudMetadata;

  final ScrollController _scrollController = ScrollController();
  final ChatLogService _chatLogService = ChatLogService();
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: _syncChatSession,
      onHide: _syncChatSession,
      onDetach: _syncChatSession,
    );
    // Initialize animation controllers immediately for vsync
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.82,
      upperBound: 1.0,
      value: 1.0,
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _soundLevel = ValueNotifier<double>(0.1);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _syncChatSession();
    _voiceAgentController?.removeListener(_handleCloudAgentChanged);
    unawaited(_voiceAgentEvents?.cancel());
    unawaited(_voiceAgentController?.dispose());
    _sessionController?.removeListener(_handleSessionChanged);
    _sessionController?.dispose();
    if (_controllersInitialized) {
      unawaited(_recognitionController.dispose());
      unawaited(_speechOutputController.dispose());
    }
    _pulseController.dispose();
    _waveController.dispose();
    _soundLevel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncChatSession() {
    if (_messages.isEmpty && _chatLogService.messageCount == 0) return;
    for (final msg in _messages) {
      if (msg.text.trim().isNotEmpty && msg.status != 'transcribing') {
        final schemeNames = (msg.schemeResults != null && msg.schemeResults!.isNotEmpty)
            ? msg.schemeResults!.map((s) => s.name).toList()
            : null;
        _chatLogService.upsertMessage(
          id: msg.id,
          speaker: msg.role == 'assistant'
              ? ChatMessageSpeaker.assistant
              : ChatMessageSpeaker.user,
          text: msg.text,
          timestamp: msg.timestamp,
          recommendations: schemeNames,
        );
      }
    }
    unawaited(_chatLogService.syncChatSession(mode: 'voice'));
  }

  void _startConversationMode() {
    unawaited(_startCompanionConversation());
  }

  void _initializeControllers() {
    if (_controllersInitialized) return;
    _controllersInitialized = true;

    final provider = Provider.of<AppProvider>(context, listen: false);
    _recognitionController = AutomaticVoiceRecognitionController();
    _speechOutputController = NativeSpeechOutputController();
    final engine = const LocalSchemeUnderstandingEngine();
    _sessionController = AssistantSessionController(
      engine: engine,
      schemes: provider.allSchemes,
      profile: provider.profile,
    );
    _sessionController!.addListener(_handleSessionChanged);

    _voiceAgentController = LiveKitVoiceAgentController.tryFromSupabase(
      session: _sessionController!,
      profile: provider.profile,
    );
    _voiceAgentController?.addListener(_handleCloudAgentChanged);
    if (_voiceAgentController != null) {
      _voiceAgentEvents = _voiceAgentController!.events.listen(
        _handleCloudAgentEvent,
      );
    }
    unawaited(_speechOutputController.initialize());

    _scrollController.addListener(() {
      if (!_scrollController.hasClients || _autoScrolling) return;
      final isAtBottom =
          _scrollController.position.maxScrollExtent -
              _scrollController.position.pixels <
          40;
      if (isAtBottom == !_isUserScrolling) return;
      setState(() => _isUserScrolling = !isAtBottom);
    });
  }

  Future<void> _startCompanionConversation() async {
    _chatLogService.startSession();
    _initializeControllers();
    if (!mounted) return;
    _lastCloudInputTranscript = '';
    _lastCloudOutputTranscript = '';
    _pendingCloudSchemes = null;
    _pendingCloudMetadata = null;
    setState(() {
      _isConversationActive = true;
      _voiceState = SaarthiVoiceState.processing;
      _cloudConnectionError = null;
    });

    await _connectCloudVoice();
  }

  Future<void> _connectCloudVoice() async {
    if (_cloudRetrying) return;
    final cloud = _voiceAgentController;
    if (cloud == null) {
      if (!mounted) return;
      setState(() {
        _voiceState = SaarthiVoiceState.idle;
        _cloudConnectionError = 'Voice service is unavailable. Tap retry.';
      });
      return;
    }

    _cloudRetrying = true;
    if (mounted) {
      setState(() {
        _voiceState = SaarthiVoiceState.processing;
        _cloudConnectionError = null;
      });
    }
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt += 1) {
      try {
        await cloud.initialize();
        if (attempt == 0) {
          await cloud.connect();
        } else {
          await cloud.retry();
        }
        if (mounted && cloud.state.usingCloud) {
          _usingCloudVoice = true;
          await cloud.setMuted(false);
          if (mounted) {
            setState(() {
              _voiceState = SaarthiVoiceState.listening;
              _cloudConnectionError = null;
            });
          }
          break;
        }
        lastError = StateError(
          cloud.state.message ?? 'LiveKit did not enter cloud mode.',
        );
      } catch (error) {
        lastError = error;
        debugPrint('Saarthi cloud connection attempt ${attempt + 1}: $error');
      }
      if (!isTransientCloudConnectionFailure(lastError)) break;
      if (attempt < 1) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    _cloudRetrying = false;
    if (!mounted || _usingCloudVoice) return;
    setState(() {
      _voiceState = SaarthiVoiceState.idle;
      _cloudConnectionError = _cloudErrorMessage(lastError);
    });
  }

  String _cloudErrorMessage(Object? error) {
    final detail = error?.toString().toLowerCase() ?? '';
    if (detail.contains('sign in') ||
        detail.contains('401') ||
        detail.contains('session')) {
      return 'Please sign in again, then retry voice.';
    }
    if (detail.contains('network') ||
        detail.contains('socket') ||
        detail.contains('host lookup')) {
      return 'Check your internet, then retry voice.';
    }
    return 'Voice service could not connect. Tap retry.';
  }

  void _handleCloudAgentChanged() {
    if (!mounted || !_usingCloudVoice || _voiceAgentController == null) return;
    final state = _voiceAgentController!.state;
    _soundLevel.value = state.audioLevel.clamp(0.0, 1.0);
    final transcript = state.inputTranscript.trim();
    if (transcript.isNotEmpty && transcript != _lastCloudInputTranscript) {
      _lastCloudInputTranscript = transcript;
      _partialUserTranscript = transcript;
      _updateLiveUserTranscript(transcript, isFinal: false);
    }
    final output = state.outputTranscript.trim();
    if (shouldApplyCloudOutput(
      output: output,
      previousOutput: _lastCloudOutputTranscript,
    )) {
      _lastCloudOutputTranscript = output;
      _updateCloudAssistantMessage(output, state.isSpeaking);
    }

    final nextState = state.isSpeaking
        ? SaarthiVoiceState.speaking
        : state.isListening
        ? SaarthiVoiceState.listening
        : SaarthiVoiceState.processing;
    if (_voiceState != nextState || _speaking != state.isSpeaking) {
      setState(() {
        _voiceState = nextState;
        _speaking = state.isSpeaking;
      });
      _setListeningAnimations(state.isListening && !state.isMuted);
    }
  }

  void _handleCloudAgentEvent(VoiceAgentEvent event) {
    if (!mounted || !_usingCloudVoice) return;
    if (event.type == VoiceAgentEventType.schemeResults) {
      final raw = event.data?['results'];
      final results = raw is List<CloudSchemeResult>
          ? raw
          : const <CloudSchemeResult>[];
      final provider = Provider.of<AppProvider>(context, listen: false);
      final catalogMatches = matchCloudSchemeResultsToCatalog(
        results,
        provider.allSchemes,
      );
      final userTurns = _messages
          .where((message) => message.role == 'user')
          .map((message) => message.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(growable: false);
      final recentQuery = userTurns
          .skip(math.max(0, userTurns.length - 3))
          .join(' ');
      final schemes = IntelligentSchemeSearch.rank(
        recentQuery,
        catalogMatches,
        limit: 3,
      ).map((match) => match.scheme).toList(growable: false);
      if (schemes.isEmpty) return;
      final index = cloudSchemeResultTargetIndex(_messages);
      if (index < 0) {
        _pendingCloudSchemes = schemes;
        _pendingCloudMetadata = results;
        return;
      }
      final schemeNames = schemes.map((s) => s.name).toList();
      _chatLogService.upsertMessage(
        id: _messages[index].id,
        speaker: ChatMessageSpeaker.assistant,
        text: _messages[index].text,
        recommendations: schemeNames,
      );
      setState(() {
        _messages[index] = _messages[index].copyWith(
          schemeResults: schemes,
          cloudSchemeResults: results,
        );
      });
      _scrollToBottom();
      return;
    }
    if (event.type == VoiceAgentEventType.recoverableError ||
        event.type == VoiceAgentEventType.fatalError) {
      unawaited(_recoverCloudVoice());
    }
  }

  void _updateCloudAssistantMessage(String text, bool speaking) {
    final index = cloudAssistantMessageTargetIndex(_messages);
    final message = SaarthiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      text: text,
      timestamp: DateTime.now(),
      schemeResults: _pendingCloudSchemes,
      cloudSchemeResults: _pendingCloudMetadata,
      speakingState: speaking ? 'speaking' : null,
    );
    if (text.trim().isNotEmpty) {
      final schemeNames =
          (_pendingCloudSchemes != null && _pendingCloudSchemes!.isNotEmpty)
              ? _pendingCloudSchemes!.map((s) => s.name).toList()
              : null;
      _chatLogService.upsertMessage(
        id: index >= 0 ? _messages[index].id : message.id,
        speaker: ChatMessageSpeaker.assistant,
        text: text,
        recommendations: schemeNames,
      );
    }
    if (index < 0) {
      setState(() {
        if (_messages.isNotEmpty && _messages.last.role == 'user') {
          _messages[_messages.length - 1] = _messages.last.copyWith(
            clearStatus: true,
          );
        }
        _messages.add(message);
      });
    } else {
      setState(() {
        _messages[index] = _messages[index].copyWith(
          text: text,
          schemeResults: _pendingCloudSchemes,
          cloudSchemeResults: _pendingCloudMetadata,
          speakingState: speaking ? 'speaking' : null,
          clearSpeakingState: !speaking,
        );
      });
    }
    _pendingCloudSchemes = null;
    _pendingCloudMetadata = null;
    _scrollToBottom();
  }

  Future<void> _recoverCloudVoice() async {
    if (!_usingCloudVoice) return;
    _usingCloudVoice = false;
    _lastCloudInputTranscript = '';
    if (!mounted || !_isConversationActive) return;
    await _connectCloudVoice();
  }

  Future<void> _startListening({bool preserveTranscript = false}) async {
    if (!mounted || _startingRecognition || _speaking) return;
    if (_usingCloudVoice) {
      await _voiceAgentController?.setMuted(false);
      return;
    }
    if (_isConversationActive) {
      await _connectCloudVoice();
      return;
    }
    _startingRecognition = true;
    _recognitionGeneration++;
    _lastFinalTranscript = null;
    _lastFinalRecognitionGeneration = -1;
    await _speechOutputController.stop();
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voiceState = SaarthiVoiceState.listening;
      if (!preserveTranscript) {
        _partialUserTranscript = '';
      }
    });

    try {
      final capabilities =
          _recognitionCapabilities ??
          await _recognitionController.initialize(
            onStatus: _handleStatus,
            onResult: _handleResult,
            onSoundLevel: _handleSoundLevel,
            onLanguage: _handleLanguage,
            onError: _handleError,
          );
      _recognitionCapabilities = capabilities;
      if (!mounted) return;
      if (!capabilities.available) {
        _setListeningAnimations(false);
        setState(() {
          _voiceState = SaarthiVoiceState.idle;
        });
        return;
      }

      setState(() {
        _voiceState = SaarthiVoiceState.listening;
      });
      _sessionController?.setListening(
        transcript: preserveTranscript ? _partialUserTranscript : '',
      );
      _setListeningAnimations(true);

      final provider = Provider.of<AppProvider>(context, listen: false);
      final isTamil = provider.selectedLanguage == 'ta';
      await _recognitionController.listen(
        localeId: isTamil ? 'ta-IN' : 'en-IN',
      );
      if (mounted && !_recognitionController.isListening) {
        _setListeningAnimations(false);
      }
    } catch (_) {
      if (!mounted) return;
      _setListeningAnimations(false);
      setState(() {
        _voiceState = SaarthiVoiceState.idle;
      });
    } finally {
      _startingRecognition = false;
    }
  }

  Future<void> _stopListening() async {
    if (_usingCloudVoice) {
      await _voiceAgentController?.setMuted(true);
      if (mounted) setState(() => _voiceState = SaarthiVoiceState.idle);
      _setListeningAnimations(false);
      return;
    }
    await _recognitionController.stop();
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voiceState = SaarthiVoiceState.idle;
    });
  }

  Future<void> _endConversation() async {
    _syncChatSession();
    _sessionController?.cancel();
    _usingCloudVoice = false;
    await _voiceAgentController?.close();
    await _speechOutputController.stop();
    await _recognitionController.cancel();
    _setListeningAnimations(false);

    setState(() {
      _isConversationActive = false;
      _voiceState = SaarthiVoiceState.ended;
      _messages.clear();
      _partialUserTranscript = '';
    });
  }

  void _handleResult(VoiceRecognitionResult result) {
    if (!mounted) return;
    final transcript = result.transcript.trim();

    setState(() {
      _partialUserTranscript = transcript;
      _updateLiveUserTranscript(transcript, isFinal: result.isFinal);
      if (result.isFinal) {
        _voiceState = SaarthiVoiceState.processing;
        _setListeningAnimations(false);
      }
    });

    if (!result.isFinal) {
      _sessionController?.updatePartialTranscript(transcript);
      return;
    }
    if (transcript.isEmpty) return;
    if (_lastFinalRecognitionGeneration == _recognitionGeneration &&
        _lastFinalTranscript == transcript) {
      return;
    }
    _lastFinalRecognitionGeneration = _recognitionGeneration;
    _lastFinalTranscript = transcript;
    unawaited(_processFinalTranscript(transcript));
  }

  void _updateLiveUserTranscript(String text, {required bool isFinal}) {
    if (text.isEmpty) return;

    if (_messages.isNotEmpty &&
        _messages.last.role == 'user' &&
        _messages.last.status == 'transcribing') {
      setState(() {
        _messages[_messages.length - 1] = _messages.last.copyWith(
          text: text,
          status: isFinal ? null : 'transcribing',
          clearStatus: isFinal,
        );
      });
    } else {
      final newMsg = SaarthiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        text: text,
        timestamp: DateTime.now(),
        status: isFinal ? null : 'transcribing',
      );
      setState(() {
        _messages.add(newMsg);
      });
    }
    if (isFinal && text.trim().isNotEmpty) {
      final msgId = (_messages.isNotEmpty && _messages.last.role == 'user')
          ? _messages.last.id
          : DateTime.now().millisecondsSinceEpoch.toString();
      _chatLogService.upsertMessage(
        id: msgId,
        speaker: ChatMessageSpeaker.user,
        text: text,
      );
    }
    _scrollToBottom();
  }

  Future<void> _processFinalTranscript(String transcript) async {
    final value = transcript.trim();
    if (value.isEmpty) return;

    final session = _sessionController;
    if (session != null) {
      if (session.state.question != null) {
        await session.answer(value);
      } else {
        _lastSpokenTurn = null;
        final provider = Provider.of<AppProvider>(context, listen: false);
        await session.start(value, isTamil: provider.selectedLanguage == 'ta');
      }
    }
  }

  void _handleSessionChanged() {
    if (!mounted || !_isConversationActive) return;
    final state = _sessionController!.state;

    if (state.phase == AssistantSessionPhase.understanding) {
      setState(() {
        _voiceState = SaarthiVoiceState.processing;
      });
    } else if (state.phase == AssistantSessionPhase.asking &&
        state.question != null) {
      final question = state.question!;
      final questionText = _questionText(state, question);

      final turnKey = 'asking|${state.questionsAsked}|${question.factKey.name}';
      if (_lastSpokenTurn != turnKey) {
        _lastSpokenTurn = turnKey;
        _speakAndShowResponse(
          questionText,
          state.isTamil ? 'ta-IN' : 'en-IN',
          questionOptions: question.options,
        );
      }
    } else if ((state.phase == AssistantSessionPhase.results ||
            state.phase == AssistantSessionPhase.noConfidentMatch) &&
        state.reply != null) {
      final reply = state.reply!;

      final turnKey = 'reply|${reply.topic}|${reply.displayText}';
      if (_lastSpokenTurn != turnKey) {
        _lastSpokenTurn = turnKey;

        final schemes = state.recommendations.map((r) => r.scheme).toList();
        _speakAndShowResponse(
          reply.displayText,
          reply.languageTag,
          schemes: schemes,
        );
      }
    } else if (state.phase == AssistantSessionPhase.error) {
      setState(() {
        _voiceState = SaarthiVoiceState.idle;
      });
      _addAssistantMessage(
        state.message ?? 'An error occurred. Please try again.',
      );
    }
  }

  Future<void> _speakAndShowResponse(
    String text,
    String languageTag, {
    List<String>? questionOptions,
    List<Scheme>? schemes,
  }) async {
    await _recognitionController.cancel();
    _setListeningAnimations(false);

    setState(() {
      _voiceState = SaarthiVoiceState.speaking;
      _speaking = true;
    });

    final speakFuture = _speechOutputController.speak(
      text,
      languageTag: languageTag,
    );

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final words = text.split(' ');
    int wordIndex = 0;

    final msg = SaarthiMessage(
      id: messageId,
      role: 'assistant',
      text: '',
      timestamp: DateTime.now(),
      speakingState: 'speaking',
    );

    setState(() {
      _messages.add(msg);
    });
    _scrollToBottom();

    Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted || !_isConversationActive) {
        t.cancel();
        return;
      }

      if (wordIndex >= words.length) {
        t.cancel();
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              text: text,
              schemeResults: schemes,
              speakingState: null,
            );
          }
        });
        _scrollToBottom();
        return;
      }

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          final partial = words.sublist(0, wordIndex + 1).join(' ');
          _messages[idx] = _messages[idx].copyWith(text: partial);
        }
      });
      _scrollToBottom();
      wordIndex++;
    });

    final completed = await speakFuture;

    if (mounted) {
      setState(() {
        _speaking = false;
      });
    }

    if (completed && mounted && _isConversationActive) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted && _isConversationActive) {
        await _startListening(preserveTranscript: false);
      }
    }
  }

  void _scrollToBottom() {
    if (_isUserScrolling) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _autoScrolling = true;
        _scrollController
            .animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            )
            .whenComplete(() {
              if (!mounted) return;
              _autoScrolling = false;
              if (_scrollController.hasClients &&
                  _scrollController.position.maxScrollExtent -
                          _scrollController.position.pixels <
                      40 &&
                  _isUserScrolling) {
                setState(() => _isUserScrolling = false);
              }
            });
      }
    });
  }

  void _scrollToLatest() {
    setState(() {
      _isUserScrolling = false;
    });
    _scrollToBottom();
  }

  void _setListeningAnimations(bool listening) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _pulseController.stop();
      _pulseController.value = 1.0;
      _waveController.stop();
      _waveController.value = 0.0;
      return;
    }
    if (listening) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
      _waveController.stop();
      _waveController.value = 0.0;
    }
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      _setListeningAnimations(true);
      setState(() => _voiceState = SaarthiVoiceState.listening);
    } else if (status == 'processing') {
      _setListeningAnimations(false);
      setState(() => _voiceState = SaarthiVoiceState.processing);
    } else if (status == 'done' || status == 'notListening') {
      _setListeningAnimations(false);
    }
  }

  void _handleSoundLevel(double level) {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastSoundLevelUpdate) <
        const Duration(milliseconds: 66)) {
      return;
    }
    _lastSoundLevelUpdate = now;
    final normalizedLevel = ((level + 2) / 12).clamp(0.0, 1.0);
    _soundLevel.value = normalizedLevel;
  }

  void _handleLanguage(String language) {}

  void _handleError(VoiceRecognitionError error) {
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voiceState = SaarthiVoiceState.idle;
    });
    _addAssistantMessage(error.message);
  }

  void _addAssistantMessage(String text) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    if (text.trim().isNotEmpty) {
      _chatLogService.upsertMessage(
        id: id,
        speaker: ChatMessageSpeaker.assistant,
        text: text,
      );
    }
    setState(() {
      _messages.add(
        SaarthiMessage(
          id: id,
          role: 'assistant',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _handleControllerMicTap() async {
    await HapticFeedback.selectionClick();
    if (_usingCloudVoice) {
      if (_voiceState == SaarthiVoiceState.listening) {
        await _stopListening();
      } else if (_voiceState == SaarthiVoiceState.speaking) {
        await _voiceAgentController?.interrupt();
        await _voiceAgentController?.setMuted(false);
      } else {
        await _voiceAgentController?.setMuted(false);
      }
      return;
    }
    if (_voiceState == SaarthiVoiceState.listening) {
      await _stopListening();
    } else if (_voiceState == SaarthiVoiceState.speaking) {
      await _speechOutputController.stop();
      setState(() {
        _voiceState = SaarthiVoiceState.listening;
      });
      await _startListening(preserveTranscript: false);
    } else {
      await _startListening(preserveTranscript: false);
    }
  }

  String _questionText(AssistantSessionState state, FollowUpQuestion question) {
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(state.statement)) {
      return question.tamil;
    }
    if (!state.isTamil) return question.english;
    return switch (question.factKey) {
      EligibilityFactKey.age => 'Unga vayasu enna?',
      EligibilityFactKey.state => 'Neenga entha state-la irukkeenga?',
      EligibilityFactKey.district => 'Neenga entha district-la irukkeenga?',
      EligibilityFactKey.annualIncome =>
        'Unga family annual income approximately evlo?',
      EligibilityFactKey.gender => 'Unga gender category enna?',
      EligibilityFactKey.community => 'Unga community category enna?',
      EligibilityFactKey.occupation => 'Ippo unga occupation enna?',
      EligibilityFactKey.education => 'Unga education level enna?',
      EligibilityFactKey.disability => 'Disability category apply aaguma?',
      EligibilityFactKey.maritalStatus => 'Unga marital status enna?',
      EligibilityFactKey.studentStatus =>
        'Neenga ippo student-ah irukkeengala?',
      EligibilityFactKey.businessStage =>
        'Idhu idea stage-ah, new business-ah, illa existing business-ah?',
      EligibilityFactKey.businessSector => 'Business sector enna?',
      EligibilityFactKey.fundingNeed => 'Approximately evlo funding thevai?',
      EligibilityFactKey.landholding => 'Unga landholding evlo?',
    };
  }

  Color _getStatusColor() {
    if (_cloudConnectionError != null) return const Color(0xFFDC2626);
    switch (_voiceState) {
      case SaarthiVoiceState.listening:
        return const Color(0xFF2563EB);
      case SaarthiVoiceState.processing:
        return const Color(0xFFB45309);
      case SaarthiVoiceState.speaking:
        return const Color(0xFF047857);
      default:
        return const Color(0xFF475569);
    }
  }

  String _getStatusLabel() {
    if (_cloudConnectionError != null) return 'Connection needs attention';
    if (_cloudRetrying) return 'Connecting';
    switch (_voiceState) {
      case SaarthiVoiceState.listening:
        return 'Listening to you';
      case SaarthiVoiceState.processing:
        return 'Checking your details';
      case SaarthiVoiceState.speaking:
        return 'Speaking now';
      default:
        return 'Ready to help';
    }
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final userName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ')[0]
        : 'Praveen';

    const Color kBrandBlue = Color(0xFF2563EB);
    const Color kDarkSlate = Color(0xFF0F172A);
    const Color kSlate500 = Color(0xFF64748B);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _syncChatSession();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top bar: Language Pill & Notifications / Profile Avatar
              if (!_isConversationActive)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: AppSpacing.xl,
                  ),
                  child: _buildTopBar(
                    provider,
                    kDarkSlate,
                    kBrandBlue,
                    kSlate500,
                  ),
                )
              else
                const SizedBox(height: AppSpacing.xs),

              // 2. Character Welcome Banner / Compact Header
              _buildCharacterHeader(
                userName,
                kDarkSlate,
                kBrandBlue,
                kSlate500,
              ),

              // 3. Expanded content area
              Expanded(
                child: _isConversationActive
                    ? _buildTranscriptSection()
                    : const SizedBox.shrink(),
              ),

              // 4. Bottom Control panel
              _buildBottomPanel(kBrandBlue, kDarkSlate, kSlate500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    AppProvider provider,
    Color kDarkSlate,
    Color kBrandBlue,
    Color kSlate500,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Language Pill selector
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.tight,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF2563EB), size: 16),
                const SizedBox(width: AppSpacing.tight),
                Flexible(
                  child: FitOneLine(
                    child: Text(
                      provider.selectedLanguage == 'ta' ? 'தமிழ்' : 'English',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: kDarkSlate,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF64748B),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // Notification icon & Profile photo
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF0F172A),
                    size: 24,
                  ),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (provider.notifications.any((n) => n['read'] == false))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: ClipOval(
                  child: () {
                    final photo = provider.effectiveProfilePhoto;
                    if (photo.isEmpty) {
                      return Image.asset(
                        'assets/images/supporting assets/user_avatar.webp',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      );
                    }
                    if (photo.startsWith('http://') ||
                        photo.startsWith('https://')) {
                      return Image.network(
                        photo,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                      );
                    }
                    final file = File(photo);
                    if (file.existsSync()) {
                      return Image.file(
                        file,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      );
                    }
                    return Image.asset(
                      'assets/images/supporting assets/user_avatar.webp',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    );
                  }(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharacterHeader(
    String userName,
    Color kDarkSlate,
    Color kBrandBlue,
    Color kSlate500,
  ) {
    if (_isConversationActive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getStatusColor().withValues(alpha: 0.28),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/saarthi/sarathi.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MSS Saarthi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kDarkSlate,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _getStatusLabel(),
                        key: ValueKey(_voiceState),
                        style: GoogleFonts.inter(
                          color: _getStatusColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.tight,
                ),
                decoration: BoxDecoration(
                  color: _cloudConnectionError == null
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _cloudConnectionError == null
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _cloudConnectionError == null
                          ? Icons.graphic_eq_rounded
                          : Icons.cloud_off_outlined,
                      size: 14,
                      color: _cloudConnectionError == null
                          ? const Color(0xFF047857)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: FitOneLine(
                        child: Text(
                          _usingCloudVoice
                              ? 'Voice connected'
                              : _cloudRetrying
                              ? 'Connecting'
                              : 'Voice offline',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _cloudConnectionError == null
                                ? const Color(0xFF047857)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                width: _isConversationActive ? 56 : 170,
                height: _isConversationActive ? 56 : 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                    width: _isConversationActive ? 2 : 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/saarthi/sarathi.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!_isConversationActive) ...[
                const Positioned(
                  left: 0,
                  top: 55,
                  child: Icon(Icons.star, color: Color(0xFF93C5FD), size: 14),
                ),
                const Positioned(
                  right: 0,
                  top: 45,
                  child: Icon(Icons.star, color: Color(0xFF93C5FD), size: 16),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.tight),
        Column(
          children: [
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kDarkSlate,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${AppConstants.getTimeGreeting(isTa: Provider.of<AppProvider>(context, listen: false).selectedLanguage == 'ta', withComma: true)} ',
                    ),
                    TextSpan(
                      text: '$userName! 👋',
                      style: const TextStyle(color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.hairline),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: kDarkSlate,
                  ),
                  children: const [
                    TextSpan(text: "I'm "),
                    TextSpan(
                      text: 'Saarthi',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ', your AI companion for\nMSME success.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildTranscriptSection() {
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _messages.isEmpty
              ? Center(
                  key: const ValueKey('voice-empty-state'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getVoiceStatusText(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.tight),
                        Text(
                          'Tell me what support you need. I will ask one detail at a time.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            height: 1.45,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('voice-transcript-list'),
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(_messages[index]),
                ),
        ),
        if (_isUserScrolling)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _scrollToLatest,
                icon: const Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  CentralizedTranslator.instance.translate('Latest'),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageItem(SaarthiMessage message) {
    if (message.role == 'user') {
      return _buildUserMessage(message);
    } else {
      return _buildAiMessage(message);
    }
  }

  Widget _buildUserMessage(SaarthiMessage message) {
    final timeStr = _formatTimestamp(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.tight,
        bottom: AppSpacing.md,
        left: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'You  $timeStr',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(SaarthiMessage message) {
    final timeStr = _formatTimestamp(message.timestamp);
    final isSpeaking = message.speakingState == 'speaking';

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.hairline,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEFF6FF),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/saarthi/sarathi.webp',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MSS Saarthi  $timeStr',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.42,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (isSpeaking) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildWaveformBar(6, 12),
                                _buildWaveformBar(9, 6),
                                _buildWaveformBar(12, 14),
                                _buildWaveformBar(7, 8),
                                _buildWaveformBar(10, 10),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: FitOneLine(
                                    child: Text(
                                      'Speaking',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: const Color(0xFF059669),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message.schemeResults != null &&
              message.schemeResults!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.only(left: 43),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Flexible(
                        child: Text(
                          context.l10n.recommendedForYou,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ranked from the details you shared. Final eligibility is confirmed by the department.',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      height: 1.35,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  ...message.schemeResults!.map(
                    (scheme) => _buildCompactSchemeCard(
                      scheme,
                      _metadataForScheme(scheme, message.cloudSchemeResults),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveformBar(double height, double animDelay) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final scale =
            0.5 +
            0.5 * math.sin(_waveController.value * math.pi * 2 + animDelay);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.hairline),
          width: 2.5,
          height: height * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      },
    );
  }

  CloudSchemeResult? _metadataForScheme(
    Scheme scheme,
    List<CloudSchemeResult>? results,
  ) {
    if (results == null) return null;
    String normalize(String value) => value.toLowerCase().trim();
    for (final result in results) {
      if (result.id.isNotEmpty &&
          normalize(result.id) == normalize(scheme.id)) {
        return result;
      }
      if (result.code.isNotEmpty &&
          (normalize(result.code) == normalize(scheme.schemeCode) ||
              normalize(result.code) == normalize(scheme.id))) {
        return result;
      }
      if (result.name.isNotEmpty &&
          normalize(result.name) == normalize(scheme.name)) {
        return result;
      }
    }
    return null;
  }

  Widget _buildCompactSchemeCard(Scheme scheme, CloudSchemeResult? metadata) {
    final lang = Provider.of<AppProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    final locScheme = scheme.toLocalized(lang);
    final isTa = lang == 'ta';

    final confidence = metadata?.matchConfidence;
    final confidenceColor = confidence == null
        ? const Color(0xFF64748B)
        : confidence >= 80
        ? const Color(0xFF047857)
        : confidence >= 60
        ? const Color(0xFF2563EB)
        : const Color(0xFFB45309);
    final verified =
        metadata?.isVerified == true ||
        scheme.verificationStatus.toLowerCase().contains('verified');
    final sourceConfidence = metadata?.sourceConfidence.trim() ?? '';
    final summary = locScheme.benefits.trim().isNotEmpty
        ? locScheme.benefits.trim()
        : locScheme.overview.trim();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('companion-scheme-${scheme.id}'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(scheme: scheme),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: confidenceColor.withValues(alpha: 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSchemeIcon(locScheme.name),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        locScheme.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.tight,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        confidence == null
                            ? (isTa ? 'பொருத்தம் காண்க' : 'Review match')
                            : (isTa
                                  ? '$confidence% பொருத்தம்'
                                  : '$confidence% match'),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: confidenceColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      height: 1.4,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      verified
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: verified
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Expanded(
                      child: Text(
                        verified
                            ? sourceConfidence.isEmpty
                                  ? 'Official source checked'
                                  : 'Official source checked · ${sourceConfidence[0].toUpperCase()}${sourceConfidence.substring(1)} confidence'
                            : 'Verify with the department',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: verified
                              ? const Color(0xFF047857)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      'View eligibility',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.hairline),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchemeIcon(String schemeName) {
    final lower = schemeName.toLowerCase();
    IconData icon = Icons.account_balance_rounded;
    Color bg = const Color(0xFFEFF6FF);
    Color foreground = const Color(0xFF2563EB);

    if (lower.contains('pmegp')) {
      icon = Icons.factory_outlined;
    } else if (lower.contains('cgtmse')) {
      icon = Icons.currency_rupee_rounded;
      bg = const Color(0xFFECFDF5);
      foreground = const Color(0xFF059669);
    } else if (lower.contains('mse-cdp')) {
      icon = Icons.settings_outlined;
      bg = const Color(0xFFF5F3FF);
      foreground = const Color(0xFF7C3AED);
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: foreground),
    );
  }

  Widget _buildBottomPanel(
    Color kBrandBlue,
    Color kDarkSlate,
    Color kSlate500,
  ) {
    if (!_isConversationActive) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ask Saarthi Card (The Box)
            GestureDetector(
              onTap: _startConversationMode,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEFF6FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kBrandBlue.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Ask Saarthi anything...',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: kDarkSlate,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      'Tap below and speak your question',
                      style: GoogleFonts.inter(fontSize: 10, color: kSlate500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildStartVoiceButton(),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVoiceStatusBanner(),
            if (_cloudConnectionError != null) ...[
              const SizedBox(height: AppSpacing.tight),
              Text(
                _cloudConnectionError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFFB91C1C),
                ),
              ),
              TextButton.icon(
                key: const Key('saarthi-cloud-retry'),
                onPressed: _cloudRetrying
                    ? null
                    : () => unawaited(_connectCloudVoice()),
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(
                  CentralizedTranslator.instance.translate('Retry voice'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _buildAccessibleVoiceControls(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _usingCloudVoice
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_sync_outlined,
                  size: 12,
                  color: const Color(0xFF94A3B8),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: FitOneLine(
                    child: Text(
                      _usingCloudVoice
                          ? 'Secure live voice session'
                          : 'Live voice connection required',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStartVoiceButton() {
    return Semantics(
      button: true,
      label: 'Start speaking to Saarthi',
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton.icon(
          key: const Key('saarthi-start-speaking'),
          onPressed: () {
            unawaited(HapticFeedback.mediumImpact());
            _startConversationMode();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.mic_rounded, size: 27),
          label: Text(
            'Tap to speak',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceStatusBanner() {
    final icon = _cloudConnectionError != null
        ? Icons.error_outline_rounded
        : _cloudRetrying
        ? Icons.sync_rounded
        : switch (_voiceState) {
            SaarthiVoiceState.listening => Icons.hearing_rounded,
            SaarthiVoiceState.processing => Icons.search_rounded,
            SaarthiVoiceState.speaking => Icons.volume_up_rounded,
            _ => Icons.mic_none_rounded,
          };
    final color = _getStatusColor();
    return Semantics(
      liveRegion: true,
      label: _getVoiceStatusText(),
      child: Container(
        key: const Key('saarthi-voice-status'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                _getVoiceStatusText(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibleVoiceControls() {
    final listening = _voiceState == SaarthiVoiceState.listening;
    final speaking = _voiceState == SaarthiVoiceState.speaking;
    final primaryColor = listening
        ? const Color(0xFF047857)
        : speaking
        ? const Color(0xFF7C3AED)
        : const Color(0xFF1D4ED8);
    final primaryIcon = listening
        ? Icons.stop_rounded
        : speaking
        ? Icons.front_hand_rounded
        : Icons.mic_rounded;
    final primaryLabel = listening
        ? 'Stop'
        : speaking
        ? 'Interrupt'
        : 'Speak';

    return Container(
      key: const Key('saarthi-accessible-controls'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Semantics(
              button: true,
              label: '$primaryLabel voice control',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: primaryColor,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      key: const Key('saarthi-primary-voice-control'),
                      customBorder: const CircleBorder(),
                      onTap: _handleControllerMicTap,
                      child: SizedBox.square(
                        dimension: 72,
                        child: Icon(primaryIcon, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  FitOneLine(
                    child: Text(
                      primaryLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: _buildLabeledControl(
              key: const Key('saarthi-end-control'),
              icon: Icons.call_end_rounded,
              label: 'End',
              color: const Color(0xFFB91C1C),
              onTap: () {
                unawaited(HapticFeedback.mediumImpact());
                unawaited(_endConversation());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledControl({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.tight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: color),
                const SizedBox(height: AppSpacing.tight),
                FitOneLine(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getVoiceStatusText() {
    if (_cloudConnectionError != null) return 'Voice is not connected';
    if (_cloudRetrying) return 'Connecting securely';
    switch (_voiceState) {
      case SaarthiVoiceState.listening:
        return 'Listening to you';
      case SaarthiVoiceState.processing:
        return 'Finding the best match';
      case SaarthiVoiceState.speaking:
        return 'Saarthi is speaking';
      default:
        return 'Ready';
    }
  }
}
