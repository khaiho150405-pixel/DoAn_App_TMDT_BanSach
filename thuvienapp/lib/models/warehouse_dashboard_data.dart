class WarehouseDashboardData {
  final int tongSoSach;
  final int sachHetHang;
  final int phieuNhapHomNay;
  final double tongGiaTriKho;

  const WarehouseDashboardData({
    required this.tongSoSach,
    required this.sachHetHang,
    required this.phieuNhapHomNay,
    required this.tongGiaTriKho,
  });

  factory WarehouseDashboardData.fromJson(Map<String, dynamic> json) {
    return WarehouseDashboardData(
      tongSoSach: _toInt(json['tongSoSach']),
      sachHetHang: _toInt(json['sachHetHang']),
      phieuNhapHomNay: _toInt(json['phieuNhapHomNay']),
      tongGiaTriKho: _toDouble(json['tongGiaTriKho']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
