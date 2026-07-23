import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:localmsg/models/chat_message.dart';
import 'package:localmsg/services/chat_repository.dart';

void main() {
  late Directory tempDir;
  late ChatRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('localmsg_test_');
    repository = ChatRepository();
    await repository.init(testStoragePath: tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'appendMessage + loadMessages round-trips message content and order',
    () async {
      final first = ChatMessage(
        fromId: 'me',
        fromAlias: 'Alice',
        text: 'Salut',
        timestamp: DateTime.utc(2026, 1, 1, 10),
        isMine: true,
      );
      final second = ChatMessage(
        fromId: 'peer-1',
        fromAlias: 'Bob',
        text: 'Yo',
        timestamp: DateTime.utc(2026, 1, 1, 10, 1),
        isMine: false,
      );

      await repository.appendMessage('peer-1', first);
      await repository.appendMessage('peer-1', second);

      final loaded = await repository.loadMessages('peer-1');

      expect(loaded, hasLength(2));
      expect(loaded[0].text, 'Salut');
      expect(loaded[0].isMine, isTrue);
      expect(loaded[1].text, 'Yo');
      expect(loaded[1].isMine, isFalse);
    },
  );

  test(
    'recordInIndex increments unread only when asked, markConversationRead resets it',
    () async {
      final message = ChatMessage(
        fromId: 'peer-1',
        fromAlias: 'Bob',
        text: 'Hey',
        timestamp: DateTime.utc(2026, 1, 1),
        isMine: false,
      );

      await repository.recordInIndex(
        'peer-1',
        alias: 'Bob',
        message: message,
        incrementUnread: true,
      );
      await repository.recordInIndex(
        'peer-1',
        alias: 'Bob',
        message: message,
        incrementUnread: true,
      );

      var summaries = repository.conversationSummaries();
      expect(summaries.single.unreadCount, 2);

      await repository.markConversationRead('peer-1');
      summaries = repository.conversationSummaries();
      expect(summaries.single.unreadCount, 0);
    },
  );

  test(
    'storageBytesUsed reports a positive size once data has been written',
    () async {
      final message = ChatMessage(
        fromId: 'peer-1',
        fromAlias: 'Bob',
        text: 'Hey',
        timestamp: DateTime.utc(2026, 1, 1),
        isMine: false,
      );
      await repository.appendMessage('peer-1', message);

      final bytes = await repository.storageBytesUsed();
      expect(bytes, greaterThan(0));
    },
  );

  test(
    'deleteConversation removes messages and the index entry for that peer only',
    () async {
      final message = ChatMessage(
        fromId: 'peer-1',
        fromAlias: 'Bob',
        text: 'Hey',
        timestamp: DateTime.utc(2026, 1, 1),
        isMine: false,
      );
      await repository.appendMessage('peer-1', message);
      await repository.recordInIndex(
        'peer-1',
        alias: 'Bob',
        message: message,
        incrementUnread: true,
      );
      await repository.appendMessage('peer-2', message);
      await repository.recordInIndex(
        'peer-2',
        alias: 'Carol',
        message: message,
        incrementUnread: true,
      );

      await repository.deleteConversation('peer-1');

      expect(await repository.loadMessages('peer-1'), isEmpty);
      final summaries = repository.conversationSummaries();
      expect(summaries.map((s) => s.peerId), ['peer-2']);
    },
  );

  test('deleteAllConversations clears every conversation', () async {
    final message = ChatMessage(
      fromId: 'peer-1',
      fromAlias: 'Bob',
      text: 'Hey',
      timestamp: DateTime.utc(2026, 1, 1),
      isMine: false,
    );
    await repository.appendMessage('peer-1', message);
    await repository.recordInIndex(
      'peer-1',
      alias: 'Bob',
      message: message,
      incrementUnread: true,
    );
    await repository.appendMessage('peer-2', message);
    await repository.recordInIndex(
      'peer-2',
      alias: 'Carol',
      message: message,
      incrementUnread: true,
    );

    await repository.deleteAllConversations();

    expect(repository.conversationSummaries(), isEmpty);
    expect(await repository.loadMessages('peer-1'), isEmpty);
    expect(await repository.loadMessages('peer-2'), isEmpty);
  });
}
