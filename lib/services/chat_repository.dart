import 'dart:io';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/chat_message.dart';

class ConversationSummary {
  final String peerId;
  final String alias;
  final String lastText;
  final DateTime lastTimestamp;
  final int unreadCount;

  ConversationSummary({
    required this.peerId,
    required this.alias,
    required this.lastText,
    required this.lastTimestamp,
    required this.unreadCount,
  });
}

/// Persists chat history to disk (Hive): one box per conversation, plus an
/// index box for the conversations list so it can render without opening
/// every conversation's full history.
class ChatRepository {
  static const _hiveSubDir = 'hive_boxes';
  static const _indexBoxName = 'conversations_index';

  late final Box<Map> _indexBox;

  /// [testStoragePath], when set, bypasses `path_provider` (unavailable in
  /// plain `flutter test`) and stores boxes directly at that path instead.
  Future<void> init({String? testStoragePath}) async {
    if (testStoragePath != null) {
      Hive.init(testStoragePath);
    } else {
      await Hive.initFlutter(_hiveSubDir);
    }
    _indexBox = await Hive.openBox<Map>(_indexBoxName);
  }

  Future<Box<Map>> _chatBox(String peerId) {
    final name = 'chat_$peerId';
    if (Hive.isBoxOpen(name)) return Future.value(Hive.box<Map>(name));
    return Hive.openBox<Map>(name);
  }

  Future<List<ChatMessage>> loadMessages(String peerId) async {
    final box = await _chatBox(peerId);
    return box.values.map((raw) {
      final m = Map<String, dynamic>.from(raw);
      return ChatMessage(
        fromId: m['fromId'] as String,
        fromAlias: m['fromAlias'] as String,
        text: m['text'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        isMine: m['isMine'] as bool,
      );
    }).toList();
  }

  Future<void> appendMessage(String peerId, ChatMessage message) async {
    final box = await _chatBox(peerId);
    await box.add({
      'fromId': message.fromId,
      'fromAlias': message.fromAlias,
      'text': message.text,
      'timestamp': message.timestamp.toIso8601String(),
      'isMine': message.isMine,
    });
  }

  List<ConversationSummary> conversationSummaries() {
    return _indexBox.keys.map((key) {
      final m = Map<String, dynamic>.from(_indexBox.get(key) as Map);
      return ConversationSummary(
        peerId: key as String,
        alias: m['alias'] as String,
        lastText: m['lastText'] as String,
        lastTimestamp: DateTime.parse(m['lastTimestamp'] as String),
        unreadCount: m['unread'] as int,
      );
    }).toList();
  }

  Future<void> recordInIndex(
    String peerId, {
    required String alias,
    required ChatMessage message,
    required bool incrementUnread,
  }) async {
    final existing = _indexBox.get(peerId);
    final currentUnread = existing != null ? existing['unread'] as int : 0;
    await _indexBox.put(peerId, {
      'alias': alias,
      'lastText': message.text,
      'lastTimestamp': message.timestamp.toIso8601String(),
      'unread': incrementUnread ? currentUnread + 1 : currentUnread,
    });
  }

  Future<void> markConversationRead(String peerId) async {
    final existing = _indexBox.get(peerId);
    if (existing == null) return;
    final m = Map<String, dynamic>.from(existing);
    m['unread'] = 0;
    await _indexBox.put(peerId, m);
  }

  /// Total bytes used on disk by all chat/index Hive boxes.
  Future<int> storageBytesUsed() async {
    final boxPath = _indexBox.path;
    if (boxPath == null) return 0;
    final dir = Directory(boxPath).parent;
    if (!await dir.exists()) return 0;

    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
