import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'chat_repository.dart';

/// Message history per peer, backed by [ChatRepository] for on-disk
/// persistence. Keeps a per-peer in-memory cache (loaded lazily via
/// [ensureLoaded]) so [ChatScreen] can watch this as a plain ChangeNotifier.
class ChatStore extends ChangeNotifier {
  final ChatRepository repository;

  ChatStore(this.repository);

  final Map<String, List<ChatMessage>> _messagesByPeerId = {};
  Map<String, ConversationSummary> _summaries = {};

  /// The peer id whose ChatScreen is currently open, if any — used to
  /// decide whether an incoming message should count as unread / notify.
  String? currentlyViewedPeerId;

  List<ConversationSummary> get conversations {
    final list = _summaries.values.toList();
    list.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    return list;
  }

  void loadSummaries() {
    _summaries = {
      for (final s in repository.conversationSummaries()) s.peerId: s,
    };
    notifyListeners();
  }

  List<ChatMessage> messagesFor(String peerId) =>
      List.unmodifiable(_messagesByPeerId[peerId] ?? const []);

  Future<void> ensureLoaded(String peerId) async {
    if (_messagesByPeerId.containsKey(peerId)) return;
    _messagesByPeerId[peerId] = await repository.loadMessages(peerId);
    notifyListeners();
  }

  Future<void> add(String peerId, String peerAlias, ChatMessage message) async {
    _messagesByPeerId.putIfAbsent(peerId, () => []).add(message);
    final incrementUnread = !message.isMine && currentlyViewedPeerId != peerId;
    await repository.appendMessage(peerId, message);
    await repository.recordInIndex(
      peerId,
      alias: peerAlias,
      message: message,
      incrementUnread: incrementUnread,
    );
    loadSummaries();
    notifyListeners();
  }

  Future<void> deleteConversation(String peerId) async {
    _messagesByPeerId.remove(peerId);
    await repository.deleteConversation(peerId);
    loadSummaries();
    notifyListeners();
  }

  Future<void> deleteAllConversations() async {
    _messagesByPeerId.clear();
    await repository.deleteAllConversations();
    loadSummaries();
    notifyListeners();
  }

  void setViewing(String? peerId) {
    currentlyViewedPeerId = peerId;
    if (peerId != null) {
      repository.markConversationRead(peerId);
      loadSummaries();
    }
  }

  Future<int> storageBytesUsed() => repository.storageBytesUsed();
}
