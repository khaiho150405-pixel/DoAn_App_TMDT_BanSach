import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/dashboard.dart';
import '../models/sach.dart';
import '../models/admin_user.dart';
import '../models/promotion.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5235/api';
  static const String imageUrl = 'http://10.0.2.2:5235/images/';

  Future<List<Sach>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Sach'));

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Sach.fromJson(data)).toList();
      }

      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('Server connection error: $e');
      return [];
    }
  }

  Future<DashboardSummary> fetchDashboardSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/summary'));

    if (response.statusCode == 200) {
      return DashboardSummary.fromJson(json.decode(response.body));
    }

    throw Exception('Dashboard summary API error: ${response.statusCode}');
  }

  Future<List<RecentOrder>> fetchRecentOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders/recent'));

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => RecentOrder.fromJson(data)).toList();
    }

    throw Exception('Recent orders API error: ${response.statusCode}');
  }

  Future<List<RevenueChartPoint>> fetchRevenueChart() async {
    final response =
        await http.get(Uri.parse('$baseUrl/dashboard/revenue-chart'));

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((data) => RevenueChartPoint.fromJson(data))
          .toList();
    }

    throw Exception('Revenue chart API error: ${response.statusCode}');
  }

  // --- ADMIN USER MANAGEMENT ---

  Future<List<AdminUser>> fetchAdminUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => AdminUser.fromJson(data)).toList();
    }

    throw Exception('Failed to load users: ${response.statusCode}');
  }

  Future<void> addAdminUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    if (response.statusCode != 200) {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Thêm nhân viên thất bại');
      } catch (e) {
        if (e is FormatException) {
          throw Exception('Thêm nhân viên thất bại: ${response.statusCode}');
        }
        rethrow;
      }
    }
  }

  Future<void> toggleUserStatus(int userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/status'),
    );

    if (response.statusCode != 200) {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Cập nhật trạng thái thất bại');
      } catch (e) {
        if (e is FormatException) {
          throw Exception('Cập nhật trạng thái thất bại: ${response.statusCode}');
        }
        rethrow;
      }
    }
  }

  // --- PROMOTION MANAGEMENT ---

  Future<List<Promotion>> fetchPromotions() async {
    final response = await http.get(Uri.parse('$baseUrl/promotions'));

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Promotion.fromJson(data)).toList();
    }

    throw Exception('Failed to load promotions: ${response.statusCode}');
  }

  Future<void> addPromotion(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promotions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Tạo khuyến mãi thất bại');
      } catch (e) {
        if (e is FormatException) {
          throw Exception('Tạo khuyến mãi thất bại: ${response.statusCode}');
        }
        rethrow;
      }
    }
  }

  // --- SETTINGS ---

  Future<void> changePassword(
      int maTaiKhoan, String oldPw, String newPw) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/ChangePassword'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'maTaiKhoan': maTaiKhoan,
        'matKhauCu': oldPw,
        'matKhauMoi': newPw,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Đổi mật khẩu thất bại');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLogs() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/Logs'));

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      return jsonResponse.cast<Map<String, dynamic>>();
    }

    throw Exception('Failed to load logs: ${response.statusCode}');
  }
}
