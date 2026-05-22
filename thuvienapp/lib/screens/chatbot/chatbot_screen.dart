import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chatbot/chatbot_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chatbot/chat_bubble.dart';
import '../../widgets/chatbot/chat_input_bar.dart';
import '../../widgets/chatbot/suggestion_chips.dart';
import '../../widgets/chatbot/typing_indicator.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatbotProvider(),
      child: const _ChatbotView(),
    );
  }
}

class _ChatbotView extends StatefulWidget {
  const _ChatbotView();

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  final ScrollController _scrollController = ScrollController();
  static const List<String> _suggestions = [
    'Goi y sach lap trinh',
    'Sach dang khuyen mai',
    'Tim sach manga',
    'Sach duoi 100k',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatbotProvider>(
      builder: (context, provider, _) {
        _scrollToBottom();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: AppBar(
            titleSpacing: 0,
            title: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.blueLight,
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BookStore AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Tu van sach thong minh',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              SuggestionChips(
                suggestions: _suggestions,
                onSelected: provider.sendSuggestion,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  itemCount:
                      provider.messages.length + (provider.isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.messages.length) {
                      return const TypingIndicator();
                    }
                    return ChatBubble(message: provider.messages[index]);
                  },
                ),
              ),
              ChatInputBar(
                enabled: !provider.isSending,
                onSend: provider.sendMessage,
              ),
            ],
          ),
        );
      },
    );
  }
}
