import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/dashboard.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard/dashboard_stat_card.dart';
import '../widgets/dashboard/dashboard_state_views.dart';
import '../widgets/dashboard/recent_order_list.dart';
import '../widgets/dashboard/revenue_line_chart.dart';
import '../widgets/admin/admin_app_bar_title.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
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
          icon: Icons.admin_panel_settings_rounded,
          title: 'Xin chào, Admin',
          subtitle: 'Tổng quan hoạt động BookStore',
        ),
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: provider.isNotificationEnabled
                        ? 'Tắt thông báo'
                        : 'Bật thông báo',
                    icon: Icon(
                      provider.isNotificationEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                    onPressed: provider.toggleNotification,
                  ),
                  if (provider.isNotificationEnabled)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasData) {
            return const DashboardLoadingView();
          }

          if (provider.errorMessage != null && !provider.hasData) {
            return DashboardErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadDashboard,
            );
          }

          final summary = provider.summary;
          if (summary == null) {
            return DashboardErrorView(
              message: 'Dashboard chưa có dữ liệu.',
              onRetry: provider.loadDashboard,
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: provider.loadDashboard,
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
                      _SummaryGrid(summary: summary),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 840) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: RevenueLineChart(
                                      points: provider.chartPoints),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: RecentOrderList(
                                      orders: provider.recentOrders),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              RevenueLineChart(points: provider.chartPoints),
                              const SizedBox(height: 16),
                              RecentOrderList(orders: provider.recentOrders),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900 ? 4 : 2;
        final aspectRatio = width >= 900 ? 1.4 : 1.15;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            DashboardStatCard(
              title: 'Doanh thu hoàn thành',
              value: currencyFormat.format(summary.totalRevenue),
              icon: Icons.payments_outlined,
              color: const Color(0xFF2563EB),
            ),
            DashboardStatCard(
              title: 'Đơn hàng mới hôm nay',
              value: summary.newOrdersToday.toString(),
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF0EA5E9),
            ),
            DashboardStatCard(
              title: 'Chi phí nhập hàng',
              value: currencyFormat.format(summary.importCost),
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF10B981),
            ),
            DashboardStatCard(
              title: 'Tài khoản hoạt động',
              value: summary.activeAccounts.toString(),
              icon: Icons.people_alt_outlined,
              color: const Color(0xFFF59E0B),
            ),
          ],
        );
      },
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
          const Icon(Icons.info_outline,
              color: Color.fromARGB(255, 250, 0, 0), size: 18),
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
