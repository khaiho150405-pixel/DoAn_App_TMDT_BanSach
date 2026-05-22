import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum ChatMessageRole { user, assistant }

class ChatRecommendedBook {
  final int bookId;
  final String title;
  final String? author;
  final String? category;
  final String? image;
  final double? price;
  final double? rating;
  final String? reason;

  ChatRecommendedBook({
    required this.bookId,
    required this.title,
    this.author,
    this.category,
    this.image,
    this.price,
    this.rating,
    this.reason,
  });

  factory ChatRecommendedBook.fromJson(Map<String, dynamic> json) {
    return ChatRecommendedBook(
      bookId: json['bookId'] ?? json['book_id'] ?? 0,
      title: json['title'] ?? '',
      author: json['author'],
      category: json['category'],
      image: json['image'],
      price: _toDouble(json['price']),
      rating: _toDouble(json['rating']),
      reason: json['reason'],
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class ChatMessage {
  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime createdAt;
  final List<ChatRecommendedBook> recommendedBooks;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.recommendedBooks = const [],
    this.isError = false,
  });
}

class ChatbotProvider extends ChangeNotifier {
  GenerativeModel? _model;
  ChatSession? _chat;

  ChatbotProvider() {
    _messages.add(
      ChatMessage(
        id: _newId(),
        role: ChatMessageRole.assistant,
        text:
            'Xin chào! Mình là Trợ lý ảo AI của E-BookStore. Mình có thể giúp bạn tìm sách, tư vấn chọn sách hay và trả lời bất kỳ câu hỏi nào khác của bạn.',
        createdAt: DateTime.now(),
      ),
    );
    _initGemini();
  }

  void _initGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Warning: GEMINI_API_KEY is not defined in .env');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          'Bạn là BookStore AI - trợ lý ảo tư vấn sách thông minh của cửa hàng sách trực tuyến E-BookStore.\n'
          'Nhiệm vụ của bạn là:\n'
          '1. Tư vấn và giới thiệu các đầu sách hay, sách lập trình, manga, văn học, khoa học, kỹ năng sống... theo sở thích người dùng.\n'
          '2. Trả lời các câu hỏi về sách một cách thân thiện, lịch sự và chuyên nghiệp bằng Tiếng Việt.\n'
          '3. Khi người dùng muốn tìm sách, hãy phân tích nhu cầu và đưa ra các đề xuất cụ thể (tên sách, tác giả, lý do khuyên đọc).\n'
          '4. Nếu bạn muốn đề xuất bất kỳ quyển sách nào, vui lòng cung cấp thông tin sách đó dưới dạng một danh sách JSON đặt trong khối mã ```json ... ``` ở CUỐI CÙNG của câu trả lời của bạn với cấu trúc chính xác như sau:\n'
          '```json\n'
          '[\n'
          '  {\n'
          '    "title": "Tên sách",\n'
          '    "author": "Tên tác giả",\n'
          '    "category": "Thể loại",\n'
          '    "price": 120000,\n'
          '    "reason": "Lý do khuyên đọc ngắn gọn"\n'
          '  }\n'
          ']\n'
          '```\n'
          'Hãy luôn trả lời bằng Tiếng Việt thân thiện, tự nhiên và hữu ích nhất.'),
    );

    _chat = _model!.startChat();
  }

  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;

    _errorMessage = null;
    _messages.add(
      ChatMessage(
        id: _newId(),
        role: ChatMessageRole.user,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    _isSending = true;
    notifyListeners();

    try {
      if (_chat == null) {
        _initGemini();
      }

      if (_chat == null) {
        throw Exception(
            'Gemini API key is not configured. Please add GEMINI_API_KEY in .env file.');
      }

      final response = await _chat!.sendMessage(Content.text(text));
      final responseText = response.text ?? '';

      // Parse JSON list for books if present
      List<ChatRecommendedBook> recommendedBooks = [];
      String cleanedText = responseText;

      final jsonRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
      final match = jsonRegex.firstMatch(responseText);
      if (match != null) {
        try {
          final jsonString = match.group(1)?.trim() ?? '';
          final decoded = json.decode(jsonString);
          if (decoded is List) {
            recommendedBooks = decoded.map((item) {
              return ChatRecommendedBook(
                bookId: DateTime.now().microsecondsSinceEpoch,
                title: item['title'] ?? '',
                author: item['author'],
                category: item['category'],
                price: item['price'] != null
                    ? double.tryParse(item['price'].toString())
                    : null,
                reason: item['reason'],
              );
            }).toList();
          }
          // Remove the JSON block from text so users only see clean markdown/text!
          cleanedText = responseText.replaceFirst(jsonRegex, '').trim();
        } catch (e) {
          debugPrint('Error parsing recommended books JSON: $e');
        }
      }

      _messages.add(
        ChatMessage(
          id: _newId(),
          role: ChatMessageRole.assistant,
          text: cleanedText.isNotEmpty
              ? cleanedText
              : 'Mình đã nhận được yêu cầu của bạn.',
          createdAt: DateTime.now(),
          recommendedBooks: recommendedBooks,
        ),
      );
    } catch (e) {
      _errorMessage =
          'Không thể kết nối với Gemini AI: $e\n\nVui lòng kiểm tra API key hoặc kết nối internet.';
      _messages.add(
        ChatMessage(
          id: _newId(),
          role: ChatMessageRole.assistant,
          text: _errorMessage!,
          createdAt: DateTime.now(),
          isError: true,
        ),
      );
      debugPrint('Gemini Chat error: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendSuggestion(String text) => sendMessage(text);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
