import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/api_service.dart';
import '../../providers/warehouse_provider.dart';
import '../../widgets/admin/admin_app_bar_title.dart';

class WarehouseAlertsScreen extends StatefulWidget {
  const WarehouseAlertsScreen({super.key});

  @override
  State<WarehouseAlertsScreen> createState() =>
      _WarehouseAlertsScreenState();
}

class _WarehouseAlertsScreenState extends State<WarehouseAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().loadAlerts();
    });
  }

  Color _alertColor(int stock) {
    if (stock == 0) return const Color(0xFFEF4444); // Red
    if (stock <= 5) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFF0EA5E9); // Blue
  }

  Color _alertBgColor(int stock) {
    if (stock == 0) return const Color(0xFFFEE2E2);
    if (stock <= 5) return const Color(0xFFFFF7ED);
    return const Color(0xFFE0F2FE);
  }

  IconData _alertIcon(int stock) {
    if (stock == 0) return Icons.error_outline;
    if (stock <= 5) return Icons.warning_amber;
    return Icons.info_outline;
  }

  String _alertLabel(int stock) {
    if (stock == 0) return 'HẾT HÀNG';
    if (stock <= 5) return 'SẮP HẾT';
    return 'TỒN THẤP';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleSpacing: 12,
        title: const AdminAppBarTitle(
          icon: Icons.warning_amber_rounded,
          title: 'Cảnh báo tồn kho',
          subtitle: 'Sách cần nhập thêm hàng',
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune, color: Color(0xFF2563EB)),
            tooltip: 'Ngưỡng cảnh báo',
            onSelected: (threshold) {
              context.read<WarehouseProvider>().setAlertThreshold(threshold);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 5, child: Text('Tồn ≤ 5')),
              const PopupMenuItem(value: 10, child: Text('Tồn ≤ 10')),
              const PopupMenuItem(value: 20, child: Text('Tồn ≤ 20')),
              const PopupMenuItem(value: 50, child: Text('Tồn ≤ 50')),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, child) {
          if (provider.isAlertsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.alertsError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(provider.alertsError!,
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.loadAlerts(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final alerts = provider.alerts;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tồn kho ổn định!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Không có sách nào tồn ≤ ${provider.alertThreshold}',
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () => provider.loadAlerts(),
            child: Column(
              children: [
                // Summary bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list,
                          size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      Text(
                        'Ngưỡng: tồn ≤ ${provider.alertThreshold}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${alerts.length} sách',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final book = alerts[index];
                      final stock = book['soluongton'] ?? 0;
                      final color = _alertColor(stock as int);
                      final bgColor = _alertBgColor(stock);
                      final icon = _alertIcon(stock);
                      final label = _alertLabel(stock);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Book Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 50,
                                  height: 65,
                                  color: const Color(0xFFF3F4F6),
                                  child: Image.network(
                                    '${ApiService.imageUrl}${book['hinhanh'] ?? 'default_book.jpg'}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.menu_book,
                                            color: Color(0xFF9CA3AF),
                                            size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book['tensach'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${book['tenTheLoai'] ?? ''} • ${book['tenTacGia'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9CA3AF)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Alert badge
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(icon,
                                        color: color, size: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    'Tồn: $stock',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: color),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
