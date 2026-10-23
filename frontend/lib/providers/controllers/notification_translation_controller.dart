import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/notifications/notification_translator.dart';

/// Shows the inbox in the user's language.
///
/// [view] returns the inbox with each notification's `title` and `body`
/// replaced by their translation when one is known, and starts translating
/// the ones that are not (listeners are told when more arrive). The original
/// text stays in `title_original` / `body_original`. Until a translation is
/// ready, or when none is possible, the original text is shown.
class NotificationTranslationController extends ChangeNotifier {
  NotificationTranslationController({NotificationTranslator? translator})
    : _translator = translator ?? NotificationTranslator.instance;

  final NotificationTranslator _translator;

  /// When each text was last sent to the translator. A text that came back
  /// unchanged (already in the user's language, or not translatable yet, e.g.
  /// offline before the first model download) is tried again after
  /// [_retryAfter], not on every rebuild.
  final Map<String, DateTime> _attempted = {};
  static const Duration _retryAfter = Duration(minutes: 2);
  int _version = 0;

  List<Map<String, dynamic>>? _source;
  String? _language;
  int _viewVersion = -1;
  List<Map<String, dynamic>> _view = const [];

  List<Map<String, dynamic>> view(
    List<Map<String, dynamic>> items,
    String language,
  ) {
    if (identical(items, _source) &&
        language == _language &&
        _version == _viewVersion) {
      return _view;
    }
    final out = <Map<String, dynamic>>[];
    for (final item in items) {
      final title = item['title']?.toString() ?? '';
      final body = item['body']?.toString() ?? '';
      final newTitle = _lookup(title, language);
      final newBody = _lookup(body, language);
      if (newTitle == title && newBody == body) {
        out.add(item);
      } else {
        out.add({
          ...item,
          'title': newTitle,
          'body': newBody,
          'title_original': title,
          'body_original': body,
        });
      }
    }
    _source = items;
    _language = language;
    _viewVersion = _version;
    return _view = out;
  }

  String _lookup(String text, String language) {
    if (text.trim().isEmpty) return text;
    final known = _translator.cached(text, language);
    if (known != null) return known;
    final key = '$language\u0000$text';
    final last = _attempted[key];
    final now = DateTime.now();
    if (last == null || now.difference(last) > _retryAfter) {
      _attempted[key] = now;
      unawaited(_fetch(text, language));
    }
    return text;
  }

  Future<void> _fetch(String text, String language) async {
    final out = await _translator.translate(text, language);
    if (out == text) return;
    _version++;
    notifyListeners();
  }
}
