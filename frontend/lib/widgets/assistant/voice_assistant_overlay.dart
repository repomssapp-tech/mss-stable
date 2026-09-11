import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../models/user_profile.dart';
import '../../services/voice/assistant_session_controller.dart';
import '../../services/edge_ai/edge_slm_understanding_engine.dart';
import '../../services/search/intelligent_scheme_search.dart';
import '../../services/voice/livekit_voice_agent_controller.dart';
import '../../services/search/official_grounded_search.dart';
import '../../services/search/private_ai_knowledge_base.dart';
import '../../services/search/scheme_understanding_engine.dart';
import '../../services/voice/speech_output_controller.dart';
import '../../services/voice/voice_recognition_controller.dart';
import '../../services/voice/voice_agent_controller.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../services/chat/chat_log_service.dart';
import '../../utils/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';
import 'voice_edge_painter.dart';

export 'voice_edge_painter.dart';

enum _VoiceAssistantPhase {
  starting,
  listening,
  processing,
  ready,
  unavailable,
}

enum VoiceInputLanguage { english, tamil }

enum _OnlineGroundingPhase { idle, checking, found, unavailable, noSources }

enum _VoiceTranscriptSpeaker { user, assistant }

@immutable
class _VoiceTranscriptTurn {
  const _VoiceTranscriptTurn({
    required this.id,
    required this.speaker,
    required this.text,
    this.schemeMatches = const [],
  });

  final String id;
  final _VoiceTranscriptSpeaker speaker;
  final String text;
  final List<SchemeSearchMatch> schemeMatches;

  _VoiceTranscriptTurn copyWith({
    String? text,
    List<SchemeSearchMatch>? schemeMatches,
  }) => _VoiceTranscriptTurn(
    id: id,
    speaker: speaker,
    text: text ?? this.text,
    schemeMatches: schemeMatches ?? this.schemeMatches,
  );
}

class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({
    super.key,
    required this.onClose,
    required this.onSubmit,
    this.schemes = const [],
    this.profile,
    this.onProfileConfirmed,
    this.onSearch,
    this.onSchemeSelected,
    this.recognitionController,
    this.speechOutputController,
    this.understandingEngine,
    this.sessionController,
    this.voiceAgentController,
    this.groundedSearch,
    this.surface = VoiceAgentSurface.regular,
    this.initialText,
    this.autoStart = true,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;
  final List<Scheme> schemes;
  final UserProfile? profile;
  final ValueChanged<UserProfile>? onProfileConfirmed;
  final Future<List<SchemeSearchMatch>> Function(String query)? onSearch;
  final ValueChanged<Scheme>? onSchemeSelected;
  final VoiceRecognitionController? recognitionController;
  final SpeechOutputController? speechOutputController;
  final SchemeUnderstandingEngine? understandingEngine;
  final AssistantSessionController? sessionController;
  final VoiceAgentController? voiceAgentController;
  final OfficialGroundedSearch? groundedSearch;
  final VoiceAgentSurface surface;
  final String? initialText;
  final bool autoStart;

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final VoiceRecognitionController _recognitionController;
  late final SpeechOutputController _speechOutputController;
  late final bool _ownsRecognitionController;
  late final bool _ownsSpeechOutputController;
  late final bool _ownsSessionController;
  late final OfficialGroundedSearch _groundedSearch;
  late final bool _ownsGroundedSearch;
  bool _ownsUnderstandingEngine = false;
  EdgeSlmUnderstandingEngine? _edgeSlmEngine;
  VoiceAgentController? _voiceAgentController;
  bool _ownsVoiceAgentController = false;
  StreamSubscription<VoiceAgentEvent>? _voiceAgentEvents;
  AssistantSessionController? _sessionController;
  late final AnimationController _edgeController;
  late final AnimationController _edgeRevealController;
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final ValueNotifier<double> _edgeIntensity;
  late final ValueNotifier<double> _soundLevel;
  late final Listenable _edgeRepaint;
  bool _reduceEdgeMotion = false;

  _VoiceAssistantPhase _voicePhase = _VoiceAssistantPhase.starting;
  String _transcript = '';
  String? _message;
  String? _detectedLanguage;
  VoiceInputLanguage _fallbackLanguage = VoiceInputLanguage.english;
  VoiceRecognitionCapabilities? _recognitionCapabilities;
  SpeechOutputCapabilities? _speechCapabilities;
  bool _showFallbackPicker = false;
  bool _startingRecognition = false;
  bool _speaking = false;
  bool _closing = false;
  bool _fallingBackToLocal = false;
  List<SchemeSearchMatch> _legacyMatches = const [];
  bool _legacySearching = false;
  int _operationGeneration = 0;
  int _recognitionGeneration = 0;
  String? _lastSpokenTurn;
  String? _lastFinalTranscript;
  int _lastFinalRecognitionGeneration = -1;
  DateTime _lastSoundLevelUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  final TextEditingController _typedController = TextEditingController();
  _OnlineGroundingPhase _groundingPhase = _OnlineGroundingPhase.idle;
  List<GroundedSource> _groundedSources = const [];
  String? _groundingKey;
  int _groundingGeneration = 0;
  bool _showAllRecommendations = false;
  String? _recommendationStatement;
  final List<_VoiceTranscriptTurn> _conversationTurns = [];
  List<SchemeSearchMatch> _pendingCloudMatches = const [];
  final ScrollController _panelScrollController = ScrollController();
  final ChatLogService _chatLogService = ChatLogService();
  late final AppLifecycleListener _lifecycleListener;
  int _fallbackTranscriptId = 0;

  bool get _isListening => _voicePhase == _VoiceAssistantPhase.listening;
  bool get _cloudSessionInUse {
    final state = _voiceAgentController?.state;
    if (state?.usingCloud != true) return false;
    return switch (state!.phase) {
      VoiceAgentConnectionPhase.initializing ||
      VoiceAgentConnectionPhase.connecting ||
      VoiceAgentConnectionPhase.connected ||
      VoiceAgentConnectionPhase.reconnecting => true,
      _ => false,
    };
  }

  bool get _isCompanion => widget.surface == VoiceAgentSurface.companion;
  Color get _accent =>
      _isCompanion ? const Color(0xFFEA580C) : const Color(0xFF2563EB);
  bool get _hasConversation => _sessionController != null;
  AssistantSessionState? get _session => _sessionController?.state;
  VoiceEdgeActivity get _edgeActivity {
    if (_speaking) return VoiceEdgeActivity.speaking;
    if (_isListening) return VoiceEdgeActivity.listening;
    if (_voicePhase == _VoiceAssistantPhase.processing ||
        _session?.phase == AssistantSessionPhase.understanding) {
      return VoiceEdgeActivity.processing;
    }
    return VoiceEdgeActivity.idle;
  }

  bool get _presentInTamil {
    if (!_isCompanion) {
      final statement = _session?.statement ?? '';
      return _detectedLanguage?.toLowerCase().startsWith('ta') == true ||
          RegExp(r'[\u0B80-\u0BFF]').hasMatch(_transcript) ||
          RegExp(r'[\u0B80-\u0BFF]').hasMatch(statement) ||
          (_showFallbackPicker &&
              _fallbackLanguage == VoiceInputLanguage.tamil);
    }
    if (_session?.isTamil == true) return true;
    if (_detectedLanguage?.toLowerCase().startsWith('ta') == true) return true;
    if (_detectedLanguage?.toLowerCase().startsWith('en') == true) return false;
    if (_transcript.trim().isNotEmpty) {
      return IntelligentSchemeSearch.interpret(_transcript).isTamil;
    }
    return _showFallbackPicker && _fallbackLanguage == VoiceInputLanguage.tamil;
  }

  // Voice-assistant chrome follows the language the user is actually speaking
  // (`_presentInTamil`), which is detected per-utterance and can differ from the
  // ambient `MaterialApp` locale — so strings resolve through an explicit
  // lookup rather than `context.l10n`.
  AppLocalizations get _l10n =>
      lookupAppLocalizations(Locale(_presentInTamil ? 'ta' : 'en'));

  String get _languageBadgeLabel {
    if (_detectedLanguage?.toLowerCase().startsWith('ta') == true ||
        _session?.isTamil == true) {
      return 'தமிழ்';
    }
    if (_detectedLanguage?.toLowerCase().startsWith('en') == true) {
      return 'English';
    }
    return _l10n.voiceLanguageAuto;
  }

  String get _statusLabel {
    final l10n = _l10n;
    if (_speaking) return l10n.voiceStatusSpeaking;
    if (_isListening) return l10n.voiceStatusListening;
    if (_voicePhase == _VoiceAssistantPhase.processing) {
      return l10n.voiceStatusProcessing;
    }
    switch (_session?.phase) {
      case AssistantSessionPhase.understanding:
        return l10n.voiceStatusUnderstanding;
      case AssistantSessionPhase.asking:
        return l10n.voiceStatusOneQuestion;
      case AssistantSessionPhase.results:
        return l10n.voiceStatusMatchesFound;
      case AssistantSessionPhase.noConfidentMatch:
        return l10n.voiceStatusNeedsMoreDetail;
      default:
        if (_legacySearching) return l10n.voiceStatusFinding;
        if (_legacyMatches.isNotEmpty) {
          return l10n.voiceStatusFoundCount(_legacyMatches.length);
        }
        return l10n.companionReadyShort;
    }
  }

  Color get _statusColor => _isListening
      ? const Color(0xFF10B981)
      : _speaking ||
            _voicePhase == _VoiceAssistantPhase.processing ||
            _session?.phase == AssistantSessionPhase.understanding
      ? const Color(0xFFF59E0B)
      : (_session?.recommendations.isNotEmpty == true ||
            _legacyMatches.isNotEmpty)
      ? const Color(0xFF60A5FA)
      : const Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsRecognitionController = widget.recognitionController == null;
    _recognitionController =
        widget.recognitionController ?? AutomaticVoiceRecognitionController();
    _ownsSpeechOutputController = widget.speechOutputController == null;
    _speechOutputController =
        widget.speechOutputController ?? NativeSpeechOutputController();
    _ownsSessionController = widget.sessionController == null;
    if (widget.sessionController != null) {
      _sessionController = widget.sessionController;
    } else if (widget.schemes.isNotEmpty) {
      final engine =
          widget.understandingEngine ?? EdgeSlmUnderstandingEngine.standard();
      _ownsUnderstandingEngine = widget.understandingEngine == null;
      if (engine is EdgeSlmUnderstandingEngine) {
        _edgeSlmEngine = engine;
        engine.addListener(_handleEdgeSlmChanged);
        unawaited(engine.prepare());
      }
      _sessionController = AssistantSessionController(
        engine: engine,
        schemes: widget.schemes,
        profile: widget.profile ?? UserProfile(),
      );
    }
    _sessionController?.addListener(_handleSessionChanged);
    if (widget.voiceAgentController != null) {
      _voiceAgentController = widget.voiceAgentController;
    } else if (_sessionController != null) {
      _voiceAgentController = LiveKitVoiceAgentController.tryFromSupabase(
        session: _sessionController!,
        profile: widget.profile ?? UserProfile(),
      );
      _ownsVoiceAgentController = _voiceAgentController != null;
    }
    _ownsGroundedSearch = widget.groundedSearch == null;
    _groundedSearch = widget.groundedSearch ?? HttpOfficialGroundedSearch();

    final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;
    _fallbackLanguage = deviceLanguage == 'ta'
        ? VoiceInputLanguage.tamil
        : VoiceInputLanguage.english;
    _edgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _edgeRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _edgeRevealController.addStatusListener(_handleEdgeBloomStatus);
    _edgeController.repeat();
    _edgeRevealController.forward();
    _edgeIntensity = ValueNotifier<double>(0.12);
    _soundLevel = ValueNotifier<double>(0.1);
    _edgeRepaint = Listenable.merge([
      _edgeController,
      _edgeRevealController,
      _edgeIntensity,
    ]);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.82,
      upperBound: 1,
      value: 1,
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_initializeSpeechOutput());
    _chatLogService.startSession();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => unawaited(_chatLogService.syncChatSession(mode: 'voice')),
      onHide: () => unawaited(_chatLogService.syncChatSession(mode: 'voice')),
      onDetach: () => unawaited(_chatLogService.syncChatSession(mode: 'voice')),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeVoiceAgent(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_voiceAgentController?.close());
      unawaited(_recognitionController.cancel());
      unawaited(_speechOutputController.stop());
      _setListeningAnimations(false);
    }
  }

  Future<void> _initializeVoiceAgent() async {
    if (!mounted) return;
    final agent = _voiceAgentController;
    if (agent != null) {
      agent.addListener(_handleVoiceAgentChanged);
      _voiceAgentEvents = agent.events.listen(_handleVoiceAgentEvent);
      try {
        await agent.initialize();
        await agent.connect();
        if (mounted && agent.state.usingCloud) {
          _handleVoiceAgentChanged();
          if (widget.initialText?.trim().isNotEmpty == true) {
            await agent.sendText(widget.initialText!.trim());
          }
          return;
        }
      } catch (_) {
        await agent.close();
        // Cloud voice is unavailable.
        if (mounted) {
          setState(() {
            // Unused fallback reason removed
          });
        }
      }
    }
    if (widget.initialText?.trim().isNotEmpty == true) {
      final value = widget.initialText!.trim();
      if (mounted) setState(() => _transcript = value);
      await _processFinalTranscript(value);
    } else if (widget.autoStart) {
      await _startListening();
    } else if (mounted) {
      setState(() => _voicePhase = _VoiceAssistantPhase.ready);
    }
  }

  void _handleEdgeSlmChanged() {
    if (mounted) setState(() {});
  }

  void _handleVoiceAgentChanged() {
    if (!mounted || _voiceAgentController == null) return;
    final state = _voiceAgentController!.state;
    if (!state.usingCloud) return;
    final level = state.audioLevel.clamp(0.0, 1.0);
    _soundLevel.value = level;
    _edgeIntensity.value = math.max(0.18, level);
    _setListeningAnimations(state.isListening && !state.isMuted);
    setState(() {
      _voicePhase = state.isListening && !state.isMuted
          ? _VoiceAssistantPhase.listening
          : state.isSpeaking
          ? _VoiceAssistantPhase.processing
          : _VoiceAssistantPhase.ready;
      _speaking = state.isSpeaking;
      if (state.inputTranscript.isNotEmpty) {
        _transcript = state.inputTranscript;
      }
      _message = state.message;
    });
  }

  void _handleVoiceAgentEvent(VoiceAgentEvent event) {
    if (!mounted) return;
    if (event.type == VoiceAgentEventType.inputTranscriptDelta ||
        event.type == VoiceAgentEventType.inputTranscriptDone) {
      _upsertTranscriptTurn(event, _VoiceTranscriptSpeaker.user);
      return;
    }
    if (event.type == VoiceAgentEventType.outputTranscriptDelta ||
        event.type == VoiceAgentEventType.outputTranscriptDone) {
      _upsertTranscriptTurn(event, _VoiceTranscriptSpeaker.assistant);
      return;
    }
    if (event.type == VoiceAgentEventType.schemeResults) {
      final raw = event.data?['results'];
      final results = raw is List<CloudSchemeResult>
          ? raw
          : const <CloudSchemeResult>[];
      final schemes = matchCloudSchemeResultsToCatalog(results, widget.schemes);
      final userTurns = _conversationTurns
          .where((turn) => turn.speaker == _VoiceTranscriptSpeaker.user)
          .map((turn) => turn.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(growable: false);
      final recentQuery = userTurns
          .skip(math.max(0, userTurns.length - 3))
          .join(' ');
      final locallyRanked = IntelligentSchemeSearch.rank(
        recentQuery,
        schemes,
        limit: 3,
      );
      final matches = locallyRanked
          .map((ranked) {
            final scheme = ranked.scheme;
            final metadata = results.cast<CloudSchemeResult?>().firstWhere(
              (result) =>
                  result?.id == scheme.id ||
                  result?.code == scheme.schemeCode ||
                  result?.name == scheme.name,
              orElse: () => null,
            );
            final confidence = metadata?.matchConfidence;
            return SchemeSearchMatch(
              scheme: scheme,
              score: ranked.score,
              reasons: [
                if (confidence != null) _l10n.voiceRelevanceMatch(confidence),
                ...ranked.reasons,
              ],
            );
          })
          .toList(growable: false);
      if (matches.isEmpty) return;
      setState(() {
        if (_conversationTurns.isNotEmpty &&
            _conversationTurns.last.speaker ==
                _VoiceTranscriptSpeaker.assistant) {
          _conversationTurns[_conversationTurns.length - 1] = _conversationTurns
              .last
              .copyWith(schemeMatches: matches);
          
          final schemeNames = matches.map((m) => m.scheme.name).toList();
          _chatLogService.upsertMessage(
            id: _conversationTurns.last.id,
            speaker: ChatMessageSpeaker.assistant,
            text: _conversationTurns.last.text,
            recommendations: schemeNames,
          );
        } else {
          _pendingCloudMatches = matches;
        }
      });
      _scrollToLatestTurn();
      return;
    }
    if (event.type == VoiceAgentEventType.recoverableError ||
        event.type == VoiceAgentEventType.fatalError) {
      setState(() {
        // Cloud voice disconnected.
      });
      unawaited(_fallBackToLocalVoice());
    }
  }

  void _upsertTranscriptTurn(
    VoiceAgentEvent event,
    _VoiceTranscriptSpeaker speaker, {
    List<String>? recommendations,
  }) {
    final text = event.text?.trim() ?? '';
    if (text.isEmpty) return;
    final suppliedId = event.data?['messageId'];
    final id = suppliedId is String && suppliedId.trim().isNotEmpty
        ? suppliedId.trim()
        : '${speaker.name}-${_fallbackTranscriptId++}';
    
    final pendingMatches = speaker == _VoiceTranscriptSpeaker.assistant
        ? _pendingCloudMatches
        : const <SchemeSearchMatch>[];
        
    _chatLogService.upsertMessage(
      id: id,
      speaker: speaker == _VoiceTranscriptSpeaker.user
          ? ChatMessageSpeaker.user
          : ChatMessageSpeaker.assistant,
      text: text,
      recommendations: recommendations ?? (pendingMatches.isNotEmpty 
          ? pendingMatches.map((m) => m.scheme.name).toList() 
          : null),
    );
    final index = _conversationTurns.indexWhere((turn) => turn.id == id);

    setState(() {
      if (index >= 0) {
        _conversationTurns[index] = _conversationTurns[index].copyWith(
          text: text,
          schemeMatches: pendingMatches.isEmpty ? null : pendingMatches,
        );
      } else {
        _conversationTurns.add(
          _VoiceTranscriptTurn(
            id: id,
            speaker: speaker,
            text: text,
            schemeMatches: pendingMatches,
          ),
        );
        if (_conversationTurns.length > 12) {
          _conversationTurns.removeAt(0);
        }
      }
      if (speaker == _VoiceTranscriptSpeaker.user) {
        _transcript = text;
      } else if (pendingMatches.isNotEmpty) {
        _pendingCloudMatches = const [];
      }
    });
    _scrollToLatestTurn();
  }

  void _scrollToLatestTurn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_panelScrollController.hasClients) return;
      _panelScrollController.animateTo(
        _panelScrollController.position.maxScrollExtent,
        duration: _reduceEdgeMotion
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _replyAlreadyInTranscript(GroundedAssistantReply reply) {
    final expected = reply.displayText.trim().toLowerCase();
    if (expected.isEmpty) return false;
    return _conversationTurns.reversed.any(
      (turn) =>
          turn.speaker == _VoiceTranscriptSpeaker.assistant &&
          turn.text.trim().toLowerCase() == expected,
    );
  }

  Future<void> _fallBackToLocalVoice() async {
    if (_fallingBackToLocal || _closing) return;
    _fallingBackToLocal = true;
    await _voiceAgentController?.close();
    if (mounted && !_closing) {
      setState(() {
        // Cloud voice disconnected.
      });
      await _startListening(preserveTranscript: _transcript.isNotEmpty);
    }
    _fallingBackToLocal = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion == _reduceEdgeMotion) return;
    _reduceEdgeMotion = reduceMotion;
    if (reduceMotion) {
      _edgeController.stop();
      _edgeController.value = 0;
      _edgeRevealController.stop();
      _edgeRevealController.value = 0.5;
    } else {
      _startEdgeBloom();
    }
  }

  void _handleEdgeBloomStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _edgeController.stop();
  }

  void _startEdgeBloom() {
    if (_reduceEdgeMotion) return;
    if (!_edgeController.isAnimating) _edgeController.repeat();
    _edgeRevealController.forward(from: 0);
  }

  Future<void> _initializeSpeechOutput() async {
    final capabilities = await _speechOutputController.initialize();
    if (mounted) setState(() => _speechCapabilities = capabilities);
  }

  void _handleSessionChanged() {
    if (!mounted) return;
    final state = _sessionController!.state;
    setState(() {
      if (state.statement != _recommendationStatement) {
        _recommendationStatement = state.statement;
        _showAllRecommendations = false;
      }
      _message = state.message;
      if (state.latestTranscript.isNotEmpty) {
        _transcript = state.latestTranscript;
      }
      if (state.phase == AssistantSessionPhase.understanding) {
        _groundingGeneration++;
        _groundingKey = null;
        _groundingPhase = _OnlineGroundingPhase.idle;
        _groundedSources = const [];
      }
    });
    if ((state.phase == AssistantSessionPhase.results ||
            state.phase == AssistantSessionPhase.noConfidentMatch) &&
        state.reply != null) {
      _startOnlineGrounding(state);
    }
    if (_cloudSessionInUse) return;
    final reply = state.reply;
    final question = state.question;
    final turnKey = [
      state.statement,
      state.questionsAsked,
      reply?.topic,
      question?.factKey.name,
    ].join('|');
    if (_lastSpokenTurn == turnKey) return;
    if (state.phase == AssistantSessionPhase.asking && question != null) {
      _lastSpokenTurn = turnKey;
      _upsertTranscriptTurn(
        VoiceAgentEvent(
          VoiceAgentEventType.outputTranscriptDone,
          text: _questionText(state, question),
          data: {'messageId': 'local-assistant-$turnKey'},
        ),
        _VoiceTranscriptSpeaker.assistant,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_speakQuestionAndListen());
      });
    } else if ((state.phase == AssistantSessionPhase.results ||
            state.phase == AssistantSessionPhase.noConfidentMatch) &&
        reply != null) {
      _lastSpokenTurn = turnKey;
      final schemeNames = state.recommendations.map((r) => r.scheme.name).toList();
      _upsertTranscriptTurn(
        VoiceAgentEvent(
          VoiceAgentEventType.outputTranscriptDone,
          text: reply.displayText,
          data: {'messageId': 'local-assistant-$turnKey'},
        ),
        _VoiceTranscriptSpeaker.assistant,
        recommendations: schemeNames.isNotEmpty ? schemeNames : null,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_speakReply(reply));
      });
    }
  }

  void _startOnlineGrounding(AssistantSessionState state) {
    final reply = state.reply;
    if (reply == null) return;
    final urls = <String>[];
    final labels = <String, String>{};
    void addSource(String url, String label) {
      final value = url.trim();
      if (value.isEmpty || urls.contains(value)) return;
      urls.add(value);
      labels[value] = label;
    }

    addSource(reply.sourceUrl, reply.sourceLabel);
    for (final recommendation in state.recommendations.take(3)) {
      addSource(recommendation.scheme.sourceUrl, recommendation.scheme.name);
    }
    if (urls.isEmpty) return;
    final key = '${reply.topic}|${urls.join('|')}';
    if (_groundingKey == key) return;
    _groundingKey = key;
    final generation = ++_groundingGeneration;
    setState(() {
      _groundingPhase = _OnlineGroundingPhase.checking;
      _groundedSources = const [];
    });
    unawaited(
      _groundedSearch
          .search(
            GroundedSearchRequest(
              topic: reply.topic,
              sourceUrls: urls,
              sourceLabels: labels,
            ),
          )
          .then((result) {
            if (!mounted || generation != _groundingGeneration) return;
            setState(() {
              _groundedSources = result.sources;
              _groundingPhase = switch (result.outcome) {
                GroundedSearchOutcome.found => _OnlineGroundingPhase.found,
                GroundedSearchOutcome.offline =>
                  _OnlineGroundingPhase.unavailable,
                GroundedSearchOutcome.noSources =>
                  _OnlineGroundingPhase.noSources,
              };
            });
          }),
    );
  }

  Future<void> _startListening({bool preserveTranscript = false}) async {
    if (!mounted || _startingRecognition || _speaking) return;
    if (_cloudSessionInUse) {
      await _voiceAgentController!.setMuted(false);
      return;
    }
    _startingRecognition = true;
    _operationGeneration++;
    _recognitionGeneration++;
    _lastFinalTranscript = null;
    _lastFinalRecognitionGeneration = -1;
    await _speechOutputController.stop();
    if (!mounted) return;
    _setListeningAnimations(false);
    setState(() {
      _voicePhase = _VoiceAssistantPhase.starting;
      _message = null;
      if (!preserveTranscript) _transcript = '';
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
        _edgeIntensity.value = 0.12;
        _setListeningAnimations(false);
        setState(() {
          _voicePhase = _VoiceAssistantPhase.unavailable;
          _message =
              capabilities.reason ?? _l10n.voiceRecognitionUnavailable;
        });
        return;
      }

      final useFallback = !capabilities.automaticLanguageDetection;
      final isUnavailableReason =
          capabilities.reason?.contains('unavailable') == true;
      setState(() {
        _voicePhase = _VoiceAssistantPhase.listening;
        _message = (useFallback && isUnavailableReason)
            ? capabilities.reason
            : null;
        _showFallbackPicker = useFallback;
      });
      _sessionController?.setListening(
        transcript: preserveTranscript ? _transcript : '',
      );
      _edgeIntensity.value = 0.25;
      _setListeningAnimations(true);
      await _recognitionController.listen(
        localeId: useFallback ? _fallbackLocaleId : null,
      );
      if (mounted && !_recognitionController.isListening) {
        _edgeIntensity.value = 0.12;
        _setListeningAnimations(false);
      }
    } catch (_) {
      if (!mounted) return;
      _edgeIntensity.value = 0.12;
      _setListeningAnimations(false);
      setState(() {
        _voicePhase = _VoiceAssistantPhase.unavailable;
        _message = _l10n.voiceRecognitionStartFailed;
      });
    } finally {
      _startingRecognition = false;
    }
  }

  String get _fallbackLocaleId =>
      _fallbackLanguage == VoiceInputLanguage.tamil ? 'ta-IN' : 'en-IN';

  void _handleResult(VoiceRecognitionResult result) {
    if (!mounted) return;
    final transcript = result.transcript.trim();
    if (_transcript == transcript && !result.isFinal) return;
    setState(() {
      _transcript = transcript;
      if (result.isFinal) {
        _voicePhase = _VoiceAssistantPhase.ready;
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
    _upsertTranscriptTurn(
      VoiceAgentEvent(
        VoiceAgentEventType.inputTranscriptDone,
        text: transcript,
        data: {'messageId': 'local-user-$_recognitionGeneration'},
      ),
      _VoiceTranscriptSpeaker.user,
    );
    unawaited(_processFinalTranscript(transcript));
  }

  Future<void> _processFinalTranscript(String transcript) async {
    final value = transcript.trim();
    final normalized = PrivateAiKnowledgeBase.normalizeForUnderstanding(value);
    if (normalized.isEmpty) return;
    final session = _sessionController;
    if (session != null) {
      if (session.state.question != null) {
        await session.answer(value);
      } else {
        _lastSpokenTurn = null;
        await session.start(value, isTamil: _presentInTamil);
      }
      return;
    }
    await _legacySearch(value);
  }

  Future<void> _legacySearch(String query) async {
    final search = widget.onSearch;
    if (search == null || query.trim().isEmpty) {
      widget.onSubmit(query);
      return;
    }
    final generation = ++_operationGeneration;
    setState(() {
      _legacySearching = true;
      _legacyMatches = const [];
      _message = null;
    });
    try {
      final matches = await search(query);
      if (!mounted || generation != _operationGeneration) return;
      setState(() {
        _legacySearching = false;
        _legacyMatches = matches;
      });
    } catch (_) {
      if (!mounted || generation != _operationGeneration) return;
      setState(() {
        _legacySearching = false;
        _legacyMatches = const [];
        _message = _l10n.voiceSearchFailed;
      });
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
    _edgeIntensity.value = math.max(0.25, normalizedLevel);
  }

  void _handleLanguage(String language) {
    if (!mounted || language == _detectedLanguage) return;
    setState(() => _detectedLanguage = language);
  }

  void _handleError(VoiceRecognitionError error) {
    if (!mounted) return;
    _edgeIntensity.value = 0.12;
    _soundLevel.value = 0.1;
    _setListeningAnimations(false);
    setState(() {
      _voicePhase = _VoiceAssistantPhase.unavailable;
      if (error.automaticUnavailable) {
        _showFallbackPicker = true;
      }
      _message = error.message;
    });
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      _startEdgeBloom();
      _edgeIntensity.value = 0.25;
      _setListeningAnimations(true);
      if (_voicePhase != _VoiceAssistantPhase.listening) {
        setState(() => _voicePhase = _VoiceAssistantPhase.listening);
      }
    } else if (status == 'processing') {
      _edgeIntensity.value = 0.16;
      _soundLevel.value = 0.1;
      _setListeningAnimations(false);
      if (_voicePhase != _VoiceAssistantPhase.processing) {
        setState(() => _voicePhase = _VoiceAssistantPhase.processing);
      }
    } else if (status == 'done' || status == 'notListening') {
      _edgeIntensity.value = 0.12;
      _soundLevel.value = 0.1;
      _setListeningAnimations(false);
      if (_voicePhase == _VoiceAssistantPhase.listening) {
        setState(() => _voicePhase = _VoiceAssistantPhase.ready);
      }
    }
  }

  Future<void> _stopListening() async {
    _operationGeneration++;
    if (_cloudSessionInUse) {
      await _voiceAgentController!.setMuted(true);
      if (!mounted) return;
      _edgeIntensity.value = 0.12;
      _soundLevel.value = 0.1;
      _setListeningAnimations(false);
      setState(() => _voicePhase = _VoiceAssistantPhase.ready);
      return;
    }
    await _recognitionController.stop();
    if (!mounted) return;
    _edgeIntensity.value = 0.12;
    _soundLevel.value = 0.1;
    _setListeningAnimations(false);
    setState(() => _voicePhase = _VoiceAssistantPhase.ready);
  }

  Future<void> _toggleListening() async {
    if (_cloudSessionInUse && _speaking) {
      await _voiceAgentController!.interrupt();
      await _voiceAgentController!.setMuted(false);
      return;
    }
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening(preserveTranscript: _session?.question != null);
    }
  }

  Future<void> _changeLanguage(VoiceInputLanguage language) async {
    if (_fallbackLanguage == language && _isListening) return;
    _operationGeneration++;
    await _recognitionController.cancel();
    if (!mounted) return;
    setState(() {
      _fallbackLanguage = language;
      _detectedLanguage = language == VoiceInputLanguage.tamil
          ? 'ta-IN'
          : 'en-IN';
      _message = null;
      _voicePhase = _VoiceAssistantPhase.ready;
    });
    await _startListening(preserveTranscript: _session?.question != null);
  }

  Future<void> _speakQuestionAndListen() async {
    if (_cloudSessionInUse) return;
    final state = _session;
    final question = state?.question;
    if (state == null || question == null || _speaking) return;
    await _recognitionController.cancel();
    if (!mounted) return;
    final reply = state.reply;
    final languageTag =
        reply?.languageTag ?? (state.isTamil ? 'ta-IN' : 'en-IN');
    final supported = _speechCapabilities?.supports(languageTag) ?? false;
    if (!supported) return;
    final generation = ++_operationGeneration;
    setState(() {
      _speaking = true;
      _voicePhase = _VoiceAssistantPhase.ready;
    });
    final questionText = _questionText(state, question);
    final spokenText = reply == null
        ? questionText
        : '${reply.spokenText} $questionText';
    final completed = await _speechOutputController.speak(
      spokenText,
      languageTag: languageTag,
    );
    if (!mounted || generation != _operationGeneration) return;
    setState(() => _speaking = false);
    if (completed) {
      // Give Android audio focus a moment to move from TTS back to the mic.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted && generation == _operationGeneration) {
        await _startListening(preserveTranscript: true);
      }
    }
  }

  Future<void> _speakReply(GroundedAssistantReply reply) async {
    if (_cloudSessionInUse || _speaking || reply.spokenText.trim().isEmpty) {
      return;
    }
    await _recognitionController.cancel();
    if (!mounted) return;
    final supported = _speechCapabilities?.supports(reply.languageTag) ?? false;
    if (!supported) return;
    final generation = ++_operationGeneration;
    setState(() {
      _speaking = true;
      _voicePhase = _VoiceAssistantPhase.ready;
    });
    await _speechOutputController.speak(
      reply.spokenText,
      languageTag: reply.languageTag,
    );
    if (!mounted || generation != _operationGeneration) return;
    setState(() => _speaking = false);
  }

  String _questionText(AssistantSessionState state, FollowUpQuestion question) {
    final tamil =
        state.isTamil || RegExp(r'[\u0B80-\u0BFF]').hasMatch(state.statement);
    return tamil ? question.tamil : question.english;
  }

  Future<void> _answerOption(String option) async {
    await _recognitionController.cancel();
    await _speechOutputController.stop();
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _transcript = option;
    });
    _upsertTranscriptTurn(
      VoiceAgentEvent(
        VoiceAgentEventType.inputTranscriptDone,
        text: option,
        data: {'messageId': 'option-${_session?.questionsAsked ?? 0}'},
      ),
      _VoiceTranscriptSpeaker.user,
    );
    await _sessionController?.answer(option);
  }

  Future<void> _useSuggestion(String query) async {
    await _recognitionController.cancel();
    if (!mounted) return;
    setState(() {
      _voicePhase = _VoiceAssistantPhase.ready;
      _transcript = query;
      _message = null;
    });
    _upsertTranscriptTurn(
      VoiceAgentEvent(
        VoiceAgentEventType.inputTranscriptDone,
        text: query,
        data: {'messageId': 'suggestion-${_fallbackTranscriptId++}'},
      ),
      _VoiceTranscriptSpeaker.user,
    );
    if (_cloudSessionInUse) {
      await _voiceAgentController!.sendText(query);
    } else {
      await _processFinalTranscript(query);
    }
  }

  Future<void> _sendTypedInput() async {
    final value = _typedController.text.trim();
    if (value.isEmpty) return;
    _typedController.clear();
    await _recognitionController.cancel();
    if (_cloudSessionInUse) {
      await _voiceAgentController!.sendText(value);
    } else {
      setState(() => _transcript = value);
      _upsertTranscriptTurn(
        VoiceAgentEvent(
          VoiceAgentEventType.inputTranscriptDone,
          text: value,
          data: {'messageId': 'typed-${_fallbackTranscriptId++}'},
        ),
        _VoiceTranscriptSpeaker.user,
      );
      await _processFinalTranscript(value);
    }
  }

  Future<void> _editFact(EligibilityFact fact) async {
    final controller = TextEditingController(text: fact.value);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          _l10n.voiceEditFact(_factLabel(context, fact.key)),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          key: const Key('voice-fact-editor'),
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(CentralizedTranslator.instance.translate('Use value')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) {
      await _sessionController?.editFact(fact.key, value);
    }
  }

  Future<void> _reviewAndSaveFacts() async {
    final controller = _sessionController;
    final callback = widget.onProfileConfirmed;
    if (controller == null || callback == null) return;
    final candidates = controller.state.facts.values
        .where((fact) => fact.source != EligibilityFactSource.profile)
        .where(
          (fact) => !{
            EligibilityFactKey.age,
            EligibilityFactKey.maritalStatus,
            EligibilityFactKey.studentStatus,
            EligibilityFactKey.landholding,
          }.contains(fact.key),
        )
        .toList(growable: false);
    if (candidates.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('voice-profile-review'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          _l10n.voiceReviewProfileUpdates,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: candidates
                .map(
                  (fact) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_factLabel(context, fact.key)),
                    subtitle: Text(fact.value),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: Text(_l10n.voiceKeepSessionOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(_l10n.voiceSaveConfirmed),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final fact in candidates) {
      controller.confirmFact(fact.key);
    }
    callback(controller.buildUpdatedProfile());
    if (mounted) {
      setState(() => _message = _l10n.voiceProfileSavedMessage);
    }
  }

  void _setListeningAnimations(bool listening) {
    if (listening) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 1;
      _waveController.stop();
      _waveController.value = 0;
    }
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _operationGeneration++;
    _sessionController?.cancel();
    // Navigation must never wait for an OEM speech service to acknowledge
    // cancellation. Disposal still performs the full native cleanup.
    unawaited(_speechOutputController.stop());
    unawaited(_recognitionController.cancel());
    unawaited(_voiceAgentController?.close());
    unawaited(_chatLogService.syncChatSession(mode: 'voice'));
    widget.onClose();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    // Note: _close() is always called before dispose() and already triggers
    // syncChatSession(). No need to call it again here.
    WidgetsBinding.instance.removeObserver(this);
    _voiceAgentController?.removeListener(_handleVoiceAgentChanged);
    unawaited(_voiceAgentEvents?.cancel());
    if (_ownsVoiceAgentController) {
      unawaited(_voiceAgentController?.dispose());
    } else {
      unawaited(_voiceAgentController?.close());
    }
    _sessionController?.removeListener(_handleSessionChanged);
    if (_ownsSessionController) _sessionController?.dispose();
    _groundingGeneration++;
    if (_ownsGroundedSearch) _groundedSearch.close();
    _edgeSlmEngine?.removeListener(_handleEdgeSlmChanged);
    if (_ownsUnderstandingEngine) {
      unawaited(_edgeSlmEngine?.close());
    }
    if (_ownsRecognitionController) {
      unawaited(_recognitionController.dispose());
    } else {
      unawaited(_recognitionController.cancel());
    }
    if (_ownsSpeechOutputController) {
      unawaited(_speechOutputController.dispose());
    } else {
      unawaited(_speechOutputController.stop());
    }
    _edgeController.dispose();
    _edgeRevealController.removeStatusListener(_handleEdgeBloomStatus);
    _edgeRevealController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _edgeIntensity.dispose();
    _soundLevel.dispose();
    _typedController.dispose();
    _panelScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCompanion) return _buildRegularVoiceExperience(context);
    final media = MediaQuery.of(context);
    final edgeRadius = math.max(26.0, media.viewPadding.top + 10);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        unawaited(_chatLogService.syncChatSession(mode: 'voice'));
      },
      child: Material(
        key: const Key('voice-assistant-overlay'),
        color: Colors.transparent,
        child: Stack(
          children: [
            const Positioned.fill(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  systemStatusBarContrastEnforced: false,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  systemNavigationBarIconBrightness: Brightness.light,
                  systemNavigationBarContrastEnforced: false,
                ),
                child: SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xFF020617).withValues(alpha: 0.10),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    key: const Key('voice-edge-outline'),
                    animation: _edgeRepaint,
                    builder: (context, child) => CustomPaint(
                      isComplex: true,
                      willChange: true,
                      painter: VoiceEdgePainter(
                        entranceProgress: _edgeRevealController.value,
                        ambientProgress: _edgeController.value,
                        activityIntensity: _edgeIntensity.value,
                        activity: _edgeActivity,
                        radius: edgeRadius,
                        reduceMotion: _reduceEdgeMotion,
                        companion: _isCompanion,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 620,
                    maxHeight: math.min(media.size.height * 0.86, 760),
                  ),
                  child: Container(
                    key: const Key('voice-assistant-panel'),
                    decoration: BoxDecoration(
                      color:
                          (_isCompanion
                                  ? const Color(0xFF1C1008)
                                  : const Color(0xFF07111F))
                              .withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.34),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66020A16),
                          blurRadius: 30,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: _panelScrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: AppSpacing.md),
                          _buildListeningArea(),
                          if (_conversationTurns.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildConversationTranscript(),
                          ],
                          if (_cloudSessionInUse) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              key: const Key('voice-cloud-disclosure'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_outlined,
                                  size: 13,
                                  color: _accent,
                                ),
                                const SizedBox(width: AppSpacing.tight),
                                Flexible(
                                  child: Text(
                                    _l10n.voiceNoiseControlSecure,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFCBD5E1),
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_message != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _message!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFCA5A5),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                          if (_session?.reply case final reply?
                              when !_replyAlreadyInTranscript(reply)) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildAssistantReply(reply),
                          ],
                          if (_groundingPhase !=
                              _OnlineGroundingPhase.idle) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _buildOnlineGrounding(),
                          ],
                          if (_session?.facts.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildFactChips(),
                          ],
                          if (_session?.question != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildQuestionCard(_session!.question!),
                          ],
                          if (_legacySearching ||
                              _session?.phase ==
                                  AssistantSessionPhase.understanding) ...[
                            const SizedBox(height: AppSpacing.md),
                            LinearProgressIndicator(
                              key: Key('voice-search-progress'),
                              minHeight: 2,
                              color: _accent,
                              backgroundColor: _accent.withValues(alpha: 0.20),
                            ),
                          ] else if (_session?.recommendations.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildConversationalResults(),
                          ] else if (_legacyMatches.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildLegacyResults(),
                          ] else if (_session?.phase ==
                                  AssistantSessionPhase.noConfidentMatch ||
                              (_transcript.isNotEmpty &&
                                  !_hasConversation &&
                                  !_legacySearching)) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _l10n.voiceNoConfidentMatch,
                              key: const Key('voice-no-results'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFBBF24),
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (_session?.excludedUncertainCount case final count?
                              when count > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            TextButton.icon(
                              key: const Key('voice-show-uncertain'),
                              onPressed: () =>
                                  _sessionController?.setIncludeUncertain(true),
                              icon: const Icon(Icons.info_outline, size: 15),
                              label: Text(
                                _l10n.voiceSeeUncertainSchemes(count),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularVoiceExperience(BuildContext context) {
    final media = MediaQuery.of(context);
    final hasConversation = _conversationTurns.isNotEmpty;
    final isGenerating =
        _voicePhase == _VoiceAssistantPhase.processing ||
        _session?.phase == AssistantSessionPhase.understanding ||
        _legacySearching;
    return Material(
      key: const Key('voice-assistant-overlay'),
      color: const Color(0xFF070A12),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF070A12),
          systemNavigationBarIconBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _RegularVoiceBackdrop()),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    key: const Key('voice-edge-outline'),
                    animation: _edgeRepaint,
                    builder: (context, child) => CustomPaint(
                      painter: _RegularVoiceAmbientPainter(
                        progress: _edgeController.value,
                        intensity: _edgeIntensity.value,
                        active: _isListening || _speaking || isGenerating,
                        reduceMotion: _reduceEdgeMotion,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Container(
                key: const Key('voice-assistant-panel'),
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  media.size.width < 360 ? AppSpacing.lg : AppSpacing.xl,
                  AppSpacing.sm,
                  media.size.width < 360 ? AppSpacing.lg : AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    _buildRegularTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _panelScrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xl,
                          bottom: AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildRegularPresence(isGenerating),
                            const SizedBox(height: 28),
                            if (!hasConversation)
                              _buildRegularWelcome()
                            else
                              Container(
                                key: _session?.reply != null
                                    ? const Key('voice-assistant-reply')
                                    : null,
                                child: _buildRegularTranscript(),
                              ),
                            if (_message != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _buildRegularNotice(_message!),
                            ],
                            if (_session?.question case final question?) ...[
                              const SizedBox(height: AppSpacing.xl),
                              _buildRegularQuestionCard(question),
                            ],
                            if (_session?.recommendations.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 22),
                              _buildRegularRecommendations(),
                            ] else if (_legacyMatches.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildRegularLegacyResults(),
                            ] else if (_session?.phase ==
                                    AssistantSessionPhase.noConfidentMatch ||
                                (_transcript.isNotEmpty &&
                                    !_hasConversation &&
                                    !_legacySearching)) ...[
                              const SizedBox(height: 18),
                              Text(
                                _l10n.voiceNeedOneMoreDetail,
                                key: const Key('voice-no-results'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFA8B0C2),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (_groundingPhase !=
                                _OnlineGroundingPhase.idle) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _buildOnlineGrounding(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildRegularControls(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularTopBar() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D5DFB), Color(0xFF36C5F0)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.askAi,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Semantics(
                liveRegion: true,
                label: _statusLabel,
                child: Text(
                  _statusLabel,
                  key: const Key('voice-live-status'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFA8B0C2),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildLanguageSelector(),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          key: const Key('voice-close-button'),
          tooltip: _l10n.voiceCancelAssistantTooltip,
          onPressed: _close,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: const Color(0xFFD7DCE8),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildRegularPresence(bool isGenerating) {
    final active = _isListening || _speaking || isGenerating;
    return Center(
      child: Semantics(
        image: true,
        label: active ? _statusLabel : _l10n.voiceAiReady,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: active ? 154 : 138,
          height: active ? 154 : 138,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8B7CFF).withValues(alpha: active ? 0.95 : 0.72),
                const Color(0xFF3E7BFA).withValues(alpha: 0.58),
                const Color(0xFF17C4D8).withValues(alpha: 0.08),
              ],
              stops: const [0, 0.52, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF6D5DFB,
                ).withValues(alpha: active ? 0.42 : 0.20),
                blurRadius: active ? 54 : 34,
                spreadRadius: active ? 10 : 2,
              ),
            ],
          ),
          child: Center(
            child: VoiceLevelBars(
              key: const Key('voice-level-bars'),
              animation: _waveController,
              level: _soundLevel,
              active: _isListening,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularWelcome() {
    return Column(
      children: [
        Text(
          _l10n.howCanIHelp,
          key: const Key('voice-transcript'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _l10n.voiceTellMeSituationFindSchemes,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA6BA),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _suggestionChip(_l10n.voiceSuggestionBusinessLoans),
            _suggestionChip(_l10n.voiceSuggestionCollegeScholarship),
            _suggestionChip(_l10n.voiceSuggestionFarmerSubsidy),
          ],
        ),
      ],
    );
  }

  Widget _buildRegularTranscript() {
    final visibleTurns = _conversationTurns.length <= 3
        ? _conversationTurns
        : _conversationTurns.sublist(_conversationTurns.length - 3);
    return Semantics(
      container: true,
      label: _l10n.voiceConversationTranscript,
      child: Column(
        key: const Key('voice-conversation-transcript'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final turn in visibleTurns) _buildRegularTurn(turn)],
      ),
    );
  }

  Widget _buildRegularTurn(_VoiceTranscriptTurn turn) {
    final isUser = turn.speaker == _VoiceTranscriptSpeaker.user;
    final label = isUser ? _l10n.voiceSpeakerYou : _l10n.voiceSpeakerAssistant;
    return Container(
      key: Key('voice-turn-${turn.id}'),
      margin: const EdgeInsets.only(bottom: 22),
      padding: EdgeInsets.only(left: isUser ? 34 : AppSpacing.none),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isUser ? const Color(0xFF7F8AA1) : const Color(0xFF8B9BFF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            turn.text,
            textAlign: isUser ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.inter(
              color: isUser ? const Color(0xFFC5CBD8) : const Color(0xFFF4F6FA),
              fontSize: isUser ? 15 : 17,
              fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
              height: 1.48,
              letterSpacing: -0.15,
            ),
          ),
          if (turn.schemeMatches.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...turn.schemeMatches.take(3).map(_buildTurnSchemeCard),
          ],
        ],
      ),
    );
  }

  Widget _buildRegularNotice(String text) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF151A27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3142)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFFD4D9E5),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildRegularQuestionCard(FollowUpQuestion question) {
    final state = _session!;
    return Container(
      key: const Key('voice-follow-up-question'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF111624),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF303A58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _questionText(state, question),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.options
                  .map(
                    (option) => ActionChip(
                      key: Key(
                        'voice-answer-${option.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      label: Text(option),
                      onPressed: () => _answerOption(option),
                      backgroundColor: const Color(0xFF222A42),
                      side: const BorderSide(color: Color(0xFF46537B)),
                      labelStyle: const TextStyle(
                        color: Color(0xFFF2F4F8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (_speechCapabilities?.supports(
                state.isTamil ? 'ta-IN' : 'en-IN',
              ) ==
              false) ...[
            const SizedBox(height: 10),
            Text(
              _l10n.voiceSpeechOutputUnavailable,
              style: GoogleFonts.inter(
                color: const Color(0xFFFFC46B),
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegularRecommendations() {
    final all = _session!.recommendations;
    final visible = _showAllRecommendations
        ? all
        : all.take(3).toList(growable: false);
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _l10n.voiceForYou,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _l10n.voiceFoundCount(all.length),
              key: const Key('voice-result-count'),
              style: GoogleFonts.inter(
                color: const Color(0xFF929DB2),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...visible.map(_buildRegularRecommendationCard),
        if (all.length > 3)
          TextButton.icon(
            key: const Key('voice-toggle-all-results'),
            onPressed: () => setState(
              () => _showAllRecommendations = !_showAllRecommendations,
            ),
            icon: Icon(
              _showAllRecommendations
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
            ),
            label: Text(
              _showAllRecommendations
                  ? _l10n.voiceShowTop3
                  : _l10n.voiceShowAllMatches(all.length),
            ),
          ),
        if (widget.onProfileConfirmed != null &&
            _session!.facts.values.any(
              (fact) => fact.source != EligibilityFactSource.profile,
            ))
          TextButton.icon(
            key: const Key('voice-review-profile'),
            onPressed: _reviewAndSaveFacts,
            icon: const Icon(Icons.tune_rounded, size: 17),
            label: Text(_l10n.voiceReviewDetails),
          ),
      ],
    );
  }

  Widget _buildRegularRecommendationCard(SchemeRecommendation recommendation) {
    final localized = recommendation.scheme.toLocalized(
      _presentInTamil ? 'ta' : 'en',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        key: Key('voice-result-${recommendation.scheme.id}'),
        onTap: () => widget.onSchemeSelected?.call(recommendation.scheme),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF111624),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF29334E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      localized.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 17,
                    color: Color(0xFF8B9BFF),
                  ),
                ],
              ),
              if (recommendation.reasons.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  _l10n.voiceWhyThisFits(
                    recommendation.reasons.join(' • '),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB7C0D2),
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.tight),
              Text(
                recommendation.isTrusted
                    ? _l10n.voiceSourceVerified
                    : _l10n.voiceConfirmEligibility,
                style: GoogleFonts.inter(
                  color: recommendation.isTrusted
                      ? const Color(0xFF70D6B2)
                      : const Color(0xFFFFC46B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegularLegacyResults() {
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _l10n.voiceForYou,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ..._legacyMatches.take(3).map(_buildTurnSchemeCard),
      ],
    );
  }

  Widget _buildRegularControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _speaking
              ? _l10n.voiceTapToInterrupt
              : _isListening
              ? _l10n.voiceStatusListening
              : _l10n.companionTapToSpeak,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFFA8B0C2),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        Semantics(
          button: true,
          label: _speaking
              ? _l10n.voiceSemInterrupt
              : _isListening
              ? _l10n.voiceStopListeningSemantic
              : _l10n.voiceStartListeningSemantic,
          hint: _l10n.voiceSemMicHint,
          onTap: _toggleListening,
          excludeSemantics: true,
          child: IconButton.filled(
            key: const Key('voice-primary-control'),
            onPressed: _toggleListening,
            style: IconButton.styleFrom(
              minimumSize: const Size(68, 68),
              backgroundColor: _isListening
                  ? const Color(0xFFF1F3F8)
                  : const Color(0xFF6D5DFB),
              foregroundColor: _isListening
                  ? const Color(0xFF121622)
                  : Colors.white,
              shadowColor: const Color(0xFF6D5DFB),
              elevation: 10,
            ),
            icon: Icon(
              _speaking
                  ? Icons.front_hand_rounded
                  : _isListening
                  ? Icons.stop_rounded
                  : Icons.mic_rounded,
              size: 28,
            ),
          ),
        ),
        if (_cloudSessionInUse) ...[
          const SizedBox(height: 9),
          Text(
            _l10n.voiceNoiseControlSecure,
            key: const Key('voice-cloud-disclosure'),
            style: GoogleFonts.inter(
              color: const Color(0xFF707A91),
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Semantics(
          image: true,
          label: _l10n.voiceAiAssistant,
          child: SizedBox(
            width: 56,
            height: 56,
            child: ClipOval(
              child: Image.asset(
                'assets/images/saarthi/sarathi.webp',
                key: const Key('voice-assistant-image'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCompanion ? _l10n.voiceHeaderTalkToSaarthi : _l10n.askAi,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Semantics(
                liveRegion: true,
                label: _statusLabel,
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tight),
                    Flexible(
                      child: FitOneLine(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _statusLabel,
                          key: const Key('voice-live-status'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
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
        _buildLanguageSelector(),
        if (_cloudSessionInUse)
          IconButton(
            key: const Key('voice-mute-button'),
            tooltip: _voiceAgentController!.state.isMuted
                ? _l10n.voiceUnmute
                : _l10n.voiceMute,
            onPressed: () => _voiceAgentController!.setMuted(
              !_voiceAgentController!.state.isMuted,
            ),
            icon: Icon(
              _voiceAgentController!.state.isMuted
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        IconButton(
          key: const Key('voice-close-button'),
          tooltip: _l10n.voiceCancelAssistantTooltip,
          onPressed: _close,
          icon: const Icon(Icons.close_rounded, color: Color(0xFFCBD5E1)),
        ),
      ],
    );
  }

  Widget _buildListeningArea() {
    final showSuggestions =
        _transcript.isEmpty && _session?.statement.isEmpty != false;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _conversationTurns.isNotEmpty
                ? (_speaking
                      ? _l10n.voiceListenOrInterrupt
                      : _isListening
                      ? _l10n.voiceSpeakNaturallyPause
                      : _l10n.voiceReadyForNextQuestion)
                : _transcript.isEmpty
                ? _l10n.voiceTellMeNaturally
                : _transcript,
            key: const Key('voice-transcript'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _transcript.isEmpty
                  ? const Color(0xFF94A3B8)
                  : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (showSuggestions) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.tight,
              runSpacing: AppSpacing.tight,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip(_l10n.voiceSuggestionBusinessLoans),
                _suggestionChip(_l10n.voiceSuggestionCollegeScholarship),
                _suggestionChip(_l10n.voiceSuggestionFarmerSubsidy),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _cloudSessionInUse
                      ? Semantics(
                          label: _l10n.voiceSemNoiseControlOn,
                          child: const Icon(
                            Icons.noise_control_off_rounded,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Semantics(
                button: true,
                label: _speaking
                    ? _l10n.voiceSemInterrupt
                    : _isListening
                    ? _l10n.voiceStopListeningSemantic
                    : _l10n.voiceStartListeningSemantic,
                hint: _l10n.voiceSemMicHint,
                onTap: _toggleListening,
                excludeSemantics: true,
                child: IconButton.filled(
                  key: const Key('voice-primary-control'),
                  onPressed: _toggleListening,
                  style: IconButton.styleFrom(
                    backgroundColor: _isListening
                        ? const Color(0xFF10B981)
                        : _accent,
                    minimumSize: const Size(56, 56),
                  ),
                  icon: Icon(
                    _speaking
                        ? Icons.front_hand_rounded
                        : _isListening
                        ? Icons.stop_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VoiceLevelBars(
                    key: const Key('voice-level-bars'),
                    animation: _waveController,
                    level: _soundLevel,
                    active: _isListening,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _speaking
                ? _l10n.companionInterrupt
                : _isListening
                ? _l10n.voiceTapWhenFinished
                : _l10n.companionTapToSpeak,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_cloudSessionInUse) ...[
            const SizedBox(height: AppSpacing.tight),
            Semantics(
              label: _l10n.voiceSemNoiseControlOn,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF34D399),
                    size: 13,
                  ),
                  const SizedBox(width: AppSpacing.tight),
                  Text(
                    _l10n.voiceDeviceNoiseControl,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6EE7B7),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isCompanion) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('voice-typed-input'),
                    controller: _typedController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTypedInput(),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _isCompanion
                          ? _l10n.voiceTypeToSaarthiHint
                          : _l10n.voiceTypeInstead,
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.tight),
                IconButton(
                  key: const Key('voice-send-text'),
                  tooltip: _l10n.voiceSendMessageTooltip,
                  onPressed: _sendTypedInput,
                  icon: Icon(Icons.send_rounded, color: _accent),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationTranscript() {
    final turnLimit = _isCompanion ? 8 : 3;
    final visibleTurns = _conversationTurns.length <= turnLimit
        ? _conversationTurns
        : _conversationTurns.sublist(_conversationTurns.length - turnLimit);
    return Semantics(
      container: true,
      label: _l10n.voiceConversationTranscript,
      child: Container(
        key: const Key('voice-conversation-transcript'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: _accent, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _l10n.voiceConversation,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final turn in visibleTurns) _buildTranscriptBubble(turn),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptBubble(_VoiceTranscriptTurn turn) {
    final isUser = turn.speaker == _VoiceTranscriptSpeaker.user;
    final bubbleColor = isUser
        ? _accent.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.075);
    final label = isUser
        ? _l10n.voiceSpeakerYou
        : _l10n.voiceSpeakerAssistant;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: '$label: ${turn.text}',
        child: Container(
          key: Key('voice-turn-${turn.id}'),
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: Border.all(
              color: isUser
                  ? _accent.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isUser ? const Color(0xFF93C5FD) : _accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                turn.text,
                maxLines: _isCompanion ? null : (isUser ? 3 : 5),
                overflow: _isCompanion ? null : TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (turn.schemeMatches.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  _l10n.voiceRecommendedForYou,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF86EFAC),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ...turn.schemeMatches.take(3).map(_buildTurnSchemeCard),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurnSchemeCard(SchemeSearchMatch match) {
    final scheme = match.scheme.toLocalized(_presentInTamil ? 'ta' : 'en');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.tight),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('voice-result-${match.scheme.id}'),
          onTap: () => widget.onSchemeSelected?.call(match.scheme),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _accent.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (match.reasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          match.reasons.join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 9.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.arrow_forward_rounded, size: 15, color: _accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestionChip(String label) => ActionChip(
    label: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    onPressed: () => _useSuggestion(label),
    side: BorderSide(color: _accent),
    backgroundColor: _accent.withValues(alpha: 0.18),
    labelStyle: const TextStyle(color: Colors.white),
    visualDensity: VisualDensity.compact,
  );

  Widget _buildLanguageSelector() {
    if (!_showFallbackPicker) {
      return Semantics(
        label: _l10n.voiceLanguageSemantic(_languageBadgeLabel),
        child: Container(
          key: const Key('voice-language-auto-badge'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Text(
            _languageBadgeLabel,
            style: GoogleFonts.inter(
              color: const Color(0xFF172554),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return Container(
      key: const Key('voice-language-fallback-picker'),
      padding: const EdgeInsets.all(AppSpacing.hairline),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _languageOption('EN', VoiceInputLanguage.english),
          _languageOption('தமிழ்', VoiceInputLanguage.tamil),
        ],
      ),
    );
  }

  Widget _languageOption(String label, VoiceInputLanguage language) {
    final selected = _fallbackLanguage == language;
    return InkWell(
      key: Key('voice-language-${language.name}'),
      onTap: () => _changeLanguage(language),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFactChips() {
    final allFacts = _session!.facts.values.toList(growable: false);
    final facts = _isCompanion
        ? allFacts
        : allFacts.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.voiceWhatIUnderstood,
          style: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.tight),
        Wrap(
          spacing: AppSpacing.tight,
          runSpacing: AppSpacing.tight,
          children: facts
              .map((fact) {
                final conflict = fact.hasConflict;
                return InputChip(
                  key: Key('voice-fact-${fact.key.name}'),
                  avatar: Icon(
                    conflict
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 15,
                    color: conflict
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF60A5FA),
                  ),
                  label: Text(
                    '${_factLabel(context, fact.key)}: ${_displayFactValue(_l10n, fact)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _editFact(fact),
                  side: BorderSide(
                    color: conflict
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF334155),
                  ),
                  backgroundColor: const Color(0xFF172554),
                  labelStyle: const TextStyle(color: Colors.white),
                  visualDensity: VisualDensity.compact,
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(FollowUpQuestion question) {
    final text = _questionText(_session!, question);
    return Container(
      key: const Key('voice-follow-up-question'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF60A5FA),
                size: 17,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              IconButton(
                key: const Key('voice-repeat-question'),
                tooltip: _l10n.voiceRepeatQuestionTooltip,
                onPressed: _speakQuestionAndListen,
                icon: const Icon(
                  Icons.volume_up_outlined,
                  color: Color(0xFF93C5FD),
                  size: 20,
                ),
              ),
            ],
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.tight,
              runSpacing: AppSpacing.tight,
              children: question.options
                  .map(
                    (option) => ActionChip(
                      key: Key(
                        'voice-answer-${option.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      label: Text(
                        option,
                        style: const TextStyle(
                          color: Color(0xFF172554),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _answerOption(option),
                      backgroundColor: const Color(0xFFDBEAFE),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      labelStyle: const TextStyle(color: Color(0xFF172554)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (_speechCapabilities?.supports(
                _session!.isTamil ? 'ta-IN' : 'en-IN',
              ) ==
              false)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.tight),
              child: Text(
                _l10n.voiceSpeechOutputUnavailable,
                style: GoogleFonts.inter(
                  color: const Color(0xFFFBBF24),
                  fontSize: 9.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationalResults() {
    final allRecommendations = _session!.recommendations;
    final recommendations = _showAllRecommendations
        ? allRecommendations
        : allRecommendations.take(3).toList(growable: false);
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _l10n.voiceSchemesSuitedToSituation,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _l10n.voiceFoundCount(allRecommendations.length),
              key: const Key('voice-result-count'),
              style: GoogleFonts.inter(
                color: const Color(0xFF93C5FD),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.tight),
            TextButton(
              key: const Key('voice-view-all-results'),
              onPressed: () => widget.onSubmit(_session!.statement),
              child: Text(
                CentralizedTranslator.instance.translate('Open search'),
                style: const TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ),
        ...recommendations.map(_buildRecommendationCard),
        if (allRecommendations.length > 3)
          TextButton.icon(
            key: const Key('voice-toggle-all-results'),
            onPressed: () => setState(
              () => _showAllRecommendations = !_showAllRecommendations,
            ),
            icon: Icon(
              _showAllRecommendations
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 17,
            ),
            label: Text(
              _showAllRecommendations
                  ? _l10n.voiceShowTop3
                  : _l10n.voiceShowAllMatches(allRecommendations.length),
            ),
          ),
        if (widget.onProfileConfirmed != null &&
            _session!.facts.values.any(
              (fact) => fact.source != EligibilityFactSource.profile,
            )) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('voice-review-profile'),
            onPressed: _reviewAndSaveFacts,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
            label: Text(
              CentralizedTranslator.instance.translate(
                'Review and save confirmed details',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssistantReply(GroundedAssistantReply reply) {
    return Container(
      key: const Key('voice-assistant-reply'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: _accent),
              const SizedBox(width: AppSpacing.tight),
              Flexible(
                child: FitOneLine(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isCompanion ? 'Saarthi' : _l10n.askAi,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reply.displayText,
            style: GoogleFonts.inter(
              color: const Color(0xFFE2E8F0),
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (reply.sourceUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const Key('voice-assistant-source'),
              onPressed: () => _openReplySource(reply.sourceUrl),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(
                reply.sourceLabel.isEmpty
                    ? _l10n.voiceOpenOfficialSource
                    : reply.sourceLabel,
                style: const TextStyle(fontSize: 10.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnlineGrounding() {
    final isChecking = _groundingPhase == _OnlineGroundingPhase.checking;
    final isFound = _groundingPhase == _OnlineGroundingPhase.found;
    final icon = isChecking
        ? Icons.travel_explore
        : isFound
        ? Icons.verified_outlined
        : Icons.cloud_off_outlined;
    final title = switch (_groundingPhase) {
      _OnlineGroundingPhase.checking => _l10n.voiceGroundingChecking,
      _OnlineGroundingPhase.found =>
        _l10n.voiceGroundingFoundSources(_groundedSources.length),
      _OnlineGroundingPhase.unavailable => _l10n.voiceGroundingUnavailable,
      _OnlineGroundingPhase.noSources => _l10n.voiceGroundingNoSources,
      _OnlineGroundingPhase.idle => '',
    };
    if (!_isCompanion) {
      final firstSource = isFound && _groundedSources.isNotEmpty
          ? _groundedSources.first
          : null;
      return Container(
        key: const Key('voice-online-grounding'),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1D2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isFound ? const Color(0xFF22C55E) : _accent).withValues(
              alpha: 0.25,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isFound ? const Color(0xFF4ADE80) : _accent,
                ),
                const SizedBox(width: AppSpacing.tight),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isChecking)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      key: const Key('voice-online-grounding-progress'),
                      strokeWidth: 1.5,
                      color: _accent,
                    ),
                  ),
              ],
            ),
            if (firstSource != null) ...[
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                key: Key('voice-grounded-source-${firstSource.url}'),
                onTap: () => _openReplySource(firstSource.url.toString()),
                child: Text(
                  firstSource.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF93C5FD),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (isChecking || isFound) ...[
              const SizedBox(height: 3),
              Text(
                _l10n.voiceGroundingPrivacyNote,
                key: const Key('voice-grounding-privacy-note'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      key: const Key('voice-online-grounding'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1D2E),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: (isFound ? const Color(0xFF22C55E) : _accent).withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isFound ? const Color(0xFF4ADE80) : _accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE2E8F0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isChecking)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    key: const Key('voice-online-grounding-progress'),
                    strokeWidth: 1.5,
                    color: _accent,
                  ),
                ),
            ],
          ),
          if (isFound) ...[
            const SizedBox(height: AppSpacing.tight),
            ..._groundedSources.map(
              (source) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.tight),
                child: InkWell(
                  key: Key('voice-grounded-source-${source.url}'),
                  onTap: () => _openReplySource(source.url.toString()),
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.tight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                source.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF93C5FD),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          source.snippet,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFCBD5E1),
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.hairline),
                        Text(
                          source.host,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4ADE80),
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (isChecking || isFound) ...[
            const SizedBox(height: AppSpacing.tight),
            Text(
              _l10n.voiceGroundingPrivacyNote,
              key: const Key('voice-grounding-privacy-note'),
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 8.5,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReplySource(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _message = _l10n.voiceCouldNotOpenSource);
    }
  }

  Widget _buildRecommendationCard(SchemeRecommendation recommendation) {
    final scheme = recommendation.scheme;
    final label = switch (recommendation.state) {
      SchemeMatchState.strongMatch => _l10n.voiceMatchStrong,
      SchemeMatchState.likelyMatch => _l10n.voiceMatchLikely,
      SchemeMatchState.needsInformation => _l10n.voiceMatchNeedsConfirmation,
      SchemeMatchState.notSuitable => _l10n.voiceMatchNotSuitable,
      SchemeMatchState.noConfidentMatch => _l10n.voiceMatchNoConfident,
    };
    final color = switch (recommendation.state) {
      SchemeMatchState.strongMatch => const Color(0xFF22C55E),
      SchemeMatchState.likelyMatch => const Color(0xFF60A5FA),
      SchemeMatchState.needsInformation => const Color(0xFFF59E0B),
      _ => const Color(0xFFF87171),
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: InkWell(
        key: Key('voice-result-${scheme.id}'),
        onTap: () => widget.onSchemeSelected?.call(scheme),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.052),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheme.toLocalized(_presentInTamil ? 'ta' : 'en').name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
                      color: color.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.62)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.tight),
              if (recommendation.reasons.isNotEmpty)
                _resultLine(
                  Icons.check_circle_outline,
                  _l10n.voiceWhyThisFits(
                    recommendation.reasons.join(' • '),
                  ),
                  const Color(0xFF86EFAC),
                ),
              if (recommendation.unknownRequirements.isNotEmpty)
                _resultLine(
                  Icons.help_outline,
                  _l10n.voiceStillConfirm(
                    recommendation.unknownRequirements.take(2).join(' • '),
                  ),
                  const Color(0xFFFCD34D),
                ),
              _resultLine(
                recommendation.isTrusted
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                recommendation.isTrusted
                    ? _l10n.voiceSourceVerified
                    : _l10n.voiceSourceUnverified,
                recommendation.isTrusted
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFFCA5A5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultLine(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: AppSpacing.tight),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFFF1F5F9),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLegacyResults() {
    return Column(
      key: const Key('voice-search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _l10n.voiceBestMatchingSchemes,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        ..._legacyMatches
            .take(3)
            .map(
              (match) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.tight),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    key: Key('voice-result-${match.scheme.id}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.white.withValues(alpha: 0.055),
                    title: Text(
                      match.scheme
                          .toLocalized(_presentInTamil ? 'ta' : 'en')
                          .name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      match.reasons.join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                      ),
                    ),
                    onTap: () => widget.onSchemeSelected?.call(match.scheme),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  static String _factLabel(BuildContext context, EligibilityFactKey key) {
    final l10n = context.l10n;
    return switch (key) {
      EligibilityFactKey.age => l10n.labelAge,
      EligibilityFactKey.state => l10n.voiceFactLabelState,
      EligibilityFactKey.district => l10n.filterDistrict,
      EligibilityFactKey.annualIncome => l10n.labelAnnualIncome,
      EligibilityFactKey.gender => l10n.labelGender,
      EligibilityFactKey.community => l10n.labelCommunity,
      EligibilityFactKey.occupation => l10n.voiceFactLabelSituation,
      EligibilityFactKey.education => l10n.labelEducation,
      EligibilityFactKey.disability => l10n.labelDisability,
      EligibilityFactKey.maritalStatus => l10n.voiceFactLabelMaritalStatus,
      EligibilityFactKey.studentStatus => l10n.empStudent,
      EligibilityFactKey.businessStage => l10n.labelBusinessStage,
      EligibilityFactKey.businessSector => l10n.voiceFactLabelSector,
      EligibilityFactKey.fundingNeed => l10n.voiceFactLabelFundingNeed,
      EligibilityFactKey.landholding => l10n.voiceFactLabelLandholding,
    };
  }

  static String _displayFactValue(AppLocalizations l10n, EligibilityFact fact) {
    if ({
      EligibilityFactKey.annualIncome,
      EligibilityFactKey.fundingNeed,
    }.contains(fact.key)) {
      final amount = double.tryParse(fact.value);
      if (amount != null) {
        if (amount >= 10000000) {
          return l10n.voiceFactCrore((amount / 10000000).toStringAsFixed(1));
        }
        if (amount >= 100000) {
          return l10n.voiceFactLakh((amount / 100000).toStringAsFixed(1));
        }
      }
    }
    return fact.hasConflict
        ? l10n.voiceFactConflictFormat(fact.conflictingValue!, fact.value)
        : fact.value;
  }
}

class _RegularVoiceBackdrop extends StatelessWidget {
  const _RegularVoiceBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1020), Color(0xFF070A12), Color(0xFF05070C)],
          stops: [0, 0.46, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5D52E8).withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D52E8).withValues(alpha: 0.16),
                    blurRadius: 120,
                    spreadRadius: 45,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -130,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF18BBD0).withValues(alpha: 0.07),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18BBD0).withValues(alpha: 0.12),
                    blurRadius: 130,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegularVoiceAmbientPainter extends CustomPainter {
  const _RegularVoiceAmbientPainter({
    required this.progress,
    required this.intensity,
    required this.active,
    required this.reduceMotion,
  });

  final double progress;
  final double intensity;
  final bool active;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = reduceMotion ? 0.35 : progress;
    final pulse = active ? 0.6 + math.sin(phase * math.pi * 2) * 0.12 : 0.35;
    final center = Offset(size.width / 2, math.min(size.height * 0.31, 270));
    final radius = math.min(size.width * 0.38, 170) + intensity * 18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B7CFF).withValues(alpha: 0.0),
          const Color(0xFF8B7CFF).withValues(alpha: 0.16 * pulse),
          const Color(0xFF22D3EE).withValues(alpha: 0.0),
        ],
        stops: const [0.66, 0.86, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius + 18, paint..strokeWidth = 0.7);
  }

  @override
  bool shouldRepaint(covariant _RegularVoiceAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.active != active ||
      oldDelegate.reduceMotion != reduceMotion;
}
