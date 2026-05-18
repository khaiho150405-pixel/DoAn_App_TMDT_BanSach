import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user.dart';
import '../../providers/cart_provider.dart';
import '../../providers/api_service.dart';
import '../login_screen.dart';
import 'checkout_screen.dart';
import '../../theme/app_theme.dart';

class GioHangScreen extends StatelessWidget {
  final User? user; // Guest có thể là null
  const GioHangScreen({super.key, this.user});

  final Color primaryBlue = AppColors.primaryBlue;

  String _fmt(double p) => p.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  void _checkout(BuildContext context, CartProvider cart) {
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    
    // Nếu có user, tiếp tục thanh toán
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        cartItems: cart.items,
        user: user!,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Giỏ hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Giỏ hàng trống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Hãy thêm sách vào giỏ hàng để mua nhé!', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Dismissible(
                      key: Key('cart_${item.sach.maSach}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.delete, color: Colors.white, size: 28),
                      ),
                      onDismissed: (direction) {
                        cart.removeItem(item.sach.maSach);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryBlue.withOpacity(0.1)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 70, height: 95,
                                child: CachedNetworkImage(
                                  imageUrl: '${ApiService.imageUrl}${item.sach.hinhAnh}',
                                  fit: BoxFit.cover,
                                  errorWidget: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.book, color: Colors.grey)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(item.sach.tenSach, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => cart.removeItem(item.sach.maSach),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${_fmt(item.sach.giaBanThucTe)} đ', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => cart.decreaseQuantity(item.sach.maSach),
                                              child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.remove, size: 16, color: Colors.grey[700])),
                                            ),
                                            Container(width: 30, alignment: Alignment.center, child: Text('${item.soLuong}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                            InkWell(
                                              onTap: () => cart.addItem(item.sach),
                                              child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.add, size: 16, color: Colors.grey[700])),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text('=${_fmt(item.sach.giaBanThucTe * item.soLuong)} đ', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tổng tiền & nút đặt hàng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng cộng:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          Text('${_fmt(cart.totalAmount)} đ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue)),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _checkout(context, cart),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
