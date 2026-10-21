import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/voice/saarthi_conversation_controller.dart';
import '../../../services/voice/voice_language.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_size.dart';
import '../saarthi_message.dart';
import 'saarthi_transcript_view.dart';

/// One scrollable conversation surface. Editing and preferences stay inline;
/// the microphone is paused before either can change the next turn.
class SaarthiLiveConversationView extends StatefulWidget {
  const SaarthiLiveConversationView({
    super.key,
    required this.conversation,
    required this.messages,
    required this.scrollController,
    required this.waveController,
    required this.onEndConversation,
  });

  final SaarthiConversationController conversation;
  final List<SaarthiMessage> messages;
  final ScrollController scrollController;
  final AnimationController waveController;
  final VoidCallback onEndConversation;

  @override
  State<SaarthiLiveConversationView> createState() =>
      _SaarthiLiveConversationViewState();
}

class _SaarthiLiveConversationViewState
    extends State<SaarthiLiveConversationView> {
  final _editor = TextEditingController();
  final _editorFocus = FocusNode();
  final _messageKeys = <String, GlobalKey>{};
  bool _wasEditing = false;

  SaarthiConversationController get conversation => widget.conversation;

  @override
  void initState() {
    super.initState();
    conversation.addListener(_changed);
    _syncEditor();
  }

  @override
  void didUpdateWidget(covariant SaarthiLiveConversationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation != conversation) {
      oldWidget.conversation.removeListener(_changed);
      conversation.addListener(_changed);
      _wasEditing = false;
    }
    _syncEditor();
  }

  void _syncEditor() {
    if (conversation.editing && !_wasEditing) {
      _editor.text = conversation.draft;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && conversation.editing) _editorFocus.requestFocus();
      });
    }
    _wasEditing = conversation.editing;
  }

  void _changed() {
    if (!mounted) return;
    _syncEditor();
    setState(() {});
  }

  @override
  void dispose() {
    conversation.removeListener(_changed);
    _editor.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  String _status(BuildContext context) => switch (conversation.phase) {
    ConversationPhase.idle => context.l10n.liveVoiceReady,
    ConversationPhase.connecting => context.l10n.liveVoiceConnecting,
    ConversationPhase.listening => context.l10n.liveVoiceListening,
    ConversationPhase.transcribing => context.l10n.liveVoiceTranscribing,
    ConversationPhase.thinking => context.l10n.liveVoiceThinking,
    ConversationPhase.speaking => context.l10n.liveVoiceSpeaking,
    ConversationPhase.paused => context.l10n.liveVoicePaused,
    ConversationPhase.error => context.l10n.liveVoiceError,
  };

  String _error(BuildContext context) =>
      switch (conversation.error?.toUpperCase()) {
        'MIC_PERMISSION' => context.l10n.liveVoiceMicrophonePermission,
        'NO_SPEECH' || 'SILENCE_TIMEOUT' => context.l10n.liveVoiceNoSpeech,
        'UNAUTHORIZED' ||
        'AUTH_REQUIRED' ||
        'INVALID_TOKEN' ||
        '401' => context.l10n.saarthiCloudErrorSignIn,
        'FINAL_TIMEOUT' ||
        'VOICE_FINAL_TIMEOUT' => context.l10n.liveVoiceFinalTimeout,
        _ => context.l10n.liveVoiceConnectionError,
      };

  Future<void> _edit({bool blank = false}) async {
    await conversation.correct(blank: blank);
    if (!mounted) return;
    _editor.text = conversation.draft;
    _editorFocus.requestFocus();
  }

  void _latest() {
    if (widget.messages.isEmpty || !widget.scrollController.hasClients) return;
    final key = _messageKeys[widget.messages.last.id];
    void reveal() {
      if (!mounted || widget.messages.isEmpty) return;
      final target = _messageKeys[widget.messages.last.id]?.currentContext;
      if (target != null) {
        unawaited(Scrollable.ensureVisible(target, alignment: 0));
      }
    }

    if (key?.currentContext != null) {
      reveal();
    } else {
      widget.scrollController.jumpTo(
        widget.scrollController.position.maxScrollExtent,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => reveal());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final paused = [
      ConversationPhase.idle,
      ConversationPhase.paused,
      ConversationPhase.error,
    ].contains(conversation.phase);
    final lastAssistant = widget.messages.lastIndexWhere(
      (message) => message.role == 'assistant',
    );
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.liveVoiceTitle,
                    style: text.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton.icon(
                    key: const Key('live-voice-end'),
                    onPressed: widget.onEndConversation,
                    icon: const Icon(Icons.close),
                    label: Text(l10n.liveVoiceEnd),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            key: const Key('live-voice-scroll'),
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        key: const Key('live-voice-status'),
                        container: true,
                        liveRegion: true,
                        excludeSemantics: true,
                        label: _status(context),
                        child: Text(
                          _status(context),
                          style: text.titleMedium?.copyWith(
                            color: conversation.phase == ConversationPhase.error
                                ? AppColors.dangerStrong
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (conversation.screenReader)
                        Text(
                          l10n.liveVoiceScreenReaderShort,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (conversation.error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error(context),
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.dangerStrong,
                          ),
                        ),
                      ],
                      if (!conversation.editing &&
                          conversation.draft.isNotEmpty &&
                          [
                            ConversationPhase.listening,
                            ConversationPhase.transcribing,
                          ].contains(conversation.phase)) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.liveVoiceHeard, style: text.labelLarge),
                        // Partial text is readable on demand, never a live region.
                        Text(
                          conversation.draft,
                          key: const Key('live-voice-draft'),
                          style: text.bodyLarge,
                        ),
                      ],
                      if (conversation.phase == ConversationPhase.listening)
                        TextButton.icon(
                          key: const Key('live-voice-finish'),
                          onPressed: () => unawaited(conversation.finishTurn()),
                          icon: const Icon(Icons.done),
                          label: Text(l10n.liveVoiceFinish),
                        ),
                      if (conversation.editing) _buildEditor(context),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          TextButton.icon(
                            key: const Key('live-voice-correct'),
                            onPressed:
                                conversation.draft.isEmpty &&
                                    conversation.lastRequest.isEmpty
                                ? null
                                : () => unawaited(_edit()),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l10n.liveVoiceCorrect),
                          ),
                          TextButton.icon(
                            key: const Key('live-voice-type'),
                            onPressed: () => unawaited(_edit(blank: true)),
                            icon: const Icon(Icons.keyboard_outlined),
                            label: Text(l10n.liveVoiceType),
                          ),
                          TextButton.icon(
                            key: const Key('live-voice-repeat'),
                            onPressed: lastAssistant < 0
                                ? null
                                : () => unawaited(conversation.repeat()),
                            icon: const Icon(Icons.replay),
                            label: Text(l10n.liveVoiceRepeat),
                          ),
                        ],
                      ),
                      _buildOptions(context),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList.builder(
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.messages[index];
                    return KeyedSubtree(
                      key: _messageKeys.putIfAbsent(message.id, GlobalKey.new),
                      child: Semantics(
                        key: ValueKey('live-message-${message.id}'),
                        container: true,
                        liveRegion:
                            conversation.screenReader &&
                            index == lastAssistant &&
                            message.status != 'transcribing',
                        child: message.role == 'user'
                            ? SaarthiUserMessage(message: message)
                            : SaarthiAiMessage(
                                message: message,
                                waveController: widget.waveController,
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          ),
        ),
        Material(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: conversation.editing
                  ? _buildSendButton(context)
                  : Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const Key('live-voice-pause-resume'),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              unawaited(
                                paused
                                    ? (conversation.active
                                          ? conversation.resume()
                                          : conversation.start())
                                    : conversation.pause(),
                              );
                            },
                            icon: Icon(paused ? Icons.mic : Icons.pause),
                            label: Text(
                              paused
                                  ? l10n.liveVoiceResume
                                  : l10n.liveVoicePause,
                            ),
                          ),
                        ),
                        if (widget.messages.isNotEmpty)
                          IconButton(
                            key: const Key('live-voice-latest'),
                            tooltip: l10n.liveVoiceLatest,
                            constraints: const BoxConstraints(
                              minWidth: AppSize.tapTarget,
                              minHeight: AppSize.tapTarget,
                            ),
                            onPressed: _latest,
                            icon: const Icon(Icons.arrow_downward),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('live-voice-editor'),
          controller: _editor,
          focusNode: _editorFocus,
          minLines: 2,
          maxLines: 6,
          maxLength: 2000,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: context.l10n.liveVoiceEditRequest,
            helperText: context.l10n.liveVoiceEditingHint,
            helperMaxLines: 4,
            border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
  );

  Widget _buildSendButton(BuildContext context) => FilledButton.icon(
    key: const Key('live-voice-send'),
    onPressed: _editor.text.trim().isEmpty
        ? null
        : () {
            FocusScope.of(context).unfocus();
            unawaited(conversation.send(_editor.text));
          },
    icon: const Icon(Icons.send),
    label: Text(context.l10n.send),
  );

  Widget _buildOptions(BuildContext context) => ExpansionTile(
    key: const Key('live-voice-options'),
    tilePadding: EdgeInsets.zero,
    title: Text(
      context.l10n.liveVoiceOptions,
      style: Theme.of(context).textTheme.titleSmall,
    ),
    onExpansionChanged: (expanded) {
      if (expanded) unawaited(conversation.pause());
    },
    children: [
      Text(
        conversation.screenReader
            ? context.l10n.liveVoiceScreenReaderHint
            : context.l10n.liveVoiceConversationHint,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<String>(
        key: const Key('live-voice-language'),
        initialValue: VoiceLanguage.code(conversation.language),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.l10n.voiceSpokenLanguage,
          border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
        ),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')), // i18n-ok
          DropdownMenuItem(value: 'ta', child: Text('தமிழ்')), // i18n-ok
          DropdownMenuItem(value: 'hi', child: Text('हिन्दी')), // i18n-ok
          DropdownMenuItem(value: 'mr', child: Text('मराठी')), // i18n-ok
        ],
        onChanged: (value) {
          if (value != null) {
            unawaited(conversation.configure(languageCode: value));
          }
        },
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(context.l10n.liveVoiceLongPauses),
        subtitle: Text(context.l10n.liveVoiceLongPausesHint),
        value: conversation.longerPauses,
        onChanged: (value) =>
            unawaited(conversation.configure(longPauses: value)),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(context.l10n.liveVoiceReadAloud),
        value: conversation.readAloud,
        onChanged: (value) => unawaited(conversation.configure(aloud: value)),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(context.l10n.liveVoiceReview),
        subtitle: Text(context.l10n.liveVoiceReviewHint),
        value: conversation.reviewBeforeSend,
        onChanged: (value) => unawaited(conversation.configure(review: value)),
      ),
    ],
  );
}
