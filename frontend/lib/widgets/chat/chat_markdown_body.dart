import 'package:flutter/material.dart';

import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

/// Minimal markdown renderer for LLM chat replies -- handles the small
/// subset the model actually emits: `**bold**` / `__bold__`,
/// `*italic*` / `_italic_`, `` `code` ``, `#`/`##`/`###` headings,
/// `-`/`*`/`•` bullets and `1.` ordered items. Anything else renders as
/// plain text. Inlined here to avoid a markdown package dependency.
final RegExp _tamilScript = RegExp('[\u0B80-\u0BFF]');
final RegExp _devanagariScript = RegExp('[\u0900-\u097F]');

/// Body style for a chat message: the app's body font with the bundled Noto
/// Sans Tamil / Devanagari fallback, and the taller Indic line height when the
/// message itself is in Tamil or Hindi (a reply can be in another language
/// than the app). A bare Inter style made Indic text fall back to an OS font
/// whose ascenders and descenders were clipped by the Latin line height.
/// [style] in bold. The body font is variable, so the `wght` axis has to
/// move with the weight.
TextStyle _bold(TextStyle style) => style.copyWith(
  fontWeight: FontWeight.bold,
  fontVariations: const [FontVariation('wght', 700)],
);

TextStyle chatBubbleTextStyle(String content, Locale locale) {
  final styles = _tamilScript.hasMatch(content)
      ? AppTextStyles.ta
      : _devanagariScript.hasMatch(content)
      ? AppTextStyles.hi
      : AppTextStyles.forLocale(locale);
  return styles.body;
}

class ChatMarkdownBody extends StatelessWidget {
  const ChatMarkdownBody({
    super.key,
    required this.text,
    required this.baseStyle,
  });

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
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.hairline),
            child: SelectableText.rich(
              _inline(
                heading.group(2)!,
                _bold(
                  baseStyle,
                ).copyWith(fontSize: (baseStyle.fontSize ?? 14) + bump),
              ),
            ),
          ),
        );
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
        spans.add(
          TextSpan(text: input.substring(index, m.start), style: style),
        );
      }
      if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: _bold(style)));
      } else if (m.group(4) != null) {
        spans.add(
          TextSpan(
            text: m.group(4),
            style: style.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (m.group(5) != null) {
        spans.add(
          TextSpan(
            text: m.group(5),
            style: style.copyWith(
              fontFamily: 'monospace',
              backgroundColor: style.color?.withValues(alpha: 0.08),
            ),
          ),
        );
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
