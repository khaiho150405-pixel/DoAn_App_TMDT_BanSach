import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../providers/api_service.dart';

// Import các màn hình để điều hướng
import 'NVSale/sale_home_screen.dart';
import 'KhachHang/home_screen.dart'; // Màn hình khách hàng
// Import tạm các màn hình khác (Nếu bạn chưa làm tới thì có thể comment lại)
// import 'Admin/AdminHome.dart';
// import 'ThuKho/ThuKho_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Hàm gọi API Đăng nhập
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/Auth/Login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "TenDangNhap": _usernameController.text.trim(),
          "MatKhau": _passwordController.text.trim()
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 1. Chuyển JSON thành đối tượng User
        User loggedInUser = User.fromJson(data);

        // 2. Lưu vào State Management (Provider)
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(loggedInUser);
        }

        // 3. Điều hướng dựa theo Role (Phân quyền)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chào mừng ${loggedInUser.fullName}!'), backgroundColor: Colors.green),
          );

          Widget nextScreen;
          switch (loggedInUser.roleId) {
            case 1:
            // nextScreen = const AdminHomeScreen(); // Chờ tạo màn hình Admin
              nextScreen = const HomeScreen(); // Tạm thời đẩy về Home
              break;
            case 2:
              nextScreen = const SaleHomeScreen(); // Vào thẳng Dashboard Sale
              break;
            case 3:
            // nextScreen = const ThuKhoHomeScreen(); // Chờ cập nhật màn hình Kho
              nextScreen = const HomeScreen();
              break;
            case 4:
            default:
              nextScreen = const HomeScreen(); // Khách hàng vào trang mua sắm
              break;
          }

          // Chuyển trang và xóa lịch sử (không cho back lại trang login)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      } else {
        // Sai tài khoản / mật khẩu
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Đăng nhập thất bại'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể kết nối đến máy chủ API!'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Icon ứng dụng
                  const Icon(Icons.book_online, size: 100, color: Colors.deepOrange),
                  const SizedBox(height: 20),
                  const Text(
                    'E-BookStore',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 40),

                  // Ô nhập Tài khoản
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Tên đăng nhập',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                  ),
                  const SizedBox(height: 20),

                  // Ô nhập Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                  ),
                  const SizedBox(height: 30),

                  // Nút Đăng nhập
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link Đăng ký (Dành cho khách hàng)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản?'),
                      TextButton(
                        onPressed: () {
                          // TODO: Chuyển sang màn hình Đăng ký
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tính năng đăng ký đang cập nhật')),
                          );
                        },
                        child: const Text('Đăng ký ngay', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}