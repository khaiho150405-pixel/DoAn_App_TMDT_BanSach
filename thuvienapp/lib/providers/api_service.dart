import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sach.dart';

class ApiService {
  // Dùng IP của máy ảo Android để trỏ về localhost của máy tính
  static const String baseUrl = 'http://10.0.2.2:5235/api';

  // Link gốc để lấy hình ảnh (từ thư mục wwwroot/images của C#)
  static const String imageUrl = 'http://10.0.2.2:5235/images/';

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
}