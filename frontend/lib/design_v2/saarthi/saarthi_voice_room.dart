// The Saarthi conversation (redesign). One screen with three bottom states: the
// mic and keyboard, the waveform pill while listening, and the text box while
// typing. Spoken and typed turns share one transcript. It only draws the
// SaarthiConversationController's state and calls back; the screen owns it.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../screens/companion_mode/saarthi_message.dart';
import '../../services/voice/saarthi_conversation_controller.dart';
import '../../utils/app_colors.dart';
import '../mss_design.dart';
import 'saarthi_kit.dart';
import 'saarthi_voice_home.dart';
import 'saarthi_voice_views.dart';

class SaarthiRoomView extends StatelessWidget {
  const SaarthiRoomView({
    super.key,
    required this.conversation,
    required this.messages,
    required this.userName,
    required this.language,
    required this.scrollController,
    required this.readyDocuments,
    required this.onToggleDocument,
    required this.typing,
    required this.typeController,
    required this.typeFocus,
    required this.onSpeak,
    required this.onType,
    required this.onSendTyped,
    required this.onHear,
    required this.nav,
  });

  final SaarthiConversationController conversation;
  final List<SaarthiMessage> messages;
  final String userName;
  final String language;
  final ScrollController scrollController;
  final Set<int> readyDocuments;
  final ValueChanged<int> onToggleDocument;
  final bool typing;
  final TextEditingController typeController;
  final FocusNode typeFocus;
  final VoidCallback onSpeak;
  final VoidCallback onType;
  final VoidCallback onSendTyped;
  final ValueChanged<String> onHear;
  final Widget nav;

  bool get _listening => const [
    ConversationPhase.connecting,
    ConversationPhase.listening,
    ConversationPhase.transcribing,
  ].contains(conversation.phase);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = conversation;
    final lastAssistant = messages.lastIndexWhere((m) => m.role != 'user');
    final status = switch (c.phase) {
      ConversationPhase.thinking => l10n.sv2Thinking,
      ConversationPhase.speaking => l10n.sv2Speaking,
      _ => null,
    };
    // Read from the window: the app shell's Scaffold already consumes the
    // keyboard's inset, so MediaQuery here always reports 0.
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;

    return Scaffold(
      key: const Key('sv2-room'),
      backgroundColor: kSaarthiBg,
      resizeToAvoidBottomInset: true,
      appBar: ChatHeader(
        leading: const SaarthiAvatar(size: 44),
        title: Text(l10n.sv2Name, style: pop(20, FontWeight.w800, kInk, 1)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const ValueKey('voice-transcript-list'),
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                children: [
                  SaarthiBubble(
                    avatarSize: 34,
                    text: l10n.sv2RoomHello(userName),
                  ),
                  for (var i = 0; i < messages.length; i++) ...[
                    const SizedBox(height: 16),
                    if (messages[i].role == 'user')
                      UserBubble(text: messages[i].text, meta: l10n.sv2You)
                    else
                      SaarthiBubble(
                        avatarSize: 34,
                        text: messages[i].text,
                        trailing: RoundIconButton(
                          key: Key('sv2-hear-$i'),
                          icon: Icons.campaign_outlined,
                          tooltip: l10n.sv2HearAgain,
                          iconSize: 20,
                          onTap: () => onHear(messages[i].text),
                        ),
                        below: [
                          if ((messages[i].schemeResults ?? const [])
                              .isNotEmpty)
                            SchemeMatches(
                              schemes: messages[i].schemeResults!,
                              language: language,
                            ),
                          if (i == lastAssistant &&
                              (messages[i].schemeResults ?? const [])
                                  .isNotEmpty &&
                              messages[i]
                                  .schemeResults!
                                  .first
                                  .requiredDocuments
                                  .isNotEmpty)
                            DocumentsCard(
                              documents: messages[i]
                                  .schemeResults!
                                  .first
                                  .requiredDocuments
                                  .take(6)
                                  .toList(),
                              ready: readyDocuments,
                              onToggle: onToggleDocument,
                            ),
                        ],
                      ),
                  ],
                  if (_listening && c.draft.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _LiveSpeech(text: c.draft),
                  ],
                  if (status != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 42),
                        child: Text(
                          status,
                          key: const Key('live-voice-status'),
                          style: pop(12.5, FontWeight.w600, kMuted, 1),
                        ),
                      ),
                    ),
                  ],
                  if (c.phase == ConversationPhase.error) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              voiceErrorText(context, c.error),
                              style: pop(13, FontWeight.w500, kInk, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_listening)
              _ListeningPill(conversation: c)
            else if (typing)
              _Composer(
                controller: typeController,
                focusNode: typeFocus,
                enabled: c.phase != ConversationPhase.thinking,
                onSpeak: onSpeak,
                onSend: onSendTyped,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SaarthiTalkControls(
                  micKey: const Key('sv2-room-mic'),
                  typeKey: const Key('sv2-room-type'),
                  onSpeak: onSpeak,
                  onType: onType,
                ),
              ),
            if (!keyboardOpen) nav,
          ],
        ),
      ),
    );
  }
}

/// The words heard so far, drawn like the user's bubble but not yet sent.
class _LiveSpeech extends StatelessWidget {
  const _LiveSpeech({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          // What Saarthi has heard so far: an outlined bubble, not yet sent.
          color: Colors.white,
          border: Border.all(color: const Color(0x59000080), width: 1.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: pop(14, FontWeight.w500, kBody, 1, height: 1.45),
        ),
      ),
    ),
  );
}

/// Takes the mic's place while listening. Grey and inactive until the voice
/// connection is up; then blue, with bars that follow the microphone's real
/// loudness, newest on the right. Tapping it finishes the turn.
class _ListeningPill extends StatefulWidget {
  const _ListeningPill({required this.conversation});

  final SaarthiConversationController conversation;

  @override
  State<_ListeningPill> createState() => _ListeningPillState();
}

class _ListeningPillState extends State<_ListeningPill> {
  static const _bars = 15;
  final List<double> _levels = List<double>.filled(_bars, 0, growable: true);
  Timer? _sampler;

  @override
  void initState() {
    super.initState();
    _sampler = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _sample(),
    );
  }

  void _sample() {
    final level = widget.conversation.phase == ConversationPhase.listening
        ? widget.conversation.inputLevel.value
        : 0.0;
    if (level == 0 && _levels.every((l) => l == 0)) return;
    setState(() {
      _levels
        ..removeAt(0)
        ..add(level);
    });
  }

  @override
  void dispose() {
    _sampler?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.conversation;
    final listening = c.phase == ConversationPhase.listening;
    final connected = c.phase != ConversationPhase.connecting;
    final status = switch (c.phase) {
      ConversationPhase.listening => l10n.sv2Listening(
        voiceLanguageName(c.language),
      ),
      ConversationPhase.transcribing => l10n.sv2Transcribing,
      _ => l10n.sv2Connecting,
    };
    return Padding(
      key: const Key('sv2-listening'),
      padding: const EdgeInsets.fromLTRB(40, 4, 40, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(status, style: pop(12.5, FontWeight.w600, kMuted, 1)),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Semantics(
              button: true,
              enabled: listening,
              label: connected ? l10n.sv2TapWhenDone : l10n.sv2Connecting,
              excludeSemantics: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    if (connected)
                      const BoxShadow(color: kSaffronHalo, spreadRadius: 6),
                  ],
                ),
                child: Material(
                  key: const Key('sv2-wave-pill'),
                  color: connected ? kBrand : AppColors.disabledBg,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    key: const Key('sv2-finish-turn'),
                    customBorder: const StadiumBorder(),
                    onTap: listening ? c.finishTurn : null,
                    child: SizedBox(
                      height: 60,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < _bars; i++)
                              Container(
                                key: Key('sv2-wave-$i'),
                                width: 3,
                                height: 6 + _levels[i] * 34,
                                decoration: BoxDecoration(
                                  color: !connected
                                      ? AppColors.disabledFg
                                      : i % 3 == 0
                                      ? MssColors.saffron
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text box in the conversation: a small mic back to speaking, then the
/// shared [TypeBar].
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSpeak,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSpeak;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.aiDisclaimerNotice,
              textAlign: TextAlign.center,
              style: pop(11, FontWeight.w500, kMuted, 1),
            ),
          ),
          Row(
            children: [
              RoundIconButton(
                key: const Key('sv2-composer-mic'),
                icon: Icons.mic_none_rounded,
                tooltip: l10n.sv2StartTalking,
                bg: Colors.white,
                border: true,
                size: 52,
                iconSize: 22,
                onTap: onSpeak,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TypeBar(
                  key: const Key('sarvam-chat-composer'),
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  onSend: onSend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
