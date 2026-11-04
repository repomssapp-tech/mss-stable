import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../account/app_session.dart';

/// One message of a saved Saarthi conversation.
@immutable
class SavedChatMessage {
  const SavedChatMessage({
    required this.role,
    required this.text,
    required this.at,
    this.schemeIds = const [],
  });

  factory SavedChatMessage.fromJson(Map<String, dynamic> j) => SavedChatMessage(
    role: j['role'] == 'assistant' ? 'assistant' : 'user',
    text: j['text']?.toString() ?? '',
    at: DateTime.tryParse(j['at']?.toString() ?? '') ?? DateTime(2000),
    schemeIds: [
      for (final id in (j['schemeIds'] as List? ?? const [])) id.toString(),
    ],
  );

  /// `user` or `assistant`.
  final String role;
  final String text;
  final DateTime at;

  /// Catalog ids of the schemes shown with this message.
  final List<String> schemeIds;

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'at': at.toIso8601String(),
    if (schemeIds.isNotEmpty) 'schemeIds': schemeIds,
  };
}

/// A saved Saarthi conversation (typed or spoken).
@immutable
class SavedChat {
  const SavedChat({
    required this.id,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory SavedChat.fromJson(Map<String, dynamic> j) => SavedChat(
    id: j['id']?.toString() ?? '',
    mode: j['mode'] == 'voice' ? 'voice' : 'type',
    createdAt:
        DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime(2000),
    updatedAt:
        DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime(2000),
    messages: [
      for (final m in (j['messages'] as List? ?? const []))
        if (m is Map) SavedChatMessage.fromJson(m.cast<String, dynamic>()),
    ],
  );

  final String id;

  /// `type` or `voice`.
  final String mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SavedChatMessage> messages;

  /// The first question asked, which names the conversation.
  String get title => messages
      .firstWhere(
        (m) => m.isUser && m.text.trim().isNotEmpty,
        orElse: () => SavedChatMessage(role: 'user', text: '', at: _epoch),
      )
      .text
      .trim();

  /// Distinct schemes shown anywhere in the conversation.
  List<String> get schemeIds =>
      {for (final m in messages) ...m.schemeIds}.toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': mode,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': [for (final m in messages) m.toJson()],
  };

  static final DateTime _epoch = DateTime.utc(2000);
}

/// Saarthi conversations kept on this phone only (the app's private files),
/// newest first, one file per account so nobody signing in on a shared phone
/// sees another person's chats. The cloud chat log is separate; this is what
/// the History screen shows, and it works offline.
class LocalChatHistory extends ChangeNotifier {
  LocalChatHistory({
    Future<Directory> Function()? directory,
    String? Function()? owner,
  }) : _directory = directory ?? getApplicationDocumentsDirectory,
       _owner = owner ?? (() => AppSession.instance.userId),
       _memoryOnly = false;

  /// Kept in memory only (nothing written to disk); for widget tests.
  @visibleForTesting
  LocalChatHistory.inMemory()
    : _directory = getApplicationDocumentsDirectory,
      _owner = (() => null),
      _memoryOnly = true,
      _chats = [];

  static final LocalChatHistory instance = LocalChatHistory();

  /// The shared file used before history was kept per account.
  static const String fileName = 'saarthi_history_v1.json';
  static const int maxChats = 100;
  static const int maxMessagesPerChat = 200;

  final Future<Directory> Function() _directory;
  final String? Function() _owner;
  final bool _memoryOnly;
  List<SavedChat>? _chats;
  String? _loadedFor;
  Future<void> _writes = Future.value();

  String _fileNameFor(String? owner) => owner == null
      ? 'saarthi_history_guest_v1.json'
      : 'saarthi_history_${base64Url.encode(utf8.encode(owner))}_v1.json';

  Future<File> _file(String? owner) async =>
      File('${(await _directory()).path}/${_fileNameFor(owner)}');

  /// The first account to open history after the update takes over the old
  /// shared file: on nearly every phone that is the person who wrote it.
  Future<void> _adoptSharedFile(File own) async {
    if (await own.exists()) return;
    final shared = File('${(await _directory()).path}/$fileName');
    if (await shared.exists()) await shared.rename(own.path);
  }

  /// Every saved conversation of the signed-in account, newest first.
  Future<List<SavedChat>> list() async {
    final owner = _owner();
    if (_chats != null && (_memoryOnly || _loadedFor == owner)) {
      return List.unmodifiable(_chats!);
    }
    _chats = null;
    _loadedFor = owner;
    try {
      final file = await _file(owner);
      if (owner != null) await _adoptSharedFile(file);
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        _chats = [
          for (final c
              in (data is Map ? data['chats'] as List? : null) ?? const [])
            if (c is Map) SavedChat.fromJson(c.cast<String, dynamic>()),
        ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
    } catch (e) {
      debugPrint('[LocalChatHistory] unreadable history, starting fresh: $e');
    }
    _chats ??= [];
    return List.unmodifiable(_chats!);
  }

  /// Adds or replaces [chat] (by id). Empty conversations are not kept.
  Future<void> save(SavedChat chat) async {
    if (chat.messages.every((m) => m.text.trim().isEmpty)) return;
    final chats = [...await list()]..removeWhere((c) => c.id == chat.id);
    final trimmed = chat.messages.length > maxMessagesPerChat
        ? SavedChat(
            id: chat.id,
            mode: chat.mode,
            createdAt: chat.createdAt,
            updatedAt: chat.updatedAt,
            messages: chat.messages.sublist(
              chat.messages.length - maxMessagesPerChat,
            ),
          )
        : chat;
    chats
      ..add(trimmed)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _chats = chats.take(maxChats).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    final chats = [...await list()]..removeWhere((c) => c.id == id);
    _chats = chats;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    await list();
    _chats = [];
    notifyListeners();
    await _persist();
  }

  // Writes are serialized so two quick saves never interleave on disk.
  Future<void> _persist() {
    if (_memoryOnly) return Future.value();
    final owner = _loadedFor;
    final snapshot = jsonEncode({
      'chats': [for (final c in _chats ?? const <SavedChat>[]) c.toJson()],
    });
    _writes = _writes.then((_) async {
      try {
        final file = await _file(owner);
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(snapshot, flush: true);
        await tmp.rename(file.path);
      } catch (e) {
        debugPrint('[LocalChatHistory] save failed: $e');
      }
    });
    return _writes;
  }

  @visibleForTesting
  void resetCache() => _chats = null;
}
