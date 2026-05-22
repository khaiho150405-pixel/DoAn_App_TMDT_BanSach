import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/api_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/admin/admin_app_bar_title.dart';
import '../../widgets/common_settings_section.dart';
import '../login_screen.dart';
import 'user_management_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {

  void _showLogsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _SystemLogsScreen()),
    );
  }

  void _showLogoutDialog() {
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
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserProvider>().logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đăng xuất thành công!')),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleSpacing: 12,
        title: const AdminAppBarTitle(
          icon: Icons.settings_outlined,
          title: 'Cài đặt',
          subtitle: 'Tuỳ chỉnh hệ thống và tài khoản',
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: () async {
          // Settings is static, no real refresh needed
        },
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
                  _buildProfileCard(),
                  const SizedBox(height: 16),

                  // --- Cài đặt chung (dùng chung) ---
                  const CommonSettingsSection(),
                  const SizedBox(height: 16),

                  // --- Admin riêng ---
                  _buildSectionLabel('Quản trị'),
                  const SizedBox(height: 8),
                  _buildSettingsCard([
                    _SettingsTile(
                      icon: Icons.history,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'Logs hệ thống',
                      subtitle: 'Xem lịch sử hoạt động',
                      onTap: _showLogsScreen,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // --- Outlined Logout Button ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        side: const BorderSide(
                            color: Color(0xFFEA580C), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = context.watch<UserProvider>().user;
    final displayName = user?.fullName ?? 'Admin';
    final roleName = user?.roleName ?? 'Quản trị viên hệ thống';

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
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
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleName,
                    style:
                        const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                if (user == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserManagementScreen(currentUser: user),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF2563EB), size: 22),
              tooltip: 'Chỉnh sửa',
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
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<_SettingsTile> tiles) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                title: Text(tile.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(tile.subtitle,
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12)),
                trailing: tile.trailing ??
                    const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
                onTap: tile.onTap,
              ),
              if (i < tiles.length - 1)
                const Divider(height: 1, indent: 72, color: Color(0xFFE5E7EB)),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
}

// --- Màn hình Logs hệ thống ---
class _SystemLogsScreen extends StatefulWidget {
  const _SystemLogsScreen();

  @override
  State<_SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<_SystemLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _logs = await ApiService().fetchLogs();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleSpacing: 12,
        title: const AdminAppBarTitle(
          icon: Icons.history,
          title: 'Logs hệ thống',
          subtitle: 'Lịch sử hoạt động gần đây',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            color: Color(0xFF2563EB), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadLogs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2563EB),
                  onRefresh: _loadLogs,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _logs.map((log) {
                            final time = DateTime.tryParse(
                                log['time']?.toString() ?? '');
                            final timeStr = time != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(time)
                                : '';

                            return Card(
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long,
                                      color: Color(0xFF0EA5E9), size: 20),
                                ),
                                title: Text(
                                  log['action'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(log['detail'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280))),
                                    const SizedBox(height: 2),
                                    Text(timeStr,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
