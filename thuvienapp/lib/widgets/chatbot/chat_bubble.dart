import 'package:flutter/material.dart';

import '../../providers/chatbot/chatbot_provider.dart';
import '../../theme/app_theme.dart';
import 'recommended_book_cards.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    final bubbleColor = isUser
        ? AppColors.primaryBlue
        : message.isError
            ? const Color(0xFFFFF1F2)
            : Colors.white;
    final textColor = isUser
        ? Colors.white
        : message.isError
            ? const Color(0xFFB91C1C)
            : AppColors.textMain;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser || message.isError
                      ? null
                      : Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.5,
                      height: 1.38,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            if (message.recommendedBooks.isNotEmpty) ...[
              const SizedBox(height: 8),
              RecommendedBookCards(books: message.recommendedBooks),
            ],
          ],
        ),
      ),
    );
  }
}
