import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../models/chat_message.dart';
import '../models/peer.dart';
import '../services/chat_store.dart';
import '../services/device_identity_service.dart';
import '../services/discovery_service.dart';
import '../services/message_client.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAlias;

  const ChatScreen({super.key, required this.peerId, required this.peerAlias});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messageClient = MessageClient();
  bool _sending = false;
  int _lastMessageCount = 0;

  late final ChatStore _chatStore;

  @override
  void initState() {
    super.initState();
    _chatStore = context.read<ChatStore>();
    _chatStore.setViewing(widget.peerId);
    _chatStore.ensureLoaded(widget.peerId);
  }

  @override
  void dispose() {
    _chatStore.setViewing(null);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(Peer? peer) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final identity = context.read<DeviceIdentityService>();
    final message = ChatMessage(
      fromId: identity.id,
      fromAlias: identity.alias,
      text: text,
      timestamp: DateTime.now(),
      isMine: true,
    );

    setState(() => _sending = true);
    _controller.clear();
    await _chatStore.add(widget.peerId, widget.peerAlias, message);

    final ok = peer != null && await _messageClient.send(peer, message);
    if (mounted) {
      setState(() => _sending = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message non envoyé : appareil injoignable'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryService>();

    Peer? livePeer;
    for (final p in discovery.peers) {
      if (p.id == widget.peerId) {
        livePeer = p;
        break;
      }
    }
    final isOnline = livePeer != null;

    final messages = context.watch<ChatStore>().messagesFor(widget.peerId);
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(id: widget.peerId, name: widget.peerAlias, diameter: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.peerAlias, style: AppTypography.chatNameHeader),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? AppColors.avatarHues[2]
                            : AppColors.textDim,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'Active now' : 'Hors ligne',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Aucun message pour le moment',
                      style: AppTypography.body,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        MessageBubble(message: messages[index]),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.panel2,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message ${widget.peerAlias}…',
                          hintStyle: const TextStyle(
                            color: AppColors.textDim,
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onSubmitted: (_) => _send(livePeer),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending ? null : () => _send(livePeer),
                    child: const SendButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_upward,
        color: AppColors.onAccent,
        size: 18,
      ),
    );
  }
}
