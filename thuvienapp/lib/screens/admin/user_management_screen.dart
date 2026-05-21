import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_user_provider.dart';
import '../../widgets/admin/user_form_dialog.dart';

import '../../widgets/dashboard/dashboard_state_views.dart';
import '../../../models/admin_user.dart';
import '../../widgets/admin/admin_app_bar_title.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().loadUsers();
    });
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (_) => const UserFormDialog(),
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
          icon: Icons.people_outline,
          title: 'Nhân viên',
          subtitle: 'Quản lý tài khoản và phân quyền',
        ),
      ),
      body: Consumer<AdminUserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const DashboardLoadingView();
          }

          if (provider.errorMessage != null && provider.users.isEmpty) {
            return DashboardErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadUsers,
            );
          }

          final users = provider.users;

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: provider.loadUsers,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InlineError(message: provider.errorMessage!),
                        ),
                      // --- Filter bar ---
                      _buildFilterBar(provider),
                      const SizedBox(height: 16),
                      // --- User list ---
                      if (users.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.person_search_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Không tìm thấy nhân viên nào.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...users.map((user) => _UserCard(user: user)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhân viên'),
      ),
    );
  }

  Widget _buildFilterBar(AdminUserProvider provider) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, email, sđt...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                provider.searchUsers(value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              value: 0,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Tất cả quyền')),
                DropdownMenuItem(value: 1, child: Text('Admin')),
                DropdownMenuItem(value: 2, child: Text('Bán hàng')),
                DropdownMenuItem(value: 3, child: Text('Kho')),
              ],
              onChanged: (value) {
                if (value != null) {
                  provider.filterByRole(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user.trangThai == 'Hoạt động';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEFF6FF),
              radius: 24,
              child: Text(
                user.hoVaTen.isNotEmpty ? user.hoVaTen[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.hoVaTen,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(user.email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${user.chucVu} • ${user.tenQuyen}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Switch(
                  value: isActive,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    if (user.id == 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Không thể khóa Admin gốc!')),
                      );
                      return;
                    }
                    context.read<AdminUserProvider>().toggleStatus(user.id);
                  },
                ),
                Text(
                  isActive ? 'Hoạt động' : 'Ngừng hoạt động',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? const Color(0xFF10B981) : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
