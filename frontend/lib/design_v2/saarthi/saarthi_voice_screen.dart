// Saarthi Voice mode (v2 design): C1 Home, then the conversation views
// (C2 Listening, C3 Confirm, C4 Conversation room). Audio and turn-taking
// stay in SaarthiConversationController; this screen draws its state, keeps
// the transcript, applies the Voice settings, and saves the conversation on
// this phone.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/companion_mode/saarthi_message.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/regular_mode/categories_screen.dart';
import '../../screens/regular_mode/search_results_screen.dart';
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
import '../../utils/constants.dart';
import '../highlight_text.dart';
import '../mss_design.dart';
import 'saarthi_history_screen.dart';
import 'saarthi_kit.dart';
import 'saarthi_type_screen.dart';
import 'saarthi_voice_settings_screen.dart';
import 'saarthi_voice_views.dart';
import 'scheme_mentions.dart';

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

  @override
  State<SaarthiVoiceScreen> createState() => _SaarthiVoiceScreenState();
}

class _SaarthiVoiceScreenState extends State<SaarthiVoiceScreen> {
  final _messages = <SaarthiMessage>[];
  final _chatLog = ChatLogService();
  final _scroll = ScrollController();
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
  String _chatId = '';
  DateTime _chatStart = DateTime.now();

  bool get _ownsConversation => widget.conversation == null;

  @override
  void initState() {
    super.initState();
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
    c.reviewBeforeSend = _settings.confirmBeforeSend;
    c.handsFree = _settings.handsFree;
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

  Future<void> _start() async {
    if (_starting || _active) return;
    _starting = true;
    try {
      await _initializeConversation();
      if (!mounted) return;
      _chatLog.startSession();
      _chatId = 'v${DateTime.now().microsecondsSinceEpoch}';
      _chatStart = DateTime.now();
      _messages.clear();
      _pendingMetadata = const [];
      _pendingSchemeIds = null;
      _readyDocs.clear();
      setState(() => _active = true);
      await _conversation!.start();
    } finally {
      _starting = false;
    }
  }

  void _onConversation() {
    if (mounted && _active) setState(() {});
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

  Future<void> _saveLocal() => _history.save(
    SavedChat(
      id: _chatId,
      mode: 'voice',
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
    if (mounted) setState(() => _active = false);
  }

  /// "Discard" on the confirm view: back to the room if the conversation
  /// already has turns, otherwise back home.
  Future<void> _discard() async {
    if (_messages.isEmpty) {
      await _end();
    } else {
      await _conversation?.pause();
    }
  }

  void _openHistory() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SaarthiHistoryScreen()));

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SaarthiVoiceSettingsScreen()),
  );

  void _openType() {
    final provider = context.read<AppProvider>();
    if (_active) unawaited(_conversation?.pause());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SaarthiTypeScreen(
          profile: provider.profile,
          language: provider.selectedLanguage,
        ),
      ),
    );
  }

  @override
  void dispose() {
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
    final Widget body;
    if (!_active || c == null) {
      body = _VoiceHome(
        userName: userName,
        unread: provider.notifications.where((n) => n['read'] == false).length,
        onStart: () => unawaited(_start()),
        onType: _openType,
        onHistory: _openHistory,
        onSettings: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
        onDiscover: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => CategoriesScreen(
              onCategorySelected: (category) => Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SearchResultsScreen(title: category, type: 'category'),
                ),
              ),
            ),
          ),
        ),
        onNotifications: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
        ),
      );
    } else if (c.editing) {
      body = SaarthiConfirmView(
        conversation: c,
        onDiscard: () => unawaited(_discard()),
      );
    } else if (const [
      ConversationPhase.connecting,
      ConversationPhase.listening,
      ConversationPhase.transcribing,
    ].contains(c.phase)) {
      body = SaarthiListeningView(
        conversation: c,
        onClose: () => unawaited(_messages.isEmpty ? _end() : c.pause()),
      );
    } else {
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
        onEnd: () => unawaited(_end()),
        onHistory: _openHistory,
        onSettings: _openSettings,
      );
    }

    return PopScope(
      canPop: !_active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _active) unawaited(_end());
      },
      child: DesignTextScale(child: body),
    );
  }
}

// ─────────────── C1 · Home ───────────────
class _VoiceHome extends StatelessWidget {
  const _VoiceHome({
    required this.userName,
    required this.unread,
    required this.onStart,
    required this.onType,
    required this.onHistory,
    required this.onSettings,
    required this.onDiscover,
    required this.onNotifications,
  });

  final String userName;
  final int unread;
  final VoidCallback onStart;
  final VoidCallback onType;
  final VoidCallback onHistory;
  final VoidCallback onSettings;
  final VoidCallback onDiscover;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final greeting = AppConstants.getTimeGreeting(l10n);
    return Scaffold(
      key: const Key('sv2-home'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Image.asset(
                          MssAssets.logo,
                          width: 40,
                          height: 40,
                          cacheWidth: 120,
                        ),
                      ),
                      const Spacer(),
                      // Shrinks on narrow phones with large text instead of
                      // pushing the icons off screen.
                      Flexible(
                        flex: 6,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ModeToggle(
                            voiceActive: true,
                            onSwitch: onType,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        key: const Key('sv2-home-history'),
                        icon: Icons.history_rounded,
                        tooltip: l10n.sv2HistoryOpen,
                        bg: Colors.white,
                        border: true,
                        onTap: onHistory,
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        children: [
                          RoundIconButton(
                            key: const Key('saarthi-notifications-btn'),
                            icon: Icons.notifications_none_rounded,
                            tooltip: unread > 0
                                ? l10n.notificationsUnreadCount(unread)
                                : l10n.notificationsTooltip,
                            bg: Colors.white,
                            border: true,
                            onTap: onNotifications,
                          ),
                          if (unread > 0)
                            Positioned(
                              top: 9,
                              right: 10,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: MssColors.saffron,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 236,
                    height: 236,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MssColors.green.withValues(alpha: .12),
                          spreadRadius: 14,
                        ),
                        BoxShadow(
                          color: MssColors.saffron.withValues(alpha: .25),
                          spreadRadius: 6,
                        ),
                        const BoxShadow(
                          color: Color(0x1F000050),
                          blurRadius: 50,
                          offset: Offset(0, 24),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: -34,
                          top: 12,
                          width: 300,
                          child: ExcludeSemantics(
                            child: Image.asset(
                              MssAssets.saarthiNamaste,
                              cacheWidth: 720,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: HighlightText(
                    '$greeting [$userName!]',
                    textAlign: TextAlign.center,
                    highlight: pop(
                      26,
                      FontWeight.w800,
                      MssColors.saffronDeep,
                      1,
                    ),
                    style: pop(26, FontWeight.w800, kInk, 1, height: 1.2),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: HighlightText(
                    l10n.sv2VoiceIntro,
                    textAlign: TextAlign.center,
                    highlight: pop(14, FontWeight.w700, kInk, 1),
                    style: pop(14, FontWeight.w500, kBody, 1, height: 1.5),
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: Text(
                    l10n.sv2AskSaarthi,
                    style: pop(
                      13,
                      FontWeight.w700,
                      kInk,
                      1,
                    ).copyWith(letterSpacing: .6),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MssColors.saffron.withValues(alpha: .35),
                          spreadRadius: 8,
                        ),
                        const BoxShadow(
                          color: Color(0x59000080),
                          blurRadius: 30,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: RoundIconButton(
                      key: const Key('saarthi-start-speaking'),
                      icon: Icons.mic_none_rounded,
                      tooltip: l10n.sv2StartTalking,
                      bg: kInk,
                      fg: Colors.white,
                      size: 76,
                      iconSize: 32,
                      onTap: onStart,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'தமிழ் · हिन्दी · English · मराठी', // i18n-ok: language names
                    style: pop(11.5, FontWeight.w500, kMuted, 1),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 32,
              right: 32,
              bottom: 20,
              child: _PillNav(onDiscover: onDiscover, onSettings: onSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillNav extends StatelessWidget {
  const _PillNav({required this.onDiscover, required this.onSettings});

  final VoidCallback onDiscover;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget item(IconData icon, String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: kInk),
              const SizedBox(height: 2),
              Text(label, style: pop(11, FontWeight.w600, kInk, 1)),
            ],
          ),
        ),
      ),
    );
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000050),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Long Tamil / Hindi labels shrink rather than overflow.
          for (final w in <Widget>[
            Semantics(
              selected: true,
              label: l10n.navHome,
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: kInk,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.navHome,
                      style: pop(12, FontWeight.w600, Colors.white, 1),
                    ),
                  ],
                ),
              ),
            ),
            item(Icons.explore_outlined, l10n.navDiscover, onDiscover),
            item(
              Icons.settings_outlined,
              l10n.profileSettingsTitle,
              onSettings,
            ),
          ])
            Flexible(
              child: FittedBox(fit: BoxFit.scaleDown, child: w),
            ),
        ],
      ),
    );
  }
}
