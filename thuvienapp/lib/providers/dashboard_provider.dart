import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import 'api_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService;

  DashboardProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  DashboardSummary? _summary;
  List<RecentOrder> _recentOrders = [];
  List<RevenueChartPoint> _chartPoints = [];
  bool _isLoading = false;
  bool _isNotificationEnabled = true;
  String? _errorMessage;

  DashboardSummary? get summary => _summary;
  List<RecentOrder> get recentOrders => List.unmodifiable(_recentOrders);
  List<RevenueChartPoint> get chartPoints => List.unmodifiable(_chartPoints);
  bool get isLoading => _isLoading;
  bool get isNotificationEnabled => _isNotificationEnabled;
  String? get errorMessage => _errorMessage;
  bool get hasData => _summary != null;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.fetchDashboardSummary(),
        _apiService.fetchRecentOrders(),
        _apiService.fetchRevenueChart(),
      ]);

      _summary = results[0] as DashboardSummary;
      _recentOrders = results[1] as List<RecentOrder>;
      _chartPoints = results[2] as List<RevenueChartPoint>;
    } catch (error) {
      _errorMessage = 'Không thể tải dữ liệu dashboard. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleNotification() {
    _isNotificationEnabled = !_isNotificationEnabled;
    notifyListeners();
  }
}
