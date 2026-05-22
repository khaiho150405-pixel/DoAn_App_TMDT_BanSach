import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/api_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/admin/admin_app_bar_title.dart';
import '../../widgets/common_settings_section.dart';
import '../login_screen.dart';
import 'author_management_screen.dart';
import 'publisher_management_screen.dart';

class WarehouseSettingsScreen extends StatefulWidget {
  const WarehouseSettingsScreen({super.key});

  @override
  State<WarehouseSettingsScreen> createState() =>
      _WarehouseSettingsScreenState();
}

class _WarehouseSettingsScreenState extends State<WarehouseSettingsScreen> {

  // =========================================================
  // ĐĂNG XUẤT
  // =========================================================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.logout, color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            const Text('Đăng xuất',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleSpacing: 12,
        title: const AdminAppBarTitle(
          icon: Icons.settings_rounded,
          title: 'Cài đặt',
          subtitle: 'Thông tin & tuỳ chỉnh',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      (user?.fullName ?? 'T').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Thủ Kho',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Nhân viên kho',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings section (dùng chung)
            const CommonSettingsSection(),
            const SizedBox(height: 20),

            // Management section
            const Text(
              'QUẢN LÝ DANH MỤC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _SettingsTile(
                icon: Icons.person_search_rounded,
                title: 'Quản lý Tác giả',
                subtitle: 'Thêm, sửa, xóa tác giả sách',
                iconColor: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AuthorManagementScreen())),
              ),
              _SettingsTile(
                icon: Icons.business_rounded,
                title: 'Quản lý Nhà xuất bản',
                subtitle: 'Thêm, sửa, xóa NXB',
                iconColor: const Color(0xFF059669),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PublisherManagementScreen())),
              ),
            ]),
            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          final tile = tiles[index];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tile.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(tile.icon, color: tile.iconColor, size: 20),
                ),
                title: Text(
                  tile.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                subtitle: Text(
                  tile.subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                trailing: tile.trailing ??
                    (tile.onTap != null
                        ? const Icon(Icons.chevron_right,
                            color: Color(0xFF9CA3AF))
                        : null),
                onTap: tile.onTap,
              ),
              if (index < tiles.length - 1)
                const Divider(height: 1, indent: 60),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
    this.trailing,
  });
}
