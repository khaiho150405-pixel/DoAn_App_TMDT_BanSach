import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/admin_user.dart';
import '../models/dashboard.dart';
import '../models/promotion.dart';
import '../models/sach.dart';
import '../models/danh_gia.dart';
import '../models/ho_dap.dart';
import '../models/tin_nhan_ho_tro.dart';
import '../models/user.dart';

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
      debugPrint('fetchBooks error: $e');
      return [];
    }
  }

  Future<List<Sach>> filterBooks({
    String? author,
    String? publisher,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final params = <String, String>{};
      if (author != null && author.trim().isNotEmpty) {
        params['author'] = author.trim();
      }
      if (publisher != null && publisher.trim().isNotEmpty) {
        params['publisher'] = publisher.trim();
      }
      if (minPrice != null) params['minPrice'] = minPrice.toString();
      if (maxPrice != null) params['maxPrice'] = maxPrice.toString();

      final uri = Uri.parse('$baseUrl/Sach/filter').replace(
        queryParameters: params.isEmpty ? null : params,
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Sach.fromJson(data)).toList();
      }
      throw Exception('Filter API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('filterBooks error: $e');
      return [];
    }
  }

  Future<List<String>> fetchAuthors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Sach/authors'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchAuthors error: $e');
      return [];
    }
  }

  Future<List<String>> fetchPublishers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Sach/publishers'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchPublishers error: $e');
      return [];
    }
  }

  Future<Sach?> fetchBookDetail(int maSach) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Sach/$maSach'));
      if (response.statusCode == 200) {
        return Sach.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('fetchBookDetail error: $e');
      return null;
    }
  }

  Future<List<Sach>> fetchUserRecommendations(int maKh) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Recommendation/user/$maKh'),
      );
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Sach.fromJson(data)).toList();
      }
      throw Exception('Recommendation API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchUserRecommendations error: $e');
      return [];
    }
  }

  Future<List<Sach>> fetchSimilarBooks(int maSach) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Recommendation/book/$maSach'),
      );
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Sach.fromJson(data)).toList();
      }
      throw Exception('Similar books API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchSimilarBooks error: $e');
      return [];
    }
  }

  Future<List<Sach>> fetchTrendingBooks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Recommendation/trending'),
      );
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Sach.fromJson(data)).toList();
      }
      throw Exception('Trending API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchTrendingBooks error: $e');
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
      final error = _tryDecodeMap(response.body);
      throw Exception(error['message'] ?? 'Them nhan vien that bai');
    }
  }

  Future<void> toggleUserStatus(int userId) async {
    final response = await http.put(Uri.parse('$baseUrl/users/$userId/status'));
    if (response.statusCode != 200) {
      final error = _tryDecodeMap(response.body);
      throw Exception(error['message'] ?? 'Cap nhat trang thai that bai');
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
      final error = _tryDecodeMap(response.body);
      throw Exception(error['message'] ?? 'Tao khuyen mai that bai');
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
      final error = _tryDecodeMap(response.body);
      throw Exception(error['message'] ?? 'Doi mat khau that bai');
    }
  }

  Future<User> fetchUserProfile(int maTaiKhoan) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/Profile/$maTaiKhoan'),
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    final error = _tryDecodeMap(response.body);
    throw Exception(error['message'] ?? 'Khong the tai thong tin tai khoan');
  }

  Future<User> updateUserProfile({
    required int maTaiKhoan,
    required String fullName,
    required String email,
    String? soDienThoai,
    String? diaChiMacDinh,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/Profile/$maTaiKhoan'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'hoVaTen': fullName,
        'email': email,
        'sdt': soDienThoai,
        'diaChiMacDinh': diaChiMacDinh,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    final error = _tryDecodeMap(response.body);
    throw Exception(error['message'] ?? 'Cap nhat thong tin that bai');
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
      return _tryDecodeMap(response.body);
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
      return {'message': 'Loi ket noi server!'};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int maDH) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/Order/cancel/$maDH'));
      return _tryDecodeMap(response.body);
    } catch (e) {
      debugPrint('cancelOrder error: $e');
      return {'success': false, 'message': 'Loi ket noi server!'};
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
      final data = _tryDecodeMap(response.body);
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
      final data = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('replyQuestion error: $e');
      return {'success': false, 'message': 'Khong the ket noi server!'};
    }
  }

  // =========================================================
  // HỎI ĐÁP / HỖ TRỢ (Khách hàng)
  // =========================================================

  Future<List<HoiDap>> fetchSupportTickets(int maKh) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/HoiDap/KhachHang/$maKh'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => HoiDap.fromJson(data)).toList();
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchSupportTickets error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createSupportTicket(
    int maKh,
    String tieuDe,
    String loaiHoTro,
    String noiDung,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/HoiDap/Tao'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'maKh': maKh,
          'tieuDe': tieuDe,
          'loaiHoTro': loaiHoTro,
          'noiDung': noiDung,
        }),
      );
      final data = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('createSupportTicket error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ!'};
    }
  }

  Future<List<TinNhanHoTro>> fetchSupportMessages(int maHoiDap) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/HoiDap/TinNhan/$maHoiDap'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => TinNhanHoTro.fromJson(data)).toList();
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchSupportMessages error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> sendSupportMessage(
    int maHoiDap,
    String nguoiGui,
    int? maKh,
    int? maNv,
    String noiDung,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/HoiDap/TinNhan/Gui'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'maHoiDap': maHoiDap,
          'nguoiGui': nguoiGui,
          'maKh': maKh,
          'maNv': maNv,
          'noiDung': noiDung,
        }),
      );
      final data = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('sendSupportMessage error: $e');
      return {'success': false, 'message': 'Không thể kết nối máy chủ!'};
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
      final data = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('deleteReview error: $e');
      return {'success': false, 'message': 'Khong the ket noi server!'};
    }
  }

  Future<List<DanhGia>> fetchReviewsByBook(int maSach) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/DanhGia/Sach/$maSach'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => DanhGia.fromJson(data)).toList();
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchReviewsByBook error: $e');
      return [];
    }
  }

  Future<List<DanhGia>> fetchReviewsByCustomer(int maKh) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/DanhGia/KhachHang/$maKh'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => DanhGia.fromJson(data)).toList();
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchReviewsByCustomer error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> saveReview({
    required int maSach,
    required int maKh,
    required int diem,
    required String nhanXet,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DanhGia/Luu'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'maSach': maSach,
          'maKh': maKh,
          'diem': diem,
          'nhanxet': nhanXet,
        }),
      );
      final data = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      debugPrint('saveReview error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchNewBooksNews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ThongBao/SachMoi'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchNewBooksNews error: $e');
      return [];
    }
  }

  // =========================================================
  // THỦ KHO — WAREHOUSE APIs
  // =========================================================

  Future<Map<String, dynamic>> fetchWarehouseDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/Kho/Dashboard'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Warehouse dashboard API error: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchInventory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Kho/TonKho'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      throw Exception('Inventory API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchInventory error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchStockAlerts({int threshold = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Kho/CanhBao?threshold=$threshold'),
      );
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      throw Exception('Stock alerts API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('fetchStockAlerts error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Sach/TheLoai'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchCategories error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAuthorList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Sach/TacGiaList'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchAuthorList error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPublisherList() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/Sach/NhaXuatBanList'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchPublisherList error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateBook(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Sach/CapNhat/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('updateBook error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  Future<Map<String, dynamic>> deleteBook(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/Sach/Xoa/$id'));
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('deleteBook error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchImportReceipts({int? maNv}) async {
    try {
      final uri = maNv != null
          ? '$baseUrl/PhieuNhap/DanhSach?maNv=$maNv'
          : '$baseUrl/PhieuNhap/DanhSach';
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchImportReceipts error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchImportReceiptDetail(int mapn) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/PhieuNhap/ChiTiet/$mapn'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('fetchImportReceiptDetail error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createImportReceipt(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/PhieuNhap/Tao'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('createImportReceipt error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  // =========================================================
  // QUẢN LÝ TÁC GIẢ (NV Kho)
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchAuthorsManagement() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/TacGia'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchAuthorsManagement error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addAuthor(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/TacGia'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('addAuthor error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  Future<Map<String, dynamic>> updateAuthor(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/TacGia/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('updateAuthor error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  Future<Map<String, dynamic>> deleteAuthor(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/TacGia/$id'));
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('deleteAuthor error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  // =========================================================
  // QUẢN LÝ NHÀ XUẤT BẢN (NV Kho)
  // =========================================================

  Future<List<Map<String, dynamic>>> fetchPublishersManagement() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/NhaXuatBan'));
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchPublishersManagement error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addPublisher(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/NhaXuatBan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('addPublisher error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  Future<Map<String, dynamic>> updatePublisher(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/NhaXuatBan/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('updatePublisher error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  Future<Map<String, dynamic>> deletePublisher(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/NhaXuatBan/$id'));
      final result = _tryDecodeMap(response.body);
      return {'success': response.statusCode == 200, ...result};
    } catch (e) {
      debugPrint('deletePublisher error: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }
  // =========================================================
  // MINING — VertTopKDS Top-K Analysis
  // =========================================================

  Future<Map<String, dynamic>> runMiningTopK(int k) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Mining/topk?k=$k'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      final error = _tryDecodeMap(response.body);
      throw Exception(error['message'] ?? 'Mining API error: ${response.statusCode}');
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('runMiningTopK error: $e');
      throw Exception('Không thể kết nối server Mining!');
    }
  }

  Future<Map<String, dynamic>> applyMiningPromotions(List<dynamic> results) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Mining/apply-promotions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'results': results}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      final error = _tryDecodeMap(response.body);
      throw Exception(error['message'] ?? 'Apply promotions error: ${response.statusCode}');
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('applyMiningPromotions error: $e');
      throw Exception('Không thể kết nối server!');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAiPromotions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Promotions/ai-generated'),
      );
      if (response.statusCode == 200) {
        final List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchAiPromotions error: $e');
      return [];
    }
  }

  Map<String, dynamic> _tryDecodeMap(String body) {
    if (body.isEmpty) return {};
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }
}
