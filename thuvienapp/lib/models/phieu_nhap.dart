class PhieuNhap {
  final int mapn;
  final int manv;
  final DateTime ngayNhap;
  final double tongTien;
  final String? ghiChu;
  final String? tenNhanVien;
  final int? soLuongMuc;
  final List<ChiTietPhieuNhap> chiTiet;

  PhieuNhap({
    required this.mapn,
    required this.manv,
    required this.ngayNhap,
    required this.tongTien,
    this.ghiChu,
    this.tenNhanVien,
    this.soLuongMuc,
    this.chiTiet = const [],
  });

  factory PhieuNhap.fromJson(Map<String, dynamic> json) {
    List<ChiTietPhieuNhap> details = [];
    if (json['chiTiet'] != null) {
      details = (json['chiTiet'] as List)
          .map((ct) => ChiTietPhieuNhap.fromJson(ct))
          .toList();
    }

    return PhieuNhap(
      mapn: json['mapn'] ?? 0,
      manv: json['manv'] ?? 0,
      ngayNhap: DateTime.tryParse(json['ngaynhap']?.toString() ?? '') ??
          DateTime.now(),
      tongTien: _toDouble(json['tongtien']),
      ghiChu: json['ghichu'],
      tenNhanVien: json['tenNhanVien'],
      soLuongMuc: json['soLuongMuc'],
      chiTiet: details,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class ChiTietPhieuNhap {
  final int masach;
  final String? tenSach;
  final int soLuong;
  final double giaNhap;
  final double? thanhTien;

  ChiTietPhieuNhap({
    required this.masach,
    this.tenSach,
    required this.soLuong,
    required this.giaNhap,
    this.thanhTien,
  });

  factory ChiTietPhieuNhap.fromJson(Map<String, dynamic> json) {
    return ChiTietPhieuNhap(
      masach: json['masach'] ?? 0,
      tenSach: json['tenSach'],
      soLuong: json['soluong'] ?? 0,
      giaNhap: _toDouble(json['gianhap']),
      thanhTien: json['thanhtien'] != null
          ? _toDouble(json['thanhtien'])
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
