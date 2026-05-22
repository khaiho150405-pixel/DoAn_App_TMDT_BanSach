import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../providers/api_service.dart';
import '../../providers/warehouse_provider.dart';

class BookFormScreen extends StatefulWidget {
  /// If [book] is provided, we're editing; otherwise we're creating.
  final Map<String, dynamic>? book;

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenSachCtrl = TextEditingController();
  final _giaBanCtrl = TextEditingController();
  final _soLuongCtrl = TextEditingController();
  final _moTaCtrl = TextEditingController();
  final _hinhAnhCtrl = TextEditingController();

  int? _selectedTacGia;
  int? _selectedNxb;
  int? _selectedTheLoai;
  bool _isSubmitting = false;

  bool get isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().loadLookupData();
    });

    if (isEditing) {
      final b = widget.book!;
      _tenSachCtrl.text = b['tensach'] ?? '';
      _giaBanCtrl.text = (b['giaban'] ?? 0).toString();
      _soLuongCtrl.text = (b['soluongton'] ?? 0).toString();
      _moTaCtrl.text = b['mota'] ?? '';
      _hinhAnhCtrl.text = b['hinhanh'] ?? '';
      _selectedTacGia = b['matg'];
      _selectedNxb = b['manxb'];
      _selectedTheLoai = b['matheloai'];
    }
  }

  @override
  void dispose() {
    _tenSachCtrl.dispose();
    _giaBanCtrl.dispose();
    _soLuongCtrl.dispose();
    _moTaCtrl.dispose();
    _hinhAnhCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTacGia == null ||
        _selectedNxb == null ||
        _selectedTheLoai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Tác giả, NXB và Thể loại'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (isEditing) {
        // UPDATE
        final data = {
          'tenSach': _tenSachCtrl.text.trim(),
          'giaBan': double.tryParse(_giaBanCtrl.text) ?? 0,
          'moTa': _moTaCtrl.text.trim(),
          'maTheLoai': _selectedTheLoai,
          'maTg': _selectedTacGia,
          'maNxb': _selectedNxb,
          if (_hinhAnhCtrl.text.trim().isNotEmpty)
            'hinhAnh': _hinhAnhCtrl.text.trim(),
        };
        final result = await ApiService()
            .updateBook(widget.book!['masach'] as int, data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Cập nhật thành công'),
            backgroundColor: result['success'] == true
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        );
        if (result['success'] == true) Navigator.pop(context, true);
      } else {
        // CREATE (sử dụng multipart/form-data cho ThemSach endpoint)
        final uri =
            Uri.parse('${ApiService.baseUrl}/Sach/ThemSach');
        final request = http.MultipartRequest('POST', uri);
        request.fields['TenSach'] = _tenSachCtrl.text.trim();
        request.fields['Matg'] = _selectedTacGia.toString();
        request.fields['Manxb'] = _selectedNxb.toString();
        request.fields['Matheloai'] = _selectedTheLoai.toString();
        request.fields['GiaBán'] = _giaBanCtrl.text.trim();
        request.fields['SoLuongTon'] = _soLuongCtrl.text.trim();
        request.fields['Mota'] = _moTaCtrl.text.trim();
        // Image URL as field (no file upload for simplicity)

        final response = await request.send();
        final respBody = await response.stream.bytesToString();
        final result = json.decode(respBody);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Thêm sách thành công'),
            backgroundColor: response.statusCode == 200
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        );
        if (response.statusCode == 200) Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: Text(
          isEditing ? 'Sửa thông tin sách' : 'Thêm sách mới',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sách
                  _buildSectionLabel('Tên sách *'),
                  TextFormField(
                    controller: _tenSachCtrl,
                    decoration: _inputDecoration('Nhập tên sách'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Tên sách là bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),

                  // Tác giả dropdown
                  _buildSectionLabel('Tác giả *'),
                  DropdownButtonFormField<int>(
                    value: _selectedTacGia,
                    decoration: _inputDecoration('Chọn tác giả'),
                    items: provider.authors
                        .map((a) => DropdownMenuItem<int>(
                              value: a['matg'] as int,
                              child: Text(a['tentg'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTacGia = v),
                  ),
                  const SizedBox(height: 16),

                  // NXB dropdown
                  _buildSectionLabel('Nhà xuất bản *'),
                  DropdownButtonFormField<int>(
                    value: _selectedNxb,
                    decoration: _inputDecoration('Chọn NXB'),
                    items: provider.publishers
                        .map((p) => DropdownMenuItem<int>(
                              value: p['manxb'] as int,
                              child: Text(p['tennxb'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedNxb = v),
                  ),
                  const SizedBox(height: 16),

                  // Thể loại dropdown
                  _buildSectionLabel('Thể loại *'),
                  DropdownButtonFormField<int>(
                    value: _selectedTheLoai,
                    decoration: _inputDecoration('Chọn thể loại'),
                    items: provider.categories
                        .map((c) => DropdownMenuItem<int>(
                              value: c['matheloai'] as int,
                              child: Text(c['tentheloai'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedTheLoai = v),
                  ),
                  const SizedBox(height: 16),

                  // Giá bán
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Giá bán (đ) *'),
                            TextFormField(
                              controller: _giaBanCtrl,
                              decoration: _inputDecoration('0'),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Nhập giá bán';
                                }
                                final price = double.tryParse(v);
                                if (price == null || price < 0) {
                                  return 'Giá phải >= 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(
                                isEditing ? 'Tồn kho (không đổi)' : 'Số lượng tồn *'),
                            TextFormField(
                              controller: _soLuongCtrl,
                              decoration: _inputDecoration('0'),
                              keyboardType: TextInputType.number,
                              enabled: !isEditing,
                              validator: isEditing
                                  ? null
                                  : (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Nhập số lượng';
                                      }
                                      final qty = int.tryParse(v);
                                      if (qty == null || qty < 0) {
                                        return 'Số lượng >= 0';
                                      }
                                      return null;
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hình ảnh
                  _buildSectionLabel('Tên file hình ảnh'),
                  TextFormField(
                    controller: _hinhAnhCtrl,
                    decoration:
                        _inputDecoration('vd: clean_code.jpg'),
                  ),
                  const SizedBox(height: 16),

                  // Mô tả
                  _buildSectionLabel('Mô tả'),
                  TextFormField(
                    controller: _moTaCtrl,
                    decoration: _inputDecoration('Nhập mô tả sách...'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isEditing ? 'CẬP NHẬT' : 'THÊM SÁCH',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }
}
