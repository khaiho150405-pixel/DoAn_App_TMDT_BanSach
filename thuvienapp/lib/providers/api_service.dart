import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sach.dart';

class ApiService {
  // Dùng IP của máy ảo Android để trỏ về localhost của máy tính
  static const String baseUrl = 'http://10.0.2.2:5235/api';

  // Link gốc để lấy hình ảnh (từ thư mục wwwroot/images của C#)
  static const String imageUrl = 'http://10.0.2.2:5235/images/';

  // ======================================================================
  //                          SÁCH
  // ======================================================================

  // Lấy danh sách Sách
  Future<List<Sach>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Sach'));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Sach.fromJson(data)).toList();
      } else {
        throw Exception('Lỗi gọi API: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi kết nối Server: $e');
      return []; // Trả về mảng rỗng nếu sập mạng
    }
  }

  // ======================================================================
  //                       ĐƠN HÀNG (Dùng cho NVSale)
  // ======================================================================

  // Lấy danh sách đơn hàng theo trạng thái
  Future<List<Map<String, dynamic>>> fetchOrdersByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DonHang/GetByStatus?status=${Uri.encodeComponent(status)}'),
      );
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi fetchOrdersByStatus: $e');
      return [];
    }
  }

  // Lấy chi tiết 1 đơn hàng
  Future<Map<String, dynamic>?> fetchOrderDetail(int maDH) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DonHang/ChiTiet/$maDH'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi fetchOrderDetail: $e');
      return null;
    }
  }

  // Cập nhật trạng thái đơn hàng (Sale chuyển trạng thái)
  Future<Map<String, dynamic>> updateOrderStatus(int maDH, String statusMoi, int maNV) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/DonHang/CapNhatTrangThaiDon/$maDH?statusMoi=${Uri.encodeComponent(statusMoi)}&maNV=$maNV'),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Lỗi updateOrderStatus: $e');
      return {'message': 'Lỗi kết nối server!'};
    }
  }

  // ======================================================================
  //                    ĐĂNG KÝ TÀI KHOẢN (Register)
  // ======================================================================

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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tenDangNhap": tenDangNhap,
          "matKhau": matKhau,
          "email": email,
          "hoVaTen": hoVaTen,
          "sdt": sdt,
          "diaChiMacDinh": diaChiMacDinh,
        }),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      print('Lỗi registerAccount: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  // ======================================================================
  //                         HỎI ĐÁP (Q&A)
  // ======================================================================

  // Lấy câu hỏi chưa trả lời
  Future<List<Map<String, dynamic>>> fetchPendingQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/HoiDap/ChuaTraLoi'),
      );
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi fetchPendingQuestions: $e');
      return [];
    }
  }

  // Lấy tất cả câu hỏi
  Future<List<Map<String, dynamic>>> fetchAllQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/HoiDap/TatCa'),
      );
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi fetchAllQuestions: $e');
      return [];
    }
  }

  // Trả lời câu hỏi
  Future<Map<String, dynamic>> replyQuestion(int maHoiDap, String traLoi, int maNV) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/HoiDap/TraLoi/$maHoiDap'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "traLoi": traLoi,
          "maNV": maNV,
        }),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      print('Lỗi replyQuestion: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }

  // ======================================================================
  //                       ĐÁNH GIÁ SÁCH (Reviews)
  // ======================================================================

  // Lấy tất cả đánh giá
  Future<List<Map<String, dynamic>>> fetchAllReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/DanhGia/DanhSach'),
      );
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi fetchAllReviews: $e');
      return [];
    }
  }

  // Xóa đánh giá vi phạm
  Future<Map<String, dynamic>> deleteReview(int maDanhGia) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/DanhGia/Xoa/$maDanhGia'),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      print('Lỗi deleteReview: $e');
      return {'success': false, 'message': 'Không thể kết nối server!'};
    }
  }
}