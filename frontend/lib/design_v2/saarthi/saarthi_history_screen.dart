// Saarthi chat history (v2 design C5): every conversation saved on this
// phone, newest first, grouped Today / Yesterday / Earlier, searchable.
// A typed conversation reopens in Type mode to carry on; a spoken one opens
// as a read-only transcript.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../providers/app_state_provider.dart';
import '../../services/chat/local_chat_history.dart';
import '../../widgets/common/app_toast.dart';
import '../../utils/app_colors.dart';
import '../mss_design.dart';
import 'saarthi_kit.dart';
import 'saarthi_type_screen.dart';

class SaarthiHistoryScreen extends StatefulWidget {
  const SaarthiHistoryScreen({
    super.key,
    this.history,
    this.now,
    this.onOpen,
    this.bottomBar,
  });

  final LocalChatHistory? history;

  /// Set when shown as the Old sessions tab: a tapped chat is handed over to
  /// be continued, and the screen has no back button.
  final ValueChanged<SavedChat>? onOpen;

  /// The nav bar, when shown as a tab.
  final Widget? bottomBar;

  /// Today, for grouping; injected in tests.
  final DateTime Function()? now;

  @override
  State<SaarthiHistoryScreen> createState() => _SaarthiHistoryScreenState();
}

class _SaarthiHistoryScreenState extends State<SaarthiHistoryScreen> {
  late final LocalChatHistory _history =
      widget.history ?? LocalChatHistory.instance;
  final _search = TextEditingController();
  List<SavedChat>? _chats;

  static const _badgeColors = [
    AppColors.primaryTint,
    AppColors.successSoft,
    AppColors.surfaceMuted,
  ];

  @override
  void initState() {
    super.initState();
    _history.addListener(_load);
    _search.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    final chats = await _history.list();
    if (mounted) setState(() => _chats = chats);
  }

  @override
  void dispose() {
    _history.removeListener(_load);
    _search.dispose();
    super.dispose();
  }

  String _initials(String title) {
    final words = title
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final chars = [
      for (final w in words.take(2)) w.characters.first.toUpperCase(),
    ];
    return chars.join();
  }

  Future<void> _delete(SavedChat chat) async {
    await _history.delete(chat.id);
    if (mounted) AppToast.showSuccess(context, context.l10n.sv2HistoryDeleted);
  }

  Future<void> _clearAll() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l10n.sv2HistoryClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (ok == true) await _history.clear();
  }

  void _open(SavedChat chat) {
    final onOpen = widget.onOpen;
    if (onOpen != null) {
      onOpen(chat);
      return;
    }
    final provider = context.read<AppProvider>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => chat.mode == 'type'
            ? SaarthiTypeScreen(
                profile: provider.profile,
                language: provider.selectedLanguage,
                resume: chat,
              )
            : SaarthiTranscriptScreen(chat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = (widget.now ?? DateTime.now)();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final query = _search.text.trim().toLowerCase();
    final chats = (_chats ?? const <SavedChat>[])
        .where(
          (c) =>
              query.isEmpty ||
              c.messages.any((m) => m.text.toLowerCase().contains(query)),
        )
        .toList();

    String group(SavedChat c) {
      final at = c.updatedAt.toLocal();
      if (!at.isBefore(today)) return l10n.notifToday;
      if (!at.isBefore(yesterday)) return l10n.notifYesterday;
      return l10n.notifEarlier;
    }

    String when(SavedChat c) {
      final at = c.updatedAt.toLocal();
      return !at.isBefore(today)
          ? sv2Time(context, at)
          : MaterialLocalizations.of(context).formatShortMonthDay(at);
    }

    final children = <Widget>[];
    String? lastGroup;
    for (var i = 0; i < chats.length; i++) {
      final c = chats[i];
      final g = group(c);
      if (g != lastGroup) {
        lastGroup = g;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              g.toUpperCase(),
              style: pop(
                11,
                FontWeight.w700,
                kMuted,
                1,
              ).copyWith(letterSpacing: .6),
            ),
          ),
        );
      }
      final schemes = c.schemeIds.length;
      final replies = c.messages.where((m) => !m.isUser);
      final subtitle = replies.isNotEmpty
          ? replies.last.text
          : schemes > 0
          ? l10n.sv2HistorySchemes(schemes)
          : l10n.sv2HistoryMessages(c.messages.length);
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey('sv2-chat-${c.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _delete(c),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
            ),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0x0F0F172A)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _open(c),
                onLongPress: () => _delete(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _badgeColors[i % _badgeColors.length],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: c.mode == 'voice'
                            ? const Icon(Icons.mic_none_rounded, color: kInk)
                            : Text(
                                _initials(c.title),
                                style: pop(13, FontWeight.w800, kInk, 1),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: pop(13.5, FontWeight.w600, kInk, 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: pop(11.5, FontWeight.w500, kMuted, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(when(c), style: pop(11, FontWeight.w500, kHint, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final clearAll = (_chats ?? const []).isEmpty
        ? null
        : RoundIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: l10n.sv2HistoryClearAll,
            bg: Colors.white,
            border: true,
            onTap: _clearAll,
          );
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (widget.onOpen == null)
          BackTitle(title: l10n.sv2HistoryTitle, trailing: clearAll)
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sv2OldSessions,
                  style: pop(24, FontWeight.w800, kInk, 1, height: 1.2),
                ),
              ),
              ?clearAll,
            ],
          ),
        const SizedBox(height: 18),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kHairline),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: kMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('sv2-history-search'),
                  controller: _search,
                  style: pop(13.5, FontWeight.w500, kInk, 1),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    hintText: l10n.sv2HistorySearch,
                    hintStyle: pop(13.5, FontWeight.w500, kHint, 1),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_chats != null && chats.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              (_chats!.isEmpty) ? l10n.sv2HistoryEmpty : l10n.sv2HistoryNoMatch,
              textAlign: TextAlign.center,
              style: pop(13, FontWeight.w500, kMuted, 1, height: 1.5),
            ),
          ),
        ...children,
      ],
    );
    return DesignTextScale(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: list),
              ?widget.bottomBar,
            ],
          ),
        ),
      ),
    );
  }
}

/// A saved spoken conversation, read-only: the turns and their schemes.
class SaarthiTranscriptScreen extends StatelessWidget {
  const SaarthiTranscriptScreen({super.key, required this.chat});

  final SavedChat chat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AppProvider>();
    final byId = {for (final s in provider.allSchemes) s.id: s};
    return DesignTextScale(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              BackTitle(title: l10n.sv2HistoryTitle),
              const SizedBox(height: 16),
              for (final m in chat.messages) ...[
                if (m.isUser)
                  UserBubble(
                    text: m.text,
                    meta: '${l10n.sv2YouVoice} · ${sv2Time(context, m.at)}',
                    voice: true,
                  )
                else
                  SaarthiBubble(
                    avatarSize: 30,
                    meta: '${l10n.sv2Name} · ${sv2Time(context, m.at)}',
                    text: m.text,
                    below: [
                      if (m.schemeIds.isNotEmpty)
                        SchemeMatches(
                          schemes: <Scheme>[
                            for (final id in m.schemeIds) ?byId[id],
                          ],
                          language: provider.selectedLanguage,
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
