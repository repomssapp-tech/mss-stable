import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/chat/chat_log_service.dart';
import '../../services/search/scheme_understanding_engine.dart';
import '../../services/voice/assistant_session_controller.dart';
import '../../services/voice/livekit_voice_agent_controller.dart';
import '../../services/voice/speech_output_controller.dart';
import '../../services/voice/voice_agent_controller.dart';
import '../../services/voice/voice_language.dart';
import '../../services/voice/voice_recognition_controller.dart';
import '../../utils/app_spacing.dart';
import 'saarthi_home/saarthi_bottom_panel.dart';
import 'saarthi_home/saarthi_character_header.dart';
import 'saarthi_home/saarthi_home_models.dart';
import 'saarthi_home/saarthi_response_helpers.dart';
import 'saarthi_home/saarthi_top_bar.dart';
import 'saarthi_home/saarthi_transcript_view.dart';
import 'saarthi_home/saarthi_voice_animations.dart';
import 'saarthi_message.dart';

export 'saarthi_message.dart';

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
  late final SaarthiVoiceAnimations _voiceAnimations;
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

  /// Cloud voice failed for good this session (e.g. the voice-token route
  /// returns 404). Saarthi then keeps working with on-device speech instead of
  /// retrying forever (issue #125).
  bool _cloudUnavailable = false;
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
    _voiceAnimations = SaarthiVoiceAnimations(this);
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
    _voiceAnimations.dispose();
    _soundLevel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncChatSession() {
    if (_messages.isEmpty && _chatLogService.messageCount == 0) return;
    for (final msg in _messages) {
      if (msg.text.trim().isNotEmpty && msg.status != 'transcribing') {
        final schemeNames =
            (msg.schemeResults != null && msg.schemeResults!.isNotEmpty)
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

    _voiceAgentController = LiveKitVoiceAgentController.tryCreate(
      session: _sessionController!,
      profile: provider.profile,
      languageCode: () => provider.selectedLanguage,
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
      _cloudUnavailable = true;
      setState(() {
        _voiceState = SaarthiVoiceState.idle;
        _cloudConnectionError = context.l10n.saarthiVoiceFallbackOnDevice;
      });
      await _startListening();
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
    // Graceful fallback: keep the conversation going on the phone's own speech
    // recognition and voice, and say so, instead of a dead "not connected".
    _cloudUnavailable = true;
    debugPrint('Saarthi: cloud voice unavailable, using on-device speech');
    setState(() {
      _voiceState = SaarthiVoiceState.idle;
      _cloudConnectionError = context.l10n.saarthiVoiceFallbackOnDevice;
    });
    await _startListening();
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
      final schemes = SaarthiResponseHelpers.rankCloudSchemeResults(
        results: results,
        catalogMatches: catalogMatches,
        recentUserTurns: userTurns
            .skip(math.max(0, userTurns.length - 3))
            .toList(growable: false),
      );
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
    if (_isConversationActive && !_cloudUnavailable) {
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
      await _recognitionController.listen(
        localeId: VoiceLanguage.speechLocale(provider.selectedLanguage),
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
      final questionText = SaarthiResponseHelpers.questionText(
        context,
        state,
        question,
      );

      final turnKey = 'asking|${state.questionsAsked}|${question.factKey.name}';
      if (_lastSpokenTurn != turnKey) {
        _lastSpokenTurn = turnKey;
        _speakAndShowResponse(
          questionText,
          state.isTamil
              ? 'ta-IN'
              : VoiceLanguage.speechLocale(
                  Localizations.localeOf(context).languageCode,
                ),
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
      _addAssistantMessage(state.message ?? context.l10n.saarthiGenericError);
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
    _voiceAnimations.setListening(listening, reduceMotion: reduceMotion);
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final userName = provider.profile.name.isNotEmpty
        ? provider.profile.name.split(' ')[0]
        : context.l10n.saarthiGreetingFriend;

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
                  child: SaarthiTopBar(provider: provider),
                )
              else
                const SizedBox(height: AppSpacing.xs),

              // 2. Character Welcome Banner / Compact Header
              SaarthiCharacterHeader(
                isConversationActive: _isConversationActive,
                userName: userName,
                voiceState: _voiceState,
                usingCloudVoice: _usingCloudVoice,
                cloudRetrying: _cloudRetrying,
                cloudConnectionError: _cloudConnectionError,
              ),

              // 3. Expanded content area
              Expanded(
                child: _isConversationActive
                    ? SaarthiTranscriptView(
                        messages: _messages,
                        scrollController: _scrollController,
                        isUserScrolling: _isUserScrolling,
                        onScrollToLatest: _scrollToLatest,
                        waveController: _voiceAnimations.waveController,
                        voiceStatusText: SaarthiHomeHelpers.voiceStatusText(
                          context,
                          _voiceState,
                          cloudConnectionError: _cloudConnectionError,
                          cloudRetrying: _cloudRetrying,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // 4. Bottom Control panel
              SaarthiBottomPanel(
                isConversationActive: _isConversationActive,
                voiceState: _voiceState,
                usingCloudVoice: _usingCloudVoice,
                cloudRetrying: _cloudRetrying,
                cloudConnectionError: _cloudConnectionError,
                onStartConversation: _startConversationMode,
                onPrimaryMicTap: _handleControllerMicTap,
                onEndConversation: () => unawaited(_endConversation()),
                onRetryCloudVoice: () => unawaited(_connectCloudVoice()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
