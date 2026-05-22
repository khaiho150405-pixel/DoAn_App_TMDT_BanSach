import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/api_service.dart';
import '../providers/user_provider.dart';

/// Widget dùng chung cho phần "Cài đặt chung" trên tất cả role.
/// Bao gồm: đổi mật khẩu, chế độ tối, ngôn ngữ, phiên bản.
class CommonSettingsSection extends StatefulWidget {
  const CommonSettingsSection({super.key});

  @override
  State<CommonSettingsSection> createState() => _CommonSettingsSectionState();
}

class _CommonSettingsSectionState extends State<CommonSettingsSection> {
  bool _isDarkMode = false;

  // =========================================================
  // ĐỔI MẬT KHẨU
  // =========================================================
  void _showChangePasswordDialog() {
    final currentUser = context.read<UserProvider>().user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String oldPw = '', newPw = '';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_outline,
                                color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu hiện tại',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
                        onSaved: (v) => oldPw = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock_reset),
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vui lòng nhập mật khẩu mới';
                          }
                          if (v.length < 6) return 'Tối thiểu 6 ký tự';
                          return null;
                        },
                        onChanged: (v) => newPw = v,
                        onSaved: (v) => newPw = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu mới',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock_reset),
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (v != newPw) {
                            return 'Mật khẩu xác nhận không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      formKey.currentState!.save();
                                      setDialogState(
                                          () => isSubmitting = true);

                                      try {
                                        await ApiService().changePassword(
                                            currentUser.maTaiKhoan,
                                            oldPw,
                                            newPw);
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Đổi mật khẩu thành công!')),
                                          );
                                        }
                                      } catch (e) {
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text(e.toString()),
                                                backgroundColor:
                                                    const Color(
                                                        0xFFEA580C)),
                                          );
                                        }
                                      } finally {
                                        if (ctx.mounted) {
                                          setDialogState(
                                              () => isSubmitting = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Text('Xác nhận'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'CÀI ĐẶT CHUNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Settings Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              // Đổi mật khẩu
              _buildSettingsTile(
                icon: Icons.lock_outline,
                iconColor: const Color(0xFF2563EB),
                title: 'Đổi mật khẩu',
                subtitle: 'Cập nhật mật khẩu tài khoản',
                onTap: _showChangePasswordDialog,
              ),
              const Divider(height: 1, indent: 60),

              // Chế độ tối
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Chế độ tối',
                subtitle: _isDarkMode ? 'Đang bật' : 'Đang tắt',
                trailing: Switch(
                  value: _isDarkMode,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    setState(() => _isDarkMode = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val
                            ? 'Chế độ tối đã bật'
                            : 'Chế độ tối đã tắt'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1, indent: 60),

              // Ngôn ngữ
              _buildSettingsTile(
                icon: Icons.language,
                iconColor: const Color(0xFF10B981),
                title: 'Ngôn ngữ',
                subtitle: 'Tiếng Việt',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Hiện chỉ hỗ trợ Tiếng Việt')),
                  );
                },
              ),
              const Divider(height: 1, indent: 60),

              // Phiên bản
              _buildSettingsTile(
                icon: Icons.info_outline,
                iconColor: const Color(0xFF0EA5E9),
                title: 'Phiên bản ứng dụng',
                subtitle: 'E-BookStore v1.0.0',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF))
              : null),
      onTap: onTap,
    );
  }
}
