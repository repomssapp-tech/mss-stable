import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../services/chat/chat_log_service.dart';
import '../../services/search/scheme_understanding_engine.dart';
import '../../services/voice/assistant_session_controller.dart';
import '../../services/voice/http_voice_agent_controller.dart';
import '../../services/voice/realtime_speech_transport.dart';
import '../../services/voice/saarthi_conversation_controller.dart';
import '../../services/voice/voice_agent_controller.dart';
import '../../services/voice/voice_microphone.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import 'saarthi_home/saarthi_bottom_panel.dart';
import 'saarthi_home/saarthi_character_header.dart';
import 'saarthi_home/saarthi_live_conversation_view.dart';
import 'saarthi_home/saarthi_response_helpers.dart';
import 'saarthi_home/saarthi_top_bar.dart';
import 'saarthi_home/saarthi_voice_animations.dart';
import 'saarthi_message.dart';

export 'saarthi_message.dart';

/// Saarthi's screen owns presentation/history; audio and turn-taking live in
/// the conversation controller and can be verified independently of widgets.
class SaarthiHomeScreen extends StatefulWidget {
  const SaarthiHomeScreen({super.key, this.conversation});
  final SaarthiConversationController? conversation;
  @override
  State<SaarthiHomeScreen> createState() => _SaarthiHomeScreenState();
}

class _SaarthiHomeScreenState extends State<SaarthiHomeScreen>
    with TickerProviderStateMixin {
  final _messages = <SaarthiMessage>[];
  final _chatLog = ChatLogService();
  final _scroll = ScrollController();
  SaarthiConversationController? _conversation;
  AssistantSessionController? _session;
  StreamSubscription<VoiceAgentEvent>? _events;
  late final SaarthiVoiceAnimations _animations;
  late final AppLifecycleListener _lifecycle;
  bool _active = false;
  List<CloudSchemeResult> _pendingMetadata = const [];
  bool get _ownsConversation => widget.conversation == null;

  @override
  void initState() {
    super.initState();
    _animations = SaarthiVoiceAnimations(this);
    _lifecycle = AppLifecycleListener(
      onInactive: _pauseInBackground,
      onPause: _pauseInBackground,
      onHide: _pauseInBackground,
      onDetach: _pauseInBackground,
    );
  }

  void _pauseInBackground() {
    if (_active) unawaited(_conversation?.pause());
    _syncHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reader = MediaQuery.of(context).accessibleNavigation;
    final conversation = _conversation;
    if (conversation != null && conversation.screenReader != reader) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(conversation.updateAccessibility(reader));
      });
    }
  }

  void _initializeConversation() {
    if (_conversation != null) return;
    final provider = context.read<AppProvider>();
    final injected = widget.conversation;
    if (injected != null) {
      _conversation = injected;
    } else {
      _session = AssistantSessionController(
        engine: const LocalSchemeUnderstandingEngine(),
        schemes: provider.allSchemes,
        profile: provider.profile,
      );
      final agent = HttpVoiceAgentController(
        session: _session!,
        languageCode: () => provider.selectedLanguage,
      );
      _conversation = SaarthiConversationController(
        agent: agent,
        transport: MssRealtimeSpeechTransport(),
        microphone: DeviceVoiceMicrophone(),
        language: provider.selectedLanguage,
        screenReader: MediaQuery.of(context).accessibleNavigation,
      );
    }
    _conversation!.addListener(_onConversation);
    _events = _conversation!.agent.events.listen(_onAgentEvent);
  }

  Future<void> _start() async {
    _initializeConversation();
    _chatLog.startSession();
    setState(() => _active = true);
    await _conversation!.start();
  }

  void _onConversation() {
    if (!mounted || !_active) return;
    final phase = _conversation!.phase;
    _animations.setListening(
      phase == ConversationPhase.listening,
      reduceMotion: MediaQuery.of(context).disableAnimations,
    );
    if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
      _messages[_messages.length - 1] = _messages.last.copyWith(
        speakingState: phase == ConversationPhase.speaking ? 'speaking' : null,
        clearSpeakingState: phase != ConversationPhase.speaking,
      );
    }
    setState(() {});
  }

  void _onAgentEvent(VoiceAgentEvent event) {
    if (!mounted || !_active) return;
    if (event.type == VoiceAgentEventType.schemeResults) {
      final raw = event.data?['results'];
      _pendingMetadata = raw is List<CloudSchemeResult> ? raw : const [];
      return;
    }
    final isUser = event.type == VoiceAgentEventType.inputTranscriptDone;
    if (!isUser && event.type != VoiceAgentEventType.outputTranscriptDone) {
      return;
    }
    final text = event.text?.trim() ?? '';
    if (text.isEmpty) return;
    final id =
        event.data?['messageId'] as String? ??
        '${DateTime.now().microsecondsSinceEpoch}';
    final provider = context.read<AppProvider>();
    final recent = _messages
        .where((message) => message.role == 'user')
        .map((message) => message.text)
        .toList();
    final catalogMatches = matchCloudSchemeResultsToCatalog(
      _pendingMetadata,
      provider.allSchemes,
    );
    final results = isUser
        ? null
        : SaarthiResponseHelpers.rankCloudSchemeResults(
            results: _pendingMetadata,
            catalogMatches: catalogMatches,
            recentUserTurns: recent
                .skip(math.max(0, recent.length - 3))
                .toList(),
          );
    final message = SaarthiMessage(
      id: id,
      role: isUser ? 'user' : 'assistant',
      text: text,
      timestamp: DateTime.now(),
      schemeResults: results,
      cloudSchemeResults: isUser ? null : _pendingMetadata,
    );
    setState(() {
      final existing = _messages.indexWhere((entry) => entry.id == id);
      if (existing >= 0) {
        _messages[existing] = message;
      } else {
        _messages.add(message);
      }
    });
    _chatLog.upsertMessage(
      id: id,
      speaker: isUser ? ChatMessageSpeaker.user : ChatMessageSpeaker.assistant,
      text: text,
      timestamp: message.timestamp,
      recommendations: results?.map((scheme) => scheme.name).toList(),
    );
    if (isUser) _pendingMetadata = const [];
    // Keep the user's reading position. A reply never forces them to its end.
  }

  void _syncHistory() {
    if (_chatLog.messageCount > 0) {
      unawaited(_chatLog.syncChatSession(mode: 'voice'));
    }
  }

  Future<void> _end() async {
    await _conversation?.end();
    _animations.stop();
    _syncHistory();
    if (mounted) setState(() => _active = false);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _syncHistory();
    unawaited(_events?.cancel());
    _conversation?.removeListener(_onConversation);
    if (_ownsConversation) {
      unawaited(
        _conversation?.dispose().then((_) => _conversation?.agent.dispose()),
      );
      _session?.dispose();
    } else {
      unawaited(_conversation?.pause());
    }
    _animations.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final userName = provider.profile.name.trim().isEmpty
        ? context.l10n.saarthiGreetingFriend
        : provider.profile.name.trim().split(' ').first;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(_conversation?.end());
          _syncHistory();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _active
              ? SaarthiLiveConversationView(
                  conversation: _conversation!,
                  messages: _messages,
                  scrollController: _scroll,
                  waveController: _animations.waveController,
                  onEndConversation: () => unawaited(_end()),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: SaarthiTopBar(provider: provider),
                      ),
                      SaarthiCharacterHeader(
                        isConversationActive: false,
                        userName: userName,
                        voiceState: SaarthiVoiceState.idle,
                        usingCloudVoice: false,
                        cloudRetrying: false,
                        cloudConnectionError: null,
                      ),
                      SaarthiBottomPanel(
                        isConversationActive: false,
                        voiceState: SaarthiVoiceState.idle,
                        usingCloudVoice: false,
                        cloudRetrying: false,
                        cloudConnectionError: null,
                        onStartConversation: () => unawaited(_start()),
                        onPrimaryMicTap: () => unawaited(_start()),
                        onEndConversation: () => unawaited(_end()),
                        onRetryCloudVoice: () => unawaited(_start()),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
