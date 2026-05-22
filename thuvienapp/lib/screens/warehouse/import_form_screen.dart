import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/api_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/warehouse_provider.dart';

class ImportFormScreen extends StatefulWidget {
  const ImportFormScreen({super.key});

  @override
  State<ImportFormScreen> createState() => _ImportFormScreenState();
}

class _ImportFormScreenState extends State<ImportFormScreen> {
  final _ghiChuCtrl = TextEditingController();
  final List<_ImportItem> _items = [];
  bool _isSubmitting = false;

  // Inventory list for book selection
  List<Map<String, dynamic>> _bookList = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await ApiService().fetchInventory();
    if (mounted) {
      setState(() => _bookList = books);
    }
  }

  @override
  void dispose() {
    _ghiChuCtrl.dispose();
    for (final item in _items) {
      item.soLuongCtrl.dispose();
      item.giaNhapCtrl.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_ImportItem(
        soLuongCtrl: TextEditingController(text: '1'),
        giaNhapCtrl: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].soLuongCtrl.dispose();
      _items[index].giaNhapCtrl.dispose();
      _items.removeAt(index);
    });
  }

  double get _totalAmount {
    double total = 0;
    for (final item in _items) {
      final qty = int.tryParse(item.soLuongCtrl.text) ?? 0;
      final price = double.tryParse(item.giaNhapCtrl.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 mục nhập'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Validate all items have book selected
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].maSach == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng chọn sách cho mục ${i + 1}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    final currentUser = context.read<UserProvider>().user;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'maNv': currentUser.realId,
        'ghiChu': _ghiChuCtrl.text.trim(),
        'chiTiet': _items
            .map((item) => {
                  'maSach': item.maSach,
                  'soLuong': int.tryParse(item.soLuongCtrl.text) ?? 0,
                  'giaNhap': double.tryParse(item.giaNhapCtrl.text) ?? 0,
                })
            .toList(),
      };

      final result = await ApiService().createImportReceipt(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Tạo phiếu nhập thành công'),
          backgroundColor: result['success'] == true
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
        ),
      );

      if (result['success'] == true) {
        // Refresh inventory
        context.read<WarehouseProvider>().loadInventory();
        context.read<WarehouseProvider>().loadDashboard();
        Navigator.pop(context, true);
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
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: const Text(
          'Tạo phiếu nhập mới',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ghi chú
                  const Text('Ghi chú',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ghiChuCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập ghi chú (tuỳ chọn)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Danh sách sách nhập',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm mục',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 40, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('Chưa có mục nào',
                              style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text(
                              'Nhấn "Thêm mục" để bắt đầu',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    ),

                  // Item cards
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mục ${index + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              InkWell(
                                onTap: () => _removeItem(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16,
                                      color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Book dropdown
                          DropdownButtonFormField<int>(
                            value: item.maSach,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Chọn sách',
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                            items: _bookList
                                .map((b) => DropdownMenuItem<int>(
                                      value: b['masach'] as int,
                                      child: Text(
                                        b['tensach'] ?? '',
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() => item.maSach = v);
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Số lượng',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Color(0xFF6B7280))),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: item.soLuongCtrl,
                                      keyboardType:
                                          TextInputType.number,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 12,
                                                vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                        ),
                                      ),
                                      onChanged: (_) =>
                                          setState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Giá nhập (đ)',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Color(0xFF6B7280))),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: item.giaNhapCtrl,
                                      keyboardType:
                                          TextInputType.number,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 12,
                                                vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                        ),
                                      ),
                                      onChanged: (_) =>
                                          setState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom bar with total + submit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền nhập:',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(
                      currencyFormat.format(_totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
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
                        : const Text(
                            'XÁC NHẬN NHẬP KHO',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportItem {
  int? maSach;
  final TextEditingController soLuongCtrl;
  final TextEditingController giaNhapCtrl;

  _ImportItem({
    this.maSach,
    required this.soLuongCtrl,
    required this.giaNhapCtrl,
  });
}
