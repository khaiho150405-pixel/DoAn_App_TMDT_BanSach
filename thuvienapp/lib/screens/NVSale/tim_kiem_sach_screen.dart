import 'package:flutter/material.dart';
class TimKiemSachSaleScreen extends StatelessWidget {
  const TimKiemSachSaleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tra cứu thông tin Sách'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: const Center(child: Text('Thanh tìm kiếm và Filter đang chờ API...')),
    );
  }
}