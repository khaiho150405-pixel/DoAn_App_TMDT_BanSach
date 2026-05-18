import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/api_service.dart';
import '../../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final User user;
  
  const CheckoutScreen({super.key, required this.cartItems, required this.user});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = 'COD';
  bool _isProcessing = false;

  final Color primaryBlue = AppColors.primaryBlue;

  double get _totalPrice {
    double total = 0;
    for (var item in widget.cartItems) {
      total += item.sach.giaBanThucTe * item.soLuong;
    }
    return total;
  }
  


  String _fmt(double p) => p.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  void initState() {
    super.initState();
    // Khởi tạo thông tin khách hàng nếu có
    _phoneController.text = widget.user.soDienThoai ?? '';
    _addressController.text = widget.user.diaChiMacDinh ?? '';
  }

  void _datHang() async {
    if (_addressController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ địa chỉ và số điện thoại giao hàng'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isProcessing = true);
    
    try {
      final requestBody = {
        "maKH": widget.user.realId, // Lấy ID của Khách Hàng (realId map với Makh trong backend)
        "tenNguoiNhan": widget.user.fullName, // Hoặc lấy từ 1 controller nếu cho phép đổi tên
        "sdtNhan": _phoneController.text.trim(),
        "diaChiGiao": _addressController.text.trim(),
        "phuongThucThanhToan": _paymentMethod,
        "ghiChu": _noteController.text.trim(),
        "tongTien": _totalPrice,
        "items": widget.cartItems.map((item) => {
          "maSach": item.sach.maSach,
          "soLuong": item.soLuong,
          "donGia": item.sach.giaBanThucTe
        }).toList()
      };

      await Provider.of<OrderProvider>(context, listen: false).checkout(requestBody);
      
      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Xóa giỏ hàng sau khi mua (nếu là mua từ giỏ hàng)
        if (widget.cartItems.length > 1 || widget.cartItems.isNotEmpty) {
          Provider.of<CartProvider>(context, listen: false).clearCart();
        }

      showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          ),
          const SizedBox(height: 16),
          const Text('Đặt hàng thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Tổng thanh toán: ${_fmt(_totalPrice)} đ', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Đơn hàng của bạn đang chờ xác nhận', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { 
                Navigator.pop(ctx); 
                Navigator.of(context).popUntil((route) => route.isFirst); // Về trang chủ
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              child: const Text('Về trang chủ', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          )
        ],
      ));
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    }
  }
}

  @override
  void dispose() { 
    _addressController.dispose(); 
    _phoneController.dispose(); 
    _noteController.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white, 
        elevation: 0, 
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          // Danh sách sản phẩm
          Container(
            color: Colors.white, 
            margin: const EdgeInsets.only(top: 8), 
            padding: const EdgeInsets.symmetric(vertical: 8), 
            child: Column(
              children: widget.cartItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 60, height: 80,
                      child: CachedNetworkImage(imageUrl: '${ApiService.imageUrl}${item.sach.hinhAnh}', fit: BoxFit.cover,
                        errorWidget: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.book, color: Colors.grey))))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.sach.tenSach, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text('${_fmt(item.sach.giaBanThucTe)} đ', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Số lượng: ${item.soLuong}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ])),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Thông tin giao hàng
          Container(
            color: Colors.white, 
            padding: const EdgeInsets.all(16), 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text('Thông tin giao hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 16),
              _field('Họ và tên', widget.user.fullName, enabled: false),
              _field('Số điện thoại', 'Chưa có số điện thoại', controller: _phoneController, keyboardType: TextInputType.phone),
              _field('Địa chỉ giao hàng', 'Chưa có địa chỉ', controller: _addressController),
              _field('Ghi chú', 'Ghi chú cho đơn hàng...', controller: _noteController, maxLines: 2),
            ])
          ),
          const SizedBox(height: 8),
          // Phương thức thanh toán
          Container(
            color: Colors.white, 
            padding: const EdgeInsets.all(16), 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Icon(Icons.payment_outlined, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text('Phương thức thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                value: 'COD', groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!),
                title: const Text('Thanh toán khi nhận hàng (COD)', style: TextStyle(fontSize: 14)), 
                activeColor: primaryBlue, contentPadding: EdgeInsets.zero
              ),
              RadioListTile<String>(
                value: 'Banking', groupValue: _paymentMethod, onChanged: (v) => setState(() => _paymentMethod = v!),
                title: const Text('Chuyển khoản ngân hàng', style: TextStyle(fontSize: 14)), 
                activeColor: primaryBlue, contentPadding: EdgeInsets.zero
              ),
            ])
          ),
          const SizedBox(height: 8),
          // Tổng tiền
          Container(
            color: Colors.white, 
            padding: const EdgeInsets.all(16), 
            child: Column(children: [
              _priceRow('Tạm tính', _totalPrice),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tổng cộng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('${_fmt(_totalPrice)} đ', style: TextStyle(fontSize: 22, color: primaryBlue, fontWeight: FontWeight.bold)),
              ]),
            ])
          ),
          const SizedBox(height: 40),
        ]))),
        // Bottom Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _datHang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, 
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: _isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Đặt hàng  •  ${_fmt(_totalPrice)} đ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            )
          ),
        ),
      ]),
    );
  }

  Widget _field(String label, String hint, {TextEditingController? controller, bool enabled = true, TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), 
      child: TextField(
        controller: controller ?? TextEditingController(text: enabled ? null : hint),
        enabled: enabled, 
        keyboardType: keyboardType, 
        maxLines: maxLines,
        style: TextStyle(fontSize: 14, color: enabled ? Colors.black87 : Colors.grey[700]),
        decoration: InputDecoration(
          labelText: label, 
          hintText: hint, 
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryBlue)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
          filled: !enabled, 
          fillColor: enabled ? Colors.white : Colors.grey[100]
        ),
      )
    );
  }

  Widget _priceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(amount == 0 ? 'Miễn phí' : '${_fmt(amount)} đ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: amount == 0 ? Colors.green : Colors.black87)),
        ]
      )
    );
  }
}
