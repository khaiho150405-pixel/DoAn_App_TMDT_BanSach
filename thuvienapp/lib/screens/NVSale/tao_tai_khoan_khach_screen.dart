import 'package:flutter/material.dart';
import '../../providers/api_service.dart';

class TaoTaiKhoanKhachScreen extends StatefulWidget {
  const TaoTaiKhoanKhachScreen({super.key});
  @override
  State<TaoTaiKhoanKhachScreen> createState() => _TaoTaiKhoanKhachScreenState();
}

class _TaoTaiKhoanKhachScreenState extends State<TaoTaiKhoanKhachScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _hoVaTenCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _tenDangNhapCtrl = TextEditingController();
  final _matKhauCtrl = TextEditingController();
  final _diaChiCtrl = TextEditingController();

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _api.registerAccount(
      tenDangNhap: _tenDangNhapCtrl.text.trim(),
      matKhau: _matKhauCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      hoVaTen: _hoVaTenCtrl.text.trim(),
      sdt: _sdtCtrl.text.trim().isEmpty ? null : _sdtCtrl.text.trim(),
      diaChiMacDinh:
          _diaChiCtrl.text.trim().isEmpty ? null : _diaChiCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        _showSuccessDialog();
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Đăng ký thất bại'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _hoVaTenCtrl.clear();
    _sdtCtrl.clear();
    _emailCtrl.clear();
    _tenDangNhapCtrl.clear();
    _matKhauCtrl.clear();
    _diaChiCtrl.clear();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded,
                size: 64, color: Colors.green.shade600),
          ),
          const SizedBox(height: 20),
          const Text('Tạo tài khoản thành công!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Khách hàng có thể đăng nhập ngay bây giờ.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Mở Tài Khoản Khách',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2563EB).withOpacity(0.08),
                    Colors.transparent
                  ]),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E44AD).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 50, color: Color(0xFF8E44AD)),
              ),
              const SizedBox(height: 12),
              const Text('Tạo tài khoản mới cho khách hàng',
                  style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF636E72),
                      fontWeight: FontWeight.w500)),
            ]),
          ),
          // Form
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _buildField(_hoVaTenCtrl, 'Họ và tên khách hàng *',
                    Icons.person_outline_rounded,
                    validator: (v) =>
                        v!.isEmpty ? 'Vui lòng nhập họ tên' : null),
                const SizedBox(height: 14),
                _buildField(_sdtCtrl, 'Số điện thoại', Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildField(_emailCtrl, 'Email *', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress, validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                  if (!v.contains('@')) return 'Email không hợp lệ';
                  return null;
                }),
                const SizedBox(height: 14),
                _buildField(_diaChiCtrl, 'Địa chỉ mặc định',
                    Icons.location_on_outlined),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90D9).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF4A90D9).withOpacity(0.2)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 18,
                              color: const Color(0xFF4A90D9).withOpacity(0.8)),
                          const SizedBox(width: 8),
                          const Text('Thông tin đăng nhập',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A90D9))),
                        ]),
                        const SizedBox(height: 14),
                        _buildField(_tenDangNhapCtrl, 'Tên đăng nhập *',
                            Icons.login_rounded,
                            validator: (v) => v!.isEmpty
                                ? 'Vui lòng nhập tên đăng nhập'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _matKhauCtrl,
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Vui lòng nhập mật khẩu';
                            if (v.length < 3)
                              return 'Mật khẩu tối thiểu 3 ký tự';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu khởi tạo *',
                            prefixIcon: const Icon(Icons.lock_rounded,
                                color: Color(0xFF2563EB)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2563EB), width: 2)),
                          ),
                        ),
                      ]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(
                        _isLoading ? 'ĐANG XỬ LÝ...' : 'TẠO TÀI KHOẢN MỚI',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E44AD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: const Color(0xFF8E44AD).withOpacity(0.4),
                    ),
                    onPressed: _isLoading ? null : _createAccount,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
    );
  }

  @override
  void dispose() {
    _hoVaTenCtrl.dispose();
    _sdtCtrl.dispose();
    _emailCtrl.dispose();
    _tenDangNhapCtrl.dispose();
    _matKhauCtrl.dispose();
    _diaChiCtrl.dispose();
    super.dispose();
  }
}
