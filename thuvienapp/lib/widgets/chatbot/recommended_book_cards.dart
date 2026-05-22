import 'package:flutter/material.dart';

import '../../providers/chatbot/chatbot_provider.dart';
import 'recommendation_card.dart';

class RecommendedBookCards extends StatelessWidget {
  final List<ChatRecommendedBook> books;
  final ValueChanged<ChatRecommendedBook>? onDetailPressed;

  const RecommendedBookCards({
    super.key,
    required this.books,
    this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final book = books[index];
          return RecommendationCard(
            book: book,
            onDetailPressed: onDetailPressed == null
                ? null
                : () => onDetailPressed!(book),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: books.length,
      ),
    );
  }
}
