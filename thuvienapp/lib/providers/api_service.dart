import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/admin_user.dart';
import '../models/dashboard.dart';
import '../models/promotion.dart';
import '../models/sach.dart';

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
        throw Exception(error['message'] ?? 'Them nhan vien that bai');
      } catch (e) {
        if (e is FormatException) {
          throw Exception('Them nhan vien that bai: ${response.statusCode}');
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
        throw Exception(error['message'] ?? 'Cap nhat trang thai that bai');
      } catch (e) {
        if (e is FormatException) {
          throw Exception(
            'Cap nhat trang thai that bai: ${response.statusCode}',
          );
        }
        rethrow;
      }
    }
  }

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
        throw Exception(error['message'] ?? 'Tao khuyen mai that bai');
      } catch (e) {
        if (e is FormatException) {
          throw Exception('Tao khuyen mai that bai: ${response.statusCode}');
        }
        rethrow;
      }
    }
  }

  Future<void> changePassword(
    int maTaiKhoan,
    String oldPw,
    String newPw,
  ) async {
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
      throw Exception(error['message'] ?? 'Doi mat khau that bai');
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

  Future<List<Map<String, dynamic>>> fetchOrdersByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/DonHang/GetByStatus?status=${Uri.encodeComponent(status)}',
        ),
      );

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }

      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchOrdersByStatus error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchOrderDetail(int maDH) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DonHang/ChiTiet/$maDH'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchOrderDetail error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    int maDH,
    String statusMoi,
    int maNV,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/DonHang/CapNhatTrangThaiDon/$maDH'
          '?statusMoi=${Uri.encodeComponent(statusMoi)}&maNV=$maNV',
        ),
      );

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
      return {'message': 'Loi ket noi server!'};
    }
  }

  Future<Map<String, dynamic>> registerAccount({
    required String tenDangNhap,
    required String matKhau,
    required String email,
    required String hoVaTen,
    String? sdt,
    String? diaChiMacDinh,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/Register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tenDangNhap': tenDangNhap,
          'matKhau': matKhau,
          'email': email,
          'hoVaTen': hoVaTen,
          'sdt': sdt,
          'diaChiMacDinh': diaChiMacDinh,
        }),
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('registerAccount error: $e');
      return {'success': false, 'message': 'Khong the ket noi server!'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingQuestions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/HoiDap/ChuaTraLoi'));

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }

      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchPendingQuestions error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllQuestions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/HoiDap/TatCa'));

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }

      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchAllQuestions error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> replyQuestion(
    int maHoiDap,
    String traLoi,
    int maNV,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/HoiDap/TraLoi/$maHoiDap'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'traLoi': traLoi,
          'maNV': maNV,
        }),
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('replyQuestion error: $e');
      return {'success': false, 'message': 'Khong the ket noi server!'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllReviews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/DanhGia/DanhSach'));

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }

      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchAllReviews error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteReview(int maDanhGia) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/DanhGia/Xoa/$maDanhGia'),
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('deleteReview error: $e');
      return {'success': false, 'message': 'Khong the ket noi server!'};
    }
  }
}
