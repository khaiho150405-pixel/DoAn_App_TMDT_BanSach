import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/promotion_provider.dart';

class PromotionFormSheet extends StatefulWidget {
  const PromotionFormSheet({super.key});

  @override
  State<PromotionFormSheet> createState() => _PromotionFormSheetState();
}

class _PromotionFormSheetState extends State<PromotionFormSheet> {
  final _formKey = GlobalKey<FormState>();

  String _tenKM = '';
  String _moTa = '';
  int _phanTramGiam = 10;
  DateTime _ngayBatDau = DateTime.now();
  DateTime _ngayKetThuc = DateTime.now().add(const Duration(days: 7));

  bool _isSubmitting = false;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _ngayBatDau : _ngayKetThuc;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _ngayBatDau = picked;
          // Tự động điều chỉnh ngày kết thúc nếu < ngày bắt đầu
          if (_ngayKetThuc.isBefore(_ngayBatDau)) {
            _ngayKetThuc = _ngayBatDau.add(const Duration(days: 1));
          }
        } else {
          _ngayKetThuc = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_ngayBatDau.isAfter(_ngayKetThuc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày bắt đầu phải trước ngày kết thúc!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'tenKM': _tenKM,
        'moTa': _moTa,
        'phanTramGiam': _phanTramGiam,
        'ngayBatDau': _ngayBatDau.toIso8601String(),
        'ngayKetThuc': _ngayKetThuc.toIso8601String(),
      };

      await context.read<PromotionProvider>().addPromotion(data);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo khuyến mãi thành công!')),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                const Text(
                  'Tạo chương trình khuyến mãi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 20),

                // Tên KM
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Tên chương trình',
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Vui lòng nhập tên khuyến mãi' : null,
                  onSaved: (v) => _tenKM = v!,
                ),
                const SizedBox(height: 14),

                // Mô tả
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 2,
                  onSaved: (v) => _moTa = v ?? '',
                ),
                const SizedBox(height: 14),

                // Phần trăm giảm
                TextFormField(
                  initialValue: _phanTramGiam.toString(),
                  decoration: InputDecoration(
                    labelText: 'Phần trăm giảm (%)',
                    prefixIcon: const Icon(Icons.percent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập % giảm';
                    final n = int.tryParse(v);
                    if (n == null || n < 1 || n > 100) {
                      return 'Giá trị từ 1 đến 100';
                    }
                    return null;
                  },
                  onSaved: (v) => _phanTramGiam = int.parse(v!),
                ),
                const SizedBox(height: 14),

                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'Ngày bắt đầu',
                        date: _ngayBatDau,
                        dateFormat: _dateFormat,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerField(
                        label: 'Ngày kết thúc',
                        date: _ngayKetThuc,
                        dateFormat: _dateFormat,
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Tạo khuyến mãi',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
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

// --- Widget phụ: Date Picker Field ---
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Text(
          dateFormat.format(date),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
