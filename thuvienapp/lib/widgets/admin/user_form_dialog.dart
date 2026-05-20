import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_user_provider.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String _tenDangNhap = '';
  String _matKhau = '';
  int _maQuyen = 2; // Bán hàng
  String _hoVaTen = '';
  String _sdt = '';
  String _email = '';
  String _chucVu = 'Nhân viên bán hàng';

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      final userData = {
        'tenDangNhap': _tenDangNhap,
        'matKhau': _matKhau,
        'email': _email,
        'maQuyen': _maQuyen,
        'hoVaTen': _hoVaTen,
        'sdt': _sdt,
        'chucVu': _chucVu,
      };

      await context.read<AdminUserProvider>().addUser(userData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm nhân viên thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thêm nhân viên mới',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Thông tin tài khoản
                const Text('Thông tin tài khoản',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.blue)),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập', border: OutlineInputBorder()),
                  validator: (v) =>
                      v!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                  onSaved: (v) => _tenDangNhap = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Mật khẩu', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) =>
                      v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                  onSaved: (v) => _matKhau = v!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                      labelText: 'Quyền', border: OutlineInputBorder()),
                  value: _maQuyen,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Admin')),
                    DropdownMenuItem(value: 2, child: Text('Bán hàng')),
                    DropdownMenuItem(value: 3, child: Text('Kho')),
                  ],
                  onChanged: (v) => setState(() => _maQuyen = v!),
                ),
                const SizedBox(height: 20),

                // Thông tin nhân viên
                const Text('Thông tin nhân viên',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.blue)),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Họ và tên', border: OutlineInputBorder()),
                  validator: (v) =>
                      v!.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                  onSaved: (v) => _hoVaTen = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập email' : null,
                  onSaved: (v) => _email = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Số điện thoại', border: OutlineInputBorder()),
                  onSaved: (v) => _sdt = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _chucVu,
                  decoration: const InputDecoration(
                      labelText: 'Chức vụ', border: OutlineInputBorder()),
                  onSaved: (v) => _chucVu = v ?? '',
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Hủy',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
