import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/promotion.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/admin/promotion_form_sheet.dart';

import '../../widgets/dashboard/dashboard_state_views.dart';
import '../../widgets/admin/admin_app_bar_title.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromotionProvider>().loadPromotions();
    });
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PromotionFormSheet(),
    );
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
          icon: Icons.local_offer_outlined,
          title: 'Khuyến mãi',
          subtitle: 'Quản lý chương trình giảm giá',
        ),
      ),
      body: Consumer<PromotionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.promotions.isEmpty) {
            return const DashboardLoadingView();
          }

          if (provider.errorMessage != null && provider.promotions.isEmpty) {
            return DashboardErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadPromotions,
            );
          }

          final list = provider.promotions;

          if (list.isEmpty && provider.filterStatus == 'Tất cả') {
            return DashboardErrorView(
              message: 'Chưa có chương trình khuyến mãi nào.',
              onRetry: provider.loadPromotions,
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: provider.loadPromotions,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InlineError(message: provider.errorMessage!),
                        ),
                      // --- Filter chips ---
                      _buildFilterChips(provider),
                      const SizedBox(height: 16),
                      // --- Promotion list ---
                      if (list.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.local_offer_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Không có khuyến mãi "${provider.filterStatus}"',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...list
                            .map((promo) => _PromotionCard(promotion: promo)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo khuyến mãi'),
      ),
    );
  }

  Widget _buildFilterChips(PromotionProvider provider) {
    const statuses = ['Tất cả', 'Đang diễn ra', 'Sắp diễn ra', 'Đã kết thúc'];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statuses.map((status) {
              final isSelected = provider.filterStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey[100],
                  side: BorderSide.none,
                  onSelected: (_) {
                    provider.setFilter(status);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// --- Card hiển thị từng chương trình khuyến mãi ---
class _PromotionCard extends StatelessWidget {
  final Promotion promotion;

  const _PromotionCard({required this.promotion});

  Color _statusColor(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return const Color(0xFF10B981);
      case 'Sắp diễn ra':
        return const Color(0xFF0EA5E9);
      case 'Đã kết thúc':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return Icons.check_circle;
      case 'Sắp diễn ra':
        return Icons.schedule;
      case 'Đã kết thúc':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _statusColor(promotion.trangThai);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: tên + badge trạng thái
            Row(
              children: [
                // Icon giảm giá
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '-${promotion.phanTramGiam}%',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tên
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.tenKM,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (promotion.moTa.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            promotion.moTa,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Badge trạng thái
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(promotion.trangThai),
                          size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        promotion.trangThai,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Divider
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),

            // Footer: thời gian + số sách
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${dateFormat.format(promotion.ngayBatDau)} - ${dateFormat.format(promotion.ngayKetThuc)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.menu_book_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${promotion.soSachApDung} sách',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
