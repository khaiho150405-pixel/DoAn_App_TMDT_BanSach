import 'package:flutter/material.dart';

class TaoTaiKhoanKhachScreen extends StatefulWidget {
  const TaoTaiKhoanKhachScreen({super.key});

  @override
  State<TaoTaiKhoanKhachScreen> createState() => _TaoTaiKhoanKhachScreenState();
}

class _TaoTaiKhoanKhachScreenState extends State<TaoTaiKhoanKhachScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mở Tài Khoản Khách'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.support_agent, size: 80, color: Colors.deepOrange),
              const SizedBox(height: 20),
              TextFormField(decoration: const InputDecoration(labelText: 'Họ và tên khách hàng', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 15),
              TextFormField(decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 15),
              TextFormField(decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 15),
              TextFormField(decoration: const InputDecoration(labelText: 'Tên đăng nhập', border: OutlineInputBorder(), prefixIcon: Icon(Icons.login))),
              const SizedBox(height: 15),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu khởi tạo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                  onPressed: () {
                    // TODO: Gọi API /api/Auth/Register
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng đang chờ API C#')));
                  },
                  child: const Text('TẠO TÀI KHOẢN MỚI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}