import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user.dart';
import '../../../providers/admin_user_provider.dart';
import '../../../providers/api_service.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/admin/user_form_dialog.dart';

import '../../widgets/dashboard/dashboard_state_views.dart';
import '../../../models/admin_user.dart';
import '../../widgets/admin/admin_app_bar_title.dart';

class UserManagementScreen extends StatefulWidget {
  final User? currentUser;

  const UserManagementScreen({super.key, this.currentUser});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  User? _accountUser;
  bool _isAccountLoading = false;
  String? _accountError;

  bool get _isAccountMode => widget.currentUser != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAccountMode) {
        _loadCurrentAccount();
      } else {
        context.read<AdminUserProvider>().loadUsers();
      }
    });
  }

  Future<void> _loadCurrentAccount() async {
    final sourceUser =
        _accountUser ?? widget.currentUser ?? context.read<UserProvider>().user;
    if (sourceUser == null) return;

    setState(() {
      _isAccountLoading = true;
      _accountError = null;
    });

    try {
      final updated =
          await ApiService().fetchUserProfile(sourceUser.maTaiKhoan);
      if (!mounted) return;
      context.read<UserProvider>().updateUser(updated);
      setState(() {
        _accountUser = updated;
        _isAccountLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accountUser = sourceUser;
        _accountError = e.toString().replaceAll('Exception:', '').trim();
        _isAccountLoading = false;
      });
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (_) => const UserFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAccountMode) {
      final accountUser = context.watch<UserProvider>().user ??
          _accountUser ??
          widget.currentUser;

      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0,
          titleSpacing: 0,
          title: const AdminAppBarTitle(
            icon: Icons.manage_accounts_outlined,
            title: 'Cài đặt tài khoản',
            subtitle: 'Thông tin tài khoản đang đăng nhập',
          ),
        ),
        body: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: _loadCurrentAccount,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _isAccountLoading && accountUser == null
                    ? const DashboardLoadingView()
                    : _CurrentAccountView(
                        user: accountUser!,
                        errorMessage: _accountError,
                        isRefreshing: _isAccountLoading,
                        onRefresh: _loadCurrentAccount,
                      ),
              ),
            ),
          ),
        ),
      );
    }

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
                          child: const Column(
                            children: [
                              Icon(Icons.person_search_outlined,
                                  size: 48, color: Color(0xFF9CA3AF)),
                              SizedBox(height: 12),
                              Text(
                                'Không tìm thấy nhân viên nào.',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
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
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, email, sđt...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
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
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              initialValue: 0,
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

class _CurrentAccountView extends StatelessWidget {
  final User user;
  final String? errorMessage;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _CurrentAccountView({
    required this.user,
    required this.errorMessage,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InlineError(message: errorMessage!),
          ),
        Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      _avatarLetter(user.fullName),
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
                      Text(
                        user.roleName ?? _roleName(user.roleId),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Chỉnh sửa',
                  onPressed: () => _showEditProfileDialog(context, user),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Thông tin đăng nhập',
          children: [
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Mã tài khoản',
              value: '#${user.maTaiKhoan}',
            ),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Tên đăng nhập',
              value: user.tenDangNhap,
            ),
            _InfoRow(
              icon: Icons.verified_user_outlined,
              label: 'Quyền',
              value: user.roleName ?? _roleName(user.roleId),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Thông tin liên hệ',
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _emptyText(user.email),
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: _emptyText(user.soDienThoai),
            ),
            if (user.roleId == 4)
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ mặc định',
                value: _emptyText(user.diaChiMacDinh),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(context, user),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Cập nhật'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _avatarLetter(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.last[0].toUpperCase();
  }

  static String _roleName(int roleId) {
    switch (roleId) {
      case 1:
        return 'Admin';
      case 2:
        return 'Nhân viên bán hàng';
      case 3:
        return 'Nhân viên kho';
      default:
        return 'Khách hàng';
    }
  }

  static String _emptyText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Chưa cập nhật' : trimmed;
  }

  void _showEditProfileDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (_) => _EditCurrentAccountDialog(user: user),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
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

class _EditCurrentAccountDialog extends StatefulWidget {
  final User user;

  const _EditCurrentAccountDialog({required this.user});

  @override
  State<_EditCurrentAccountDialog> createState() =>
      _EditCurrentAccountDialogState();
}

class _EditCurrentAccountDialogState extends State<_EditCurrentAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _phoneController =
        TextEditingController(text: widget.user.soDienThoai ?? '');
    _addressController =
        TextEditingController(text: widget.user.diaChiMacDinh ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cập nhật hồ sơ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _field(
                controller: _fullNameController,
                label: 'Họ và tên',
                icon: Icons.person_outline,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập họ và tên'
                    : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Vui lòng nhập email';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) return null;
                  if (!RegExp(r'^\d{9,11}$').hasMatch(phone)) {
                    return 'Số điện thoại phải gồm 9-11 chữ số';
                  }
                  return null;
                },
              ),
              if (widget.user.roleId == 4) ...[
                const SizedBox(height: 12),
                _field(
                  controller: _addressController,
                  label: 'Địa chỉ mặc định',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final updated = await ApiService().updateUserProfile(
        maTaiKhoan: widget.user.maTaiKhoan,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        soDienThoai: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        diaChiMacDinh: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (!mounted) return;
      context.read<UserProvider>().updateUser(updated);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: const Color(0xFFEA580C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user.trangThai == 'Hoạt động';

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
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
                          size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(user.email,
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text('${user.chucVu} • ${user.tenQuyen}',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 13)),
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
                  activeThumbColor: const Color(0xFF2563EB),
                  activeTrackColor: const Color(0xFFEFF6FF),
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
                    color: isActive
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFEA580C),
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
