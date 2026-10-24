// Shared pieces of the v2 Saarthi screens (Type and Voice), ported from the
// designer's saarthi_common.dart and wired to real schemes and l10n.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/localized_scheme.dart';
import '../../models/scheme_model.dart';
import '../../screens/regular_mode/scheme_details_screen.dart';
import '../../widgets/chat/chat_markdown_body.dart';
import '../mss_design.dart';

const kInk = MssColors.ashokaBlue;
const kMuted = Color(0xFF5A5A8A);
const kBody = Color(0xFF3A3A6A);
const kHairline = Color(0x14000080);
const kHint = Color(0xFF8A8AB0);

/// "9:41" in the user's locale.
String sv2Time(BuildContext context, DateTime at) =>
    DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(at);

/// Circular Saarthi picture used in chat and confirm screens.
class SaarthiAvatar extends StatelessWidget {
  const SaarthiAvatar({super.key, this.size = 34, this.ring = false});

  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MssColors.saffronLight,
        boxShadow: ring
            ? [
                BoxShadow(
                  color: MssColors.saffron.withValues(alpha: .25),
                  spreadRadius: 6,
                ),
              ]
            : null,
        border: ring ? null : Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        MssAssets.saarthiAvatar,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
      ),
    ),
  );
}

/// Type / Voice segmented switch.
class ModeToggle extends StatelessWidget {
  const ModeToggle({
    super.key,
    required this.voiceActive,
    required this.onSwitch,
  });

  final bool voiceActive;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget seg(String label, bool active, Color activeBg, Color activeFg) =>
        Semantics(
          button: true,
          selected: active,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: active ? null : onSwitch,
            child: Container(
              constraints: const BoxConstraints(minHeight: 32, minWidth: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: pop(12, FontWeight.w600, active ? activeFg : kInk, 1),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1A000080)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(l10n.sv2ModeType, !voiceActive, kInk, Colors.white),
          seg(l10n.sv2ModeVoice, voiceActive, MssColors.saffron, kInk),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.bg = MssColors.cream,
    this.fg = kInk,
    this.size = 44,
    this.iconSize = 18,
    this.border = false,
  });

  final IconData icon;

  /// Shown on long press and read by screen readers.
  final String tooltip;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final double size;
  final double iconSize;
  final bool border;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    excludeFromSemantics: true,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: CircleBorder(
          side: border
              ? const BorderSide(color: Color(0x1A000080))
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: fg),
          ),
        ),
      ),
    ),
  );
}

/// "Saarthi / Powered by MSS AI" title block.
class SaarthiTitle extends StatelessWidget {
  const SaarthiTitle({
    super.key,
    this.size = 20,
    this.subtitle,
    this.subtitleColor = kMuted,
    this.subtitleDot = false,
  });

  final double size;
  final String? subtitle;
  final Color subtitleColor;
  final bool subtitleDot;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        context.l10n.sv2Name,
        style: pop(size, FontWeight.w800, kInk, 1, height: 1.1),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitleDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: subtitleColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              subtitle ?? context.l10n.sv2PoweredBy,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: pop(11, FontWeight.w500, subtitleColor, 1, height: 1.3),
            ),
          ),
        ],
      ),
    ],
  );
}

/// White top bar of the chat screens.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHeader({
    super.key,
    required this.leading,
    required this.title,
    this.actions = const [],
  });

  final Widget leading;
  final Widget title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kHairline)),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(child: title),
            for (final a in actions) ...[const SizedBox(width: 8), a],
          ],
        ),
      ),
    ),
  );
}

class UserBubble extends StatelessWidget {
  const UserBubble({
    super.key,
    required this.text,
    required this.meta,
    this.voice = false,
  });

  final String text;
  final String meta;
  final bool voice;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (voice) ...[
                const Icon(Icons.mic_none_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
              ],
              Text(meta, style: pop(11, FontWeight.w500, kMuted, 1)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: const BoxDecoration(
              color: kInk,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: SelectableText(
              text,
              style: pop(14, FontWeight.w500, Colors.white, 1, height: 1.45),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Saarthi's message: avatar, bubble (Markdown reply), and content below it.
class SaarthiBubble extends StatelessWidget {
  const SaarthiBubble({
    super.key,
    required this.text,
    this.meta,
    this.below = const [],
    this.avatarSize = 34,
    this.child,
  });

  final String text;
  final String? meta;
  final List<Widget> below;
  final double avatarSize;

  /// Replaces the Markdown text (e.g. a reply being revealed or a status).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final base = chatBubbleTextStyle(
      text,
      Localizations.localeOf(context),
    ).copyWith(color: kInk, fontSize: 14);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaarthiAvatar(size: avatarSize),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meta != null) ...[
                Text(meta!, style: pop(11, FontWeight.w500, kMuted, 1)),
                const SizedBox(height: 4),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kHairline),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: child ?? ChatMarkdownBody(text: text, baseStyle: base),
              ),
              for (final w in below) ...[const SizedBox(height: 10), w],
            ],
          ),
        ),
      ],
    );
  }
}

/// A matched scheme: badge, name, one-line summary, "View scheme".
class SchemeMatchCard extends StatelessWidget {
  const SchemeMatchCard({
    super.key,
    required this.scheme,
    required this.best,
    required this.language,
  });

  final Scheme scheme;
  final bool best;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final local = scheme.toLocalized(language);
    final badgeFg = best ? MssColors.green : MssColors.eligibleAmber;
    final badgeBg = best
        ? MssColors.green.withValues(alpha: .1)
        : MssColors.saffron.withValues(alpha: .16);
    final summary = local.overview.isNotEmpty ? local.overview : local.benefits;
    return Semantics(
      button: true,
      label:
          '${best ? l10n.sv2BestMatch : l10n.sv2GoodMatch}. ${local.name}. '
          '${l10n.sv2ViewScheme}',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SchemeDetailsScreen(scheme: scheme),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000050),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    best ? l10n.sv2BestMatch : l10n.sv2GoodMatch,
                    style: pop(10, FontWeight.w700, badgeFg, 1),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  local.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: pop(14, FontWeight.w800, kInk, 1, height: 1.2),
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: pop(11.5, FontWeight.w500, kBody, 1, height: 1.4),
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.sv2ViewScheme,
                        style: pop(
                          11.5,
                          FontWeight.w700,
                          MssColors.saffronDeep,
                          1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: MssColors.saffronDeep,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One or two matched schemes side by side (the first is the best match).
class SchemeMatches extends StatelessWidget {
  const SchemeMatches({
    super.key,
    required this.schemes,
    required this.language,
  });

  final List<Scheme> schemes;
  final String language;

  @override
  Widget build(BuildContext context) {
    final shown = schemes.take(2).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: SchemeMatchCard(
                scheme: shown[i],
                best: i == 0,
                language: language,
              ),
            ),
          ],
          if (shown.length == 1) const Spacer(),
        ],
      ),
    );
  }
}

/// "Type here…" field and round send button.
class TypeBar extends StatelessWidget {
  const TypeBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kHairline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000050),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              key: const Key('sarvam-chat-input'),
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: pop(14, FontWeight.w500, kInk, 1),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: l10n.sv2TypeHint,
                hintStyle: pop(14, FontWeight.w500, kHint, 1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x4D000080),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: RoundIconButton(
            key: const Key('sarvam-chat-send'),
            icon: Icons.arrow_upward_rounded,
            tooltip: l10n.send,
            onTap: enabled ? onSend : null,
            bg: kInk,
            fg: Colors.white,
            size: 52,
            iconSize: 22,
          ),
        ),
      ],
    );
  }
}

/// Voice pill plus tick / cross pebble.
class VoiceActionBar extends StatelessWidget {
  const VoiceActionBar({
    super.key,
    required this.label,
    required this.onMic,
    required this.yesLabel,
    required this.noLabel,
    this.onYes,
    this.onNo,
  });

  final String label;
  final VoidCallback onMic;
  final String yesLabel;
  final String noLabel;
  final VoidCallback? onYes;
  final VoidCallback? onNo;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onMic,
            icon: const Icon(Icons.mic_none_rounded, color: Colors.white),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: pop(14, FontWeight.w600, Colors.white, 1),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kInk,
              shape: const StadiumBorder(),
              elevation: 6,
              shadowColor: const Color(0x4D000080),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000050),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            RoundIconButton(
              icon: Icons.check_rounded,
              tooltip: yesLabel,
              onTap: onYes,
              bg: onYes == null ? const Color(0xFFB9D9B5) : MssColors.green,
              fg: Colors.white,
              size: 48,
              iconSize: 22,
            ),
            const SizedBox(width: 6),
            RoundIconButton(
              icon: Icons.close_rounded,
              tooltip: noLabel,
              onTap: onNo,
              bg: MssColors.saffronLight,
              fg: MssColors.saffronText,
              size: 48,
              iconSize: 20,
            ),
          ],
        ),
      ),
    ],
  );
}

/// "Documents needed" checklist for the top scheme; ticks are the user's.
class DocumentsCard extends StatelessWidget {
  const DocumentsCard({
    super.key,
    required this.documents,
    required this.ready,
    required this.onToggle,
  });

  final List<String> documents;
  final Set<int> ready;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kHairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.sv2DocumentsNeeded,
                    style: pop(13, FontWeight.w700, kInk, 1),
                  ),
                ),
                Text(
                  l10n.sv2DocumentsReady(ready.length, documents.length),
                  style: pop(11, FontWeight.w600, MssColors.green, 1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < documents.length; i++)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: ready.contains(i),
                onChanged: (_) => onToggle(i),
                activeColor: MssColors.green,
                shape: const CircleBorder(),
                checkboxShape: const CircleBorder(),
                title: Text(
                  documents[i],
                  style: pop(12.5, FontWeight.w500, kInk, 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Back button and screen title.
class BackTitle extends StatelessWidget {
  const BackTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      RoundIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        bg: Colors.white,
        border: true,
        iconSize: 16,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: pop(20, FontWeight.w800, kInk, 1))),
      ?trailing,
    ],
  );
}
