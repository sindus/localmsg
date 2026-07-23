import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../services/chat_store.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';
import 'nearby_screen.dart';

/// Home screen: conversations the user has actually exchanged messages in.
/// Starting a new one happens via Nearby (the "+" button).
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final sameDay =
        now.year == time.year && now.month == time.month && now.day == time.day;
    if (sameDay) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ChatStore>().conversations;

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: AppTypography.screenTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyScreen()),
              ),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: AppColors.onAccent),
              ),
            ),
          ),
        ],
      ),
      body: conversations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Aucune conversation. Touchez + pour trouver un appareil à proximité.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: conversations.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AppColors.borderSubtle, height: 1),
              itemBuilder: (context, index) {
                final c = conversations[index];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(peerId: c.peerId, peerAlias: c.alias),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      children: [
                        Avatar(id: c.peerId, name: c.alias),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.alias,
                                      style: AppTypography.listTitle,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(c.lastTimestamp),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.lastText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body,
                                    ),
                                  ),
                                  if (c.unreadCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${c.unreadCount}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
