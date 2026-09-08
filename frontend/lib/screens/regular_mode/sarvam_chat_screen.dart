import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile.dart';
import '../../services/chat_log_service.dart';
import '../../services/sarvam_chat_service.dart';
import '../../utils/app_spacing.dart';

class SarvamChatScreen extends StatefulWidget {
  const SarvamChatScreen({
    super.key,
    required this.profile,
    required this.language,
    this.client,
  });

  final UserProfile profile;
  final String language;
  final SarvamChatClient? client;

  @override
  State<SarvamChatScreen> createState() => _SarvamChatScreenState();
}

class _SarvamChatScreenState extends State<SarvamChatScreen> {
  late final SarvamChatClient _client;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _chatLog = ChatLogService();
  final List<SarvamChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

  bool get _isTamil => widget.language == 'ta';

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? SupabaseSarvamChatClient();
  }

  @override
  void dispose() {
    unawaited(_chatLog.syncChatSession(mode: 'text'));
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedText]) async {
    if (_sending) return;
    final text = (suggestedText ?? _inputController.text).trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    _inputController.clear();
    setState(() {
      _messages.add(SarvamChatMessage(role: 'user', content: text));
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
      setState(() {
        _messages.add(
          SarvamChatMessage(role: 'assistant', content: response.reply),
        );
        _sending = false;
      });
      _chatLog.recordAiMessage(response.reply);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error is SarvamChatException
            ? error.message
            : (_isTamil
                  ? 'சார்த்தியை அணுக முடியவில்லை. மீண்டும் முயலவும்.'
                  : 'Could not reach Saarthi. Please try again.');
      });
    }
    _scrollToEnd();
  }

  Future<void> _retry() async {
    if (_sending || _messages.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    await _requestReply();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF2563EB),
                size: 19,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saarthi',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _isTamil ? 'Sarvam AI மூலம்' : 'Powered by Sarvam AI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount:
                          _messages.length +
                          (_sending ? 1 : 0) +
                          (_error != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _messages.length) {
                          return _MessageBubble(message: _messages[index]);
                        }
                        if (_sending && index == _messages.length) {
                          return const _ThinkingBubble();
                        }
                        return _ErrorBubble(
                          message: _error!,
                          isTamil: _isTamil,
                          onRetry: _retry,
                        );
                      },
                    ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    final trimmedName = widget.profile.name.trim();
    final name = trimmedName.isEmpty ? '' : trimmedName.split(' ').first;
    final title = _isTamil
        ? '${name.isNotEmpty ? '$name, ' : ''}நான் எப்படி உதவலாம்?'
        : '${name.isNotEmpty ? '$name, ' : ''}How can I help?';
    final prompts = _isTamil
        ? const [
            'எனக்கான திட்டங்களைக் கண்டறியவும்',
            'MSME கடன் பற்றி சொல்லுங்கள்',
          ]
        : const ['Find schemes for me', 'Explain MSME loans'];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2563EB),
              size: 34,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                height: 1.2,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isTamil
                  ? 'திட்டங்கள், தகுதி மற்றும் விண்ணப்ப வழிமுறைகள் பற்றி கேளுங்கள்.'
                  : 'Ask about schemes, eligibility, or how to apply.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: prompts
                  .map(
                    (prompt) => ActionChip(
                      onPressed: () => _send(prompt),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: Colors.white,
                      label: Text(prompt),
                      labelStyle: GoogleFonts.inter(
                        color: const Color(0xFF334155),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('sarvam-chat-input'),
              controller: _inputController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                counterText: '',
                hintText: _isTamil
                    ? 'சார்த்தியிடம் கேளுங்கள்…'
                    : 'Ask Saarthi…',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            key: const Key('sarvam-chat-send'),
            onPressed: _sending ? null : _send,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              minimumSize: const Size(46, 46),
            ),
            tooltip: _isTamil ? 'அனுப்பு' : 'Send',
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SarvamChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final baseStyle = GoogleFonts.inter(
      fontSize: 14,
      height: 1.45,
      color: isUser ? Colors.white : const Color(0xFF1E293B),
    );
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(5) : null,
            bottomLeft: isUser ? null : const Radius.circular(5),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        // Model replies arrive as markdown; user messages are plain text.
        child: isUser
            ? SelectableText(message.content, style: baseStyle)
            : _MarkdownBody(text: message.content, baseStyle: baseStyle),
      ),
    );
  }
}

/// Minimal markdown renderer for LLM chat replies -- handles the small
/// subset the model actually emits: `**bold**` / `__bold__`,
/// `*italic*` / `_italic_`, `` `code` ``, `#`/`##`/`###` headings,
/// `-`/`*`/`•` bullets and `1.` ordered items. Anything else renders as
/// plain text. Inlined here to avoid a markdown package dependency.
class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.text, required this.baseStyle});

  final String text;
  final TextStyle baseStyle;

  static final RegExp _heading = RegExp(r'^(#{1,3})\s+(.*)$');
  static final RegExp _bullet = RegExp(r'^([-*•])\s+(.*)$');
  static final RegExp _ordered = RegExp(r'^(\d+)[.)]\s+(.*)$');
  static final RegExp _inlinePattern = RegExp(
    r'(\*\*|__)(.+?)\1|(\*|_)(.+?)\3|`([^`]+)`',
    dotAll: true,
  );

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        blocks.add(const SizedBox(height: AppSpacing.tight));
        continue;
      }

      final heading = _heading.firstMatch(trimmed);
      if (heading != null) {
        final level = heading.group(1)!.length;
        final bump = level == 1 ? 3.0 : (level == 2 ? 2.0 : 1.0);
        blocks.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.hairline),
          child: SelectableText.rich(
            _inline(
              heading.group(2)!,
              baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: (baseStyle.fontSize ?? 14) + bump,
              ),
            ),
          ),
        ));
        continue;
      }

      final bullet = _bullet.firstMatch(trimmed);
      if (bullet != null) {
        blocks.add(_listRow('•  ', bullet.group(2)!));
        continue;
      }

      final ordered = _ordered.firstMatch(trimmed);
      if (ordered != null) {
        blocks.add(_listRow('${ordered.group(1)}.  ', ordered.group(2)!));
        continue;
      }

      blocks.add(SelectableText.rich(_inline(line, baseStyle)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  Widget _listRow(String marker, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.hairline),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marker, style: baseStyle),
          Expanded(child: SelectableText.rich(_inline(content, baseStyle))),
        ],
      ),
    );
  }

  TextSpan _inline(String input, TextStyle style) {
    final spans = <TextSpan>[];
    var index = 0;
    for (final m in _inlinePattern.allMatches(input)) {
      if (m.start > index) {
        spans.add(TextSpan(text: input.substring(index, m.start), style: style));
      }
      if (m.group(2) != null) {
        spans.add(TextSpan(
          text: m.group(2),
          style: style.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(
          text: m.group(4),
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(
          text: m.group(5),
          style: style.copyWith(
            fontFamily: 'monospace',
            backgroundColor: style.color?.withValues(alpha: 0.08),
          ),
        ));
      }
      index = m.end;
    }
    if (index < input.length) {
      spans.add(TextSpan(text: input.substring(index), style: style));
    }
    if (spans.isEmpty) {
      return TextSpan(text: input, style: style);
    }
    return TextSpan(children: spans);
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      key: const Key('sarvam-chat-thinking'),
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({
    required this.message,
    required this.isTamil,
    required this.onRetry,
  });

  final String message;
  final bool isTamil;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: const Color(0xFF9A3412),
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              key: const Key('sarvam-chat-retry'),
              onPressed: onRetry,
              child: Text(isTamil ? 'மீண்டும்' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
