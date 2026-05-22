import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_settings_section.dart';
import '../login_screen.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import 'change_password_screen.dart';
import 'my_reviews_screen.dart';
import 'support_screen.dart';
import '../chatbot/chatbot_screen.dart';

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

    // Các menu chức năng cài đặt
    final List<_SettingsTile> settingsTiles = [
      _SettingsTile(
        icon: Icons.shopping_bag_outlined,
        iconColor: const Color(0xFF2563EB),
        title: 'Đơn hàng của tôi',
        subtitle: 'Xem lịch sử và trạng thái đơn hàng',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MyOrdersScreen(user: user!)),
          );
        },
      ),
      _SettingsTile(
        icon: Icons.lock_outline,
        iconColor: const Color(0xFF8B5CF6),
        title: 'Đổi mật khẩu',
        subtitle: 'Cập nhật mật khẩu tài khoản',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChangePasswordScreen(user: user!)),
          );
        },
      ),
      _SettingsTile(
        icon: Icons.star_border,
        iconColor: const Color(0xFFF59E0B),
        title: 'Đánh giá của tôi',
        subtitle: 'Xem lại các nhận xét và lượt đánh giá của bạn',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MyReviewsScreen(user: user!)),
          );
        },
      ),
      _SettingsTile(
        icon: Icons.smart_toy_outlined,
        iconColor: const Color(0xFF10B981),
        title: 'Trợ lý ảo AI',
        subtitle: 'Nhận gợi ý và tư vấn tìm sách thông minh',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
      ),
      _SettingsTile(
        icon: Icons.help_outline,
        iconColor: const Color(0xFF0EA5E9),
        title: 'Hỏi đáp / Hỗ trợ',
        subtitle: 'Liên hệ giải đáp câu hỏi và trợ giúp trực tuyến',
        onTap: () {
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Vui lòng đăng nhập để sử dụng tính năng hỗ trợ!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SupportScreen(user: user!)),
          );
        },
      ),
    ];

    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Profile Card ---
                _buildProfileCard(user!),
                const SizedBox(height: 16),

                // --- Section label ---
                _buildSectionLabel('Tài khoản của tôi'),
                const SizedBox(height: 8),

                // --- Grouped settings menu card ---
                _buildSettingsCard(settingsTiles),
                const SizedBox(height: 16),

                // --- Cài đặt chung ---
                const CommonSettingsSection(),
                const SizedBox(height: 24),

                // --- Outlined Logout Button ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutConfirmation(context),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Đăng xuất',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _getAvatarLetter(user.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        user.tenDangNhap,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        user.roleName ?? 'Khách hàng',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<_SettingsTile> tiles) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Column(
        children: List.generate(tiles.length, (i) {
          final tile = tiles[i];
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tile.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tile.icon, color: tile.iconColor, size: 22),
                ),
                title: Text(
                  tile.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  tile.subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: tile.onTap,
              ),
              if (i < tiles.length - 1)
                Divider(height: 1, indent: 72, color: Colors.grey[200]),
            ],
          );
        }),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận đăng xuất',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
          style: TextStyle(color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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

class _SettingsTile {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
