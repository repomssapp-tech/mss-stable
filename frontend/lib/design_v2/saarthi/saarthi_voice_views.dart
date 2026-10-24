// The three in-conversation views of Saarthi Voice mode (v2 design):
// C2 Listening (live transcript), C3 "Did I hear you right?", and C4 the
// conversation room. They only draw the SaarthiConversationController's
// state and call it back; the screen owns the controller.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../screens/companion_mode/saarthi_message.dart';
import '../../services/voice/saarthi_conversation_controller.dart';
import '../mss_design.dart';
import 'saarthi_kit.dart';

/// Name of a voice language in its own script.
String voiceLanguageName(String code) => switch (code) {
  'ta' => 'தமிழ்', // i18n-ok
  'hi' => 'हिन्दी', // i18n-ok
  'mr' => 'मराठी', // i18n-ok
  _ => 'English', // i18n-ok
};

/// Localised text for a conversation error code.
String voiceErrorText(BuildContext context, String? code) {
  final l10n = context.l10n;
  return switch (code?.toUpperCase()) {
    'MIC_PERMISSION' => l10n.liveVoiceMicrophonePermission,
    'NO_SPEECH' || 'SILENCE_TIMEOUT' => l10n.liveVoiceNoSpeech,
    'UNAUTHORIZED' ||
    'AUTH_REQUIRED' ||
    'INVALID_TOKEN' ||
    '401' => l10n.saarthiCloudErrorSignIn,
    'SPEECH-UNAVAILABLE' => l10n.liveVoiceSpeechUnavailable,
    'FINAL_TIMEOUT' || 'VOICE_FINAL_TIMEOUT' => l10n.liveVoiceFinalTimeout,
    _ => l10n.liveVoiceConnectionError,
  };
}

// ─────────────── C2 · Listening ───────────────
class SaarthiListeningView extends StatefulWidget {
  const SaarthiListeningView({
    super.key,
    required this.conversation,
    required this.onClose,
  });

  final SaarthiConversationController conversation;
  final VoidCallback onClose;

  @override
  State<SaarthiListeningView> createState() => _SaarthiListeningViewState();
}

class _SaarthiListeningViewState extends State<SaarthiListeningView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWave();
  }

  @override
  void didUpdateWidget(covariant SaarthiListeningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWave();
  }

  // The wave runs only while Saarthi is actually listening.
  void _syncWave() {
    final listening =
        widget.conversation.phase == ConversationPhase.listening &&
        !MediaQuery.disableAnimationsOf(context);
    if (listening && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!listening && _wave.isAnimating) {
      _wave.stop();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.conversation;
    final listening = c.phase == ConversationPhase.listening;
    final status = switch (c.phase) {
      ConversationPhase.listening => l10n.sv2Listening(
        voiceLanguageName(c.language),
      ),
      ConversationPhase.transcribing => l10n.sv2Transcribing,
      _ => l10n.sv2Connecting,
    };
    return Container(
      key: const Key('sv2-listening'),
      color: kInk,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: MssColors.saffron,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        status,
                        style: pop(13, FontWeight.w600, Colors.white, 1),
                      ),
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.close_rounded,
                    tooltip: l10n.sv2EndConversation,
                    bg: Colors.white.withValues(alpha: .14),
                    fg: Colors.white,
                    size: 40,
                    onTap: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                l10n.sv2YourSpeech,
                style: pop(
                  12,
                  FontWeight.w600,
                  const Color(0xFFFFB766),
                  1,
                ).copyWith(letterSpacing: .7),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: c.draft),
                        if (listening)
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: SizedBox(
                                width: 3,
                                height: 26,
                                child: ColoredBox(color: MssColors.saffron),
                              ),
                            ),
                          ),
                      ],
                    ),
                    style: pop(
                      24,
                      FontWeight.w700,
                      Colors.white,
                      1,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ExcludeSemantics(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (_, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(21, (i) {
                        final h =
                            10 +
                            (math.sin(
                                  i * .9 + _wave.value * math.pi * 4,
                                )).abs() *
                                46 *
                                (1 - (i - 10).abs() / 13);
                        final color = i % 3 == 0
                            ? MssColors.saffron
                            : (i % 3 == 1
                                  ? Colors.white
                                  : const Color(0xFF3FBF35));
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: 5,
                          height: listening ? h : 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MssColors.saffron.withValues(alpha: .10),
                            spreadRadius: 30,
                          ),
                          BoxShadow(
                            color: MssColors.saffron.withValues(alpha: .22),
                            spreadRadius: 14,
                          ),
                        ],
                      ),
                      child: RoundIconButton(
                        key: const Key('sv2-finish-turn'),
                        icon: Icons.mic_none_rounded,
                        tooltip: l10n.sv2TapWhenDone,
                        bg: MssColors.saffron,
                        fg: kInk,
                        size: 92,
                        iconSize: 36,
                        onTap: listening ? c.finishTurn : null,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.sv2TapWhenDone,
                      textAlign: TextAlign.center,
                      style: pop(
                        13,
                        FontWeight.w500,
                        Colors.white.withValues(alpha: .85),
                        1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── C3 · Confirm ───────────────
class SaarthiConfirmView extends StatelessWidget {
  const SaarthiConfirmView({
    super.key,
    required this.conversation,
    required this.onDiscard,
  });

  final SaarthiConversationController conversation;
  final VoidCallback onDiscard;

  Future<void> _edit(BuildContext context) async {
    final l10n = context.l10n;
    final ctrl = TextEditingController(text: conversation.draft);
    final res = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          l10n.sv2EditTitle,
          style: pop(16, FontWeight.w700, kInk, 1),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 2000,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (res != null && res.trim().isNotEmpty) {
      conversation.updateDraft(res.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = conversation.draft;
    return Container(
      key: const Key('sv2-confirm'),
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      const SaarthiAvatar(size: 150, ring: true),
                      const SizedBox(height: 28),
                      Text(
                        l10n.sv2ConfirmTitle,
                        textAlign: TextAlign.center,
                        style: pop(22, FontWeight.w800, kInk, 1, height: 1.25),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: MssColors.saffron,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000050),
                              blurRadius: 30,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.sv2Transcribed,
                                    style: pop(
                                      10.5,
                                      FontWeight.w600,
                                      MssColors.eligibleAmber,
                                      1,
                                    ).copyWith(letterSpacing: .6),
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    '“$text”',
                                    style: pop(
                                      16,
                                      FontWeight.w600,
                                      kInk,
                                      1,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            RoundIconButton(
                              icon: Icons.edit_outlined,
                              tooltip: l10n.sv2EditTitle,
                              size: 40,
                              iconSize: 16,
                              onTap: () => _edit(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.sv2ConfirmHelp,
                        textAlign: TextAlign.center,
                        style: pop(12, FontWeight.w500, kMuted, 1),
                      ),
                    ],
                  ),
                ),
              ),
              VoiceActionBar(
                label: l10n.sv2Speak,
                onMic: conversation.resume,
                yesLabel: l10n.sv2Send,
                noLabel: l10n.sv2Discard,
                onYes: text.trim().isEmpty
                    ? null
                    : () => conversation.send(text),
                onNo: onDiscard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── C4 · Conversation room ───────────────
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
    required this.onEnd,
    required this.onHistory,
    required this.onSettings,
  });

  final SaarthiConversationController conversation;
  final List<SaarthiMessage> messages;
  final String userName;
  final String language;
  final ScrollController scrollController;
  final Set<int> readyDocuments;
  final ValueChanged<int> onToggleDocument;
  final VoidCallback onEnd;
  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = conversation;
    final lastAssistant = messages.lastIndexWhere((m) => m.role != 'user');
    final busy =
        c.phase == ConversationPhase.thinking ||
        c.phase == ConversationPhase.speaking;
    final status = switch (c.phase) {
      ConversationPhase.thinking => l10n.sv2Thinking,
      ConversationPhase.speaking => l10n.sv2Speaking,
      _ => null,
    };

    return Scaffold(
      key: const Key('sv2-room'),
      backgroundColor: Colors.white,
      appBar: ChatHeader(
        leading: const SaarthiAvatar(size: 38),
        title: SaarthiTitle(
          size: 17,
          subtitle: l10n.sv2Room,
          subtitleColor: MssColors.green,
          subtitleDot: true,
        ),
        actions: [
          RoundIconButton(
            key: const Key('sv2-open-history'),
            icon: Icons.history_rounded,
            tooltip: l10n.sv2HistoryOpen,
            onTap: onHistory,
          ),
          RoundIconButton(
            key: const Key('sv2-open-voice-settings'),
            icon: Icons.tune_rounded,
            tooltip: l10n.sv2VoiceSettingsOpen,
            onTap: onSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('voice-transcript-list'),
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              children: [
                SaarthiBubble(
                  avatarSize: 30,
                  text: l10n.sv2RoomHello(userName),
                ),
                for (var i = 0; i < messages.length; i++) ...[
                  const SizedBox(height: 12),
                  if (messages[i].role == 'user')
                    UserBubble(
                      text: messages[i].text,
                      meta: l10n.sv2YouVoice,
                      voice: true,
                    )
                  else
                    SaarthiBubble(
                      avatarSize: 30,
                      text: messages[i].text,
                      below: [
                        if ((messages[i].schemeResults ?? const []).isNotEmpty)
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
                if (status != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 38),
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
                      color: MssColors.saffronLight.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: MssColors.saffronText,
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
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: VoiceActionBar(
              label: l10n.sv2TapToSpeak,
              onMic: c.resume,
              yesLabel: l10n.sv2HearAgain,
              noLabel: l10n.sv2EndConversation,
              onYes: c.canRepeat && !busy ? c.repeat : null,
              onNo: onEnd,
            ),
          ),
        ],
      ),
    );
  }
}
