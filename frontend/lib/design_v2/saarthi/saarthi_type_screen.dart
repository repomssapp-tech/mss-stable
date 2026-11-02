// Saarthi Type mode (v2 design): R1 Ask, then R2 Results once a question is
// sent. Talks to the backend text assistant (POST /chat) through
// SarvamChatClient, reveals replies gradually, keeps the AI disclaimer on
// screen, shows the catalog schemes a reply names, and saves the
// conversation on this phone (LocalChatHistory).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state_provider.dart';
import '../../services/chat/chat_log_service.dart';
import '../../services/chat/local_chat_history.dart';
import '../../services/chat/sarvam_chat_service.dart';
import '../highlight_text.dart';
import '../../utils/app_colors.dart';
import '../mss_design.dart';
import 'saarthi_kit.dart';
import 'scheme_mentions.dart';

class SaarthiTypeScreen extends StatefulWidget {
  const SaarthiTypeScreen({
    super.key,
    required this.profile,
    required this.language,
    this.client,
    this.onSwitchToVoice,
    this.history,
    this.resume,
  });

  final UserProfile profile;
  final String language;
  final SarvamChatClient? client;

  /// The Type / Voice switch. Null: the Voice segment just closes this screen.
  final VoidCallback? onSwitchToVoice;

  /// Defaults to [LocalChatHistory.instance].
  final LocalChatHistory? history;

  /// A saved typed conversation to continue.
  final SavedChat? resume;

  @override
  State<SaarthiTypeScreen> createState() => _SaarthiTypeScreenState();
}

class _Entry {
  _Entry(this.message, this.at, [this.schemes = const []]);

  final SarvamChatMessage message;
  final DateTime at;
  List<Scheme> schemes;
}

class _SaarthiTypeScreenState extends State<SaarthiTypeScreen> {
  late final SarvamChatClient _client;
  late final LocalChatHistory _history;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _chatLog = ChatLogService();
  final List<_Entry> _entries = [];
  late final String _chatId;
  late final DateTime _createdAt;
  bool _sending = false;
  String? _error;
  Timer? _revealTimer;
  int? _revealing;
  String _visible = '';

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? RestSarvamChatClient();
    _history = widget.history ?? LocalChatHistory.instance;
    final resume = widget.resume;
    _chatId = resume?.id ?? 't${DateTime.now().microsecondsSinceEpoch}';
    _createdAt = resume?.createdAt ?? DateTime.now();
    if (resume != null) {
      for (final m in resume.messages) {
        _entries.add(
          _Entry(SarvamChatMessage(role: m.role, content: m.text), m.at),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSchemes());
    }
  }

  void _restoreSchemes() {
    if (!mounted) return;
    final all = context.read<AppProvider?>()?.allSchemes ?? const <Scheme>[];
    final byId = {for (final s in all) s.id: s};
    final saved = widget.resume!.messages;
    setState(() {
      for (var i = 0; i < _entries.length && i < saved.length; i++) {
        _entries[i].schemes = [for (final id in saved[i].schemeIds) ?byId[id]];
      }
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    unawaited(_chatLog.syncChatSession(mode: 'text'));
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<SarvamChatMessage> get _messages => [
    for (final e in _entries) e.message,
  ];

  Future<void> _send([String? preset]) async {
    if (_sending) return;
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    _input.clear();
    setState(() {
      _entries.add(
        _Entry(SarvamChatMessage(role: 'user', content: text), DateTime.now()),
      );
      _sending = true;
      _error = null;
    });
    _chatLog.recordUserMessage(text);
    _scrollToEnd();
    await _requestReply();
  }

  Future<void> _requestReply() async {
    try {
      final response = await _client.complete(
        messages: List.unmodifiable(_messages),
        language: widget.language,
      );
      if (!mounted) return;
      final catalog =
          context.read<AppProvider?>()?.allSchemes ?? const <Scheme>[];
      setState(() {
        _entries.add(
          _Entry(
            SarvamChatMessage(role: 'assistant', content: response.reply),
            DateTime.now(),
            schemesMentionedIn(response.reply, catalog),
          ),
        );
      });
      _chatLog.recordAiMessage(response.reply);
      unawaited(_save());
      _reveal(response.reply);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error is SarvamChatException
            ? error.message
            : context.l10n.sarvamCouldNotReach;
      });
    }
  }

  Future<void> _save() => _history.save(
    SavedChat(
      id: _chatId,
      mode: 'type',
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      messages: [
        for (final e in _entries)
          SavedChatMessage(
            role: e.message.role,
            text: e.message.content,
            at: e.at,
            schemeIds: [for (final s in e.schemes) s.id],
          ),
      ],
    ),
  );

  void _reveal(String reply) {
    _revealTimer?.cancel();
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      setState(() => _sending = false);
      return;
    }
    // Whole grapheme clusters, so Tamil/Hindi vowel signs are never split.
    final characters = reply.characters.toList(growable: false);
    var count = characters.length.clamp(0, 3);
    setState(() {
      _revealing = _entries.length - 1;
      _visible = characters.take(count).join();
    });
    _revealTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      count = (count + 3).clamp(0, characters.length);
      setState(() {
        _visible = characters.take(count).join();
        if (count == characters.length) {
          timer.cancel();
          _revealing = null;
          _sending = false;
        }
      });
    });
  }

  Future<void> _retry() async {
    if (_sending || _entries.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    await _requestReply();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _switchToVoice() {
    final onSwitch = widget.onSwitchToVoice;
    if (onSwitch != null) {
      onSwitch();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignTextScale(
      child: _entries.isEmpty ? _buildAsk(context) : _buildResults(context),
    );
  }

  // ─────────────── R1 · Ask ───────────────
  Widget _buildAsk(BuildContext context) {
    final l10n = context.l10n;
    final trimmed = widget.profile.name.trim();
    final name = trimmed.isEmpty
        ? l10n.saarthiGreetingFriend
        : trimmed.split(' ').first;
    Widget chip(String label, Color ring) => Material(
      color: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: ring, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _send(label),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, style: pop(13, FontWeight.w600, kInk, 1)),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            left: -90,
            bottom: 120,
            child: _glow(300, AppColors.primary.withValues(alpha: .08)),
          ),
          Positioned(
            right: -110,
            bottom: 40,
            width: 320,
            height: 320,
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _glow(320, AppColors.primaryLight.withValues(alpha: .10)),
                  Positioned(
                    left: -113,
                    top: -9,
                    width: 398,
                    height: 368,
                    child: ExcludeSemantics(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(-1, 1, 1),
                        child: Image.asset(
                          MssAssets.saarthiPresent,
                          fit: BoxFit.fill,
                          cacheWidth: 720,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop()) ...[
                        RoundIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onTap: () => Navigator.of(context).maybePop(),
                          iconSize: 16,
                        ),
                        const SizedBox(width: 8),
                      ],
                      ExcludeSemantics(
                        child: Image.asset(
                          MssAssets.logo,
                          width: 36,
                          height: 36,
                          cacheWidth: 120,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: SaarthiTitle()),
                      ModeToggle(voiceActive: false, onSwitch: _switchToVoice),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HighlightText(
                          l10n.sv2TypeGreeting(name),
                          highlight: pop(
                            32,
                            FontWeight.w800,
                            AppColors.primary,
                            1,
                          ),
                          style: pop(
                            32,
                            FontWeight.w800,
                            kInk,
                            1,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.sv2TypeIntro,
                          style: pop(
                            13,
                            FontWeight.w500,
                            kBody,
                            1,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        chip(l10n.sv2ChipPmegp, AppColors.primary),
                        const SizedBox(height: 10),
                        chip(l10n.sv2ChipWomen, AppColors.success),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: _composer(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          context.l10n.aiDisclaimerNotice,
          textAlign: TextAlign.center,
          style: pop(11, FontWeight.w500, kMuted, 1),
        ),
      ),
      TypeBar(
        key: const Key('sarvam-chat-composer'),
        controller: _input,
        focusNode: _focus,
        onSend: _send,
        enabled: !_sending,
      ),
    ],
  );

  // ─────────────── R2 · Results ───────────────
  Widget _buildResults(BuildContext context) {
    final l10n = context.l10n;
    final lastAssistant = _entries.lastIndexWhere(
      (e) => e.message.role == 'assistant',
    );
    final itemCount =
        _entries.length +
        (_sending && _revealing == null ? 1 : 0) +
        (_error != null ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatHeader(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: () => Navigator.of(context).maybePop(),
              iconSize: 16,
            ),
            const SizedBox(width: 10),
            ExcludeSemantics(
              child: Image.asset(
                MssAssets.logo,
                width: 30,
                height: 30,
                cacheWidth: 100,
              ),
            ),
          ],
        ),
        title: const SaarthiTitle(size: 17),
        actions: [
          // Bounded share of the header so the toggle scales down on
          // narrow phones instead of squeezing the title.
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: ModeToggle(voiceActive: false, onSwitch: _switchToVoice),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index < _entries.length) {
                    final e = _entries[index];
                    final isUser = e.message.role == 'user';
                    final text = index == _revealing
                        ? _visible
                        : e.message.content;
                    return Padding(
                      key: ValueKey('sarvam-message-$index'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: isUser
                          ? UserBubble(
                              text: text,
                              meta:
                                  '${l10n.sv2You} · ${sv2Time(context, e.at)}',
                            )
                          : SaarthiBubble(
                              text: text,
                              meta:
                                  '${l10n.sv2Name} · ${sv2Time(context, e.at)}',
                              below: index == _revealing
                                  ? const []
                                  : [
                                      if (e.schemes.isNotEmpty)
                                        SchemeMatches(
                                          schemes: e.schemes,
                                          language: widget.language,
                                        ),
                                      if (index == lastAssistant && !_sending)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _followUp(l10n.sv2FollowEligible),
                                            _followUp(l10n.sv2FollowDocuments),
                                          ],
                                        ),
                                    ],
                            ),
                    );
                  }
                  if (_sending && index == _entries.length) {
                    return SaarthiBubble(
                      key: const Key('sarvam-chat-thinking'),
                      text: '',
                      child: Text(
                        l10n.sv2Thinking,
                        style: pop(13, FontWeight.w500, kMuted, 1),
                      ),
                    );
                  }
                  return _errorBubble(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _composer(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _followUp(String t) => ActionChip(
    onPressed: () => _send(t),
    backgroundColor: Colors.white,
    side: const BorderSide(color: Color(0x240F172A)),
    shape: const StadiumBorder(),
    label: Text(t, style: pop(12, FontWeight.w600, kInk, 1)),
  );

  Widget _errorBubble(BuildContext context) => SaarthiBubble(
    text: '',
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _error!,
            style: pop(13, FontWeight.w500, kInk, 1, height: 1.4),
          ),
        ),
        TextButton(
          key: const Key('sarvam-chat-retry'),
          onPressed: _retry,
          child: Text(context.l10n.retry),
        ),
      ],
    ),
  );
}

Widget _glow(double size, Color c) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
);
