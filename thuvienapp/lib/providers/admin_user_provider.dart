import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import 'api_service.dart';

class AdminUserProvider with ChangeNotifier {
  final ApiService _apiService;

  AdminUserProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<AdminUser> _users = [];
  List<AdminUser> _filteredUsers = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  int _selectedRoleId = 0; // 0 = Tất cả

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AdminUser> get users => _filteredUsers;

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _apiService.fetchAdminUsers();
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchUsers(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void filterByRole(int roleId) {
    _selectedRoleId = roleId;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final matchSearch = user.hoVaTen.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery) ||
          user.chucVu.toLowerCase().contains(_searchQuery);

      final matchRole = _selectedRoleId == 0 || user.maQuyen == _selectedRoleId;

      return matchSearch && matchRole;
    }).toList();

    notifyListeners();
  }

  Future<void> addUser(Map<String, dynamic> userData) async {
    await _apiService.addAdminUser(userData);
    await loadUsers(); // Refresh sau khi thêm
  }

  Future<void> toggleStatus(int userId) async {
    try {
      await _apiService.toggleUserStatus(userId);
      // Thay đổi trạng thái UI ngay lập tức cho mượt
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final current = _users[index];
        final newStatus =
            current.trangThai == 'Hoạt động' ? 'Ngừng hoạt động' : 'Hoạt động';
        _users[index] = current.copyWith(trangThai: newStatus);
        _applyFilters();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
