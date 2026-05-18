import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/api_service.dart';
import '../../theme/app_theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final order = await Provider.of<OrderProvider>(context, listen: false)
        .loadOrderDetail(widget.orderId);
    
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  String _fmt(double p) => p.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận': return Colors.orange;
      case 'Đang chuẩn bị hàng': return Colors.blue;
      case 'Đang giao': return Colors.indigo;
      case 'Đã giao': return Colors.green;
      case 'Đã hủy': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _order == null 
          ? const Center(child: Text('Không tìm thấy thông tin đơn hàng'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trạng thái đơn hàng
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_order!.trangThaiDonHang).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _order!.trangThaiDonHang,
                          style: TextStyle(
                            color: _getStatusColor(_order!.trangThaiDonHang),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Mã đơn hàng: #${_order!.maDH}', style: const TextStyle(color: Colors.black87)),
                        Text('Ngày đặt: ${_order!.ngayDat.day}/${_order!.ngayDat.month}/${_order!.ngayDat.year} ${_order!.ngayDat.hour}:${_order!.ngayDat.minute}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thông tin người nhận
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            const Text('Địa chỉ nhận hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(_order!.tenNguoiNhan, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_order!.sdtNhan, style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        Text(_order!.diaChiGiao, style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách sản phẩm
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            const Text('Sản phẩm đã mua', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 24),
                        ..._order!.chiTiet.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 60, height: 80,
                                    child: CachedNetworkImage(
                                      imageUrl: '${ApiService.imageUrl}${item.hinhAnh}',
                                      fit: BoxFit.cover,
                                      errorWidget: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.tenSach, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${_fmt(item.donGia)} đ x ${item.soLuong}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                          Text('${_fmt(item.thanhTien)} đ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thanh toán
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payment_outlined, color: AppColors.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            const Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Phương thức:', style: TextStyle(color: Colors.grey[600])),
                            Text(_order!.phuongThucThanhToan, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tình trạng:', style: TextStyle(color: Colors.grey[600])),
                            Text(_order!.trangThaiThanhToan, style: TextStyle(fontWeight: FontWeight.bold, color: _order!.trangThaiThanhToan == 'Đã thanh toán' ? Colors.green : Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tạm tính:', style: TextStyle(color: Colors.grey[600])),
                            Text('${_fmt(_order!.tongTien)} đ', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Phí vận chuyển:', style: TextStyle(color: Colors.grey[600])),
                            const Text('Miễn phí', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${_fmt(_order!.tongTien)} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryBlue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
