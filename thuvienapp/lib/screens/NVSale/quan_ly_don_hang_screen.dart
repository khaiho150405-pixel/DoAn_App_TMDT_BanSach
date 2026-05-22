import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/api_service.dart';
import '../../providers/user_provider.dart';

class QuanLyDonHangScreen extends StatefulWidget {
  const QuanLyDonHangScreen({super.key});
  @override
  State<QuanLyDonHangScreen> createState() => _QuanLyDonHangScreenState();
}

class _QuanLyDonHangScreenState extends State<QuanLyDonHangScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  final List<String> _statuses = [
    'Chờ xác nhận',
    'Đang chuẩn bị hàng',
    'Đang giao',
    'Hoàn thành',
    'Đã hủy'
  ];
  final List<IconData> _tabIcons = [
    Icons.pending_actions,
    Icons.inventory_2,
    Icons.local_shipping,
    Icons.check_circle,
    Icons.cancel
  ];
  final List<Color> _tabColors = [
    const Color(0xFF4A90D9),
    const Color(0xFFE8913A),
    const Color(0xFF8E44AD),
    const Color(0xFF27AE60),
    Colors.redAccent
  ];

  Map<String, List<Map<String, dynamic>>> _ordersMap = {};
  Map<String, bool> _loadingMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    for (var s in _statuses) {
      _ordersMap[s] = [];
      _loadingMap[s] = true;
    }
    _loadOrders(_statuses[0]);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadOrders(_statuses[_tabController.index]);
      }
    });
  }

  Future<void> _loadOrders(String status) async {
    setState(() => _loadingMap[status] = true);
    final orders = await _api.fetchOrdersByStatus(status);
    if (mounted)
      setState(() {
        _ordersMap[status] = orders;
        _loadingMap[status] = false;
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Xử lý Đơn Hàng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: List.generate(
              _statuses.length,
              (i) => Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_tabIcons[i], size: 18),
                      const SizedBox(width: 6),
                      Text(_statuses[i]),
                    ]),
                  )),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) => _buildOrderList(status)).toList(),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final isLoading = _loadingMap[status] ?? true;
    final orders = _ordersMap[status] ?? [];

    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (orders.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Không có đơn hàng nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(status),
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => _buildOrderCard(orders[i], status),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String currentStatus) {
    final maDH = order['madh'] ?? 0;
    final tenNguoiNhan = order['tennguoinhan'] ?? 'N/A';
    final sdtNhan = order['sdtnhan'] ?? '';
    final diaChi = order['diachigiao'] ?? '';
    final tongTien = (order['tongtien'] ?? 0).toDouble();
    final ngayDat = order['ngaydat'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(order['ngaydat']))
        : 'N/A';
    final ttThanhToan = order['trangthaithanhtoan'] ?? '';
    final ghiChu = order['ghichu'] ?? '';
    final statusIdx = _statuses.indexOf(currentStatus);
    final statusColor = statusIdx >= 0 ? _tabColors[statusIdx] : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(Icons.receipt_long_rounded, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Text('Đơn #$maDH',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: statusColor)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(currentStatus,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _infoRow(Icons.person_outline, tenNguoiNhan, subtitle: sdtNhan),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on_outlined, diaChi),
            const SizedBox(height: 8),
            _infoRow(Icons.calendar_today_outlined, ngayDat),
            if (ghiChu.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.note_alt_outlined, ghiChu)
            ],
            const Divider(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ttThanhToan == 'Đã thanh toán'
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ttThanhToan,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ttThanhToan == 'Đã thanh toán'
                            ? Colors.green.shade700
                            : Colors.orange.shade700)),
              ),
              const Spacer(),
              Text(currencyFormat.format(tongTien),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB))),
            ]),
          ]),
        ),
        // Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16)),
          ),
          child: Row(children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Chi tiết'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A90D9),
                  side: const BorderSide(color: Color(0xFF4A90D9)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
              onPressed: () => _showOrderDetail(maDH),
            ),
            const Spacer(),
            if (currentStatus == 'Chờ xác nhận') ...[
              _actionBtn(
                icon: Icons.cancel_outlined,
                label: 'Hủy đơn',
                color: Colors.redAccent,
                onPressed: () => _changeStatus(
                    maDH, 'Đã hủy', tenNguoiNhan, tongTien),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                icon: Icons.check_circle_outline,
                label: 'Xác nhận',
                color: const Color(0xFF27AE60),
                onPressed: () => _changeStatus(
                    maDH, 'Đang chuẩn bị hàng', tenNguoiNhan, tongTien),
              ),
            ],
            if (currentStatus == 'Đang chuẩn bị hàng')
              _actionBtn(
                icon: Icons.local_shipping_outlined,
                label: 'Giao hàng',
                color: const Color(0xFF8E44AD),
                onPressed: () => _changeStatus(
                    maDH, 'Đang giao', tenNguoiNhan, tongTien),
              ),
            if (currentStatus == 'Đang giao')
              _actionBtn(
                icon: Icons.done_all_rounded,
                label: 'Hoàn thành',
                color: const Color(0xFF27AE60),
                onPressed: () => _changeStatus(
                    maDH, 'Hoàn thành', tenNguoiNhan, tongTien),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
    );
  }

  Widget _infoRow(IconData icon, String text, {String? subtitle}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Colors.grey.shade500),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2D3436))),
        if (subtitle != null && subtitle.isNotEmpty)
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ])),
    ]);
  }

  Future<void> _changeStatus(
      int maDH, String newStatus, String tenKH, double tongTien) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final isCancel = newStatus == 'Đã hủy';
    final statusColor = isCancel ? Colors.redAccent : const Color(0xFF2563EB);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCancel ? Icons.cancel_outlined : Icons.swap_horiz_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(isCancel ? 'Hủy đơn hàng' : 'Xác nhận chuyển trạng thái',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đơn #$maDH',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Khách: $tenKH',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                  Text(
                      'Tổng tiền: ${currencyFormat.format(tongTien)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isCancel
                  ? 'Bạn có chắc muốn hủy đơn hàng này? Tồn kho sẽ được hoàn lại.'
                  : 'Chuyển trạng thái sang "$newStatus"?',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: statusColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isCancel ? 'Hủy đơn' : 'Xác nhận'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result =
        await _api.updateOrderStatus(maDH, newStatus, user?.realId ?? 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Đã cập nhật'),
          backgroundColor: isCancel ? Colors.red : Colors.green));
      for (var s in _statuses) {
        _loadOrders(s);
      }
    }
  }

  Future<void> _showOrderDetail(int maDH) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB))));
    final detail = await _api.fetchOrderDetail(maDH);
    if (mounted) Navigator.pop(context); // close loading

    if (detail == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không tải được chi tiết đơn hàng'),
            backgroundColor: Colors.red));
      return;
    }

    final products = detail['danhSachSanPham'] as List<dynamic>? ?? [];

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const Icon(Icons.shopping_bag_rounded,
                    color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Text('Chi tiết đơn hàng #$maDH',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('Không có sản phẩm'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (ctx, i) {
                        final p = products[i];
                        return Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                                '${ApiService.imageUrl}${p['hinhAnh'] ?? 'default_book.jpg'}',
                                width: 55,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 55,
                                    height: 70,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.book,
                                        color: Colors.grey))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(p['tenSach'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(
                                    'SL: ${p['soluong']} × ${currencyFormat.format((p['dongia'] ?? 0).toDouble())}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ])),
                          Text(
                              currencyFormat
                                  .format((p['thanhTien'] ?? 0).toDouble()),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB))),
                        ]);
                      },
                    ),
            ),
          ]),
        ),
      );
    }
  }
}
