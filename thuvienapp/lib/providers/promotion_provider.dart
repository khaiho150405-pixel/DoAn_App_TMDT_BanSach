import 'package:flutter/material.dart';
import '../models/promotion.dart';
import 'api_service.dart';

class PromotionProvider with ChangeNotifier {
  final ApiService _apiService;

  PromotionProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<Promotion> _promotions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterStatus = 'Tất cả';

  List<Promotion> get promotions {
    if (_filterStatus == 'Tất cả') return _promotions;
    return _promotions.where((p) => p.trangThai == _filterStatus).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;

  Future<void> loadPromotions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _promotions = await _apiService.fetchPromotions();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> addPromotion(Map<String, dynamic> data) async {
    await _apiService.addPromotion(data);
    await loadPromotions();
  }
}
