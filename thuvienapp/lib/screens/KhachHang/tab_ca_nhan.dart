import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import '../../theme/app_theme.dart';

/// Tab Cá Nhân - Hiển thị thông tin khách hàng hoặc yêu cầu đăng nhập
class TabCaNhan extends StatelessWidget {
  final User? user;
  const TabCaNhan({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    // Nếu chưa đăng nhập -> hiển thị yêu cầu đăng nhập
    if (user == null) {
      return const LoginRequiredView(title: 'Tài khoản cá nhân');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar lớn
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepOrange,
            child: Text(
              _getAvatarLetter(user!.fullName),
              style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(user!.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user!.tenDangNhap, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(user!.roleName ?? 'Khách hàng',
                style: const TextStyle(color: Colors.deepOrange, fontSize: 13)),
          ),
          const SizedBox(height: 30),

          // Danh sách menu
          _buildMenuItem(context, Icons.shopping_bag_outlined, 'Đơn hàng của tôi', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MyOrdersScreen(user: user!)));
          }),
          _buildMenuItem(context, Icons.location_on_outlined, 'Địa chỉ giao hàng', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')));
          }),
          _buildMenuItem(context, Icons.favorite_border, 'Sách yêu thích', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')));
          }),
          _buildMenuItem(context, Icons.star_border, 'Đánh giá của tôi', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')));
          }),
          _buildMenuItem(context, Icons.help_outline, 'Hỏi đáp / Hỗ trợ', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')));
          }),
          _buildMenuItem(context, Icons.settings_outlined, 'Cài đặt', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')));
          }),
          const Divider(height: 30),
          // Nút đăng xuất
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepOrange),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getAvatarLetter(String fullName) {
    if (fullName.isEmpty) return "K";
    List<String> parts = fullName.trim().split(' ');
    if (parts.isNotEmpty && parts.last.isNotEmpty) {
      return parts.last[0].toUpperCase();
    }
    return fullName[0].toUpperCase();
  }
}
