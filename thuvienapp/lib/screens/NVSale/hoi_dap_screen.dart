import 'package:flutter/material.dart';
class HoidapScreen extends StatelessWidget {
  const HoidapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ Khách hàng'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: const Center(child: Text('Danh sách câu hỏi của khách đang chờ API...')),
    );
  }
}