import 'package:flutter/material.dart';

import '../../services/notifications/notification_translator.dart';

/// [text] in the user's [language] ('en', 'hi', 'ta').
///
/// Shows [text] as it is when the app is in English or the text is already in
/// the user's script, and otherwise translates it on the phone with Google ML
/// Kit (the same translator the notifications use). The original text shows
/// until the translation is ready, and stays if it cannot be translated.
class AutoTranslatedText extends StatefulWidget {
  const AutoTranslatedText(
    this.text, {
    super.key,
    required this.language,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final String language;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// True when [text] has Latin letters and nothing in an Indic script, i.e. it
  /// was not translated by the catalog.
  static bool isEnglishOnly(String text) {
    var letters = 0;
    for (final unit in text.runes) {
      if ((unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A)) {
        letters++;
      } else if (unit >= 0x0900 && unit <= 0x0DFF) {
        return false;
      }
    }
    return letters > 0;
  }

  @override
  State<AutoTranslatedText> createState() => _AutoTranslatedTextState();
}

class _AutoTranslatedTextState extends State<AutoTranslatedText> {
  String? _translated;

  bool get _needed =>
      widget.language != 'en' && AutoTranslatedText.isEnglishOnly(widget.text);

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(AutoTranslatedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.language != widget.language) {
      _translated = null;
      _resolve();
    }
  }

  void _resolve() {
    if (!_needed) return;
    final translator = NotificationTranslator.instance;
    final known = translator.cached(widget.text, widget.language);
    if (known != null) {
      _translated = known;
      return;
    }
    final text = widget.text;
    final language = widget.language;
    translator.translate(text, language).then((out) {
      if (!mounted || widget.text != text || widget.language != language) {
        return;
      }
      if (out != text) setState(() => _translated = out);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _needed ? (_translated ?? widget.text) : widget.text,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
