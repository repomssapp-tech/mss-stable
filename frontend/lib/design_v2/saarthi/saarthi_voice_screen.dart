// Saarthi (redesign): Home, Old sessions, and one conversation that can be
// spoken or typed, with the optional review step. Audio and turn-taking stay
// in SaarthiConversationController; this screen draws its state, keeps the
// transcript, applies the Voice settings, and saves the conversation on this
// phone. Any saved conversation can be reopened and continued.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/companion_mode/saarthi_message.dart';
import '../../screens/profile_screen.dart';
import '../../screens/regular_mode/settings_screen.dart';
import '../../services/chat/chat_log_service.dart';
import '../../services/chat/local_chat_history.dart';
import '../../services/search/scheme_understanding_engine.dart';
import '../../services/voice/assistant_session_controller.dart';
import '../../services/voice/http_voice_agent_controller.dart';
import '../../services/voice/native_saarthi_conversation_controller.dart';
import '../../services/voice/realtime_speech_transport.dart';
import '../../services/voice/saarthi_conversation_controller.dart';
import '../../services/voice/saarthi_voice_settings.dart';
import '../../services/voice/voice_accessibility.dart';
import '../../services/voice/voice_agent_controller.dart';
import '../../services/voice/voice_microphone.dart';
import '../../services/voice/voice_preferences.dart';
import '../mss_design.dart';
import 'saarthi_history_screen.dart';
import 'saarthi_voice_home.dart';
import 'saarthi_voice_room.dart';
import 'scheme_mentions.dart';
import '../../widgets/common/sign_in_required_sheet.dart';

class SaarthiVoiceScreen extends StatefulWidget {
  const SaarthiVoiceScreen({
    super.key,
    this.conversation,
    this.history,
    this.settings,
  });

  /// Injected in tests; otherwise the screen builds the native one.
  final SaarthiConversationController? conversation;

  /// Defaults to [LocalChatHistory.instance].
  final LocalChatHistory? history;

  /// Defaults to [SaarthiVoiceSettings.instance].
  final SaarthiVoiceSettings? settings;

  static _SaarthiVoiceScreenState? _shown;

  /// True while Back should stay inside Saarthi (a chat is open, or another
  /// tab is showing). The app shell's Back handler runs alongside this
  /// screen's, so it checks this before exiting the app.
  static bool get handlesBack => _shown?._blocksBack ?? false;

  @override
  State<SaarthiVoiceScreen> createState() => _SaarthiVoiceScreenState();
}

class _SaarthiVoiceScreenState extends State<SaarthiVoiceScreen> {
  final _messages = <SaarthiMessage>[];
  final _chatLog = ChatLogService();
  final _scroll = ScrollController();
  final _typeInput = TextEditingController();
  final _typeFocus = FocusNode();
  final Set<int> _readyDocs = {};
  late final LocalChatHistory _history;
  late final SaarthiVoiceSettings _settings;
  late final AppLifecycleListener _lifecycle;
  SaarthiConversationController? _conversation;
  AssistantSessionController? _session;
  StreamSubscription<VoiceAgentEvent>? _events;
  List<CloudSchemeResult> _pendingMetadata = const [];
  List<String>? _pendingSchemeIds;
  String? _appLanguage;
  bool _active = false;
  bool _starting = false;
  bool _typing = false;
  ConversationPhase? _lastPhase;
  SaarthiNavTab _tab = SaarthiNavTab.home;
  String _chatMode = 'voice';
  String _chatId = '';
  DateTime _chatStart = DateTime.now();

  bool get _ownsConversation => widget.conversation == null;

  bool get _blocksBack => _active || _tab != SaarthiNavTab.home;

  @override
  void initState() {
    super.initState();
    SaarthiVoiceScreen._shown = this;
    _history = widget.history ?? LocalChatHistory.instance;
    _settings = widget.settings ?? SaarthiVoiceSettings.instance;
    _settings.addListener(_applySettings);
    unawaited(_settings.load());
    _lifecycle = AppLifecycleListener(
      onInactive: _pauseInBackground,
      onPause: _pauseInBackground,
      onHide: _pauseInBackground,
    );
  }

  void _pauseInBackground() {
    if (_active) unawaited(_conversation?.pause());
    _syncHistory();
  }

  void _applySettings() {
    final c = _conversation;
    if (c == null) return;
    // Applied between turns: configure() pauses, so only when idle/paused.
    c.agent.speakReplies = _settings.autoplay && !c.screenReader;
    final language = _settings.languageChange;
    if (language != null && language != c.language) {
      _settings.languageChange = null;
      unawaited(c.configure(languageCode: language));
    }
  }

  Future<void> _initializeConversation() async {
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
      final reader = await VoiceAccessibility.screenReaderEnabled(
        platformHint: MediaQuery.of(context).accessibleNavigation,
      );
      final preferences = VoicePreferences();
      final language = await preferences.languageFor(provider.selectedLanguage);
      if (!mounted) return;
      _appLanguage = provider.selectedLanguage;
      final agent = HttpVoiceAgentController(
        session: _session!,
        languageCode: () => provider.selectedLanguage,
      );
      _conversation = NativeSaarthiConversationController(
        agent: agent,
        transport: MssRealtimeSpeechTransport(),
        microphone: DeviceVoiceMicrophone(),
        language: language,
        persistLanguage: (code) =>
            preferences.saveLanguage(code, provider.selectedLanguage),
        screenReader: reader,
      );
    }
    _applySettings();
    _conversation!.addListener(_onConversation);
    _events = _conversation!.agent.events.listen(_onAgentEvent);
  }

  /// A new chat, listening straight away or (with [typing]) waiting for text.
  Future<void> _start({bool typing = false}) async {
    if (_starting || _active) return;
    // Saarthi (voice and typed) needs an account until the backend's guest
    // token exists: a guest is asked to sign in instead.
    if (!await requireAccount(context, feature: SignInFeature.saarthi)) return;
    if (!mounted) return;
    _starting = true;
    try {
      await _initializeConversation();
      if (!mounted) return;
      _chatLog.startSession();
      _chatId = '${typing ? 't' : 'v'}${DateTime.now().microsecondsSinceEpoch}';
      _chatMode = typing ? 'type' : 'voice';
      _chatStart = DateTime.now();
      _messages.clear();
      _pendingMetadata = const [];
      _pendingSchemeIds = null;
      _readyDocs.clear();
      _conversation!.agent.restoreHistory(const []);
      setState(() {
        _active = true;
        _typing = typing;
      });
      if (typing) {
        _focusComposer();
      } else {
        await _conversation!.start();
      }
    } finally {
      _starting = false;
    }
  }

  /// Reopens a saved chat with its turns and context. New turns are added to
  /// it, spoken or typed; the mic stays off until the user taps it.
  Future<void> _resume(SavedChat chat) async {
    if (_starting || _active) return;
    if (!await requireAccount(context, feature: SignInFeature.saarthi)) return;
    if (!mounted) return;
    _starting = true;
    try {
      await _initializeConversation();
      if (!mounted) return;
      final all = context.read<AppProvider>().allSchemes;
      final byId = {for (final s in all) s.id: s};
      _chatLog.startSession();
      _chatId = chat.id;
      _chatMode = chat.mode;
      _chatStart = chat.createdAt;
      _messages
        ..clear()
        ..addAll([
          for (var i = 0; i < chat.messages.length; i++)
            SaarthiMessage(
              id: 'saved-$i',
              role: chat.messages[i].role,
              text: chat.messages[i].text,
              timestamp: chat.messages[i].at,
              schemeResults: <Scheme>[
                for (final id in chat.messages[i].schemeIds) ?byId[id],
              ],
            ),
        ]);
      _readyDocs.clear();
      _conversation!.agent.restoreHistory([
        for (final m in chat.messages) {'role': m.role, 'content': m.text},
      ]);
      setState(() {
        _active = true;
        _typing = false;
      });
      _scrollToEnd();
    } finally {
      _starting = false;
    }
  }

  void _focusComposer() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _typeFocus.requestFocus();
  });

  void _speak() {
    setState(() => _typing = false);
    unawaited(_conversation?.start());
  }

  void _showComposer() {
    final c = _conversation;
    // A reply being worked out is left to finish; speech stops for typing.
    if (c?.phase == ConversationPhase.speaking) unawaited(c?.pause());
    setState(() => _typing = true);
    _focusComposer();
  }

  /// Typed questions get a silent reply and leave the mic off; the megaphone
  /// reads the reply out on request.
  Future<void> _sendTyped() async {
    final c = _conversation;
    final text = _typeInput.text.trim();
    if (c == null || text.isEmpty) return;
    if (c.phase == ConversationPhase.thinking) return;
    _typeInput.clear();
    c.agent.speakReplies = false;
    try {
      await c.send(text);
    } finally {
      _applySettings();
    }
  }

  void _openTab(SaarthiNavTab tab) {
    setState(() => _tab = tab);
    if (_active) unawaited(_end());
  }

  void _openOver(Widget screen) {
    final c = _conversation;
    if (_active && c != null) {
      const live = [ConversationPhase.listening, ConversationPhase.speaking];
      if (live.contains(c.phase)) unawaited(c.pause());
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onConversation() {
    if (!mounted || !_active) return;
    setState(() {});
    // Status and error lines are added under the transcript; keep them in view.
    final phase = _conversation?.phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      if (const [
        ConversationPhase.thinking,
        ConversationPhase.speaking,
        ConversationPhase.error,
      ].contains(phase)) {
        _scrollToEnd();
      }
    }
  }

  void _onAgentEvent(VoiceAgentEvent event) {
    if (!mounted || !_active) return;
    if (event.type == VoiceAgentEventType.schemeResults) {
      final raw = event.data?['results'];
      _pendingMetadata = raw is List<CloudSchemeResult> ? raw : const [];
      _pendingSchemeIds = event.data == null
          ? null
          : replySchemeIds(event.data!);
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
    final results = isUser
        ? null
        : schemesForReply(
            text,
            provider.allSchemes,
            results: _pendingMetadata,
            schemeIds: _pendingSchemeIds,
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
      final existing = _messages.indexWhere((m) => m.id == id);
      if (existing >= 0) {
        _messages[existing] = message;
      } else {
        _messages.add(message);
        if (!isUser) _readyDocs.clear();
      }
    });
    _chatLog.upsertMessage(
      id: id,
      speaker: isUser ? ChatMessageSpeaker.user : ChatMessageSpeaker.assistant,
      text: text,
      timestamp: message.timestamp,
      recommendations: results?.map((s) => s.name).toList(),
    );
    _pendingMetadata = const [];
    _pendingSchemeIds = null;
    unawaited(_saveLocal());
    _scrollToEnd();
  }

  Future<void> _saveLocal() => _history.save(
    SavedChat(
      id: _chatId,
      mode: _chatMode,
      createdAt: _chatStart,
      updatedAt: DateTime.now(),
      messages: [
        for (final m in _messages)
          SavedChatMessage(
            role: m.role == 'user' ? 'user' : 'assistant',
            text: m.text,
            at: m.timestamp,
            schemeIds: [for (final s in m.schemeResults ?? const []) s.id],
          ),
      ],
    ),
  );

  void _syncHistory() {
    if (_chatLog.messageCount > 0) {
      unawaited(_chatLog.syncChatSession(mode: 'voice'));
    }
  }

  Future<void> _end() async {
    await _conversation?.end();
    _syncHistory();
    if (mounted) {
      setState(() {
        _active = false;
        _typing = false;
      });
    }
  }

  @override
  void dispose() {
    if (identical(SaarthiVoiceScreen._shown, this)) {
      SaarthiVoiceScreen._shown = null;
    }
    _lifecycle.dispose();
    _settings.removeListener(_applySettings);
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
    _scroll.dispose();
    _typeInput.dispose();
    _typeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (_conversation != null &&
        _appLanguage != null &&
        _appLanguage != provider.selectedLanguage) {
      final selected = _appLanguage = provider.selectedLanguage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_conversation?.configure(languageCode: selected));
        }
      });
    }
    final trimmed = provider.profile.name.trim();
    final userName = trimmed.isEmpty
        ? context.l10n.saarthiGreetingFriend
        : trimmed.split(' ').first;

    final c = _conversation;
    final nav = SaarthiPillNav(
      selected: _active ? SaarthiNavTab.sessions : _tab,
      onHome: () => _openTab(SaarthiNavTab.home),
      onSessions: () => _openTab(SaarthiNavTab.sessions),
      onSettings: () => _openOver(const SettingsScreen()),
    );
    final Widget body;
    if (_active && c != null) {
      body = SaarthiRoomView(
        conversation: c,
        messages: _messages,
        userName: userName,
        language: provider.selectedLanguage,
        scrollController: _scroll,
        readyDocuments: _readyDocs,
        onToggleDocument: (i) => setState(
          () =>
              _readyDocs.contains(i) ? _readyDocs.remove(i) : _readyDocs.add(i),
        ),
        typing: _typing,
        typeController: _typeInput,
        typeFocus: _typeFocus,
        onSpeak: _speak,
        onType: _showComposer,
        onSendTyped: () => unawaited(_sendTyped()),
        onHear: (reply) => unawaited(c.hear(reply)),
        nav: nav,
      );
    } else if (_tab == SaarthiNavTab.sessions) {
      body = SaarthiHistoryScreen(
        history: _history,
        onOpen: (chat) => unawaited(_resume(chat)),
        bottomBar: nav,
      );
    } else {
      body = SaarthiVoiceHome(
        userName: userName,
        onStart: () => unawaited(_start()),
        onType: () => unawaited(_start(typing: true)),
        onProfile: () => _openOver(const ProfileScreen()),
        nav: nav,
      );
    }

    return PopScope(
      canPop: !_blocksBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Deferred so the shell's handler, running in this same pass, still
        // sees that Saarthi is handling Back.
        scheduleMicrotask(() {
          if (!mounted) return;
          if (_active) {
            unawaited(_end());
          } else {
            setState(() => _tab = SaarthiNavTab.home);
          }
        });
      },
      child: DesignTextScale(child: body),
    );
  }
}
