import 'package:flutter/material.dart';
class QuanLyDanhGiaScreen extends StatelessWidget {
  const QuanLyDanhGiaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Đánh giá'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: const Center(child: Text('Tính năng duyệt/ẩn Feedback chờ API...')),
    );
  }
}