import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';

// Import các màn hình con (Sẽ tạo ở bước dưới)
import 'tim_kiem_sach_screen.dart';
import 'quan_ly_don_hang_screen.dart';
import 'tao_tai_khoan_khach_screen.dart';
import 'hoi_dap_screen.dart';
import 'quan_ly_danh_gia_screen.dart';

class SaleHomeScreen extends StatelessWidget {
  const SaleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Điều Khiển - Bán Hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Header chào mừng
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: Colors.deepOrange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xin chào, ${user?.fullName ?? "Nhân viên"}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                const SizedBox(height: 5),
                const Text('Chúc bạn một ngày chốt sale hiệu quả!', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),

          // Lưới tính năng
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(context, 'Xử lý Đơn hàng', Icons.receipt_long, Colors.blue, const QuanLyDonHangScreen()),
                _buildMenuCard(context, 'Tìm kiếm Sách', Icons.search, Colors.green, const TimKiemSachSaleScreen()),
                _buildMenuCard(context, 'Hỗ trợ Hỏi đáp', Icons.chat_bubble_outline, Colors.orange, const HoidapScreen()),
                _buildMenuCard(context, 'Quản lý Đánh giá', Icons.star_rate, Colors.amber, const QuanLyDanhGiaScreen()),
                _buildMenuCard(context, 'Tạo TK Khách', Icons.person_add_alt_1, Colors.purple, const TaoTaiKhoanKhachScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget targetScreen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen)),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(icon, size: 30, color: color)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}