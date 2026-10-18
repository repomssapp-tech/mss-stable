import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/scheme_model.dart';
import '../../models/user_profile.dart';
import '../../services/voice/assistant_session_controller.dart';
import '../../services/search/intelligent_scheme_search.dart';
import '../../services/voice/livekit_voice_agent_controller.dart';
import '../../services/search/official_grounded_search.dart';
import '../../services/search/private_ai_knowledge_base.dart';
import '../../services/search/scheme_understanding_engine.dart';
import '../../services/voice/speech_output_controller.dart';
import '../../services/voice/voice_recognition_controller.dart';
import '../../services/voice/voice_agent_controller.dart';
import '../../services/chat/chat_log_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_spacing.dart';
import 'voice_edge_painter.dart';

export 'voice_edge_painter.dart';
export 'voice/companion_voice_header.dart';
export 'voice/regular_voice_backdrop.dart';
export 'voice/regular_voice_experience.dart';
export 'voice/voice_fact_dialogs.dart';
export 'voice/voice_interactive_widgets.dart';
export 'voice/voice_overlay_models.dart';
export 'voice/voice_recommendation_cards.dart';
export 'voice/voice_transcript_widgets.dart';

import 'voice/companion_voice_header.dart';
import 'voice/regular_voice_backdrop.dart';
import 'voice/regular_voice_experience.dart';
import 'voice/voice_fact_dialogs.dart';
import 'voice/voice_interactive_widgets.dart';
import 'voice/voice_overlay_models.dart';
import 'voice/voice_recommendation_cards.dart';
import 'voice/voice_transcript_widgets.dart';

typedef _VoiceAssistantPhase = VoiceAssistantPhase;
typedef _OnlineGroundingPhase = OnlineGroundingPhase;
typedef _VoiceTranscriptTurn = VoiceTranscriptTurn;
typedef _VoiceTranscriptSpeaker = VoiceTranscriptSpeaker;

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
  // Voice input is English/Tamil only, so a Hindi-UI user speaking English
  // still gets Hindi chrome rather than falling back to English.
  AppLocalizations get _l10n {
    final appLanguage = Localizations.localeOf(context).languageCode;
    return lookupAppLocalizations(
      Locale(_presentInTamil ? 'ta' : (appLanguage == 'hi' ? 'hi' : 'en')),
    );
  }

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
          widget.understandingEngine ?? const LocalSchemeUnderstandingEngine();
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
    final value = await showVoiceEditFactDialog(
      context: context,
      l10n: _l10n,
      fact: fact,
    );
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
    final confirmed = await showVoiceProfileReviewDialog(
      context: context,
      l10n: _l10n,
      candidates: candidates,
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
                      color: (_isCompanion
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
                          CompanionVoiceHeader(
                            isCompanion: _isCompanion,
                            statusLabel: _statusLabel,
                            statusColor: _statusColor,
                            l10n: _l10n,
                            languageSelector: _buildLanguageSelector(),
                            cloudSessionInUse: _cloudSessionInUse,
                            isMuted: _voiceAgentController?.state.isMuted ?? false,
                            onToggleMute: _cloudSessionInUse
                                ? () => _voiceAgentController!.setMuted(
                                      !_voiceAgentController!.state.isMuted,
                                    )
                                : null,
                            onClose: _close,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CompanionVoiceListeningArea(
                            isCompanion: _isCompanion,
                            transcript: _transcript,
                            hasConversationTurns: _conversationTurns.isNotEmpty,
                            speaking: _speaking,
                            isListening: _isListening,
                            cloudSessionInUse: _cloudSessionInUse,
                            statusColor: _statusColor,
                            accent: _accent,
                            waveController: _waveController,
                            soundLevel: _soundLevel,
                            typedController: _typedController,
                            l10n: _l10n,
                            onToggleListening: _toggleListening,
                            onSendTypedInput: _sendTypedInput,
                            onSuggestionSelected: _useSuggestion,
                            showSuggestions: _transcript.isEmpty &&
                                _session?.statement.isEmpty != false,
                          ),
                          if (_conversationTurns.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            CompanionVoiceTranscriptSection(
                              conversationTurns: _conversationTurns,
                              isCompanion: _isCompanion,
                              accent: _accent,
                              l10n: _l10n,
                              presentInTamil: _presentInTamil,
                              onSchemeSelected: widget.onSchemeSelected,
                            ),
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
                            VoiceAssistantReplyCard(
                              reply: reply,
                              accentColor: _accent,
                              isCompanion: _isCompanion,
                              l10n: _l10n,
                              onOpenSource: _openReplySource,
                            ),
                          ],
                          if (_groundingPhase != _OnlineGroundingPhase.idle) ...[
                            const SizedBox(height: AppSpacing.sm),
                            VoiceOnlineGroundingPill(
                              groundingPhase: _groundingPhase,
                              groundedSources: _groundedSources,
                              accentColor: _accent,
                              isCompanion: true,
                              l10n: _l10n,
                              onOpenSource: _openReplySource,
                            ),
                          ],
                          if (_session?.facts.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.md),
                            VoiceFactChips(
                              facts: _session!.facts,
                              isCompanion: true,
                              l10n: _l10n,
                              onEditFact: _editFact,
                            ),
                          ],
                          if (_session?.question != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            VoiceQuestionCard(
                              question: _session!.question!,
                              questionText: _questionText(_session!, _session!.question!),
                              l10n: _l10n,
                              onOptionSelected: _answerOption,
                              onRepeatQuestion: _speakQuestionAndListen,
                            ),
                          ],
                          if (_legacySearching ||
                              _session?.phase ==
                                  AssistantSessionPhase.understanding) ...[
                            const SizedBox(height: AppSpacing.md),
                            LinearProgressIndicator(
                              key: const Key('voice-search-progress'),
                              minHeight: 2,
                              color: _accent,
                              backgroundColor: _accent.withValues(alpha: 0.20),
                            ),
                          ] else if (_session?.recommendations.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: AppSpacing.md),
                            VoiceConversationalResultsSection(
                              session: _session!,
                              showAllRecommendations: _showAllRecommendations,
                              presentInTamil: _presentInTamil,
                              l10n: _l10n,
                              onToggleAllResults: () => setState(
                                () => _showAllRecommendations =
                                    !_showAllRecommendations,
                              ),
                              onOpenSearch: () =>
                                  widget.onSubmit(_session!.statement),
                              onSchemeSelected: widget.onSchemeSelected,
                              onReviewProfile: widget.onProfileConfirmed != null
                                  ? _reviewAndSaveFacts
                                  : null,
                              hasUnsavedProfileFacts: _session!.facts.values.any(
                                (f) => f.source != EligibilityFactSource.profile,
                              ),
                            ),
                          ] else if (_legacyMatches.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            VoiceLegacyResultsSection(
                              matches: _legacyMatches,
                              presentInTamil: _presentInTamil,
                              l10n: _l10n,
                              onSchemeSelected: widget.onSchemeSelected,
                            ),
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
            const Positioned.fill(child: RegularVoiceBackdrop()),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    key: const Key('voice-edge-outline'),
                    animation: _edgeRepaint,
                    builder: (context, child) => CustomPaint(
                      painter: RegularVoiceAmbientPainter(
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
                    RegularVoiceTopBar(
                      statusLabel: _statusLabel,
                      l10n: _l10n,
                      languageSelector: _buildLanguageSelector(),
                      onClose: _close,
                    ),
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
                            RegularVoicePresence(
                              isGenerating: isGenerating,
                              isListening: _isListening,
                              speaking: _speaking,
                              statusLabel: _statusLabel,
                              waveController: _waveController,
                              soundLevel: _soundLevel,
                              l10n: _l10n,
                            ),
                            const SizedBox(height: 28),
                            if (!hasConversation)
                              RegularVoiceWelcome(
                                l10n: _l10n,
                                onSuggestionSelected: _useSuggestion,
                              )
                            else
                              Container(
                                key: _session?.reply != null
                                    ? const Key('voice-assistant-reply')
                                    : null,
                                child: RegularVoiceTranscript(
                                  conversationTurns: _conversationTurns,
                                  presentInTamil: _presentInTamil,
                                  l10n: _l10n,
                                  onSchemeSelected: widget.onSchemeSelected,
                                ),
                              ),
                            if (_message != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              RegularVoiceNotice(text: _message!),
                            ],
                            if (_session?.question case final question?) ...[
                              const SizedBox(height: AppSpacing.xl),
                              RegularVoiceQuestionCard(
                                question: question,
                                questionText: _questionText(_session!, question),
                                l10n: _l10n,
                                speechOutputSupported: _speechCapabilities?.supports(
                                  _session!.isTamil ? 'ta-IN' : 'en-IN',
                                ) ?? true,
                                onOptionSelected: _answerOption,
                              ),
                            ],
                            if (_session?.recommendations.isNotEmpty == true) ...[
                              const SizedBox(height: 22),
                              RegularVoiceRecommendationsSection(
                                session: _session!,
                                showAllRecommendations: _showAllRecommendations,
                                presentInTamil: _presentInTamil,
                                l10n: _l10n,
                                onToggleAllResults: () => setState(
                                  () => _showAllRecommendations =
                                      !_showAllRecommendations,
                                ),
                                onSchemeSelected: widget.onSchemeSelected,
                                onReviewProfile: widget.onProfileConfirmed != null
                                    ? _reviewAndSaveFacts
                                    : null,
                                hasUnsavedProfileFacts: _session!.facts.values.any(
                                  (f) => f.source != EligibilityFactSource.profile,
                                ),
                              ),
                            ] else if (_legacyMatches.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              RegularVoiceLegacyResultsSection(
                                matches: _legacyMatches,
                                presentInTamil: _presentInTamil,
                                l10n: _l10n,
                                onSchemeSelected: widget.onSchemeSelected,
                              ),
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
                            if (_groundingPhase != _OnlineGroundingPhase.idle) ...[
                              const SizedBox(height: AppSpacing.lg),
                              VoiceOnlineGroundingPill(
                                groundingPhase: _groundingPhase,
                                groundedSources: _groundedSources,
                                accentColor: _accent,
                                isCompanion: false,
                                l10n: _l10n,
                                onOpenSource: _openReplySource,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    RegularVoiceControls(
                      speaking: _speaking,
                      isListening: _isListening,
                      cloudSessionInUse: _cloudSessionInUse,
                      l10n: _l10n,
                      onToggleListening: _toggleListening,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return VoiceLanguageSelector(
      showFallbackPicker: _showFallbackPicker,
      languageBadgeLabel: _languageBadgeLabel,
      fallbackLanguage: _fallbackLanguage,
      l10n: _l10n,
      onChangeLanguage: _changeLanguage,
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
}
