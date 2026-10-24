import 'package:flutter/widgets.dart';

/// Text whose `[bracketed]` part is drawn in [highlight]. Titles are one
/// translatable string, so each language puts the coloured word where its
/// grammar needs it ("Made [Simple]", "இப்போது [எளிதாக]").
class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    super.key,
    required this.style,
    required this.highlight,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextStyle highlight;
  final TextAlign? textAlign;

  /// [text] split into (part, highlighted) runs; brackets are removed.
  static List<(String, bool)> runs(String text) {
    final out = <(String, bool)>[];
    final re = RegExp(r'\[([^\]]*)\]');
    var at = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > at) out.add((text.substring(at, m.start), false));
      out.add((m[1]!, true));
      at = m.end;
    }
    if (at < text.length) out.add((text.substring(at), false));
    return out;
  }

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final (part, hl) in runs(text))
          TextSpan(text: part, style: hl ? highlight : null),
      ],
    ),
    style: style,
    textAlign: textAlign,
  );
}
