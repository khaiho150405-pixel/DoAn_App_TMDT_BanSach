import 'package:flutter/material.dart';

class QuanLyDonHangScreen extends StatelessWidget {
  const QuanLyDonHangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xử lý Đơn Hàng'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đang chuẩn bị'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Danh sách đơn chờ xác nhận... (Đang chờ API)')),
            Center(child: Text('Danh sách đơn đang đóng gói... (Đang chờ API)')),
            Center(child: Text('Danh sách đơn đang giao... (Đang chờ API)')),
            Center(child: Text('Đơn thành công / Đã hủy... (Đang chờ API)')),
          ],
        ),
      ),
    );
  }
}