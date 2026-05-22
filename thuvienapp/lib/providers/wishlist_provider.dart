import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sach.dart';

class WishlistProvider with ChangeNotifier {
  static const String _prefKey = 'user_wishlist_books';
  final List<Sach> _favorites = [];

  WishlistProvider() {
    _loadFromPrefs();
  }

  /// Trả về danh sách sách yêu thích không thể sửa đổi trực tiếp từ bên ngoài
  List<Sach> get items => List.unmodifiable(_favorites);

  /// Kiểm tra xem một cuốn sách đã nằm trong danh sách yêu thích chưa
  bool isFavorite(int bookId) {
    return _favorites.any((book) => book.maSach == bookId);
  }

  /// Thêm hoặc bớt cuốn sách khỏi danh sách yêu thích
  Future<void> toggleFavorite(Sach book) async {
    final index = _favorites.indexWhere((item) => item.maSach == book.maSach);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(book);
    }
    notifyListeners();
    await _saveToPrefs();
  }

  /// Xóa sạch danh sách yêu thích
  Future<void> clear() async {
    _favorites.clear();
    notifyListeners();
    await _saveToPrefs();
  }

  /// Tải dữ liệu lưu trữ từ SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(jsonString);
        _favorites.clear();
        for (final item in decodedList) {
          if (item is Map<String, dynamic>) {
            _favorites.add(Sach.fromJson(item));
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách yêu thích từ Prefs: $e');
    }
  }

  /// Ghi danh sách yêu thích xuống SharedPreferences dưới dạng chuỗi JSON
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> mappedList =
          _favorites.map((book) => book.toJson()).toList();
      final String jsonString = json.encode(mappedList);
      await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      debugPrint('Lỗi lưu danh sách yêu thích vào Prefs: $e');
    }
  }
}
