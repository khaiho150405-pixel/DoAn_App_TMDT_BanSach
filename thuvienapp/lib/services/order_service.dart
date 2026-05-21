import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../providers/api_service.dart';

class OrderService {
  static final String _baseUrl = '${ApiService.baseUrl}/Order';

  Future<OrderModel> checkout(Map<String, dynamic> requestBody) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/Checkout'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        throw Exception('API trả về dữ liệu rỗng (Không có phản hồi).');
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return OrderModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Lỗi khi đặt hàng');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Lỗi định dạng dữ liệu từ máy chủ.');
      }
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<List<OrderModel>> getOrdersByCustomer(int customerId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/Customer/$customerId'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        throw Exception('API trả về dữ liệu rỗng.');
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Iterable list = data['data'];
        return list.map((model) => OrderModel.fromJson(model)).toList();
      } else {
        throw Exception(data['message'] ?? 'Lỗi khi tải danh sách đơn hàng');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Lỗi định dạng dữ liệu từ máy chủ.');
      }
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$orderId'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        throw Exception('API trả về dữ liệu rỗng.');
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return OrderModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Không tìm thấy đơn hàng');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Lỗi định dạng dữ liệu từ máy chủ.');
      }
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/cancel/$orderId'),
          )
          .timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Lỗi khi hủy đơn hàng');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }
}
