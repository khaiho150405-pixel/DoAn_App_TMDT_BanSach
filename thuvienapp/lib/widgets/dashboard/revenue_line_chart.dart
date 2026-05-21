import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard.dart';

class RevenueLineChart extends StatelessWidget {
  final List<RevenueChartPoint> points;

  const RevenueLineChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu theo thời gian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu biểu đồ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : LineChart(_buildChartData()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final maxRevenue = points
        .map((point) => point.revenue)
        .fold<double>(0, (max, value) => value > max ? value : max);
    final interval = maxRevenue <= 0 ? 1.0 : maxRevenue / 4;

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: maxRevenue <= 0 ? 1 : maxRevenue * 1.15,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color(0xFFE5E7EB),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) {
              return Text(
                _shortCurrency(value),
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length || value != index) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  points[index].label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var index = 0; index < points.length; index++)
              FlSpot(index.toDouble(), points[index].revenue),
          ],
          isCurved: true,
          color: const Color(0xFF2563EB),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }

  String _shortCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    }
    return NumberFormat.compact(locale: 'vi_VN').format(value);
  }
}
