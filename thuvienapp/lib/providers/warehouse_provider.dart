import 'dart:async';

import 'package:flutter/material.dart';

import '../models/warehouse_dashboard_data.dart';
import 'api_service.dart';

class WarehouseProvider with ChangeNotifier {
  final ApiService _apiService;

  WarehouseProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // =========================================================
  // DASHBOARD
  // =========================================================
  WarehouseDashboardData? _dashboardData;
  bool _isDashboardLoading = false;
  String? _dashboardError;

  WarehouseDashboardData? get dashboardData => _dashboardData;
  bool get isDashboardLoading => _isDashboardLoading;
  String? get dashboardError => _dashboardError;

  Future<void> loadDashboard() async {
    _isDashboardLoading = true;
    _dashboardError = null;
    notifyListeners();

    try {
      final json = await _apiService.fetchWarehouseDashboard();
      _dashboardData = WarehouseDashboardData.fromJson(json);
    } catch (e) {
      _dashboardError = 'Không thể tải dữ liệu dashboard.';
    } finally {
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // INVENTORY (TỒN KHO)
  // =========================================================
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _filteredInventory = [];
  bool _isInventoryLoading = false;
  String? _inventoryError;
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterStatus;
  Timer? _debounceTimer;

  List<Map<String, dynamic>> get filteredInventory => _filteredInventory;
  bool get isInventoryLoading => _isInventoryLoading;
  String? get inventoryError => _inventoryError;
  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  String? get filterStatus => _filterStatus;

  Future<void> loadInventory() async {
    _isInventoryLoading = true;
    _inventoryError = null;
    notifyListeners();

    try {
      _inventory = await _apiService.fetchInventory();
      _applyFilters();
    } catch (e) {
      _inventoryError = 'Không thể tải danh sách tồn kho.';
    } finally {
      _isInventoryLoading = false;
      notifyListeners();
    }
  }

  void searchInventory(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    });
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    _filterStatus = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var result = List<Map<String, dynamic>>.from(_inventory);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) {
        final name = (item['tensach'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    }

    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      result = result.where((item) {
        return item['tenTheLoai'] == _filterCategory;
      }).toList();
    }

    if (_filterStatus != null && _filterStatus!.isNotEmpty) {
      result = result.where((item) {
        return item['trangthai'] == _filterStatus;
      }).toList();
    }

    _filteredInventory = result;
  }

  // =========================================================
  // STOCK ALERTS (CẢNH BÁO)
  // =========================================================
  List<Map<String, dynamic>> _alerts = [];
  bool _isAlertsLoading = false;
  String? _alertsError;
  int _alertThreshold = 10;

  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isAlertsLoading => _isAlertsLoading;
  String? get alertsError => _alertsError;
  int get alertThreshold => _alertThreshold;

  Future<void> loadAlerts({int? threshold}) async {
    if (threshold != null) _alertThreshold = threshold;
    _isAlertsLoading = true;
    _alertsError = null;
    notifyListeners();

    try {
      _alerts =
          await _apiService.fetchStockAlerts(threshold: _alertThreshold);
    } catch (e) {
      _alertsError = 'Không thể tải cảnh báo tồn kho.';
    } finally {
      _isAlertsLoading = false;
      notifyListeners();
    }
  }

  void setAlertThreshold(int threshold) {
    _alertThreshold = threshold;
    loadAlerts();
  }

  // =========================================================
  // IMPORT RECEIPTS (PHIẾU NHẬP)
  // =========================================================
  List<Map<String, dynamic>> _importReceipts = [];
  bool _isImportLoading = false;
  String? _importError;

  List<Map<String, dynamic>> get importReceipts => _importReceipts;
  bool get isImportLoading => _isImportLoading;
  String? get importError => _importError;

  Future<void> loadImportReceipts({int? maNv}) async {
    _isImportLoading = true;
    _importError = null;
    notifyListeners();

    try {
      _importReceipts = await _apiService.fetchImportReceipts(maNv: maNv);
    } catch (e) {
      _importError = 'Không thể tải danh sách phiếu nhập.';
    } finally {
      _isImportLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOOKUP DATA (dropdown dùng chung)
  // =========================================================
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _authors = [];
  List<Map<String, dynamic>> _publishers = [];

  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get authors => _authors;
  List<Map<String, dynamic>> get publishers => _publishers;

  Future<void> loadLookupData() async {
    try {
      final results = await Future.wait([
        _apiService.fetchCategories(),
        _apiService.fetchAuthorList(),
        _apiService.fetchPublisherList(),
      ]);

      _categories = results[0];
      _authors = results[1];
      _publishers = results[2];
      notifyListeners();
    } catch (e) {
      debugPrint('loadLookupData error: $e');
    }
  }

  /// Danh sách tên thể loại unique cho filter dropdown
  List<String> get categoryNames {
    return _categories
        .map((c) => c['tentheloai']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
