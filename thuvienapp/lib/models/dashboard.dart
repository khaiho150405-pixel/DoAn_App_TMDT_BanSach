class DashboardSummary {
  final double totalRevenue;
  final int newOrdersToday;
  final double importCost;
  final int activeAccounts;

  const DashboardSummary({
    required this.totalRevenue,
    required this.newOrdersToday,
    required this.importCost,
    required this.activeAccounts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalRevenue: _toDouble(json['totalRevenue']),
      newOrdersToday: _toInt(json['newOrdersToday']),
      importCost: _toDouble(json['importCost']),
      activeAccounts: _toInt(json['activeAccounts']),
    );
  }
}

class RecentOrder {
  final int orderId;
  final String customerName;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;

  const RecentOrder({
    required this.orderId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      orderId: _toInt(json['orderId']),
      customerName: json['customerName']?.toString() ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class RevenueChartPoint {
  final String label;
  final double revenue;

  const RevenueChartPoint({
    required this.label,
    required this.revenue,
  });

  factory RevenueChartPoint.fromJson(Map<String, dynamic> json) {
    return RevenueChartPoint(
      label: json['label']?.toString() ?? '',
      revenue: _toDouble(json['revenue']),
    );
  }
}

class DashboardData {
  final DashboardSummary summary;
  final List<RecentOrder> recentOrders;
  final List<RevenueChartPoint> chartPoints;

  const DashboardData({
    required this.summary,
    required this.recentOrders,
    required this.chartPoints,
  });
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
