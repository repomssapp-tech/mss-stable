// Shared pieces of the v2 Saarthi screens (Type and Voice), ported from the
// designer's saarthi_common.dart and wired to real schemes and l10n.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/localized_scheme.dart';
import '../../models/scheme_model.dart';
import '../../screens/regular_mode/scheme_details_screen.dart';
import '../../widgets/chat/chat_markdown_body.dart';
import '../../utils/app_colors.dart';
import '../mss_design.dart';

// The Saarathi redesign canvas's palette: Ashoka navy for text and actions,
// saffron and green only in the rings and halos, on white.
const kInk = MssColors.ashokaBlue;
const kBrand = MssColors.ashokaBlue;
const kMuted = Color(0xFF5A5A8A);
const kBody = Color(0xFF3A3A6A);
const kHint = Color(0xFF5A5A8A);
const kHairline = Color(0x14000080); // navy 8%
const kOutline = Color(0x1A000080); // navy 10%, round buttons
const kFieldBorder = Color(0x33000080); // navy 20%, text fields
const kSaarthiBg = Colors.white;
const kSaffronHalo = Color(0x59FF9933); // saffron 35%, around the mic

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
            ? const [BoxShadow(color: kSaffronHalo, spreadRadius: 6)]
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
          side: border ? const BorderSide(color: kOutline) : BorderSide.none,
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
              color: kBrand,
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
    this.trailing,
  });

  final String text;
  final String? meta;
  final List<Widget> below;
  final double avatarSize;

  /// Replaces the Markdown text (e.g. a reply being revealed or a status).
  final Widget? child;

  /// Sits to the right of the message (the "hear it again" button).
  final Widget? trailing;

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
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
    final badgeFg = best ? AppColors.success : AppColors.warningText;
    final badgeBg = best ? AppColors.successSoft : AppColors.warningSoft;
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
              builder: (_) => SchemeDetailsScreen(
                scheme: scheme,
                analyticsEntryPoint: 'saarthi',
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
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
                        style: pop(11.5, FontWeight.w700, AppColors.primary, 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primary,
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
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kFieldBorder),
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
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                counterText: '',
                hintText: l10n.sv2TypeHint,
                hintStyle: pop(14, FontWeight.w500, kHint, 1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        RoundIconButton(
          key: const Key('sarvam-chat-send'),
          icon: Icons.arrow_upward_rounded,
          tooltip: l10n.send,
          onTap: enabled ? onSend : null,
          bg: kBrand,
          fg: Colors.white,
          size: 48,
          iconSize: 20,
        ),
      ],
    );
  }
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
                  style: pop(11, FontWeight.w600, AppColors.success, 1),
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
                activeColor: AppColors.success,
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
