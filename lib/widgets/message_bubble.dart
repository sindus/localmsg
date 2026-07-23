import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidthFraction;
  final double radius;

  const MessageBubble({
    super.key,
    required this.message,
    this.maxWidthFraction = 0.76,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * maxWidthFraction,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMine ? AppColors.accent : AppColors.panel2,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          message.text,
          style: AppTypography.bubbleText.copyWith(
            color: isMine ? AppColors.onAccent : AppColors.text,
          ),
        ),
      ),
    );
  }
}
